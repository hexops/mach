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

        return .{ .dummy = self };
    }

    pub fn deinit(self: *Context) void {
        for (self.devices_info.list.items) |d|
            freeDevice(self.allocator, d);
        self.devices_info.list.deinit(self.allocator);
        self.allocator.destroy(self);
    }

    pub fn refresh(self: *Context) !void {
        for (self.devices_info.list.items) |d|
            freeDevice(self.allocator, d);
        self.devices_info.clear(self.allocator);

        try self.devices_info.list.append(self.allocator, dummy_playback);
        try self.devices_info.list.append(self.allocator, dummy_capture);
        self.devices_info.list.items[0].channels = try self.allocator.alloc(main.Channel, 1);
        self.devices_info.list.items[0].channels[0] = .{
            .id = .front_center,
        };
        self.devices_info.list.items[1].channels = try self.allocator.alloc(main.Channel, 1);
        self.devices_info.list.items[1].channels[0] = .{
            .id = .front_center,
        };
        self.devices_info.setDefault(.playback, 0);
        self.devices_info.setDefault(.capture, 1);
    }

    pub fn devices(self: Context) []const main.Device {
        return self.devices_info.list.items;
    }

    pub fn defaultDevice(self: Context, mode: main.Device.Mode) ?main.Device {
        return self.devices_info.default(mode);
    }

    pub fn createPlayer(self: *Context, device: main.Device, writeFn: main.WriteFn, options: main.Player.Options) !backends.BackendPlayer {
        _ = writeFn;
        var player = try self.allocator.create(Player);
        player.* = .{
            .allocator = self.allocator,
            .sample_rate = options.sample_rate,
            .is_paused = false,
            .vol = 1.0,
            .channels = device.channels,
            .format = options.format,
            .write_step = 0,
        };
        return .{ .dummy = player };
    }
};

pub const Player = struct {
    allocator: std.mem.Allocator,
    sample_rate: u24,
    is_paused: bool,
    vol: f32,

    channels: []main.Channel,
    format: main.Format,
    write_step: u8,

    pub fn deinit(self: *Player) void {
        self.allocator.destroy(self);
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
