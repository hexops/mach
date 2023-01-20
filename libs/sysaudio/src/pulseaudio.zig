const std = @import("std");
const c = @cImport(@cInclude("pulse/pulseaudio.h"));
const main = @import("main.zig");
const backends = @import("backends.zig");
const util = @import("util.zig");
const is_little = @import("builtin").cpu.arch.endian() == .Little;

const lib = struct {
    var handle: std.DynLib = undefined;

    var pa_threaded_mainloop_new: *const fn () callconv(.C) ?*c.pa_threaded_mainloop = undefined;
    var pa_threaded_mainloop_free: *const fn (?*c.pa_threaded_mainloop) callconv(.C) void = undefined;
    var pa_threaded_mainloop_start: *const fn (?*c.pa_threaded_mainloop) callconv(.C) c_int = undefined;
    var pa_threaded_mainloop_stop: *const fn (?*c.pa_threaded_mainloop) callconv(.C) void = undefined;
    var pa_threaded_mainloop_signal: *const fn (?*c.pa_threaded_mainloop, c_int) callconv(.C) void = undefined;
    var pa_threaded_mainloop_wait: *const fn (?*c.pa_threaded_mainloop) callconv(.C) void = undefined;
    var pa_threaded_mainloop_lock: *const fn (?*c.pa_threaded_mainloop) callconv(.C) void = undefined;
    var pa_threaded_mainloop_unlock: *const fn (?*c.pa_threaded_mainloop) callconv(.C) void = undefined;
    var pa_threaded_mainloop_get_api: *const fn (?*c.pa_threaded_mainloop) callconv(.C) [*c]c.pa_mainloop_api = undefined;
    var pa_operation_unref: *const fn (?*c.pa_operation) callconv(.C) void = undefined;
    var pa_operation_get_state: *const fn (?*const c.pa_operation) callconv(.C) c.pa_operation_state_t = undefined;
    var pa_context_new_with_proplist: *const fn ([*c]c.pa_mainloop_api, [*c]const u8, ?*const c.pa_proplist) callconv(.C) ?*c.pa_context = undefined;
    var pa_context_unref: *const fn (?*c.pa_context) callconv(.C) void = undefined;
    var pa_context_connect: *const fn (?*c.pa_context, [*c]const u8, c.pa_context_flags_t, [*c]const c.pa_spawn_api) callconv(.C) c_int = undefined;
    var pa_context_disconnect: *const fn (?*c.pa_context) callconv(.C) void = undefined;
    var pa_context_subscribe: *const fn (?*c.pa_context, c.pa_subscription_mask_t, c.pa_context_success_cb_t, ?*anyopaque) callconv(.C) ?*c.pa_operation = undefined;
    var pa_context_get_state: *const fn (?*const c.pa_context) callconv(.C) c.pa_context_state_t = undefined;
    var pa_context_set_state_callback: *const fn (?*c.pa_context, c.pa_context_notify_cb_t, ?*anyopaque) callconv(.C) void = undefined;
    var pa_context_set_subscribe_callback: *const fn (?*c.pa_context, c.pa_context_subscribe_cb_t, ?*anyopaque) callconv(.C) void = undefined;
    var pa_context_get_sink_input_info: *const fn (?*c.pa_context, u32, c.pa_sink_input_info_cb_t, ?*anyopaque) callconv(.C) ?*c.pa_operation = undefined;
    var pa_context_get_sink_info_list: *const fn (?*c.pa_context, c.pa_sink_info_cb_t, ?*anyopaque) callconv(.C) ?*c.pa_operation = undefined;
    var pa_context_set_sink_input_volume: *const fn (?*c.pa_context, u32, [*c]const c.pa_cvolume, c.pa_context_success_cb_t, ?*anyopaque) callconv(.C) ?*c.pa_operation = undefined;
    var pa_context_get_source_info_list: *const fn (?*c.pa_context, c.pa_source_info_cb_t, ?*anyopaque) callconv(.C) ?*c.pa_operation = undefined;
    var pa_context_get_server_info: *const fn (?*c.pa_context, c.pa_server_info_cb_t, ?*anyopaque) callconv(.C) ?*c.pa_operation = undefined;
    var pa_stream_new: *const fn (?*c.pa_context, [*c]const u8, [*c]const c.pa_sample_spec, [*c]const c.pa_channel_map) callconv(.C) ?*c.pa_stream = undefined;
    var pa_stream_unref: *const fn (?*c.pa_stream) callconv(.C) void = undefined;
    var pa_stream_connect_playback: *const fn (?*c.pa_stream, [*c]const u8, [*c]const c.pa_buffer_attr, c.pa_stream_flags_t, [*c]const c.pa_cvolume, ?*c.pa_stream) callconv(.C) c_int = undefined;
    var pa_stream_disconnect: *const fn (?*c.pa_stream) callconv(.C) c_int = undefined;
    var pa_stream_cork: *const fn (?*c.pa_stream, c_int, c.pa_stream_success_cb_t, ?*anyopaque) callconv(.C) ?*c.pa_operation = undefined;
    var pa_stream_is_corked: *const fn (?*const c.pa_stream) callconv(.C) c_int = undefined;
    var pa_stream_begin_write: *const fn (?*c.pa_stream, [*c]?*anyopaque, [*c]usize) callconv(.C) c_int = undefined;
    var pa_stream_write: *const fn (?*c.pa_stream, ?*const anyopaque, usize, c.pa_free_cb_t, i64, c.pa_seek_mode_t) callconv(.C) c_int = undefined;
    var pa_stream_get_state: *const fn (?*const c.pa_stream) callconv(.C) c.pa_stream_state_t = undefined;
    var pa_stream_get_index: *const fn (?*const c.pa_stream) callconv(.C) u32 = undefined;
    var pa_stream_set_state_callback: *const fn (?*c.pa_stream, c.pa_stream_notify_cb_t, ?*anyopaque) callconv(.C) void = undefined;
    var pa_stream_set_write_callback: *const fn (?*c.pa_stream, c.pa_stream_request_cb_t, ?*anyopaque) callconv(.C) void = undefined;
    var pa_stream_set_underflow_callback: *const fn (?*c.pa_stream, c.pa_stream_notify_cb_t, ?*anyopaque) callconv(.C) void = undefined;
    var pa_stream_set_overflow_callback: *const fn (?*c.pa_stream, c.pa_stream_notify_cb_t, ?*anyopaque) callconv(.C) void = undefined;
    var pa_cvolume_init: *const fn ([*c]c.pa_cvolume) callconv(.C) [*c]c.pa_cvolume = undefined;
    var pa_cvolume_set: *const fn ([*c]c.pa_cvolume, c_uint, c.pa_volume_t) callconv(.C) [*c]c.pa_cvolume = undefined;
    var pa_sw_volume_from_linear: *const fn (f64) callconv(.C) c.pa_volume_t = undefined;

    pub fn load() !void {
        handle = std.DynLib.openZ("libpulse.so") catch return error.LibraryNotFound;

        pa_threaded_mainloop_new = handle.lookup(@TypeOf(pa_threaded_mainloop_new), "pa_threaded_mainloop_new") orelse return error.SymbolLookup;
        pa_threaded_mainloop_free = handle.lookup(@TypeOf(pa_threaded_mainloop_free), "pa_threaded_mainloop_free") orelse return error.SymbolLookup;
        pa_threaded_mainloop_start = handle.lookup(@TypeOf(pa_threaded_mainloop_start), "pa_threaded_mainloop_start") orelse return error.SymbolLookup;
        pa_threaded_mainloop_stop = handle.lookup(@TypeOf(pa_threaded_mainloop_stop), "pa_threaded_mainloop_stop") orelse return error.SymbolLookup;
        pa_threaded_mainloop_signal = handle.lookup(@TypeOf(pa_threaded_mainloop_signal), "pa_threaded_mainloop_signal") orelse return error.SymbolLookup;
        pa_threaded_mainloop_wait = handle.lookup(@TypeOf(pa_threaded_mainloop_wait), "pa_threaded_mainloop_wait") orelse return error.SymbolLookup;
        pa_threaded_mainloop_lock = handle.lookup(@TypeOf(pa_threaded_mainloop_lock), "pa_threaded_mainloop_lock") orelse return error.SymbolLookup;
        pa_threaded_mainloop_unlock = handle.lookup(@TypeOf(pa_threaded_mainloop_unlock), "pa_threaded_mainloop_unlock") orelse return error.SymbolLookup;
        pa_threaded_mainloop_get_api = handle.lookup(@TypeOf(pa_threaded_mainloop_get_api), "pa_threaded_mainloop_get_api") orelse return error.SymbolLookup;
        pa_operation_unref = handle.lookup(@TypeOf(pa_operation_unref), "pa_operation_unref") orelse return error.SymbolLookup;
        pa_operation_get_state = handle.lookup(@TypeOf(pa_operation_get_state), "pa_operation_get_state") orelse return error.SymbolLookup;
        pa_context_new_with_proplist = handle.lookup(@TypeOf(pa_context_new_with_proplist), "pa_context_new_with_proplist") orelse return error.SymbolLookup;
        pa_context_unref = handle.lookup(@TypeOf(pa_context_unref), "pa_context_unref") orelse return error.SymbolLookup;
        pa_context_connect = handle.lookup(@TypeOf(pa_context_connect), "pa_context_connect") orelse return error.SymbolLookup;
        pa_context_disconnect = handle.lookup(@TypeOf(pa_context_disconnect), "pa_context_disconnect") orelse return error.SymbolLookup;
        pa_context_subscribe = handle.lookup(@TypeOf(pa_context_subscribe), "pa_context_subscribe") orelse return error.SymbolLookup;
        pa_context_get_state = handle.lookup(@TypeOf(pa_context_get_state), "pa_context_get_state") orelse return error.SymbolLookup;
        pa_context_set_state_callback = handle.lookup(@TypeOf(pa_context_set_state_callback), "pa_context_set_state_callback") orelse return error.SymbolLookup;
        pa_context_set_subscribe_callback = handle.lookup(@TypeOf(pa_context_set_subscribe_callback), "pa_context_set_subscribe_callback") orelse return error.SymbolLookup;
        pa_context_get_sink_input_info = handle.lookup(@TypeOf(pa_context_get_sink_input_info), "pa_context_get_sink_input_info") orelse return error.SymbolLookup;
        pa_context_get_sink_info_list = handle.lookup(@TypeOf(pa_context_get_sink_info_list), "pa_context_get_sink_info_list") orelse return error.SymbolLookup;
        pa_context_set_sink_input_volume = handle.lookup(@TypeOf(pa_context_set_sink_input_volume), "pa_context_set_sink_input_volume") orelse return error.SymbolLookup;
        pa_context_get_source_info_list = handle.lookup(@TypeOf(pa_context_get_source_info_list), "pa_context_get_source_info_list") orelse return error.SymbolLookup;
        pa_context_get_server_info = handle.lookup(@TypeOf(pa_context_get_server_info), "pa_context_get_server_info") orelse return error.SymbolLookup;
        pa_stream_new = handle.lookup(@TypeOf(pa_stream_new), "pa_stream_new") orelse return error.SymbolLookup;
        pa_stream_unref = handle.lookup(@TypeOf(pa_stream_unref), "pa_stream_unref") orelse return error.SymbolLookup;
        pa_stream_connect_playback = handle.lookup(@TypeOf(pa_stream_connect_playback), "pa_stream_connect_playback") orelse return error.SymbolLookup;
        pa_stream_disconnect = handle.lookup(@TypeOf(pa_stream_disconnect), "pa_stream_disconnect") orelse return error.SymbolLookup;
        pa_stream_cork = handle.lookup(@TypeOf(pa_stream_cork), "pa_stream_cork") orelse return error.SymbolLookup;
        pa_stream_is_corked = handle.lookup(@TypeOf(pa_stream_is_corked), "pa_stream_is_corked") orelse return error.SymbolLookup;
        pa_stream_begin_write = handle.lookup(@TypeOf(pa_stream_begin_write), "pa_stream_begin_write") orelse return error.SymbolLookup;
        pa_stream_write = handle.lookup(@TypeOf(pa_stream_write), "pa_stream_write") orelse return error.SymbolLookup;
        pa_stream_get_state = handle.lookup(@TypeOf(pa_stream_get_state), "pa_stream_get_state") orelse return error.SymbolLookup;
        pa_stream_get_index = handle.lookup(@TypeOf(pa_stream_get_index), "pa_stream_get_index") orelse return error.SymbolLookup;
        pa_stream_set_state_callback = handle.lookup(@TypeOf(pa_stream_set_state_callback), "pa_stream_set_state_callback") orelse return error.SymbolLookup;
        pa_stream_set_write_callback = handle.lookup(@TypeOf(pa_stream_set_write_callback), "pa_stream_set_write_callback") orelse return error.SymbolLookup;
        pa_stream_set_underflow_callback = handle.lookup(@TypeOf(pa_stream_set_underflow_callback), "pa_stream_set_underflow_callback") orelse return error.SymbolLookup;
        pa_stream_set_overflow_callback = handle.lookup(@TypeOf(pa_stream_set_overflow_callback), "pa_stream_set_overflow_callback") orelse return error.SymbolLookup;
        pa_cvolume_init = handle.lookup(@TypeOf(pa_cvolume_init), "pa_cvolume_init") orelse return error.SymbolLookup;
        pa_cvolume_set = handle.lookup(@TypeOf(pa_cvolume_set), "pa_cvolume_set") orelse return error.SymbolLookup;
        pa_sw_volume_from_linear = handle.lookup(@TypeOf(pa_sw_volume_from_linear), "pa_sw_volume_from_linear") orelse return error.SymbolLookup;
    }
};

