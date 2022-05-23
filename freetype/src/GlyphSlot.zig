const std = @import("std");
const c = @import("c.zig");
const types = @import("types.zig");
const Glyph = @import("Glyph.zig");
const Outline = @import("Outline.zig");
const Bitmap = @import("Bitmap.zig");
const Error = @import("error.zig").Error;
const convertError = @import("error.zig").convertError;

const GlyphSlot = @This();

pub const GlyphMetrics = c.FT_Glyph_Metrics;
pub const SubGlyphInfo = struct {
    index: i32,
    flags: u32,
    arg1: i32,
    arg2: i32,
    transform: types.Matrix,
};

handle: c.FT_GlyphSlot,

pub fn init(handle: c.FT_GlyphSlot) GlyphSlot {
    return GlyphSlot{ .handle = handle };
}

pub fn render(self: GlyphSlot, render_mode: Glyph.RenderMode) Error!void {
    return convertError(c.FT_Render_Glyph(self.handle, @enumToInt(render_mode)));
}

pub fn subGlyphInfo(self: GlyphSlot, sub_index: u32) Error!SubGlyphInfo {
    var info = std.mem.zeroes(SubGlyphInfo);
    try convertError(c.FT_Get_SubGlyph_Info(self.handle, sub_index, &info.index, &info.flags, &info.arg1, &info.arg2, &info.transform));
    return info;
}

pub fn glyph(self: GlyphSlot) Error!Glyph {
    var out = std.mem.zeroes(c.FT_Glyph);
    try convertError(c.FT_Get_Glyph(self.handle, &out));
    return Glyph.init(out);
}

pub fn outline(self: GlyphSlot) ?Outline {
    const out = self.handle.*.outline;
    const format = self.handle.*.format;

    return if (format == c.FT_GLYPH_FORMAT_OUTLINE)
        Outline.init(out)
    else
        null;
}

pub fn bitmap(self: GlyphSlot) Bitmap {
    return Bitmap.init(self.handle.*.bitmap);
}

pub fn bitmapLeft(self: GlyphSlot) i32 {
    return self.handle.*.bitmap_left;
}

pub fn bitmapTop(self: GlyphSlot) i32 {
    return self.handle.*.bitmap_top;
}

pub fn linearHoriAdvance(self: GlyphSlot) i64 {
    return self.handle.*.linearHoriAdvance;
}

pub fn linearVertAdvance(self: GlyphSlot) i64 {
    return self.handle.*.linearVertAdvance;
}

pub fn advance(self: GlyphSlot) types.Vector {
    return self.handle.*.advance;
}

pub fn metrics(self: GlyphSlot) GlyphMetrics {
    return self.handle.*.metrics;
}
