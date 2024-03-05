struct Uniforms {
  modelViewProjectionMatrix : mat4x4<f32>,
};
@binding(0) @group(0) var<uniform> uniforms : Uniforms;

struct VertexOutput {
  @builtin(position) Position : vec4<f32>,
  @location(0) fragUV : vec2<f32>,
  @location(1) spriteIndex : f32,
};

struct Sprite {
  pos: vec2<f32>,
  size: vec2<f32>,
  world_pos: vec2<f32>,
  sheet_size: vec2<f32>,
};
@binding(3) @group(0) var<storage, read> sprites: array<Sprite>;

@vertex
fn vertex_main(
  @builtin(vertex_index) VertexIndex : u32
) -> VertexOutput {
  var sprite = sprites[VertexIndex / 6];

  // Calculate the vertex position
  var positions = array<vec2<f32>, 6>(
      vec2<f32>(0.0, 0.0), // bottom-left
      vec2<f32>(0.0, 1.0), // top-left
      vec2<f32>(1.0, 0.0), // bottom-right
      vec2<f32>(1.0, 0.0), // bottom-right
      vec2<f32>(0.0, 1.0), // top-left
      vec2<f32>(1.0, 1.0), // top-right
  );
  var pos = positions[VertexIndex % 6];
  pos.x *= sprite.size.x;
  pos.y *= sprite.size.y;
  pos.x += sprite.world_pos.x;
  pos.y += sprite.world_pos.y;

  // Calculate the UV coordinate
  var uvs = array<vec2<f32>, 6>(
      vec2<f32>(0.0, 1.0), // bottom-left
      vec2<f32>(0.0, 0.0), // top-left
      vec2<f32>(1.0, 1.0), // bottom-right
      vec2<f32>(1.0, 1.0), // bottom-right
      vec2<f32>(0.0, 0.0), // top-left
      vec2<f32>(1.0, 0.0), // top-right
  );
  var uv = uvs[VertexIndex % 6];
  uv.x *= sprite.size.x / sprite.sheet_size.x;
  uv.y *= sprite.size.y / sprite.sheet_size.y;
  uv.x += sprite.pos.x / sprite.sheet_size.x;
  uv.y += sprite.pos.y / sprite.sheet_size.y;

  var output : VertexOutput;
  output.Position = vec4<f32>(pos.x, 0.0, pos.y, 1.0) * uniforms.modelViewProjectionMatrix;
  output.fragUV = uv;
  output.spriteIndex = f32(VertexIndex / 6);
  return output;
}

@group(0) @binding(1) var spriteSampler: sampler;
@group(0) @binding(2) var spriteTexture: texture_2d<f32>;

@fragment
fn frag_main(
  @location(0) fragUV: vec2<f32>,
  @location(1) spriteIndex: f32
) -> @location(0) vec4<f32> {
    var color = textureSample(spriteTexture, spriteSampler, fragUV);
    if (spriteIndex == 0.0) {
      if (color[3] > 0.0) {
        color[0] = 0.3;
        color[1] = 0.2;
        color[2] = 0.5;
        color[3] = 1.0;
      }
    }
    
    return color;
}