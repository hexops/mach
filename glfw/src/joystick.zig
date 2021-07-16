//! Joystick IDs.
//!
//! See glfw.setJoystickCallback for how these are used.

const c = @cImport(@cInclude("GLFW/glfw3.h"));

pub const one = C.GLFW_JOYSTICK_1;
pub const two = C.GLFW_JOYSTICK_2;
pub const three = C.GLFW_JOYSTICK_3;
pub const four = C.GLFW_JOYSTICK_4;
pub const five = C.GLFW_JOYSTICK_5;
pub const six = C.GLFW_JOYSTICK_6;
pub const seven = C.GLFW_JOYSTICK_7;
pub const eight = C.GLFW_JOYSTICK_8;
pub const nine = C.GLFW_JOYSTICK_9;
pub const ten = C.GLFW_JOYSTICK_10;
pub const eleven = C.GLFW_JOYSTICK_11;
pub const twelve = C.GLFW_JOYSTICK_12;
pub const thirteen = C.GLFW_JOYSTICK_13;
pub const fourteen = C.GLFW_JOYSTICK_14;
pub const fifteen = C.GLFW_JOYSTICK_15;
pub const sixteen = C.GLFW_JOYSTICK_16;
pub const last = C.GLFW_JOYSTICK_LAST;
