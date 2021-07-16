const std = @import("std");
const testing = std.testing;

const c = @cImport(@cInclude("GLFW/glfw3.h"));

// The major version number of the GLFW library.
//
// This is incremented when the API is changed in non-compatible ways.
pub const version_major = c.GLFW_VERSION_MAJOR;

// The minor version number of the GLFW library.
//
// This is incremented when features are added to the API but it remains backward-compatible.
pub const version_minor = c.GLFW_VERSION_MINOR;

// The revision number of the GLFW library.
//
// This is incremented when a bug fix release is made that does not contain any API changes.
pub const version_revision = c.GLFW_VERSION_REVISION;

// The key or mouse button was released.
pub const release = C.GLFW_RELEASE

// The key or mouse button was pressed.
pub const press = C.GLFW_RELEASE

// The key was held down until it repeated.
pub const repeat = C.GLFW_REPEAT

pub fn basicTest() void {
    if (c.glfwInit() != c.GLFW_TRUE) {
        @panic("failed to init");
    }
    c.glfwWindowHint(c.GLFW_VISIBLE, c.GLFW_FALSE);
    const window = c.glfwCreateWindow(640, 480, "GLFW example", null, null);
    if (window == null) {
        c.glfwTerminate();
        @panic("failed to create window");
    }

    var start = std.time.milliTimestamp();
    while (std.time.milliTimestamp() < start + 3000 and c.glfwWindowShouldClose(window) != c.GLFW_TRUE) {
        c.glfwPollEvents();
    }

    c.glfwDestroyWindow(window);
    c.glfwTerminate();
}

test "version" {
    std.debug.print("\nGLFW version v{}.{}.{}\n", .{version_major, version_minor, version_revision});
}

test "basic" {
    basicTest();
}
