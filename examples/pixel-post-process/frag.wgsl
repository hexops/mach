@fragment fn main(
    @location(0) normal: vec3<f32>,
    @location(1) uv: vec2<f32>,
) -> @location(0) vec4<f32> {
    var color = floor((uv * 0.5 + 0.25) * 32) / 32;
    return vec4<f32>(color, 1, 1);
}

