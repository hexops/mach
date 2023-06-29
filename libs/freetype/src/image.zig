const builtin = @import("builtin");
const std = @import("std");
const testing = std.testing;
const c = @import("c.zig");
const intToError = @import("error.zig").intToError;
const errorToInt = @import("error.zig").errorToInt;
const Error = @import("error.zig").Error;
const Library = @import("freetype.zig").Library;
const Color = @import("color.zig").Color;
const Stroker = @import("stroke.zig").Stroker;
const Matrix = @import("types.zig").Matrix;
const BBox = @import("types.zig").BBox;

pub const Vector = c.FT_Vector;
pub const GlyphMetrics = c.FT_Glyph_Metrics;
pub const Span = c.FT_Span;
pub const SpanFunc = *const fn (y: c_int, count: c_int, spans: [*]const Span, user: *anyopaque) callconv(.C) void;

pub const PixelMode = enum(u3) {
    none = c.FT_PIXEL_MODE_NONE,
    mono = c.FT_PIXEL_MODE_MONO,
    gray = c.FT_PIXEL_MODE_GRAY,
    gray2 = c.FT_PIXEL_MODE_GRAY2,
    gray4 = c.FT_PIXEL_MODE_GRAY4,
    lcd = c.FT_PIXEL_MODE_LCD,
    lcd_v = c.FT_PIXEL_MODE_LCD_V,
    bgra = c.FT_PIXEL_MODE_BGRA,
};

pub const GlyphFormat = enum(u32) {
    none = c.FT_GLYPH_FORMAT_NONE,
    composite = c.FT_GLYPH_FORMAT_COMPOSITE,
    bitmap = c.FT_GLYPH_FORMAT_BITMAP,
    outline = c.FT_GLYPH_FORMAT_OUTLINE,
    plotter = c.FT_GLYPH_FORMAT_PLOTTER,
    svg = c.FT_GLYPH_FORMAT_SVG,
};

pub const Bitmap = struct {
    handle: c.FT_Bitmap,

    pub fn init() Bitmap {
        var b: c.FT_Bitmap = undefined;
        c.FT_Bitmap_Init(&b);
        return .{ .handle = b };
    }

    pub fn deinit(self: *Bitmap, lib: Library) void {
        _ = c.FT_Bitmap_Done(lib.handle, &self.handle);
    }

    pub fn copy(self: Bitmap, lib: Library) Error!Bitmap {
        var b: c.FT_Bitmap = undefined;
        try intToError(c.FT_Bitmap_Copy(lib.handle, &self.handle, &b));
        return Bitmap{ .handle = b };
    }

    pub fn embolden(self: *Bitmap, lib: Library, x_strength: i32, y_strength: i32) Error!void {
        try intToError(c.FT_Bitmap_Embolden(lib.handle, &self.handle, x_strength, y_strength));
    }

    pub fn convert(self: Bitmap, lib: Library, alignment: u29) Error!Bitmap {
        var b: c.FT_Bitmap = undefined;
        try intToError(c.FT_Bitmap_Convert(lib.handle, &self.handle, &b, alignment));
        return Bitmap{ .handle = b };
    }

    pub fn blend(self: *Bitmap, lib: Library, source_offset: Vector, target_offset: *Vector, color: Color) Error!void {
        var b: c.FT_Bitmap = undefined;
        c.FT_Bitmap_Init(&b);
        try intToError(c.FT_Bitmap_Blend(lib.handle, &self.handle, source_offset, &b, target_offset, color));
    }

    pub fn width(self: Bitmap) u32 {
        return self.handle.width;
    }

    pub fn pitch(self: Bitmap) i32 {
        return self.handle.pitch;
    }

    pub fn rows(self: Bitmap) u32 {
        return self.handle.rows;
    }

    pub fn pixelMode(self: Bitmap) PixelMode {
        return @as(PixelMode, @enumFromInt(self.handle.pixel_mode));
    }

    pub fn buffer(self: Bitmap) ?[]const u8 {
        const buffer_size = std.math.absCast(self.pitch()) * self.rows();
        return if (self.handle.buffer == null)
            // freetype returns a null pointer for zero-length allocations
            // https://github.com/hexops-graveyard/freetype/blob/bbd80a52b7b749140ec87d24b6c767c5063be356/freetype/src/base/ftutil.c#L135
            null
        else
            self.handle.buffer[0..buffer_size];
    }
};

