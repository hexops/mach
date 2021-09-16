//! Key and button actions

const c = @import("c.zig").c;

/// The key or mouse button was released.
pub const release = c.GLFW_RELEASE;

/// The key or mouse button was pressed.
pub const press = c.GLFW_PRESS;

/// The key was held down until it repeated.
pub const repeat = c.GLFW_REPEAT;
