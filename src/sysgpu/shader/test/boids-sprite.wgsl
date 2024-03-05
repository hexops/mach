@vertex
fn vert_main(@location(0) a_particlePos : vec2<f32>,
             @location(1) a_particleVel : vec2<f32>,
             @location(2) a_pos : vec2<f32>) -> @builtin(position) vec4<f32> {
  let angle = -atan2(a_particleVel.x, a_particleVel.y);
  let pos = vec2<f32>(
      (a_pos.x * cos(angle)) - (a_pos.y * sin(angle)),
      (a_pos.x * sin(angle)) + (a_pos.y * cos(angle)));
  return vec4<f32>(pos + a_particlePos, 0.0, 1.0);
}

@fragment
fn frag_main() -> @location(0) vec4<f32> {
  return vec4<f32>(1.0, 1.0, 1.0, 1.0);
}