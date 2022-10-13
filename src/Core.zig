const std = @import("std");
const Allocator = std.mem.Allocator;
const builtin = @import("builtin");
const glfw = @import("glfw");
const gpu = @import("gpu");
const platform = @import("platform.zig");
const structs = @import("structs.zig");
const enums = @import("enums.zig");
const Timer = @import("Timer.zig");

const Core = @This();

allocator: Allocator,

options: structs.Options,

/// The amount of time (in seconds) that has passed since the last frame was rendered.
///
/// For example, if you are animating a cube which should rotate 360 degrees every second,
/// instead of writing (360.0 / 60.0) and assuming the frame rate is 60hz, write
/// (360.0 * core.delta_time)
delta_time: f32 = 0,
delta_time_ns: u64 = 0,
timer: Timer,

device: *gpu.Device,
backend_type: gpu.BackendType,
swap_chain: ?*gpu.SwapChain,
swap_chain_format: gpu.Texture.Format,

surface: ?*gpu.Surface,
current_desc: gpu.SwapChain.Descriptor,
target_desc: gpu.SwapChain.Descriptor,

internal: platform.Type,

pub fn init(allocator: std.mem.Allocator, core: *Core) !void {
    core.allocator = allocator;
    core.options = structs.Options{};
    core.timer = try Timer.start();
    core.internal = try platform.Type.init(allocator, core);
}

/// Set runtime options for application, like title, window size etc.
///
/// See mach.Options for details
pub fn setOptions(core: *Core, options: structs.Options) !void {
    try core.internal.setOptions(options);
    core.options = options;
}

// Signals mach to stop the update loop.
pub fn close(core: *Core) void {
    core.internal.close();
}

// Sets seconds to wait for an event with timeout before calling update()
// again.
//
// timeout is in seconds (<= 0.0 disables waiting)
// - pass std.math.inf(f64) to wait with no timeout
//
// update() can be called earlier than timeout if an event happens (key press,
// mouse motion, etc.)
//
// update() can be called a bit later than timeout due to timer precision and
// process scheduling.
pub fn setWaitEvent(core: *Core, timeout: f64) void {
    core.internal.setWaitEvent(timeout);
}

// Returns the framebuffer size, in subpixel units.
//
// e.g. returns 1280x960 on macOS for a window that is 640x480
pub fn getFramebufferSize(core: *Core) structs.Size {
    return core.internal.getFramebufferSize();
}

// Returns the window size, in pixel units.
//
// e.g. returns 1280x960 on macOS for a window that is 640x480
pub fn getWindowSize(core: *Core) structs.Size {
    return core.internal.getWindowSize();
}

pub fn setMouseCursor(core: *Core, cursor: enums.MouseCursor) !void {
    try core.internal.setMouseCursor(cursor);
}

pub fn setCursorMode(core: *Core, mode: enums.CursorMode) !void {
    try core.internal.setCursorMode(mode);
}

pub fn hasEvent(core: *Core) bool {
    return core.internal.hasEvent();
}

pub fn pollEvent(core: *Core) ?structs.Event {
    return core.internal.pollEvent();
}
