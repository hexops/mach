const std = @import("std");
const c = @cImport(@cInclude("pulse/pulseaudio.h"));
const main = @import("main.zig");
const backends = @import("backends.zig");
const util = @import("util.zig");
const is_little = @import("builtin").cpu.arch.endian() == .little;

const default_sample_rate = 44_100; // Hz

var lib: Lib = undefined;
const Lib = struct {
    handle: std.DynLib,

    pa_threaded_mainloop_new: *const fn () callconv(.C) ?*c.pa_threaded_mainloop,
    pa_threaded_mainloop_free: *const fn (?*c.pa_threaded_mainloop) callconv(.C) void,
    pa_threaded_mainloop_start: *const fn (?*c.pa_threaded_mainloop) callconv(.C) c_int,
    pa_threaded_mainloop_stop: *const fn (?*c.pa_threaded_mainloop) callconv(.C) void,
    pa_threaded_mainloop_signal: *const fn (?*c.pa_threaded_mainloop, c_int) callconv(.C) void,
    pa_threaded_mainloop_wait: *const fn (?*c.pa_threaded_mainloop) callconv(.C) void,
    pa_threaded_mainloop_lock: *const fn (?*c.pa_threaded_mainloop) callconv(.C) void,
    pa_threaded_mainloop_unlock: *const fn (?*c.pa_threaded_mainloop) callconv(.C) void,
    pa_threaded_mainloop_get_api: *const fn (?*c.pa_threaded_mainloop) callconv(.C) [*c]c.pa_mainloop_api,
    pa_operation_unref: *const fn (?*c.pa_operation) callconv(.C) void,
    pa_operation_get_state: *const fn (?*const c.pa_operation) callconv(.C) c.pa_operation_state_t,
    pa_context_new_with_proplist: *const fn ([*c]c.pa_mainloop_api, [*c]const u8, ?*const c.pa_proplist) callconv(.C) ?*c.pa_context,
    pa_context_unref: *const fn (?*c.pa_context) callconv(.C) void,
    pa_context_connect: *const fn (?*c.pa_context, [*c]const u8, c.pa_context_flags_t, [*c]const c.pa_spawn_api) callconv(.C) c_int,
    pa_context_disconnect: *const fn (?*c.pa_context) callconv(.C) void,
    pa_context_subscribe: *const fn (?*c.pa_context, c.pa_subscription_mask_t, c.pa_context_success_cb_t, ?*anyopaque) callconv(.C) ?*c.pa_operation,
    pa_context_get_state: *const fn (?*const c.pa_context) callconv(.C) c.pa_context_state_t,
    pa_context_set_state_callback: *const fn (?*c.pa_context, c.pa_context_notify_cb_t, ?*anyopaque) callconv(.C) void,
    pa_context_set_subscribe_callback: *const fn (?*c.pa_context, c.pa_context_subscribe_cb_t, ?*anyopaque) callconv(.C) void,
    pa_context_get_sink_input_info: *const fn (?*c.pa_context, u32, c.pa_sink_input_info_cb_t, ?*anyopaque) callconv(.C) ?*c.pa_operation,
    pa_context_get_sink_info_list: *const fn (?*c.pa_context, c.pa_sink_info_cb_t, ?*anyopaque) callconv(.C) ?*c.pa_operation,
    pa_context_set_sink_input_volume: *const fn (?*c.pa_context, u32, [*c]const c.pa_cvolume, c.pa_context_success_cb_t, ?*anyopaque) callconv(.C) ?*c.pa_operation,
    pa_context_get_source_info_list: *const fn (?*c.pa_context, c.pa_source_info_cb_t, ?*anyopaque) callconv(.C) ?*c.pa_operation,
    pa_context_get_server_info: *const fn (?*c.pa_context, c.pa_server_info_cb_t, ?*anyopaque) callconv(.C) ?*c.pa_operation,
    pa_stream_new: *const fn (?*c.pa_context, [*c]const u8, [*c]const c.pa_sample_spec, [*c]const c.pa_channel_map) callconv(.C) ?*c.pa_stream,
    pa_stream_unref: *const fn (?*c.pa_stream) callconv(.C) void,
    pa_stream_connect_playback: *const fn (?*c.pa_stream, [*c]const u8, [*c]const c.pa_buffer_attr, c.pa_stream_flags_t, [*c]const c.pa_cvolume, ?*c.pa_stream) callconv(.C) c_int,
    pa_stream_connect_record: *const fn (?*c.pa_stream, [*c]const u8, [*c]const c.pa_buffer_attr, c.pa_stream_flags_t) callconv(.C) c_int,
    pa_stream_disconnect: *const fn (?*c.pa_stream) callconv(.C) c_int,
    pa_stream_cork: *const fn (?*c.pa_stream, c_int, c.pa_stream_success_cb_t, ?*anyopaque) callconv(.C) ?*c.pa_operation,
    pa_stream_is_corked: *const fn (?*const c.pa_stream) callconv(.C) c_int,
    pa_stream_begin_write: *const fn (?*c.pa_stream, [*c]?*anyopaque, [*c]usize) callconv(.C) c_int,
    pa_stream_peek: *const fn (?*c.pa_stream, [*c]?*anyopaque, [*c]usize) callconv(.C) c_int,
    pa_stream_drop: *const fn (?*c.pa_stream) callconv(.C) c_int,
    pa_stream_write: *const fn (?*c.pa_stream, ?*const anyopaque, usize, c.pa_free_cb_t, i64, c.pa_seek_mode_t) callconv(.C) c_int,
    pa_stream_get_state: *const fn (?*const c.pa_stream) callconv(.C) c.pa_stream_state_t,
    pa_stream_get_index: *const fn (?*const c.pa_stream) callconv(.C) u32,
    pa_stream_set_state_callback: *const fn (?*c.pa_stream, c.pa_stream_notify_cb_t, ?*anyopaque) callconv(.C) void,
    pa_stream_set_read_callback: *const fn (?*c.pa_stream, c.pa_stream_request_cb_t, ?*anyopaque) callconv(.C) void,
    pa_stream_set_write_callback: *const fn (?*c.pa_stream, c.pa_stream_request_cb_t, ?*anyopaque) callconv(.C) void,
    pa_stream_set_underflow_callback: *const fn (?*c.pa_stream, c.pa_stream_notify_cb_t, ?*anyopaque) callconv(.C) void,
    pa_stream_set_overflow_callback: *const fn (?*c.pa_stream, c.pa_stream_notify_cb_t, ?*anyopaque) callconv(.C) void,
    pa_cvolume_init: *const fn ([*c]c.pa_cvolume) callconv(.C) [*c]c.pa_cvolume,
    pa_cvolume_set: *const fn ([*c]c.pa_cvolume, c_uint, c.pa_volume_t) callconv(.C) [*c]c.pa_cvolume,
    pa_sw_volume_from_linear: *const fn (f64) callconv(.C) c.pa_volume_t,

    pa_usec_to_bytes: *const fn (t: c.pa_usec_t, spec: [*c]const c.pa_sample_spec) usize,
    pa_stream_get_sample_spec: *const fn (s: ?*c.pa_stream) [*c]const c.pa_sample_spec,

    pub fn load() !void {
        lib.handle = std.DynLib.open("libpulse.so") catch return error.LibraryNotFound;
        inline for (@typeInfo(Lib).Struct.fields[1..]) |field| {
            const name = std.fmt.comptimePrint("{s}\x00", .{field.name});
            const name_z: [:0]const u8 = @ptrCast(name[0 .. name.len - 1]);
            @field(lib, field.name) = lib.handle.lookup(field.type, name_z) orelse return error.SymbolLookup;
        }
    }
};

