pub const CommandEncoder = enum(usize) {
    _,

    // TODO: verify there is a use case for nullable value of this type.
    pub const none: CommandEncoder = @intToEnum(CommandEncoder, 0);
};
