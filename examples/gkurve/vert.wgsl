struct VertexUniform {
    matrix: mat4x4<f32>,
}
@binding(0) @group(0) var<uniform> ubo: VertexUniform;

struct VertexOut {
    @builtin(position) position_clip: vec4<f32>,
    @location(0) frag_uv: vec2<f32>,
    @interpolate(linear) @location(1) frag_bary: vec3<f32>,
    @interpolate(flat) @location(2) triangle_index: u32,
}

@stage(vertex) fn main(
    @builtin(vertex_index) vertex_index: u32,
    @location(0) position: vec4<f32>,
    @location(1) uv: vec2<f32>,
) -> VertexOut {
    var output : VertexOut;
    output.position_clip = ubo.matrix * position;
    output.frag_uv = uv;
    output.frag_bary = vec3<f32>(
        f32(((vertex_index+2u) % 3u * 2u) % 3u),
        f32(((vertex_index+2u) % 3u * 2u) & 2u) * 2.0,
        0.0,
    );
    output.triangle_index = vertex_index / 3u;
    return output;
}
