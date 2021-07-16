//! Key and button actions

const c = @cImport(@cInclude("GLFW/glfw3.h"));

// The key or mouse button was released.
pub const release = C.GLFW_RELEASE;

// The key or mouse button was pressed.
pub const press = C.GLFW_RELEASE;

// The key was held down until it repeated.
pub const repeat = C.GLFW_REPEAT;
