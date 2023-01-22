const std = @import("std");
const c = @cImport({
    @cInclude("pipewire/pipewire.h");
    @cInclude("spa/param/audio/format-utils.h");
});
const main = @import("main.zig");
const backends = @import("backends.zig");
const util = @import("util.zig");

const lib = struct {
    var handle: std.DynLib = undefined;

    var pw_init: *const fn ([*c]c_int, [*c][*c][*c]u8) callconv(.C) void = undefined;
    var pw_deinit: *const fn () callconv(.C) void = undefined;
    var pw_thread_loop_new: *const fn ([*c]const u8, [*c]const c.spa_dict) callconv(.C) ?*c.pw_thread_loop = undefined;
    var pw_thread_loop_destroy: *const fn (?*c.pw_thread_loop) callconv(.C) void = undefined;
    var pw_thread_loop_start: *const fn (?*c.pw_thread_loop) callconv(.C) c_int = undefined;
    var pw_thread_loop_stop: *const fn (?*c.pw_thread_loop) callconv(.C) void = undefined;
    var pw_thread_loop_signal: *const fn (?*c.pw_thread_loop, bool) callconv(.C) void = undefined;
    var pw_thread_loop_wait: *const fn (?*c.pw_thread_loop) callconv(.C) void = undefined;
    var pw_thread_loop_lock: *const fn (?*c.pw_thread_loop) callconv(.C) void = undefined;
    var pw_thread_loop_unlock: *const fn (?*c.pw_thread_loop) callconv(.C) void = undefined;
    var pw_thread_loop_get_loop: *const fn (?*c.pw_thread_loop) callconv(.C) [*c]c.pw_loop = undefined;
    var pw_properties_new: *const fn ([*c]const u8, ...) callconv(.C) [*c]c.pw_properties = undefined;
    var pw_stream_new_simple: *const fn ([*c]c.pw_loop, [*c]const u8, [*c]c.pw_properties, [*c]const c.pw_stream_events, ?*anyopaque) callconv(.C) ?*c.pw_stream = undefined;
    var pw_stream_destroy: *const fn (?*c.pw_stream) callconv(.C) void = undefined;
    var pw_stream_connect: *const fn (?*c.pw_stream, c.spa_direction, u32, c.pw_stream_flags, [*c][*c]const c.spa_pod, u32) callconv(.C) c_int = undefined;
    var pw_stream_queue_buffer: *const fn (?*c.pw_stream, [*c]c.pw_buffer) callconv(.C) c_int = undefined;
    var pw_stream_dequeue_buffer: *const fn (?*c.pw_stream) callconv(.C) [*c]c.pw_buffer = undefined;
    var pw_stream_get_state: *const fn (?*c.pw_stream, [*c][*c]const u8) callconv(.C) c.pw_stream_state = undefined;

    pub fn load() !void {
        handle = std.DynLib.openZ("libpipewire-0.3.so") catch return error.LibraryNotFound;

        pw_init = handle.lookup(@TypeOf(pw_init), "pw_init") orelse return error.SymbolLookup;
        pw_deinit = handle.lookup(@TypeOf(pw_deinit), "pw_deinit") orelse return error.SymbolLookup;
        pw_thread_loop_new = handle.lookup(@TypeOf(pw_thread_loop_new), "pw_thread_loop_new") orelse return error.SymbolLookup;
        pw_thread_loop_destroy = handle.lookup(@TypeOf(pw_thread_loop_destroy), "pw_thread_loop_destroy") orelse return error.SymbolLookup;
        pw_thread_loop_start = handle.lookup(@TypeOf(pw_thread_loop_start), "pw_thread_loop_start") orelse return error.SymbolLookup;
        pw_thread_loop_stop = handle.lookup(@TypeOf(pw_thread_loop_stop), "pw_thread_loop_stop") orelse return error.SymbolLookup;
        pw_thread_loop_signal = handle.lookup(@TypeOf(pw_thread_loop_signal), "pw_thread_loop_signal") orelse return error.SymbolLookup;
        pw_thread_loop_wait = handle.lookup(@TypeOf(pw_thread_loop_wait), "pw_thread_loop_wait") orelse return error.SymbolLookup;
        pw_thread_loop_lock = handle.lookup(@TypeOf(pw_thread_loop_lock), "pw_thread_loop_lock") orelse return error.SymbolLookup;
        pw_thread_loop_unlock = handle.lookup(@TypeOf(pw_thread_loop_unlock), "pw_thread_loop_unlock") orelse return error.SymbolLookup;
        pw_thread_loop_get_loop = handle.lookup(@TypeOf(pw_thread_loop_get_loop), "pw_thread_loop_get_loop") orelse return error.SymbolLookup;
        pw_properties_new = handle.lookup(@TypeOf(pw_properties_new), "pw_properties_new") orelse return error.SymbolLookup;
        pw_stream_new_simple = handle.lookup(@TypeOf(pw_stream_new_simple), "pw_stream_new_simple") orelse return error.SymbolLookup;
        pw_stream_destroy = handle.lookup(@TypeOf(pw_stream_destroy), "pw_stream_destroy") orelse return error.SymbolLookup;
        pw_stream_connect = handle.lookup(@TypeOf(pw_stream_connect), "pw_stream_connect") orelse return error.SymbolLookup;
        pw_stream_queue_buffer = handle.lookup(@TypeOf(pw_stream_queue_buffer), "pw_stream_queue_buffer") orelse return error.SymbolLookup;
        pw_stream_dequeue_buffer = handle.lookup(@TypeOf(pw_stream_dequeue_buffer), "pw_stream_dequeue_buffer") orelse return error.SymbolLookup;
        pw_stream_get_state = handle.lookup(@TypeOf(pw_stream_get_state), "pw_stream_get_state") orelse return error.SymbolLookup;
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
        aborted: std.atomic.Atomic(bool),
    };

    pub fn init(allocator: std.mem.Allocator, options: main.Context.Options) !backends.BackendContext {
        try lib.load();

        lib.pw_init(null, null);

        var self = try allocator.create(Context);
        errdefer allocator.destroy(self);
        self.* = .{
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
            //             .aborted = .{ .value = false },
            //         };
            //     } else break :blk null;
            // },
        };

        return .{ .pipewire = self };
    }

    pub fn deinit(self: *Context) void {
        for (self.devices_info.list.items) |d|
            freeDevice(self.allocator, d);
        self.devices_info.list.deinit(self.allocator);
        lib.pw_deinit();
        self.allocator.destroy(self);
        lib.handle.close();
    }

    pub fn refresh(self: *Context) !void {
        for (self.devices_info.list.items) |d|
            freeDevice(self.allocator, d);
        self.devices_info.clear(self.allocator);

        try self.devices_info.list.append(self.allocator, default_playback);
        try self.devices_info.list.append(self.allocator, default_capture);

        self.devices_info.setDefault(.playback, 0);
        self.devices_info.setDefault(.capture, 1);

        self.devices_info.list.items[0].channels = try self.allocator.alloc(main.Channel, 2);
        self.devices_info.list.items[1].channels = try self.allocator.alloc(main.Channel, 2);

        self.devices_info.list.items[0].channels[0] = .{ .id = .front_right };
        self.devices_info.list.items[0].channels[1] = .{ .id = .front_left };
        self.devices_info.list.items[1].channels[0] = .{ .id = .front_right };
        self.devices_info.list.items[1].channels[1] = .{ .id = .front_left };
    }

    pub fn devices(self: Context) []const main.Device {
        return self.devices_info.list.items;
    }

    pub fn defaultDevice(self: Context, mode: main.Device.Mode) ?main.Device {
        return self.devices_info.default(mode);
    }

    const stream_events = c.pw_stream_events{
        .version = c.PW_VERSION_STREAM_EVENTS,
        .process = Player.processCb,
        .destroy = null,
        .state_changed = Player.stateChangedCb,
        .control_info = null,
        .io_changed = null,
        .param_changed = null,
        .add_buffer = null,
        .remove_buffer = null,
        .drained = null,
        .command = null,
        .trigger_done = null,
    };

    pub fn createPlayer(self: *Context, device: main.Device, writeFn: main.WriteFn, options: main.Player.Options) !backends.BackendPlayer {
        const thread = lib.pw_thread_loop_new(device.id, null) orelse return error.SystemResources;

        const media_role = switch (options.media_role) {
            .default => "Screen",
            .game => "Game",
            .music => "Music",
            .movie => "Movie",
            .communication => "Communication",
        };

        var buf: [8]u8 = undefined;
        const audio_rate = std.fmt.bufPrintZ(&buf, "{d}", .{options.sample_rate}) catch unreachable;

        const props = lib.pw_properties_new(
            c.PW_KEY_MEDIA_TYPE,
            "Audio",

            c.PW_KEY_MEDIA_CATEGORY,
            "Playback",

            c.PW_KEY_MEDIA_ROLE,
            media_role.ptr,

            c.PW_KEY_MEDIA_NAME,
            self.app_name.ptr,

            c.PW_KEY_AUDIO_RATE,
            audio_rate.ptr,

            @intToPtr(*allowzero u0, 0),
        );

        var player = try self.allocator.create(Player);
        errdefer self.allocator.destroy(player);

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
            .channels = @intCast(u32, device.channels.len),
            .rate = options.sample_rate,
            .flags = 0,
            .position = undefined,
        };
        var params = [1][*c]c.spa_pod{
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
            .allocator = self.allocator,
            .thread = thread,
            .stream = stream,
            .is_paused = .{ .value = false },
            .vol = 1.0,
            .writeFn = writeFn,
            .user_data = options.user_data,
            .channels = device.channels,
            .format = .f32,
            .sample_rate = options.sample_rate,
            .write_step = main.Format.frameSize(.f32, 2),
        };
        return .{ .pipewire = player };
    }
};

