const std = @import("std");
const mem = std.mem;
const testing = std.testing;
const builtin = @import("builtin");
const Backend = if (builtin.cpu.arch == .wasm32) @import("webaudio.zig") else switch (builtin.os.tag) {
    .linux,
    .windows,
    .macos,
    .ios,
    => @import("soundio.zig"),
    else => @compileError("unsupported os"),
};
pub const Error = Backend.Error;
pub const Device = Backend.Device;
pub const DeviceIterator = Backend.DeviceIterator;

pub const Mode = enum {
    input,
    output,
};

pub const Format = enum {
    U8,
    S16,
    S24,
    S32,
    F32,
};

pub const DeviceOptions = struct {
    mode: Mode = .output,
    format: ?Format = null,
    is_raw: ?bool = null,
    channels: ?u8 = null,
    sample_rate: ?u32 = null,
    id: ?[:0]const u8 = null,
    name: ?[]const u8 = null,
};

pub const DeviceProperties = struct {
    mode: Mode,
    format: Format,
    is_raw: bool,
    channels: u8,
    sample_rate: u32,
    id: [:0]const u8,
    name: []const u8,

    pub fn intoConfig(properties: DeviceProperties) DeviceOptions {
        return .{
            .mode = properties.mode,
            .format = properties.format,
            .is_raw = properties.is_raw,
            .channels = properties.channels,
            .sample_rate = properties.sample_rate,
            .id = properties.id,
            .name = properties.name,
        };
    }
};

const Audio = @This();

backend: Backend,

pub fn init() Error!Audio {
    return Audio{
        .backend = try Backend.init(),
    };
}

pub fn deinit(self: Audio) void {
    self.backend.deinit();
}

pub fn waitEvents(self: Audio) void {
    self.backend.waitEvents();
}

pub fn requestDevice(self: Audio, allocator: std.mem.Allocator, config: Device.Options) Error!*Device {
    return self.backend.requestDevice(allocator, config);
}

pub fn inputDeviceIterator(self: Audio) DeviceIterator {
    return self.backend.inputDeviceIterator();
}

pub fn outputDeviceIterator(self: Audio) DeviceIterator {
    return self.backend.outputDeviceIterator();
}

test "list devices" {
    const a = try init();
    defer a.deinit();

    var iter = a.inputDeviceIterator();
    while (try iter.next()) |_| {}
}

test "connect to device" {
    const a = try init();
    defer a.deinit();

    const d = try a.requestDevice(std.testing.allocator, .{ .mode = .output });
    defer d.deinit(std.testing.allocator);
}

test "connect to device from descriptor" {
    const a = try init();
    defer a.deinit();

    var iter = a.outputDeviceIterator();
    var device_conf = (try iter.next()) orelse return error.NoDeviceFound;

    const d = try a.requestDevice(std.testing.allocator, device_conf);
    defer d.deinit(std.testing.allocator);
}

test "requestDevice behavior: null is_raw" {
    const a = try init();
    defer a.deinit();

    var iter = a.outputDeviceIterator();
    var device_conf = (try iter.next()) orelse return error.NoDeviceFound;

    const bad_conf = Device.Options{
        .is_raw = null,
        .mode = device_conf.mode,
        .id = device_conf.id,
    };
    try testing.expectError(error.InvalidParameter, a.requestDevice(std.testing.allocator, bad_conf));
}

test "requestDevice behavior: invalid id" {
    return error.SkipZigTest;
    // const a = try init();
    // defer a.deinit();

    // var iter = a.outputDeviceIterator();
    // var device_conf = (try iter.next()) orelse return error.NoDeviceFound;

    // const bad_conf = Device.Options{
    //     .is_raw = device_conf.is_raw,
    //     .mode = device_conf.mode,
    //     .id = "wrong-id",
    // };
    // try testing.expectError(error.DeviceUnavailable, a.requestDevice(bad_conf));
}
