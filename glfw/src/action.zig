const c = @import("c.zig").c;

/// Key and button actions
pub const Action = enum(c_int) {
    /// The key or mouse button was released.
    release = c.GLFW_RELEASE,

    /// The key or mouse button was pressed.
    press = c.GLFW_PRESS,

    /// The key was held down until it repeated.
    repeat = c.GLFW_REPEAT,
};
