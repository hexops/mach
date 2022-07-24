const ChainedStruct = @import("types.zig").ChainedStruct;

pub const CommandBuffer = *opaque {};

pub const CommandBufferDescriptor = extern struct {
    next_in_chain: *const ChainedStruct,
    label: ?[*:0]const u8 = null,
};
