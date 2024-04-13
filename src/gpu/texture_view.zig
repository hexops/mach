const ChainedStruct = @import("main.zig").ChainedStruct;
const Texture = @import("texture.zig").Texture;
const Impl = @import("interface.zig").Impl;
const types = @import("main.zig");

pub const TextureView = opaque {
    pub const Dimension = enum(u32) {
        dimension_undefined = 0x00000000,
        dimension_1d = 0x00000001,
        dimension_2d = 0x00000002,
        dimension_2d_array = 0x00000003,
        dimension_cube = 0x00000004,
        dimension_cube_array = 0x00000005,
        dimension_3d = 0x00000006,
    };

    pub const Descriptor = extern struct {
        next_in_chain: ?*const ChainedStruct = null,
        label: ?[*:0]const u8 = null,
        format: Texture.Format = .undefined,
        dimension: Dimension = .dimension_undefined,
        base_mip_level: u32 = 0,
        mip_level_count: u32 = types.mip_level_count_undefined,
        base_array_layer: u32 = 0,
        array_layer_count: u32 = types.array_layer_count_undefined,
        aspect: Texture.Aspect = .all,
    };

    pub inline fn setLabel(texture_view: *TextureView, label: [*:0]const u8) void {
        Impl.textureViewSetLabel(texture_view, label);
    }

    pub inline fn reference(texture_view: *TextureView) void {
        Impl.textureViewReference(texture_view);
    }

    pub inline fn release(texture_view: *TextureView) void {
        Impl.textureViewRelease(texture_view);
    }
};
