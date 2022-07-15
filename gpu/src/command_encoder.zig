pub const CommandEncoder = enum(usize) {
    _,

    pub const none: CommandEncoder = @intToEnum(CommandEncoder, 0);
};
