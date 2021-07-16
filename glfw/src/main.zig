const std = @import("std");
const testing = std.testing;

const c = @cImport(@cInclude("GLFW/glfw3.h"));

pub usingnamespace @import("consts.zig");
pub const Error = @import("errors.zig").Error;
const getError = @import("errors.zig").getError;

pub const action = @import("action.zig");
pub const gamepad_axis = @import("gamepad_axis.zig");
pub const gamepad_button = @import("gamepad_button.zig");
pub const hat = @import("hat.zig");
pub const joystick = @import("joystick.zig");
pub const key = @import("key.zig");
pub const mod = @import("mod.zig");
pub const mouse_button = @import("mouse_button.zig");
pub const version = @import("version.zig");

/// Initializes the GLFW library.
///
/// This function initializes the GLFW library. Before most GLFW functions can be used, GLFW must
/// be initialized, and before an application terminates GLFW should be terminated in order to free
/// any resources allocated during or after initialization.
///
/// If this function fails, it calls glfw.Terminate before returning. If it succeeds, you should
/// call glfw.Terminate before the application exits.
///
/// Additional calls to this function after successful initialization but before termination will
/// return immediately with no error.
///
/// macos: This function will change the current directory of the application to the
/// `Contents/Resources` subdirectory of the application's bundle, if present. This can be disabled
/// with the glfw.COCOA_CHDIR_RESOURCES init hint.
///
/// x11: This function will set the `LC_CTYPE` category of the application locale according to the
/// current environment if that category is still "C".  This is because the "C" locale breaks
/// Unicode text input.
///
/// @thread_safety This function must only be called from the main thread.
pub fn init() Error!void {
    if (c.glfwInit() != c.GLFW_TRUE) {
        return try getError();
    }
    return;
}

pub fn basicTest() void {
    init() catch @panic("failed to init!");
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
