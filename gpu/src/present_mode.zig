pub const PresentMode = enum(u32) {
    // TODO: zig enums are not CamelCase
    Immediate = 0x00000000,
    Mailbox = 0x00000001,
    Fifo = 0x00000002,
};
