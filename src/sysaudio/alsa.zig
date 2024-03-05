const std = @import("std");
const c = @cImport(@cInclude("alsa/asoundlib.h"));
const main = @import("main.zig");
const backends = @import("backends.zig");
const util = @import("util.zig");
const inotify_event = std.os.linux.inotify_event;
const is_little = @import("builtin").cpu.arch.endian() == .little;

const default_sample_rate = 44_100; // Hz

var lib: Lib = undefined;
const Lib = struct {
    handle: std.DynLib,

    snd_lib_error_set_handler: *const fn (c.snd_lib_error_handler_t) callconv(.C) c_int,
    snd_pcm_info_malloc: *const fn ([*c]?*c.snd_pcm_info_t) callconv(.C) c_int,
    snd_pcm_info_free: *const fn (?*c.snd_pcm_info_t) callconv(.C) void,
    snd_pcm_open: *const fn ([*c]?*c.snd_pcm_t, [*c]const u8, c.snd_pcm_stream_t, c_int) callconv(.C) c_int,
    snd_pcm_close: *const fn (?*c.snd_pcm_t) callconv(.C) c_int,
    snd_pcm_state: *const fn (?*c.snd_pcm_t) callconv(.C) c.snd_pcm_state_t,
    snd_pcm_pause: *const fn (?*c.snd_pcm_t, c_int) callconv(.C) c_int,
    snd_pcm_writei: *const fn (?*c.snd_pcm_t, ?*const anyopaque, c.snd_pcm_uframes_t) callconv(.C) c.snd_pcm_sframes_t,
    snd_pcm_readi: *const fn (?*c.snd_pcm_t, ?*const anyopaque, c.snd_pcm_uframes_t) callconv(.C) c.snd_pcm_sframes_t,
    snd_pcm_prepare: *const fn (?*c.snd_pcm_t) callconv(.C) c_int,
    snd_pcm_info_set_device: *const fn (?*c.snd_pcm_info_t, c_uint) callconv(.C) void,
    snd_pcm_info_set_subdevice: *const fn (?*c.snd_pcm_info_t, c_uint) callconv(.C) void,
    snd_pcm_info_get_name: *const fn (?*const c.snd_pcm_info_t) callconv(.C) [*c]const u8,
    snd_pcm_info_set_stream: *const fn (?*c.snd_pcm_info_t, c.snd_pcm_stream_t) callconv(.C) void,
    snd_pcm_hw_free: *const fn (?*c.snd_pcm_t) callconv(.C) c_int,
    snd_pcm_hw_params_malloc: *const fn ([*c]?*c.snd_pcm_hw_params_t) callconv(.C) c_int,
    snd_pcm_hw_params_free: *const fn (?*c.snd_pcm_hw_params_t) callconv(.C) void,
    snd_pcm_set_params: *const fn (?*c.snd_pcm_t, c.snd_pcm_format_t, c.snd_pcm_access_t, c_uint, c_uint, c_int, c_uint) callconv(.C) c_int,
    snd_pcm_hw_params_any: *const fn (?*c.snd_pcm_t, ?*c.snd_pcm_hw_params_t) callconv(.C) c_int,
    snd_pcm_hw_params_can_pause: *const fn (?*const c.snd_pcm_hw_params_t) callconv(.C) c_int,
    snd_pcm_hw_params_current: *const fn (?*c.snd_pcm_t, ?*c.snd_pcm_hw_params_t) callconv(.C) c_int,
    snd_pcm_hw_params_get_format_mask: *const fn (?*c.snd_pcm_hw_params_t, ?*c.snd_pcm_format_mask_t) callconv(.C) void,
    snd_pcm_hw_params_get_rate_min: *const fn (?*const c.snd_pcm_hw_params_t, [*c]c_uint, [*c]c_int) callconv(.C) c_int,
    snd_pcm_hw_params_get_rate_max: *const fn (?*const c.snd_pcm_hw_params_t, [*c]c_uint, [*c]c_int) callconv(.C) c_int,
    snd_pcm_hw_params_get_period_size: *const fn (?*const c.snd_pcm_hw_params_t, [*c]c.snd_pcm_uframes_t, [*c]c_int) callconv(.C) c_int,
    snd_pcm_query_chmaps: *const fn (?*c.snd_pcm_t) callconv(.C) [*c][*c]c.snd_pcm_chmap_query_t,
    snd_pcm_free_chmaps: *const fn ([*c][*c]c.snd_pcm_chmap_query_t) callconv(.C) void,
    snd_pcm_format_mask_malloc: *const fn ([*c]?*c.snd_pcm_format_mask_t) callconv(.C) c_int,
    snd_pcm_format_mask_free: *const fn (?*c.snd_pcm_format_mask_t) callconv(.C) void,
    snd_pcm_format_mask_none: *const fn (?*c.snd_pcm_format_mask_t) callconv(.C) void,
    snd_pcm_format_mask_set: *const fn (?*c.snd_pcm_format_mask_t, c.snd_pcm_format_t) callconv(.C) void,
    snd_pcm_format_mask_test: *const fn (?*const c.snd_pcm_format_mask_t, c.snd_pcm_format_t) callconv(.C) c_int,
    snd_card_next: *const fn ([*c]c_int) callconv(.C) c_int,
    snd_ctl_open: *const fn ([*c]?*c.snd_ctl_t, [*c]const u8, c_int) callconv(.C) c_int,
    snd_ctl_close: *const fn (?*c.snd_ctl_t) callconv(.C) c_int,
    snd_ctl_pcm_next_device: *const fn (?*c.snd_ctl_t, [*c]c_int) callconv(.C) c_int,
    snd_ctl_pcm_info: *const fn (?*c.snd_ctl_t, ?*c.snd_pcm_info_t) callconv(.C) c_int,
    snd_mixer_open: *const fn ([*c]?*c.snd_mixer_t, c_int) callconv(.C) c_int,
    snd_mixer_close: *const fn (?*c.snd_mixer_t) callconv(.C) c_int,
    snd_mixer_load: *const fn (?*c.snd_mixer_t) callconv(.C) c_int,
    snd_mixer_attach: *const fn (?*c.snd_mixer_t, [*c]const u8) callconv(.C) c_int,
    snd_mixer_find_selem: *const fn (?*c.snd_mixer_t, ?*const c.snd_mixer_selem_id_t) callconv(.C) ?*c.snd_mixer_elem_t,
    snd_mixer_selem_register: *const fn (?*c.snd_mixer_t, [*c]c.struct_snd_mixer_selem_regopt, [*c]?*c.snd_mixer_class_t) callconv(.C) c_int,
    snd_mixer_selem_id_malloc: *const fn ([*c]?*c.snd_mixer_selem_id_t) callconv(.C) c_int,
    snd_mixer_selem_id_free: *const fn (?*c.snd_mixer_selem_id_t) callconv(.C) void,
    snd_mixer_selem_id_set_index: *const fn (?*c.snd_mixer_selem_id_t, c_uint) callconv(.C) void,
    snd_mixer_selem_id_set_name: *const fn (?*c.snd_mixer_selem_id_t, [*c]const u8) callconv(.C) void,
    snd_mixer_selem_set_playback_volume_all: *const fn (?*c.snd_mixer_elem_t, c_long) callconv(.C) c_int,
    snd_mixer_selem_get_playback_volume: *const fn (?*c.snd_mixer_elem_t, c.snd_mixer_selem_channel_id_t, [*c]c_long) callconv(.C) c_int,
    snd_mixer_selem_get_playback_volume_range: *const fn (?*c.snd_mixer_elem_t, [*c]c_long, [*c]c_long) callconv(.C) c_int,
    snd_mixer_selem_has_playback_channel: *const fn (?*c.snd_mixer_elem_t, c.snd_mixer_selem_channel_id_t) callconv(.C) c_int,
    snd_mixer_selem_set_capture_volume_all: *const fn (?*c.snd_mixer_elem_t, c_long) callconv(.C) c_int,
    snd_mixer_selem_get_capture_volume: *const fn (?*c.snd_mixer_elem_t, c.snd_mixer_selem_channel_id_t, [*c]c_long) callconv(.C) c_int,
    snd_mixer_selem_get_capture_volume_range: *const fn (?*c.snd_mixer_elem_t, [*c]c_long, [*c]c_long) callconv(.C) c_int,
    snd_mixer_selem_has_capture_channel: *const fn (?*c.snd_mixer_elem_t, c.snd_mixer_selem_channel_id_t) callconv(.C) c_int,

    pub fn load() !void {
        lib.handle = std.DynLib.openZ("libasound.so") catch return error.LibraryNotFound;
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
    watcher: ?Watcher,

    const Watcher = struct {
        deviceChangeFn: main.Context.DeviceChangeFn,
        user_data: ?*anyopaque,
        thread: std.Thread,
        aborted: std.atomic.Value(bool),
        notify_fd: std.os.fd_t,
        notify_wd: std.os.fd_t,
        notify_pipe_fd: [2]std.os.fd_t,
    };

    pub fn init(allocator: std.mem.Allocator, options: main.Context.Options) !backends.Context {
        try Lib.load();

        _ = lib.snd_lib_error_set_handler(@as(c.snd_lib_error_handler_t, @ptrCast(&util.doNothing)));

        const ctx = try allocator.create(Context);
        errdefer allocator.destroy(ctx);
        ctx.* = .{
            .allocator = allocator,
            .devices_info = util.DevicesInfo.init(),
            .watcher = blk: {
                if (options.deviceChangeFn) |deviceChangeFn| {
                    const notify_fd = std.os.inotify_init1(std.os.linux.IN.NONBLOCK) catch |err| switch (err) {
                        error.ProcessFdQuotaExceeded,
                        error.SystemFdQuotaExceeded,
                        error.SystemResources,
                        => return error.SystemResources,
                        error.Unexpected => unreachable,
                    };
                    errdefer std.os.close(notify_fd);

                    const notify_wd = std.os.inotify_add_watch(
                        notify_fd,
                        "/dev/snd",
                        std.os.linux.IN.CREATE | std.os.linux.IN.DELETE,
                    ) catch |err| switch (err) {
                        error.AccessDenied => return error.AccessDenied,
                        error.UserResourceLimitReached,
                        error.NotDir,
                        error.FileNotFound,
                        error.SystemResources,
                        => return error.SystemResources,
                        error.NameTooLong,
                        error.WatchAlreadyExists,
                        error.Unexpected,
                        => unreachable,
                    };
                    errdefer std.os.inotify_rm_watch(notify_fd, notify_wd);

                    const notify_pipe_fd = std.os.pipe2(std.os.O.NONBLOCK) catch |err| switch (err) {
                        error.ProcessFdQuotaExceeded,
                        error.SystemFdQuotaExceeded,
                        => return error.SystemResources,
                        error.Unexpected => unreachable,
                    };
                    errdefer {
                        std.os.close(notify_pipe_fd[0]);
                        std.os.close(notify_pipe_fd[1]);
                    }

                    break :blk .{
                        .deviceChangeFn = deviceChangeFn,
                        .user_data = options.user_data,
                        .aborted = .{ .raw = false },
                        .notify_fd = notify_fd,
                        .notify_wd = notify_wd,
                        .notify_pipe_fd = notify_pipe_fd,
                        .thread = std.Thread.spawn(.{}, deviceEventsLoop, .{ctx}) catch |err| switch (err) {
                            error.ThreadQuotaExceeded,
                            error.SystemResources,
                            error.LockedMemoryLimitExceeded,
                            => return error.SystemResources,
                            error.OutOfMemory => return error.OutOfMemory,
                            error.Unexpected => unreachable,
                        },
                    };
                }

                break :blk null;
            },
        };

        return .{ .alsa = ctx };
    }

    pub fn deinit(ctx: *Context) void {
        if (ctx.watcher) |*watcher| {
            watcher.aborted.store(true, .Unordered);
            _ = std.os.write(watcher.notify_pipe_fd[1], "a") catch {};
            watcher.thread.join();

            std.os.close(watcher.notify_pipe_fd[0]);
            std.os.close(watcher.notify_pipe_fd[1]);
            std.os.inotify_rm_watch(watcher.notify_fd, watcher.notify_wd);
            std.os.close(watcher.notify_fd);
        }

        for (ctx.devices_info.list.items) |d|
            freeDevice(ctx.allocator, d);
        ctx.devices_info.list.deinit(ctx.allocator);
        ctx.allocator.destroy(ctx);
        lib.handle.close();
    }

    fn deviceEventsLoop(ctx: *Context) void {
        var watcher = ctx.watcher.?;
        var scan = false;
        var last_crash: ?i64 = null;
        var buf: [2048]u8 = undefined;
        var fds = [2]std.os.pollfd{
            .{
                .fd = watcher.notify_fd,
                .events = std.os.POLL.IN,
                .revents = 0,
            },
            .{
                .fd = watcher.notify_pipe_fd[0],
                .events = std.os.POLL.IN,
                .revents = 0,
            },
        };

        while (!watcher.aborted.load(.Unordered)) {
            _ = std.os.poll(&fds, -1) catch |err| switch (err) {
                error.NetworkSubsystemFailed,
                error.SystemResources,
                => {
                    const ts = std.time.milliTimestamp();
                    if (last_crash) |lc| {
                        if (ts - lc < 500) return;
                    }
                    last_crash = ts;
                    continue;
                },
                error.Unexpected => unreachable,
            };
            if (watcher.notify_fd & std.os.POLL.IN != 0) {
                while (true) {
                    const len = std.os.read(watcher.notify_fd, &buf) catch |err| {
                        if (err == error.WouldBlock) break;
                        const ts = std.time.milliTimestamp();
                        if (last_crash) |lc| {
                            if (ts - lc < 500) return;
                        }
                        last_crash = ts;
                        break;
                    };
                    if (len == 0) break;

                    var i: usize = 0;
                    var evt: *inotify_event = undefined;
                    while (i < buf.len) : (i += @sizeOf(inotify_event) + evt.len) {
                        evt = @as(*inotify_event, @ptrCast(@alignCast(buf[i..])));
                        const evt_name = @as([*]u8, @ptrCast(buf[i..]))[@sizeOf(inotify_event) .. @sizeOf(inotify_event) + 8];

                        if (evt.mask & std.os.linux.IN.ISDIR != 0 or !std.mem.startsWith(u8, evt_name, "pcm"))
                            continue;

                        scan = true;
                    }
                }
            }

            if (scan) {
                watcher.deviceChangeFn(ctx.watcher.?.user_data);
                scan = false;
            }
        }
    }

    pub fn refresh(ctx: *Context) !void {
        for (ctx.devices_info.list.items) |d|
            freeDevice(ctx.allocator, d);
        ctx.devices_info.clear();

        var pcm_info: ?*c.snd_pcm_info_t = null;
        _ = lib.snd_pcm_info_malloc(&pcm_info);
        defer lib.snd_pcm_info_free(pcm_info);

        var card_idx: c_int = -1;
        if (lib.snd_card_next(&card_idx) < 0)
            return error.SystemResources;

        while (card_idx >= 0) {
            var card_id_buf: [8]u8 = undefined;
            const card_id = std.fmt.bufPrintZ(&card_id_buf, "hw:{d}", .{card_idx}) catch break;

            var ctl: ?*c.snd_ctl_t = undefined;
            _ = switch (-lib.snd_ctl_open(&ctl, card_id.ptr, 0)) {
                0 => {},
                @intFromEnum(std.os.E.NOENT) => break,
                else => return error.OpeningDevice,
            };
            defer _ = lib.snd_ctl_close(ctl);

            var dev_idx: c_int = -1;
            if (lib.snd_ctl_pcm_next_device(ctl, &dev_idx) < 0)
                return error.SystemResources;

            lib.snd_pcm_info_set_device(pcm_info, @as(c_uint, @intCast(dev_idx)));
            lib.snd_pcm_info_set_subdevice(pcm_info, 0);
            const name = std.mem.span(lib.snd_pcm_info_get_name(pcm_info) orelse continue);

            for (&[_]main.Device.Mode{ .playback, .capture }) |mode| {
                const snd_stream = modeToStream(mode);
                lib.snd_pcm_info_set_stream(pcm_info, snd_stream);
                const err = lib.snd_ctl_pcm_info(ctl, pcm_info);
                switch (@as(std.os.E, @enumFromInt(-err))) {
                    .SUCCESS => {},
                    .NOENT,
                    .NXIO,
                    .NODEV,
                    => break,
                    else => return error.SystemResources,
                }

                var buf: [9]u8 = undefined; // 'hw' + max(card|device) * 2 + ':' + \0
                const id = std.fmt.bufPrintZ(&buf, "hw:{d},{d}", .{ card_idx, dev_idx }) catch continue;

                var pcm: ?*c.snd_pcm_t = null;
                if (lib.snd_pcm_open(&pcm, id.ptr, snd_stream, 0) < 0)
                    continue;
                defer _ = lib.snd_pcm_close(pcm);

                var params: ?*c.snd_pcm_hw_params_t = null;
                _ = lib.snd_pcm_hw_params_malloc(&params);
                defer lib.snd_pcm_hw_params_free(params);
                if (lib.snd_pcm_hw_params_any(pcm, params) < 0)
                    continue;

                if (lib.snd_pcm_hw_params_can_pause(params) == 0)
                    continue;

                const device = main.Device{
                    .mode = mode,
                    .channels = blk: {
                        const chmap = lib.snd_pcm_query_chmaps(pcm);
                        if (chmap) |_| {
                            defer lib.snd_pcm_free_chmaps(chmap);

                            if (chmap[0] == null) continue;

                            const channels = try ctx.allocator.alloc(main.ChannelPosition, chmap.*.*.map.channels);
                            for (channels, 0..) |*ch, i|
                                ch.* = fromAlsaChannel(chmap[0][0].map.pos()[i]) catch return error.OpeningDevice;
                            break :blk channels;
                        } else {
                            continue;
                        }
                    },
                    .formats = blk: {
                        var fmt_mask: ?*c.snd_pcm_format_mask_t = null;
                        _ = lib.snd_pcm_format_mask_malloc(&fmt_mask);
                        defer lib.snd_pcm_format_mask_free(fmt_mask);
                        lib.snd_pcm_format_mask_none(fmt_mask);
                        lib.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_S8);
                        lib.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_U8);
                        lib.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_S16_LE);
                        lib.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_S16_BE);
                        lib.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_U16_LE);
                        lib.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_U16_BE);
                        lib.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_S24_3LE);
                        lib.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_S24_3BE);
                        lib.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_U24_3LE);
                        lib.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_U24_3BE);
                        lib.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_S24_LE);
                        lib.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_S24_BE);
                        lib.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_U24_LE);
                        lib.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_U24_BE);
                        lib.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_S32_LE);
                        lib.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_S32_BE);
                        lib.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_U32_LE);
                        lib.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_U32_BE);
                        lib.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_FLOAT_LE);
                        lib.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_FLOAT_BE);
                        lib.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_FLOAT64_LE);
                        lib.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_FLOAT64_BE);
                        lib.snd_pcm_hw_params_get_format_mask(params, fmt_mask);

                        var fmt_arr = std.ArrayList(main.Format).init(ctx.allocator);
                        inline for (std.meta.tags(main.Format)) |format| {
                            if (lib.snd_pcm_format_mask_test(fmt_mask, toAlsaFormat(format)) != 0) {
                                try fmt_arr.append(format);
                            }
                        }

                        break :blk try fmt_arr.toOwnedSlice();
                    },
                    .sample_rate = blk: {
                        var rate_min: c_uint = 0;
                        var rate_max: c_uint = 0;
                        if (lib.snd_pcm_hw_params_get_rate_min(params, &rate_min, null) < 0)
                            continue;
                        if (lib.snd_pcm_hw_params_get_rate_max(params, &rate_max, null) < 0)
                            continue;
                        break :blk .{
                            .min = @as(u24, @intCast(rate_min)),
                            .max = @as(u24, @intCast(rate_max)),
                        };
                    },
                    .id = try ctx.allocator.dupeZ(u8, id),
                    .name = try ctx.allocator.dupeZ(u8, name),
                };

                try ctx.devices_info.list.append(ctx.allocator, device);

                if (ctx.devices_info.default(mode) == null and dev_idx == 0) {
                    ctx.devices_info.setDefault(mode, ctx.devices_info.list.items.len - 1);
                }
            }

            if (lib.snd_card_next(&card_idx) < 0)
                return error.SystemResources;
        }
    }

    pub fn devices(ctx: Context) []const main.Device {
        return ctx.devices_info.list.items;
    }

    pub fn defaultDevice(ctx: Context, mode: main.Device.Mode) ?main.Device {
        return ctx.devices_info.default(mode);
    }

    pub fn createStream(
        ctx: Context,
        device: main.Device,
        format: main.Format,
        sample_rate: u24,
        pcm: *?*c.snd_pcm_t,
        mixer: *?*c.snd_mixer_t,
        selem: *?*c.snd_mixer_selem_id_t,
        mixer_elm: *?*c.snd_mixer_elem_t,
        period_size: *c_ulong,
    ) !void {
        if (lib.snd_pcm_open(pcm, device.id.ptr, modeToStream(device.mode), 0) < 0)
            return error.OpeningDevice;
        errdefer _ = lib.snd_pcm_close(pcm.*);
        {
            var hw_params: ?*c.snd_pcm_hw_params_t = null;

            if ((lib.snd_pcm_set_params(
                pcm.*,
                toAlsaFormat(format),
                c.SND_PCM_ACCESS_RW_INTERLEAVED,
                @as(c_uint, @intCast(device.channels.len)),
                sample_rate,
                1,
                main.default_latency,
            )) < 0)
                return error.OpeningDevice;
            errdefer _ = lib.snd_pcm_hw_free(pcm.*);

            if (lib.snd_pcm_hw_params_malloc(&hw_params) < 0)
                return error.OpeningDevice;
            defer lib.snd_pcm_hw_params_free(hw_params);

            if (lib.snd_pcm_hw_params_current(pcm.*, hw_params) < 0)
                return error.OpeningDevice;

            if (lib.snd_pcm_hw_params_get_period_size(hw_params, period_size, null) < 0)
                return error.OpeningDevice;
        }

        {
            if (lib.snd_mixer_open(mixer, 0) < 0)
                return error.OutOfMemory;

            const card_id = try ctx.allocator.dupeZ(u8, std.mem.sliceTo(device.id, ','));
            defer ctx.allocator.free(card_id);

            if (lib.snd_mixer_attach(mixer.*, card_id.ptr) < 0)
                return error.IncompatibleDevice;

            if (lib.snd_mixer_selem_register(mixer.*, null, null) < 0)
                return error.OpeningDevice;

            if (lib.snd_mixer_load(mixer.*) < 0)
                return error.OpeningDevice;

            if (lib.snd_mixer_selem_id_malloc(selem) < 0)
                return error.OutOfMemory;
            errdefer lib.snd_mixer_selem_id_free(selem.*);

            lib.snd_mixer_selem_id_set_index(selem.*, 0);
            lib.snd_mixer_selem_id_set_name(selem.*, "Master");

            mixer_elm.* = lib.snd_mixer_find_selem(mixer.*, selem.*) orelse
                return error.IncompatibleDevice;
        }
    }

    pub fn createPlayer(ctx: Context, device: main.Device, writeFn: main.WriteFn, options: main.StreamOptions) !backends.Player {
        const format = device.preferredFormat(options.format);
        const sample_rate = device.sample_rate.clamp(options.sample_rate orelse default_sample_rate);
        var pcm: ?*c.snd_pcm_t = null;
        var mixer: ?*c.snd_mixer_t = null;
        var selem: ?*c.snd_mixer_selem_id_t = null;
        var mixer_elm: ?*c.snd_mixer_elem_t = null;
        var period_size: c_ulong = 0;
        try ctx.createStream(device, format, sample_rate, &pcm, &mixer, &selem, &mixer_elm, &period_size);

        const player = try ctx.allocator.create(Player);
        player.* = .{
            .allocator = ctx.allocator,
            .thread = undefined,
            .aborted = .{ .raw = false },
            .sample_buffer = try ctx.allocator.alloc(u8, period_size * format.frameSize(@intCast(device.channels.len))),
            .period_size = period_size,
            .pcm = pcm.?,
            .mixer = mixer.?,
            .selem = selem.?,
            .mixer_elm = mixer_elm.?,
            .writeFn = writeFn,
            .user_data = options.user_data,
            .channels = device.channels,
            .format = format,
            .sample_rate = sample_rate,
        };
        return .{ .alsa = player };
    }

    pub fn createRecorder(ctx: *Context, device: main.Device, readFn: main.ReadFn, options: main.StreamOptions) !backends.Recorder {
        const format = device.preferredFormat(options.format);
        const sample_rate = device.sample_rate.clamp(options.sample_rate orelse default_sample_rate);
        var pcm: ?*c.snd_pcm_t = null;
        var mixer: ?*c.snd_mixer_t = null;
        var selem: ?*c.snd_mixer_selem_id_t = null;
        var mixer_elm: ?*c.snd_mixer_elem_t = null;
        var period_size: c_ulong = 0;
        try ctx.createStream(device, format, sample_rate, &pcm, &mixer, &selem, &mixer_elm, &period_size);

        const recorder = try ctx.allocator.create(Recorder);
        recorder.* = .{
            .allocator = ctx.allocator,
            .thread = undefined,
            .aborted = .{ .raw = false },
            .sample_buffer = try ctx.allocator.alloc(u8, period_size * format.frameSize(@intCast(device.channels.len))),
            .period_size = period_size,
            .pcm = pcm.?,
            .mixer = mixer.?,
            .selem = selem.?,
            .mixer_elm = mixer_elm.?,
            .readFn = readFn,
            .user_data = options.user_data,
            .channels = device.channels,
            .format = format,
            .sample_rate = sample_rate,
        };
        return .{ .alsa = recorder };
    }
};

