@group(0) @binding(0) var<storage> _runtime_array : array<u32>;

@fragment
fn main() {
  // TODO: Add all builtins
  let _array_length = arrayLength(&_runtime_array);
  let _sin = sin(1.0);
  let _cos = cos(1.0);
  let _normalize = normalize(vec3(1.0));
  let _length = length(1.0);
  let _floor = floor(1.0);
  let _abs = abs(1.0);
  let _all = all(vec3(true));
  let _dpdx = dpdx(1.0);
  let _dpdy = dpdy(1.0);
  let _fwidth = fwidth(1.0);
  let _min = min(1.0, 1.0);
  let _max = max(1.0, 1.0);
  let _atan2 = atan2(1.0, 1.0);
  let _distance = distance(1.0, 1.0);
  let _dot = dot(vec3(1.0), vec3(1.0));
  let _pow = pow(1.0, 1.0);
  let _step = step(1.0, 1.0);
  let _mix = mix(1.0, 1.0, 1.0);
  let _clamp = clamp(1.0, 1.0, 1.0);
  let _smoothstep = smoothstep(1.0, 1.0, 1.0);
}