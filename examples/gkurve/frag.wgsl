struct FragUniform {
    type_: u32,
    padding: vec3<f32>,
    blend_color: vec4<f32>,
}
@binding(1) @group(0) var<storage> ubos: array<FragUniform>;
@binding(2) @group(0) var mySampler: sampler;
@binding(3) @group(0) var myTexture: texture_2d<f32>;

@fragment fn main( 
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
    var color = textureSample(myTexture, mySampler, correct_uv) * ubos[triangle_index].blend_color;

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
    let border_color = vec4<f32>(1.0, 0.0, 0.0, 1.0);
    let border_width = 3.0;
    let border_smoothing = 1.0;
    // if (dist > 0.0 && dist <= 0.1) { return vec4<f32>(1.0, 0.0, 0.0, 1.0); }
    // if (dist > 0.2 && dist <= 0.3) { return vec4<f32>(0.0, 0.0, 1.0, 1.0); }

    // // Wireframe rendering.
    // let right_face_dist = bary.y;
    // let bottom_face_dist = bary.x-bary.y;
    // let left_face_dist = 1.0 - ((bottom_face_dist*2.0) + bary.y);
    // let normal_bary = vec3<f32>(right_face_dist, bottom_face_dist, left_face_dist);

    // let fwd = fwidth(normal_bary);
    // let w = smoothstep(border_width * fwd, (border_width + border_smoothing) * fwd, normal_bary);
    // let width = 1.0 - min(min(w.x, w.y), w.z);
    // let epsilon = 0.001;
    // if (right_face_dist >= -epsilon && right_face_dist <= width
    //     || left_face_dist >= -epsilon && left_face_dist <= width
    //     || bottom_face_dist >= -epsilon && bottom_face_dist <= width) {
    //     color = mix(color, border_color, width);
    //     if (dist < 0.0 && ubos[triangle_index].type_ != 2u) {
    //         return vec4<f32>(border_color.rgb, width);
    //     }
    // }

    return color * f32(dist >= 0.0 || ubos[triangle_index].type_ == 2u);
}
