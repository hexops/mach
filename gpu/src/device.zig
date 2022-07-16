pub const Device = enum(usize) {
    _,

    // TODO: verify there is a use case for nullable value of this type.
    pub const none: Device = @intToEnum(Device, 0);

    pub const LostReason = enum(u32) {
        undef = 0x00000000,
        destroyed = 0x00000001,
    };
};