pub const Context = struct {
    allocator: std.mem.Allocator,
    devices_info: util.DevicesInfo,
    app_name: [:0]const u8,
    main_loop: *c.pa_threaded_mainloop,
    ctx: *c.pa_context,
    ctx_state: c.pa_context_state_t,
    default_sink: ?[:0]const u8,
    default_source: ?[:0]const u8,
    watcher: ?Watcher,

    const Watcher = struct {
        deviceChangeFn: main.Context.DeviceChangeFn,
        user_data: ?*anyopaque,
    };

    pub fn init(allocator: std.mem.Allocator, options: main.Context.Options) !backends.BackendContext {
        try lib.load();

        const main_loop = lib.pa_threaded_mainloop_new() orelse
            return error.OutOfMemory;
        errdefer lib.pa_threaded_mainloop_free(main_loop);
        var main_loop_api = lib.pa_threaded_mainloop_get_api(main_loop);

        const ctx = lib.pa_context_new_with_proplist(main_loop_api, options.app_name.ptr, null) orelse
            return error.OutOfMemory;
        errdefer lib.pa_context_unref(ctx);

        var self = try allocator.create(Context);
        errdefer allocator.destroy(self);
        self.* = Context{
            .allocator = allocator,
            .devices_info = util.DevicesInfo.init(),
            .app_name = options.app_name,
            .main_loop = main_loop,
            .ctx = ctx,
            .ctx_state = c.PA_CONTEXT_UNCONNECTED,
            .default_sink = null,
            .default_source = null,
            .watcher = if (options.deviceChangeFn) |dcf| .{
                .deviceChangeFn = dcf,
                .user_data = options.user_data,
            } else null,
        };

        if (lib.pa_context_connect(ctx, null, 0, null) != 0)
            return error.ConnectionRefused;
        errdefer lib.pa_context_disconnect(ctx);
        lib.pa_context_set_state_callback(ctx, contextStateOp, self);

        if (lib.pa_threaded_mainloop_start(main_loop) != 0)
            return error.SystemResources;
        errdefer lib.pa_threaded_mainloop_stop(main_loop);

        lib.pa_threaded_mainloop_lock(main_loop);
        defer lib.pa_threaded_mainloop_unlock(main_loop);

        while (true) {
            switch (self.ctx_state) {
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
            lib.pa_context_set_subscribe_callback(ctx, subscribeOp, self);
            const events = c.PA_SUBSCRIPTION_MASK_SINK | c.PA_SUBSCRIPTION_MASK_SOURCE;
            const subscribe_op = lib.pa_context_subscribe(ctx, events, null, self) orelse
                return error.OutOfMemory;
            lib.pa_operation_unref(subscribe_op);
        }

        return .{ .pulseaudio = self };
    }

    fn subscribeOp(_: ?*c.pa_context, _: c.pa_subscription_event_type_t, _: u32, user_data: ?*anyopaque) callconv(.C) void {
        var self = @ptrCast(*Context, @alignCast(@alignOf(*Context), user_data.?));
        self.watcher.?.deviceChangeFn(self.watcher.?.user_data);
    }

    fn contextStateOp(ctx: ?*c.pa_context, user_data: ?*anyopaque) callconv(.C) void {
        var self = @ptrCast(*Context, @alignCast(@alignOf(*Context), user_data.?));

        self.ctx_state = lib.pa_context_get_state(ctx);
        lib.pa_threaded_mainloop_signal(self.main_loop, 0);
    }

    pub fn deinit(self: *Context) void {
        lib.pa_context_set_subscribe_callback(self.ctx, null, null);
        lib.pa_context_set_state_callback(self.ctx, null, null);
        lib.pa_context_disconnect(self.ctx);
        lib.pa_context_unref(self.ctx);
        lib.pa_threaded_mainloop_stop(self.main_loop);
        lib.pa_threaded_mainloop_free(self.main_loop);
        for (self.devices_info.list.items) |d|
            freeDevice(self.allocator, d);
        self.devices_info.list.deinit(self.allocator);
        self.allocator.destroy(self);
        lib.handle.close();
    }

    pub fn refresh(self: *Context) !void {
        lib.pa_threaded_mainloop_lock(self.main_loop);
        defer lib.pa_threaded_mainloop_unlock(self.main_loop);

        for (self.devices_info.list.items) |d|
            freeDevice(self.allocator, d);
        self.devices_info.clear(self.allocator);

        const list_sink_op = lib.pa_context_get_sink_info_list(self.ctx, sinkInfoOp, self);
        const list_source_op = lib.pa_context_get_source_info_list(self.ctx, sourceInfoOp, self);
        const server_info_op = lib.pa_context_get_server_info(self.ctx, serverInfoOp, self);

        performOperation(self.main_loop, list_sink_op);
        performOperation(self.main_loop, list_source_op);
        performOperation(self.main_loop, server_info_op);

        defer {
            if (self.default_sink) |d|
                self.allocator.free(d);
            if (self.default_source) |d|
                self.allocator.free(d);
        }
        for (self.devices_info.list.items) |device, i| {
            if ((device.mode == .playback and
                self.default_sink != null and
                std.mem.eql(u8, device.id, self.default_sink.?)) or
                //
                (device.mode == .capture and
                self.default_source != null and
                std.mem.eql(u8, device.id, self.default_source.?)))
            {
                self.devices_info.setDefault(device.mode, i);
                break;
            }
        }
    }

    fn serverInfoOp(_: ?*c.pa_context, info: [*c]const c.pa_server_info, user_data: ?*anyopaque) callconv(.C) void {
        var self = @ptrCast(*Context, @alignCast(@alignOf(*Context), user_data.?));

        defer lib.pa_threaded_mainloop_signal(self.main_loop, 0);
        self.default_sink = self.allocator.dupeZ(u8, std.mem.span(info.*.default_sink_name)) catch return;
        self.default_source = self.allocator.dupeZ(u8, std.mem.span(info.*.default_source_name)) catch {
            self.allocator.free(self.default_sink.?);
            return;
        };
    }

    fn sinkInfoOp(_: ?*c.pa_context, info: [*c]const c.pa_sink_info, eol: c_int, user_data: ?*anyopaque) callconv(.C) void {
        var self = @ptrCast(*Context, @alignCast(@alignOf(*Context), user_data.?));
        if (eol != 0) {
            lib.pa_threaded_mainloop_signal(self.main_loop, 0);
            return;
        }

        self.deviceInfoOp(info, .playback) catch return;
    }

    fn sourceInfoOp(_: ?*c.pa_context, info: [*c]const c.pa_source_info, eol: c_int, user_data: ?*anyopaque) callconv(.C) void {
        var self = @ptrCast(*Context, @alignCast(@alignOf(*Context), user_data.?));
        if (eol != 0) {
            lib.pa_threaded_mainloop_signal(self.main_loop, 0);
            return;
        }

        self.deviceInfoOp(info, .capture) catch return;
    }

    fn deviceInfoOp(self: *Context, info: anytype, mode: main.Device.Mode) !void {
        var id = try self.allocator.dupeZ(u8, std.mem.span(info.*.name));
        errdefer self.allocator.free(id);
        var name = try self.allocator.dupeZ(u8, std.mem.span(info.*.description));
        errdefer self.allocator.free(name);

        var device = main.Device{
            .mode = mode,
            .channels = blk: {
                var channels = try self.allocator.alloc(main.Channel, info.*.channel_map.channels);
                for (channels) |*ch, i|
                    ch.*.id = fromPAChannelPos(info.*.channel_map.map[i]) catch unreachable;
                break :blk channels;
            },
            .formats = available_formats,
            .sample_rate = .{
                .min = @intCast(u24, info.*.sample_spec.rate),
                .max = @intCast(u24, info.*.sample_spec.rate),
            },
            .id = id,
            .name = name,
        };

        try self.devices_info.list.append(self.allocator, device);
    }

    pub fn devices(self: Context) []const main.Device {
        return self.devices_info.list.items;
    }

    pub fn defaultDevice(self: Context, mode: main.Device.Mode) ?main.Device {
        return self.devices_info.default(mode);
    }

    pub fn createPlayer(self: *Context, device: main.Device, writeFn: main.WriteFn, options: main.Player.Options) !backends.BackendPlayer {
        lib.pa_threaded_mainloop_lock(self.main_loop);
        defer lib.pa_threaded_mainloop_unlock(self.main_loop);

        const format = device.preferredFormat(options.format);
        const sample_rate = device.sample_rate.clamp(options.sample_rate);

        const sample_spec = c.pa_sample_spec{
            .format = toPAFormat(format) catch unreachable,
            .rate = sample_rate,
            .channels = @intCast(u5, device.channels.len),
        };

        const channel_map = try toPAChannelMap(device.channels);

        var stream = lib.pa_stream_new(self.ctx, self.app_name.ptr, &sample_spec, &channel_map);
        if (stream == null)
            return error.OutOfMemory;
        errdefer lib.pa_stream_unref(stream);

        var status: StreamStatus = .{ .main_loop = self.main_loop, .status = .unknown };
        lib.pa_stream_set_state_callback(stream, streamStateOp, &status);

        const buf_attr = c.pa_buffer_attr{
            .maxlength = std.math.maxInt(u32),
            .tlength = std.math.maxInt(u32),
            .prebuf = 0,
            .minreq = std.math.maxInt(u32),
            .fragsize = std.math.maxInt(u32),
        };

        const flags =
            c.PA_STREAM_START_CORKED |
            c.PA_STREAM_AUTO_TIMING_UPDATE |
            c.PA_STREAM_INTERPOLATE_TIMING |
            c.PA_STREAM_ADJUST_LATENCY;

        if (lib.pa_stream_connect_playback(stream, device.id.ptr, &buf_attr, flags, null, null) != 0) {
            return error.OpeningDevice;
        }
        errdefer _ = lib.pa_stream_disconnect(stream);

        while (true) {
            switch (status.status) {
                .unknown => lib.pa_threaded_mainloop_wait(self.main_loop),
                .ready => break,
                .failure => return error.OpeningDevice,
            }
        }

        var player = try self.allocator.create(Player);
        player.* = .{
            .allocator = self.allocator,
            .main_loop = self.main_loop,
            .ctx = self.ctx,
            .stream = stream.?,
            .write_ptr = undefined,
            .vol = 1.0,
            .writeFn = writeFn,
            .user_data = options.user_data,
            .channels = device.channels,
            .format = format,
            .sample_rate = sample_rate,
            .write_step = format.frameSize(device.channels.len),
        };
        return .{ .pulseaudio = player };
    }

    const StreamStatus = struct {
        main_loop: *c.pa_threaded_mainloop,
        status: enum(u8) {
            unknown,
            ready,
            failure,
        },
    };

    fn streamStateOp(stream: ?*c.pa_stream, user_data: ?*anyopaque) callconv(.C) void {
        var self = @ptrCast(*StreamStatus, @alignCast(@alignOf(*StreamStatus), user_data.?));

        switch (lib.pa_stream_get_state(stream)) {
            c.PA_STREAM_UNCONNECTED,
            c.PA_STREAM_CREATING,
            c.PA_STREAM_TERMINATED,
            => {},
            c.PA_STREAM_READY => {
                self.status = .ready;
                lib.pa_threaded_mainloop_signal(self.main_loop, 0);
            },
            c.PA_STREAM_FAILED => {
                self.status = .failure;
                lib.pa_threaded_mainloop_signal(self.main_loop, 0);
            },
            else => unreachable,
        }
    }
};

pub const Player = struct {
    allocator: std.mem.Allocator,
    main_loop: *c.pa_threaded_mainloop,
    ctx: *c.pa_context,
    stream: *c.pa_stream,
    write_ptr: [*]u8,
    vol: f32,
    writeFn: main.WriteFn,
    user_data: ?*anyopaque,

    channels: []main.Channel,
    format: main.Format,
    sample_rate: u24,
    write_step: u8,

    pub fn deinit(self: *Player) void {
        lib.pa_threaded_mainloop_lock(self.main_loop);
        lib.pa_stream_set_write_callback(self.stream, null, null);
        lib.pa_stream_set_state_callback(self.stream, null, null);
        lib.pa_stream_set_underflow_callback(self.stream, null, null);
        lib.pa_stream_set_overflow_callback(self.stream, null, null);
        _ = lib.pa_stream_disconnect(self.stream);
        lib.pa_stream_unref(self.stream);
        lib.pa_threaded_mainloop_unlock(self.main_loop);

        self.allocator.destroy(self);
    }

    pub fn start(self: *Player) !void {
        lib.pa_threaded_mainloop_lock(self.main_loop);
        defer lib.pa_threaded_mainloop_unlock(self.main_loop);

        const op = lib.pa_stream_cork(self.stream, 0, null, null) orelse
            return error.CannotPlay;
        lib.pa_operation_unref(op);
        lib.pa_stream_set_write_callback(self.stream, playbackStreamWriteOp, self);
    }

    fn playbackStreamWriteOp(_: ?*c.pa_stream, nbytes: usize, user_data: ?*anyopaque) callconv(.C) void {
        var self = @ptrCast(*Player, @alignCast(@alignOf(*Player), user_data.?));

        var frames_left = nbytes;
        while (frames_left > 0) {
            var chunk_size = frames_left;
            if (lib.pa_stream_begin_write(
                self.stream,
                @ptrCast(
                    [*c]?*anyopaque,
                    @alignCast(@alignOf([*c]?*anyopaque), &self.write_ptr),
                ),
                &chunk_size,
            ) != 0) {
                if (std.debug.runtime_safety) unreachable;
                return;
            }

            for (self.channels) |*ch, i| {
                ch.*.ptr = self.write_ptr + self.format.frameSize(i);
            }

            const frames = chunk_size / self.format.frameSize(self.channels.len);
            self.writeFn(self.user_data, frames);

            if (lib.pa_stream_write(self.stream, self.write_ptr, chunk_size, null, 0, c.PA_SEEK_RELATIVE) != 0) {
                if (std.debug.runtime_safety) unreachable;
                return;
            }

            frames_left -= chunk_size;
        }
    }

    pub fn play(self: *Player) !void {
        lib.pa_threaded_mainloop_lock(self.main_loop);
        defer lib.pa_threaded_mainloop_unlock(self.main_loop);

        if (lib.pa_stream_is_corked(self.stream) > 0) {
            const op = lib.pa_stream_cork(self.stream, 0, null, null) orelse
                return error.CannotPlay;
            lib.pa_operation_unref(op);
        }
    }

    pub fn pause(self: *Player) !void {
        lib.pa_threaded_mainloop_lock(self.main_loop);
        defer lib.pa_threaded_mainloop_unlock(self.main_loop);

        if (lib.pa_stream_is_corked(self.stream) == 0) {
            const op = lib.pa_stream_cork(self.stream, 1, null, null) orelse
                return error.CannotPause;
            lib.pa_operation_unref(op);
        }
    }

    pub fn paused(self: *Player) bool {
        lib.pa_threaded_mainloop_lock(self.main_loop);
        defer lib.pa_threaded_mainloop_unlock(self.main_loop);

        return lib.pa_stream_is_corked(self.stream) > 0;
    }

    pub fn setVolume(self: *Player, vol: f32) !void {
        lib.pa_threaded_mainloop_lock(self.main_loop);
        defer lib.pa_threaded_mainloop_unlock(self.main_loop);

        var cvolume: c.pa_cvolume = undefined;
        _ = lib.pa_cvolume_init(&cvolume);
        _ = lib.pa_cvolume_set(&cvolume, @intCast(c_uint, self.channels.len), lib.pa_sw_volume_from_linear(vol));

        performOperation(
            self.main_loop,
            lib.pa_context_set_sink_input_volume(
                self.ctx,
                lib.pa_stream_get_index(self.stream),
                &cvolume,
                successOp,
                self,
            ),
        );
    }

    fn successOp(_: ?*c.pa_context, success: c_int, user_data: ?*anyopaque) callconv(.C) void {
        var self = @ptrCast(*Player, @alignCast(@alignOf(*Player), user_data.?));
        if (success == 1)
            lib.pa_threaded_mainloop_signal(self.main_loop, 0);
    }

    pub fn volume(self: *Player) !f32 {
        lib.pa_threaded_mainloop_lock(self.main_loop);
        defer lib.pa_threaded_mainloop_unlock(self.main_loop);

        performOperation(
            self.main_loop,
            lib.pa_context_get_sink_input_info(
                self.ctx,
                lib.pa_stream_get_index(self.stream),
                sinkInputInfoOp,
                self,
            ),
        );

        return self.vol;
    }

    fn sinkInputInfoOp(_: ?*c.pa_context, info: [*c]const c.pa_sink_input_info, eol: c_int, user_data: ?*anyopaque) callconv(.C) void {
        var self = @ptrCast(*Player, @alignCast(@alignOf(*Player), user_data.?));

        if (eol != 0) {
            lib.pa_threaded_mainloop_signal(self.main_loop, 0);
            return;
        }

        self.vol = @intToFloat(f32, info.*.volume.values[0]) / @intToFloat(f32, c.PA_VOLUME_NORM);
    }
};

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
            c.PA_OPERATION_CANCELLED => {
                std.debug.assert(false);
                lib.pa_operation_unref(op);
                return;
            },
            else => unreachable,
        }
    }
}

