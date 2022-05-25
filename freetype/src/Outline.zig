const std = @import("std");
const c = @import("c.zig");
const types = @import("types.zig");
const Glyph = @import("Glyph.zig");
const Error = @import("error.zig").Error;
const convertError = @import("error.zig").convertError;
const errorToInt = @import("error.zig").errorToInt;

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
    return @ptrCast([]types.Vector, self.handle.*.points[0..self.numPoints()]);
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
    c.FT_Outline_Transform(self.handle, @ptrCast(*c.FT_Matrix, &m));
}

pub fn bbox(self: Outline) Error!types.BBox {
    var res = std.mem.zeroes(types.BBox);
    try convertError(c.FT_Outline_Get_BBox(self.handle, @ptrCast(*c.FT_BBox, &res)));
    return res;
}

pub fn OutlineFuncs(comptime Context: type) type {
    return struct {
        move_to: fn (ctx: Context, to: types.Vector) Error!void,
        line_to: fn (ctx: Context, to: types.Vector) Error!void,
        conic_to: fn (ctx: Context, control: types.Vector, to: types.Vector) Error!void,
        cubic_to: fn (ctx: Context, control_0: types.Vector, control_1: types.Vector, to: types.Vector) Error!void,
        shift: c_int,
        delta: isize,
    };
}

pub fn OutlineFuncsWrapper(comptime Context: type) type {
    return struct {
        const Self = @This();
        ctx: Context,
        callbacks: OutlineFuncs(Context),

        fn getSelf(ptr: ?*anyopaque) *Self {
            return @ptrCast(*Self, @alignCast(@alignOf(Self), ptr));
        }

        fn castVec(vec: [*c]const c.FT_Vector) types.Vector {
            return @intToPtr(*types.Vector, @ptrToInt(vec)).*;
        }

        pub fn move_to(to: [*c]const c.FT_Vector, ctx: ?*anyopaque) callconv(.C) c_int {
            const self = getSelf(ctx);
            return if (self.callbacks.move_to(self.ctx, castVec(to))) |_|
                0
            else |err|
                errorToInt(err);
        }

        pub fn line_to(to: [*c]const c.FT_Vector, ctx: ?*anyopaque) callconv(.C) c_int {
            const self = getSelf(ctx);
            return if (self.callbacks.line_to(self.ctx, castVec(to))) |_|
                0
            else |err|
                errorToInt(err);
        }

        pub fn conic_to(
            control: [*c]const c.FT_Vector,
            to: [*c]const c.FT_Vector,
            ctx: ?*anyopaque,
        ) callconv(.C) c_int {
            const self = getSelf(ctx);
            return if (self.callbacks.conic_to(
                self.ctx,
                castVec(control),
                castVec(to),
            )) |_|
                0
            else |err|
                errorToInt(err);
        }

        pub fn cubic_to(
            control_0: [*c]const c.FT_Vector,
            control_1: [*c]const c.FT_Vector,
            to: [*c]const c.FT_Vector,
            ctx: ?*anyopaque,
        ) callconv(.C) c_int {
            const self = getSelf(ctx);
            return if (self.callbacks.cubic_to(
                self.ctx,
                castVec(control_0),
                castVec(control_1),
                castVec(to),
            )) |_|
                0
            else |err|
                errorToInt(err);
        }
    };
}

pub fn decompose(self: Outline, ctx: anytype, callbacks: OutlineFuncs(@TypeOf(ctx))) Error!void {
    var wrapper = OutlineFuncsWrapper(@TypeOf(ctx)){ .ctx = ctx, .callbacks = callbacks };
    try convertError(c.FT_Outline_Decompose(
        self.handle,
        &c.FT_Outline_Funcs{
            .move_to = @TypeOf(wrapper).move_to,
            .line_to = @TypeOf(wrapper).line_to,
            .conic_to = @TypeOf(wrapper).conic_to,
            .cubic_to = @TypeOf(wrapper).cubic_to,
            .shift = callbacks.shift,
            .delta = callbacks.delta,
        },
        &wrapper,
    ));
}
