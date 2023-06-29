const c = @import("c.zig").c;

// must be in sync with GLFW C constants in hat state group, search for "@defgroup hat_state Joystick hat states"
/// A bitmask of all Joystick hat states
///
/// See glfw.Joystick.getHats for how these are used.
pub const Hat = packed struct(u8) {
    up: bool = false,
    right: bool = false,
    down: bool = false,
    left: bool = false,
    _padding: u4 = 0,

    pub inline fn centered(self: Hat) bool {
        return self.up == false and self.right == false and self.down == false and self.left == false;
    }

    inline fn verifyIntType(comptime IntType: type) void {
        comptime {
            switch (@typeInfo(IntType)) {
                .Int => {},
                else => @compileError("Int was not of int type"),
            }
        }
    }

    pub inline fn toInt(self: Hat, comptime IntType: type) IntType {
        verifyIntType(IntType);
        return @as(IntType, @intCast(@as(u8, @bitCast(self))));
    }

    pub inline fn fromInt(flags: anytype) Hat {
        verifyIntType(@TypeOf(flags));
        return @as(Hat, @bitCast(@as(u8, @intCast(flags))));
    }
};

/// Holds all GLFW hat values in their raw form.
pub const RawHat = struct {
    pub const centered = c.GLFW_HAT_CENTERED;
    pub const up = c.GLFW_HAT_UP;
    pub const right = c.GLFW_HAT_RIGHT;
    pub const down = c.GLFW_HAT_DOWN;
    pub const left = c.GLFW_HAT_LEFT;

    pub const right_up = right | up;
    pub const right_down = right | down;
    pub const left_up = left | up;
    pub const left_down = left | down;
};

test "from int, single" {
    const std = @import("std");

    try std.testing.expectEqual(Hat{
        .up = true,
        .right = false,
        .down = false,
        .left = false,
        ._padding = 0,
    }, Hat.fromInt(RawHat.up));
}

test "from int, multi" {
    const std = @import("std");

    try std.testing.expectEqual(Hat{
        .up = true,
        .right = false,
        .down = true,
        .left = true,
        ._padding = 0,
    }, Hat.fromInt(RawHat.up | RawHat.down | RawHat.left));
}

test "to int, single" {
    const std = @import("std");

    var v = Hat{
        .up = true,
        .right = false,
        .down = false,
        .left = false,
        ._padding = 0,
    };
    try std.testing.expectEqual(v.toInt(c_int), RawHat.up);
}

test "to int, multi" {
    const std = @import("std");

    var v = Hat{
        .up = true,
        .right = false,
        .down = true,
        .left = true,
        ._padding = 0,
    };
    try std.testing.expectEqual(v.toInt(c_int), RawHat.up | RawHat.down | RawHat.left);
}
