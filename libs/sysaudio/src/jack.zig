const std = @import("std");
const c = @cImport(@cInclude("jack/jack.h"));
const main = @import("main.zig");
const backends = @import("backends.zig");
const util = @import("util.zig");

const lib = struct {
    var handle: std.DynLib = undefined;

    var jack_free: *const fn (ptr: ?*anyopaque) callconv(.C) void = undefined;
    var jack_set_error_function: *const fn (?*const fn ([*c]const u8) callconv(.C) void) callconv(.C) void = undefined;
    var jack_set_info_function: *const fn (?*const fn ([*c]const u8) callconv(.C) void) callconv(.C) void = undefined;
    var jack_client_open: *const fn ([*c]const u8, c.jack_options_t, [*c]c.jack_status_t, ...) callconv(.C) ?*c.jack_client_t = undefined;
    var jack_client_close: *const fn (?*c.jack_client_t) callconv(.C) c_int = undefined;
    var jack_connect: *const fn (?*c.jack_client_t, [*c]const u8, [*c]const u8) callconv(.C) c_int = undefined;
    var jack_disconnect: *const fn (?*c.jack_client_t, [*c]const u8, [*c]const u8) callconv(.C) c_int = undefined;
    var jack_activate: *const fn (?*c.jack_client_t) callconv(.C) c_int = undefined;
    var jack_deactivate: *const fn (?*c.jack_client_t) callconv(.C) c_int = undefined;
    var jack_port_by_name: *const fn (?*c.jack_client_t, [*c]const u8) callconv(.C) ?*c.jack_port_t = undefined;
    var jack_port_register: *const fn (?*c.jack_client_t, [*c]const u8, [*c]const u8, c_ulong, c_ulong) callconv(.C) ?*c.jack_port_t = undefined;
    var jack_set_sample_rate_callback: *const fn (?*c.jack_client_t, c.JackSampleRateCallback, ?*anyopaque) callconv(.C) c_int = undefined;
    var jack_set_port_registration_callback: *const fn (?*c.jack_client_t, c.JackPortRegistrationCallback, ?*anyopaque) callconv(.C) c_int = undefined;
    var jack_set_process_callback: *const fn (?*c.jack_client_t, c.JackProcessCallback, ?*anyopaque) callconv(.C) c_int = undefined;
    var jack_set_port_rename_callback: *const fn (?*c.jack_client_t, c.JackPortRenameCallback, ?*anyopaque) callconv(.C) c_int = undefined;
    var jack_get_sample_rate: *const fn (?*c.jack_client_t) callconv(.C) c.jack_nframes_t = undefined;
    var jack_get_ports: *const fn (?*c.jack_client_t, [*c]const u8, [*c]const u8, c_ulong) callconv(.C) [*c][*c]const u8 = undefined;
    var jack_port_type: *const fn (port: ?*const c.jack_port_t) callconv(.C) [*c]const u8 = undefined;
    var jack_port_flags: *const fn (port: ?*const c.jack_port_t) callconv(.C) c_int = undefined;
    var jack_port_name: *const fn (?*const c.jack_port_t) callconv(.C) [*c]const u8 = undefined;
    var jack_port_get_buffer: *const fn (?*c.jack_port_t, c.jack_nframes_t) callconv(.C) ?*anyopaque = undefined;
    var jack_port_connected_to: *const fn (?*const c.jack_port_t, [*c]const u8) callconv(.C) c_int = undefined;
    var jack_port_type_size: *const fn () c_int = undefined;

    pub fn load() !void {
        handle = std.DynLib.openZ("libjack.so") catch return error.LibraryNotFound;

        jack_free = handle.lookup(@TypeOf(jack_free), "jack_free") orelse return error.SymbolLookup;
        jack_set_error_function = handle.lookup(@TypeOf(jack_set_error_function), "jack_set_error_function") orelse return error.SymbolLookup;
        jack_set_info_function = handle.lookup(@TypeOf(jack_set_info_function), "jack_set_info_function") orelse return error.SymbolLookup;
        jack_client_open = handle.lookup(@TypeOf(jack_client_open), "jack_client_open") orelse return error.SymbolLookup;
        jack_client_close = handle.lookup(@TypeOf(jack_client_close), "jack_client_close") orelse return error.SymbolLookup;
        jack_connect = handle.lookup(@TypeOf(jack_connect), "jack_connect") orelse return error.SymbolLookup;
        jack_disconnect = handle.lookup(@TypeOf(jack_disconnect), "jack_disconnect") orelse return error.SymbolLookup;
        jack_activate = handle.lookup(@TypeOf(jack_activate), "jack_activate") orelse return error.SymbolLookup;
        jack_deactivate = handle.lookup(@TypeOf(jack_deactivate), "jack_deactivate") orelse return error.SymbolLookup;
        jack_port_by_name = handle.lookup(@TypeOf(jack_port_by_name), "jack_port_by_name") orelse return error.SymbolLookup;
        jack_port_register = handle.lookup(@TypeOf(jack_port_register), "jack_port_register") orelse return error.SymbolLookup;
        jack_set_sample_rate_callback = handle.lookup(@TypeOf(jack_set_sample_rate_callback), "jack_set_sample_rate_callback") orelse return error.SymbolLookup;
        jack_set_port_registration_callback = handle.lookup(@TypeOf(jack_set_port_registration_callback), "jack_set_port_registration_callback") orelse return error.SymbolLookup;
        jack_set_process_callback = handle.lookup(@TypeOf(jack_set_process_callback), "jack_set_process_callback") orelse return error.SymbolLookup;
        jack_set_port_rename_callback = handle.lookup(@TypeOf(jack_set_port_rename_callback), "jack_set_port_rename_callback") orelse return error.SymbolLookup;
        jack_get_sample_rate = handle.lookup(@TypeOf(jack_get_sample_rate), "jack_get_sample_rate") orelse return error.SymbolLookup;
        jack_get_ports = handle.lookup(@TypeOf(jack_get_ports), "jack_get_ports") orelse return error.SymbolLookup;
        jack_port_type = handle.lookup(@TypeOf(jack_port_type), "jack_port_type") orelse return error.SymbolLookup;
        jack_port_flags = handle.lookup(@TypeOf(jack_port_flags), "jack_port_flags") orelse return error.SymbolLookup;
        jack_port_name = handle.lookup(@TypeOf(jack_port_name), "jack_port_name") orelse return error.SymbolLookup;
        jack_port_get_buffer = handle.lookup(@TypeOf(jack_port_get_buffer), "jack_port_get_buffer") orelse return error.SymbolLookup;
        jack_port_connected_to = handle.lookup(@TypeOf(jack_port_connected_to), "jack_port_connected_to") orelse return error.SymbolLookup;
        jack_port_type_size = handle.lookup(@TypeOf(jack_port_type_size), "jack_port_type_size") orelse return error.SymbolLookup;
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

    pub fn init(allocator: std.mem.Allocator, options: main.Context.Options) !backends.BackendContext {
        try lib.load();

        lib.jack_set_error_function(@ptrCast(?*const fn ([*c]const u8) callconv(.C) void, &util.doNothing));
        lib.jack_set_info_function(@ptrCast(?*const fn ([*c]const u8) callconv(.C) void, &util.doNothing));

        var status: c.jack_status_t = 0;
        var self = try allocator.create(Context);
        errdefer allocator.destroy(self);
        self.* = .{
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
            if (lib.jack_set_sample_rate_callback(self.client, sampleRateCallback, self) != 0 or
                lib.jack_set_port_registration_callback(self.client, portRegistrationCallback, self) != 0 or
                lib.jack_set_port_rename_callback(self.client, portRenameCalllback, self) != 0)
                return error.ConnectionRefused;
        }

        return .{ .jack = self };
    }

    pub fn deinit(self: *Context) void {
        for (self.devices_info.list.items) |device|
            freeDevice(self.allocator, device);
        self.devices_info.list.deinit(self.allocator);
        _ = lib.jack_client_close(self.client);
        self.allocator.destroy(self);
        lib.handle.close();
    }

    pub fn refresh(self: *Context) !void {
        for (self.devices_info.list.items) |d|
            freeDevice(self.allocator, d);
        self.devices_info.clear(self.allocator);

        const sample_rate = @intCast(u24, lib.jack_get_sample_rate(self.client));

        const port_names = lib.jack_get_ports(self.client, null, null, 0) orelse
            return error.OutOfMemory;
        defer lib.jack_free(@ptrCast(?*anyopaque, port_names));

        var i: usize = 0;
        outer: while (port_names[i] != null) : (i += 1) {
            const port = lib.jack_port_by_name(self.client, port_names[i]) orelse break;
            const port_type = lib.jack_port_type(port)[0..@intCast(usize, lib.jack_port_type_size())];
            if (!std.mem.startsWith(u8, port_type, c.JACK_DEFAULT_AUDIO_TYPE))
                continue;

            const flags = lib.jack_port_flags(port);
            const mode: main.Device.Mode = if (flags & c.JackPortIsInput != 0) .capture else .playback;

            const name = std.mem.span(port_names[i]);
            const id = std.mem.sliceTo(name, ':');

            for (self.devices_info.list.items) |*dev| {
                if (std.mem.eql(u8, dev.id, id) and mode == dev.mode) {
                    const new_ch = main.Channel{
                        .id = @intToEnum(main.Channel.Id, dev.channels.len),
                    };
                    dev.channels = try self.allocator.realloc(dev.channels, dev.channels.len + 1);
                    dev.channels[dev.channels.len - 1] = new_ch;
                    break :outer;
                }
            }

            var device = main.Device{
                .id = try self.allocator.dupeZ(u8, id),
                .name = name,
                .mode = mode,
                .channels = blk: {
                    var channels = try self.allocator.alloc(main.Channel, 1);
                    channels[0] = .{ .id = @intToEnum(main.Channel.Id, 0) };
                    break :blk channels;
                },
                .formats = &.{.f32},
                .sample_rate = .{
                    .min = sample_rate,
                    .max = sample_rate,
                },
            };

            try self.devices_info.list.append(self.allocator, device);
            if (self.devices_info.default(mode) == null) {
                self.devices_info.setDefault(mode, self.devices_info.list.items.len - 1);
            }
        }
    }

    fn sampleRateCallback(_: c.jack_nframes_t, arg: ?*anyopaque) callconv(.C) c_int {
        var self = @ptrCast(*Context, @alignCast(@alignOf(*Context), arg.?));
        self.watcher.?.deviceChangeFn(self.watcher.?.user_data);
        return 0;
    }

    fn portRegistrationCallback(_: c.jack_port_id_t, _: c_int, arg: ?*anyopaque) callconv(.C) void {
        var self = @ptrCast(*Context, @alignCast(@alignOf(*Context), arg.?));
        self.watcher.?.deviceChangeFn(self.watcher.?.user_data);
    }

    fn portRenameCalllback(_: c.jack_port_id_t, _: [*c]const u8, _: [*c]const u8, arg: ?*anyopaque) callconv(.C) void {
        var self = @ptrCast(*Context, @alignCast(@alignOf(*Context), arg.?));
        self.watcher.?.deviceChangeFn(self.watcher.?.user_data);
    }

    pub fn devices(self: *Context) []const main.Device {
        return self.devices_info.list.items;
    }

    pub fn defaultDevice(self: *Context, mode: main.Device.Mode) ?main.Device {
        return self.devices_info.default(mode);
    }

    pub fn createPlayer(self: *Context, device: main.Device, writeFn: main.WriteFn, options: main.Player.Options) !backends.BackendPlayer {
        var ports = try self.allocator.alloc(*c.jack_port_t, device.channels.len);
        var dest_ports = try self.allocator.alloc([:0]const u8, ports.len);
        var buf: [64]u8 = undefined;
        for (device.channels, 0..) |_, i| {
            const port_name = std.fmt.bufPrintZ(&buf, "playback_{d}", .{i + 1}) catch unreachable;
            const dest_name = try std.fmt.allocPrintZ(self.allocator, "{s}:{s}", .{ device.id, port_name });
            ports[i] = lib.jack_port_register(self.client, port_name.ptr, c.JACK_DEFAULT_AUDIO_TYPE, c.JackPortIsOutput, 0) orelse
                return error.OpeningDevice;
            dest_ports[i] = dest_name;
        }

        var player = try self.allocator.create(Player);
        player.* = .{
            .allocator = self.allocator,
            .mutex = .{},
            .client = self.client,
            .ports = ports,
            .dest_ports = dest_ports,
            .device = device,
            .vol = 1.0,
            .writeFn = writeFn,
            .user_data = options.user_data,
            .channels = device.channels,
            .format = .f32,
            .write_step = main.Format.size(.f32),
        };
        return .{ .jack = player };
    }
};

pub const Player = struct {
    allocator: std.mem.Allocator,
    mutex: std.Thread.Mutex,
    client: *c.jack_client_t,
    ports: []const *c.jack_port_t,
    dest_ports: []const [:0]const u8,
    device: main.Device,
    vol: f32,
    writeFn: main.WriteFn,
    user_data: ?*anyopaque,

    channels: []main.Channel,
    format: main.Format,
    write_step: u8,

    pub fn deinit(self: *Player) void {
        self.allocator.free(self.ports);
        for (self.dest_ports) |d|
            self.allocator.free(d);
        self.allocator.free(self.dest_ports);
        _ = lib.jack_deactivate(self.client);
        self.allocator.destroy(self);
    }

    pub fn start(self: *Player) !void {
        if (lib.jack_set_process_callback(self.client, processCallback, self) != 0)
            return error.CannotPlay;

        if (lib.jack_activate(self.client) != 0)
            return error.CannotPlay;

        for (self.ports, 0..) |port, i| {
            if (lib.jack_connect(self.client, lib.jack_port_name(port), self.dest_ports[i].ptr) != 0)
                return error.CannotPlay;
        }
    }

    fn processCallback(n_frames: c.jack_nframes_t, self_opaque: ?*anyopaque) callconv(.C) c_int {
        const self = @ptrCast(*Player, @alignCast(@alignOf(*Player), self_opaque.?));

        for (self.channels, 0..) |*ch, i| {
            ch.*.ptr = @ptrCast([*]u8, lib.jack_port_get_buffer(self.ports[i], n_frames));
        }
        self.writeFn(self.user_data, n_frames);

        return 0;
    }

    pub fn play(self: *Player) !void {
        self.mutex.lock();
        defer self.mutex.unlock();
        for (self.ports, 0..) |port, i| {
            if (lib.jack_connect(self.client, lib.jack_port_name(port), self.dest_ports[i].ptr) != 0)
                return error.CannotPlay;
        }
    }

    pub fn pause(self: *Player) !void {
        self.mutex.lock();
        defer self.mutex.unlock();
        for (self.ports, 0..) |port, i| {
            if (lib.jack_disconnect(self.client, lib.jack_port_name(port), self.dest_ports[i].ptr) != 0)
                return error.CannotPause;
        }
    }

    pub fn paused(self: *Player) bool {
        self.mutex.lock();
        defer self.mutex.unlock();
        for (self.ports, 0..) |port, i| {
            if (lib.jack_port_connected_to(port, self.dest_ports[i].ptr) == 1)
                return false;
        }
        return true;
    }

    pub fn setVolume(self: *Player, vol: f32) !void {
        self.vol = vol;
    }

    pub fn volume(self: *Player) !f32 {
        return self.vol;
    }

    pub fn sampleRate(self: Player) u24 {
        return @intCast(u24, lib.jack_get_sample_rate(self.client));
    }
};

pub fn freeDevice(allocator: std.mem.Allocator, device: main.Device) void {
    allocator.free(device.id);
    allocator.free(device.channels);
}

test {
    std.testing.refAllDeclsRecursive(@This());
}
