const builtin = @import("builtin");
const std = @import("std");
const util = @import("util.zig");
const backends = @import("backends.zig");
const conv = @import("conv.zig");

pub const Backend = backends.Backend;
pub const Range = util.Range;

pub const default_latency = 30 * std.time.us_per_ms; // ms
pub const min_sample_rate = 8_000; // Hz
pub const max_sample_rate = 5_644_800; // Hz

pub const Context = struct {
    pub const DeviceChangeFn = *const fn (userdata: ?*anyopaque) void;
    pub const Options = struct {
        app_name: [:0]const u8 = "Mach Game",
        deviceChangeFn: ?DeviceChangeFn = null,
        user_data: ?*anyopaque = null,
    };

    data: backends.Context,

    pub const InitError = error{
        OutOfMemory,
        AccessDenied,
        LibraryNotFound,
        SymbolLookup,
        SystemResources,
        ConnectionRefused,
    };

    pub fn init(comptime backend: ?Backend, allocator: std.mem.Allocator, options: Options) InitError!Context {
        const data: backends.Context = blk: {
            if (backend) |b| {
                break :blk try @typeInfo(
                    std.meta.fieldInfo(backends.Context, b).type,
                ).Pointer.child.init(allocator, options);
            } else {
                inline for (std.meta.fields(Backend), 0..) |b, i| {
                    if (@typeInfo(
                        std.meta.fieldInfo(backends.Context, @as(Backend, @enumFromInt(b.value))).type,
                    ).Pointer.child.init(allocator, options)) |d| {
                        break :blk d;
                    } else |err| {
                        if (i == std.meta.fields(Backend).len - 1)
                            return err;
                    }
                }
                unreachable;
            }
        };

        return .{ .data = data };
    }

    pub inline fn deinit(ctx: Context) void {
        switch (ctx.data) {
            inline else => |b| b.deinit(),
        }
    }

    pub const RefreshError = error{
        OutOfMemory,
        SystemResources,
        OpeningDevice,
    };

    pub inline fn refresh(ctx: Context) RefreshError!void {
        return switch (ctx.data) {
            inline else => |b| b.refresh(),
        };
    }

    pub inline fn devices(ctx: Context) []const Device {
        return switch (ctx.data) {
            inline else => |b| b.devices(),
        };
    }

    pub inline fn defaultDevice(ctx: Context, mode: Device.Mode) ?Device {
        return switch (ctx.data) {
            inline else => |b| b.defaultDevice(mode),
        };
    }

    pub const CreateStreamError = error{
        OutOfMemory,
        SystemResources,
        OpeningDevice,
        IncompatibleDevice,
    };

    pub inline fn createPlayer(ctx: Context, device: Device, writeFn: WriteFn, options: StreamOptions) CreateStreamError!Player {
        std.debug.assert(device.mode == .playback);

        return .{
            .data = switch (ctx.data) {
                inline else => |b| try b.createPlayer(device, writeFn, options),
            },
        };
    }

    pub inline fn createRecorder(ctx: Context, device: Device, readFn: ReadFn, options: StreamOptions) CreateStreamError!Recorder {
        std.debug.assert(device.mode == .capture);

        return .{
            .data = switch (ctx.data) {
                inline else => |b| try b.createRecorder(device, readFn, options),
            },
        };
    }
};

pub const StreamOptions = struct {
    format: Format = .f32,
    sample_rate: ?u24 = null,
    media_role: MediaRole = .default,
    user_data: ?*anyopaque = null,
};

pub const MediaRole = enum {
    default,
    game,
    music,
    movie,
    communication,
};

// TODO: `*Player` instead `*anyopaque`
// https://github.com/ziglang/zig/issues/12325
pub const WriteFn = *const fn (user_data: ?*anyopaque, output: []u8) void;
// TODO: `*Recorder` instead `*anyopaque`
pub const ReadFn = *const fn (user_data: ?*anyopaque, input: []const u8) void;