pub const Outline = struct {
    pub const Orientation = enum(u2) {
        truetype = c.FT_ORIENTATION_TRUETYPE,
        postscript = c.FT_ORIENTATION_POSTSCRIPT,
        none = c.FT_ORIENTATION_NONE,
    };

    pub const Flags = packed struct(c_int) {
        owner: bool = false,
        even_odd_fill: bool = false,
        reverse_fill: bool = false,
        ignore_dropouts: bool = false,
        smart_dropouts: bool = false,
        include_stubs: bool = false,
        overlap: bool = false,
        _padding: u1 = 0,
        high_precision: bool = false,
        single_pass: bool = false,
        _padding0: u22 = 0,
    };

    handle: *c.FT_Outline,

    pub fn numPoints(self: Outline) u15 {
        return @as(u15, @intCast(self.handle.*.n_points));
    }

    pub fn numContours(self: Outline) u15 {
        return @as(u15, @intCast(self.handle.*.n_contours));
    }

    pub fn points(self: Outline) []const Vector {
        return self.handle.*.points[0..self.numPoints()];
    }

    pub fn tags(self: Outline) []const u8 {
        return self.handle.tags[0..@as(u15, @intCast(self.handle.n_points))];
    }

    pub fn contours(self: Outline) []const i16 {
        return self.handle.*.contours[0..self.numContours()];
    }

    pub fn flags(self: Outline) Flags {
        return @as(Flags, @bitCast(self.handle.*.flags));
    }

    pub fn copy(self: Outline) Error!Outline {
        var o: c.FT_Outline = undefined;
        try intToError(c.FT_Outline_Copy(self.handle, &o));
        return Outline{ .handle = &o };
    }

    pub fn translate(self: Outline, x_offset: i32, y_offset: i32) void {
        c.FT_Outline_Translate(self.handle, x_offset, y_offset);
    }

    pub fn transform(self: Outline, matrix: ?Matrix) void {
        c.FT_Outline_Transform(self.handle, if (matrix) |m| &m else null);
    }

    pub fn embolden(self: Outline, strength: i32) Error!void {
        try intToError(c.FT_Outline_Embolden(self.handle, strength));
    }

    pub fn emboldenXY(self: Outline, x_strength: i32, y_strength: i32) Error!void {
        try intToError(c.FT_Outline_EmboldenXY(self.handle, x_strength, y_strength));
    }

    pub fn reverse(self: Outline) void {
        c.FT_Outline_Reverse(self.handle);
    }

    pub fn check(self: Outline) Error!void {
        try intToError(c.FT_Outline_Check(self.handle));
    }

    pub fn cbox(self: Outline) BBox {
        var b: BBox = undefined;
        c.FT_Outline_Get_CBox(self.handle, &b);
        return b;
    }

    pub fn bbox(self: Outline) Error!BBox {
        var b: BBox = undefined;
        try intToError(c.FT_Outline_Get_BBox(self.handle, &b));
        return b;
    }

    pub fn orientation(self: Outline) Orientation {
        return @as(Orientation, @enumFromInt(c.FT_Outline_Get_Orientation(self.handle)));
    }

    pub fn getInsideBorder(self: Outline) Stroker.Border {
        return @as(Stroker.Border, @enumFromInt(c.FT_Outline_GetInsideBorder(self.handle)));
    }

    pub fn getOutsideBorder(self: Outline) Stroker.Border {
        return @as(Stroker.Border, @enumFromInt(c.FT_Outline_GetOutsideBorder(self.handle)));
    }

    pub fn Funcs(comptime Context: type) type {
        return struct {
            move_to: *const fn (ctx: Context, to: Vector) Error!void,
            line_to: *const fn (ctx: Context, to: Vector) Error!void,
            conic_to: *const fn (ctx: Context, control: Vector, to: Vector) Error!void,
            cubic_to: *const fn (ctx: Context, control_0: Vector, control_1: Vector, to: Vector) Error!void,
            shift: i32,
            delta: i32,
        };
    }

    fn FuncsWrapper(comptime Context: type) type {
        return struct {
            const Self = @This();
            ctx: Context,
            callbacks: Funcs(Context),

            fn getSelf(ptr: ?*anyopaque) *Self {
                return @as(*Self, @ptrCast(@alignCast(@alignOf(Self), ptr)));
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
};

pub const Raster = struct {
    handle: c.FT_Raster,

    pub const NewFunc = *const fn (memory: ?*anyopaque, raster: [*c]c.FT_Raster) callconv(.C) c_int;
    pub const DoneFunc = *const fn (raster: [*c]c.FT_Raster) callconv(.C) void;
    pub const ResetFunc = *const fn (raster: c.FT_Raster, pool_base: [*c]u8, pool_size: c_ulong) callconv(.C) void;
    pub const SetModeFunc = *const fn (raster: c.FT_Raster, mode: c_ulong, args: ?*anyopaque) callconv(.C) c_int;
    pub const RenderFunc = *const fn (raster: c.FT_Raster, params: Params) callconv(.C) c_int;
    pub const BitTestFunc = *const fn (y: c_int, x: c_int, user: ?*anyopaque) callconv(.C) c_int;
    pub const BitSetFunc = *const fn (y: c_int, x: c_int, user: ?*anyopaque) callconv(.C) void;

    pub const Params = extern struct {
        target: [*c]const c.FT_Bitmap,
        source: [*]const u8,
        flags: c_int,
        gray_spans: SpanFunc,
        black_spans: ?SpanFunc = null, // unused
        bit_test: ?BitTestFunc = null, // unused
        bit_set: ?BitSetFunc = null, // unused
        user: ?*anyopaque = null,
        clip_box: BBox,
    };

    pub const Flags = packed struct(c_int) {
        aa: bool = false,
        direct: bool = false,
        clip: bool = false,
        sdf: bool = false,
        _padding: u28 = 0,
    };
};
