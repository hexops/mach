const std = @import("std");

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

const AddressMode = enum(u32) {
    repeat = 0x00000000,
    mirror_repeat = 0x00000001,
    clamp_to_edge = 0x00000002,
};

pub const PresentMode = enum(u32) {
    immediate = 0x00000000,
    mailbox = 0x00000001,
    fifo = 0x00000002,
};

pub const TextureFormat = enum(u32) {
    none = 0x00000000,
    r8_unorm = 0x00000001,
    r8_snorm = 0x00000002,
    r8_uint = 0x00000003,
    r8_sint = 0x00000004,
    r16_uint = 0x00000005,
    r16_sint = 0x00000006,
    r16_float = 0x00000007,
    rg8_unorm = 0x00000008,
    rg8_snorm = 0x00000009,
    rg8_uint = 0x0000000a,
    rg8_sint = 0x0000000b,
    r32_float = 0x0000000c,
    r32_uint = 0x0000000d,
    r32_sint = 0x0000000e,
    rg16_uint = 0x0000000f,
    rg16_sint = 0x00000010,
    rg16_float = 0x00000011,
    rgba8_unorm = 0x00000012,
    rgba8_unorm_srgb = 0x00000013,
    rgba8_snorm = 0x00000014,
    rgba8_uint = 0x00000015,
    rgba8_sint = 0x00000016,
    bgra8_unorm = 0x00000017,
    bgra8_unorm_srgb = 0x00000018,
    rgb10a2_unorm = 0x00000019,
    rg11b10u_float = 0x0000001a,
    rgb9e5u_float = 0x0000001b,
    rg32_float = 0x0000001c,
    rg32_uint = 0x0000001d,
    rg32_sint = 0x0000001e,
    rgba16_uint = 0x0000001f,
    rgba16_sint = 0x00000020,
    rgba16_float = 0x00000021,
    rgba32_float = 0x00000022,
    rgba32_uint = 0x00000023,
    rgba32_sint = 0x00000024,
    stencil8 = 0x00000025,
    depth16_unorm = 0x00000026,
    depth24_plus = 0x00000027,
    depth24_plus_stencil8 = 0x00000028,
    depth24_unorm_stencil8 = 0x00000029,
    depth32_float = 0x0000002a,
    depth32_float_stencil8 = 0x0000002b,
    bc1rgba_unorm = 0x0000002c,
    bc1rgba_unorm_srgb = 0x0000002d,
    bc2rgba_unorm = 0x0000002e,
    bc2rgba_unorm_srgb = 0x0000002f,
    bc3rgba_unorm = 0x00000030,
    bc3rgba_unorm_srgb = 0x00000031,
    bc4r_unorm = 0x00000032,
    bc4r_snorm = 0x00000033,
    bc5rg_unorm = 0x00000034,
    bc5rg_snorm = 0x00000035,
    bc6hrgbu_float = 0x00000036,
    bc6hrgb_float = 0x00000037,
    bc7rgba_unorm = 0x00000038,
    bc7rgba_unorm_srgb = 0x00000039,
    etc2rgb8_unorm = 0x0000003a,
    etc2rgb8_unorm_srgb = 0x0000003b,
    etc2rgb8a1_unorm = 0x0000003c,
    etc2rgb8a1_unorm_srgb = 0x0000003d,
    etc2rgba8_unorm = 0x0000003e,
    etc2rgba8_unorm_srgb = 0x0000003f,
    eacr11_unorm = 0x00000040,
    eacr11_snorm = 0x00000041,
    eacrg11_unorm = 0x00000042,
    eacrg11_snorm = 0x00000043,
    astc4x4_unorm = 0x00000044,
    astc4x4_unorm_srgb = 0x00000045,
    astc5x4_unorm = 0x00000046,
    astc5x4_unorm_srgb = 0x00000047,
    astc5x5_unorm = 0x00000048,
    astc5x5_unorm_srgb = 0x00000049,
    astc6x5_unorm = 0x0000004a,
    astc6x5_unorm_srgb = 0x0000004b,
    astc6x6_unorm = 0x0000004c,
    astc6x6_unorm_srgb = 0x0000004d,
    astc8x5_unorm = 0x0000004e,
    astc8x5_unorm_srgb = 0x0000004f,
    astc8x6_unorm = 0x00000050,
    astc8x6_unorm_srgb = 0x00000051,
    astc8x8_unorm = 0x00000052,
    astc8x8_unorm_srgb = 0x00000053,
    astc10x5_unorm = 0x00000054,
    astc10x5_unorm_srgb = 0x00000055,
    astc10x6_unorm = 0x00000056,
    astc10x6_unorm_srgb = 0x00000057,
    astc10x8_unorm = 0x00000058,
    astc10x8_unorm_srgb = 0x00000059,
    astc10x10_unorm = 0x0000005a,
    astc10x10_unorm_srgb = 0x0000005b,
    astc12x10_unorm = 0x0000005c,
    astc12x10_unorm_srgb = 0x0000005d,
    astc12x12_unorm = 0x0000005e,
    astc12x12_unorm_srgb = 0x0000005f,
    r8bg8biplanar420_unorm = 0x00000060,
};

