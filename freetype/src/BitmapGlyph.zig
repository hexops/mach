const std = @import("std");
const c = @import("c.zig");
const Bitmap = @import("Bitmap.zig");
const Error = @import("error.zig").Error;
const convertError = @import("error.zig").convertError;

const BitmapGlyph = @This();

handle: c.FT_BitmapGlyph,

pub fn init(handle: c.FT_BitmapGlyph) BitmapGlyph {
    return BitmapGlyph{ .handle = handle };
}

pub fn deinit(self: BitmapGlyph) void {
    c.FT_Done_Glyph(@ptrCast(c.FT_Glyph, self.handle));
}

pub fn clone(self: BitmapGlyph) Error!BitmapGlyph {
    var res = std.mem.zeroes(c.FT_Glyph);
    try convertError(c.FT_Glyph_Copy(@ptrCast(c.FT_Glyph, self.handle), &res));
    return BitmapGlyph.init(@ptrCast(c.FT_BitmapGlyph, res));
}

pub fn left(self: BitmapGlyph) i32 {
    return self.handle.*.left;
}

pub fn top(self: BitmapGlyph) i32 {
    return self.handle.*.top;
}

pub fn bitmap(self: BitmapGlyph) Bitmap {
    return Bitmap.init(self.handle.*.bitmap);
}
