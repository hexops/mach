pub const ComputePassEncoder = enum(usize) {
    _,

    // TODO: verify there is a use case for nullable value of this type.
    pub const none: ComputePassEncoder = @intToEnum(ComputePassEncoder, 0);
};
