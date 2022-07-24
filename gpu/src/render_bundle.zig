const ChainedStruct = @import("types.zig").ChainedStruct;

pub const RenderBundle = *opaque {};

pub const RenderBundleDescriptor = extern struct {
    next_in_chain: *const ChainedStruct,
    label: ?[*:0]const u8 = null,
};
