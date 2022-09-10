const c = @import("c.zig");
const intToError = @import("error.zig").intToError;
const Error = @import("error.zig").Error;
const Format = @import("enums.zig").Format;
const ChannelLayout = @import("ChannelLayout.zig");

const InStream = @This();

pub const WriteCallback = *const fn (stream: ?[*]c.SoundIoInStream, frame_count_min: c_int, frame_count_max: c_int) callconv(.C) void;

handle: *c.SoundIoInStream,

pub fn deinit(self: InStream) void {
    c.soundio_instream_destroy(self.handle);
}

pub fn open(self: InStream) Error!void {
    try intToError(c.soundio_instream_open(self.handle));
}

pub fn start(self: InStream) Error!void {
    try intToError(c.soundio_instream_start(self.handle));
}

pub fn pause(self: InStream, pause_state: bool) Error!void {
    try intToError(c.soundio_instream_pause(self.handle, pause_state));
}

pub fn beginWrite(self: InStream, areas: [*]?[*]c.SoundIoChannelArea, frame_count: *i32) Error!void {
    try intToError(c.soundio_instream_begin_write(
        self.handle,
        areas,
        frame_count,
    ));
}

pub fn endWrite(self: InStream) Error!void {
    try intToError(c.soundio_instream_end_write(self.handle));
}

pub fn setFormat(self: InStream, format: Format) void {
    self.handle.*.format = @enumToInt(format);
}

pub fn setWriteCallback(self: InStream, callback: WriteCallback) void {
    self.handle.*.write_callback = callback;
}

pub fn layout(self: InStream) ChannelLayout {
    return ChannelLayout{ .handle = self.handle.*.layout };
}

pub fn sampleRate(self: InStream) i32 {
    return self.handle.*.sample_rate;
}

pub fn layoutError(self: InStream) Error!void {
    try intToError(self.handle.*.layout_error);
}