pub const Player = struct {
    data: backends.Player,

    pub inline fn deinit(player: *Player) void {
        return switch (player.data) {
            inline else => |b| b.deinit(),
        };
    }

    pub const StartError = error{
        CannotPlay,
        OutOfMemory,
        SystemResources,
    };

    pub inline fn start(player: *Player) StartError!void {
        return switch (player.data) {
            inline else => |b| b.start(),
        };
    }

    pub const PlayError = error{
        CannotPlay,
        OutOfMemory,
    };

    pub inline fn play(player: *Player) PlayError!void {
        return switch (player.data) {
            inline else => |b| b.play(),
        };
    }

    pub const PauseError = error{
        CannotPause,
        OutOfMemory,
    };

    pub inline fn pause(player: *Player) PauseError!void {
        return switch (player.data) {
            inline else => |b| b.pause(),
        };
    }

    pub inline fn paused(player: *Player) bool {
        return switch (player.data) {
            inline else => |b| b.paused(),
        };
    }

    pub const SetVolumeError = error{
        CannotSetVolume,
    };

    // confidence interval (±) depends on the device
    pub inline fn setVolume(player: *Player, vol: f32) SetVolumeError!void {
        std.debug.assert(vol <= 1.0);
        return switch (player.data) {
            inline else => |b| b.setVolume(vol),
        };
    }

    pub const GetVolumeError = error{
        CannotGetVolume,
    };

    // confidence interval (±) depends on the device
    pub inline fn volume(player: *Player) GetVolumeError!f32 {
        return switch (player.data) {
            inline else => |b| b.volume(),
        };
    }

    pub inline fn sampleRate(player: *Player) u24 {
        return if (@hasField(Backend, "jack")) switch (player.data) {
            .jack => |b| b.sampleRate(),
            inline else => |b| b.sample_rate,
        } else switch (player.data) {
            inline else => |b| b.sample_rate,
        };
    }

    pub inline fn channels(player: *Player) []ChannelPosition {
        return switch (player.data) {
            inline else => |b| b.channels,
        };
    }

    pub inline fn format(player: *Player) Format {
        return switch (player.data) {
            inline else => |b| b.format,
        };
    }
};

pub const Recorder = struct {
    data: backends.Recorder,

    pub inline fn deinit(recorder: *Recorder) void {
        return switch (recorder.data) {
            inline else => |b| b.deinit(),
        };
    }

    pub const StartError = error{
        CannotRecord,
        OutOfMemory,
        SystemResources,
    };

    pub inline fn start(recorder: *Recorder) StartError!void {
        return switch (recorder.data) {
            inline else => |b| b.start(),
        };
    }

    pub const RecordError = error{
        CannotRecord,
        OutOfMemory,
    };

    pub inline fn record(recorder: *Recorder) RecordError!void {
        return switch (recorder.data) {
            inline else => |b| b.record(),
        };
    }

    pub const PauseError = error{
        CannotPause,
        OutOfMemory,
    };

    pub inline fn pause(recorder: *Recorder) PauseError!void {
        return switch (recorder.data) {
            inline else => |b| b.pause(),
        };
    }

    pub inline fn paused(recorder: *Recorder) bool {
        return switch (recorder.data) {
            inline else => |b| b.paused(),
        };
    }

    pub const SetVolumeError = error{
        CannotSetVolume,
    };

    // confidence interval (±) depends on the device
    pub inline fn setVolume(recorder: *Recorder, vol: f32) SetVolumeError!void {
        std.debug.assert(vol <= 1.0);
        return switch (recorder.data) {
            inline else => |b| b.setVolume(vol),
        };
    }

    pub const GetVolumeError = error{
        CannotGetVolume,
    };

    // confidence interval (±) depends on the device
    pub inline fn volume(recorder: *Recorder) GetVolumeError!f32 {
        return switch (recorder.data) {
            inline else => |b| b.volume(),
        };
    }

    pub inline fn sampleRate(recorder: *Recorder) u24 {
        return if (@hasField(Backend, "jack")) switch (recorder.data) {
            .jack => |b| b.sampleRate(),
            inline else => |b| b.sample_rate,
        } else switch (recorder.data) {
            inline else => |b| b.sample_rate,
        };
    }

    pub inline fn channels(recorder: *Recorder) []ChannelPosition {
        return switch (recorder.data) {
            inline else => |b| b.channels,
        };
    }

    pub inline fn format(recorder: *Recorder) Format {
        return switch (recorder.data) {
            inline else => |b| b.format,
        };
    }
};

