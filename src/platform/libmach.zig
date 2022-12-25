const std = @import("std");
const Core = @import("../Core.zig");
const gpu = @import("gpu");
const ecs = @import("ecs");
const glfw = @import("glfw");
const native = @import("native.zig");

pub const App = @This();

pub const GPUInterface = gpu.dawn.Interface;

const _ = gpu.Export(GPUInterface);

// Dummy init, deinit, and update functions
pub fn init(_: *App, _: *Core) !void {}

pub fn deinit(_: *App, _: *Core) void {}

pub fn update(_: *App, _: *Core) !void {}

// Current Limitations:
// 1. Currently, ecs seems to be using some weird compile-time type trickery, so I'm not exactly sure how
// `engine` should be integrated into the C API
// 2. Core might need to expose more state so more API functions can be exposed (for example, the WebGPU API)
// 3. Be very careful about arguments, types, memory, etc - any mismatch will result in undefined behavior

pub export fn mach_core_close(core: *Core) void {
    core.close();
}

pub export fn mach_core_delta_time(core: *Core) f32 {
    return core.delta_time;
}

pub export fn mach_core_window_should_close(core: *Core) bool {
    return core.internal.window.shouldClose();
}

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

// Returns a pointer to a newly allocated Core
// Will return a null pointer if an error occurred while initializing Core
pub export fn mach_core_init() ?*Core {
    gpu.Impl.init();
    const core = native.coreInit(allocator) catch {
        return @intToPtr(?*Core, 0);
    };
    return core;
}

pub export fn mach_core_deinit(core: *Core) void {
    native.coreDeinit(core, allocator);
}

pub export fn mach_core_update(core: *Core, resize: ?native.CoreResizeCallback) MachStatus {
    native.coreUpdate(core, resize) catch {
        return MachStatus.Error;
    };
    return MachStatus.Success;
}

const MachStatus = enum(c_int) {
    Success = 0x00000000,
    Error = 0x00000001,
};
