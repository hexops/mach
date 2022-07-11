ptr: *anyopaque,

pub const LostReason = enum(u32) {
    undef = 0x00000000,
    destroyed = 0x00000001,
};
