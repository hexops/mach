pub const std = @import("std");

pub const ns_per_s = std.time.ns_per_s;

pub const Timer = @import("Timer.zig");
pub const Frequency = @import("Frequency.zig");

test {
    _ = Timer;
    _ = Frequency;
}
