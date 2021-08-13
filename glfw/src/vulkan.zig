const std = @import("std");

const c = @import("c.zig").c;

pub const Window = @import("Window.zig");
const Error = @import("errors.zig").Error;
const getError = @import("errors.zig").getError;

pub const VkInstance = opaque {};
pub const VkAllocationCallbacks = opaque {};
pub const VkSurfaceKHR = opaque {};


pub inline fn createWindowSurface(instance: VkInstance, window: Window, allocator: *?VkAllocationCallbacks, surface: *VkSurfaceKHR) Error!void {
    c.glfwCreateWindowSurface(instance, window.handle, allocator, surface);
    try getError();
}

pub inline fn getRequiredInstanceExtensions() Error![][*c]const u8 {
    var glfw_extensions_count: u32 = 0;
    const glfw_extensions_raw = c.glfwGetRequiredInstanceExtensions(&glfw_extensions_count);
    try getError();
    return glfw_extensions_raw[0..glfw_extensions_count];
}

pub inline fn getInstanceProcAddress(instance: anytype, procname: [*c]const u8) c.GLFWvkproc {
    const proc = c.glfwGetInstanceProcAddress(instance, procname);
    // This can fail, but in order to keep function signature the same as glfwGetInstanceProcAddress we emit them ...
    getError() catch {}; 
    return proc;
}
