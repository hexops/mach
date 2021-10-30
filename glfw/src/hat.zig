const c = @import("c.zig").c;

// must be in sync with GLFW C constants in hat state group, search for "@defgroup hat_state Joystick hat states"
/// A bitmask of all Joystick hat states
///
/// See glfw.Joystick.getHats for how these are used.
pub const Hat = packed struct {
    centered: bool align(@alignOf(u8)) = false,
    up: bool = false,
    right: bool = false,
    down: bool = false,
    left: bool = false,

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
        return @bitCast(IntType, self);
    }

    pub inline fn fromInt(flags: anytype) Hat {
        verifyIntType(@TypeOf(flags));
        return @bitCast(Hat, flags);
    }
};

/// Holds all GLFW hat values in their raw form.
pub const RawHats = struct {
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
