const std = @import("std");
const c = @cImport(@cInclude("alsa/asoundlib.h"));
const main = @import("main.zig");
const backends = @import("backends.zig");
const util = @import("util.zig");
const inotify_event = std.os.linux.inotify_event;
const is_little = @import("builtin").cpu.arch.endian() == .Little;

pub const Context = struct {
    allocator: std.mem.Allocator,
    devices_info: util.DevicesInfo,
    watcher: ?Watcher,

    const Watcher = struct {
        deviceChangeFn: main.DeviceChangeFn,
        user_data: ?*anyopaque,
        thread: std.Thread,
        aborted: std.atomic.Atomic(bool),
        notify_fd: std.os.fd_t,
        notify_wd: std.os.fd_t,
        notify_pipe_fd: [2]std.os.fd_t,
    };

    pub fn init(allocator: std.mem.Allocator, options: main.Context.Options) !backends.BackendContext {
        _ = c.snd_lib_error_set_handler(@ptrCast(c.snd_lib_error_handler_t, &util.doNothing));

        var self = try allocator.create(Context);
        errdefer allocator.destroy(self);
        self.* = .{
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
                        .aborted = .{ .value = false },
                        .notify_fd = notify_fd,
                        .notify_wd = notify_wd,
                        .notify_pipe_fd = notify_pipe_fd,
                        .thread = std.Thread.spawn(.{}, deviceEventsLoop, .{self}) catch |err| switch (err) {
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

        return .{ .alsa = self };
    }

    pub fn deinit(self: *Context) void {
        if (self.watcher) |*watcher| {
            watcher.aborted.store(true, .Unordered);
            _ = std.os.write(watcher.notify_pipe_fd[1], "a") catch {};
            watcher.thread.join();

            std.os.close(watcher.notify_pipe_fd[0]);
            std.os.close(watcher.notify_pipe_fd[1]);
            std.os.inotify_rm_watch(watcher.notify_fd, watcher.notify_wd);
            std.os.close(watcher.notify_fd);
        }

        for (self.devices_info.list.items) |d|
            freeDevice(self.allocator, d);
        self.devices_info.list.deinit(self.allocator);
        self.allocator.destroy(self);
    }

    fn deviceEventsLoop(self: *Context) void {
        var watcher = self.watcher.?;
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
                        evt = @ptrCast(*inotify_event, @alignCast(4, buf[i..]));
                        const evt_name = @ptrCast([*]u8, buf[i..])[@sizeOf(inotify_event) .. @sizeOf(inotify_event) + 8];

                        if (evt.mask & std.os.linux.IN.ISDIR != 0 or !std.mem.startsWith(u8, evt_name, "pcm"))
                            continue;

                        scan = true;
                    }
                }
            }

            if (scan) {
                watcher.deviceChangeFn(self.watcher.?.user_data);
                scan = false;
            }
        }
    }

    pub fn refresh(self: *Context) !void {
        for (self.devices_info.list.items) |d|
            freeDevice(self.allocator, d);
        self.devices_info.clear(self.allocator);

        var pcm_info: ?*c.snd_pcm_info_t = null;
        _ = c.snd_pcm_info_malloc(&pcm_info);
        defer c.snd_pcm_info_free(pcm_info);

        var card_idx: c_int = -1;
        if (c.snd_card_next(&card_idx) < 0)
            return error.SystemResources;

        while (card_idx >= 0) {
            var card_id_buf: [8]u8 = undefined;
            const card_id = std.fmt.bufPrintZ(&card_id_buf, "hw:{d}", .{card_idx}) catch break;

            var ctl: ?*c.snd_ctl_t = undefined;
            _ = switch (-c.snd_ctl_open(&ctl, card_id.ptr, 0)) {
                0 => {},
                @enumToInt(std.os.E.NOENT) => break,
                else => return error.OpeningDevice,
            };
            defer _ = c.snd_ctl_close(ctl);

            var dev_idx: c_int = -1;
            if (c.snd_ctl_pcm_next_device(ctl, &dev_idx) < 0)
                return error.SystemResources;

            c.snd_pcm_info_set_device(pcm_info, @intCast(c_uint, dev_idx));
            c.snd_pcm_info_set_subdevice(pcm_info, 0);
            const name = std.mem.span(c.snd_pcm_info_get_name(pcm_info) orelse continue);

            for (&[_]main.Device.Mode{ .playback, .capture }) |mode| {
                const snd_stream = modeToStream(mode);
                c.snd_pcm_info_set_stream(pcm_info, snd_stream);
                const err = c.snd_ctl_pcm_info(ctl, pcm_info);
                switch (@intToEnum(std.os.E, -err)) {
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
                if (c.snd_pcm_open(&pcm, id.ptr, snd_stream, 0) < 0)
                    continue;
                defer _ = c.snd_pcm_close(pcm);

                var params: ?*c.snd_pcm_hw_params_t = null;
                _ = c.snd_pcm_hw_params_malloc(&params);
                defer c.snd_pcm_hw_params_free(params);
                if (c.snd_pcm_hw_params_any(pcm, params) < 0)
                    continue;

                if (c.snd_pcm_hw_params_can_pause(params) == 0)
                    continue;

                const device = main.Device{
                    .mode = mode,
                    .channels = blk: {
                        const chmap = c.snd_pcm_query_chmaps(pcm);
                        if (chmap) |_| {
                            defer c.snd_pcm_free_chmaps(chmap);

                            if (chmap[0] == null) continue;

                            var channels = try self.allocator.alloc(main.Channel, chmap.*.*.map.channels);
                            for (channels) |*ch, i|
                                ch.*.id = fromAlsaChannel(chmap[0][0].map.pos()[i]) catch return error.OpeningDevice;
                            break :blk channels;
                        } else {
                            continue;
                        }
                    },
                    .formats = blk: {
                        var fmt_mask: ?*c.snd_pcm_format_mask_t = null;
                        _ = c.snd_pcm_format_mask_malloc(&fmt_mask);
                        defer c.snd_pcm_format_mask_free(fmt_mask);
                        c.snd_pcm_format_mask_none(fmt_mask);
                        c.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_S8);
                        c.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_U8);
                        c.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_S16_LE);
                        c.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_S16_BE);
                        c.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_U16_LE);
                        c.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_U16_BE);
                        c.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_S24_3LE);
                        c.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_S24_3BE);
                        c.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_U24_3LE);
                        c.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_U24_3BE);
                        c.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_S24_LE);
                        c.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_S24_BE);
                        c.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_U24_LE);
                        c.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_U24_BE);
                        c.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_S32_LE);
                        c.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_S32_BE);
                        c.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_U32_LE);
                        c.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_U32_BE);
                        c.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_FLOAT_LE);
                        c.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_FLOAT_BE);
                        c.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_FLOAT64_LE);
                        c.snd_pcm_format_mask_set(fmt_mask, c.SND_PCM_FORMAT_FLOAT64_BE);
                        c.snd_pcm_hw_params_get_format_mask(params, fmt_mask);

                        var fmt_arr = std.ArrayList(main.Format).init(self.allocator);
                        inline for (std.meta.tags(main.Format)) |format| {
                            if (c.snd_pcm_format_mask_test(
                                fmt_mask,
                                toAlsaFormat(format) catch unreachable,
                            ) != 0) {
                                try fmt_arr.append(format);
                            }
                        }

                        break :blk try fmt_arr.toOwnedSlice();
                    },
                    .sample_rate = blk: {
                        var rate_min: c_uint = 0;
                        var rate_max: c_uint = 0;
                        if (c.snd_pcm_hw_params_get_rate_min(params, &rate_min, null) < 0)
                            continue;
                        if (c.snd_pcm_hw_params_get_rate_max(params, &rate_max, null) < 0)
                            continue;
                        break :blk .{
                            .min = @intCast(u24, rate_min),
                            .max = @intCast(u24, rate_max),
                        };
                    },
                    .id = try self.allocator.dupeZ(u8, id),
                    .name = try self.allocator.dupeZ(u8, name),
                };

                try self.devices_info.list.append(self.allocator, device);

                if (self.devices_info.default(mode) == null and dev_idx == 0) {
                    self.devices_info.setDefault(mode, self.devices_info.list.items.len - 1);
                }
            }

            if (c.snd_card_next(&card_idx) < 0)
                return error.SystemResources;
        }
    }

    pub fn devices(self: Context) []const main.Device {
        return self.devices_info.list.items;
    }

    pub fn defaultDevice(self: Context, mode: main.Device.Mode) ?main.Device {
        return self.devices_info.default(mode);
    }

    pub fn createPlayer(self: Context, device: main.Device, writeFn: main.WriteFn, options: main.Player.Options) !backends.BackendPlayer {
        const format = device.preferredFormat(options.format);
        const sample_rate = device.sample_rate.clamp(options.sample_rate);
        var pcm: ?*c.snd_pcm_t = null;
        var mixer: ?*c.snd_mixer_t = null;
        var selem: ?*c.snd_mixer_selem_id_t = null;
        var mixer_elm: ?*c.snd_mixer_elem_t = null;
        var period_size: c_ulong = 0;

        if (c.snd_pcm_open(&pcm, device.id.ptr, modeToStream(device.mode), 0) < 0)
            return error.OpeningDevice;
        errdefer _ = c.snd_pcm_close(pcm);
        {
            var hw_params: ?*c.snd_pcm_hw_params_t = null;

            if ((c.snd_pcm_set_params(
                pcm,
                toAlsaFormat(format) catch unreachable,
                c.SND_PCM_ACCESS_RW_INTERLEAVED,
                @intCast(c_uint, device.channels.len),
                sample_rate,
                1,
                main.default_latency,
            )) < 0)
                return error.OpeningDevice;
            errdefer _ = c.snd_pcm_hw_free(pcm);

            if (c.snd_pcm_hw_params_malloc(&hw_params) < 0)
                return error.OpeningDevice;
            defer c.snd_pcm_hw_params_free(hw_params);

            if (c.snd_pcm_hw_params_current(pcm, hw_params) < 0)
                return error.OpeningDevice;

            if (c.snd_pcm_hw_params_get_period_size(hw_params, &period_size, null) < 0)
                return error.OpeningDevice;
        }

        {
            var chmap: c.snd_pcm_chmap_t = .{ .channels = @intCast(c_uint, device.channels.len) };

            for (device.channels) |ch, i|
                chmap.pos()[i] = toCHMAP(ch.id);

            if (c.snd_pcm_set_chmap(pcm, &chmap) < 0)
                return error.IncompatibleDevice;
        }

        {
            if (c.snd_mixer_open(&mixer, 0) < 0)
                return error.OutOfMemory;

            const card_id = try self.allocator.dupeZ(u8, std.mem.sliceTo(device.id, ','));
            defer self.allocator.free(card_id);

            if (c.snd_mixer_attach(mixer, card_id.ptr) < 0)
                return error.IncompatibleDevice;

            if (c.snd_mixer_selem_register(mixer, null, null) < 0)
                return error.OpeningDevice;

            if (c.snd_mixer_load(mixer) < 0)
                return error.OpeningDevice;

            if (c.snd_mixer_selem_id_malloc(&selem) < 0)
                return error.OutOfMemory;
            errdefer c.snd_mixer_selem_id_free(selem);

            c.snd_mixer_selem_id_set_index(selem, 0);
            c.snd_mixer_selem_id_set_name(selem, "Master");

            mixer_elm = c.snd_mixer_find_selem(mixer, selem) orelse
                return error.IncompatibleDevice;
        }

        var player = try self.allocator.create(Player);
        player.* = .{
            .allocator = self.allocator,
            .thread = undefined,
            .mutex = .{},
            .aborted = .{ .value = false },
            .sample_buffer = try self.allocator.alloc(u8, period_size * format.frameSize(device.channels.len)),
            .period_size = period_size,
            .pcm = pcm.?,
            .mixer = mixer.?,
            .selem = selem.?,
            .mixer_elm = mixer_elm.?,
            .sample_rate = sample_rate,
            .writeFn = writeFn,
            .user_data = options.user_data,
            .channels = device.channels,
            .format = format,
            .write_step = format.frameSize(device.channels.len),
        };
        return .{ .alsa = player };
    }
};

