const c = @import("c.zig");
const types = @import("types.zig");

const Outline = @This();

handle: c.FT_Outline,

pub fn init(handle: c.FT_Outline) Outline {
    return Outline{ .handle = handle };
}

pub fn points(self: Outline) []const types.Vector {
    return self.handle.points[0..@intCast(u15, self.handle.n_points)];
}

pub fn tags(self: Outline) []const u8 {
    return self.handle.tags[0..@intCast(u15, self.handle.n_points)];
}

pub fn contours(self: Outline) []const i16 {
    return self.handle.contours[0..@intCast(u15, self.handle.n_contours)];
}
