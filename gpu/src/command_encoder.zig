const ChainedStruct = @import("types.zig").ChainedStruct;

pub const CommandEncoder = *opaque {};

pub const CommandEncoderDescriptor = extern struct {
    next_in_chain: *const ChainedStruct,
    label: ?[*:0]const u8 = null,
};