pub const Player = struct {
    allocator: std.mem.Allocator,
    thread: std.Thread,
    mutex: std.Thread.Mutex,
    aborted: std.atomic.Atomic(bool),
    sample_buffer: []u8,
    period_size: c_ulong,
    pcm: *c.snd_pcm_t,
    mixer: *c.snd_mixer_t,
    selem: *c.snd_mixer_selem_id_t,
    mixer_elm: *c.snd_mixer_elem_t,
    writeFn: main.WriteFn,
    user_data: ?*anyopaque,
    sample_rate: u24,

    channels: []main.Channel,
    format: main.Format,
    write_step: u8,

    pub fn deinit(self: *Player) void {
        self.aborted.store(true, .Unordered);
        self.thread.join();

        _ = c.snd_mixer_close(self.mixer);
        c.snd_mixer_selem_id_free(self.selem);
        _ = c.snd_pcm_close(self.pcm);
        _ = c.snd_pcm_hw_free(self.pcm);

        self.allocator.free(self.sample_buffer);
        self.allocator.destroy(self);
    }

    pub fn start(self: *Player) !void {
        self.thread = std.Thread.spawn(.{}, writeLoop, .{self}) catch |err| switch (err) {
            error.ThreadQuotaExceeded,
            error.SystemResources,
            error.LockedMemoryLimitExceeded,
            => return error.SystemResources,
            error.OutOfMemory => return error.OutOfMemory,
            error.Unexpected => unreachable,
        };
    }

    fn writeLoop(self: *Player) void {
        for (self.channels) |*ch, i| {
            ch.*.ptr = self.sample_buffer.ptr + self.format.frameSize(i);
        }

        while (!self.aborted.load(.Unordered)) {
            var frames_left = self.period_size;
            while (frames_left > 0) {
                self.writeFn(self.user_data, frames_left);
                const n = c.snd_pcm_writei(self.pcm, self.sample_buffer.ptr, frames_left);
                if (n < 0) {
                    if (c.snd_pcm_recover(self.pcm, @intCast(c_int, n), 1) < 0) {
                        if (std.debug.runtime_safety) unreachable;
                        return;
                    }
                    return;
                }
                frames_left -= @intCast(c_uint, n);
            }
        }
    }

    pub fn play(self: Player) !void {
        if (c.snd_pcm_state(self.pcm) == c.SND_PCM_STATE_PAUSED) {
            if (c.snd_pcm_pause(self.pcm, 0) < 0)
                return error.CannotPlay;
        }
    }

    pub fn pause(self: Player) !void {
        if (c.snd_pcm_state(self.pcm) != c.SND_PCM_STATE_PAUSED) {
            if (c.snd_pcm_pause(self.pcm, 1) < 0)
                return error.CannotPause;
        }
    }

    pub fn paused(self: Player) bool {
        return c.snd_pcm_state(self.pcm) == c.SND_PCM_STATE_PAUSED;
    }

    pub fn setVolume(self: *Player, vol: f32) !void {
        self.mutex.lock();
        defer self.mutex.unlock();

        var min_vol: c_long = 0;
        var max_vol: c_long = 0;
        if (c.snd_mixer_selem_get_playback_volume_range(self.mixer_elm, &min_vol, &max_vol) < 0)
            return error.CannotSetVolume;

        const dist = @intToFloat(f32, max_vol - min_vol);
        if (c.snd_mixer_selem_set_playback_volume_all(
            self.mixer_elm,
            @floatToInt(c_long, dist * vol) + min_vol,
        ) < 0)
            return error.CannotSetVolume;
    }

    pub fn volume(self: *Player) !f32 {
        self.mutex.lock();
        defer self.mutex.unlock();

        var vol: c_long = 0;
        var channel: c_int = 0;

        while (channel < c.SND_MIXER_SCHN_LAST) : (channel += 1) {
            if (c.snd_mixer_selem_has_playback_channel(self.mixer_elm, channel) == 1) {
                if (c.snd_mixer_selem_get_playback_volume(self.mixer_elm, channel, &vol) == 0)
                    break;
            }
        }

        if (channel == c.SND_MIXER_SCHN_LAST)
            return error.CannotGetVolume;

        var min_vol: c_long = 0;
        var max_vol: c_long = 0;
        if (c.snd_mixer_selem_get_playback_volume_range(self.mixer_elm, &min_vol, &max_vol) < 0)
            return error.CannotGetVolume;

        return @intToFloat(f32, vol) / @intToFloat(f32, max_vol - min_vol);
    }

    pub fn sampleRate(self: Player) u24 {
        return self.sample_rate;
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

pub fn toAlsaFormat(format: main.Format) !c.snd_pcm_format_t {
    return switch (format) {
        .u8 => c.SND_PCM_FORMAT_U8,
        .i8 => c.SND_PCM_FORMAT_S8,
        .i16 => if (is_little) c.SND_PCM_FORMAT_S16_LE else c.SND_PCM_FORMAT_S16_BE,
        .i24 => if (is_little) c.SND_PCM_FORMAT_S24_3LE else c.SND_PCM_FORMAT_S24_3BE,
        .i24_4b => if (is_little) c.SND_PCM_FORMAT_S24_LE else c.SND_PCM_FORMAT_S24_BE,
        .i32 => if (is_little) c.SND_PCM_FORMAT_S32_LE else c.SND_PCM_FORMAT_S32_BE,
        .f32 => if (is_little) c.SND_PCM_FORMAT_FLOAT_LE else c.SND_PCM_FORMAT_FLOAT_BE,
    };
}

pub fn fromAlsaChannel(pos: c_uint) !main.Channel.Id {
    return switch (pos) {
        c.SND_CHMAP_UNKNOWN, c.SND_CHMAP_NA => return error.Invalid,
        c.SND_CHMAP_MONO, c.SND_CHMAP_FC => .front_center,
        c.SND_CHMAP_FL => .front_left,
        c.SND_CHMAP_FR => .front_right,
        c.SND_CHMAP_LFE => .lfe,
        c.SND_CHMAP_SL => .side_left,
        c.SND_CHMAP_SR => .side_right,
        c.SND_CHMAP_RC => .back_center,
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

pub fn toCHMAP(pos: main.Channel.Id) c_uint {
    return switch (pos) {
        .front_center => c.SND_CHMAP_FC,
        .front_left => c.SND_CHMAP_FL,
        .front_right => c.SND_CHMAP_FR,
        .lfe => c.SND_CHMAP_LFE,
        .side_left => c.SND_CHMAP_SL,
        .side_right => c.SND_CHMAP_SR,
        .back_center => c.SND_CHMAP_RC,
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

test {
    std.testing.refAllDeclsRecursive(@This());
}
