const std = @import("std");
const c = @import("c.zig");
const OutStream = @import("OutStream.zig");

const Device = @This();

handle: *c.SoundIoDevice,

pub fn unref(self: Device) void {
    c.soundio_device_unref(self.handle);
}

pub fn name(self: Device) [:0]const u8 {
    return std.mem.span(self.handle.*.name);
}

pub fn createOutStream(self: Device) error{OutOfMemory}!OutStream {
    return OutStream{ .handle = c.soundio_outstream_create(self.handle) orelse return error.OutOfMemory };
}
