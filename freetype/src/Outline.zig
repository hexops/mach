const std = @import("std");
const c = @import("c.zig");
const types = @import("types.zig");
const Glyph = @import("Glyph.zig");
const Error = @import("error.zig").Error;
const convertError = @import("error.zig").convertError;

const Outline = @This();

handle: *c.FT_Outline,

pub fn init(handle: *c.FT_Outline) Outline {
    return Outline{ .handle = handle };
}

pub fn numPoints(self: Outline) u15 {
    return @intCast(u15, self.handle.*.n_points);
}

pub fn numContours(self: Outline) u15 {
    return @intCast(u15, self.handle.*.n_contours);
}

pub fn points(self: Outline) []const types.Vector {
    return self.handle.*.points[0..self.numPoints()];
}

pub fn tags(self: Outline) []const u8 {
    return self.handle.tags[0..@intCast(u15, self.handle.n_points)];
}

pub fn contours(self: Outline) []const i16 {
    return self.handle.*.contours[0..self.numContours()];
}

pub fn check(self: Outline) Error!void {
    try convertError(c.FT_Outline_Check(self.handle));
}

pub fn transform(self: Outline, matrix: ?types.Matrix) void {
    var m = matrix orelse std.mem.zeroes(types.Matrix);
    c.FT_Outline_Transform(self.handle, &m);
}

pub fn bbox(self: Outline) Error!types.BBox {
    var res = std.mem.zeroes(types.BBox);
    try convertError(c.FT_Outline_Get_BBox(self.handle, &res));
    return res;
}

pub fn decompose(self: Outline, callbacks_ctx: anytype, callbacks: *c.FT_Outline_Funcs) Error!void {
    try convertError(c.FT_Outline_Decompose(self.handle, callbacks, @ptrCast(?*anyopaque, callbacks_ctx)));
}
