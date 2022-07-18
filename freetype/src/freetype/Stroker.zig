const c = @import("c");

const Stroker = @This();

pub const LineCap = enum(u2) {
    butt = c.FT_STROKER_LINECAP_BUTT,
    round = c.FT_STROKER_LINECAP_ROUND,
    square = c.FT_STROKER_LINECAP_SQUARE,
};

pub const LineJoin = enum(u2) {
    round = c.FT_STROKER_LINEJOIN_ROUND,
    bevel = c.FT_STROKER_LINEJOIN_BEVEL,
    miter_variable = c.FT_STROKER_LINEJOIN_MITER_VARIABLE,
    miter_fixed = c.FT_STROKER_LINEJOIN_MITER_FIXED,
};

handle: c.FT_Stroker,

pub fn set(self: Stroker, radius: i32, line_cap: LineCap, line_join: LineJoin, miter_limit: i32) void {
    c.FT_Stroker_Set(self.handle, radius, @enumToInt(line_cap), @enumToInt(line_join), miter_limit);
}

pub fn deinit(self: Stroker) void {
    c.FT_Stroker_Done(self.handle);
}
