pub const PipelineLayout = enum(usize) {
    _,

    pub const none: PipelineLayout = @intToEnum(PipelineLayout, 0);
};
