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

/// Terminates the GLFW library.
///
/// This function destroys all remaining windows and cursors, restores any modified gamma ramps
/// and frees any other allocated resources. Once this function is called, you must again call
/// glfw.init successfully before you will be able to use most GLFW functions.
///
/// If GLFW has been successfully initialized, this function should be called before the
/// application exits. If initialization fails, there is no need to call this function, as it is
/// called by glfw.init before it returns failure.
///
/// This function has no effect if GLFW is not initialized.
///
/// Possible errors include glfw.Error.PlatformError.
///
/// remark: This function may be called before glfw.init.
///
/// warning: The contexts of any remaining windows must not be current on any other thread when
/// this function is called.
///
/// reentrancy: This function must not be called from a callback.
///
/// thread_safety: This function must only be called from the main thread.
pub inline fn terminate() void {
    c.glfwTerminate();
}

/// Sets the specified init hint to the desired value.
///
/// This function sets hints for the next initialization of GLFW.
///
/// The values you set hints to are never reset by GLFW, but they only take effect during
/// initialization. Once GLFW has been initialized, any values you set will be ignored until the
/// library is terminated and initialized again.
///
/// Some hints are platform specific.  These may be set on any platform but they will only affect
/// their specific platform.  Other platforms will ignore them. Setting these hints requires no
/// platform specific headers or functions.
///
/// @param hint: The init hint to set.
/// @param value: The new value of the init hint.
///
/// Possible errors include glfw.Error.InvalidEnum and glfw.Error.InvalidValue.
///
/// @remarks This function may be called before glfw.init.
///
/// @thread_safety This function must only be called from the main thread.
pub inline fn initHint(hint: c_int, value: c_int) !void {
    c.glfwInitHint(hint, value);
    try getError();
}

/// Returns a string describing the compile-time configuration.
///
/// This function returns the compile-time generated version string of the GLFW library binary. It
/// describes the version, platform, compiler and any platform-specific compile-time options. It
/// should not be confused with the OpenGL or OpenGL ES version string, queried with `glGetString`.
///
/// __Do not use the version string__ to parse the GLFW library version. Use the glfw.version
/// constants instead.
///
/// @return The ASCII encoded GLFW version string.
///
/// @errors None.
///
/// @remark This function may be called before @ref glfwInit.
///
/// @pointer_lifetime The returned string is static and compile-time generated.
///
/// @thread_safety This function may be called from any thread.
pub inline fn getVersionString() [*c]const u8 {
    return c.glfwGetVersionString();
}

pub fn basicTest() !void {
    try init();
    defer terminate();

    c.glfwWindowHint(c.GLFW_VISIBLE, c.GLFW_FALSE);
    const window = c.glfwCreateWindow(640, 480, "GLFW example", null, null);
    if (window == null) {
        @panic("failed to create window");
    }

    var start = std.time.milliTimestamp();
    while (std.time.milliTimestamp() < start + 3000 and c.glfwWindowShouldClose(window) != c.GLFW_TRUE) {
        c.glfwPollEvents();
    }

    c.glfwDestroyWindow(window);
}

test "version" {
    std.debug.print("\nGLFW version v{}.{}.{}\n", .{ version.major, version.minor, version.revision });
    std.debug.print("\nstring: {s}\n", .{ getVersionString() });
}

test "basic" {
    basicTest() catch unreachable;
}
