pub const TextureUsage = enum(u32) {
    // TODO: enums not CamelCase
    None = 0x00000000,
    CopySrc = 0x00000001,
    CopyDst = 0x00000002,
    TextureBinding = 0x00000004,
    StorageBinding = 0x00000008,
    RenderAttachment = 0x00000010,
    Present = 0x00000020,
};
