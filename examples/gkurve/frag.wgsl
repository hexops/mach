struct FragUniform {
    type_: u32,
    padding: vec3<f32>,
}
@binding(1) @group(0) var<storage> ubos: array<FragUniform>;

@stage(fragment) fn main( 
    @location(0) uv: vec2<f32>,
    @interpolate(linear) @location(1) bary: vec3<f32>,
    @interpolate(flat) @location(2) triangle_index: u32,
) -> @location(0) vec4<f32> {
    // Example 1: Visualize barycentric coordinates:
    // return vec4<f32>(bary.x, bary.y, bary.z, 1.0);
    // return vec4<f32>(0.0, bary.x, 0.0, 1.0); // bottom-left of triangle
    // return vec4<f32>(0.0, bary.y, 0.0, 1.0); // bottom-right of triangle
    // return vec4<f32>(0.0, bary.z, 0.0, 1.0); // top of triangle

    // Example 2: Render gkurve primitives
    var inversion = -1.0;
    if(ubos[triangle_index].type_ == 1u) {
        // Solid triangle
        return vec4<f32>(0.0, 1.0, 0.0, 1.0);
    } else if(ubos[triangle_index].type_ == 2u) {
        // Concave (inverted quadratic bezier curve)
        inversion = -1.0;
    } else {
        // Convex (quadratic bezier curve)
        inversion = 1.0;
    }

	// Gradients
	let px = dpdx(bary.xy);
	let py = dpdy(bary.xy);

	// Chain rule
	let fx = (2.0 * bary.x) * px.x - px.y;
	let fy = (2.0 * bary.x) * py.x - py.y;

	// Signed distance
	var dist = (bary.x * bary.x - bary.y) / sqrt(fx * fx + fy * fy);
    // var dist = bary.z*bary.z - bary.y;

    dist *= inversion;
    dist /= 128.0;
    dist /= 1.75;

    // Border rendering.
    if (dist > 0.0 && dist <= 0.1) { return vec4<f32>(1.0, 0.0, 0.0, 1.0); }
    if (dist > 0.2 && dist <= 0.3) { return vec4<f32>(0.0, 0.0, 1.0, 1.0); }

    // Fill color
    if (dist < 0.0) { discard; }
    return vec4<f32>(0.0, 1.0, 0.0, 1.0);
}
