pub const RenderBundle = enum(usize) {
    _,

    pub const none: RenderBundle = @intToEnum(RenderBundle, 0);
};
