//! Joystick hat states
//!
//! See glfw.getJoystickHats for how these are used.

const c = @import("c.zig").c;

pub const centered = c.GLFW_HAT_CENTERED;
pub const up = c.GLFW_HAT_UP;
pub const right = c.GLFW_HAT_RIGHT;
pub const down = c.GLFW_HAT_DOWN;
pub const left = c.GLFW_HAT_LEFT;

pub const right_up = right | up;
pub const right_down = right | down;
pub const left_up = left | up;
pub const left_down = left | down;
