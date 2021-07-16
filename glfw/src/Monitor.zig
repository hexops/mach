//! Monitor type and related functions

const std = @import("std");
const mem = std.mem;
const testing = std.testing;
const c = @cImport(@cInclude("GLFW/glfw3.h"));

pub const Error = @import("errors.zig").Error;
const getError = @import("errors.zig").getError;

const Monitor = @This();

handle: *c.GLFWmonitor,

/// A monitor position, in screen coordinates, of the upper left corner of the monitor on the
/// virtual screen.
const Pos = struct {
    /// The x coordinate.
    x: isize,
    /// The y coordinate.
    y: isize,
};

/// Returns the position of the monitor's viewport on the virtual screen.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: monitor_properties
pub fn getPos(self: Monitor) !Pos {
    var xpos: c_int = 0;
    var ypos: c_int = 0;
    c.glfwGetMonitorPos(self.handle, &xpos, &ypos);
    try getError();
    return Pos{ .x = xpos, .y = ypos };
}

/// Returns the currently connected monitors.
///
/// This function returns a slice of all currently connected monitors. The primary monitor is
/// always first. If no monitors were found, this function returns an empty slice.
///
/// The returned slice memory is owned by the caller. The underlying handles are owned by GLFW, and
/// are valid until the monitor configuration changes or the `glfw.terminate` is called.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: monitor_monitors, monitor_event, glfw.monitor.getPrimary
pub fn getAll(allocator: *mem.Allocator) ![]Monitor {
    var count: c_int = 0;
    const monitors = c.glfwGetMonitors(&count);

    const slice = try allocator.alloc(Monitor, @intCast(usize, count));
    var i: usize = 0;
    while (i < count) : (i += 1) {
        slice[i] = Monitor{ .handle = monitors[i].? };
    }
    return slice;
}

/// Returns the primary monitor.
///
/// This function returns the primary monitor. This is usually the monitor where elements like
/// the task bar or global menu bar are located.
///
/// Possible errors include glfw.Error.NotInitialized.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: monitor_monitors, glfw.monitors.getAll
pub fn getPrimary() !?Monitor {
    const handle = c.glfwGetPrimaryMonitor();
    if (handle == null) {
        return null;
    }
    try getError();
    return Monitor{ .handle = handle.? };
}

test "getAll" {
    const allocator = testing.allocator;
    const monitors = try getAll(allocator);
    defer allocator.free(monitors);
}

test "getPrimary" {
    _ = try getPrimary();
}

test "getPos" {
    const monitor = try getPrimary();
    if (monitor) |m| {
        _ = try m.getPos();
    }
}
