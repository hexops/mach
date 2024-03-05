const std = @import("std");
const c = @cImport(@cInclude("jack/jack.h"));
const main = @import("main.zig");
const backends = @import("backends.zig");
const util = @import("util.zig");

var lib: Lib = undefined;
const Lib = struct {
    handle: std.DynLib,

    jack_free: *const fn (ptr: ?*anyopaque) callconv(.C) void,
    jack_set_error_function: *const fn (?*const fn ([*c]const u8) callconv(.C) void) callconv(.C) void,
    jack_set_info_function: *const fn (?*const fn ([*c]const u8) callconv(.C) void) callconv(.C) void,
    jack_client_open: *const fn ([*c]const u8, c.jack_options_t, [*c]c.jack_status_t, ...) callconv(.C) ?*c.jack_client_t,
    jack_client_close: *const fn (?*c.jack_client_t) callconv(.C) c_int,
    jack_connect: *const fn (?*c.jack_client_t, [*c]const u8, [*c]const u8) callconv(.C) c_int,
    jack_disconnect: *const fn (?*c.jack_client_t, [*c]const u8, [*c]const u8) callconv(.C) c_int,
    jack_activate: *const fn (?*c.jack_client_t) callconv(.C) c_int,
    jack_deactivate: *const fn (?*c.jack_client_t) callconv(.C) c_int,
    jack_port_by_name: *const fn (?*c.jack_client_t, [*c]const u8) callconv(.C) ?*c.jack_port_t,
    jack_port_register: *const fn (?*c.jack_client_t, [*c]const u8, [*c]const u8, c_ulong, c_ulong) callconv(.C) ?*c.jack_port_t,
    jack_set_sample_rate_callback: *const fn (?*c.jack_client_t, c.JackSampleRateCallback, ?*anyopaque) callconv(.C) c_int,
    jack_set_port_registration_callback: *const fn (?*c.jack_client_t, c.JackPortRegistrationCallback, ?*anyopaque) callconv(.C) c_int,
    jack_set_process_callback: *const fn (?*c.jack_client_t, c.JackProcessCallback, ?*anyopaque) callconv(.C) c_int,
    jack_set_port_rename_callback: *const fn (?*c.jack_client_t, c.JackPortRenameCallback, ?*anyopaque) callconv(.C) c_int,
    jack_get_sample_rate: *const fn (?*c.jack_client_t) callconv(.C) c.jack_nframes_t,
    jack_get_ports: *const fn (?*c.jack_client_t, [*c]const u8, [*c]const u8, c_ulong) callconv(.C) [*c][*c]const u8,
    jack_port_type: *const fn (port: ?*const c.jack_port_t) callconv(.C) [*c]const u8,
    jack_port_flags: *const fn (port: ?*const c.jack_port_t) callconv(.C) c_int,
    jack_port_name: *const fn (?*const c.jack_port_t) callconv(.C) [*c]const u8,
    jack_port_get_buffer: *const fn (?*c.jack_port_t, c.jack_nframes_t) callconv(.C) ?*anyopaque,
    jack_port_connected_to: *const fn (?*const c.jack_port_t, [*c]const u8) callconv(.C) c_int,
    jack_port_type_size: *const fn () c_int,

    pub fn load() !void {
        lib.handle = std.DynLib.openZ("libjack.so") catch return error.LibraryNotFound;
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
    client: *c.jack_client_t,
    watcher: ?Watcher,

    const Watcher = struct {
        deviceChangeFn: main.Context.DeviceChangeFn,
        user_data: ?*anyopaque,
    };

    pub fn init(allocator: std.mem.Allocator, options: main.Context.Options) !backends.Context {
        try Lib.load();

        lib.jack_set_error_function(@as(?*const fn ([*c]const u8) callconv(.C) void, @ptrCast(&util.doNothing)));
        lib.jack_set_info_function(@as(?*const fn ([*c]const u8) callconv(.C) void, @ptrCast(&util.doNothing)));

        var status: c.jack_status_t = 0;
        const ctx = try allocator.create(Context);
        errdefer allocator.destroy(ctx);
        ctx.* = .{
            .allocator = allocator,
            .devices_info = util.DevicesInfo.init(),
            .client = lib.jack_client_open(options.app_name.ptr, c.JackNoStartServer, &status) orelse {
                std.debug.assert(status & c.JackInvalidOption == 0);
                return if (status & c.JackShmFailure != 0)
                    error.SystemResources
                else
                    error.ConnectionRefused;
            },
            .watcher = if (options.deviceChangeFn) |deviceChangeFn| .{
                .deviceChangeFn = deviceChangeFn,
                .user_data = options.user_data,
            } else null,
        };

        if (options.deviceChangeFn) |_| {
            if (lib.jack_set_sample_rate_callback(ctx.client, sampleRateCallback, ctx) != 0 or
                lib.jack_set_port_registration_callback(ctx.client, portRegistrationCallback, ctx) != 0 or
                lib.jack_set_port_rename_callback(ctx.client, portRenameCalllback, ctx) != 0)
                return error.ConnectionRefused;
        }

        return .{ .jack = ctx };
    }

    pub fn deinit(ctx: *Context) void {
        for (ctx.devices_info.list.items) |device|
            freeDevice(ctx.allocator, device);
        ctx.devices_info.list.deinit(ctx.allocator);
        _ = lib.jack_client_close(ctx.client);
        ctx.allocator.destroy(ctx);
        lib.handle.close();
    }

    pub fn refresh(ctx: *Context) !void {
        for (ctx.devices_info.list.items) |d|
            freeDevice(ctx.allocator, d);
        ctx.devices_info.clear();

        const sample_rate = @as(u24, @intCast(lib.jack_get_sample_rate(ctx.client)));

        const port_names = lib.jack_get_ports(ctx.client, null, null, 0) orelse
            return error.OutOfMemory;
        defer lib.jack_free(@as(?*anyopaque, @ptrCast(port_names)));

        var i: usize = 0;
        outer: while (port_names[i] != null) : (i += 1) {
            const port = lib.jack_port_by_name(ctx.client, port_names[i]) orelse break;
            const port_type = lib.jack_port_type(port)[0..@as(usize, @intCast(lib.jack_port_type_size()))];
            if (!std.mem.startsWith(u8, port_type, c.JACK_DEFAULT_AUDIO_TYPE))
                continue;

            const flags = lib.jack_port_flags(port);
            const mode: main.Device.Mode = if (flags & c.JackPortIsInput != 0) .capture else .playback;

            const name = std.mem.span(port_names[i]);
            const id = std.mem.sliceTo(name, ':');

            for (ctx.devices_info.list.items) |*dev| {
                if (std.mem.eql(u8, dev.id, id) and mode == dev.mode) {
                    const new_ch: main.ChannelPosition = @enumFromInt(dev.channels.len);
                    dev.channels = try ctx.allocator.realloc(dev.channels, dev.channels.len + 1);
                    dev.channels[dev.channels.len - 1] = new_ch;
                    break :outer;
                }
            }

            const device = main.Device{
                .id = try ctx.allocator.dupeZ(u8, id),
                .name = name,
                .mode = mode,
                .channels = blk: {
                    var channels = try ctx.allocator.alloc(main.ChannelPosition, 1);
                    channels[0] = .front_center;
                    break :blk channels;
                },
                .formats = &.{.f32},
                .sample_rate = .{
                    .min = sample_rate,
                    .max = sample_rate,
                },
            };

            try ctx.devices_info.list.append(ctx.allocator, device);
            if (ctx.devices_info.default(mode) == null) {
                ctx.devices_info.setDefault(mode, ctx.devices_info.list.items.len - 1);
            }
        }
    }

    fn sampleRateCallback(_: c.jack_nframes_t, arg: ?*anyopaque) callconv(.C) c_int {
        var ctx = @as(*Context, @ptrCast(@alignCast(arg.?)));
        ctx.watcher.?.deviceChangeFn(ctx.watcher.?.user_data);
        return 0;
    }

    fn portRegistrationCallback(_: c.jack_port_id_t, _: c_int, arg: ?*anyopaque) callconv(.C) void {
        var ctx = @as(*Context, @ptrCast(@alignCast(arg.?)));
        ctx.watcher.?.deviceChangeFn(ctx.watcher.?.user_data);
    }

    fn portRenameCalllback(_: c.jack_port_id_t, _: [*c]const u8, _: [*c]const u8, arg: ?*anyopaque) callconv(.C) void {
        var ctx = @as(*Context, @ptrCast(@alignCast(arg.?)));
        ctx.watcher.?.deviceChangeFn(ctx.watcher.?.user_data);
    }

    pub fn devices(ctx: *Context) []const main.Device {
        return ctx.devices_info.list.items;
    }

    pub fn defaultDevice(ctx: *Context, mode: main.Device.Mode) ?main.Device {
        return ctx.devices_info.default(mode);
    }

    pub fn createPlayer(ctx: *Context, device: main.Device, writeFn: main.WriteFn, options: main.StreamOptions) !backends.Player {
        var ports = try ctx.allocator.alloc(*c.jack_port_t, device.channels.len);
        var dest_ports = try ctx.allocator.alloc([:0]const u8, ports.len);
        var buf: [64]u8 = undefined;
        for (device.channels, 0..) |_, i| {
            const port_name = std.fmt.bufPrintZ(&buf, "playback_{d}", .{i + 1}) catch unreachable;
            const dest_name = try std.fmt.allocPrintZ(ctx.allocator, "{s}:{s}", .{ device.id, port_name });
            ports[i] = lib.jack_port_register(ctx.client, port_name.ptr, c.JACK_DEFAULT_AUDIO_TYPE, c.JackPortIsOutput, 0) orelse
                return error.OpeningDevice;
            dest_ports[i] = dest_name;
        }

        const player = try ctx.allocator.create(Player);
        player.* = .{
            .allocator = ctx.allocator,
            .client = ctx.client,
            .ports = ports,
            .dest_ports = dest_ports,
            .device = device,
            .vol = 1.0,
            .writeFn = writeFn,
            .user_data = options.user_data,
            .channels = device.channels,
            .format = .f32,
        };
        return .{ .jack = player };
    }

    pub fn createRecorder(ctx: *Context, device: main.Device, readFn: main.ReadFn, options: main.StreamOptions) !backends.Recorder {
        var ports = try ctx.allocator.alloc(*c.jack_port_t, device.channels.len);
        var dest_ports = try ctx.allocator.alloc([:0]const u8, ports.len);
        var buf: [64]u8 = undefined;
        for (device.channels, 0..) |_, i| {
            const port_name = std.fmt.bufPrintZ(&buf, "capture_{d}", .{i + 1}) catch unreachable;
            const dest_name = try std.fmt.allocPrintZ(ctx.allocator, "{s}:{s}", .{ device.id, port_name });
            ports[i] = lib.jack_port_register(ctx.client, port_name.ptr, c.JACK_DEFAULT_AUDIO_TYPE, c.JackPortIsInput, 0) orelse
                return error.OpeningDevice;
            dest_ports[i] = dest_name;
        }

        const recorder = try ctx.allocator.create(Recorder);
        recorder.* = .{
            .allocator = ctx.allocator,
            .client = ctx.client,
            .ports = ports,
            .dest_ports = dest_ports,
            .device = device,
            .vol = 1.0,
            .readFn = readFn,
            .user_data = options.user_data,
            .channels = device.channels,
            .format = .f32,
        };
        return .{ .jack = recorder };
    }
};

pub const Player = struct {
    allocator: std.mem.Allocator,
    client: *c.jack_client_t,
    ports: []const *c.jack_port_t,
    dest_ports: []const [:0]const u8,
    device: main.Device,
    vol: f32,
    writeFn: main.WriteFn,
    user_data: ?*anyopaque,

    channels: []main.ChannelPosition,
    format: main.Format,

    pub fn deinit(player: *Player) void {
        player.allocator.free(player.ports);
        for (player.dest_ports) |d|
            player.allocator.free(d);
        player.allocator.free(player.dest_ports);
        _ = lib.jack_deactivate(player.client);
        player.allocator.destroy(player);
    }

    pub fn start(player: *Player) !void {
        if (lib.jack_set_process_callback(player.client, processCallback, player) != 0)
            return error.CannotPlay;

        if (lib.jack_activate(player.client) != 0)
            return error.CannotPlay;

        for (player.ports, 0..) |port, i| {
            if (lib.jack_connect(player.client, lib.jack_port_name(port), player.dest_ports[i].ptr) != 0)
                return error.CannotPlay;
        }
    }

    fn processCallback(n_frames: c.jack_nframes_t, player_opaque: ?*anyopaque) callconv(.C) c_int {
        const player = @as(*Player, @ptrCast(@alignCast(player_opaque.?)));

        if (true) @panic("TODO: convert planar to interleaved");
        // for (player.channels, 0..) |*ch, i| {
        //     ch.*.ptr = @as([*]u8, @ptrCast(lib.jack_port_get_buffer(player.ports[i], n_frames)));
        // }
        player.writeFn(player.user_data, undefined, n_frames);

        return 0;
    }

    pub fn play(player: *Player) !void {
        for (player.ports, 0..) |port, i| {
            if (lib.jack_connect(player.client, lib.jack_port_name(port), player.dest_ports[i].ptr) != 0)
                return error.CannotPlay;
        }
    }

    pub fn pause(player: *Player) !void {
        for (player.ports, 0..) |port, i| {
            if (lib.jack_disconnect(player.client, lib.jack_port_name(port), player.dest_ports[i].ptr) != 0)
                return error.CannotPause;
        }
    }

    pub fn paused(player: *Player) bool {
        for (player.ports, 0..) |port, i| {
            if (lib.jack_port_connected_to(port, player.dest_ports[i].ptr) == 1)
                return false;
        }
        return true;
    }

    pub fn setVolume(player: *Player, vol: f32) !void {
        player.vol = vol;
    }

    pub fn volume(player: *Player) !f32 {
        return player.vol;
    }

    pub fn sampleRate(player: *Player) u24 {
        return @as(u24, @intCast(lib.jack_get_sample_rate(player.client)));
    }
};

pub const Recorder = struct {
    allocator: std.mem.Allocator,
    client: *c.jack_client_t,
    ports: []const *c.jack_port_t,
    dest_ports: []const [:0]const u8,
    device: main.Device,
    vol: f32,
    readFn: main.ReadFn,
    user_data: ?*anyopaque,

    channels: []main.ChannelPosition,
    format: main.Format,

    pub fn deinit(recorder: *Recorder) void {
        recorder.allocator.free(recorder.ports);
        for (recorder.dest_ports) |d|
            recorder.allocator.free(d);
        recorder.allocator.free(recorder.dest_ports);
        _ = lib.jack_deactivate(recorder.client);
        recorder.allocator.destroy(recorder);
    }

    pub fn start(recorder: *Recorder) !void {
        if (lib.jack_set_process_callback(recorder.client, processCallback, recorder) != 0)
            return error.CannotRecord;

        if (lib.jack_activate(recorder.client) != 0)
            return error.CannotRecord;

        for (recorder.ports, 0..) |port, i| {
            if (lib.jack_connect(recorder.client, lib.jack_port_name(port), recorder.dest_ports[i].ptr) != 0)
                return error.CannotRecord;
        }
    }

    fn processCallback(n_frames: c.jack_nframes_t, recorder_opaque: ?*anyopaque) callconv(.C) c_int {
        const recorder = @as(*Recorder, @ptrCast(@alignCast(recorder_opaque.?)));

        if (true) @panic("TODO: convert planar to interleaved");
        // for (recorder.channels, 0..) |*ch, i| {
        //     ch.*.ptr = @as([*]u8, @ptrCast(lib.jack_port_get_buffer(recorder.ports[i], n_frames)));
        // }
        recorder.readFn(recorder.user_data, n_frames);

        return 0;
    }

    pub fn record(recorder: *Recorder) !void {
        for (recorder.ports, 0..) |port, i| {
            if (lib.jack_connect(recorder.client, lib.jack_port_name(port), recorder.dest_ports[i].ptr) != 0)
                return error.CannotRecord;
        }
    }

    pub fn pause(recorder: *Recorder) !void {
        for (recorder.ports, 0..) |port, i| {
            if (lib.jack_disconnect(recorder.client, lib.jack_port_name(port), recorder.dest_ports[i].ptr) != 0)
                return error.CannotPause;
        }
    }

    pub fn paused(recorder: *Recorder) bool {
        for (recorder.ports, 0..) |port, i| {
            if (lib.jack_port_connected_to(port, recorder.dest_ports[i].ptr) == 1)
                return false;
        }
        return true;
    }

    pub fn setVolume(recorder: *Recorder, vol: f32) !void {
        recorder.vol = vol;
    }

    pub fn volume(recorder: *Recorder) !f32 {
        return recorder.vol;
    }

    pub fn sampleRate(recorder: *Recorder) u24 {
        return @as(u24, @intCast(lib.jack_get_sample_rate(recorder.client)));
    }
};

pub fn freeDevice(allocator: std.mem.Allocator, device: main.Device) void {
    allocator.free(device.id);
    allocator.free(device.channels);
}
