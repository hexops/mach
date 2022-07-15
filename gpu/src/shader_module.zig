pub const ShaderModule = enum(usize) {
    _,

    // TODO: verify there is a use case for nullable value of this type.
    pub const none: ShaderModule = @intToEnum(ShaderModule, 0);
};