pub const Context = struct {
    allocator: std.mem.Allocator,
    devices_info: util.DevicesInfo,
    app_name: [:0]const u8,
    main_loop: *c.pa_threaded_mainloop,
    pulse_ctx: *c.pa_context,
    pulse_ctx_state: c.pa_context_state_t,
    default_sink: ?[:0]const u8,
    default_source: ?[:0]const u8,
    watcher: ?Watcher,

    const Watcher = struct {
        deviceChangeFn: main.Context.DeviceChangeFn,
        user_data: ?*anyopaque,
    };

    pub fn init(allocator: std.mem.Allocator, options: main.Context.Options) !backends.Context {
        try Lib.load();

        const main_loop = lib.pa_threaded_mainloop_new() orelse
            return error.OutOfMemory;
        errdefer lib.pa_threaded_mainloop_free(main_loop);
        const main_loop_api = lib.pa_threaded_mainloop_get_api(main_loop);

        const pulse_ctx = lib.pa_context_new_with_proplist(main_loop_api, options.app_name.ptr, null) orelse
            return error.OutOfMemory;
        errdefer lib.pa_context_unref(pulse_ctx);

        const ctx = try allocator.create(Context);
        errdefer allocator.destroy(ctx);
        ctx.* = Context{
            .allocator = allocator,
            .devices_info = util.DevicesInfo.init(),
            .app_name = options.app_name,
            .main_loop = main_loop,
            .pulse_ctx = pulse_ctx,
            .pulse_ctx_state = c.PA_CONTEXT_UNCONNECTED,
            .default_sink = null,
            .default_source = null,
            .watcher = if (options.deviceChangeFn) |dcf| .{
                .deviceChangeFn = dcf,
                .user_data = options.user_data,
            } else null,
        };

        if (lib.pa_context_connect(pulse_ctx, null, 0, null) != 0)
            return error.ConnectionRefused;
        errdefer lib.pa_context_disconnect(pulse_ctx);
        lib.pa_context_set_state_callback(pulse_ctx, contextStateOp, ctx);

        if (lib.pa_threaded_mainloop_start(main_loop) != 0)
            return error.SystemResources;
        errdefer lib.pa_threaded_mainloop_stop(main_loop);

        lib.pa_threaded_mainloop_lock(main_loop);
        defer lib.pa_threaded_mainloop_unlock(main_loop);

        while (true) {
            switch (ctx.pulse_ctx_state) {
                // The context hasn't been connected yet.
                c.PA_CONTEXT_UNCONNECTED,
                // A connection is being established.
                c.PA_CONTEXT_CONNECTING,
                // The client is authorizing itself to the daemon.
                c.PA_CONTEXT_AUTHORIZING,
                // The client is passing its application name to the daemon.
                c.PA_CONTEXT_SETTING_NAME,
                => lib.pa_threaded_mainloop_wait(main_loop),

                // The connection is established, the context is ready to execute operations.
                c.PA_CONTEXT_READY => break,

                // The connection was terminated cleanly.
                c.PA_CONTEXT_TERMINATED,
                // The connection failed or was disconnected.
                c.PA_CONTEXT_FAILED,
                => return error.ConnectionRefused,

                else => unreachable,
            }
        }

        // subscribe to events
        if (options.deviceChangeFn != null) {
            lib.pa_context_set_subscribe_callback(pulse_ctx, subscribeOp, ctx);
            const events = c.PA_SUBSCRIPTION_MASK_SINK | c.PA_SUBSCRIPTION_MASK_SOURCE;
            const subscribe_op = lib.pa_context_subscribe(pulse_ctx, events, null, ctx) orelse
                return error.OutOfMemory;
            lib.pa_operation_unref(subscribe_op);
        }

        return .{ .pulseaudio = ctx };
    }

    fn subscribeOp(_: ?*c.pa_context, _: c.pa_subscription_event_type_t, _: u32, ctx_opaque: ?*anyopaque) callconv(.C) void {
        var ctx = @as(*Context, @ptrCast(@alignCast(ctx_opaque.?)));
        ctx.watcher.?.deviceChangeFn(ctx.watcher.?.user_data);
    }

    fn contextStateOp(pulse_ctx: ?*c.pa_context, ctx_opaque: ?*anyopaque) callconv(.C) void {
        var ctx = @as(*Context, @ptrCast(@alignCast(ctx_opaque.?)));

        ctx.pulse_ctx_state = lib.pa_context_get_state(pulse_ctx);
        lib.pa_threaded_mainloop_signal(ctx.main_loop, 0);
    }

    pub fn deinit(ctx: *Context) void {
        lib.pa_context_set_subscribe_callback(ctx.pulse_ctx, null, null);
        lib.pa_context_set_state_callback(ctx.pulse_ctx, null, null);
        lib.pa_context_disconnect(ctx.pulse_ctx);
        lib.pa_context_unref(ctx.pulse_ctx);
        lib.pa_threaded_mainloop_stop(ctx.main_loop);
        lib.pa_threaded_mainloop_free(ctx.main_loop);
        for (ctx.devices_info.list.items) |d|
            freeDevice(ctx.allocator, d);
        ctx.devices_info.list.deinit(ctx.allocator);
        ctx.allocator.destroy(ctx);
        lib.handle.close();
    }

    pub fn refresh(ctx: *Context) !void {
        lib.pa_threaded_mainloop_lock(ctx.main_loop);
        defer lib.pa_threaded_mainloop_unlock(ctx.main_loop);

        for (ctx.devices_info.list.items) |d|
            freeDevice(ctx.allocator, d);
        ctx.devices_info.clear();

        const list_sink_op = lib.pa_context_get_sink_info_list(ctx.pulse_ctx, sinkInfoOp, ctx);
        const list_source_op = lib.pa_context_get_source_info_list(ctx.pulse_ctx, sourceInfoOp, ctx);
        const server_info_op = lib.pa_context_get_server_info(ctx.pulse_ctx, serverInfoOp, ctx);

        performOperation(ctx.main_loop, list_sink_op);
        performOperation(ctx.main_loop, list_source_op);
        performOperation(ctx.main_loop, server_info_op);

        defer {
            if (ctx.default_sink) |d|
                ctx.allocator.free(d);
            if (ctx.default_source) |d|
                ctx.allocator.free(d);
        }
        for (ctx.devices_info.list.items, 0..) |device, i| {
            if ((device.mode == .playback and
                ctx.default_sink != null and
                std.mem.eql(u8, device.id, ctx.default_sink.?)) or
                //
                (device.mode == .capture and
                ctx.default_source != null and
                std.mem.eql(u8, device.id, ctx.default_source.?)))
            {
                ctx.devices_info.setDefault(device.mode, i);
                break;
            }
        }
    }

    fn serverInfoOp(_: ?*c.pa_context, info: [*c]const c.pa_server_info, user_data: ?*anyopaque) callconv(.C) void {
        var ctx = @as(*Context, @ptrCast(@alignCast(user_data.?)));

        defer lib.pa_threaded_mainloop_signal(ctx.main_loop, 0);
        ctx.default_sink = ctx.allocator.dupeZ(u8, std.mem.span(info.*.default_sink_name)) catch return;
        ctx.default_source = ctx.allocator.dupeZ(u8, std.mem.span(info.*.default_source_name)) catch {
            ctx.allocator.free(ctx.default_sink.?);
            return;
        };
    }

    fn sinkInfoOp(_: ?*c.pa_context, info: [*c]const c.pa_sink_info, eol: c_int, user_data: ?*anyopaque) callconv(.C) void {
        var ctx = @as(*Context, @ptrCast(@alignCast(user_data.?)));
        if (eol != 0) {
            lib.pa_threaded_mainloop_signal(ctx.main_loop, 0);
            return;
        }

        ctx.deviceInfoOp(info, .playback) catch return;
    }

    fn sourceInfoOp(_: ?*c.pa_context, info: [*c]const c.pa_source_info, eol: c_int, user_data: ?*anyopaque) callconv(.C) void {
        var ctx = @as(*Context, @ptrCast(@alignCast(user_data.?)));
        if (eol != 0) {
            lib.pa_threaded_mainloop_signal(ctx.main_loop, 0);
            return;
        }

        ctx.deviceInfoOp(info, .capture) catch return;
    }

    fn deviceInfoOp(ctx: *Context, info: anytype, mode: main.Device.Mode) !void {
        const id = try ctx.allocator.dupeZ(u8, std.mem.span(info.*.name));
        errdefer ctx.allocator.free(id);
        const name = try ctx.allocator.dupeZ(u8, std.mem.span(info.*.description));
        errdefer ctx.allocator.free(name);

        const device = main.Device{
            .mode = mode,
            .channels = blk: {
                const channels = try ctx.allocator.alloc(main.ChannelPosition, info.*.channel_map.channels);
                for (channels, 0..) |*ch, i| ch.* = try fromPAChannelPos(info.*.channel_map.map[i]);
                break :blk channels;
            },
            .formats = available_formats,
            .sample_rate = .{
                .min = @as(u24, @intCast(info.*.sample_spec.rate)),
                .max = @as(u24, @intCast(info.*.sample_spec.rate)),
            },
            .id = id,
            .name = name,
        };

        try ctx.devices_info.list.append(ctx.allocator, device);
    }

    pub fn devices(ctx: Context) []const main.Device {
        return ctx.devices_info.list.items;
    }

    pub fn defaultDevice(ctx: Context, mode: main.Device.Mode) ?main.Device {
        return ctx.devices_info.default(mode);
    }

    pub fn createPlayer(ctx: *Context, device: main.Device, writeFn: main.WriteFn, options: main.StreamOptions) !backends.Player {
        lib.pa_threaded_mainloop_lock(ctx.main_loop);
        defer lib.pa_threaded_mainloop_unlock(ctx.main_loop);

        const format = device.preferredFormat(options.format);
        const sample_rate = device.sample_rate.clamp(options.sample_rate orelse default_sample_rate);

        const sample_spec = c.pa_sample_spec{
            .format = toPAFormat(format),
            .rate = sample_rate,
            .channels = @as(u5, @intCast(device.channels.len)),
        };

        const channel_map = try toPAChannelMap(device.channels);

        const stream = lib.pa_stream_new(ctx.pulse_ctx, ctx.app_name.ptr, &sample_spec, &channel_map);
        if (stream == null)
            return error.OutOfMemory;
        errdefer lib.pa_stream_unref(stream);

        var status: StreamStatus = .{ .main_loop = ctx.main_loop, .status = .unknown };
        lib.pa_stream_set_state_callback(stream, streamStateOp, &status);

        const buffer_len = lib.pa_usec_to_bytes(main.default_latency, lib.pa_stream_get_sample_spec(stream));
        const buf_attr = c.pa_buffer_attr{
            .maxlength = std.math.maxInt(u32),
            .tlength = @intCast(buffer_len),
            .prebuf = 0,
            .minreq = std.math.maxInt(u32),
            .fragsize = std.math.maxInt(u32),
        };

        const flags =
            c.PA_STREAM_START_CORKED |
            c.PA_STREAM_AUTO_TIMING_UPDATE |
            c.PA_STREAM_INTERPOLATE_TIMING;

        if (lib.pa_stream_connect_playback(stream, device.id.ptr, &buf_attr, flags, null, null) != 0) {
            return error.OpeningDevice;
        }
        errdefer _ = lib.pa_stream_disconnect(stream);

        while (true) {
            switch (status.status) {
                .unknown => lib.pa_threaded_mainloop_wait(ctx.main_loop),
                .ready => break,
                .failure => return error.OpeningDevice,
            }
        }

        const player = try ctx.allocator.create(Player);
        player.* = .{
            .allocator = ctx.allocator,
            .main_loop = ctx.main_loop,
            .pulse_ctx = ctx.pulse_ctx,
            .stream = stream.?,
            .write_ptr = undefined,
            .vol = 1.0,
            .writeFn = writeFn,
            .user_data = options.user_data,
            .channels = device.channels,
            .format = format,
            .sample_rate = sample_rate,
        };
        return .{ .pulseaudio = player };
    }

    pub fn createRecorder(ctx: *Context, device: main.Device, readFn: main.ReadFn, options: main.StreamOptions) !backends.Recorder {
        lib.pa_threaded_mainloop_lock(ctx.main_loop);
        defer lib.pa_threaded_mainloop_unlock(ctx.main_loop);

        const format = device.preferredFormat(options.format);
        const sample_rate = device.sample_rate.clamp(options.sample_rate orelse default_sample_rate);

        const sample_spec = c.pa_sample_spec{
            .format = toPAFormat(format),
            .rate = sample_rate,
            .channels = @as(u5, @intCast(device.channels.len)),
        };

        const channel_map = try toPAChannelMap(device.channels);

        const stream = lib.pa_stream_new(ctx.pulse_ctx, ctx.app_name.ptr, &sample_spec, &channel_map);
        if (stream == null)
            return error.OutOfMemory;
        errdefer lib.pa_stream_unref(stream);

        var status: StreamStatus = .{ .main_loop = ctx.main_loop, .status = .unknown };
        lib.pa_stream_set_state_callback(stream, streamStateOp, &status);

        const buffer_len = lib.pa_usec_to_bytes(main.default_latency, lib.pa_stream_get_sample_spec(stream));
        const buf_attr = c.pa_buffer_attr{
            .maxlength = std.math.maxInt(u32),
            .tlength = std.math.maxInt(u32),
            .prebuf = std.math.maxInt(u32),
            .minreq = std.math.maxInt(u32),
            .fragsize = @intCast(buffer_len),
        };

        const flags =
            c.PA_STREAM_START_CORKED |
            c.PA_STREAM_AUTO_TIMING_UPDATE |
            c.PA_STREAM_INTERPOLATE_TIMING;

        if (lib.pa_stream_connect_record(stream, device.id.ptr, &buf_attr, flags) != 0) {
            return error.OpeningDevice;
        }
        errdefer _ = lib.pa_stream_disconnect(stream);

        while (true) {
            switch (status.status) {
                .unknown => lib.pa_threaded_mainloop_wait(ctx.main_loop),
                .ready => break,
                .failure => return error.OpeningDevice,
            }
        }

        const recorder = try ctx.allocator.create(Recorder);
        recorder.* = .{
            .allocator = ctx.allocator,
            .main_loop = ctx.main_loop,
            .pulse_ctx = ctx.pulse_ctx,
            .stream = stream.?,
            .peek_ptr = undefined,
            .peek_index = 0,
            .vol = 1.0,
            .readFn = readFn,
            .user_data = options.user_data,
            .channels = device.channels,
            .format = format,
            .sample_rate = sample_rate,
        };
        return .{ .pulseaudio = recorder };
    }

    const StreamStatus = struct {
        main_loop: *c.pa_threaded_mainloop,
        status: enum(u8) {
            unknown,
            ready,
            failure,
        },
    };

    fn streamStateOp(stream: ?*c.pa_stream, stream_status_opaque: ?*anyopaque) callconv(.C) void {
        const stream_status = @as(*StreamStatus, @ptrCast(@alignCast(stream_status_opaque.?)));
        switch (lib.pa_stream_get_state(stream)) {
            c.PA_STREAM_UNCONNECTED,
            c.PA_STREAM_CREATING,
            c.PA_STREAM_TERMINATED,
            => {},
            c.PA_STREAM_READY => {
                stream_status.status = .ready;
                lib.pa_threaded_mainloop_signal(stream_status.main_loop, 0);
            },
            c.PA_STREAM_FAILED => {
                stream_status.status = .failure;
                lib.pa_threaded_mainloop_signal(stream_status.main_loop, 0);
            },
            else => unreachable,
        }
    }
};

