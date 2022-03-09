pub const Feature = enum(u32) {
    depth24_unorm_stencil8 = 0x00000002,
    depth32_float_stencil8 = 0x00000003,
    timestamp_query = 0x00000004,
    pipeline_statistics_query = 0x00000005,
    texture_compression_bc = 0x00000006,
    texture_compression_etc2 = 0x00000007,
    texture_compression_astc = 0x00000008,
    indirect_first_instance = 0x00000009,
    depth_clamping = 0x000003e8,
    dawn_shader_float16 = 0x000003e9,
    dawn_internal_usages = 0x000003ea,
    dawn_multi_planar_formats = 0x000003eb,
    dawn_native = 0x000003ec,
};

// TODO: add featureName stringer method

const AddressMode = enum(u32) {
    repeat = 0x00000000,
    mirror_repeat = 0x00000001,
    clamp_to_edge = 0x00000002,
};

test "syntax" {
    _ = Feature;
    _ = AddressMode;
}
