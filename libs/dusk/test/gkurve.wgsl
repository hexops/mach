struct FragUniform {
    type_: u32,
    padding: vec3<f32>,
    blend_color: vec4<f32>,
}
@binding(1) @group(0) var<storage> ubos: array<FragUniform>;
@binding(2) @group(0) var mySampler: sampler;
@binding(3) @group(0) var myTexture: texture_2d<f32>;

const wireframe = false;
const antialiased = true;
const aa_px = 1.0; // pixels to consume for AA
const dist_scale_px = 300.0; // TODO: do not hard code

@fragment fn main( 
    @location(0) uv: vec2<f32>,
    @interpolate(linear) @location(1) bary_in: vec2<f32>,
    @interpolate(flat) @location(2) triangle_index: u32,
) -> @location(0) vec4<f32> {
    // Example 1: Visualize barycentric coordinates:
    // let bary = bary_in;
    // return vec4<f32>(bary.x, bary.y, 0.0, 1.0);
    // return vec4<f32>(0.0, bary.x, 0.0, 1.0); // [1.0 (bottom-left vertex), 0.0 (bottom-right vertex)]
    // return vec4<f32>(0.0, bary.y, 0.0, 1.0); // [1.0 (bottom-left vertex), 0.0 (top-right face)]

    // Example 2: Very simple quadratic bezier
    // let bary = bary_in;
    // if (bary.x * bary.x - bary.y) > 0 {
    //     discard;
    // }
    // return vec4<f32>(0.0, 1.0, 0.0, 1.0);

    // Example 3: Render gkurve primitives
    let inversion = select( 1.0, -1.0, ubos[triangle_index].type_ == 0u || ubos[triangle_index].type_ == 1u);
    // Texture uvs
    var correct_uv = uv;
    correct_uv.y = 1.0 - correct_uv.y;
    var color = textureSample(myTexture, mySampler, correct_uv) * ubos[triangle_index].blend_color;

    // Curve rendering
    let border_color = vec4<f32>(1.0, 0.0, 0.0, 1.0);
    let border_px = 30.0;
    let is_semicircle = ubos[triangle_index].type_ == 1u || ubos[triangle_index].type_ == 3u;
    var result = select(
        curveColor(bary_in, border_px, border_color, color, inversion, is_semicircle),
        color,
        ubos[triangle_index].type_ == 4u, // triangle rendering
    );

    // Wireframe rendering
    let wireframe_px = 1.0;
    let wireframe_color = vec4<f32>(0.5, 0.5, 0.5, 1.0);
    if (wireframe) {
        result = wireframeColor(bary_in, wireframe_px, wireframe_color, result);
    }

    if (result.a == 0.0) { discard; }
    return result;
}

// Performs alpha 'over' blending between two premultiplied-alpha colors.
fn alphaOver(a: vec4<f32>, b: vec4<f32>) -> vec4<f32> {
    return a + (b * (1.0 - a.a));
}

// Calculates signed distance to a quadratic bézier curve using barycentric coordinates.
fn distanceToQuadratic(bary: vec2<f32>) -> f32 {
    // Gradients
    let px = dpdx(bary.xy);
    let py = dpdy(bary.xy);

    // Chain rule
    let fx = (2.0 * bary.x) * px.x - px.y;
    let fy = (2.0 * bary.x) * py.x - py.y;

    return (bary.x * bary.x - bary.y) / sqrt(fx * fx + fy * fy);
}

// Calculates signed distance to a semicircle using barycentric coordinates.
fn distanceToSemicircle(bary: vec2<f32>) -> f32 {
    let x = abs(((bary.x - 0.5) * 2.0)); // [0.0 left, 1.0 center, 0.0 right]
    let y = ((bary.x-bary.y) * 4.0); // [2.0 bottom, 0.0 top]
    let c = x*x + y*y;

    // Gradients
    let px = dpdx(bary.xy);
    let py = dpdy(bary.xy);

    // Chain rule
    let fx = c * px.x - px.y;
    let fy = c * py.x - py.y;

    let d = (1.0 - (x*x + y*y)) - 0.2;
    return (-d / 6.0) / sqrt(fx * fx + fy * fy);
}

