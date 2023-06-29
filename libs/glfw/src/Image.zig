//! Image data
//!
//!
//! This describes a single 2D image. See the documentation for each related function what the
//! expected pixel format is.
//!
//! see also: cursor_custom, window_icon
//!
//! It may be .owned (e.g. in the case of an image initialized by you for passing into glfw) or not
//! .owned (e.g. in the case of one gotten via glfw) If it is .owned, deinit should be called to
//! free the memory. It is safe to call deinit even if not .owned.

const std = @import("std");
const testing = std.testing;
const mem = std.mem;
const c = @import("c.zig").c;

const Image = @This();

/// The width of this image, in pixels.
width: u32,

/// The height of this image, in pixels.
height: u32,

/// The pixel data of this image, arranged left-to-right, top-to-bottom.
pixels: []u8,

/// Whether or not the pixels data is owned by you (true) or GLFW (false).
owned: bool,

/// Initializes a new owned image with the given size and pixel_data_len of undefined .pixel values.
pub inline fn init(allocator: mem.Allocator, width: u32, height: u32, pixel_data_len: usize) !Image {
    const buf = try allocator.alloc(u8, pixel_data_len);
    return Image{
        .width = width,
        .height = height,
        .pixels = buf,
        .owned = true,
    };
}

/// Turns a GLFW / C image into the nicer Zig type, and sets `.owned = false`.
///
/// The length of pixel data must be supplied, as GLFW's image type does not itself describe the
/// number of bytes required per pixel / the length of the pixel data array.
///
/// The returned memory is valid for as long as the GLFW C memory is valid.
pub inline fn fromC(native: c.GLFWimage, pixel_data_len: usize) Image {
    return Image{
        .width = @as(u32, @intCast(native.width)),
        .height = @as(u32, @intCast(native.height)),
        .pixels = native.pixels[0..pixel_data_len],
        .owned = false,
    };
}

/// Turns the nicer Zig type into a GLFW / C image, for passing into GLFW C functions.
///
/// The returned memory is valid for as long as the Zig memory is valid.
pub inline fn toC(self: Image) c.GLFWimage {
    return c.GLFWimage{
        .width = @as(c_int, @intCast(self.width)),
        .height = @as(c_int, @intCast(self.height)),
        .pixels = &self.pixels[0],
    };
}

/// Deinitializes the memory using the allocator iff `.owned = true`.
pub inline fn deinit(self: Image, allocator: mem.Allocator) void {
    if (self.owned) allocator.free(self.pixels);
}

test "conversion" {
    const allocator = testing.allocator;

    const image = try Image.init(allocator, 256, 256, 256 * 256 * 4);
    defer image.deinit(allocator);

    const glfw = image.toC();
    _ = Image.fromC(glfw, image.width * image.height * 4);
}
