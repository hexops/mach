const c = @import("c.zig").c;

/// Mouse button IDs.
///
/// See glfw.setMouseButtonCallback for how these are used.
pub const MouseButton = enum(c_int) {
    // We use left/right/middle aliases here because those are more common and we cannot have
    // duplicate values in a Zig enum.
    left = c.GLFW_MOUSE_BUTTON_1,
    right = c.GLFW_MOUSE_BUTTON_2,
    middle = c.GLFW_MOUSE_BUTTON_3,
    four = c.GLFW_MOUSE_BUTTON_4,
    five = c.GLFW_MOUSE_BUTTON_5,
    six = c.GLFW_MOUSE_BUTTON_6,
    seven = c.GLFW_MOUSE_BUTTON_7,
    eight = c.GLFW_MOUSE_BUTTON_8,
};

/// Not in the MouseButton enumeration as it is a duplicate value which is forbidden.
pub const last = MouseButton.eight;
pub const one = MouseButton.left;
pub const two = MouseButton.right;
pub const three = MouseButton.middle;