pub const TextureUsage = enum(u32) {
    none = 0x00000000,
    copy_src = 0x00000001,
    copy_dst = 0x00000002,
    texture_binding = 0x00000004,
    storage_binding = 0x00000008,
    render_attachment = 0x00000010,
    present = 0x00000020,
};

pub const AlphaMode = enum(u32) {
    premultiplied = 0x00000000,
    unpremultiplied = 0x00000001,
};

pub const BlendFactor = enum(u32) {
    zero = 0x00000000,
    one = 0x00000001,
    src = 0x00000002,
    one_minus_src = 0x00000003,
    src_alpha = 0x00000004,
    oneMinusSrcAlpha = 0x00000005,
    dst = 0x00000006,
    one_minus_dst = 0x00000007,
    dst_alpha = 0x00000008,
    one_minus_dst_alpha = 0x00000009,
    src_alpha_saturated = 0x0000000A,
    constant = 0x0000000B,
    one_minus_constant = 0x0000000C,
};

pub const BlendOperation = enum(u32) {
    add = 0x00000000,
    subtract = 0x00000001,
    reverse_subtract = 0x00000002,
    min = 0x00000003,
    max = 0x00000004,
};

pub const BufferBindingType = enum(u32) {
    none = 0x00000000,
    uniform = 0x00000001,
    storage = 0x00000002,
    read_only_storage = 0x00000003,
};

pub const BufferMapAsyncStatus = enum(u32) {
    success = 0x00000000,
    err = 0x00000001,
    unknown = 0x00000002,
    device_lost = 0x00000003,
    destroyed_before_callback = 0x00000004,
    unmapped_before_callback = 0x00000005,
};

pub const CompareFunction = enum(u32) {
    none = 0x00000000,
    never = 0x00000001,
    less = 0x00000002,
    less_equal = 0x00000003,
    greater = 0x00000004,
    greater_equal = 0x00000005,
    equal = 0x00000006,
    not_equal = 0x00000007,
    always = 0x00000008,
};

pub const CompilationInfoRequestStatus = enum(u32) {
    success = 0x00000000,
    err = 0x00000001,
    device_lost = 0x00000002,
    unknown = 0x00000003,
};

pub const CompilationMessageType = enum(u32) {
    err = 0x00000000,
    warning = 0x00000001,
    info = 0x00000002,
};

test "name" {
    try std.testing.expect(std.mem.eql(u8, @tagName(Feature.timestamp_query), "timestamp_query"));
}

test "syntax" {
    _ = Feature;
    _ = AddressMode;
    _ = PresentMode;
    _ = AlphaMode;
    _ = BlendFactor;
    _ = BlendOperation;
    _ = BufferBindingType;
    _ = BufferMapAsyncStatus;
    _ = CompareFunction;
    _ = CompilationInfoRequestStatus;
    _ = CompilationMessageType;
}
