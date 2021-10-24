//! Mouse button IDs.
//!
//! See glfw.setMouseButtonCallback for how these are used.

const c = @import("c.zig").c;

pub const one = c.GLFW_MOUSE_BUTTON_1;
pub const two = c.GLFW_MOUSE_BUTTON_2;
pub const three = c.GLFW_MOUSE_BUTTON_3;
pub const four = c.GLFW_MOUSE_BUTTON_4;
pub const five = c.GLFW_MOUSE_BUTTON_5;
pub const six = c.GLFW_MOUSE_BUTTON_6;
pub const seven = c.GLFW_MOUSE_BUTTON_7;
pub const eight = c.GLFW_MOUSE_BUTTON_8;

pub const last = eight;
pub const left = one;
pub const right = two;
pub const middle = three;
