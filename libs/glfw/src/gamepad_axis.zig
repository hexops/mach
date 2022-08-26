const c = @import("c.zig").c;

/// Gamepad axes.
///
/// See glfw.getGamepadState for how these are used.
pub const GamepadAxis = enum(c_int) {
    left_x = c.GLFW_GAMEPAD_AXIS_LEFT_X,
    left_y = c.GLFW_GAMEPAD_AXIS_LEFT_Y,
    right_x = c.GLFW_GAMEPAD_AXIS_RIGHT_X,
    right_y = c.GLFW_GAMEPAD_AXIS_RIGHT_Y,
    left_trigger = c.GLFW_GAMEPAD_AXIS_LEFT_TRIGGER,
    right_trigger = c.GLFW_GAMEPAD_AXIS_RIGHT_TRIGGER,
};

/// Not in the GamepadAxis enumeration as it is a duplicate value which is forbidden.
pub const last = GamepadAxis.right_trigger;
