const ChainedStruct = @import("types.zig").ChainedStruct;
const Texture = @import("texture.zig").Texture;
const TextureFormat = @import("texture.zig").TextureFormat;
const TextureAspect = @import("texture.zig").TextureAspect;
const impl = @import("interface.zig").impl;

pub const TextureView = *opaque {
    pub inline fn setLabel(texture_view: TextureView, label: [*:0]const u8) void {
        impl.textureViewSetLabel(texture_view, label);
    }

    pub inline fn reference(texture_view: TextureView) void {
        impl.textureViewReference(texture_view);
    }

    pub inline fn release(texture_view: TextureView) void {
        impl.textureViewRelease(texture_view);
    }
};

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
