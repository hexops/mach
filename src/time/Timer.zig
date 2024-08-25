const mach = @import("../main.zig");
const std = @import("std");

const Timer = @This();

// TODO: support a WASM-based timer as well, which is the primary reason this abstraction exists.

timer: std.time.Timer,

/// Initialize the timer.
pub fn start() !Timer {
    return .{ .timer = try std.time.Timer.start() };
}

/// Reads the timer value since start or the last reset in nanoseconds.
pub inline fn readPrecise(timer: *Timer) u64 {
    return timer.timer.read();
}

/// Reads the timer value since start or the last reset in seconds.
pub inline fn read(timer: *Timer) f32 {
    return @as(f32, @floatFromInt(timer.readPrecise())) / @as(f32, @floatFromInt(mach.time.ns_per_s));
}

/// Resets the timer value to 0/now.
pub inline fn reset(timer: *Timer) void {
    timer.timer.reset();
}

/// Returns the current value of the timer in nanoseconds, then resets it.
pub inline fn lapPrecise(timer: *Timer) u64 {
    return timer.timer.lap();
}

/// Returns the current value of the timer in seconds, then resets it.
pub inline fn lap(timer: *Timer) f32 {
    return @as(f32, @floatFromInt(timer.lapPrecise())) / @as(f32, @floatFromInt(mach.time.ns_per_s));
}
