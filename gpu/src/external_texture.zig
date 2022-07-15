pub const ExternalTexture = enum(usize) {
    _,

    pub const none: ExternalTexture = @intToEnum(ExternalTexture, 0);
};