pub const Player = struct {
    allocator: std.mem.Allocator,
    main_loop: *c.pa_threaded_mainloop,
    pulse_ctx: *c.pa_context,
    stream: *c.pa_stream,
    write_ptr: [*]u8,
    vol: f32,
    writeFn: main.WriteFn,
    user_data: ?*anyopaque,

    channels: []main.ChannelPosition,
    format: main.Format,
    sample_rate: u24,

    pub fn deinit(player: *Player) void {
        lib.pa_threaded_mainloop_lock(player.main_loop);
        lib.pa_stream_set_write_callback(player.stream, null, null);
        lib.pa_stream_set_state_callback(player.stream, null, null);
        lib.pa_stream_set_underflow_callback(player.stream, null, null);
        lib.pa_stream_set_overflow_callback(player.stream, null, null);
        _ = lib.pa_stream_disconnect(player.stream);
        lib.pa_stream_unref(player.stream);
        lib.pa_threaded_mainloop_unlock(player.main_loop);

        player.allocator.destroy(player);
    }

    pub fn start(player: *Player) !void {
        lib.pa_threaded_mainloop_lock(player.main_loop);
        defer lib.pa_threaded_mainloop_unlock(player.main_loop);

        const op = lib.pa_stream_cork(player.stream, 0, null, null) orelse
            return error.CannotPlay;
        lib.pa_operation_unref(op);
        lib.pa_stream_set_write_callback(player.stream, playbackStreamWriteOp, player);
    }

    fn playbackStreamWriteOp(stream: ?*c.pa_stream, nbytes: usize, user_data: ?*anyopaque) callconv(.C) void {
        var player = @as(*Player, @ptrCast(@alignCast(user_data.?)));

        var frames_left = nbytes;
        if (lib.pa_stream_begin_write(
            stream,
            @as(
                [*c]?*anyopaque,
                @ptrCast(@alignCast(&player.write_ptr)),
            ),
            &frames_left,
        ) != 0) return;

        player.writeFn(player.user_data, player.write_ptr[0..frames_left]);

        if (lib.pa_stream_write(
            stream,
            player.write_ptr,
            frames_left,
            null,
            0,
            c.PA_SEEK_RELATIVE,
        ) != 0) return;
    }

    pub fn play(player: *Player) !void {
        lib.pa_threaded_mainloop_lock(player.main_loop);
        defer lib.pa_threaded_mainloop_unlock(player.main_loop);

        if (lib.pa_stream_is_corked(player.stream) > 0) {
            const op = lib.pa_stream_cork(player.stream, 0, null, null) orelse
                return error.CannotPlay;
            lib.pa_operation_unref(op);
        }
    }

    pub fn pause(player: *Player) !void {
        lib.pa_threaded_mainloop_lock(player.main_loop);
        defer lib.pa_threaded_mainloop_unlock(player.main_loop);

        if (lib.pa_stream_is_corked(player.stream) == 0) {
            const op = lib.pa_stream_cork(player.stream, 1, null, null) orelse
                return error.CannotPause;
            lib.pa_operation_unref(op);
        }
    }

    pub fn paused(player: *Player) bool {
        lib.pa_threaded_mainloop_lock(player.main_loop);
        defer lib.pa_threaded_mainloop_unlock(player.main_loop);

        return lib.pa_stream_is_corked(player.stream) > 0;
    }

    pub fn setVolume(player: *Player, vol: f32) !void {
        lib.pa_threaded_mainloop_lock(player.main_loop);
        defer lib.pa_threaded_mainloop_unlock(player.main_loop);

        var cvolume: c.pa_cvolume = undefined;
        _ = lib.pa_cvolume_init(&cvolume);
        _ = lib.pa_cvolume_set(&cvolume, @as(c_uint, @intCast(player.channels.len)), lib.pa_sw_volume_from_linear(vol));

        performOperation(
            player.main_loop,
            lib.pa_context_set_sink_input_volume(
                player.pulse_ctx,
                lib.pa_stream_get_index(player.stream),
                &cvolume,
                successOp,
                player,
            ),
        );
    }

    pub fn volume(player: *Player) !f32 {
        lib.pa_threaded_mainloop_lock(player.main_loop);
        defer lib.pa_threaded_mainloop_unlock(player.main_loop);

        performOperation(
            player.main_loop,
            lib.pa_context_get_sink_input_info(
                player.pulse_ctx,
                lib.pa_stream_get_index(player.stream),
                sinkInputInfoOp,
                player,
            ),
        );

        return player.vol;
    }
};

