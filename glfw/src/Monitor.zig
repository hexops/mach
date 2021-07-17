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
    x: usize,
    /// The y coordinate.
    y: usize,
};

/// Returns the position of the monitor's viewport on the virtual screen.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: monitor_properties
pub fn getPos(self: Monitor) Error!Pos {
    var xpos: c_int = 0;
    var ypos: c_int = 0;
    c.glfwGetMonitorPos(self.handle, &xpos, &ypos);
    try getError();
    return Pos{ .x = @intCast(usize, xpos), .y = @intCast(usize, ypos) };
}

/// The monitor workarea, in screen coordinates.
///
/// This is the position of the upper-left corner of the work area of the monitor, along with the
/// work area size. The work area is defined as the area of the monitor not occluded by the
/// operating system task bar where present. If no task bar exists then the work area is the
/// monitor resolution in screen coordinates.
const Workarea = struct {
    x: usize,
    y: usize,
    width: usize,
    height: usize,
};

/// Retrieves the work area of the monitor.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: monitor_workarea
pub fn getWorkarea(self: Monitor) Error!Workarea {
    var xpos: c_int = 0;
    var ypos: c_int = 0;
    var width: c_int = 0;
    var height: c_int = 0;
    c.glfwGetMonitorWorkarea(self.handle, &xpos, &ypos, &width, &height);
    try getError();
    return Workarea{ .x = @intCast(usize, xpos), .y = @intCast(usize, ypos), .width = @intCast(usize, width), .height = @intCast(usize, height) };
}

/// The physical size, in millimetres, of the display area of a monitor.
const PhysicalSize = struct {
    width_mm: usize,
    height_mm: usize,
};

/// Returns the physical size of the monitor.
///
/// Some systems do not provide accurate monitor size information, either because the monitor
/// [EDID](https://en.wikipedia.org/wiki/Extended_display_identification_data)
/// data is incorrect or because the driver does not report it accurately.
///
/// Possible errors include glfw.Error.NotInitialized.
///
/// win32: calculates the returned physical size from the current resolution and system DPI
/// instead of querying the monitor EDID data.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: monitor_properties
pub fn getPhysicalSize(self: Monitor) Error!PhysicalSize {
    var width_mm: c_int = 0;
    var height_mm: c_int = 0;
    c.glfwGetMonitorPhysicalSize(self.handle, &width_mm, &height_mm);
    try getError();
    return PhysicalSize{ .width_mm = @intCast(usize, width_mm), .height_mm = @intCast(usize, height_mm) };
}

/// The content scale for a monitor.
///
/// This is the ratio between the current DPI and the platform's default DPI. This is especially
/// important for text and any UI elements. If the pixel dimensions of your UI scaled by this look
/// appropriate on your machine then it should appear at a reasonable size on other machines
/// regardless of their DPI and scaling settings. This relies on the system DPI and scaling
/// settings being somewhat correct.
///
/// The content scale may depend on both the monitor resolution and pixel density and on users
/// settings. It may be very different from the raw DPI calculated from the physical size and
/// current resolution.
const ContentScale = struct {
    x_scale: f32,
    y_scale: f32,
};

/// Returns the content scale for the monitor.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: monitor_scale, glfw.Window.getContentScale
pub fn getContentScale(self: Monitor) Error!ContentScale {
    var x_scale: f32 = 0;
    var y_scale: f32 = 0;
    c.glfwGetMonitorContentScale(self.handle, &x_scale, &y_scale);
    try getError();
    return ContentScale{ .x_scale = @floatCast(f32, x_scale), .y_scale = @floatCast(f32, y_scale) };
}

/// Returns the name of the specified monitor.
///
/// This function returns a human-readable name, encoded as UTF-8, of the specified monitor. The
/// name typically reflects the make and model of the monitor and is not guaranteed to be unique
/// among the connected monitors.
///
/// Possible errors include glfw.Error.NotInitialized.
///
/// @pointer_lifetime The returned string is allocated and freed by GLFW. You should not free it
/// yourself. It is valid until the specified monitor is disconnected or the library is terminated.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: monitor_properties
pub fn getName(self: Monitor) Error![*c]const u8 {
    const name = c.glfwGetMonitorName(self.handle);
    try getError();
    return name;
}

/// Sets the user pointer of the specified monitor.
///
/// This function sets the user-defined pointer of the specified monitor. The current value is
/// retained until the monitor is disconnected.
///
/// This function may be called from the monitor callback, even for a monitor that is being
/// disconnected.
///
/// Possible errors include glfw.Error.NotInitialized.
///
/// @thread_safety This function may be called from any thread. Access is not synchronized.
///
/// see also: monitor_userptr, glfw.Monitor.getUserPointer
pub fn setUserPointer(self: Monitor, comptime T: type, ptr: *T) Error!void {
    c.glfwSetMonitorUserPointer(self.handle, ptr);
    try getError();
}

/// Returns the user pointer of the specified monitor.
///
/// This function returns the current value of the user-defined pointer of the specified monitor.
///
/// This function may be called from the monitor callback, even for a monitor that is being
/// disconnected.
///
/// Possible errors include glfw.Error.NotInitialized.
///
/// @thread_safety This function may be called from any thread.  Access is not
/// synchronized.
///
/// see also: monitor_userptr, glfw.Monitor.setUserPointer
pub fn getUserPointer(self: Monitor, comptime T: type) Error!?*T {
    const ptr = c.glfwGetMonitorUserPointer(self.handle);
    try getError();
    if (ptr == null) return null;
    return @ptrCast(*T, @alignCast(@alignOf(*T), ptr.?));
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

test "getWorkarea" {
    const monitor = try getPrimary();
    if (monitor) |m| {
        _ = try m.getWorkarea();
    }
}

test "getPhysicalSize" {
    const monitor = try getPrimary();
    if (monitor) |m| {
        _ = try m.getPhysicalSize();
    }
}

test "getContentScale" {
    const monitor = try getPrimary();
    if (monitor) |m| {
        _ = try m.getContentScale();
    }
}

test "getName" {
    const monitor = try getPrimary();
    if (monitor) |m| {
        _ = try m.getName();
    }
}

test "userPointer" {
    const monitor = try getPrimary();
    if (monitor) |m| {
        var p = try m.getUserPointer(u32);
        try testing.expect(p == null);
        var x: u32 = 5;
        try m.setUserPointer(u32, &x);
        p = try m.getUserPointer(u32);
        try testing.expectEqual(p.?.*, 5);
    }
}