pub fn convertTo(comptime SrcType: type, src: []const SrcType, dst_format: Format, dst_bytes: []u8) void {
    const src_stride = @bitSizeOf(SrcType) / 8;
    const dst_stride = dst_format.size();
    const src_bytes = @as([*]const u8, @ptrCast(@alignCast(src)))[0 .. src.len * src_stride];
    std.debug.assert(@bitSizeOf(SrcType) % 8 == 0);
    std.debug.assert(dst_bytes.len / dst_stride == src.len);

    return switch (dst_format) {
        .u8 => switch (SrcType) {
            u8 => @memcpy(dst_bytes, src_bytes),
            i8, i16, i24, i32 => conv.signedToUnsigned(SrcType, src_stride, src_bytes, u8, dst_stride, dst_bytes, src.len),
            f32 => conv.floatToUnsigned(SrcType, src_stride, src_bytes, u8, dst_stride, dst_bytes, src.len),
            else => unreachable,
        },
        .i16 => switch (SrcType) {
            i16 => @memcpy(dst_bytes, src_bytes),
            u8 => conv.unsignedToSigned(SrcType, src_stride, src_bytes, i16, dst_stride, dst_bytes, src.len),
            i8, i24, i32 => conv.signedToSigned(SrcType, src_stride, src_bytes, i16, dst_stride, dst_bytes, src.len),
            f32 => conv.floatToSigned(SrcType, src_stride, src_bytes, i16, dst_stride, dst_bytes, src.len),
            else => unreachable,
        },
        .i24 => switch (SrcType) {
            i24 => @memcpy(dst_bytes, src_bytes),
            u8 => conv.unsignedToSigned(SrcType, src_stride, src_bytes, i24, dst_stride, dst_bytes, src.len),
            i8, i16, i32 => conv.signedToSigned(SrcType, src_stride, src_bytes, i24, dst_stride, dst_bytes, src.len),
            f32 => conv.floatToSigned(SrcType, src_stride, src_bytes, i24, dst_stride, dst_bytes, src.len),
            else => unreachable,
        },
        .i32 => switch (SrcType) {
            i32 => @memcpy(dst_bytes, src_bytes),
            u8 => conv.unsignedToSigned(SrcType, src_stride, src_bytes, i32, dst_stride, dst_bytes, src.len),
            i8, i16, i24 => conv.signedToSigned(SrcType, src_stride, src_bytes, i32, dst_stride, dst_bytes, src.len),
            f32 => conv.floatToSigned(SrcType, src_stride, src_bytes, i32, dst_stride, dst_bytes, src.len),
            else => unreachable,
        },
        .f32 => switch (SrcType) {
            f32 => @memcpy(dst_bytes, src_bytes),
            u8 => conv.unsignedToFloat(SrcType, src_stride, src_bytes, f32, dst_stride, dst_bytes, src.len),
            i8, i16, i24, i32 => conv.signedToFloat(SrcType, src_stride, src_bytes, f32, dst_stride, dst_bytes, src.len),
            else => unreachable,
        },
    };
}

