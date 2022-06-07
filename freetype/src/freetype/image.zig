const std = @import("std");
const c = @import("c.zig");

pub const Outline = @import("Outline.zig");

pub const Vector = c.FT_Vector;
pub const GlyphMetrics = c.FT_Glyph_Metrics;

pub const PixelMode = enum(u3) {
    none = c.FT_PIXEL_MODE_NONE,
    mono = c.FT_PIXEL_MODE_MONO,
    gray = c.FT_PIXEL_MODE_GRAY,
    gray2 = c.FT_PIXEL_MODE_GRAY2,
    gray4 = c.FT_PIXEL_MODE_GRAY4,
    lcd = c.FT_PIXEL_MODE_LCD,
    lcd_v = c.FT_PIXEL_MODE_LCD_V,
    bgra = c.FT_PIXEL_MODE_BGRA,
};

pub const GlyphFormat = enum(u32) {
    none = c.FT_GLYPH_FORMAT_NONE,
    composite = c.FT_GLYPH_FORMAT_COMPOSITE,
    bitmap = c.FT_GLYPH_FORMAT_BITMAP,
    outline = c.FT_GLYPH_FORMAT_OUTLINE,
    plotter = c.FT_GLYPH_FORMAT_PLOTTER,
    svg = c.FT_GLYPH_FORMAT_SVG,
};

pub const Bitmap = struct {
    handle: c.FT_Bitmap,

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
        return @intToEnum(PixelMode, self.handle.pixel_mode);
    }

    pub fn buffer(self: Bitmap) []const u8 {
        const buffer_size = std.math.absCast(self.pitch()) * self.rows();
        return self.handle.buffer[0..buffer_size];
    }
};
