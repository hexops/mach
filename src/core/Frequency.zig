const std = @import("std");
const core = @import("main.zig");
const Timer = @import("Timer.zig");

pub const Frequency = @This();

/// The target frequency (e.g. 60hz) or zero for unlimited
target: u32 = 0,

/// The estimated delay that is needed to achieve the target frequency. Updated during tick()
delay_ns: u64 = 0,

/// The actual measured frequency. This is updated every second.
rate: u32 = 0,

delta_time: ?*f32 = null,
delta_time_ns: *u64 = undefined,

/// Internal fields, this must be initialized via a call to start().
internal: struct {
    // The frame number in this second's cycle. e.g. zero to 59
    count: u32,
    timer: Timer,
    last_time: u64,
} = undefined,

/// Starts the timer used for frequency calculation. Must be called once before anything else.
pub fn start(f: *Frequency) !void {
    f.internal = .{
        .count = 0,
        .timer = try Timer.start(),
        .last_time = 0,
    };
}

/// Tick should be called at each occurrence (e.g. frame)
pub inline fn tick(f: *Frequency) void {
    var current_time = f.internal.timer.readPrecise();

    if (f.delta_time) |delta_time| {
        f.delta_time_ns.* = current_time -| f.internal.last_time;
        delta_time.* = @as(f32, @floatFromInt(f.delta_time_ns.*)) / @as(f32, @floatFromInt(std.time.ns_per_s));
    }

    if (current_time >= std.time.ns_per_s) {
        f.rate = f.internal.count;
        f.internal.count = 0;
        f.internal.timer.reset();
        current_time -= std.time.ns_per_s;
    }
    f.internal.last_time = current_time;
    f.internal.count += 1;

    if (f.target != 0) {
        const limited_count = @min(f.target, f.internal.count);
        const target_time_per_tick: u64 = (std.time.ns_per_s / f.target);
        const target_time = target_time_per_tick * limited_count;
        if (current_time > target_time) {
            f.delay_ns = 0;
        } else {
            f.delay_ns = target_time - current_time;
        }
    } else {
        f.delay_ns = 0;
    }
}
