const c = @import("c.zig");
const intToError = @import("error.zig").intToError;
const Error = @import("error.zig").Error;
const Format = @import("enums.zig").Format;
const ChannelLayout = @import("ChannelLayout.zig");

const OutStream = @This();

pub const WriteCallback = if (@import("builtin").zig_backend == .stage1)
    fn (stream: ?[*]c.SoundIoOutStream, frame_count_min: c_int, frame_count_max: c_int) callconv(.C) void
else
    *const fn (stream: ?[*]c.SoundIoOutStream, frame_count_min: c_int, frame_count_max: c_int) callconv(.C) void;

handle: *c.SoundIoOutStream,

pub fn deinit(self: OutStream) void {
    c.soundio_outstream_destroy(self.handle);
}

pub fn open(self: OutStream) Error!void {
    try intToError(c.soundio_outstream_open(self.handle));
}

pub fn start(self: OutStream) Error!void {
    try intToError(c.soundio_outstream_start(self.handle));
}

pub fn pause(self: OutStream) Error!void {
    try intToError(c.soundio_outstream_pause(self.handle));
}

pub fn beginWrite(self: OutStream, areas: [*]?[*]c.SoundIoChannelArea, frame_count: *i32) Error!void {
    try intToError(c.soundio_outstream_begin_write(
        self.handle,
        areas,
        frame_count,
    ));
}

pub fn endWrite(self: OutStream) Error!void {
    try intToError(c.soundio_outstream_end_write(self.handle));
}

pub fn setFormat(self: OutStream, format: Format) void {
    self.handle.*.format = @enumToInt(format);
}

pub fn setWriteCallback(self: OutStream, callback: WriteCallback) void {
    self.handle.*.write_callback = callback;
}

pub fn layout(self: OutStream) ChannelLayout {
    return ChannelLayout{ .handle = self.handle.*.layout };
}

pub fn sampleRate(self: OutStream) i32 {
    return self.handle.*.sample_rate;
}

pub fn layoutError(self: OutStream) Error!void {
    try intToError(self.handle.*.layout_error);
}
