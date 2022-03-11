const Texture = @This();

/// The type erased pointer to the Texture implementation
/// Equal to c.WGPUTexture for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    // TODO:
    // WGPU_EXPORT WGPUTextureView wgpuTextureCreateView(WGPUTexture texture, WGPUTextureViewDescriptor const * descriptor);
    destroy: fn (ptr: *anyopaque) void,
    setLabel: fn (ptr: *anyopaque, label: [:0]const u8) void,
};

pub inline fn reference(texture: Texture) void {
    texture.vtable.reference(texture.ptr);
}

pub inline fn release(texture: Texture) void {
    texture.vtable.release(texture.ptr);
}

pub inline fn setLabel(texture: Texture, label: [:0]const u8) void {
    texture.vtable.setLabel(texture.ptr, label);
}

pub inline fn destroy(texture: Texture) void {
    texture.vtable.destroy(texture.ptr);
}

pub const Usage = enum(u32) {
    none = 0x00000000,
    copy_src = 0x00000001,
    copy_dst = 0x00000002,
    texture_binding = 0x00000004,
    storage_binding = 0x00000008,
    render_attachment = 0x00000010,
    present = 0x00000020,
};

pub const Format = enum(u32) {
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

pub const Aspect = enum(u32) {
    all = 0x00000000,
    stencil_only = 0x00000001,
    depth_only = 0x00000002,
    plane0_only = 0x00000003,
    plane1_only = 0x00000004,
};

pub const ComponentType = enum(u32) {
    float = 0x00000000,
    sint = 0x00000001,
    uint = 0x00000002,
    depth_comparison = 0x00000003,
};

pub const Dimension = enum(u32) {
    dimension_1d = 0x00000000,
    dimension_2d = 0x00000001,
    dimension_3d = 0x00000002,
};

pub const SampleType = enum(u32) {
    none = 0x00000000,
    float = 0x00000001,
    unfilterable_float = 0x00000002,
    depth = 0x00000003,
    sint = 0x00000004,
    uint = 0x00000005,
};

pub const ViewDimension = enum(u32) {
    dimension_none = 0x00000000,
    dimension_1d = 0x00000001,
    dimension_2d = 0x00000002,
    dimension_2d_array = 0x00000003,
    dimension_cube = 0x00000004,
    dimension_cube_array = 0x00000005,
    dimension_3d = 0x00000006,
};

pub const BindingLayout = struct {
    sample_type: SampleType,
    view_dimension: ViewDimension,
    multisampled: bool,
};

pub const DataLayout = struct {
    offset: u64,
    bytes_per_row: u32,
    rows_per_image: u32,
};

test "syntax" {
    _ = VTable;
    _ = reference;
    _ = release;
    _ = destroy;
    _ = Usage;
    _ = Format;
    _ = Aspect;
    _ = ComponentType;
    _ = Dimension;
    _ = SampleType;
    _ = ViewDimension;
    _ = BindingLayout;
    _ = DataLayout;
}
