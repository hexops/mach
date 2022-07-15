pub const Queue = enum(usize) {
    _,

    // TODO: verify there is a use case for nullable value of this type.
    pub const none: Queue = @intToEnum(Queue, 0);

    pub const WorkDoneStatus = enum(u32) {
        success = 0x00000000,
        err = 0x00000001,
        unknown = 0x00000002,
        device_lost = 0x00000003,
    };
};
