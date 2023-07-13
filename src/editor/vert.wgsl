struct VertexOut {
    @builtin(position) position_clip : vec4<f32>,
    @location(0) frag_uv : vec2<f32>,
}

@vertex fn main(@builtin(vertex_index) index : u32) -> VertexOut {
    var pos = array<vec2<f32>, 3>(
        vec2<f32>(-1.0, -1.0),
        vec2<f32>( 3.0, -1.0),
        vec2<f32>(-1.0,  3.0),
    );

    var uv = array<vec2<f32>, 3>(
        vec2<f32>(0.0, 0.0),
        vec2<f32>(2.0, 0.0),
        vec2<f32>(0.0, 2.0),
    );

    var output : VertexOut;
    output.position_clip = vec4<f32>(pos[index], 0.0, 1.0);
    output.frag_uv = uv[index];
    return output;
}
