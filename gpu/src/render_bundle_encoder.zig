const ChainedStruct = @import("types.zig").ChainedStruct;
const Texture = @import("texture.zig").Texture;

pub const RenderBundleEncoder = *opaque {};

pub const RenderBundleEncoderDescriptor = extern struct {
    next_in_chain: *const ChainedStruct,
    label: ?[*:0]const u8 = null,
    color_formats_count: u32,
    color_formats: [*]const Texture.Format,
    depth_stencil_format: Texture.Format,
    sample_count: u32,
    depth_read_only: bool,
    stencil_read_only: bool,
};
