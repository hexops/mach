const ChainedStruct = @import("types.zig").ChainedStruct;
const Texture = @import("texture.zig").Texture;
const TextureFormat = @import("texture.zig").TextureFormat;
const TextureAspect = @import("texture.zig").TextureAspect;

pub const TextureView = *opaque {};

pub const TextureViewDimension = enum(u32) {
    dimension_undef = 0x00000000,
    dimension_1d = 0x00000001,
    dimension_2d = 0x00000002,
    dimension_2d_array = 0x00000003,
    dimension_cube = 0x00000004,
    dimension_cube_array = 0x00000005,
    dimension_3d = 0x00000006,
};

pub const TextureViewDescriptor = extern struct {
    next_in_chain: *const ChainedStruct,
    label: ?[*:0]const u8 = null,
    format: TextureFormat,
    dimension: TextureViewDimension,
    base_mip_level: u32,
    mip_level_count: u32,
    base_array_layer: u32,
    array_layer_count: u32,
    aspect: TextureAspect,
};
