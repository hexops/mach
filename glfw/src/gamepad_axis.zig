//! Gamepad axes.
//!
//! See glfw.getGamepadState for how these are used.

const c = @import("c.zig").c;

pub const left_x = C.GLFW_GAMEPAD_AXIS_LEFT_X;
pub const left_y = C.GLFW_GAMEPAD_AXIS_LEFT_Y;
pub const right_x = C.GLFW_GAMEPAD_AXIS_RIGHT_X;
pub const right_y = C.GLFW_GAMEPAD_AXIS_RIGHT_Y;
pub const left_trigger = C.GLFW_GAMEPAD_AXIS_LEFT_TRIGGER;
pub const right_trigger = C.GLFW_GAMEPAD_AXIS_RIGHT_TRIGGER;
pub const left = right_trigger;
