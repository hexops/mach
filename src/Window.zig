const gpu = @import("gpu");
const platform = @import("platform.zig");
const structs = @import("structs.zig");

const Window = @This();

options: structs.WindowOptions,

swap_chain: ?*gpu.SwapChain,
swap_chain_format: gpu.Texture.Format,

surface: ?*gpu.Surface,
current_desc: gpu.SwapChain.Descriptor,
target_desc: gpu.SwapChain.Descriptor,

internal: platform.BackingWindowType,

/// Set runtime options for the window, like title, window size etc.
///
/// See mach.WindowOptions for details
pub fn setOptions(window: *Window, options: structs.WindowOptions) !void {
    try window.internal.setOptions(options);
    window.options = options;
}

// Signals mach to close the window.
pub fn close(window: *Window) void {
    window.internal.close();
}

// Returns the framebuffer size, in subpixel units.
//
// e.g. returns 1280x960 on macOS for a window that is 640x480
pub fn getFramebufferSize(window: *Window) structs.Size {
    return window.internal.getFramebufferSize();
}

// Returns the window size, in pixel units.
//
// e.g. returns 1280x960 on macOS for a window that is 640x480
pub fn getSize(window: *Window) structs.Size {
    return window.internal.getSize();
}