pub const Recorder = struct {
    allocator: std.mem.Allocator,
    main_loop: *c.pa_threaded_mainloop,
    pulse_ctx: *c.pa_context,
    stream: *c.pa_stream,
    peek_ptr: [*]u8,
    peek_index: usize,
    vol: f32,
    readFn: main.ReadFn,
    user_data: ?*anyopaque,

    channels: []main.ChannelPosition,
    format: main.Format,
    sample_rate: u24,

    pub fn deinit(recorder: *Recorder) void {
        lib.pa_threaded_mainloop_lock(recorder.main_loop);
        lib.pa_stream_set_write_callback(recorder.stream, null, null);
        lib.pa_stream_set_state_callback(recorder.stream, null, null);
        lib.pa_stream_set_underflow_callback(recorder.stream, null, null);
        lib.pa_stream_set_overflow_callback(recorder.stream, null, null);
        _ = lib.pa_stream_disconnect(recorder.stream);
        lib.pa_stream_unref(recorder.stream);
        lib.pa_threaded_mainloop_unlock(recorder.main_loop);

        recorder.allocator.destroy(recorder);
    }

    pub fn start(recorder: *Recorder) !void {
        lib.pa_threaded_mainloop_lock(recorder.main_loop);
        defer lib.pa_threaded_mainloop_unlock(recorder.main_loop);

        const op = lib.pa_stream_cork(recorder.stream, 0, null, null) orelse
            return error.CannotRecord;
        lib.pa_operation_unref(op);
        lib.pa_stream_set_read_callback(recorder.stream, playbackStreamReadOp, recorder);
    }

    fn playbackStreamReadOp(stream: ?*c.pa_stream, nbytes: usize, user_data: ?*anyopaque) callconv(.C) void {
        var recorder = @as(*Recorder, @ptrCast(@alignCast(user_data.?)));

        var frames_left = nbytes;
        var peek_ptr: ?*anyopaque = undefined;
        if (lib.pa_stream_peek(stream, &peek_ptr, &frames_left) != 0) {
            if (std.debug.runtime_safety) unreachable;
            return;
        }

        if (peek_ptr) |ptr| {
            recorder.peek_ptr = @ptrCast(ptr);

            recorder.readFn(recorder.user_data, (recorder.peek_ptr + recorder.peek_index)[0..frames_left]);
            recorder.peek_index += frames_left;
        } else {
            _ = lib.pa_stream_drop(stream);
        }
    }

    pub fn record(recorder: *Recorder) !void {
        lib.pa_threaded_mainloop_lock(recorder.main_loop);
        defer lib.pa_threaded_mainloop_unlock(recorder.main_loop);

        if (lib.pa_stream_is_corked(recorder.stream) > 0) {
            const op = lib.pa_stream_cork(recorder.stream, 0, null, null) orelse
                return error.CannotRecord;
            lib.pa_operation_unref(op);
        }
    }

    pub fn pause(recorder: *Recorder) !void {
        lib.pa_threaded_mainloop_lock(recorder.main_loop);
        defer lib.pa_threaded_mainloop_unlock(recorder.main_loop);

        if (lib.pa_stream_is_corked(recorder.stream) == 0) {
            const op = lib.pa_stream_cork(recorder.stream, 1, null, null) orelse
                return error.CannotPause;
            lib.pa_operation_unref(op);
        }
    }

    pub fn paused(recorder: *Recorder) bool {
        lib.pa_threaded_mainloop_lock(recorder.main_loop);
        defer lib.pa_threaded_mainloop_unlock(recorder.main_loop);

        return lib.pa_stream_is_corked(recorder.stream) > 0;
    }

    pub fn setVolume(recorder: *Recorder, vol: f32) !void {
        lib.pa_threaded_mainloop_lock(recorder.main_loop);
        defer lib.pa_threaded_mainloop_unlock(recorder.main_loop);

        var cvolume: c.pa_cvolume = undefined;
        _ = lib.pa_cvolume_init(&cvolume);
        _ = lib.pa_cvolume_set(&cvolume, @as(c_uint, @intCast(recorder.channels.len)), lib.pa_sw_volume_from_linear(vol));

        performOperation(
            recorder.main_loop,
            lib.pa_context_set_sink_input_volume(
                recorder.pulse_ctx,
                lib.pa_stream_get_index(recorder.stream),
                &cvolume,
                successOp,
                recorder,
            ),
        );
    }

    pub fn volume(recorder: *Recorder) !f32 {
        lib.pa_threaded_mainloop_lock(recorder.main_loop);
        defer lib.pa_threaded_mainloop_unlock(recorder.main_loop);

        performOperation(
            recorder.main_loop,
            lib.pa_context_get_sink_input_info(
                recorder.pulse_ctx,
                lib.pa_stream_get_index(recorder.stream),
                sinkInputInfoOp,
                recorder,
            ),
        );

        return recorder.vol;
    }
};

