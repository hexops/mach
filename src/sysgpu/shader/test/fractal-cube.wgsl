struct Uniforms {
  matrix : mat4x4<f32>,
};

@binding(0) @group(0) var<uniform> ubo : Uniforms;

struct VertexOut {
     @builtin(position) Position : vec4<f32>,
     @location(0) fragUV : vec2<f32>,
     @location(1) fragPosition: vec4<f32>,
}

@vertex fn vertex_main(
     @location(0) position : vec4<f32>,
     @location(1) uv: vec2<f32> 
) -> VertexOut {
     var output : VertexOut;
     output.Position = position * ubo.matrix;
     output.fragUV = uv;
     output.fragPosition = 0.5 * (position + vec4<f32>(1.0, 1.0, 1.0, 1.0));
     return output;
}

@binding(1) @group(0) var mySampler: sampler;
@binding(2) @group(0) var myTexture: texture_2d<f32>;

@fragment fn frag_main(
        @location(0) fragUV: vec2<f32>,
        @location(1) fragPosition: vec4<f32>
) -> @location(0) vec4<f32> {
  let texColor = textureSample(myTexture, mySampler, fragUV * 0.8 + vec2<f32>(0.1, 0.1));
  let f = f32(length(texColor.rgb - vec3<f32>(0.5, 0.5, 0.5)) < 0.01);
  return (1.0 - f) * texColor + f * fragPosition;
  // return vec4<f32>(texColor.rgb,1.0);
}