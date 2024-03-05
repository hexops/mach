struct VertexOut {
    @builtin(position) position_clip: vec4<f32>,
    @location(0) uv: vec2<f32>
}

@vertex fn main(
    @location(0) position: vec3<f32>,
    @location(1) uv: vec2<f32>
) -> VertexOut {
    var output : VertexOut;
    output.position_clip = vec4<f32>(position.xy, 0.0, 1.0);
    output.uv = uv;
    return output;
}