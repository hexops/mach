const std = @import("std");

const c = @import("c.zig").c;
const Error = @import("errors.zig").Error;
const getError = @import("errors.zig").getError;

const internal_debug = @import("internal_debug.zig");

/// Sets the clipboard to the specified string.
///
/// This function sets the system clipboard to the specified, UTF-8 encoded string.
///
/// @param[in] string A UTF-8 encoded string.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
///
/// @pointer_lifetime The specified string is copied before this function returns.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: clipboard, glfwGetClipboardString
pub inline fn setClipboardString(value: [*:0]const u8) Error!void {
    internal_debug.assertInitialized();
    c.glfwSetClipboardString(null, value);
    getError() catch |err| return switch (err) {
        Error.PlatformError => err,
        else => unreachable,
    };
}

/// Returns the contents of the clipboard as a string.
///
/// This function returns the contents of the system clipboard, if it contains or is convertible to
/// a UTF-8 encoded string. If the clipboard is empty or if its contents cannot be converted,
/// glfw.Error.FormatUnavailable is returned.
///
/// @return The contents of the clipboard as a UTF-8 encoded string.
///
/// Possible errors include glfw.Error.NotInitialized, glfw.Error.FormatUnavailable and glfw.Error.PlatformError.
///
/// @pointer_lifetime The returned string is allocated and freed by GLFW. You should not free it
/// yourself. It is valid until the next call to glfw.getClipboardString or glfw.setClipboardString
/// or until the library is terminated.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: clipboard, glfwSetClipboardString
pub inline fn getClipboardString() Error![:0]const u8 {
    internal_debug.assertInitialized();
    const value = c.glfwGetClipboardString(null);
    getError() catch |err| return switch (err) {
        Error.PlatformError,
        Error.FormatUnavailable,
        => err,
        else => unreachable,
    };
    return std.mem.span(value);
}

test "setClipboardString" {
    const glfw = @import("main.zig");
    try glfw.init(.{});
    defer glfw.terminate();

    try glfw.setClipboardString("hello mach");
}

test "getClipboardString" {
    const glfw = @import("main.zig");
    try glfw.init(.{});
    defer glfw.terminate();

    _ = glfw.getClipboardString() catch |err| std.debug.print("can't get clipboard, not supported by OS? error={}\n", .{err});
}
