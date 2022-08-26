const c = @import("c.zig").c;

/// Gamepad buttons.
///
/// See glfw.getGamepadState for how these are used.
pub const GamepadButton = enum(c_int) {
    a = c.GLFW_GAMEPAD_BUTTON_A,
    b = c.GLFW_GAMEPAD_BUTTON_B,
    x = c.GLFW_GAMEPAD_BUTTON_X,
    y = c.GLFW_GAMEPAD_BUTTON_Y,
    left_bumper = c.GLFW_GAMEPAD_BUTTON_LEFT_BUMPER,
    right_bumper = c.GLFW_GAMEPAD_BUTTON_RIGHT_BUMPER,
    back = c.GLFW_GAMEPAD_BUTTON_BACK,
    start = c.GLFW_GAMEPAD_BUTTON_START,
    guide = c.GLFW_GAMEPAD_BUTTON_GUIDE,
    left_thumb = c.GLFW_GAMEPAD_BUTTON_LEFT_THUMB,
    right_thumb = c.GLFW_GAMEPAD_BUTTON_RIGHT_THUMB,
    dpad_up = c.GLFW_GAMEPAD_BUTTON_DPAD_UP,
    dpad_right = c.GLFW_GAMEPAD_BUTTON_DPAD_RIGHT,
    dpad_down = c.GLFW_GAMEPAD_BUTTON_DPAD_DOWN,
    dpad_left = c.GLFW_GAMEPAD_BUTTON_DPAD_LEFT,
};

/// Not in the GamepadAxis enumeration as it is a duplicate value which is forbidden.
pub const last = GamepadButton.dpad_left;

/// Not in the GamepadAxis enumeration as it is a duplicate value which is forbidden.
pub const cross = GamepadButton.a;

/// Not in the GamepadAxis enumeration as it is a duplicate value which is forbidden.
pub const circle = GamepadButton.b;

/// Not in the GamepadAxis enumeration as it is a duplicate value which is forbidden.
pub const square = GamepadButton.x;

/// Not in the GamepadAxis enumeration as it is a duplicate value which is forbidden.
pub const triangle = GamepadButton.y;
