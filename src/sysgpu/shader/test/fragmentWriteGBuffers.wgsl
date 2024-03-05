struct GBufferOutput {
  @location(0) normal : vec4<f32>,

  // Textures: diffuse color, specular color, smoothness, emissive etc. could go here
  @location(1) albedo : vec4<f32>,
}

@fragment
fn main(
  @location(0) fragNormal: vec3<f32>,
  @location(1) fragUV : vec2<f32>
) -> GBufferOutput {
  // faking some kind of checkerboard texture
  let uv = floor(30.0 * fragUV);
  let c = 0.2 + 0.5 * ((uv.x + uv.y) - 2.0 * floor((uv.x + uv.y) / 2.0));

  var output : GBufferOutput;
  output.normal = vec4(fragNormal, 1.0);
  output.albedo = vec4(c, c, c, 1.0);

  return output;
}