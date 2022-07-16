pub const Instance = enum(usize) {
    _,

    // TODO: verify there is a use case for nullable value of this type.
    pub const none: Instance = @intToEnum(Instance, 0);
};
