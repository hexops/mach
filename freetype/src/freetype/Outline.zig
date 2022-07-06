const c = @import("c");
const builtin = @import("builtin");
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

pub fn Funcs(comptime Context: type) type {
    return struct {
        move_to: if (builtin.zig_backend == .stage1 or builtin.zig_backend == .other) fn (ctx: Context, to: Vector) Error!void else *const fn (ctx: Context, to: Vector) Error!void,
        line_to: if (builtin.zig_backend == .stage1 or builtin.zig_backend == .other) fn (ctx: Context, to: Vector) Error!void else *const fn (ctx: Context, to: Vector) Error!void,
        conic_to: if (builtin.zig_backend == .stage1 or builtin.zig_backend == .other) fn (ctx: Context, control: Vector, to: Vector) Error!void else *const fn (ctx: Context, control: Vector, to: Vector) Error!void,
        cubic_to: if (builtin.zig_backend == .stage1 or builtin.zig_backend == .other) fn (ctx: Context, control_0: Vector, control_1: Vector, to: Vector) Error!void else *const fn (ctx: Context, control_0: Vector, control_1: Vector, to: Vector) Error!void,
        shift: i32,
        delta: i32,
    };
}

pub fn FuncsWrapper(comptime Context: type) type {
    return struct {
        const Self = @This();
        ctx: Context,
        callbacks: Funcs(Context),

        fn getSelf(ptr: ?*anyopaque) *Self {
            return @ptrCast(*Self, @alignCast(@alignOf(Self), ptr));
        }

        pub fn move_to(to: [*c]const c.FT_Vector, ctx: ?*anyopaque) callconv(.C) c_int {
            const self = getSelf(ctx);
            return if (self.callbacks.move_to(self.ctx, to.*)) |_|
                0
            else |err|
                errorToInt(err);
        }

        pub fn line_to(to: [*c]const c.FT_Vector, ctx: ?*anyopaque) callconv(.C) c_int {
            const self = getSelf(ctx);
            return if (self.callbacks.line_to(self.ctx, to.*)) |_|
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
                control.*,
                to.*,
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
                control_0.*,
                control_1.*,
                to.*,
            )) |_|
                0
            else |err|
                errorToInt(err);
        }
    };
}

pub fn decompose(self: Outline, ctx: anytype, callbacks: Funcs(@TypeOf(ctx))) Error!void {
    var wrapper = FuncsWrapper(@TypeOf(ctx)){ .ctx = ctx, .callbacks = callbacks };
    try intToError(c.FT_Outline_Decompose(
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
