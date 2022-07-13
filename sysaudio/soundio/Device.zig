const std = @import("std");
const c = @import("c.zig");
const InStream = @import("InStream.zig");
const OutStream = @import("OutStream.zig");
const Format = @import("enums.zig").Format;

const Device = @This();

handle: *c.SoundIoDevice,

pub fn unref(self: Device) void {
    c.soundio_device_unref(self.handle);
}

pub fn id(self: Device) [:0]const u8 {
    return std.mem.span(self.handle.*.id);
}

pub fn name(self: Device) [:0]const u8 {
    return std.mem.span(self.handle.*.name);
}

pub fn createInStream(self: Device) error{OutOfMemory}!InStream {
    return InStream{ .handle = c.soundio_instream_create(self.handle) orelse return error.OutOfMemory };
}

pub fn createOutStream(self: Device) error{OutOfMemory}!OutStream {
    return OutStream{ .handle = c.soundio_outstream_create(self.handle) orelse return error.OutOfMemory };
}

pub fn supportsFormat(self: Device, format: Format) bool {
    return c.soundio_device_supports_format(self.handle, @enumToInt(format));
}
