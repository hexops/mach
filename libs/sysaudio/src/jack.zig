const std = @import("std");
const c = @cImport(@cInclude("jack/jack.h"));
const main = @import("main.zig");
const backends = @import("backends.zig");
const util = @import("util.zig");

pub const Context = struct {
    allocator: std.mem.Allocator,
    devices_info: util.DevicesInfo,
    client: *c.jack_client_t,
    watcher: ?Watcher,

    const Watcher = struct {
        deviceChangeFn: main.DeviceChangeFn,
        user_data: ?*anyopaque,
    };

    pub fn init(allocator: std.mem.Allocator, options: main.Context.Options) !backends.BackendContext {
        c.jack_set_error_function(@ptrCast(?*const fn ([*c]const u8) callconv(.C) void, &util.doNothing));
        c.jack_set_info_function(@ptrCast(?*const fn ([*c]const u8) callconv(.C) void, &util.doNothing));

        var status: c.jack_status_t = 0;
        var self = try allocator.create(Context);
        errdefer allocator.destroy(self);
        self.* = .{
            .allocator = allocator,
            .devices_info = util.DevicesInfo.init(),
            .client = c.jack_client_open(options.app_name.ptr, c.JackNoStartServer, &status) orelse {
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
            if (c.jack_set_sample_rate_callback(self.client, sampleRateCallback, self) != 0 or
                c.jack_set_port_registration_callback(self.client, portRegistrationCallback, self) != 0 or
                c.jack_set_port_rename_callback(self.client, portRenameCalllback, self) != 0)
                return error.ConnectionRefused;
        }

        return .{ .jack = self };
    }

    pub fn deinit(self: *Context) void {
        for (self.devices_info.list.items) |device|
            freeDevice(self.allocator, device);
        self.devices_info.list.deinit(self.allocator);
        self.allocator.destroy(self);
    }

    pub fn refresh(self: *Context) !void {
        for (self.devices_info.list.items) |d|
            freeDevice(self.allocator, d);
        self.devices_info.clear(self.allocator);

        const sample_rate = @intCast(u24, c.jack_get_sample_rate(self.client));

        const port_names = c.jack_get_ports(self.client, null, null, 0) orelse
            return error.OutOfMemory;
        defer c.jack_free(@ptrCast(?*anyopaque, port_names));

        var i: usize = 0;
        outer: while (port_names[i] != null) : (i += 1) {
            const port = c.jack_port_by_name(self.client, port_names[i]) orelse break;
            const port_type = c.jack_port_type(port)[0..@intCast(usize, c.jack_port_type_size())];
            if (!std.mem.startsWith(u8, port_type, c.JACK_DEFAULT_AUDIO_TYPE))
                continue;

            const flags = c.jack_port_flags(port);
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
            if (std.mem.eql(u8, "system", id)) {
                self.devices_info.setDefault(device.mode, self.devices_info.list.items.len - 1);
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
        for (device.channels) |_, i| {
            const port_name = std.fmt.bufPrintZ(&buf, "playback_{d}", .{i + 1}) catch unreachable;
            const dest_name = try std.fmt.allocPrintZ(self.allocator, "{s}:{s}", .{ device.id, port_name });
            ports[i] = c.jack_port_register(self.client, port_name.ptr, c.JACK_DEFAULT_AUDIO_TYPE, c.JackPortIsOutput, 0) orelse
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
        self.allocator.destroy(self);
    }

    pub fn start(self: *Player) !void {
        if (c.jack_set_process_callback(self.client, processCallback, self) != 0)
            return error.CannotPlay;

        if (c.jack_activate(self.client) != 0)
            return error.CannotPlay;

        for (self.ports) |port, i| {
            if (c.jack_connect(self.client, c.jack_port_name(port), self.dest_ports[i].ptr) != 0)
                return error.CannotPlay;
        }
    }

    fn processCallback(n_frames: c.jack_nframes_t, self_opaque: ?*anyopaque) callconv(.C) c_int {
        const self = @ptrCast(*Player, @alignCast(@alignOf(*Player), self_opaque.?));
        for (self.channels) |*ch, i| {
            ch.*.ptr = @ptrCast([*]u8, c.jack_port_get_buffer(self.ports[i], n_frames));
        }
        self.writeFn(self.user_data, n_frames);
        return 0;
    }

    pub fn play(self: *Player) !void {
        self.mutex.lock();
        defer self.mutex.unlock();
        for (self.ports) |port, i| {
            if (c.jack_connect(self.client, c.jack_port_name(port), self.dest_ports[i].ptr) != 0)
                return error.CannotPlay;
        }
    }

    pub fn pause(self: *Player) !void {
        self.mutex.lock();
        defer self.mutex.unlock();
        for (self.ports) |port, i| {
            if (c.jack_disconnect(self.client, c.jack_port_name(port), self.dest_ports[i].ptr) != 0)
                return error.CannotPause;
        }
    }

    pub fn paused(self: *Player) bool {
        self.mutex.lock();
        defer self.mutex.unlock();
        for (self.ports) |port, i| {
            if (c.jack_port_connected_to(port, self.dest_ports[i].ptr) == 1)
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
        return @intCast(u24, c.jack_get_sample_rate(self.client));
    }
};

pub fn freeDevice(allocator: std.mem.Allocator, device: main.Device) void {
    allocator.free(device.id);
    allocator.free(device.channels);
}

test {
    std.testing.refAllDeclsRecursive(@This());
}
