pub const CommandBuffer = enum(usize) {
    _,

    // TODO: verify there is a use case for nullable value of this type.
    pub const none: CommandBuffer = @intToEnum(CommandBuffer, 0);
};
