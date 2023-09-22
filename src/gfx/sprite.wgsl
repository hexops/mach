//-----------------------------------------------------------------------------
// Vertex shader
//-----------------------------------------------------------------------------
struct VertexOutput {
  // Vertex position
  @builtin(position) Position : vec4<f32>,

  // UV coordinate
  @location(0) fragUV : vec2<f32>,
};

// Our vertex shader will recieve these parameters
struct Uniforms {
  // The view * orthographic projection matrix
  view_projection: mat4x4<f32>,

  // Total size of the sprite texture in pixels
  texture_size: vec2<f32>,
};

@group(0) @binding(0) var<uniform> uniforms : Uniforms;

// Sprite model transformation matrices
@group(0) @binding(1) var<storage, read> sprite_transforms: array<mat4x4<f32>>;

// Sprite UV coordinate transformation matrices. Sprite UV coordinates are (0, 0) at the top-left
// corner, and in pixels.
@group(0) @binding(2) var<storage, read> sprite_uv_transforms: array<mat3x3<f32>>;

// Sprite sizes, in pixels.
@group(0) @binding(3) var<storage, read> sprite_sizes: array<vec2<f32>>;

@vertex
fn vertMain(
  @builtin(vertex_index) VertexIndex : u32
) -> VertexOutput {
  // Our vertex shader will be called six times per sprite (2 triangles make up a sprite, so six
  // vertices.) The VertexIndex tells us which vertex we need to render, so we know e.g. vertices
  // 0-5 correspond to the first sprite, vertices 6-11 correspond to the second sprite, and so on.
  let sprite_transform = sprite_transforms[VertexIndex / 6];
  let sprite_uv_transform = sprite_uv_transforms[VertexIndex / 6];
  let sprite_size = sprite_sizes[VertexIndex / 6];

  // Imagine the vertices and UV coordinates of a card. There are two triangles, the UV coordinates
  // describe the corresponding location of each vertex on the texture. We hard-code the vertex
  // positions and UV coordinates here:
  let positions = array<vec2<f32>, 6>(
      vec2<f32>(0, 0), // left, bottom
      vec2<f32>(0, 1), // left, top
      vec2<f32>(1, 0), // right, bottom
      vec2<f32>(1, 0), // right, bottom
      vec2<f32>(0, 1), // left, top
      vec2<f32>(1, 1), // right, top
  );
  let uvs = array<vec2<f32>, 6>(
      vec2<f32>(0, 1), // left, bottom
      vec2<f32>(0, 0), // left, top
      vec2<f32>(1, 1), // right, bottom
      vec2<f32>(1, 1), // right, bottom
      vec2<f32>(0, 0), // left, top
      vec2<f32>(1, 0), // right, top
  );

  // Based on the vertex index, we determine which positions[n] and uvs[n] we need to use. Our
  // vertex shader is invoked 6 times per sprite, we need to produce the right vertex/uv coordinates
  // each time to produce a textured card.
  let pos_2d = positions[VertexIndex % 6];
  var uv = uvs[VertexIndex % 6];

  // Currently, our pos_2d and uv coordinates describe a card that covers 1px by 1px; and the UV
  // coordinates describe using the entire texture. We alter the coordinates to describe the
  // desired sprite location, size, and apply a subset of the texture instead of the entire texture.
  var pos = vec4<f32>(pos_2d * sprite_size, 0, 1); // normalized -> pixels
  pos = sprite_transform * pos; // apply sprite transform (pixels)
  pos = uniforms.view_projection * pos; // pixels -> normalized

  uv *= sprite_size; // normalized -> pixels
  uv = (sprite_uv_transform * vec3<f32>(uv.xy, 1)).xy; // apply sprite UV transform (pixels)
  uv /= uniforms.texture_size; // pixels -> normalized

  var output : VertexOutput;
  output.Position = pos;
  output.fragUV = uv;
  return output;
}

//-----------------------------------------------------------------------------
// Fragment shader
//-----------------------------------------------------------------------------
@group(0) @binding(4) var spriteSampler: sampler;
@group(0) @binding(5) var spriteTexture: texture_2d<f32>;

@fragment
fn fragMain(
  @location(0) fragUV: vec2<f32>
) -> @location(0) vec4<f32> {
  var c = textureSample(spriteTexture, spriteSampler, fragUV);
  if (c.a <= 0.0) {
    discard;
  }
  return c;
}