fn successOp(_: ?*c.pa_context, success: c_int, player_opaque: ?*anyopaque) callconv(.C) void {
    const player = @as(*Player, @ptrCast(@alignCast(player_opaque.?)));
    if (success == 1)
        lib.pa_threaded_mainloop_signal(player.main_loop, 0);
}

fn sinkInputInfoOp(_: ?*c.pa_context, info: [*c]const c.pa_sink_input_info, eol: c_int, player_opaque: ?*anyopaque) callconv(.C) void {
    var player = @as(*Player, @ptrCast(@alignCast(player_opaque.?)));

    if (eol != 0) {
        lib.pa_threaded_mainloop_signal(player.main_loop, 0);
        return;
    }

    player.vol = @as(f32, @floatFromInt(info.*.volume.values[0])) / @as(f32, @floatFromInt(c.PA_VOLUME_NORM));
}

fn freeDevice(allocator: std.mem.Allocator, device: main.Device) void {
    allocator.free(device.id);
    allocator.free(device.name);
    allocator.free(device.channels);
}

fn performOperation(main_loop: *c.pa_threaded_mainloop, op: ?*c.pa_operation) void {
    while (true) {
        switch (lib.pa_operation_get_state(op)) {
            c.PA_OPERATION_RUNNING => lib.pa_threaded_mainloop_wait(main_loop),
            c.PA_OPERATION_DONE => return lib.pa_operation_unref(op),
            c.PA_OPERATION_CANCELLED => return lib.pa_operation_unref(op),
            else => unreachable,
        }
    }
}

