pub const TextureUsage = enum(u32) {
    none = 0x00000000,
    copy_src = 0x00000001,
    copy_dst = 0x00000002,
    texture_binding = 0x00000004,
    storage_binding = 0x00000008,
    render_attachment = 0x00000010,
    present = 0x00000020,
};
