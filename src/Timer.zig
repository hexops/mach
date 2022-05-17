const std = @import("std");
const builtin = @import("builtin");

const Timer = @This();

backing_timer: BackingTimerType = undefined,

// TODO: verify declarations and its signatures
const BackingTimerType = if (builtin.cpu.arch == .wasm32) void else std.time.Timer;

/// Initialize the timer.
pub fn start() !Timer {
    return Timer{
        .backing_timer = try BackingTimerType.start(),
    };
}

/// Reads the timer value since start or the last reset in nanoseconds.
pub fn readPrecise(timer: *Timer) u64 {
    return timer.backing_timer.read();
}

/// Reads the timer value since start or the last reset in seconds.
pub fn read(timer: *Timer) f32 {
    return @intToFloat(f32, timer.readPrecise()) / @intToFloat(f32, std.time.ns_per_s);
}

/// Resets the timer value to 0/now.
pub fn reset(timer: *Timer) void {
    timer.backing_timer.reset();
}

/// Returns the current value of the timer in nanoseconds, then resets it.
pub fn lapPrecise(timer: *Timer) u64 {
    return timer.backing_timer.lap();
}

/// Returns the current value of the timer in seconds, then resets it.
pub fn lap(timer: *Timer) f32 {
    return @intToFloat(f32, timer.lapPrecise()) / @intToFloat(f32, std.time.ns_per_s);
}
