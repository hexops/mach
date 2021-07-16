const std = @import("std");
const testing = std.testing;

const c = @cImport(@cInclude("GLFW/glfw3.h"));

pub usingnamespace @import("consts.zig");

pub const action = @import("action.zig");
pub const gamepad_axis = @import("gamepad_axis.zig");
pub const gamepad_button = @import("gamepad_button.zig");
pub const hat = @import("hat.zig");
pub const joystick = @import("joystick.zig");
pub const key = @import("key.zig");
pub const mod = @import("mod.zig");
pub const mouse_button = @import("mouse_button.zig");
pub const version = @import("version.zig");

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
    std.debug.print("\nGLFW version v{}.{}.{}\n", .{ version.major, version.minor, version.revision });
}

test "basic" {
    basicTest();
}
