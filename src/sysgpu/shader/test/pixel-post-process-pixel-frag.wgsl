@group(0) @binding(0)
var draw_texture: texture_2d<f32>;
@group(0) @binding(1)
var draw_texture_sampler: sampler;

@group(0) @binding(2)
var depth_texture: texture_depth_2d;
@group(0) @binding(3)
var depth_texture_sampler: sampler;

@group(0) @binding(4)
var normal_texture: texture_2d<f32>;
@group(0) @binding(5)
var normal_texture_sampler: sampler;

struct View {
    @location(0) width: u32,
    @location(1) height: u32,
    @location(2) pixel_size: u32,
}
@group(0) @binding(6)
var<uniform> view: View;

fn sample_depth(uv: vec2<f32>, x: f32, y: f32) -> f32 {
    return textureSample(
        depth_texture,
        depth_texture_sampler,
        uv + vec2<f32>(x * f32(view.pixel_size) / f32(view.width), y * f32(view.pixel_size) / f32(view.height))
    );
}

fn sample_normal(uv: vec2<f32>, x: f32, y: f32) -> vec3<f32> {
    return textureSample(
        normal_texture,
        normal_texture_sampler,
        uv + vec2<f32>(x * f32(view.pixel_size) / f32(view.width), y * f32(view.pixel_size) / f32(view.height))
    ).xyz;
}

fn normal_indicator(uv: vec2<f32>, x: f32, y: f32) -> f32 {
    // TODO - integer promotion to float argument
    var depth_diff = sample_depth(uv, 0.0, 0.0) - sample_depth(uv, x, y);
    var dx = sample_normal(uv, 0.0, 0.0);
    var dy = sample_normal(uv, x, y);
    if (depth_diff > 0) {
        // only sample normals from closest pixel
        return 0;
    }
    return distance(dx, dy); 
}

@fragment fn main(
    // TODO - vertex/fragment linkage
    @location(0) uv: vec2<f32>,
    @builtin(position) position: vec4<f32>
) -> @location(0) vec4<f32> {
    // TODO - integer promotion to float argument
    var depth = sample_depth(uv, 0.0, 0.0);
    var depth_diff: f32 = 0;
    depth_diff += abs(depth - sample_depth(uv, -1.0, 0.0));
    depth_diff += abs(depth - sample_depth(uv, 1.0, 0.0));
    depth_diff += abs(depth - sample_depth(uv, 0.0, -1.0));
    depth_diff += abs(depth - sample_depth(uv, 0.0, 1.0));

    var normal_diff: f32 = 0;
    normal_diff += normal_indicator(uv, -1.0, 0.0);
    normal_diff += normal_indicator(uv, 1.0, 0.0);
    normal_diff += normal_indicator(uv, 0.0, -1.0);
    normal_diff += normal_indicator(uv, 0.0, 1.0);

    var color = textureSample(draw_texture, draw_texture_sampler, uv);
    if (depth_diff > 0.007) { // magic number from testing
        return color * 0.7;
    }
    // add instead of multiply so really dark pixels get brighter 
    return color + (vec4<f32>(1) * step(0.1, normal_diff) * 0.7);
}