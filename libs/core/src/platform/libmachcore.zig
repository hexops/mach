const std = @import("std");
const gpu = @import("gpu");
const ecs = @import("ecs");
const glfw = @import("glfw");
const Core = @import("../Core.zig");
const native = @import("native.zig");

pub const App = @This();

pub const GPUInterface = gpu.dawn.Interface;

const _ = gpu.Export(GPUInterface);

// Current Limitations:
// 1. Currently, ecs seems to be using some weird compile-time type trickery, so I'm not exactly sure how
// `engine` should be integrated into the C API
// 2. Core might need to expose more state so more API functions can be exposed (for example, the WebGPU API)
// 3. Be very careful about arguments, types, memory, etc - any mismatch will result in undefined behavior

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

// Returns a pointer to a newly allocated Core
// Will return a null pointer if an error occurred while initializing Core
pub export fn mach_core_init() ?*native.Core {
    gpu.Impl.init();
    // TODO(libmach): eliminate this allocation
    var core = allocator.create(native.Core) catch {
        return @intToPtr(?*native.Core, 0);
    };
    // TODO(libmach): allow passing init options
    core.init(allocator, .{}) catch {
        // TODO(libmach): better error handling
        return @intToPtr(?*native.Core, 0);
    };
    return core;
}

pub export fn mach_core_deinit(core: *native.Core) void {
    native.Core.deinit(core);
}

// pub export fn mach_core_poll_events(core: *native.Core) Core.Event {
//     return native.Core.pollEvents(core);
// }

const MachStatus = enum(c_int) {
    Success = 0x00000000,
    Error = 0x00000001,
};
