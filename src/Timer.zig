const std = @import("std");
const platform = @import("platform.zig");

pub const Timer = @This();

internal: platform.Timer,

/// Initialize the timer.
pub fn start() !Timer {
    return Timer{
        .internal = try platform.Timer.start(),
    };
}

/// Reads the timer value since start or the last reset in nanoseconds.
pub inline fn readPrecise(timer: *Timer) u64 {
    return timer.internal.read();
}

/// Reads the timer value since start or the last reset in seconds.
pub inline fn read(timer: *Timer) f32 {
    return @intToFloat(f32, timer.readPrecise()) / @intToFloat(f32, std.time.ns_per_s);
}

/// Resets the timer value to 0/now.
pub inline fn reset(timer: *Timer) void {
    timer.internal.reset();
}

/// Returns the current value of the timer in nanoseconds, then resets it.
pub inline fn lapPrecise(timer: *Timer) u64 {
    return timer.internal.lap();
}

/// Returns the current value of the timer in seconds, then resets it.
pub inline fn lap(timer: *Timer) f32 {
    return @intToFloat(f32, timer.lapPrecise()) / @intToFloat(f32, std.time.ns_per_s);
}
