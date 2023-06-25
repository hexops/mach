const std = @import("std");
const c = @import("c.zig");
const intToError = @import("error.zig").intToError;
const Error = @import("error.zig").Error;
const Stroker = @import("stroke.zig").Stroker;
const Library = @import("freetype.zig").Library;
const RenderMode = @import("freetype.zig").RenderMode;
const SizeMetrics = @import("freetype.zig").SizeMetrics;
const Matrix = @import("types.zig").Matrix;
const BBox = @import("types.zig").BBox;
const Outline = @import("image.zig").Outline;
const GlyphFormat = @import("image.zig").GlyphFormat;
const Vector = @import("image.zig").Vector;
const Bitmap = @import("image.zig").Bitmap;

pub const BBoxMode = enum(u2) {
    // https://freetype.org/freetype2/docs/reference/ft2-glyph_management.html#ft_glyph_bbox_mode
    // both `unscaled` and `subpixel` are set to 0
    unscaled_or_subpixels = c.FT_GLYPH_BBOX_UNSCALED,
    gridfit = c.FT_GLYPH_BBOX_GRIDFIT,
    truncate = c.FT_GLYPH_BBOX_TRUNCATE,
    pixels = c.FT_GLYPH_BBOX_PIXELS,
};

pub const Glyph = struct {
    handle: c.FT_Glyph,

    pub fn deinit(self: Glyph) void {
        c.FT_Done_Glyph(self.handle);
    }

    pub fn newGlyph(library: Library, glyph_format: GlyphFormat) Glyph {
        var g: c.FT_Glyph = undefined;
        return .{
            .handle = c.FT_New_Glyph(library.handle, @intFromEnum(glyph_format), &g),
        };
    }

    pub fn copy(self: Glyph) Error!Glyph {
        var g: c.FT_Glyph = undefined;
        try intToError(c.FT_Glyph_Copy(self.handle, &g));
        return Glyph{ .handle = g };
    }

    pub fn transform(self: Glyph, matrix: ?Matrix, delta: ?Vector) Error!void {
        try intToError(c.FT_Glyph_Transform(self.handle, if (matrix) |m| &m else null, if (delta) |d| &d else null));
    }

    pub fn getCBox(self: Glyph, bbox_mode: BBoxMode) BBox {
        var b: BBox = undefined;
        c.FT_Glyph_Get_CBox(self.handle, @intFromEnum(bbox_mode), &b);
        return b;
    }

    pub fn toBitmapGlyph(self: *Glyph, render_mode: RenderMode, origin: ?Vector) Error!BitmapGlyph {
        try intToError(c.FT_Glyph_To_Bitmap(&self.handle, @intFromEnum(render_mode), if (origin) |o| &o else null, 1));
        return BitmapGlyph{ .handle = @ptrCast(c.FT_BitmapGlyph, self.handle) };
    }

    pub fn copyBitmapGlyph(self: *Glyph, render_mode: RenderMode, origin: ?Vector) Error!BitmapGlyph {
        try intToError(c.FT_Glyph_To_Bitmap(&self.handle, @intFromEnum(render_mode), if (origin) |o| &o else null, 0));
        return BitmapGlyph{ .handle = @ptrCast(c.FT_BitmapGlyph, self.handle) };
    }

    pub fn castBitmapGlyph(self: Glyph) Error!BitmapGlyph {
        return BitmapGlyph{ .handle = @ptrCast(c.FT_BitmapGlyph, self.handle) };
    }

    pub fn castOutlineGlyph(self: Glyph) Error!OutlineGlyph {
        return OutlineGlyph{ .handle = @ptrCast(c.FT_OutlineGlyph, self.handle) };
    }

    pub fn castSvgGlyph(self: Glyph) Error!SvgGlyph {
        return SvgGlyph{ .handle = @ptrCast(c.FT_SvgGlyph, self.handle) };
    }

    pub fn stroke(self: *Glyph, stroker: Stroker) Error!void {
        try intToError(c.FT_Glyph_Stroke(&self.handle, stroker.handle, 0));
    }

    pub fn strokeBorder(self: *Glyph, stroker: Stroker, inside: bool) Error!void {
        try intToError(c.FT_Glyph_StrokeBorder(&self.handle, stroker.handle, if (inside) 1 else 0, 0));
    }

    pub fn format(self: Glyph) GlyphFormat {
        return @enumFromInt(GlyphFormat, self.handle.*.format);
    }

    pub fn advanceX(self: Glyph) isize {
        return self.handle.*.advance.x;
    }

    pub fn advanceY(self: Glyph) isize {
        return self.handle.*.advance.y;
    }
};

const SvgGlyph = struct {
    handle: c.FT_SvgGlyph,

    pub fn deinit(self: SvgGlyph) void {
        c.FT_Done_Glyph(@ptrCast(c.FT_Glyph, self.handle));
    }

    pub fn svgBuffer(self: SvgGlyph) []const u8 {
        return self.handle.*.svg_document[0..self.svgBufferLen()];
    }

    pub fn svgBufferLen(self: SvgGlyph) u32 {
        return self.handle.*.svg_document_length;
    }

    pub fn glyphIndex(self: SvgGlyph) u32 {
        return self.handle.*.glyph_index;
    }

    pub fn metrics(self: SvgGlyph) SizeMetrics {
        return self.handle.*.metrics;
    }

    pub fn unitsPerEM(self: SvgGlyph) u16 {
        return self.handle.*.units_per_EM;
    }

    pub fn startGlyphID(self: SvgGlyph) u16 {
        return self.handle.*.start_glyph_id;
    }

    pub fn endGlyphID(self: SvgGlyph) u16 {
        return self.handle.*.end_glyph_id;
    }

    pub fn transform(self: SvgGlyph) Matrix {
        return self.handle.*.transform;
    }

    pub fn delta(self: SvgGlyph) Vector {
        return self.handle.*.delta;
    }
};

pub const BitmapGlyph = struct {
    handle: c.FT_BitmapGlyph,

    pub fn deinit(self: BitmapGlyph) void {
        c.FT_Done_Glyph(@ptrCast(c.FT_Glyph, self.handle));
    }

    pub fn left(self: BitmapGlyph) i32 {
        return self.handle.*.left;
    }

    pub fn top(self: BitmapGlyph) i32 {
        return self.handle.*.top;
    }

    pub fn bitmap(self: BitmapGlyph) Bitmap {
        return .{ .handle = self.handle.*.bitmap };
    }
};

pub const OutlineGlyph = struct {
    handle: c.FT_OutlineGlyph,

    pub fn deinit(self: OutlineGlyph) void {
        c.FT_Done_Glyph(@ptrCast(c.FT_Glyph, self.handle));
    }

    pub fn outline(self: OutlineGlyph) Outline {
        return .{ .handle = &self.handle.*.outline };
    }
};
