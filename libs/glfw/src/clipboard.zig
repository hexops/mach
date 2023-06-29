const std = @import("std");

const c = @import("c.zig").c;

const internal_debug = @import("internal_debug.zig");

/// Sets the clipboard to the specified string.
///
/// This function sets the system clipboard to the specified, UTF-8 encoded string.
///
/// @param[in] string A UTF-8 encoded string.
///
/// Possible errors include glfw.ErrorCode.PlatformError.
///
/// @pointer_lifetime The specified string is copied before this function returns.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: clipboard, glfwGetClipboardString
pub inline fn setClipboardString(value: [*:0]const u8) void {
    internal_debug.assertInitialized();
    c.glfwSetClipboardString(null, value);
}

/// Returns the contents of the clipboard as a string.
///
/// This function returns the contents of the system clipboard, if it contains or is convertible to
/// a UTF-8 encoded string. If the clipboard is empty or if its contents cannot be converted,
/// glfw.ErrorCode.FormatUnavailable is returned.
///
/// @return The contents of the clipboard as a UTF-8 encoded string.
///
/// Possible errors include glfw.ErrorCode.FormatUnavailable and glfw.ErrorCode.PlatformError.
/// null is returned in the event of an error.
///
/// @pointer_lifetime The returned string is allocated and freed by GLFW. You should not free it
/// yourself. It is valid until the next call to glfw.getClipboardString or glfw.setClipboardString
/// or until the library is terminated.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: clipboard, glfwSetClipboardString
pub inline fn getClipboardString() ?[:0]const u8 {
    internal_debug.assertInitialized();
    if (c.glfwGetClipboardString(null)) |c_str| return std.mem.span(@as([*:0]const u8, @ptrCast(c_str)));
    return null;
}

test "setClipboardString" {
    const glfw = @import("main.zig");
    defer glfw.clearError(); // clear any error we generate
    if (!glfw.init(.{})) {
        std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    defer glfw.terminate();

    glfw.setClipboardString("hello mach");
}

test "getClipboardString" {
    const glfw = @import("main.zig");
    defer glfw.clearError(); // clear any error we generate
    if (!glfw.init(.{})) {
        std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    defer glfw.terminate();

    _ = glfw.getClipboardString();
}
