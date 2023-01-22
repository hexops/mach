const std = @import("std");
const js = @import("sysjs");
const main = @import("main.zig");
const backends = @import("backends.zig");
const util = @import("util.zig");

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

    pub fn init(allocator: std.mem.Allocator, options: main.Context.Options) !backends.BackendContext {
        _ = options;

        const audio_context = js.global().get("AudioContext");
        if (audio_context.is(.undefined))
            return error.ConnectionRefused;

        var self = try allocator.create(Context);
        errdefer allocator.destroy(self);
        self.* = .{
            .allocator = allocator,
            .devices_info = util.DevicesInfo.init(),
        };

        return .{ .webaudio = self };
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

        try self.devices_info.list.append(self.allocator, default_playback);
        self.devices_info.list.items[0].channels = try self.allocator.alloc(main.Channel, 2);
        self.devices_info.list.items[0].channels[0] = .{ .id = .front_left };
        self.devices_info.list.items[0].channels[1] = .{ .id = .front_right };
        self.devices_info.setDefault(.playback, 0);
    }

    pub fn devices(self: Context) []const main.Device {
        return self.devices_info.list.items;
    }

    pub fn defaultDevice(self: Context, mode: main.Device.Mode) ?main.Device {
        return self.devices_info.default(mode);
    }

    pub fn createPlayer(self: *Context, device: main.Device, writeFn: main.WriteFn, options: main.Player.Options) !backends.BackendPlayer {
        const context_options = js.createMap();
        defer context_options.deinit();
        context_options.set("sampleRate", js.createNumber(options.sample_rate));

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

        var player = try self.allocator.create(Player);
        errdefer self.allocator.destroy(player);

        var captures = try self.allocator.alloc(js.Value, 1);
        captures[0] = js.createNumber(@ptrToInt(player));

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
            .allocator = self.allocator,
            .audio_context = audio_context,
            .process_node = process_node,
            .gain_node = gain_node,
            .process_captures = captures,
            .resume_on_click = resume_on_click,
            .buf = try self.allocator.alloc(u8, channel_size_bytes * device.channels.len),
            .buf_js = js.constructType("Uint8Array", &.{js.createNumber(channel_size_bytes)}),
            .is_paused = false,
            .writeFn = writeFn,
            .user_data = options.user_data,
            .channels = device.channels,
            .format = .f32,
            .sample_rate = options.sample_rate,
            .write_step = @sizeOf(f32),
        };

        for (player.channels) |*ch, i| {
            ch.*.ptr = player.buf.ptr + i * channel_size_bytes;
        }

        return .{ .webaudio = player };
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

    channels: []main.Channel,
    format: main.Format,
    sample_rate: u24,
    write_step: u8,

    pub fn deinit(self: *Player) void {
        self.resume_on_click.deinit();
        self.buf_js.deinit();
        self.gain_node.deinit();
        self.process_node.deinit();
        self.audio_context.deinit();
        self.allocator.free(self.process_captures);
        self.allocator.free(self.buf);
        self.allocator.destroy(self);
    }

    pub fn start(self: Player) !void {
        const destination = self.audio_context.get("destination").view(.object);
        defer destination.deinit();
        _ = self.gain_node.call("connect", &.{destination.toValue()});
        _ = self.process_node.call("connect", &.{self.gain_node.toValue()});
    }

    fn resumeOnClick(args: js.Object, _: usize, captures: []js.Value) js.Value {
        const self = @intToPtr(*Player, @floatToInt(usize, captures[0].view(.num)));
        self.play() catch {};

        const document = js.global().get("document").view(.object);
        defer document.deinit();

        const event = args.getIndex(0).view(.object);
        defer event.deinit();
        _ = document.call("removeEventListener", &.{ event.toValue(), self.resume_on_click.toValue() });

        return js.createUndefined();
    }

    fn audioProcessEvent(args: js.Object, _: usize, captures: []js.Value) js.Value {
        const self = @intToPtr(*Player, @floatToInt(usize, captures[0].view(.num)));

        const event = args.getIndex(0).view(.object);
        defer event.deinit();
        const output_buffer = event.get("outputBuffer").view(.object);
        defer output_buffer.deinit();

        self.writeFn(self.user_data, channel_size);

        for (self.channels) |_, i| {
            self.buf_js.copyBytes(self.buf[i * channel_size_bytes .. (i + 1) * channel_size_bytes]);
            const buf_f32_js = js.constructType("Float32Array", &.{ self.buf_js.get("buffer"), self.buf_js.get("byteOffset"), js.createNumber(channel_size) });
            defer buf_f32_js.deinit();
            _ = output_buffer.call("copyToChannel", &.{ buf_f32_js.toValue(), js.createNumber(i) });
        }

        return js.createUndefined();
    }

    pub fn play(self: *Player) !void {
        _ = self.audio_context.call("resume", &.{js.createUndefined()});
        self.is_paused = false;
    }

    pub fn pause(self: *Player) !void {
        _ = self.audio_context.call("suspend", &.{js.createUndefined()});
        self.is_paused = true;
    }

    pub fn paused(self: Player) bool {
        return self.is_paused;
    }

    pub fn setVolume(self: *Player, vol: f32) !void {
        const gain = self.gain_node.get("gain").view(.object);
        defer gain.deinit();
        gain.set("value", js.createNumber(vol));
    }

    pub fn volume(self: Player) !f32 {
        const gain = self.gain_node.get("gain").view(.object);
        defer gain.deinit();
        return @floatCast(f32, gain.get("value").view(.num));
    }
};

fn freeDevice(allocator: std.mem.Allocator, device: main.Device) void {
    allocator.free(device.channels);
}

test {
    std.testing.refAllDeclsRecursive(@This());
}
