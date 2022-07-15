pub const RenderPassEncoder = enum(usize) {
    _,

    pub const none: RenderPassEncoder = @intToEnum(RenderPassEncoder, 0);
};
