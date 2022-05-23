const std = @import("std");
const c = @import("c.zig");
const Error = @import("error.zig").Error;
const convertError = @import("error.zig").convertError;

const Bitmap = @This();

pub const PixelMode = enum {
    none,
    mono,
    gray,
    gray2,
    gray4,
    lcd,
    lcd_v,
    bgra,
};

handle: c.FT_Bitmap,

pub fn init(handle: c.FT_Bitmap) Bitmap {
    return Bitmap{ .handle = handle };
}

pub fn width(self: Bitmap) u32 {
    return self.handle.width;
}

pub fn pitch(self: Bitmap) i32 {
    return self.handle.pitch;
}

pub fn rows(self: Bitmap) u32 {
    return self.handle.rows;
}

pub fn pixelMode(self: Bitmap) PixelMode {
    return switch (self.handle.pixel_mode) {
        c.FT_PIXEL_MODE_NONE => .none,
        c.FT_PIXEL_MODE_MONO => .mono,
        c.FT_PIXEL_MODE_GRAY => .gray,
        c.FT_PIXEL_MODE_GRAY2 => .gray2,
        c.FT_PIXEL_MODE_GRAY4 => .gray4,
        c.FT_PIXEL_MODE_LCD => .lcd,
        c.FT_PIXEL_MODE_LCD_V => .lcd_v,
        c.FT_PIXEL_MODE_BGRA => .bgra,
        else => unreachable,
    };
}

pub fn buffer(self: Bitmap) []u8 {
    const buffer_size = std.math.absCast(self.pitch()) * self.rows();
    return self.handle.buffer[0..buffer_size];
}
