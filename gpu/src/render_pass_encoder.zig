pub const RenderPassEncoder = enum(usize) {
    _,

    // TODO: verify there is a use case for nullable value of this type.
    pub const none: RenderPassEncoder = @intToEnum(RenderPassEncoder, 0);
};
