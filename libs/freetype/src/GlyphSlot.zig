const c = @import("c.zig");
const intToError = @import("error.zig").intToError;
const Error = @import("error.zig").Error;
const Glyph = @import("glyph.zig").Glyph;
const Library = @import("freetype.zig").Library;
const Face = @import("freetype.zig").Face;
const RenderMode = @import("freetype.zig").RenderMode;
const Matrix = @import("types.zig").Matrix;
const Outline = @import("image.zig").Outline;
const GlyphFormat = @import("image.zig").GlyphFormat;
const Vector = @import("image.zig").Vector;
const GlyphMetrics = @import("image.zig").GlyphMetrics;
const Bitmap = @import("image.zig").Bitmap;

const GlyphSlot = @This();

pub const SubGlyphInfo = struct {
    index: i32,
    flags: c_uint,
    arg1: i32,
    arg2: i32,
    transform: Matrix,
};

handle: c.FT_GlyphSlot,

pub fn library(self: GlyphSlot) Library {
    return .{ .handle = self.handle.*.library };
}

pub fn face(self: GlyphSlot) Face {
    return .{ .handle = self.handle.*.face };
}

pub fn next(self: GlyphSlot) GlyphSlot {
    return .{ .handle = self.handle.*.next };
}

pub fn glyphIndex(self: GlyphSlot) u32 {
    return self.handle.*.glyph_index;
}

pub fn metrics(self: GlyphSlot) GlyphMetrics {
    return self.handle.*.metrics;
}

pub fn linearHoriAdvance(self: GlyphSlot) i32 {
    return @intCast(i32, self.handle.*.linearHoriAdvance);
}

pub fn linearVertAdvance(self: GlyphSlot) i32 {
    return @intCast(i32, self.handle.*.linearVertAdvance);
}

pub fn advance(self: GlyphSlot) Vector {
    return self.handle.*.advance;
}

pub fn format(self: GlyphSlot) GlyphFormat {
    return @enumFromInt(GlyphFormat, self.handle.*.format);
}

pub fn ownBitmap(self: GlyphSlot) Error!void {
    try intToError(c.FT_GlyphSlot_Own_Bitmap(self.handle));
}

pub fn bitmap(self: GlyphSlot) Bitmap {
    return .{ .handle = self.handle.*.bitmap };
}

pub fn bitmapLeft(self: GlyphSlot) i32 {
    return self.handle.*.bitmap_left;
}

pub fn bitmapTop(self: GlyphSlot) i32 {
    return self.handle.*.bitmap_top;
}

pub fn outline(self: GlyphSlot) ?Outline {
    return if (self.format() == .outline) .{ .handle = &self.handle.*.outline } else null;
}

pub fn lsbDelta(self: GlyphSlot) i32 {
    return @intCast(i32, self.handle.*.lsb_delta);
}

pub fn rsbDelta(self: GlyphSlot) i32 {
    return @intCast(i32, self.handle.*.rsb_delta);
}

pub fn render(self: GlyphSlot, render_mode: RenderMode) Error!void {
    return intToError(c.FT_Render_Glyph(self.handle, @intFromEnum(render_mode)));
}

pub fn getSubGlyphInfo(self: GlyphSlot, sub_index: u32) Error!SubGlyphInfo {
    var info: SubGlyphInfo = undefined;
    try intToError(c.FT_Get_SubGlyph_Info(self.handle, sub_index, &info.index, &info.flags, &info.arg1, &info.arg2, &info.transform));
    return info;
}

pub fn getGlyph(self: GlyphSlot) Error!Glyph {
    var res: c.FT_Glyph = undefined;
    try intToError(c.FT_Get_Glyph(self.handle, &res));
    return Glyph{ .handle = res };
}
