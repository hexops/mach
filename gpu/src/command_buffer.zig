const ChainedStruct = @import("types.zig").ChainedStruct;

pub const CommandBuffer = enum(usize) {
    _,

    // TODO: verify there is a use case for nullable value of this type.
    pub const none: CommandBuffer = @intToEnum(CommandBuffer, 0);

    pub const Descriptor = extern struct {
        next_in_chain: *const ChainedStruct,
        label: ?[*:0]const u8 = null,
    };
};
