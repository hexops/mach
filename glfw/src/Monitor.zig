//! Monitor type and related functions

const std = @import("std");
const mem = std.mem;
const testing = std.testing;
const c = @import("c.zig").c;

const Error = @import("errors.zig").Error;
const getError = @import("errors.zig").getError;
const GammaRamp = @import("GammaRamp.zig");
const VideoMode = @import("VideoMode.zig");

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
pub inline fn getPos(self: Monitor) Error!Pos {
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
pub inline fn getWorkarea(self: Monitor) Error!Workarea {
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
pub inline fn getPhysicalSize(self: Monitor) Error!PhysicalSize {
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
pub inline fn getContentScale(self: Monitor) Error!ContentScale {
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
pub inline fn getName(self: Monitor) Error![*:0]const u8 {
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
pub inline fn setUserPointer(self: Monitor, comptime T: type, ptr: *T) Error!void {
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
/// @thread_safety This function may be called from any thread. Access is not synchronized.
///
/// see also: monitor_userptr, glfw.Monitor.setUserPointer
pub inline fn getUserPointer(self: Monitor, comptime T: type) Error!?*T {
    const ptr = c.glfwGetMonitorUserPointer(self.handle);
    try getError();
    if (ptr == null) return null;
    return @ptrCast(*T, @alignCast(@alignOf(T), ptr.?));
}

/// Returns the available video modes for the specified monitor.
///
/// This function returns an array of all video modes supported by the monitor. The returned slice
/// is sorted in ascending order, first by color bit depth (the sum of all channel depths) and
/// then by resolution area (the product of width and height).
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
///
/// The returned slice memory is owned by the caller.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: monitor_modes, glfw.Monitor.getVideoMode
pub inline fn getVideoModes(self: Monitor, allocator: *mem.Allocator) Error![]VideoMode {
    var count: c_int = 0;
    const modes = c.glfwGetVideoModes(self.handle, &count);
    try getError();

    const slice = try allocator.alloc(VideoMode, @intCast(usize, count));
    var i: usize = 0;
    while (i < count) : (i += 1) {
        slice[i] = VideoMode{ .handle = modes[i] };
    }
    return slice;
}

/// Returns the current mode of the specified monitor.
///
/// This function returns the current video mode of the specified monitor. If you have created a
/// full screen window for that monitor, the return value will depend on whether that window is
/// iconified.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: monitor_modes, glfw.Monitor.getVideoModes
pub inline fn getVideoMode(self: Monitor) Error!VideoMode {
    const mode = c.glfwGetVideoMode(self.handle);
    try getError();
    return VideoMode{ .handle = mode.?.* };
}

/// Generates a gamma ramp and sets it for the specified monitor.
///
/// This function generates an appropriately sized gamma ramp from the specified exponent and then
/// calls glfw.Monitor.setGammaRamp with it. The value must be a finite number greater than zero.
///
/// The software controlled gamma ramp is applied _in addition_ to the hardware gamma correction,
/// which today is usually an approximation of sRGB gamma. This means that setting a perfectly
/// linear ramp, or gamma 1.0, will produce the default (usually sRGB-like) behavior.
///
/// For gamma correct rendering with OpenGL or OpenGL ES, see the glfw.srgb_capable hint.
///
/// Possible errors include glfw.Error.NotInitialized, glfw.Error.InvalidValue and glfw.Error.PlatformError.
///
/// wayland: Gamma handling is a privileged protocol, this function will thus never be implemented
/// and emits glfw.Error.PlatformError.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: monitor_gamma
pub inline fn setGamma(self: Monitor, gamma: f32) Error!void {
    c.glfwSetGamma(self.handle, gamma);
    try getError();
}

/// Returns the current gamma ramp for the specified monitor.
///
/// This function returns the current gamma ramp of the specified monitor.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
///
/// wayland: Gamma handling is a privileged protocol, this function will thus never be implemented
/// and returns glfw.Error.PlatformError.
///
/// The returned gamma ramp is `.owned = true` by GLFW, and is valid until the monitor is
/// disconnected, this function is called again, or `glfw.terminate()` is called.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: monitor_gamma
pub inline fn getGammaRamp(self: Monitor) Error!GammaRamp {
    const ramp = c.glfwGetGammaRamp(self.handle);
    try getError();
    return GammaRamp.fromC(ramp.*);
}

/// Sets the current gamma ramp for the specified monitor.
///
/// This function sets the current gamma ramp for the specified monitor. The original gamma ramp
/// for that monitor is saved by GLFW the first time this function is called and is restored by
/// `glfw.terminate()`.
///
/// The software controlled gamma ramp is applied _in addition_ to the hardware gamma correction,
/// which today is usually an approximation of sRGB gamma. This means that setting a perfectly
/// linear ramp, or gamma 1.0, will produce the default (usually sRGB-like) behavior.
///
/// For gamma correct rendering with OpenGL or OpenGL ES, see the glfw.srgb_capable hint.
///
/// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
///
/// The size of the specified gamma ramp should match the size of the current ramp for that
/// monitor. On win32, the gamma ramp size must be 256.
///
/// wayland: Gamma handling is a privileged protocol, this function will thus never be implemented
/// and emits glfw.Error.PlatformError.
///
/// @pointer_lifetime The specified gamma ramp is copied before this function returns.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: monitor_gamma
pub inline fn setGammaRamp(self: Monitor, ramp: GammaRamp) Error!void {
    c.glfwSetGammaRamp(self.handle, &ramp.toC());
    try getError();
}

/// Returns the currently connected monitors.
///
/// This function returns a slice of all currently connected monitors. The primary monitor is
/// always first. If no monitors were found, this function returns an empty slice.
///
/// The returned slice memory is owned by the caller. The underlying handles are owned by GLFW, and
/// are valid until the monitor configuration changes or `glfw.terminate` is called.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: monitor_monitors, monitor_event, glfw.monitor.getPrimary
pub inline fn getAll(allocator: *mem.Allocator) Error![]Monitor {
    var count: c_int = 0;
    const monitors = c.glfwGetMonitors(&count);
    try getError();

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
pub inline fn getPrimary() Error!?Monitor {
    const handle = c.glfwGetPrimaryMonitor();
    try getError();
    if (handle == null) {
        return null;
    }
    return Monitor{ .handle = handle.? };
}

var callback_fn_ptr: ?usize = null;
var callback_data_ptr: ?usize = undefined;

/// Describes an event relating to a monitor.
pub const Event = enum(c_int) {
    /// The device was connected.
    connected = c.GLFW_CONNECTED,

    /// The device was disconnected.
    disconnected = c.GLFW_DISCONNECTED,
};

/// Sets the monitor configuration callback.
///
/// This function sets the monitor configuration callback, or removes the currently set callback.
/// This is called when a monitor is connected to or disconnected from the system. Example:
///
/// ```
/// fn monitorCallback(monitor: glfw.Monitor, event: glfw.Monitor.Event, data: *MyData) void {
///     // data is the pointer you passed into setCallback.
///     // event is one of .connected or .disconnected
/// }
/// ...
/// glfw.Monitor.setCallback(MyData, &myData, monitorCallback)
/// ```
///
/// `event` may be one of .connected or .disconnected. More events may be added in the future.
///
/// Possible errors include glfw.Error.NotInitialized.
///
/// @thread_safety This function must only be called from the main thread.
///
/// see also: monitor_event
pub inline fn setCallback(comptime Data: type, data: *Data, f: ?*const fn (monitor: Monitor, event: Event, data: *Data) void) Error!void {
    if (f) |new_callback| {
        callback_fn_ptr = @ptrToInt(new_callback);
        callback_data_ptr = @ptrToInt(data);
        const NewCallback = @TypeOf(new_callback);
        _ = c.glfwSetMonitorCallback((struct {
            fn callbackC(monitor: ?*c.GLFWmonitor, event: c_int) callconv(.C) void {
                const callback = @intToPtr(NewCallback, callback_fn_ptr.?);
                callback.*(
                    Monitor{ .handle = monitor.? },
                    @intToEnum(Event, event),
                    @intToPtr(*Data, callback_data_ptr.?),
                );
            }
        }).callbackC);
    } else {
        _ = c.glfwSetMonitorCallback(null);
        callback_fn_ptr = null;
        callback_data_ptr = null;
    }
    try getError();
}

test "getAll" {
    const glfw = @import("main.zig");
    try glfw.init(.{});
    defer glfw.terminate();

    const allocator = testing.allocator;
    const monitors = try getAll(allocator);
    defer allocator.free(monitors);
}

test "getPrimary" {
    const glfw = @import("main.zig");
    try glfw.init(.{});
    defer glfw.terminate();

    _ = try getPrimary();
}

test "getPos" {
    const glfw = @import("main.zig");
    try glfw.init(.{});
    defer glfw.terminate();

    const monitor = try getPrimary();
    if (monitor) |m| {
        _ = try m.getPos();
    }
}

test "getWorkarea" {
    const glfw = @import("main.zig");
    try glfw.init(.{});
    defer glfw.terminate();

    const monitor = try getPrimary();
    if (monitor) |m| {
        _ = try m.getWorkarea();
    }
}

test "getPhysicalSize" {
    const glfw = @import("main.zig");
    try glfw.init(.{});
    defer glfw.terminate();

    const monitor = try getPrimary();
    if (monitor) |m| {
        _ = try m.getPhysicalSize();
    }
}

test "getContentScale" {
    const glfw = @import("main.zig");
    try glfw.init(.{});
    defer glfw.terminate();

    const monitor = try getPrimary();
    if (monitor) |m| {
        _ = try m.getContentScale();
    }
}

test "getName" {
    const glfw = @import("main.zig");
    try glfw.init(.{});
    defer glfw.terminate();

    const monitor = try getPrimary();
    if (monitor) |m| {
        _ = try m.getName();
    }
}

test "userPointer" {
    const glfw = @import("main.zig");
    try glfw.init(.{});
    defer glfw.terminate();

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

test "setCallback" {
    const glfw = @import("main.zig");
    try glfw.init(.{});
    defer glfw.terminate();

    var custom_data: u32 = 5;
    try setCallback(u32, &custom_data, &(struct {
        fn callback(monitor: Monitor, event: Event, data: *u32) void {
            _ = monitor;
            _ = event;
            _ = data;
        }
    }).callback);
}

test "getVideoModes" {
    const glfw = @import("main.zig");
    try glfw.init(.{});
    defer glfw.terminate();

    const monitor = try getPrimary();
    if (monitor) |m| {
        const allocator = testing.allocator;
        const modes = try m.getVideoModes(allocator);
        defer allocator.free(modes);
    }
}

test "getVideoMode" {
    const glfw = @import("main.zig");
    try glfw.init(.{});
    defer glfw.terminate();

    const monitor = try getPrimary();
    if (monitor) |m| {
        _ = try m.getVideoMode();
    }
}

test "set_getGammaRamp" {
    const allocator = testing.allocator;
    const glfw = @import("main.zig");
    try glfw.init(.{});
    defer glfw.terminate();

    const monitor = try getPrimary();
    if (monitor) |m| {
        const ramp = m.getGammaRamp() catch |err| {
            std.debug.print("can't get window position, wayland maybe? error={}\n", .{err});
            return;
        };

        // Set it to the exact same value; if we do otherwise an our tests fail it wouldn't call
        // terminate and our made-up gamma ramp would get stuck.
        try m.setGammaRamp(ramp);

        // technically not needed here / noop because GLFW owns this gamma ramp.
        defer ramp.deinit(allocator);
    }
}
