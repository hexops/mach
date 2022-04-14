struct UBO {
    transform: mat4x4<f32>;
    time: f32;
}
@group(0) @binding(0) var<uniform> ubo : UBO;

@stage(fragment) fn main(
    @location(0) uv : vec2<f32>
) -> @location(0) vec4<f32> {
    let h = f32(mandel(uv)) / 100.0;
    let s = 1.0;
    let l = 0.5;

    return vec4(h,h,h,1.0);
}

// The usual mandelbrot algorithm
fn mandel(uv: vec2<f32>) -> i32{
    let mapped_point = (uv - vec2<f32>(0.5,0.5)) * 2.0 - vec2<f32>(0.5,0.0);
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
