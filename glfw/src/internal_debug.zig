const std = @import("std");
const zig_builtin = @import("builtin");

// TODO: Consider if this idea could also be applied to prevent 'PlatformError'

const debug_mode = (zig_builtin.mode == .Debug);
var glfw_initialized = if (debug_mode) false else @as(void, {});
pub inline fn toggleInitialized() void {
    if (debug_mode) glfw_initialized = !glfw_initialized;
}
pub inline fn assertInitialized() void {
    if (debug_mode) std.debug.assert(glfw_initialized);
}
