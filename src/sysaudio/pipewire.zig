const std = @import("std");
const c = @cImport({
    @cInclude("pipewire/pipewire.h");
    @cInclude("spa/param/audio/format-utils.h");
});
const main = @import("main.zig");
const backends = @import("backends.zig");
const util = @import("util.zig");

const default_sample_rate = 44_100; // Hz

var lib: Lib = undefined;
const Lib = struct {
    handle: std.DynLib,

    pw_init: *const fn ([*c]c_int, [*c][*c][*c]u8) callconv(.C) void,
    pw_deinit: *const fn () callconv(.C) void,
    pw_thread_loop_new: *const fn ([*c]const u8, [*c]const c.spa_dict) callconv(.C) ?*c.pw_thread_loop,
    pw_thread_loop_destroy: *const fn (?*c.pw_thread_loop) callconv(.C) void,
    pw_thread_loop_start: *const fn (?*c.pw_thread_loop) callconv(.C) c_int,
    pw_thread_loop_stop: *const fn (?*c.pw_thread_loop) callconv(.C) void,
    pw_thread_loop_signal: *const fn (?*c.pw_thread_loop, bool) callconv(.C) void,
    pw_thread_loop_wait: *const fn (?*c.pw_thread_loop) callconv(.C) void,
    pw_thread_loop_lock: *const fn (?*c.pw_thread_loop) callconv(.C) void,
    pw_thread_loop_unlock: *const fn (?*c.pw_thread_loop) callconv(.C) void,
    pw_thread_loop_get_loop: *const fn (?*c.pw_thread_loop) callconv(.C) [*c]c.pw_loop,
    pw_properties_new: *const fn ([*c]const u8, ...) callconv(.C) [*c]c.pw_properties,
    pw_stream_new_simple: *const fn ([*c]c.pw_loop, [*c]const u8, [*c]c.pw_properties, [*c]const c.pw_stream_events, ?*anyopaque) callconv(.C) ?*c.pw_stream,
    pw_stream_destroy: *const fn (?*c.pw_stream) callconv(.C) void,
    pw_stream_connect: *const fn (?*c.pw_stream, c.spa_direction, u32, c.pw_stream_flags, [*c][*c]const c.spa_pod, u32) callconv(.C) c_int,
    pw_stream_queue_buffer: *const fn (?*c.pw_stream, [*c]c.pw_buffer) callconv(.C) c_int,
    pw_stream_dequeue_buffer: *const fn (?*c.pw_stream) callconv(.C) [*c]c.pw_buffer,
    pw_stream_get_state: *const fn (?*c.pw_stream, [*c][*c]const u8) callconv(.C) c.pw_stream_state,

    pub fn load() !void {
        lib.handle = std.DynLib.open("libpipewire-0.3.so") catch return error.LibraryNotFound;
        inline for (@typeInfo(Lib).@"struct".fields[1..]) |field| {
            const name = std.fmt.comptimePrint("{s}\x00", .{field.name});
            const name_z: [:0]const u8 = @ptrCast(name[0 .. name.len - 1]);
            @field(lib, field.name) = lib.handle.lookup(field.type, name_z) orelse return error.SymbolLookup;
        }
    }
};

const default_playback = main.Device{
    .id = "default-playback",
    .name = "Default Device",
    .mode = .playback,
    .channels = undefined,
    .formats = std.meta.tags(main.Format),
    .sample_rate = .{
        .min = main.min_sample_rate,
        .max = main.max_sample_rate,
    },
};

