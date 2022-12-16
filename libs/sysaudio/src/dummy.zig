const std = @import("std");
const main = @import("main.zig");
const backends = @import("backends.zig");
const util = @import("util.zig");

pub const min_sample_rate = 8_000; // Hz
pub const max_sample_rate = 5_644_800; // Hz

const dummy_playback = main.Device{
    .id = "dummy-playback",
    .name = "Dummy Device",
    .mode = .playback,
    .channels = undefined,
    .formats = std.meta.tags(main.Format),
    .sample_rate = .{
        .min = min_sample_rate,
        .max = max_sample_rate,
    },
};

const dummy_capture = main.Device{
    .id = "dummy-capture",
    .name = "Dummy Device",
    .mode = .capture,
    .channels = undefined,
    .formats = std.meta.tags(main.Format),
    .sample_rate = .{
        .min = min_sample_rate,
        .max = max_sample_rate,
    },
};

pub const Context = struct {
    allocator: std.mem.Allocator,
    devices_info: util.DevicesInfo,

    pub fn init(allocator: std.mem.Allocator, options: main.Context.Options) !backends.BackendContext {
        _ = options;

        var self = try allocator.create(Context);
        errdefer allocator.destroy(self);
        self.* = .{
            .allocator = allocator,
            .devices_info = util.DevicesInfo.init(),
        };

        try self.devices_info.list.append(self.allocator, dummy_playback);
        try self.devices_info.list.append(self.allocator, dummy_capture);
        self.devices_info.list.items[0].channels = try allocator.alloc(main.Channel, 1);
        self.devices_info.list.items[0].channels[0] = .{
            .id = .front_center,
        };
        self.devices_info.list.items[1].channels = try allocator.alloc(main.Channel, 1);
        self.devices_info.list.items[1].channels[0] = .{
            .id = .front_center,
        };
        self.devices_info.setDefault(.playback, 0);
        self.devices_info.setDefault(.capture, 1);

        return .{ .dummy = self };
    }

    pub fn deinit(self: *Context) void {
        for (self.devices_info.list.items) |d|
            freeDevice(self.allocator, d);
        self.devices_info.list.deinit(self.allocator);
        self.allocator.destroy(self);
    }

    pub fn refresh(self: *Context) !void {
        _ = self;
    }

    pub fn devices(self: Context) []const main.Device {
        return self.devices_info.list.items;
    }

    pub fn defaultDevice(self: Context, mode: main.Device.Mode) ?main.Device {
        return self.devices_info.default(mode);
    }

    pub fn createPlayer(self: *Context, device: main.Device, writeFn: main.WriteFn, options: main.Player.Options) !backends.BackendPlayer {
        _ = self;
        _ = writeFn;
        return .{
            .dummy = .{
                ._channels = device.channels,
                ._format = options.format,
                .sample_rate = options.sample_rate,
                .is_paused = false,
                .vol = 1.0,
            },
        };
    }
};

pub const Player = struct {
    _channels: []main.Channel,
    _format: main.Format,
    sample_rate: u24,
    is_paused: bool,
    vol: f32,

    pub fn deinit(self: Player) void {
        _ = self;
    }

    pub fn start(self: Player) !void {
        _ = self;
    }

    pub fn play(self: *Player) !void {
        self.is_paused = false;
    }

    pub fn pause(self: *Player) !void {
        self.is_paused = true;
    }

    pub fn paused(self: Player) bool {
        return self.is_paused;
    }

    pub fn setVolume(self: *Player, vol: f32) !void {
        self.vol = vol;
    }

    pub fn volume(self: Player) !f32 {
        return self.vol;
    }

    pub fn writeRaw(self: Player, channel: main.Channel, frame: usize, sample: anytype) void {
        _ = self;
        _ = channel;
        _ = frame;
        _ = sample;
    }

    pub fn channels(self: Player) []main.Channel {
        return self._channels;
    }

    pub fn format(self: Player) main.Format {
        return self._format;
    }

    pub fn sampleRate(self: Player) u24 {
        return self.sample_rate;
    }
};

fn freeDevice(allocator: std.mem.Allocator, device: main.Device) void {
    allocator.free(device.channels);
}

test {
    std.testing.refAllDeclsRecursive(@This());
}
