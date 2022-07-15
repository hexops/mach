pub const RenderBundleEncoder = enum(usize) {
    _,

    pub const none: RenderBundleEncoder = @intToEnum(RenderBundleEncoder, 0);
};
