const std = @import("std");
const Mode = @import("main.zig").Mode;
const DeviceDescriptor = @import("main.zig").DeviceDescriptor;
const c = @import("soundio").c;
const Aim = @import("soundio").Aim;
const SoundIo = @import("soundio").SoundIo;
const SoundIoDevice = @import("soundio").Device;
const SoundIoInStream = @import("soundio").InStream;
const SoundIoOutStream = @import("soundio").OutStream;
const SoundIoStream = union(Mode) {
    input: SoundIoInStream,
    output: SoundIoOutStream,
};

const Audio = @This();

pub const DataCallback = fn (device: Device, frame_count: u32) void;
pub const Device = struct {
    handle: SoundIoStream,
    data_callback: ?DataCallback = null,
    user_data: ?*anyopaque = null,

    pub fn setCallback(self: Device, callback: DataCallback, data: *anyopaque) void {
        self.data_callback = callback;
        self.user_data = data;
    }

    pub fn deinit(self: Device) void {
        return switch (self.handle) {
            .input => |d| d.deinit(),
            .output => |d| d.deinit(),
        };
    }
};
pub const DeviceIterator = struct {
    ctx: Audio,
    mode: Mode,
    device_len: u16,
    index: u16,

    pub fn next(self: *DeviceIterator) IteratorError!?DeviceDescriptor {
        if (self.index < self.device_len) {
            const device_desc = switch (self.mode) {
                .input => self.ctx.handle.getInputDevice(self.index) orelse return null,
                .output => self.ctx.handle.getOutputDevice(self.index) orelse return null,
            };
            self.index += 1;
            return DeviceDescriptor{
                .mode = switch (@intToEnum(Aim, device_desc.handle.aim)) {
                    .input => .input,
                    .output => .output,
                },
                .is_raw = device_desc.handle.is_raw,
                .id = device_desc.id(),
                .name = device_desc.name(),
            };
        }
        return null;
    }
};

pub const IteratorError = error{OutOfMemory};
pub const Error = error{
    OutOfMemory,
    InvalidDeviceID,
    InvalidParameter,
    NoDeviceFound,
    AlreadyConnected,
    CannotConnect,
    UnsupportedOS,
    UnsupportedBackend,
    DeviceUnavailable,
};

handle: SoundIo,

pub fn init() Error!Audio {
    var self = Audio{
        .handle = try SoundIo.init(),
    };
    self.handle.connect() catch |err| {
        return switch (err) {
            error.SystemResources, error.NoSuchClient => error.CannotConnect,
            error.Invalid => error.AlreadyConnected,
            error.OutOfMemory => error.OutOfMemory,
            else => unreachable,
        };
    };
    self.handle.flushEvents();
    return self;
}

pub fn deinit(self: Audio) void {
    self.handle.deinit();
}

pub fn waitEvents(self: Audio) void {
    self.handle.waitEvents();
}

pub fn requestDevice(self: Audio, config: DeviceDescriptor) Error!Device {
    return Device{
        .handle = blk: {
            var sio_device: SoundIoDevice = undefined;

            if (config.id) |id| {
                if (config.mode == null or config.is_raw == null)
                    return error.InvalidParameter;

                sio_device = switch (config.mode.?) {
                    .input => self.handle.getInputDeviceFromID(id, config.is_raw.?),
                    .output => self.handle.getOutputDeviceFromID(id, config.is_raw.?),
                } orelse {
                    return if (switch (config.mode.?) {
                        .input => self.handle.inputDeviceCount().?,
                        .output => self.handle.outputDeviceCount().?,
                    } == 0)
                        error.NoDeviceFound
                    else
                        error.DeviceUnavailable;
                };
            } else {
                if (config.mode == null) return error.InvalidParameter;

                const id = switch (config.mode.?) {
                    .input => self.handle.defaultInputDeviceIndex(),
                    .output => self.handle.defaultOutputDeviceIndex(),
                } orelse return error.NoDeviceFound;
                sio_device = switch (config.mode.?) {
                    .input => self.handle.getInputDevice(id),
                    .output => self.handle.getOutputDevice(id),
                } orelse return error.DeviceUnavailable;
            }

            break :blk switch (config.mode.?) {
                .input => SoundIoStream{ .input = try sio_device.createInStream() },
                .output => SoundIoStream{ .output = try sio_device.createOutStream() },
            };
        },
    };
}

pub fn outputDeviceIterator(self: Audio) DeviceIterator {
    return .{
        .ctx = self,
        .mode = .output,
        .device_len = self.handle.outputDeviceCount() orelse 0,
        .index = 0,
    };
}

pub fn inputDeviceIterator(self: Audio) DeviceIterator {
    return .{
        .ctx = self,
        .mode = .input,
        .device_len = self.handle.inputDeviceCount() orelse 0,
        .index = 0,
    };
}
