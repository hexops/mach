pub const ComputePassEncoder = enum(usize) {
    _,

    pub const none: ComputePassEncoder = @intToEnum(ComputePassEncoder, 0);
};
