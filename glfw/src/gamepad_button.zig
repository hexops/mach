//! Gamepad buttons.
//!
//! See glfw.getGamepadState for how these are used.

const c = @import("c.zig").c;

pub const a = c.GLFW_GAMEPAD_BUTTON_A;
pub const b = c.GLFW_GAMEPAD_BUTTON_B;
pub const x = c.GLFW_GAMEPAD_BUTTON_X;
pub const y = c.GLFW_GAMEPAD_BUTTON_Y;
pub const left_bumper = c.GLFW_GAMEPAD_BUTTON_LEFT_BUMPER;
pub const right_bumper = c.GLFW_GAMEPAD_BUTTON_RIGHT_BUMPER;
pub const back = c.GLFW_GAMEPAD_BUTTON_BACK;
pub const start = c.GLFW_GAMEPAD_BUTTON_START;
pub const guide = c.GLFW_GAMEPAD_BUTTON_GUIDE;
pub const left_thumb = c.GLFW_GAMEPAD_BUTTON_LEFT_THUMB;
pub const right_thumb = c.GLFW_GAMEPAD_BUTTON_RIGHT_THUMB;
pub const dpad_up = c.GLFW_GAMEPAD_BUTTON_DPAD_UP;
pub const dpad_right = c.GLFW_GAMEPAD_BUTTON_DPAD_RIGHT;
pub const dpad_down = c.GLFW_GAMEPAD_BUTTON_DPAD_DOWN;
pub const dpad_left = c.GLFW_GAMEPAD_BUTTON_DPAD_LEFT;
pub const last = dpad_left;

pub const cross = a;
pub const circle = b;
pub const square = x;
pub const triangle = y;
