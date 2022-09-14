const std = @import("std");

pub fn main() void {
    var x: i16 = 1;
    x += 1;
    std.testing.expect(x == 2) catch unreachable;
}
