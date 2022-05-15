struct FragUniform {
    type_: u32,
    padding: vec3<f32>,
}
@binding(1) @group(0) var<storage> ubos: array<FragUniform>;

@stage(fragment) fn main( 
    @location(0) uv: vec2<f32>,
    @location(1) bary: vec3<f32>,
    @interpolate(flat) @location(2) triangle_index: u32,
) -> @location(0) vec4<f32> {
    // Example 1: Visualize barycentric coordinates:
    // return vec4<f32>(bary.x, bary.y, bary.z, 1.0);
    // return vec4<f32>(0.0, bary.x, 0.0, 1.0); // bottom-left of triangle
    // return vec4<f32>(0.0, bary.y, 0.0, 1.0); // bottom-right of triangle
    // return vec4<f32>(0.0, bary.z, 0.0, 1.0); // top of triangle

    // Example 2: Render gkurves
    var inversion = -1.0;
    if(ubos[triangle_index].type_ == 1u) {
        // Solid triangle
        return vec4<f32>(0.0, 1.0, 0.0, 1.0);
    } else if(ubos[triangle_index].type_ == 2u) {
        // Concave (inverted quadratic bezier curve)
        inversion = -1.0;
    } else {
        // Convex (inverted quadratic bezier curve)
        inversion = 1.0;
    }

    var dist = (-(pow(bary.z, 4.0) - bary.y * bary.x)) * inversion;
    if (dist < 0.0) {
        discard;
    }
    return vec4<f32>(0.0, 1.0, 0.0, 1.0);
}