const default_capture = main.Device{
    .id = "default-capture",
    .name = "Default Device",
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
    app_name: [:0]const u8,
    // watcher: ?Watcher,

    const Watcher = struct {
        deviceChangeFn: main.Context.DeviceChangeFn,
        user_data: ?*anyopaque,
        thread: *c.pw_thread_loop,
        aborted: std.atomic.Value(bool),
    };

    pub fn init(allocator: std.mem.Allocator, options: main.Context.Options) !backends.Context {
        try Lib.load();

        lib.pw_init(null, null);

        const ctx = try allocator.create(Context);
        errdefer allocator.destroy(ctx);
        ctx.* = .{
            .allocator = allocator,
            .devices_info = util.DevicesInfo.init(),
            .app_name = options.app_name,
            // TODO: device change watcher
            // .watcher = blk: {
            //     if (options.deviceChangeFn != null) {
            //         const thread = c.pw_thread_loop_new("device-change-watcher", null) orelse return error.SystemResources;
            //         const context = c.pw_context_new(c.pw_thread_loop_get_loop(thread), null, 0);
            //         const core = c.pw_context_connect(context, null, 0);
            //         const registry = c.pw_core_get_registry(core, c.PW_VERSION_REGISTRY, 0);
            //         _ = c.spa_zero(registry);

            //         var registry_listener: c.spa_hook = undefined;
            //         _ = c.pw_registry_add_listener(registry, registry_listener);

            //         break :blk .{
            //             .deviceChangeFn = options.deviceChangeFn.?,
            //             .user_data = options.user_data,
            //             .thread = thread,
            //             .aborted = .{ .raw = false },
            //         };
            //     } else break :blk null;
            // },
        };

        return .{ .pipewire = ctx };
    }

    pub fn deinit(ctx: *Context) void {
        for (ctx.devices_info.list.items) |d|
            freeDevice(ctx.allocator, d);
        ctx.devices_info.list.deinit(ctx.allocator);
        lib.pw_deinit();
        ctx.allocator.destroy(ctx);
        lib.handle.close();
    }

    pub fn refresh(ctx: *Context) !void {
        for (ctx.devices_info.list.items) |d|
            freeDevice(ctx.allocator, d);
        ctx.devices_info.clear();

        try ctx.devices_info.list.append(ctx.allocator, default_playback);
        try ctx.devices_info.list.append(ctx.allocator, default_capture);

        ctx.devices_info.setDefault(.playback, 0);
        ctx.devices_info.setDefault(.capture, 1);

        ctx.devices_info.list.items[0].channels = try ctx.allocator.alloc(main.ChannelPosition, 2);
        ctx.devices_info.list.items[1].channels = try ctx.allocator.alloc(main.ChannelPosition, 2);

        ctx.devices_info.list.items[0].channels[0] = .front_right;
        ctx.devices_info.list.items[0].channels[1] = .front_left;
        ctx.devices_info.list.items[1].channels[0] = .front_right;
        ctx.devices_info.list.items[1].channels[1] = .front_left;
    }

    pub fn devices(ctx: Context) []const main.Device {
        return ctx.devices_info.list.items;
    }

    pub fn defaultDevice(ctx: Context, mode: main.Device.Mode) ?main.Device {
        return ctx.devices_info.default(mode);
    }

    pub fn createPlayer(ctx: *Context, device: main.Device, writeFn: main.WriteFn, options: main.StreamOptions) !backends.Player {
        const media_role = switch (options.media_role) {
            .default => "Screen",
            .game => "Game",
            .music => "Music",
            .movie => "Movie",
            .communication => "Communication",
        };

        var buf: [8]u8 = undefined;
        const audio_rate = std.fmt.bufPrintZ(&buf, "{d}", .{options.sample_rate orelse default_sample_rate}) catch unreachable;

        const props = lib.pw_properties_new(
            c.PW_KEY_MEDIA_TYPE,
            "Audio",

            c.PW_KEY_MEDIA_CATEGORY,
            "Playback",

            c.PW_KEY_MEDIA_ROLE,
            media_role.ptr,

            c.PW_KEY_MEDIA_NAME,
            ctx.app_name.ptr,

            c.PW_KEY_AUDIO_RATE,
            audio_rate.ptr,

            @as(*allowzero u0, @ptrFromInt(0)),
        );

        const stream_events = c.pw_stream_events{
            .version = c.PW_VERSION_STREAM_EVENTS,
            .process = Player.processCb,
            .destroy = null,
            .state_changed = stateChangedCb,
            .control_info = null,
            .io_changed = null,
            .param_changed = null,
            .add_buffer = null,
            .remove_buffer = null,
            .drained = null,
            .command = null,
            .trigger_done = null,
        };

        const player = try ctx.allocator.create(Player);
        errdefer ctx.allocator.destroy(player);

        const thread = lib.pw_thread_loop_new(device.id, null) orelse return error.SystemResources;
        const stream = lib.pw_stream_new_simple(
            lib.pw_thread_loop_get_loop(thread),
            "audio-src",
            props,
            &stream_events,
            player,
        ) orelse return error.OpeningDevice;

        var builder_buf: [256]u8 = undefined;
        var pod_builder = c.spa_pod_builder{
            .data = &builder_buf,
            .size = builder_buf.len,
            ._padding = 0,
            .state = .{
                .offset = 0,
                .flags = 0,
                .frame = null,
            },
            .callbacks = .{ .funcs = null, .data = null },
        };
        var info = c.spa_audio_info_raw{
            .format = c.SPA_AUDIO_FORMAT_F32,
            .channels = @as(u32, @intCast(device.channels.len)),
            .rate = options.sample_rate orelse default_sample_rate,
            .flags = 0,
            .position = undefined,
        };
        var params = [1][*c]const c.spa_pod{
            sysaudio_spa_format_audio_raw_build(&pod_builder, c.SPA_PARAM_EnumFormat, &info),
        };

        if (lib.pw_stream_connect(
            stream,
            c.PW_DIRECTION_OUTPUT,
            c.PW_ID_ANY,
            c.PW_STREAM_FLAG_AUTOCONNECT | c.PW_STREAM_FLAG_MAP_BUFFERS | c.PW_STREAM_FLAG_RT_PROCESS,
            &params,
            params.len,
        ) < 0) return error.OpeningDevice;

        player.* = .{
            .allocator = ctx.allocator,
            .thread = thread,
            .stream = stream,
            .is_paused = .{ .raw = false },
            .vol = 1.0,
            .writeFn = writeFn,
            .user_data = options.user_data,
            .channels = device.channels,
            .format = .f32,
            .sample_rate = options.sample_rate orelse default_sample_rate,
        };
        return .{ .pipewire = player };
    }

    pub fn createRecorder(ctx: *Context, device: main.Device, readFn: main.ReadFn, options: main.StreamOptions) !backends.Recorder {
        const media_role = switch (options.media_role) {
            .default => "Screen",
            .game => "Game",
            .music => "Music",
            .movie => "Movie",
            .communication => "Communication",
        };

        var buf: [8]u8 = undefined;
        const audio_rate = std.fmt.bufPrintZ(&buf, "{d}", .{options.sample_rate orelse default_sample_rate}) catch unreachable;

        const props = lib.pw_properties_new(
            c.PW_KEY_MEDIA_TYPE,
            "Audio",

            c.PW_KEY_MEDIA_CATEGORY,
            "Capture",

            c.PW_KEY_MEDIA_ROLE,
            media_role.ptr,

            c.PW_KEY_MEDIA_NAME,
            ctx.app_name.ptr,

            c.PW_KEY_AUDIO_RATE,
            audio_rate.ptr,

            @as(*allowzero u0, @ptrFromInt(0)),
        );

        const stream_events = c.pw_stream_events{
            .version = c.PW_VERSION_STREAM_EVENTS,
            .process = Recorder.processCb,
            .destroy = null,
            .state_changed = stateChangedCb,
            .control_info = null,
            .io_changed = null,
            .param_changed = null,
            .add_buffer = null,
            .remove_buffer = null,
            .drained = null,
            .command = null,
            .trigger_done = null,
        };

        const recorder = try ctx.allocator.create(Recorder);
        errdefer ctx.allocator.destroy(recorder);

        const thread = lib.pw_thread_loop_new(device.id, null) orelse return error.SystemResources;
        const stream = lib.pw_stream_new_simple(
            lib.pw_thread_loop_get_loop(thread),
            "audio-capture",
            props,
            &stream_events,
            recorder,
        ) orelse return error.OpeningDevice;

        var builder_buf: [256]u8 = undefined;
        var pod_builder = c.spa_pod_builder{
            .data = &builder_buf,
            .size = builder_buf.len,
            ._padding = 0,
            .state = .{
                .offset = 0,
                .flags = 0,
                .frame = null,
            },
            .callbacks = .{ .funcs = null, .data = null },
        };
        var info = c.spa_audio_info_raw{
            .format = c.SPA_AUDIO_FORMAT_F32,
            .channels = @as(u32, @intCast(device.channels.len)),
            .rate = options.sample_rate orelse default_sample_rate,
            .flags = 0,
            .position = undefined,
        };
        var params = [1][*c]c.spa_pod{
            sysaudio_spa_format_audio_raw_build(&pod_builder, c.SPA_PARAM_EnumFormat, &info),
        };

        if (lib.pw_stream_connect(
            stream,
            c.PW_DIRECTION_INPUT,
            c.PW_ID_ANY,
            c.PW_STREAM_FLAG_AUTOCONNECT | c.PW_STREAM_FLAG_MAP_BUFFERS | c.PW_STREAM_FLAG_RT_PROCESS,
            &params,
            params.len,
        ) < 0) return error.OpeningDevice;

        recorder.* = .{
            .allocator = ctx.allocator,
            .thread = thread,
            .stream = stream,
            .is_paused = .{ .raw = false },
            .vol = 1.0,
            .readFn = readFn,
            .user_data = options.user_data,
            .channels = device.channels,
            .format = .f32,
            .sample_rate = options.sample_rate orelse default_sample_rate,
        };
        return .{ .pipewire = recorder };
    }
};

