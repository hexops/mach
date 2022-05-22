struct FragUniform {
    type_: u32,
    padding: vec3<f32>,
    blend_color: vec4<f32>,
}
@binding(1) @group(0) var<storage> ubos: array<FragUniform>;
@binding(2) @group(0) var mySampler: sampler;
@binding(3) @group(0) var myTexture: texture_2d<f32>;

@stage(fragment) fn main( 
    @location(0) uv: vec2<f32>,
    @interpolate(linear) @location(1) bary: vec2<f32>,
    @interpolate(flat) @location(2) triangle_index: u32,
) -> @location(0) vec4<f32> {
    // Example 1: Visualize barycentric coordinates:
    // return vec4<f32>(bary.x, bary.y, 0.0, 1.0);
    // return vec4<f32>(0.0, bary.x, 0.0, 1.0); // [1.0 (bottom-left vertex), 0.0 (bottom-right vertex)]
    // return vec4<f32>(0.0, bary.y, 0.0, 1.0); // [1.0 (bottom-left vertex), 1.0 (top-right face)]

    // Example 2: Render gkurve primitives
    // Concave (inverted quadratic bezier curve)
    // inversion = -1.0;
    // Convex (inverted quadratic bezier curve)
    // inversion = 1.0;
    let inversion = select( 1.0, -1.0, ubos[triangle_index].type_ == 1u);
    // Texture uvs
    // (These two could be cut with vec2(0.0,1.0) + uv * vec2(1.0,-1.0))
    var correct_uv = uv;
    correct_uv.y = 1.0 - correct_uv.y;
    let color = textureSample(myTexture, mySampler, correct_uv) * ubos[triangle_index].blend_color;

    // Gradients
    let px = dpdx(bary.xy);
    let py = dpdy(bary.xy);

    // Chain rule
    let fx = (2.0 * bary.x) * px.x - px.y;
    let fy = (2.0 * bary.x) * py.x - py.y;

    // Signed distance
    var dist = (bary.x * bary.x - bary.y) / sqrt(fx * fx + fy * fy);

    dist *= inversion;
    dist /= 300.0;

    // Border rendering.
    // if (dist > 0.0 && dist <= 0.1) { return vec4<f32>(1.0, 0.0, 0.0, 1.0); }
    // if (dist > 0.2 && dist <= 0.3) { return vec4<f32>(0.0, 0.0, 1.0, 1.0); }

    // WIREFRAME
    // var barys = bary;
    // barys.z = 1.0 - barys.x - barys.y;
    // let deltas = fwidth(barys);
    // let smoothing = deltas * 1.0;
    // let thickness = deltas * 0.25;
    // barys = smoothstep(thickness, thickness + smoothing, barys);
    // let min_bary = min(barys.x, min(barys.y, barys.z));
    // color = vec4(min_bary * color.xyz, 1.0);

    return color * f32(dist >= 0.0 || ubos[triangle_index].type_ == 2u);
}
