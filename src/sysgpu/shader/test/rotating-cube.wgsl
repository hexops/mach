@group(0) @binding(0) var<uniform> ubo : mat4x4<f32>;
struct VertexOut {
     @builtin(position) position_clip : vec4<f32>,
     @location(0) fragUV : vec2<f32>,
     @location(1) fragPosition: vec4<f32>,
}

@vertex fn vertex_main(
     @location(0) position : vec4<f32>,
     @location(1) uv: vec2<f32> 
) -> VertexOut {
     var output : VertexOut;
     output.position_clip = position * ubo;
     output.fragUV = uv;
     output.fragPosition = 0.5 * (position + vec4<f32>(1.0, 1.0, 1.0, 1.0));
     return output;
}

@fragment fn frag_main(
    @location(0) fragUV: vec2<f32>,
    @location(1) fragPosition: vec4<f32>
) -> @location(0) vec4<f32> {
    return fragPosition;
}