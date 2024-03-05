const std = @import("std");
const main = @import("main.zig");
const backends = @import("backends.zig");
const util = @import("util.zig");

const default_sample_rate = 44_100; // Hz

const dummy_playback = main.Device{
    .id = "dummy-playback",
    .name = "Dummy Device",
    .mode = .playback,
    .channels = undefined,
    .formats = std.meta.tags(main.Format),
    .sample_rate = .{
        .min = main.min_sample_rate,
        .max = main.max_sample_rate,
    },
};

const dummy_capture = main.Device{
    .id = "dummy-capture",
    .name = "Dummy Device",
    .mode = .capture,
    .channels = undefined,
    .formats = std.meta.tags(main.Format),
    .sample_rate = .{
        .min = main.min_sample_rate,
        .max = main.max_sample_rate,
    },
};

pub const Context = struct {
    allocator: std.mem.Allocator,
    devices_info: util.DevicesInfo,

    pub fn init(allocator: std.mem.Allocator, options: main.Context.Options) !backends.Context {
        _ = options;

        const ctx = try allocator.create(Context);
        errdefer allocator.destroy(ctx);
        ctx.* = .{
            .allocator = allocator,
            .devices_info = util.DevicesInfo.init(),
        };

        return .{ .dummy = ctx };
    }

    pub fn deinit(ctx: *Context) void {
        for (ctx.devices_info.list.items) |d|
            freeDevice(ctx.allocator, d);
        ctx.devices_info.list.deinit(ctx.allocator);
        ctx.allocator.destroy(ctx);
    }

    pub fn refresh(ctx: *Context) !void {
        for (ctx.devices_info.list.items) |d|
            freeDevice(ctx.allocator, d);
        ctx.devices_info.clear();

        try ctx.devices_info.list.append(ctx.allocator, dummy_playback);
        try ctx.devices_info.list.append(ctx.allocator, dummy_capture);

        ctx.devices_info.setDefault(.playback, 0);
        ctx.devices_info.setDefault(.capture, 1);

        ctx.devices_info.list.items[0].channels = try ctx.allocator.alloc(main.ChannelPosition, 1);
        ctx.devices_info.list.items[1].channels = try ctx.allocator.alloc(main.ChannelPosition, 1);

        ctx.devices_info.list.items[0].channels[0] = .front_center;
        ctx.devices_info.list.items[1].channels[0] = .front_center;
    }

    pub fn devices(ctx: Context) []const main.Device {
        return ctx.devices_info.list.items;
    }

    pub fn defaultDevice(ctx: Context, mode: main.Device.Mode) ?main.Device {
        return ctx.devices_info.default(mode);
    }

    pub fn createPlayer(ctx: *Context, device: main.Device, writeFn: main.WriteFn, options: main.StreamOptions) !backends.Player {
        _ = writeFn;
        const player = try ctx.allocator.create(Player);
        player.* = .{
            .allocator = ctx.allocator,
            .is_paused = false,
            .vol = 1.0,
            .channels = device.channels,
            .format = options.format,
            .sample_rate = options.sample_rate orelse default_sample_rate,
        };
        return .{ .dummy = player };
    }

    pub fn createRecorder(ctx: *Context, device: main.Device, readFn: main.ReadFn, options: main.StreamOptions) !backends.Recorder {
        _ = readFn;
        const recorder = try ctx.allocator.create(Recorder);
        recorder.* = .{
            .allocator = ctx.allocator,
            .is_paused = false,
            .vol = 1.0,
            .channels = device.channels,
            .format = options.format,
            .sample_rate = options.sample_rate orelse default_sample_rate,
        };
        return .{ .dummy = recorder };
    }
};

pub const Player = struct {
    allocator: std.mem.Allocator,
    is_paused: bool,
    vol: f32,

    channels: []main.ChannelPosition,
    format: main.Format,
    sample_rate: u24,

    pub fn deinit(player: *Player) void {
        player.allocator.destroy(player);
    }

    pub fn start(player: *Player) !void {
        _ = player;
    }

    pub fn play(player: *Player) !void {
        player.is_paused = false;
    }

    pub fn pause(player: *Player) !void {
        player.is_paused = true;
    }

    pub fn paused(player: *Player) bool {
        return player.is_paused;
    }

    pub fn setVolume(player: *Player, vol: f32) !void {
        player.vol = vol;
    }

    pub fn volume(player: *Player) !f32 {
        return player.vol;
    }
};

pub const Recorder = struct {
    allocator: std.mem.Allocator,
    is_paused: bool,
    vol: f32,

    channels: []main.ChannelPosition,
    format: main.Format,
    sample_rate: u24,

    pub fn deinit(recorder: *Recorder) void {
        recorder.allocator.destroy(recorder);
    }

    pub fn start(recorder: *Recorder) !void {
        _ = recorder;
    }

    pub fn record(recorder: *Recorder) !void {
        recorder.is_paused = false;
    }

    pub fn pause(recorder: *Recorder) !void {
        recorder.is_paused = true;
    }

    pub fn paused(recorder: *Recorder) bool {
        return recorder.is_paused;
    }

    pub fn setVolume(recorder: *Recorder, vol: f32) !void {
        recorder.vol = vol;
    }

    pub fn volume(recorder: *Recorder) !f32 {
        return recorder.vol;
    }
};

fn freeDevice(allocator: std.mem.Allocator, device: main.Device) void {
    allocator.free(device.channels);
}
