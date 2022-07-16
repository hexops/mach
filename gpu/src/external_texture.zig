pub const ChainedStruct = @import("types.zig").ChainedStruct;

pub const ExternalTexture = enum(usize) {
    _,

    // TODO: verify there is a use case for nullable value of this type.
    pub const none: ExternalTexture = @intToEnum(ExternalTexture, 0);

    pub const BindingEntry = extern struct {
        chain: ChainedStruct,
        external_texture: ExternalTexture,
    };

    pub const BindingLayout = extern struct {
        chain: ChainedStruct,
    };
};
