struct LightData {
  position : vec4<f32>,
  color : vec3<f32>,
  radius : f32,
}
struct LightsBuffer {
  lights: array<LightData>,
}
@group(0) @binding(0) var<storage, read_write> lightsBuffer: LightsBuffer;

struct Config {
  numLights : u32,
}
@group(0) @binding(1) var<uniform> config: Config;

struct LightExtent {
  min : vec4<f32>,
  max : vec4<f32>,
}
@group(0) @binding(2) var<uniform> lightExtent: LightExtent;

@compute @workgroup_size(64, 1, 1)
fn main(@builtin(global_invocation_id) GlobalInvocationID : vec3<u32>) {
  var index = GlobalInvocationID.x;
  if (index >= config.numLights) {
    return;
  }

  lightsBuffer.lights[index].position.y = lightsBuffer.lights[index].position.y - 0.5 - 0.003 * (f32(index) - 64.0 * floor(f32(index) / 64.0));

  if (lightsBuffer.lights[index].position.y < lightExtent.min.y) {
    lightsBuffer.lights[index].position.y = lightExtent.max.y;
  }
}
