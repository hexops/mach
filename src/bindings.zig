const std = @import("std");
const gpu = @import("gpu");
const Core = @import("Core.zig");
const libmach = @import("platform/libmach.zig");
const native = @import("platform/native.zig");

// Current Limitations:
// 1. Currently, ecs seems to be using some weird compile-time type trickery, so I'm not exactly sure how
// `engine` should be integrated into the C API
// 2. Core might need to expose more state so more API functions can be exposed (for example, the WebGPU API)
// 3. Be very careful about arguments, types, memory, etc - any mismatch will result in undefined behavior

pub const App = libmach;

pub export fn mach_core_set_init(core_init: libmach.CoreCallback) void {
    std.debug.print("mach core set init\n", .{});
    libmach.core_callbacks.core_init = core_init;
}

pub export fn mach_core_set_deinit(core_deinit: libmach.CoreCallback) void {
    std.debug.print("mach core set deinit\n", .{});
    libmach.core_callbacks.core_deinit = core_deinit;
}

pub export fn mach_core_set_update(core_update: libmach.CoreCallback) void {
    std.debug.print("mach core set update\n", .{});
    libmach.core_callbacks.core_update = core_update;
}

pub export fn mach_run() void {
    if (libmach.core_callbacks.core_init == null) {
        std.debug.print("Did not provide a core_init callback\n", .{});
        return;
    }
    if (libmach.core_callbacks.core_update == null) {
        std.debug.print("Did not provide a core_update callback\n", .{});
        return;
    }
    if (libmach.core_callbacks.core_deinit == null) {
        std.debug.print("Did not provide a core_deinit callback\n", .{});
        return;
    }
    native.main() catch unreachable;
}

pub export fn core_set_should_close(core: *Core) void {
    core.*.setShouldClose(true);
}

pub export fn core_delta_time(core: *Core) f32 {
    return core.*.delta_time;
}
