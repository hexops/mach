//! Gamma ramp for monitors and related functions.
//!
//! It may be .owned (e.g. in the case of a gamma ramp initialized by you for passing into
//! glfw.Monitor.setGammaRamp) or not .owned (e.g. in the case of one gotten via
//! glfw.Monitor.getGammaRamp.) If it is .owned, deinit should be called to free the memory. It is
//! safe to call deinit even if not .owned.
//!
//! see also: monitor_gamma, glfw.Monitor.getGammaRamp

const std = @import("std");
const testing = std.testing;
const mem = std.mem;
const c = @import("c.zig").c;

const GammaRamp = @This();

red: []u16,
green: []u16,
blue: []u16,
owned: ?[]u16,

/// Initializes a new owned gamma ramp with the given array size and undefined values.
///
/// see also: glfw.Monitor.getGammaRamp
pub inline fn init(allocator: mem.Allocator, size: usize) !GammaRamp {
    const buf = try allocator.alloc(u16, size * 3);
    return GammaRamp{
        .red = buf[size * 0 .. (size * 0) + size],
        .green = buf[size * 1 .. (size * 1) + size],
        .blue = buf[size * 2 .. (size * 2) + size],
        .owned = buf,
    };
}

/// Turns a GLFW / C gamma ramp into the nicer Zig type, and sets `.owned = false`.
///
/// The returned memory is valid for as long as the GLFW C memory is valid.
pub inline fn fromC(native: c.GLFWgammaramp) GammaRamp {
    return GammaRamp{
        .red = native.red[0..native.size],
        .green = native.green[0..native.size],
        .blue = native.blue[0..native.size],
        .owned = null,
    };
}

/// Turns the nicer Zig type into a GLFW / C gamma ramp, for passing into GLFW C functions.
///
/// The returned memory is valid for as long as the Zig memory is valid.
pub inline fn toC(self: GammaRamp) c.GLFWgammaramp {
    std.debug.assert(self.red.len == self.green.len);
    std.debug.assert(self.red.len == self.blue.len);
    return c.GLFWgammaramp{
        .red = &self.red[0],
        .green = &self.green[0],
        .blue = &self.blue[0],
        .size = @as(c_uint, @intCast(self.red.len)),
    };
}

/// Deinitializes the memory using the allocator iff `.owned = true`.
pub inline fn deinit(self: GammaRamp, allocator: mem.Allocator) void {
    if (self.owned) |buf| allocator.free(buf);
}

test "conversion" {
    const allocator = testing.allocator;

    const ramp = try GammaRamp.init(allocator, 256);
    defer ramp.deinit(allocator);

    const glfw = ramp.toC();
    _ = GammaRamp.fromC(glfw);
}
