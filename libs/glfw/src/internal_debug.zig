const std = @import("std");
const builtin = @import("builtin");

const is_debug = builtin.mode == .Debug;
var glfw_initialized = if (is_debug) false else @as(void, {});
pub inline fn toggleInitialized() void {
    if (is_debug) glfw_initialized = !glfw_initialized;
}
pub inline fn assertInitialized() void {
    if (is_debug) std.debug.assert(glfw_initialized);
}
pub inline fn assumeInitialized() void {
    glfw_initialized = true;
}
