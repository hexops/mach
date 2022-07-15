pub const ExternalTexture = enum(usize) {
    _,

    // TODO: verify there is a use case for nullable value of this type.
    pub const none: ExternalTexture = @intToEnum(ExternalTexture, 0);
};
