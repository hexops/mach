pub const CommandBuffer = enum(usize) {
    _,

    pub const none: CommandBuffer = @intToEnum(CommandBuffer, 0);
};