// Calculates signed distance to the wireframe (i.e. faces) of the triangle using barycentric
// coordinates.
fn distanceToWireframe(bary: vec2<f32>) -> f32 {
    let normal = vec3<f32>(
        bary.y, // distance to right face
        (bary.x - bary.y) * 2.0, // distance to bottom face
        1.0 - (((bary.x - bary.y)) + bary.x), // distance to left face
    );
    let fw = sqrt(dpdx(normal)*dpdx(normal) + dpdy(normal)*dpdy(normal));
    let d = normal / fw;
    return min(min(d.x, d.y), d.z);
}

// Calculates the color of the wireframe, taking into account antialiasing and alpha blending with
// the desired background blend color.
fn wireframeColor(bary: vec2<f32>, px: f32, color: vec4<f32>, blend_color: vec4<f32>) -> vec4<f32> {
    let dist = distanceToWireframe(bary);
    if (antialiased) {
        let outer = dist;
        let inner = (px + (aa_px * 2.0)) - dist;
        let in_wireframe = outer >= 0.0 && inner >= 0.0;
        if (in_wireframe) {
            // Note: If this is the outer edge of the wireframe, we do not want to perform alpha
            // blending with the background blend color, since it is an antialiased edge and should
            // be transparent. However, if it is the internal edge of the wireframe, we do want to
            // perform alpha blending as it should be an overlay, not transparent.
            let is_outer_edge = outer < inner;
            if (is_outer_edge) {
                let alpha = smoothstep(0.0, 1.0, outer*(1.0 / aa_px));
                return vec4<f32>((color.rgb/color.a)*alpha, alpha);
            } else {
                let aa_inner = inner - aa_px;
                let alpha = smoothstep(0.0, 1.0, aa_inner*(1.0 / aa_px));
                let wireframe_color = vec4<f32>((color.rgb/color.a)*alpha, alpha);
                return alphaOver(wireframe_color, blend_color);
            }
        }
        return blend_color;
    } else {
        // If we're at the edge use the wireframe color, otherwise use the background blend_color.
        return select(blend_color, color, (px - dist) >= 0.0);
    }
}

// Calculates the color for a curve, taking into account antialiasing and alpha blending with
// the desired background blend color.
//
// inversion: concave (-1.0) or convex (1.0)
// is_semicircle: quadratic bezier (false) or semicircle (true)
fn curveColor(
    bary: vec2<f32>,
    border_px: f32,
    border_color: vec4<f32>,
    blend_color: vec4<f32>,
    inversion: f32,
    is_semicircle: bool,
) -> vec4<f32> {
    let dist = select(
        distanceToQuadratic(bary),
        distanceToSemicircle(bary),
        is_semicircle,
    ) * inversion;
    let is_inverted = (inversion + 1.0) / 2.0; // 1.0 if inverted, 0.0 otherwise

    if (antialiased) {
        let outer = dist + ((border_px + (aa_px * 2.0)) * is_inverted); // bottom
        let inner = ((border_px + (aa_px * 2.0)) * (1.0-is_inverted)) - dist; // top
        let in_border = outer >= 0.0 && inner >= 0.0;
        if (in_border) {
            // Note: If this is the outer edge of the curve, we do not want to perform alpha
            // blending with the background blend color, since it is an antialiased edge and should
            // be transparent. However, if it is the internal edge of the curve, we do want to
            // perform alpha blending as it should be an overlay, not transparent.
            let is_outer_edge = outer < inner;
            if (is_outer_edge) {
                let aa_outer = outer - (aa_px * is_inverted);
                let alpha = smoothstep(0.0, 1.0, aa_outer*(1.0 / aa_px));
                return vec4<f32>((border_color.rgb/border_color.a)*alpha, alpha);
            } else {
                let aa_inner = inner - (aa_px * (1.0 - is_inverted));
                let alpha = smoothstep(0.0, 1.0, aa_inner*(1.0 / aa_px));
                let new_border_color = vec4<f32>((border_color.rgb/border_color.a)*alpha, alpha);
                return alphaOver(new_border_color, blend_color);
            }
            return border_color;
        } else if (outer >= 0.0) {
            return blend_color;
        } else {
            return vec4<f32>(0.0);
        }
    } else {
        let outer = dist + (border_px * is_inverted);
        let inner = (border_px * (1.0-is_inverted)) - dist;
        let in_border = outer >= 0.0 && inner >= 0.0;
        if (in_border) {
            return border_color;
        } else if (outer >= 0.0) {
            return blend_color;
        } else {
            return vec4<f32>(0.0);
        }
    }
}