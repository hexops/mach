pub const ComputePipeline = enum(usize) {
    _,

    // TODO: verify there is a use case for nullable value of this type.
    pub const none: ComputePipeline = @intToEnum(ComputePipeline, 0);
};
