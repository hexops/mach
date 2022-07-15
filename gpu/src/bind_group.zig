pub const BindGroup = enum(usize) {
    _,

    // TODO: verify there is a use case for nullable value of this type.
    pub const none: BindGroup = @intToEnum(BindGroup, 0);
};
