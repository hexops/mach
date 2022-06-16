const std = @import("std");
const Allocator = std.mem.Allocator;
const builtin = @import("builtin");
const glfw = @import("glfw");
const gpu = @import("gpu");
const platform = @import("platform.zig");
const structs = @import("structs.zig");
const enums = @import("enums.zig");
const Timer = @import("Timer.zig");

const Engine = @This();

allocator: Allocator,

options: structs.Options,

/// The amount of time (in seconds) that has passed since the last frame was rendered.
///
/// For example, if you are animating a cube which should rotate 360 degrees every second,
/// instead of writing (360.0 / 60.0) and assuming the frame rate is 60hz, write
/// (360.0 * engine.delta_time)
delta_time: f32 = 0,
delta_time_ns: u64 = 0,
timer: Timer,

device: gpu.Device,
backend_type: gpu.Adapter.BackendType,
swap_chain: ?gpu.SwapChain,
swap_chain_format: gpu.Texture.Format,

surface: ?gpu.Surface,
current_desc: gpu.SwapChain.Descriptor,
target_desc: gpu.SwapChain.Descriptor,

internal: platform.Type,

pub fn init(allocator: std.mem.Allocator) !Engine {
    var engine: Engine = undefined;
    engine.allocator = allocator;
    engine.options = structs.Options{};
    engine.timer = try Timer.start();

    engine.internal = try platform.Type.init(allocator, &engine);

    return engine;
}

/// Set runtime options for application, like title, window size etc.
///
/// See mach.Options for details
pub fn setOptions(engine: *Engine, options: structs.Options) !void {
    try engine.internal.setOptions(options);
    engine.options = options;
}

// Signals mach to stop the update loop.
pub fn setShouldClose(engine: *Engine, value: bool) void {
    engine.internal.setShouldClose(value);
}

// Sets seconds to wait for an event with timeout before calling update()
// again.
//
// timeout is in seconds (<= 0.0 disables waiting)
// - pass std.math.floatMax(f64) to wait with no timeout
//
// update() can be called earlier than timeout if an event happens (key press,
// mouse motion, etc.)
//
// update() can be called a bit later than timeout due to timer precision and
// process scheduling.
pub fn setWaitEvent(engine: *Engine, timeout: f64) void {
    engine.internal.setWaitEvent(timeout);
}

// Returns the framebuffer size, in subpixel units.
//
// e.g. returns 1280x960 on macOS for a window that is 640x480
pub fn getFramebufferSize(engine: *Engine) structs.Size {
    return engine.internal.getFramebufferSize();
}

// Returns the widow size, in pixel units.
//
// e.g. returns 1280x960 on macOS for a window that is 640x480
pub fn getWindowSize(engine: *Engine) structs.Size {
    return engine.internal.getWindowSize();
}

pub fn setMouseCursor(engine: *Engine, cursor: enums.MouseCursor) !void {
    try engine.internal.setMouseCursor(cursor);
}

pub fn hasEvent(engine: *Engine) bool {
    return engine.internal.hasEvent();
}

pub fn pollEvent(engine: *Engine) ?structs.Event {
    return engine.internal.pollEvent();
}