pub const Player = struct {
    allocator: std.mem.Allocator,
    thread: *c.pw_thread_loop,
    stream: *c.pw_stream,
    is_paused: std.atomic.Atomic(bool),
    vol: f32,
    writeFn: main.WriteFn,
    user_data: ?*anyopaque,

    channels: []main.Channel,
    format: main.Format,
    sample_rate: u24,
    write_step: u8,

    pub fn stateChangedCb(self_opaque: ?*anyopaque, old_state: c.pw_stream_state, state: c.pw_stream_state, err: [*c]const u8) callconv(.C) void {
        _ = old_state;
        _ = err;

        var self = @ptrCast(*Player, @alignCast(@alignOf(*Player), self_opaque.?));

        if (state == c.PW_STREAM_STATE_STREAMING or state == c.PW_STREAM_STATE_ERROR) {
            lib.pw_thread_loop_signal(self.thread, false);
        }
    }

    pub fn processCb(self_opaque: ?*anyopaque) callconv(.C) void {
        var self = @ptrCast(*Player, @alignCast(@alignOf(*Player), self_opaque.?));

        const buf = lib.pw_stream_dequeue_buffer(self.stream) orelse unreachable;
        if (buf.*.buffer.*.datas[0].data == null) return;
        defer _ = lib.pw_stream_queue_buffer(self.stream, buf);

        buf.*.buffer.*.datas[0].chunk.*.offset = 0;
        if (self.is_paused.load(.Unordered)) {
            buf.*.buffer.*.datas[0].chunk.*.stride = 0;
            buf.*.buffer.*.datas[0].chunk.*.size = 0;
            return;
        }

        const stride = self.format.frameSize(self.channels.len);
        const n_frames = std.math.min(
            buf.*.requested,
            buf.*.buffer.*.datas[0].maxsize / stride,
        );
        buf.*.buffer.*.datas[0].chunk.*.stride = stride;
        buf.*.buffer.*.datas[0].chunk.*.size = n_frames * stride;

        for (self.channels) |*ch, i| {
            ch.ptr = @ptrCast([*]u8, buf.*.buffer.*.datas[0].data.?) + self.format.frameSize(i);
        }
        self.writeFn(self.user_data, n_frames);
    }

    pub fn deinit(self: *Player) void {
        lib.pw_thread_loop_stop(self.thread);
        lib.pw_thread_loop_destroy(self.thread);
        lib.pw_stream_destroy(self.stream);
        self.allocator.destroy(self);
    }

    pub fn start(self: *Player) !void {
        if (lib.pw_thread_loop_start(self.thread) < 0) return error.SystemResources;

        lib.pw_thread_loop_lock(self.thread);
        lib.pw_thread_loop_wait(self.thread);
        lib.pw_thread_loop_unlock(self.thread);

        if (lib.pw_stream_get_state(self.stream, null) == c.PW_STREAM_STATE_ERROR) {
            return error.CannotPlay;
        }
    }

    pub fn play(self: *Player) !void {
        self.is_paused.store(false, .Unordered);
    }

    pub fn pause(self: *Player) !void {
        self.is_paused.store(true, .Unordered);
    }

    pub fn paused(self: Player) bool {
        return self.is_paused.load(.Unordered);
    }

    pub fn setVolume(self: *Player, vol: f32) !void {
        self.vol = vol;
    }

    pub fn volume(self: Player) !f32 {
        return self.vol;
    }
};

fn freeDevice(allocator: std.mem.Allocator, device: main.Device) void {
    allocator.free(device.channels);
}

extern fn sysaudio_spa_format_audio_raw_build(builder: [*c]c.spa_pod_builder, id: u32, info: [*c]c.spa_audio_info_raw) callconv(.C) [*c]c.spa_pod;

test {
    std.testing.refAllDeclsRecursive(@This());
}
