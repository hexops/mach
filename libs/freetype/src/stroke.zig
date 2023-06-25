const c = @import("c.zig");
const intToError = @import("error.zig").intToError;
const Error = @import("error.zig").Error;
const Outline = @import("image.zig").Outline;
const Vector = @import("image.zig").Vector;

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

pub const Stroker = struct {
    pub const Border = enum(u1) {
        left,
        right,
    };

    pub const BorderCounts = struct {
        points: u32,
        contours: u32,
    };

    handle: c.FT_Stroker,

    pub fn set(self: Stroker, radius: i32, line_cap: LineCap, line_join: LineJoin, miter_limit: i32) void {
        c.FT_Stroker_Set(self.handle, radius, @intFromEnum(line_cap), @intFromEnum(line_join), miter_limit);
    }

    pub fn rewind(self: Stroker) void {
        c.FT_Stroker_Rewind(self.handle);
    }

    pub fn parseOutline(self: Stroker, outline: Outline, opened: bool) Error!void {
        try intToError(c.FT_Stroker_ParseOutline(self.handle, outline.handle, if (opened) 1 else 0));
    }

    pub fn beginSubPath(self: Stroker, to: *Vector, open: bool) Error!void {
        try intToError(c.FT_Stroker_BeginSubPath(self.handle, to, if (open) 1 else 0));
    }

    pub fn endSubPath(self: Stroker) Error!void {
        try intToError(c.FT_Stroker_EndSubPath(self.handle));
    }

    pub fn lineTo(self: Stroker, to: *Vector) Error!void {
        try intToError(c.FT_Stroker_LineTo(self.handle, to));
    }

    pub fn conicTo(self: Stroker, control: *Vector, to: *Vector) Error!void {
        try intToError(c.FT_Stroker_ConicTo(self.handle, control, to));
    }

    pub fn cubicTo(self: Stroker, control_0: *Vector, control_1: *Vector, to: *Vector) Error!void {
        try intToError(c.FT_Stroker_CubicTo(self.handle, control_0, control_1, to));
    }

    pub fn getBorderCounts(self: Stroker, border: Border) Error!BorderCounts {
        var counts: BorderCounts = undefined;
        try intToError(c.FT_Stroker_GetBorderCounts(self.handle, @intFromEnum(border), &counts.points, &counts.contours));
        return counts;
    }

    pub fn exportBorder(self: Stroker, border: Border, outline: *Outline) void {
        c.FT_Stroker_ExportBorder(self.handle, @intFromEnum(border), outline.handle);
    }

    pub fn getCounts(self: Stroker) Error!BorderCounts {
        var counts: BorderCounts = undefined;
        try intToError(c.FT_Stroker_GetCounts(self.handle, &counts.points, &counts.contours));
        return counts;
    }

    pub fn exportAll(self: Stroker, outline: *Outline) void {
        c.FT_Stroker_Export(self.handle, outline.handle);
    }

    pub fn deinit(self: Stroker) void {
        c.FT_Stroker_Done(self.handle);
    }
};