pub const available_formats = &[_]main.Format{
    .u8,
    .i16,
    .i24,
    .i32,
    .f32,
};

pub fn fromPAChannelPos(pos: c.pa_channel_position_t) !main.ChannelPosition {
    return switch (pos) {
        c.PA_CHANNEL_POSITION_MONO => .front_center,
        c.PA_CHANNEL_POSITION_FRONT_LEFT => .front_left, // PA_CHANNEL_POSITION_LEFT
        c.PA_CHANNEL_POSITION_FRONT_RIGHT => .front_right, // PA_CHANNEL_POSITION_RIGHT
        c.PA_CHANNEL_POSITION_FRONT_CENTER => .front_center, // PA_CHANNEL_POSITION_CENTER
        c.PA_CHANNEL_POSITION_REAR_CENTER => .back_center,
        c.PA_CHANNEL_POSITION_REAR_LEFT => .back_left,
        c.PA_CHANNEL_POSITION_REAR_RIGHT => .back_right,
        c.PA_CHANNEL_POSITION_LFE => .lfe, // PA_CHANNEL_POSITION_SUBWOOFER
        c.PA_CHANNEL_POSITION_FRONT_LEFT_OF_CENTER => .front_left_center,
        c.PA_CHANNEL_POSITION_FRONT_RIGHT_OF_CENTER => .front_right_center,
        c.PA_CHANNEL_POSITION_SIDE_LEFT => .side_left,
        c.PA_CHANNEL_POSITION_SIDE_RIGHT => .side_right,
        c.PA_CHANNEL_POSITION_AUX0...c.PA_CHANNEL_POSITION_AUX31 => .front_center,
        c.PA_CHANNEL_POSITION_TOP_CENTER => .top_center,
        c.PA_CHANNEL_POSITION_TOP_FRONT_LEFT => .top_front_left,
        c.PA_CHANNEL_POSITION_TOP_FRONT_RIGHT => .top_front_right,
        c.PA_CHANNEL_POSITION_TOP_FRONT_CENTER => .top_front_center,
        c.PA_CHANNEL_POSITION_TOP_REAR_LEFT => .top_back_left,
        c.PA_CHANNEL_POSITION_TOP_REAR_RIGHT => .top_back_right,
        c.PA_CHANNEL_POSITION_TOP_REAR_CENTER => .top_back_center,

        else => error.Invalid,
    };
}

