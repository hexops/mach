pub const ShaderModule = enum(usize) {
    _,

    pub const none: ShaderModule = @intToEnum(ShaderModule, 0);
};
