struct VertexUniform {
    matrix: mat4x4<f32>,
}
@binding(0) @group(0) var<uniform> ubo: VertexUniform;

struct VertexOut {
    @builtin(position) position_clip: vec4<f32>,
    @location(0) frag_uv: vec2<f32>,
    @interpolate(linear) @location(1) frag_bary: vec2<f32>,
    @interpolate(flat) @location(2) triangle_index: u32,
}

@vertex fn main(
    @builtin(vertex_index) vertex_index: u32,
    @location(0) position: vec4<f32>,
    @location(1) uv: vec2<f32>,
) -> VertexOut {
    var output : VertexOut;
    output.position_clip = ubo.matrix * position;
    output.frag_uv = uv;

    // Generates [0.0, 0.0], [0.5, 0.0], [1.0, 1.0]
    //
    // Equal to:
    //
    // if ((vertex_index+1u) % 3u == 0u) {
    //     output.frag_bary = vec2<f32>(0.0, 0.0);
    // } else if ((vertex_index+1u) % 3u == 1u) {
    //     output.frag_bary = vec2<f32>(0.5, 0.0);
    // } else {
    //     output.frag_bary = vec2<f32>(1.0, 1.0);
    // }
    //
    output.frag_bary = vec2<f32>(
        f32((vertex_index+1u) % 3u) * 0.5,
        1.0 - f32((((vertex_index + 3u) % 3u) + 1u) % 2u),
    );
    output.triangle_index = vertex_index / 3u;
    return output;
}