pub const available_formats = &[_]main.Format{
    .u8,  .i16,
    .i24, .i24_4b,
    .i32, .f32,
};

pub fn fromPAChannelPos(pos: c.pa_channel_position_t) !main.Channel.Id {
    return switch (pos) {
        c.PA_CHANNEL_POSITION_MONO => .front_center,
        c.PA_CHANNEL_POSITION_FRONT_LEFT => .front_left, // PA_CHANNEL_POSITION_LEFT
        c.PA_CHANNEL_POSITION_FRONT_RIGHT => .front_right, // PA_CHANNEL_POSITION_RIGHT
        c.PA_CHANNEL_POSITION_FRONT_CENTER => .front_center, // PA_CHANNEL_POSITION_CENTER
        c.PA_CHANNEL_POSITION_REAR_CENTER => .back_center,
        c.PA_CHANNEL_POSITION_LFE => .lfe, // PA_CHANNEL_POSITION_SUBWOOFER
        c.PA_CHANNEL_POSITION_FRONT_LEFT_OF_CENTER => .front_left_center,
        c.PA_CHANNEL_POSITION_FRONT_RIGHT_OF_CENTER => .front_right_center,
        c.PA_CHANNEL_POSITION_SIDE_LEFT => .side_left,
        c.PA_CHANNEL_POSITION_SIDE_RIGHT => .side_right,

        // TODO: .front_center?
        c.PA_CHANNEL_POSITION_AUX0...c.PA_CHANNEL_POSITION_AUX31 => error.Invalid,

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

pub fn toPAFormat(format: main.Format) !c.pa_sample_format_t {
    return switch (format) {
        .u8 => c.PA_SAMPLE_U8,
        .i16 => if (is_little) c.PA_SAMPLE_S16LE else c.PA_SAMPLE_S16BE,
        .i24 => if (is_little) c.PA_SAMPLE_S24LE else c.PA_SAMPLE_S24LE,
        .i24_4b => if (is_little) c.PA_SAMPLE_S24_32LE else c.PA_SAMPLE_S24_32BE,
        .i32 => if (is_little) c.PA_SAMPLE_S32LE else c.PA_SAMPLE_S32BE,
        .f32 => if (is_little) c.PA_SAMPLE_FLOAT32LE else c.PA_SAMPLE_FLOAT32BE,

        .i8 => error.Invalid,
    };
}

pub fn toPAChannelMap(channels: []const main.Channel) !c.pa_channel_map {
    var channel_map: c.pa_channel_map = undefined;
    channel_map.channels = @intCast(u5, channels.len);
    for (channels) |ch, i|
        channel_map.map[i] = try toPAChannelPos(ch.id);
    return channel_map;
}

fn toPAChannelPos(channel_id: main.Channel.Id) !c.pa_channel_position_t {
    return switch (channel_id) {
        .front_left => c.PA_CHANNEL_POSITION_FRONT_LEFT,
        .front_right => c.PA_CHANNEL_POSITION_FRONT_RIGHT,
        .front_center => c.PA_CHANNEL_POSITION_FRONT_CENTER,
        .lfe => c.PA_CHANNEL_POSITION_LFE,
        .front_left_center => c.PA_CHANNEL_POSITION_FRONT_LEFT_OF_CENTER,
        .front_right_center => c.PA_CHANNEL_POSITION_FRONT_RIGHT_OF_CENTER,
        .back_center => c.PA_CHANNEL_POSITION_REAR_CENTER,
        .side_left => c.PA_CHANNEL_POSITION_SIDE_LEFT,
        .side_right => c.PA_CHANNEL_POSITION_SIDE_RIGHT,
        .top_center => c.PA_CHANNEL_POSITION_TOP_CENTER,
        .top_front_left => c.PA_CHANNEL_POSITION_TOP_FRONT_LEFT,
        .top_front_center => c.PA_CHANNEL_POSITION_TOP_FRONT_CENTER,
        .top_front_right => c.PA_CHANNEL_POSITION_TOP_FRONT_RIGHT,
        .top_back_left => c.PA_CHANNEL_POSITION_TOP_REAR_LEFT,
        .top_back_center => c.PA_CHANNEL_POSITION_TOP_REAR_CENTER,
        .top_back_right => c.PA_CHANNEL_POSITION_TOP_REAR_RIGHT,
    };
}

test {
    std.testing.refAllDeclsRecursive(@This());
}
