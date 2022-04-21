struct VertexOut {
     @builtin(position) position_clip : vec4<f32>;
     @location(0) frag_uv : vec2<f32>;
}

@stage(vertex) fn main(
     @location(0) position : vec4<f32>,
     @location(1) uv : vec2<f32>
) -> VertexOut {
     var output : VertexOut;
     output.position_clip = position;
     output.frag_uv = uv;
     return output;
}
