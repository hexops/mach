const std = @import("std");
const c = @import("c");
const intToError = @import("error.zig").intToError;
const Error = @import("error.zig").Error;
const Library = @import("Library.zig");
const Color = @import("color.zig").Color;

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

    pub fn init() Bitmap {
        var b: c.FT_Bitmap = undefined;
        c.FT_Bitmap_Init(&b);
        return .{ .handle = b };
    }

    pub fn deinit(self: *Bitmap, lib: Library) void {
        _ = c.FT_Bitmap_Done(lib.handle, &self.handle);
    }

    pub fn copy(self: Bitmap, lib: Library) Error!Bitmap {
        var b: c.FT_Bitmap = undefined;
        try intToError(c.FT_Bitmap_Copy(lib.handle, &self.handle, &b));
        return Bitmap{ .handle = b };
    }

    pub fn embolden(self: *Bitmap, lib: Library, x_strength: i32, y_strength: i32) Error!void {
        try intToError(c.FT_Bitmap_Embolden(lib.handle, &self.handle, x_strength, y_strength));
    }

    pub fn convert(self: Bitmap, lib: Library, alignment: u29) Error!Bitmap {
        var b: c.FT_Bitmap = undefined;
        try intToError(c.FT_Bitmap_Convert(lib.handle, &self.handle, &b, alignment));
        return Bitmap{ .handle = b };
    }

    pub fn blend(self: *Bitmap, lib: Library, source_offset: Vector, target_offset: *Vector, color: Color) Error!void {
        var b: c.FT_Bitmap = undefined;
        c.FT_Bitmap_Init(&b);
        try intToError(c.FT_Bitmap_Blend(lib.handle, &self.handle, source_offset, &b, target_offset, color));
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
        return @intToEnum(PixelMode, self.handle.pixel_mode);
    }

    pub fn buffer(self: Bitmap) ?[]const u8 {
        const buffer_size = std.math.absCast(self.pitch()) * self.rows();
        return if (self.handle.buffer == null)
            // freetype returns a null pointer for zero-length allocations
            // https://github.com/hexops/freetype/blob/bbd80a52b7b749140ec87d24b6c767c5063be356/freetype/src/base/ftutil.c#L135
            null
        else
            self.handle.buffer[0..buffer_size];
    }
};
