const std = @import("std");
const c = @import("c.zig");
const BitmapGlyph = @import("BitmapGlyph.zig");
const Stroker = @import("Stroker.zig");
const types = @import("types.zig");
const Error = @import("error.zig").Error;
const convertError = @import("error.zig").convertError;

const Glyph = @This();

pub const BBox = c.FT_BBox;
pub const RenderMode = enum(u3) {
    normal = c.FT_RENDER_MODE_NORMAL,
    light = c.FT_RENDER_MODE_LIGHT,
    mono = c.FT_RENDER_MODE_MONO,
    lcd = c.FT_RENDER_MODE_LCD,
    lcd_v = c.FT_RENDER_MODE_LCD_V,
    sdf = c.FT_RENDER_MODE_SDF,
};
pub const BBoxMode = enum(u2) {
    // https://freetype.org/freetype2/docs/reference/ft2-glyph_management.html#ft_glyph_bbox_mode
    // both `unscaled` and `subpixel` constants are set to 0
    unscaled_or_subpixels = c.FT_GLYPH_BBOX_UNSCALED,
    gridfit = c.FT_GLYPH_BBOX_GRIDFIT,
    truncate = c.FT_GLYPH_BBOX_TRUNCATE,
    pixels = c.FT_GLYPH_BBOX_PIXELS,
};

handle: c.FT_Glyph,

pub fn init(handle: c.FT_Glyph) Glyph {
    return Glyph{ .handle = handle };
}

pub fn deinit(self: Glyph) void {
    c.FT_Done_Glyph(self.handle);
}

pub fn clone(self: Glyph) Error!Glyph {
    var res = std.mem.zeroes(c.FT_Glyph);
    try convertError(c.FT_Glyph_Copy(self.handle, &res));
    return Glyph.init(res);
}

pub fn transform(self: Glyph, matrix: ?types.Matrix, delta: ?types.Vector) Error!void {
    var m = matrix orelse std.mem.zeroes(types.Matrix);
    var d = delta orelse std.mem.zeroes(types.Vector);
    try convertError(c.FT_Glyph_Transform(self.handle, &m, &d));
}

pub fn getCBox(self: Glyph, bbox_mode: BBoxMode) BBox {
    var res = std.mem.zeroes(BBox);
    c.FT_Glyph_Get_CBox(self.handle, @enumToInt(bbox_mode), &res);
    return res;
}

pub fn toBitmap(self: Glyph, render_mode: RenderMode, origin: ?types.Vector) Error!BitmapGlyph {
    var res = self.handle;
    var o = origin orelse std.mem.zeroes(types.Vector);
    try convertError(c.FT_Glyph_To_Bitmap(&res, @enumToInt(render_mode), &o, 0));
    return BitmapGlyph.init(@ptrCast(c.FT_BitmapGlyph, self.handle));
}

pub fn stroke(self: Glyph, stroker: Stroker) Error!Glyph {
    var res = self.handle;
    try convertError(c.FT_Glyph_Stroke(&res, stroker.handle, 0));
    return Glyph.init(res);
}

pub fn strokeBorder(self: Glyph, stroker: Stroker, inside: bool) Error!Glyph {
    var res = self.handle;
    try convertError(c.FT_Glyph_StrokeBorder(&res, stroker.handle, if (inside) 1 else 0, 0));
    return Glyph.init(res);
}

pub fn advanceX(self: Glyph) isize {
    return self.handle.*.advance.x;
}

pub fn advanceY(self: Glyph) isize {
    return self.handle.*.advance.y;
}
