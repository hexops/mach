pub const PipelineLayout = enum(usize) {
    _,

    // TODO: verify there is a use case for nullable value of this type.
    pub const none: PipelineLayout = @intToEnum(PipelineLayout, 0);
};
