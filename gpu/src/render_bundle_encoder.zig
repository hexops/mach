pub const RenderBundleEncoder = enum(usize) {
    _,

    // TODO: verify there is a use case for nullable value of this type.
    pub const none: RenderBundleEncoder = @intToEnum(RenderBundleEncoder, 0);
};
