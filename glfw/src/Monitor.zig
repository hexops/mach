//! Monitor type and related functions

const std = @import("std");
const mem = std.mem;
const testing = std.testing;
const c = @cImport(@cInclude("GLFW/glfw3.h"));

pub const Error = @import("errors.zig").Error;
const getError = @import("errors.zig").getError;

const Monitor = @This();

handle: *c.GLFWmonitor,

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

    const slice = allocator.alloc(Monitor, count);
    var i = 0;
    while (i < count) : (i += 1) {
        slice[i] = Monitor{ .handle = monitors[i] };
    }
    return slice;
}

test "getAll" {
    const allocator = testing.allocator;
    const monitors = try getAll(allocator);
    defer allocator.free(monitors);
}
