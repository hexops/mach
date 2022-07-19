const std = @import("std");
const Core = @import("../Core.zig");
const gpu = @import("gpu");
const ecs = @import("ecs");
const glfw = @import("glfw");

pub const App = @This();

// Dummy init, deinit, and update functions
pub fn init(_: *App, _: *Core) !void { }

pub fn deinit(_: *App, _: *Core) void { }

pub fn update(_: *App, _: *Core) !void { }

// Current Limitations:
// 1. Currently, ecs seems to be using some weird compile-time type trickery, so I'm not exactly sure how
// `engine` should be integrated into the C API
// 2. Core might need to expose more state so more API functions can be exposed (for example, the WebGPU API)
// 3. Be very careful about arguments, types, memory, etc - any mismatch will result in undefined behavior

pub export fn mach_set_should_close(core: *Core) void {
    core.setShouldClose(true);
}

pub export fn mach_delta_time(core: *Core) f32 {
    return core.delta_time;
}

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

// Initializes and returns Mach's core structure
// Uses an optional type so it is valid to return 0 (on an error)
// TODO: come up with a better error reporting system
pub export fn mach_init_core() ?*Core {
    const core: *Core = allocator.create(Core) catch {
        return @intToPtr(?*Core, 0); // on error, return null pointer
    };
    core.* = Core.init(allocator) catch {
        return @intToPtr(?*Core, 0); // on error, return null pointer
    };

    // // Glfw specific: initialize the user pointer used in callbacks
    core.*.internal.initCallback();

    return core;
}

// Deinitializes mach core structure
pub export fn mach_deinit(core: *Core) void {
    core.internal.deinit();
    allocator.destroy(core);
}

pub export fn mach_window_should_close(core: *Core) bool {
    return core.internal.window.shouldClose();
}

pub const CoreCallback = fn (*Core, u32, u32) callconv(.C) void;

// Adapted from native.zig
pub export fn mach_update(core: *Core, resize_fn: ?CoreCallback) i32 {
    if (core.internal.wait_event_timeout > 0.0) {
        if (core.internal.wait_event_timeout == std.math.inf(f64)) {
            // Wait for an event
            glfw.waitEvents() catch {
                return 0;
            };
        } else {
            // Wait for an event with a timeout
            glfw.waitEventsTimeout(core.internal.wait_event_timeout) catch {
                return 0;
            };
        }
    } else {
        // Don't wait for events
        glfw.pollEvents() catch {
            return 0;
        };
    }

    core.delta_time_ns = core.timer.lapPrecise();
    core.delta_time = @intToFloat(f32, core.delta_time_ns) / @intToFloat(f32, std.time.ns_per_s);

    var framebuffer_size = core.getFramebufferSize();
    core.target_desc.width = framebuffer_size.width;
    core.target_desc.height = framebuffer_size.height;

    if (core.swap_chain == null or !core.current_desc.equal(&core.target_desc)) {
        const use_legacy_api = core.surface == null;
        if (!use_legacy_api) {
            core.swap_chain = core.device.nativeCreateSwapChain(core.surface, &core.target_desc);
        } else core.swap_chain.?.configure(
            core.swap_chain_format,
            .{ .render_attachment = true },
            core.target_desc.width,
            core.target_desc.height,
        );

        if (resize_fn != null) {
            resize_fn.?(core, core.target_desc.width, core.target_desc.height);
        }
        core.current_desc = core.target_desc;
    }
    return 1;
}