pub const Player = struct {
    allocator: std.mem.Allocator,
    thread: std.Thread,
    aborted: std.atomic.Value(bool),
    sample_buffer: []u8,
    period_size: c_ulong,
    pcm: *c.snd_pcm_t,
    mixer: *c.snd_mixer_t,
    selem: *c.snd_mixer_selem_id_t,
    mixer_elm: *c.snd_mixer_elem_t,
    writeFn: main.WriteFn,
    user_data: ?*anyopaque,

    channels: []main.ChannelPosition,
    format: main.Format,
    sample_rate: u24,

    pub fn deinit(player: *Player) void {
        player.aborted.store(true, .Unordered);
        player.thread.join();

        _ = lib.snd_mixer_close(player.mixer);
        lib.snd_mixer_selem_id_free(player.selem);
        _ = lib.snd_pcm_close(player.pcm);
        _ = lib.snd_pcm_hw_free(player.pcm);

        player.allocator.free(player.sample_buffer);
        player.allocator.destroy(player);
    }

    pub fn start(player: *Player) !void {
        player.thread = std.Thread.spawn(.{}, writeThread, .{player}) catch |err| switch (err) {
            error.ThreadQuotaExceeded,
            error.SystemResources,
            error.LockedMemoryLimitExceeded,
            => return error.SystemResources,
            error.OutOfMemory => return error.OutOfMemory,
            error.Unexpected => unreachable,
        };
    }

    fn writeThread(player: *Player) void {
        var underrun = false;
        while (!player.aborted.load(.Unordered)) {
            if (!underrun) {
                player.writeFn(
                    player.user_data,
                    player.sample_buffer[0 .. player.period_size * player.format.frameSize(@intCast(player.channels.len))],
                );
            }
            underrun = false;
            const n = lib.snd_pcm_writei(player.pcm, player.sample_buffer.ptr, player.period_size);
            if (n < 0) {
                _ = lib.snd_pcm_prepare(player.pcm);
                underrun = true;
            }
        }
    }

    pub fn play(player: *Player) !void {
        if (lib.snd_pcm_state(player.pcm) == c.SND_PCM_STATE_PAUSED) {
            if (lib.snd_pcm_pause(player.pcm, 0) < 0)
                return error.CannotPlay;
        }
    }

    pub fn pause(player: *Player) !void {
        if (lib.snd_pcm_state(player.pcm) != c.SND_PCM_STATE_PAUSED) {
            if (lib.snd_pcm_pause(player.pcm, 1) < 0)
                return error.CannotPause;
        }
    }

    pub fn paused(player: *Player) bool {
        return lib.snd_pcm_state(player.pcm) == c.SND_PCM_STATE_PAUSED;
    }

    pub fn setVolume(player: *Player, vol: f32) !void {
        var min_vol: c_long = 0;
        var max_vol: c_long = 0;
        if (lib.snd_mixer_selem_get_playback_volume_range(player.mixer_elm, &min_vol, &max_vol) < 0)
            return error.CannotSetVolume;

        const dist = @as(f32, @floatFromInt(max_vol - min_vol));
        if (lib.snd_mixer_selem_set_playback_volume_all(
            player.mixer_elm,
            @as(c_long, @intFromFloat(dist * vol)) + min_vol,
        ) < 0)
            return error.CannotSetVolume;
    }

    pub fn volume(player: *Player) !f32 {
        var vol: c_long = 0;
        var channel: c_int = 0;

        while (channel < c.SND_MIXER_SCHN_LAST) : (channel += 1) {
            if (lib.snd_mixer_selem_has_playback_channel(player.mixer_elm, channel) == 1) {
                if (lib.snd_mixer_selem_get_playback_volume(player.mixer_elm, channel, &vol) == 0)
                    break;
            }
        }

        if (channel == c.SND_MIXER_SCHN_LAST)
            return error.CannotGetVolume;

        var min_vol: c_long = 0;
        var max_vol: c_long = 0;
        if (lib.snd_mixer_selem_get_playback_volume_range(player.mixer_elm, &min_vol, &max_vol) < 0)
            return error.CannotGetVolume;

        return @as(f32, @floatFromInt(vol)) / @as(f32, @floatFromInt(max_vol - min_vol));
    }
};

