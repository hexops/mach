const ChainedStruct = @import("types.zig").ChainedStruct;

pub const Instance = enum(usize) {
    _,

    // TODO: verify there is a use case for nullable value of this type.
    pub const none: Instance = @intToEnum(Instance, 0);

    pub const Descriptor = extern struct {
        next_in_chain: *const ChainedStruct,
    };
};
