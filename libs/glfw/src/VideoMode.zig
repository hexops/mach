//! Monitor video modes and related functions
//!
//! see also: glfw.Monitor.getVideoMode

const std = @import("std");
const c = @import("c.zig").c;

const VideoMode = @This();

handle: c.GLFWvidmode,

/// Returns the width of the video mode, in screen coordinates.
pub inline fn getWidth(self: VideoMode) u32 {
    return @as(u32, @intCast(self.handle.width));
}

/// Returns the height of the video mode, in screen coordinates.
pub inline fn getHeight(self: VideoMode) u32 {
    return @as(u32, @intCast(self.handle.height));
}

/// Returns the bit depth of the red channel of the video mode.
pub inline fn getRedBits(self: VideoMode) u32 {
    return @as(u32, @intCast(self.handle.redBits));
}

/// Returns the bit depth of the green channel of the video mode.
pub inline fn getGreenBits(self: VideoMode) u32 {
    return @as(u32, @intCast(self.handle.greenBits));
}

/// Returns the bit depth of the blue channel of the video mode.
pub inline fn getBlueBits(self: VideoMode) u32 {
    return @as(u32, @intCast(self.handle.blueBits));
}

/// Returns the refresh rate of the video mode, in Hz.
pub inline fn getRefreshRate(self: VideoMode) u32 {
    return @as(u32, @intCast(self.handle.refreshRate));
}

test "getters" {
    const x = std.mem.zeroes(VideoMode);
    _ = x.getWidth();
    _ = x.getHeight();
    _ = x.getRedBits();
    _ = x.getGreenBits();
    _ = x.getBlueBits();
    _ = x.getRefreshRate();
}