pub const Recorder = struct {
    allocator: std.mem.Allocator,
    thread: std.Thread,
    aborted: std.atomic.Value(bool),
    sample_buffer: []u8,
    period_size: c_ulong,
    pcm: *c.snd_pcm_t,
    mixer: *c.snd_mixer_t,
    selem: *c.snd_mixer_selem_id_t,
    mixer_elm: *c.snd_mixer_elem_t,
    readFn: main.ReadFn,
    user_data: ?*anyopaque,

    channels: []main.ChannelPosition,
    format: main.Format,
    sample_rate: u24,

    pub fn deinit(recorder: *Recorder) void {
        recorder.aborted.store(true, .Unordered);
        recorder.thread.join();

        _ = lib.snd_mixer_close(recorder.mixer);
        lib.snd_mixer_selem_id_free(recorder.selem);
        _ = lib.snd_pcm_close(recorder.pcm);
        _ = lib.snd_pcm_hw_free(recorder.pcm);

        recorder.allocator.free(recorder.sample_buffer);
        recorder.allocator.destroy(recorder);
    }

    pub fn start(recorder: *Recorder) !void {
        recorder.thread = std.Thread.spawn(.{}, readThread, .{recorder}) catch |err| switch (err) {
            error.ThreadQuotaExceeded,
            error.SystemResources,
            error.LockedMemoryLimitExceeded,
            => return error.SystemResources,
            error.OutOfMemory => return error.OutOfMemory,
            error.Unexpected => unreachable,
        };
    }

    fn readThread(recorder: *Recorder) void {
        var underrun = false;
        while (!recorder.aborted.load(.Unordered)) {
            if (!underrun) {
                recorder.readFn(recorder.user_data, recorder.sample_buffer[0..recorder.period_size]);
            }
            underrun = false;
            const n = lib.snd_pcm_readi(recorder.pcm, recorder.sample_buffer.ptr, recorder.period_size);
            if (n < 0) {
                _ = lib.snd_pcm_prepare(recorder.pcm);
                underrun = true;
            }
        }
    }

    pub fn record(recorder: *Recorder) !void {
        if (lib.snd_pcm_state(recorder.pcm) == c.SND_PCM_STATE_PAUSED) {
            if (lib.snd_pcm_pause(recorder.pcm, 0) < 0)
                return error.CannotRecord;
        }
    }

    pub fn pause(recorder: *Recorder) !void {
        if (lib.snd_pcm_state(recorder.pcm) != c.SND_PCM_STATE_PAUSED) {
            if (lib.snd_pcm_pause(recorder.pcm, 1) < 0)
                return error.CannotPause;
        }
    }

    pub fn paused(recorder: *Recorder) bool {
        return lib.snd_pcm_state(recorder.pcm) == c.SND_PCM_STATE_PAUSED;
    }

    pub fn setVolume(recorder: *Recorder, vol: f32) !void {
        var min_vol: c_long = 0;
        var max_vol: c_long = 0;
        if (lib.snd_mixer_selem_get_capture_volume_range(recorder.mixer_elm, &min_vol, &max_vol) < 0)
            return error.CannotSetVolume;

        const dist = @as(f32, @floatFromInt(max_vol - min_vol));
        if (lib.snd_mixer_selem_set_capture_volume_all(
            recorder.mixer_elm,
            @as(c_long, @intFromFloat(dist * vol)) + min_vol,
        ) < 0)
            return error.CannotSetVolume;
    }

    pub fn volume(recorder: *Recorder) !f32 {
        var vol: c_long = 0;
        var channel: c_int = 0;

        while (channel < c.SND_MIXER_SCHN_LAST) : (channel += 1) {
            if (lib.snd_mixer_selem_has_capture_channel(recorder.mixer_elm, channel) == 1) {
                if (lib.snd_mixer_selem_get_capture_volume(recorder.mixer_elm, channel, &vol) == 0)
                    break;
            }
        }

        if (channel == c.SND_MIXER_SCHN_LAST)
            return error.CannotGetVolume;

        var min_vol: c_long = 0;
        var max_vol: c_long = 0;
        if (lib.snd_mixer_selem_get_capture_volume_range(recorder.mixer_elm, &min_vol, &max_vol) < 0)
            return error.CannotGetVolume;

        return @as(f32, @floatFromInt(vol)) / @as(f32, @floatFromInt(max_vol - min_vol));
    }
};

