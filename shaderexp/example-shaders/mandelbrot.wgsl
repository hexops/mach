struct UniformBufferObject {
    resolution: vec2<f32>,
    time: f32,
}
@group(0) @binding(0) var<uniform> ubo : UniformBufferObject;

@stage(fragment) fn main(
    @location(0) uv : vec2<f32>
) -> @location(0) vec4<f32> {
    let aspect = ubo.resolution / min(ubo.resolution.x,ubo.resolution.y);
    let translated_uv = (uv - vec2(0.5,0.5)) * aspect * 2.0;
    let col = f32(mandel(translated_uv)) / 100.0;

    return vec4(vec3<f32>(col), 1.0);
}

fn mandel(uv: vec2<f32>) -> i32{
    let zoom = 1.0;
    let center_position = vec2<f32>(0.5,0.0);
    let mapped_point = uv * zoom - center_position;
    var z = mapped_point;
    var tmp:f32;
    var i:i32 = 0;
    var found = false;
    var res = 0;
    loop {
        if (i >= 100){
            break;
        }
        tmp = z.x;
        z.x = z.x * z.x - z.y * z.y + mapped_point.x;
        z.y = 2. * tmp * z.y + mapped_point.y;
        found = found || (z.x * z.x + z.y * z.y > 16.);
        res = res + 1 * i32(!found);
        i = i + 1;
    }
    return res;
}