pub fn convertFrom(comptime DstType: type, dst: []DstType, src_format: Format, src_bytes: []const u8) void {
    const src_stride = src_format.size();
    const dst_stride = @bitSizeOf(DstType) / 8;
    const dst_bytes = @as([*]u8, @ptrCast(@alignCast(dst)))[0 .. dst.len * dst_stride];
    std.debug.assert(@bitSizeOf(DstType) % 8 == 0);
    std.debug.assert(src_bytes.len / src_stride == dst.len);

    return switch (src_format) {
        .u8 => switch (DstType) {
            u8 => @memcpy(dst_bytes, src_bytes),
            i8, i16, i24, i32 => conv.unsignedToSigned(u8, src_stride, src_bytes, DstType, dst_stride, dst_bytes, dst.len),
            f32 => conv.unsignedToFloat(u8, src_stride, src_bytes, DstType, dst_stride, dst_bytes, dst.len),
            else => unreachable,
        },
        .i16 => switch (DstType) {
            i16 => @memcpy(dst_bytes, src_bytes),
            u8 => conv.signedToUnsigned(i16, src_stride, src_bytes, DstType, dst_stride, dst_bytes, dst.len),
            i8, i24, i32 => conv.signedToSigned(i16, src_stride, src_bytes, DstType, dst_stride, dst_bytes, dst.len),
            f32 => conv.signedToFloat(i16, src_stride, src_bytes, DstType, dst_stride, dst_bytes, dst.len),
            else => unreachable,
        },
        .i24 => switch (DstType) {
            i24 => @memcpy(dst_bytes, src_bytes),
            u8 => conv.signedToUnsigned(i24, src_stride, src_bytes, DstType, dst_stride, dst_bytes, dst.len),
            i8, i16, i32 => conv.signedToSigned(i24, src_stride, src_bytes, DstType, dst_stride, dst_bytes, dst.len),
            f32 => conv.signedToFloat(i24, src_stride, src_bytes, DstType, dst_stride, dst_bytes, dst.len),
            else => unreachable,
        },
        .i32 => switch (DstType) {
            i32 => @memcpy(dst_bytes, src_bytes),
            u8 => conv.signedToUnsigned(i32, src_stride, src_bytes, DstType, dst_stride, dst_bytes, dst.len),
            i8, i16, i24 => conv.signedToSigned(i32, src_stride, src_bytes, DstType, dst_stride, dst_bytes, dst.len),
            f32 => conv.signedToFloat(i32, src_stride, src_bytes, DstType, dst_stride, dst_bytes, dst.len),
            else => unreachable,
        },
        .f32 => switch (DstType) {
            f32 => @memcpy(dst_bytes, src_bytes),
            u8 => conv.floatToUnsigned(f32, src_stride, src_bytes, DstType, dst_stride, dst_bytes, dst.len),
            i8, i16, i24, i32 => conv.floatToSigned(f32, src_stride, src_bytes, DstType, dst_stride, dst_bytes, dst.len),
            else => unreachable,
        },
    };
}

pub const Device = struct {
    id: [:0]const u8,
    name: [:0]const u8,
    mode: Mode,
    channels: []ChannelPosition,
    formats: []const Format,
    sample_rate: util.Range(u24),

    pub const Mode = enum {
        playback,
        capture,
    };

    // TODO: don't call this in backends. let the user use it
    pub fn preferredFormat(device: Device, format: ?Format) Format {
        if (format) |f| {
            for (device.formats) |fmt| if (f == fmt) return fmt;
        }

        var best: Format = device.formats[0];
        for (device.formats) |fmt| {
            if (@intFromEnum(fmt) > @intFromEnum(best)) best = fmt;
        }
        return best;
    }
};

pub const ChannelPosition = enum {
    front_center,
    front_left,
    front_right,
    front_left_center,
    front_right_center,
    back_center,
    back_left,
    back_right,
    side_left,
    side_right,
    top_center,
    top_front_center,
    top_front_left,
    top_front_right,
    top_back_center,
    top_back_left,
    top_back_right,
    lfe,
};

pub const Format = enum {
    u8,
    i16,
    i24,
    i32,
    f32,

    pub inline fn size(format: Format) u8 {
        return switch (format) {
            .u8 => 1,
            .i16 => 2,
            .i24 => 3,
            .i32, .f32 => 4,
        };
    }

    pub inline fn validSize(format: Format) u8 {
        return switch (format) {
            .u8 => 1,
            .i16 => 2,
            .i24 => 3,
            .i32, .f32 => 4,
        };
    }

    pub inline fn sizeBits(format: Format) u8 {
        return format.size() * 8;
    }

    pub inline fn validSizeBits(format: Format) u8 {
        return format.validSize() * 8;
    }

    pub inline fn frameSize(format: Format, channels: u8) u8 {
        return format.size() * channels;
    }
};

test "reference declarations" {
    _ = conv;
    _ = backends.Context;
    _ = backends.Player;
    _ = backends.Recorder;
}
