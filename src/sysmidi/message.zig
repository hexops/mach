pub const StatusByte = packed struct(u8) {
    is_data_message: bool,
    remaining: u7,
};

pub const StatusByteDataMessage = packed struct(u7) {
    status_message_type: StatusMessageType,
    channel_or_message_subclass: u4,
};

pub const StatusByteSystemMessage = u7;

pub const StatusMessageType = enum(u3) {
    note_off = 0, // Note Number, Velocity
    note_on = 1, // Note Number, Velocity
    polyphonic_key_pressure = 2, // Note Number, Pressure
    control_change = 3, // Controller Number, Data
    program_change = 4, // Program Number, Unused
    channel_pressure = 5, // Pressure, Unused
    pitch_wheel = 6, // LSB, MSB
};

pub const Event = union(enum) {
    channel: ChannelEvent,
};

pub const ChannelEvent = union(enum) {
    note_on: struct {
        channel: u4,
        key: u8,
        velocity: u8,
    },
    note_off: struct {
        channel: u4,
        key: u8,
        velocity: u8,
    },
};
