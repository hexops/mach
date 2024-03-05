@fragment fn fs_main() -> @location(0) vec4<f32> {
    var dummy = false;
    if dummy {
        let dummy_var_1 = 0.0;
        return vec4<f32>(dummy_var_1, 1, 1, 1);
    } else if !dummy {
        let dummy_var_2 = 0.0;
        return vec4<f32>(dummy_var_2, 1, 1, 1);
    }
    return vec4<f32>(0.0, 1, 1, 1);
}