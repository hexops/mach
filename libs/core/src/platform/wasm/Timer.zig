const std = @import("std");
const js = @import("js.zig");

pub const Timer = @This();

initial: f64 = undefined,

pub fn start() !Timer {
    return Timer{ .initial = js.machPerfNow() };
}

pub fn read(timer: *Timer) u64 {
    return (js.machPerfNow() - timer.initial) * std.time.ns_per_ms;
}

pub fn reset(timer: *Timer) void {
    timer.initial = js.machPerfNow();
}

pub fn lap(timer: *Timer) u64 {
    const now = js.machPerfNow();
    const initial = timer.initial;
    timer.initial = now;
    return @floatToInt(u64, now - initial) * std.time.ns_per_ms;
}