pub fn toPAFormat(format: main.Format) c.pa_sample_format_t {
    return switch (format) {
        .u8 => c.PA_SAMPLE_U8,
        .i16 => if (is_little) c.PA_SAMPLE_S16LE else c.PA_SAMPLE_S16BE,
        .i24 => if (is_little) c.PA_SAMPLE_S24LE else c.PA_SAMPLE_S24LE,
        .i32 => if (is_little) c.PA_SAMPLE_S32LE else c.PA_SAMPLE_S32BE,
        .f32 => if (is_little) c.PA_SAMPLE_FLOAT32LE else c.PA_SAMPLE_FLOAT32BE,
    };
}

pub fn toPAChannelMap(channels: []const main.ChannelPosition) !c.pa_channel_map {
    var channel_map: c.pa_channel_map = undefined;
    channel_map.channels = @as(u5, @intCast(channels.len));
    for (channels, 0..) |ch, i|
        channel_map.map[i] = try toPAChannelPos(ch);
    return channel_map;
}

fn toPAChannelPos(channel_id: main.ChannelPosition) !c.pa_channel_position_t {
    return switch (channel_id) {
        .lfe => c.PA_CHANNEL_POSITION_LFE,
        .front_center => c.PA_CHANNEL_POSITION_FRONT_CENTER,
        .front_left => c.PA_CHANNEL_POSITION_FRONT_LEFT,
        .front_right => c.PA_CHANNEL_POSITION_FRONT_RIGHT,
        .front_left_center => c.PA_CHANNEL_POSITION_FRONT_LEFT_OF_CENTER,
        .front_right_center => c.PA_CHANNEL_POSITION_FRONT_RIGHT_OF_CENTER,
        .back_center => c.PA_CHANNEL_POSITION_REAR_CENTER,
        .back_left => c.PA_CHANNEL_POSITION_REAR_LEFT,
        .back_right => c.PA_CHANNEL_POSITION_REAR_RIGHT,
        .side_left => c.PA_CHANNEL_POSITION_SIDE_LEFT,
        .side_right => c.PA_CHANNEL_POSITION_SIDE_RIGHT,
        .top_center => c.PA_CHANNEL_POSITION_TOP_CENTER,
        .top_front_center => c.PA_CHANNEL_POSITION_TOP_FRONT_CENTER,
        .top_front_left => c.PA_CHANNEL_POSITION_TOP_FRONT_LEFT,
        .top_front_right => c.PA_CHANNEL_POSITION_TOP_FRONT_RIGHT,
        .top_back_center => c.PA_CHANNEL_POSITION_TOP_REAR_CENTER,
        .top_back_left => c.PA_CHANNEL_POSITION_TOP_REAR_LEFT,
        .top_back_right => c.PA_CHANNEL_POSITION_TOP_REAR_RIGHT,
    };
}
