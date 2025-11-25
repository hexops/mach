@fragment
fn main() -> @location(0) vec4<f32> {
    var cond = true;
    var t = vec4<f32>(1.0, 1.0, 1.0, 1.0);
    var f = vec4<f32>(0.0, 0.0, 0.0, 0.0);
    
    return select(f, t, cond);
}