struct Uniforms {
  matrix : mat4x4<f32>,
};

@binding(0) @group(0) var<uniform> ubo : Uniforms;

struct VertexOut {
     @builtin(position) Position : vec4<f32>,
     @location(0) fragUV : vec2<f32>,
     @location(1) fragPosition: vec4<f32>,
}

@vertex fn main(
     @location(0) position : vec4<f32>,
     @location(1) uv: vec2<f32> 
) -> VertexOut {
     var output : VertexOut;
     output.Position = position * ubo.matrix;
     output.fragUV = uv;
     output.fragPosition = 0.5 * (position + vec4<f32>(1.0, 1.0, 1.0, 1.0));
     return output;
}
