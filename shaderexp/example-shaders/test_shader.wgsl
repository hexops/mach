struct UniformBufferObject {
    resolution: vec2<f32>,
    time: f32,
}
@group(0) @binding(0) var<uniform> ubo : UniformBufferObject;

@stage(fragment) fn main(
    @location(0) uv : vec2<f32>
) -> @location(0) vec4<f32> {
    let aspect = ubo.resolution.xy / ubo.resolution.y;
    let translated_uv = (uv - vec2<f32>(0.5,0.5)) * 2.0 * aspect;
    let freq:f32 = 5.0;
    let speed: f32 = 5.0;
    let h = (sin(freq * length(translated_uv) + speed * ubo.time) + 1.0) / 2.0;

    let h_off = 20.0;
    return vec4<f32>(hsl_to_rgb(h * (360.0 - h_off * 2.0) + h_off ,0.7,0.5),1.0);
}

// 0 ≤ H < 360, 0 ≤ S ≤ 1 and 0 ≤ L ≤ 1
fn hsl_to_rgb(h:f32,s:f32,l:f32) -> vec3<f32> {
    let tmp_h = h % 360.0;
    let c = (1.0 - abs(2.0 * l - 1.0)) * s;
    let x = c * (1.0 - abs((tmp_h / 60.0) % 2.0 - 1.0));
    let m = l - c / 2.0;

    let case_1 = vec3<f32>(c  ,x  ,0.0);
    let case_2 = vec3<f32>(x  ,c  ,0.0);
    let case_3 = vec3<f32>(0.0,c  ,x);
    let case_4 = vec3<f32>(0.0,x  ,c);
    let case_5 = vec3<f32>(x  ,0.0,c);
    let case_6 = vec3<f32>(c  ,0.0,x);

    return case_1 * f32(tmp_h < 60.0  && tmp_h >= 0.0) +
           case_2 * f32(tmp_h < 120.0 && tmp_h >= 60.0) +
           case_3 * f32(tmp_h < 180.0 && tmp_h >= 120.0) +
           case_4 * f32(tmp_h < 240.0 && tmp_h >= 180.0) +
           case_5 * f32(tmp_h < 300.0 && tmp_h >= 240.0) +
           case_6 * f32(tmp_h < 360.0 && tmp_h >= 300.0) + vec3<f32>(m);
}
