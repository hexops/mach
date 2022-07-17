const ChainedStruct = @import("types.zig").ChainedStruct;
const Texture = @import("texture.zig").Texture;

pub const TextureView = enum(usize) {
    _,

    pub const none: TextureView = @intToEnum(TextureView, 0);

    pub const Dimension = enum(u32) {
        dimension_undef = 0x00000000,
        dimension_1d = 0x00000001,
        dimension_2d = 0x00000002,
        dimension_2d_array = 0x00000003,
        dimension_cube = 0x00000004,
        dimension_cube_array = 0x00000005,
        dimension_3d = 0x00000006,
    };

    pub const Descriptor = extern struct {
        next_in_chain: *const ChainedStruct,
        label: ?[*:0]const u8 = null,
        format: Texture.Format,
        dimension: Dimension,
        base_mip_level: u32,
        mip_level_count: u32,
        base_array_layer: u32,
        array_layer_count: u32,
        aspect: Texture.Aspect,
    };
};
