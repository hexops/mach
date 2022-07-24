const ChainedStruct = @import("types.zig").ChainedStruct;

pub const Instance = *opaque {};

pub const InstanceDescriptor = extern struct {
    next_in_chain: *const ChainedStruct,
};
