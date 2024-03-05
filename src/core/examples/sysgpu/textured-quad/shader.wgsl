struct VertexOutput {
  @builtin(position) Position : vec4<f32>,
  @location(0) fragUV : vec2<f32>,
};

@vertex
fn vertex_main(@location(0) position : vec2<f32>,
        @location(1) uv : vec2<f32>) -> VertexOutput {
  var output : VertexOutput;
  output.Position = vec4(position, 0, 1);
  output.fragUV = uv;
  return output;
}

@group(0) @binding(0) var mySampler: sampler;
@group(0) @binding(1) var myTexture: texture_2d<f32>;

@fragment
fn frag_main(@location(0) fragUV: vec2<f32>) -> @location(0) vec4<f32> {
    return textureSample(myTexture, mySampler, fragUV);
}