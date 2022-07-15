pub const RenderPipeline = enum(usize) {
    _,

    pub const none: RenderPipeline = @intToEnum(RenderPipeline, 0);
};
