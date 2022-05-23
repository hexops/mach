const c = @import("c.zig");
const Error = @import("error.zig").Error;
const convertError = @import("error.zig").convertError;

const Stroker = @This();

pub const StrokerLineCap = enum(u2) {
    butt = c.FT_STROKER_LINECAP_BUTT,
    round = c.FT_STROKER_LINECAP_ROUND,
    square = c.FT_STROKER_LINECAP_SQUARE,
};

pub const StrokerLineJoin = enum(u2) {
    round = c.FT_STROKER_LINEJOIN_ROUND,
    bevel = c.FT_STROKER_LINEJOIN_BEVEL,
    miterVariable = c.FT_STROKER_LINEJOIN_MITER_VARIABLE,
    miterFixed = c.FT_STROKER_LINEJOIN_MITER_FIXED,
};

handle: c.FT_Stroker,

pub fn init(handle: c.FT_Stroker) Stroker {
    return Stroker{ .handle = handle };
}

pub fn set(self: Stroker, radius: i32, line_cap: StrokerLineCap, line_join: StrokerLineJoin, miter_limit: i32) void {
    c.FT_Stroker_Set(self.handle, radius, @enumToInt(line_cap), @enumToInt(line_join), miter_limit);
}

pub fn deinit(self: Stroker) void {
    c.FT_Stroker_Done(self.handle);
}
