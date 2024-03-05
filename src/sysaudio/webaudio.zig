const std = @import("std");
const js = @import("sysjs");
const main = @import("main.zig");
const backends = @import("backends.zig");
const util = @import("util.zig");

const default_sample_rate = 44_100; // Hz
const channel_size = 1024;
const channel_size_bytes = channel_size * @sizeOf(f32);

const default_playback = main.Device{
    .id = "default-playback",
    .name = "Default Device",
    .mode = .playback,
    .channels = undefined,
    .formats = &.{.f32},
    .sample_rate = .{
        .min = 8_000,
        .max = 96_000,
    },
};

pub const Context = struct {
    allocator: std.mem.Allocator,
    devices_info: util.DevicesInfo,

    pub fn init(allocator: std.mem.Allocator, options: main.Context.Options) !backends.Context {
        _ = options;

        const audio_context = js.global().get("AudioContext");
        if (audio_context.is(.undefined))
            return error.ConnectionRefused;

        const ctx = try allocator.create(Context);
        errdefer allocator.destroy(ctx);
        ctx.* = .{
            .allocator = allocator,
            .devices_info = util.DevicesInfo.init(),
        };

        return .{ .webaudio = ctx };
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
        ctx.devices_info.clear(ctx.allocator);

        try ctx.devices_info.list.append(ctx.allocator, default_playback);
        ctx.devices_info.list.items[0].channels = try ctx.allocator.alloc(main.ChannelPosition, 2);
        ctx.devices_info.list.items[0].channels[0] = .front_left;
        ctx.devices_info.list.items[0].channels[1] = .front_right;
        ctx.devices_info.setDefault(.playback, 0);
    }

    pub fn devices(ctx: Context) []const main.Device {
        return ctx.devices_info.list.items;
    }

    pub fn defaultDevice(ctx: Context, mode: main.Device.Mode) ?main.Device {
        return ctx.devices_info.default(mode);
    }

    pub fn createPlayer(ctx: *Context, device: main.Device, writeFn: main.WriteFn, options: main.StreamOptions) !backends.Player {
        const context_options = js.createMap();
        defer context_options.deinit();
        context_options.set("sampleRate", js.createNumber(options.sample_rate orelse default_sample_rate));

        const audio_context = js.constructType("AudioContext", &.{context_options.toValue()});
        const gain_node = audio_context.call("createGain", &.{
            js.createNumber(1),
            js.createNumber(0),
            js.createNumber(device.channels.len),
        }).view(.object);
        const process_node = audio_context.call("createScriptProcessor", &.{
            js.createNumber(channel_size),
            js.createNumber(device.channels.len),
        }).view(.object);

        const player = try ctx.allocator.create(Player);
        errdefer ctx.allocator.destroy(player);

        var captures = try ctx.allocator.alloc(js.Value, 1);
        captures[0] = js.createNumber(@intFromPtr(player));

        const document = js.global().get("document").view(.object);
        defer document.deinit();
        const click_event_str = js.createString("click");
        defer click_event_str.deinit();
        const resume_on_click = js.createFunction(Player.resumeOnClick, captures);
        _ = document.call("addEventListener", &.{ click_event_str.toValue(), resume_on_click.toValue() });

        const audio_process_event = js.createFunction(Player.audioProcessEvent, captures);
        defer audio_process_event.deinit();
        process_node.set("onaudioprocess", audio_process_event.toValue());

        player.* = .{
            .allocator = ctx.allocator,
            .audio_context = audio_context,
            .process_node = process_node,
            .gain_node = gain_node,
            .process_captures = captures,
            .resume_on_click = resume_on_click,
            .buf = try ctx.allocator.alloc(u8, channel_size_bytes * device.channels.len),
            .buf_js = js.constructType("Uint8Array", &.{js.createNumber(channel_size_bytes)}),
            .is_paused = false,
            .writeFn = writeFn,
            .user_data = options.user_data,
            .channels = device.channels,
            .format = .f32,
            .sample_rate = options.sample_rate orelse default_sample_rate,
        };

        return .{ .webaudio = player };
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
        return .{ .webaudio = recorder };
    }
};

pub const Player = struct {
    allocator: std.mem.Allocator,
    audio_context: js.Object,
    process_node: js.Object,
    gain_node: js.Object,
    process_captures: []js.Value,
    resume_on_click: js.Function,
    buf: []u8,
    buf_js: js.Object,
    is_paused: bool,
    writeFn: main.WriteFn,
    user_data: ?*anyopaque,

    channels: []main.ChannelPosition,
    format: main.Format,
    sample_rate: u24,

    pub fn deinit(player: *Player) void {
        player.resume_on_click.deinit();
        player.buf_js.deinit();
        player.gain_node.deinit();
        player.process_node.deinit();
        player.audio_context.deinit();
        player.allocator.free(player.process_captures);
        player.allocator.free(player.buf);
        player.allocator.destroy(player);
    }

    pub fn start(player: *Player) !void {
        const destination = player.audio_context.get("destination").view(.object);
        defer destination.deinit();
        _ = player.gain_node.call("connect", &.{destination.toValue()});
        _ = player.process_node.call("connect", &.{player.gain_node.toValue()});
    }

    fn resumeOnClick(args: js.Object, _: usize, captures: []js.Value) js.Value {
        const player = @as(*Player, @ptrFromInt(@as(usize, @intFromFloat(captures[0].view(.num)))));
        player.play() catch {};

        const document = js.global().get("document").view(.object);
        defer document.deinit();

        const event = args.getIndex(0).view(.object);
        defer event.deinit();
        _ = document.call("removeEventListener", &.{ event.toValue(), player.resume_on_click.toValue() });

        return js.createUndefined();
    }

    fn audioProcessEvent(args: js.Object, _: usize, captures: []js.Value) js.Value {
        const player = @as(*Player, @ptrFromInt(@as(usize, @intFromFloat(captures[0].view(.num)))));

        const event = args.getIndex(0).view(.object);
        defer event.deinit();
        const output_buffer = event.get("outputBuffer").view(.object);
        defer output_buffer.deinit();

        player.writeFn(player.user_data, player.buf[0..channel_size]);

        for (player.channels, 0..) |_, i| {
            player.buf_js.copyBytes(player.buf[i * channel_size_bytes .. (i + 1) * channel_size_bytes]);
            const buf_f32_js = js.constructType("Float32Array", &.{ player.buf_js.get("buffer"), player.buf_js.get("byteOffset"), js.createNumber(channel_size) });
            defer buf_f32_js.deinit();
            _ = output_buffer.call("copyToChannel", &.{ buf_f32_js.toValue(), js.createNumber(i) });
        }

        return js.createUndefined();
    }

    pub fn play(player: *Player) !void {
        _ = player.audio_context.call("resume", &.{js.createUndefined()});
        player.is_paused = false;
    }

    pub fn pause(player: *Player) !void {
        _ = player.audio_context.call("suspend", &.{js.createUndefined()});
        player.is_paused = true;
    }

    pub fn paused(player: *Player) bool {
        return player.is_paused;
    }

    pub fn setVolume(player: *Player, vol: f32) !void {
        const gain = player.gain_node.get("gain").view(.object);
        defer gain.deinit();
        gain.set("value", js.createNumber(vol));
    }

    pub fn volume(player: *Player) !f32 {
        const gain = player.gain_node.get("gain").view(.object);
        defer gain.deinit();
        return @as(f32, @floatCast(gain.get("value").view(.num)));
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
