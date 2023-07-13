struct UniformBufferObject {
    time: f32,
    resolution: vec2<f32>,
}
@group(0) @binding(0) var<uniform> ubo : UniformBufferObject;

@fragment fn main(
    @location(0) uv : vec2<f32>
) -> @location(0) vec4<f32> {
    return vec4<f32>( 0.0, 0.0, 0.0, 1.0);
}
