const c = @import("c.zig");
const intToError = @import("error.zig").intToError;
const errorToInt = @import("error.zig").errorToInt;
const Error = @import("error.zig").Error;
const Matrix = @import("types.zig").Matrix;
const BBox = @import("types.zig").BBox;
const Vector = @import("image.zig").Vector;

const Outline = @This();

handle: *c.FT_Outline,

pub fn numPoints(self: Outline) u15 {
    return @intCast(u15, self.handle.*.n_points);
}

pub fn numContours(self: Outline) u15 {
    return @intCast(u15, self.handle.*.n_contours);
}

pub fn points(self: Outline) []const Vector {
    return self.handle.*.points[0..self.numPoints()];
}

pub fn tags(self: Outline) []const u8 {
    return self.handle.tags[0..@intCast(u15, self.handle.n_points)];
}

pub fn contours(self: Outline) []const i16 {
    return self.handle.*.contours[0..self.numContours()];
}

pub fn check(self: Outline) Error!void {
    try intToError(c.FT_Outline_Check(self.handle));
}

pub fn transform(self: Outline, matrix: ?Matrix) void {
    c.FT_Outline_Transform(self.handle, if (matrix) |m| &m else null);
}

pub fn bbox(self: Outline) Error!BBox {
    var b: BBox = undefined;
    try intToError(c.FT_Outline_Get_BBox(self.handle, &b));
    return b;
}

pub fn OutlineFuncs(comptime Context: type) type {
    return struct {
        move_to: fn (ctx: Context, to: Vector) Error!void,
        line_to: fn (ctx: Context, to: Vector) Error!void,
        conic_to: fn (ctx: Context, control: Vector, to: Vector) Error!void,
        cubic_to: fn (ctx: Context, control_0: Vector, control_1: Vector, to: Vector) Error!void,
        shift: i32,
        delta: i32,
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

        fn castVec(vec: [*c]const c.FT_Vector) Vector {
            return @intToPtr(*Vector, @ptrToInt(vec)).*;
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
    try intToError(c.FT_Outline_Decompose(
        self.handle,
        &.{
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
