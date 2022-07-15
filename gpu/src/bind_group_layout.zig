pub const BindGroupLayout = enum(usize) {
    _,

    // TODO: verify there is a use case for nullable value of this type.
    pub const none: BindGroupLayout = @intToEnum(BindGroupLayout, 0);
};
