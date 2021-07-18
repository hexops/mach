//! Gamepad buttons.
//!
//! See glfw.getGamepadState for how these are used.

const c = @import("c.zig").c;

pub const a = C.GLFW_GAMEPAD_BUTTON_A;
pub const b = C.GLFW_GAMEPAD_BUTTON_B;
pub const x = C.GLFW_GAMEPAD_BUTTON_X;
pub const y = C.GLFW_GAMEPAD_BUTTON_Y;
pub const left_bumper = C.GLFW_GAMEPAD_BUTTON_LEFT_BUMPER;
pub const right_bumper = C.GLFW_GAMEPAD_BUTTON_RIGHT_BUMPER;
pub const back = C.GLFW_GAMEPAD_BUTTON_BACK;
pub const start = C.GLFW_GAMEPAD_BUTTON_START;
pub const guide = C.GLFW_GAMEPAD_BUTTON_GUIDE;
pub const left_thumb = C.GLFW_GAMEPAD_BUTTON_LEFT_THUMB;
pub const right_thumb = C.GLFW_GAMEPAD_BUTTON_RIGHT_THUMB;
pub const dpad_up = C.GLFW_GAMEPAD_BUTTON_DPAD_UP;
pub const dpad_right = C.GLFW_GAMEPAD_BUTTON_DPAD_RIGHT;
pub const dpad_down = C.GLFW_GAMEPAD_BUTTON_DPAD_DOWN;
pub const dpad_left = C.GLFW_GAMEPAD_BUTTON_DPAD_LEFT;
pub const last = dpad_left;

pub const cross = a;
pub const circle = b;
pub const square = x;
pub const triangle = y;
