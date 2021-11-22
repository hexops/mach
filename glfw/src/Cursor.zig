//! Represents a cursor and provides facilities for setting cursor images.

const std = @import("std");
const testing = std.testing;

const c = @import("c.zig").c;
const Error = @import("errors.zig").Error;
const getError = @import("errors.zig").getError;
const Image = @import("Image.zig");

const internal_debug = @import("internal_debug.zig");

const Cursor = @This();

ptr: *c.GLFWcursor,

// Standard system cursor shapes.
pub const Shape = enum(isize) {
    /// The regular arrow cursor shape.
    arrow = c.GLFW_ARROW_CURSOR,

    /// The text input I-beam cursor shape.
    ibeam = c.GLFW_IBEAM_CURSOR,

    /// The crosshair shape.
    crosshair = c.GLFW_CROSSHAIR_CURSOR,

    /// The hand shape.
    hand = c.GLFW_HAND_CURSOR,

    /// The horizontal resize arrow shape.
    hresize = c.GLFW_HRESIZE_CURSOR,

    /// The vertical resize arrow shape.
    vresize = c.GLFW_VRESIZE_CURSOR,
};

/// Creates a custom cursor.
///
/// Creates a new custom cursor image that can be set for a window with glfw.Cursor.set. The cursor
/// can be destroyed with glfwCursor.destroy. Any remaining cursors are destroyed by glfw.terminate.
///
/// The pixels are 32-bit, little-endian, non-premultiplied RGBA, i.e. eight bits per channel with
/// the red channel first. They are arranged canonically as packed sequential rows, starting from
/// the top-left corner.
///
/// The cursor hotspot is specified in pixels, relative to the upper-left corner of the cursor
/// image. Like all other coordinate systems in GLFW, the X-axis points to the right and the Y-axis
/// points down.
///
/// @param[in] image The desired cursor image.
/// @param[in] xhot The desired x-coordinate, in pixels, of the cursor hotspot.
/// @param[in] yhot The desired y-coordinate, in pixels, of the cursor hotspot.
/// @return The handle of the created cursor.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
///
/// @pointer_lifetime The specified image data is copied before this function returns.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: cursor_object, glfw.Cursor.destroy, glfw.Cursor.createStandard
pub inline fn create(image: Image, xhot: isize, yhot: isize) Error!Cursor {
    internal_debug.assertInitialized();
    const img = image.toC();
    const cursor = c.glfwCreateCursor(&img, @intCast(c_int, xhot), @intCast(c_int, yhot));
    getError() catch |err| return switch (err) {
        Error.PlatformError => err,
        else => unreachable,
    };
    return Cursor{ .ptr = cursor.? };
}

/// Creates a cursor with a standard shape.
///
/// Returns a cursor with a standard shape (see shapes), that can be set for a window with glfw.Window.setCursor.
///
/// Possible errors include glfw.Error.NotInitialized, glfw.Error.InvalidEnum and glfw.Error.PlatformError.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: cursor_object, glfwCreateCursor
pub inline fn createStandard(shape: Shape) Error!Cursor {
    internal_debug.assertInitialized();
    const cursor = c.glfwCreateStandardCursor(@intCast(c_int, @enumToInt(shape)));
    getError() catch |err| return switch (err) {
        // should be unreachable given that only the values in 'Shape' are available, unless the user explicitly gives us a bad value via casting
        Error.InvalidEnum => unreachable, 
        Error.PlatformError => err,
        else => unreachable,
    };
    return Cursor{ .ptr = cursor.? };
}

/// Destroys a cursor.
///
/// This function destroys a cursor previously created with glfw.Cursor.create. Any remaining
/// cursors will be destroyed by glfw.terminate.
///
/// If the specified cursor is current for any window, that window will be reverted to the default
/// cursor. This does not affect the cursor mode.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
///
/// @reentrancy This function must not be called from a callback.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: cursor_object, glfw.createCursor
pub inline fn destroy(self: Cursor) void {
    internal_debug.assertInitialized();
    c.glfwDestroyCursor(self.ptr);
    getError() catch |err| return switch (err) {
        Error.PlatformError => std.log.debug("{}: was unable to destroy Cursor.\n", .{ err }),
        else => unreachable,
    };
}

test "create" {
    const allocator = testing.allocator;

    const glfw = @import("main.zig");
    try glfw.init(.{});
    defer glfw.terminate();

    const image = try Image.init(allocator, 32, 32, 32 * 32 * 4);
    defer image.deinit(allocator);

    const cursor = glfw.Cursor.create(image, 0, 0) catch |err| {
        std.debug.print("failed to create cursor, custom cursors not supported? error={}\n", .{err});
        return;
    };
    cursor.destroy();
}

test "createStandard" {
    const glfw = @import("main.zig");
    try glfw.init(.{});
    defer glfw.terminate();

    const cursor = glfw.Cursor.createStandard(.ibeam) catch |err| {
        std.debug.print("failed to create cursor, custom cursors not supported? error={}\n", .{err});
        return;
    };
    cursor.destroy();
}
