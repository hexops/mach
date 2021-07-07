const std = @import("std");
const testing = std.testing;

const c = @cImport(@cInclude("GLFW/glfw3.h"));

pub fn basicTest() void {
    if (c.glfwInit() != c.GLFW_TRUE) {
        @panic("failed to init");
    }
    const window = c.glfwCreateWindow(640, 480, "GLFW example", null, null);
    if (window == null)
    {
        c.glfwTerminate();
        @panic("failed to create window");
    }

    var start = std.time.milliTimestamp();
    while (std.time.milliTimestamp() < start+3000 and c.glfwWindowShouldClose(window) != c.GLFW_TRUE) {
        c.glfwPollEvents();
    }

    c.glfwDestroyWindow(window);
    c.glfwTerminate();
}

test "basic" {
    basicTest();
}