fn stateChangedCb(player_opaque: ?*anyopaque, old_state: c.pw_stream_state, state: c.pw_stream_state, err: [*c]const u8) callconv(.C) void {
    _ = old_state;
    _ = err;

    const player = @as(*Player, @ptrCast(@alignCast(player_opaque.?)));

    if (state == c.PW_STREAM_STATE_STREAMING or state == c.PW_STREAM_STATE_ERROR) {
        lib.pw_thread_loop_signal(player.thread, false);
    }
}

pub const Player = struct {
    allocator: std.mem.Allocator,
    thread: *c.pw_thread_loop,
    stream: *c.pw_stream,
    is_paused: std.atomic.Value(bool),
    vol: f32,
    writeFn: main.WriteFn,
    user_data: ?*anyopaque,

    channels: []main.ChannelPosition,
    format: main.Format,
    sample_rate: u24,

    pub fn processCb(player_opaque: ?*anyopaque) callconv(.C) void {
        var player = @as(*Player, @ptrCast(@alignCast(player_opaque.?)));

        const buf = lib.pw_stream_dequeue_buffer(player.stream) orelse return;
        if (buf.*.buffer.*.datas[0].data == null) return;
        defer _ = lib.pw_stream_queue_buffer(player.stream, buf);

        buf.*.buffer.*.datas[0].chunk.*.offset = 0;
        if (player.is_paused.load(.unordered)) {
            buf.*.buffer.*.datas[0].chunk.*.stride = 0;
            buf.*.buffer.*.datas[0].chunk.*.size = 0;
            return;
        }

        const stride = player.format.frameSize(@intCast(player.channels.len));
        const frames = @min(buf.*.requested * stride, buf.*.buffer.*.datas[0].maxsize);
        buf.*.buffer.*.datas[0].chunk.*.stride = stride;
        buf.*.buffer.*.datas[0].chunk.*.size = @intCast(frames);

        player.writeFn(player.user_data, @as([*]u8, @ptrCast(buf.*.buffer.*.datas[0].data.?))[0..frames]);
    }

    pub fn deinit(player: *Player) void {
        lib.pw_thread_loop_stop(player.thread);
        lib.pw_thread_loop_destroy(player.thread);
        lib.pw_stream_destroy(player.stream);
        player.allocator.destroy(player);
    }

    pub fn start(player: *Player) !void {
        if (lib.pw_thread_loop_start(player.thread) < 0) return error.SystemResources;

        lib.pw_thread_loop_lock(player.thread);
        lib.pw_thread_loop_wait(player.thread);
        lib.pw_thread_loop_unlock(player.thread);

        if (lib.pw_stream_get_state(player.stream, null) == c.PW_STREAM_STATE_ERROR) {
            return error.CannotPlay;
        }
    }

    pub fn play(player: *Player) !void {
        player.is_paused.store(false, .unordered);
    }

    pub fn pause(player: *Player) !void {
        player.is_paused.store(true, .unordered);
    }

    pub fn paused(player: *Player) bool {
        return player.is_paused.load(.unordered);
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
    thread: *c.pw_thread_loop,
    stream: *c.pw_stream,
    is_paused: std.atomic.Value(bool),
    vol: f32,
    readFn: main.ReadFn,
    user_data: ?*anyopaque,

    channels: []main.ChannelPosition,
    format: main.Format,
    sample_rate: u24,

    pub fn processCb(recorder_opaque: ?*anyopaque) callconv(.C) void {
        var recorder = @as(*Recorder, @ptrCast(@alignCast(recorder_opaque.?)));

        const buf = lib.pw_stream_dequeue_buffer(recorder.stream) orelse return;
        if (buf.*.buffer.*.datas[0].data == null) return;
        defer _ = lib.pw_stream_queue_buffer(recorder.stream, buf);

        buf.*.buffer.*.datas[0].chunk.*.offset = 0;
        if (recorder.is_paused.load(.unordered)) {
            buf.*.buffer.*.datas[0].chunk.*.stride = 0;
            buf.*.buffer.*.datas[0].chunk.*.size = 0;
            return;
        }

        const frames = buf.*.buffer.*.datas[0].chunk.*.size;
        recorder.readFn(recorder.user_data, @as([*]u8, @ptrCast(buf.*.buffer.*.datas[0].data.?))[0..frames]);
    }

    pub fn deinit(recorder: *Recorder) void {
        lib.pw_thread_loop_stop(recorder.thread);
        lib.pw_thread_loop_destroy(recorder.thread);
        lib.pw_stream_destroy(recorder.stream);
        recorder.allocator.destroy(recorder);
    }

    pub fn start(recorder: *Recorder) !void {
        if (lib.pw_thread_loop_start(recorder.thread) < 0) return error.SystemResources;

        lib.pw_thread_loop_lock(recorder.thread);
        lib.pw_thread_loop_wait(recorder.thread);
        lib.pw_thread_loop_unlock(recorder.thread);

        if (lib.pw_stream_get_state(recorder.stream, null) == c.PW_STREAM_STATE_ERROR) {
            return error.CannotRecord;
        }
    }

    pub fn record(recorder: *Recorder) !void {
        recorder.is_paused.store(false, .unordered);
    }

    pub fn pause(recorder: *Recorder) !void {
        recorder.is_paused.store(true, .unordered);
    }

    pub fn paused(recorder: *Recorder) bool {
        return recorder.is_paused.load(.unordered);
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

extern fn sysaudio_spa_format_audio_raw_build(builder: [*c]c.spa_pod_builder, id: u32, info: [*c]c.spa_audio_info_raw) callconv(.C) [*c]c.spa_pod;
