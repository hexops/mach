const std = @import("std");
const builtin = @import("builtin");
const PlatformTimer = if (builtin.cpu.arch == .wasm32) @panic("TODO: support WASM") else NativeTimer;

const Timer = @This();

platform: PlatformTimer,

/// Initialize the timer.
pub fn start() !Timer {
    return .{ .platform = try PlatformTimer.start() };
}

/// Reads the timer value since start or the last reset in nanoseconds.
pub inline fn readPrecise(timer: *Timer) u64 {
    return timer.platform.read();
}

/// Reads the timer value since start or the last reset in seconds.
pub inline fn read(timer: *Timer) f32 {
    return @as(f32, @floatFromInt(timer.readPrecise())) / @as(f32, @floatFromInt(std.time.ns_per_s));
}

/// Resets the timer value to 0/now.
pub inline fn reset(timer: *Timer) void {
    timer.platform.reset();
}

/// Returns the current value of the timer in nanoseconds, then resets it.
pub inline fn lapPrecise(timer: *Timer) u64 {
    return timer.platform.lap();
}

/// Returns the current value of the timer in seconds, then resets it.
pub inline fn lap(timer: *Timer) f32 {
    return @as(f32, @floatFromInt(timer.lapPrecise())) / @as(f32, @floatFromInt(std.time.ns_per_s));
}

const NativeTimer = struct {
    timer: std.time.Timer,

    pub fn start() !NativeTimer {
        return .{ .timer = try std.time.Timer.start() };
    }

    pub inline fn read(timer: *NativeTimer) u64 {
        return timer.timer.read();
    }

    pub inline fn reset(timer: *NativeTimer) void {
        timer.timer.reset();
    }

    pub inline fn lap(timer: *NativeTimer) u64 {
        return timer.timer.lap();
    }
};
