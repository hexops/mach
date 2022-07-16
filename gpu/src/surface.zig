pub const Surface = enum(usize) {
    _,

    // TODO: verify there is a use case for nullable value of this type.
    pub const none: Surface = @intToEnum(Surface, 0);
};
