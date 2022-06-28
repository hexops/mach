const c = @import("c.zig");
const intToError = @import("error.zig").intToError;
const Error = @import("error.zig").Error;
const Backend = @import("enums.zig").Backend;
const Device = @import("Device.zig");

const SoundIo = @This();

handle: *c.SoundIo,

pub fn init() Error!SoundIo {
    return SoundIo{ .handle = c.soundio_create() orelse return Error.OutOfMemory };
}

pub fn deinit(self: SoundIo) void {
    c.soundio_destroy(self.handle);
}

pub fn connect(self: SoundIo) Error!void {
    try intToError(c.soundio_connect(self.handle));
}

pub fn connectBackend(self: SoundIo, backend: Backend) Error!void {
    try intToError(c.soundio_connect_backend(self.handle, @enumToInt(backend)));
}

pub fn disconnect(self: SoundIo) void {
    c.soundio_disconnect(self.handle);
}

pub fn flushEvents(self: SoundIo) void {
    c.soundio_flush_events(self.handle);
}

pub fn defaultInputDeviceIndex(self: SoundIo) ?u16 {
    const index = c.soundio_default_input_device_index(self.handle);
    return if (index < 0) null else @intCast(u16, index);
}

pub fn defaultOutputDeviceIndex(self: SoundIo) ?u16 {
    const index = c.soundio_default_output_device_index(self.handle);
    return if (index < 0) null else @intCast(u16, index);
}

pub fn getInputDevice(self: SoundIo, index: u16) ?Device {
    return Device{
        .handle = c.soundio_get_input_device(self.handle, index) orelse return null,
    };
}

pub fn getOutputDevice(self: SoundIo, index: u16) ?Device {
    return Device{
        .handle = c.soundio_get_output_device(self.handle, index) orelse return null,
    };
}
