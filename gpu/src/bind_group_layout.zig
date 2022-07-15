pub const BindGroupLayout = enum(usize) {
    _,

    pub const none: BindGroupLayout = @intToEnum(BindGroupLayout, 0);
};
