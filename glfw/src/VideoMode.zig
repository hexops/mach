//! Monitor video modes and related functions
//!
//! see also: glfw.Monitor.getVideoMode

const std = @import("std");
const c = @import("c.zig").c;

handle: c.GLFWvidmode,

/// Returns the width of the video mode, in screen coordinates.
pub inline fn getWidth(self: VideoMode) usize {
    return @intCast(usize, self.handle.width);
}

/// Returns the height of the video mode, in screen coordinates.
pub inline fn getHeight(self: VideoMode) usize {
    return @intCast(usize, self.handle.height);
}

/// Returns the bit depth of the red channel of the video mode.
pub inline fn getRedBits(self: VideoMode) usize {
    return @intCast(usize, self.handle.redBits);
}

/// Returns the bit depth of the green channel of the video mode.
pub inline fn getGreenBits(self: VideoMode) usize {
    return @intCast(usize, self.handle.greenBits);
}

/// Returns the bit depth of the blue channel of the video mode.
pub inline fn getBlueBits(self: VideoMode) usize {
    return @intCast(usize, self.handle.blueBits);
}

/// Returns the refresh rate of the video mode, in Hz.
pub inline fn getRefreshRate(self: VideoMode) usize {
    return @intCast(usize, self.handle.refreshRate);
}