fn freeDevice(allocator: std.mem.Allocator, device: main.Device) void {
    allocator.free(device.id);
    allocator.free(device.name);
    allocator.free(device.formats);
    allocator.free(device.channels);
}

pub fn modeToStream(mode: main.Device.Mode) c_uint {
    return switch (mode) {
        .playback => c.SND_PCM_STREAM_PLAYBACK,
        .capture => c.SND_PCM_STREAM_CAPTURE,
    };
}

pub fn toAlsaFormat(format: main.Format) c.snd_pcm_format_t {
    return switch (format) {
        .u8 => c.SND_PCM_FORMAT_U8,
        .i16 => if (is_little) c.SND_PCM_FORMAT_S16_LE else c.SND_PCM_FORMAT_S16_BE,
        .i24 => if (is_little) c.SND_PCM_FORMAT_S24_3LE else c.SND_PCM_FORMAT_S24_3BE,
        .i32 => if (is_little) c.SND_PCM_FORMAT_S32_LE else c.SND_PCM_FORMAT_S32_BE,
        .f32 => if (is_little) c.SND_PCM_FORMAT_FLOAT_LE else c.SND_PCM_FORMAT_FLOAT_BE,
    };
}

pub fn fromAlsaChannel(pos: c_uint) !main.ChannelPosition {
    return switch (pos) {
        c.SND_CHMAP_UNKNOWN, c.SND_CHMAP_NA => return error.Invalid,
        c.SND_CHMAP_MONO, c.SND_CHMAP_FC => .front_center,
        c.SND_CHMAP_FL => .front_left,
        c.SND_CHMAP_FR => .front_right,
        c.SND_CHMAP_LFE => .lfe,
        c.SND_CHMAP_SL => .side_left,
        c.SND_CHMAP_SR => .side_right,
        c.SND_CHMAP_RC => .back_center,
        c.SND_CHMAP_RLC => .back_left,
        c.SND_CHMAP_RRC => .back_right,
        c.SND_CHMAP_FLC => .front_left_center,
        c.SND_CHMAP_FRC => .front_right_center,
        c.SND_CHMAP_TC => .top_center,
        c.SND_CHMAP_TFL => .top_front_left,
        c.SND_CHMAP_TFR => .top_front_right,
        c.SND_CHMAP_TFC => .top_front_center,
        c.SND_CHMAP_TRL => .top_back_left,
        c.SND_CHMAP_TRR => .top_back_right,
        c.SND_CHMAP_TRC => .top_back_center,

        else => return error.Invalid,
    };
}

pub fn toCHMAP(pos: main.ChannelPosition) c_uint {
    return switch (pos) {
        .front_center => c.SND_CHMAP_FC,
        .front_left => c.SND_CHMAP_FL,
        .front_right => c.SND_CHMAP_FR,
        .lfe => c.SND_CHMAP_LFE,
        .side_left => c.SND_CHMAP_SL,
        .side_right => c.SND_CHMAP_SR,
        .back_center => c.SND_CHMAP_RC,
        .back_left => c.SND_CHMAP_RLC,
        .back_right => c.SND_CHMAP_RRC,
        .front_left_center => c.SND_CHMAP_FLC,
        .front_right_center => c.SND_CHMAP_FRC,
        .top_center => c.SND_CHMAP_TC,
        .top_front_left => c.SND_CHMAP_TFL,
        .top_front_right => c.SND_CHMAP_TFR,
        .top_front_center => c.SND_CHMAP_TFC,
        .top_back_left => c.SND_CHMAP_TRL,
        .top_back_right => c.SND_CHMAP_TRR,
        .top_back_center => c.SND_CHMAP_TRC,
    };
}
