//! Mouse button IDs.
//!
//! See glfw.setMouseButtonCallback for how these are used.

const c = @import("c.zig").c;

pub const one = C.GLFW_MOUSE_BUTTON_1;
pub const two = C.GLFW_MOUSE_BUTTON_2;
pub const three = C.GLFW_MOUSE_BUTTON_3;
pub const four = C.GLFW_MOUSE_BUTTON_4;
pub const five = C.GLFW_MOUSE_BUTTON_5;
pub const six = C.GLFW_MOUSE_BUTTON_6;
pub const seven = C.GLFW_MOUSE_BUTTON_7;
pub const eight = C.GLFW_MOUSE_BUTTON_8;

pub const last = eight;
pub const left = one;
pub const right = two;
pub const middle = three;
