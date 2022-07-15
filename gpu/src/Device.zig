pub const Device = enum(usize) {
    _,

    pub const none: Device = @intToEnum(Device, 0);

    pub const LostReason = enum(u32) {
        undef = 0x00000000,
        destroyed = 0x00000001,
    };
};
