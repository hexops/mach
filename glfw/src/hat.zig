//! Joystick hat states
//!
//! See glfw.getJoystickHats for how these are used.

const c = @cImport(@cInclude("GLFW/glfw3.h"));

pub const centered = C.GLFW_HAT_CENTERED;
pub const up = C.GLFW_HAT_UP;
pub const right = C.GLFW_HAT_RIGHT;
pub const down = C.GLFW_HAT_DOWN;
pub const left = C.GLFW_HAT_LEFT;

pub const right_up = right | up;
pub const right_down = right | down;
pub const left_up = left | up;
pub const left_down = left | down;
