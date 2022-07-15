pub const ComputePipeline = enum(usize) {
    _,

    pub const none: ComputePipeline = @intToEnum(ComputePipeline, 0);
};
