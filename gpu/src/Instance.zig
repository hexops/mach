pub const Instance = enum(usize) {
    _,

    pub const none: Instance = @intToEnum(Instance, 0);
};
