struct Uniforms {
  modelMatrix : mat4x4<f32>,
  normalModelMatrix : mat4x4<f32>,
}
struct Camera {
  viewProjectionMatrix : mat4x4<f32>,
  invViewProjectionMatrix : mat4x4<f32>,
}
@group(0) @binding(0) var<uniform> uniforms : Uniforms;
@group(0) @binding(1) var<uniform> camera : Camera;

struct VertexOutput {
  @builtin(position) Position : vec4<f32>,
  @location(0) fragNormal: vec3<f32>,    // normal in world space
  @location(1) fragUV: vec2<f32>,
}

@vertex
fn main(
  @location(0) position : vec3<f32>,
  @location(1) normal : vec3<f32>,
  @location(2) uv : vec2<f32>
) -> VertexOutput {
  var output : VertexOutput;
  let worldPosition = (uniforms.modelMatrix * vec4(position, 1.0)).xyz;
  output.Position = camera.viewProjectionMatrix * vec4(worldPosition, 1.0);
  output.fragNormal = normalize((uniforms.normalModelMatrix * vec4(normal, 1.0)).xyz);
  output.fragUV = uv;
  return output;
}