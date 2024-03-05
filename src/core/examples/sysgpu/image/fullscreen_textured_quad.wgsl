@group(0) @binding(0) var mySampler : sampler;
@group(0) @binding(1) var myTexture : texture_2d<f32>;

struct VertexOutput {
  @builtin(position) Position : vec4<f32>,
  @location(0) fragUV : vec2<f32>,
}

@vertex
fn vert_main(@builtin(vertex_index) VertexIndex : u32) -> VertexOutput {
  // Draw a fullscreen quad using two triangles, with UV coordinates (normalized pixel coordinates)
  // that would have the full texture be displayed.
  var pos = array<vec2<f32>, 6>(
    vec2<f32>( 1.0,  1.0), // right, top
    vec2<f32>( 1.0, -1.0), // right, bottom
    vec2<f32>(-1.0, -1.0), // left, bottom
    vec2<f32>( 1.0,  1.0), // right, top
    vec2<f32>(-1.0, -1.0), // left, bottom
    vec2<f32>(-1.0,  1.0) // left, top
  );
  var uv = array<vec2<f32>, 6>(
    vec2<f32>(1.0, 0.0),
    vec2<f32>(1.0, 1.0),
    vec2<f32>(0.0, 1.0),
    vec2<f32>(1.0, 0.0),
    vec2<f32>(0.0, 1.0),
    vec2<f32>(0.0, 0.0)
  );

  var output : VertexOutput;
  output.Position = vec4<f32>(pos[VertexIndex], 0.0, 1.0);
  output.fragUV = uv[VertexIndex];
  return output;
}

@fragment
fn frag_main(@location(0) fragUV : vec2<f32>) -> @location(0) vec4<f32> {
  return textureSample(myTexture, mySampler, fragUV);
}
