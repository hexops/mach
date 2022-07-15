pub const BindGroup = enum(usize) {
    _,

    pub const none: BindGroup = @intToEnum(BindGroup, 0);
};
