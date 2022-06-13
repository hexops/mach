const std = @import("std");
const freetype = @import("freetype");

const OutlinePrinter = struct {
    library: freetype.Library,
    face: freetype.Face,
    output_file: std.fs.File,
    path_stream: std.io.FixedBufferStream([]u8),

    xMin: isize,
    yMin: isize,
    width: isize,
    height: isize,

    const Self = @This();

    pub fn init(file: std.fs.File) freetype.Error!Self {
        var lib = try freetype.Library.init();
        return Self{
            .library = lib,
            .face = try lib.newFace("upstream/assets/FiraSans-Regular.ttf", 0),
            .output_file = file,
            .path_stream = std.io.fixedBufferStream(&std.mem.zeroes([1024 * 10]u8)),
            .xMin = 0,
            .yMin = 0,
            .width = 0,
            .height = 0,
        };
    }

    pub fn deinit(self: Self) void {
        self.library.deinit();
    }

    pub fn outlineExists(self: Self) bool {
        const outline = self.face.glyph().outline() orelse return false;
        if (outline.numContours() <= 0 or outline.numPoints() <= 0)
            return false;
        outline.check() catch return false;
        return true;
    }

    pub fn flipOutline(self: Self) void {
        const multiplier = 65536;
        const matrix = freetype.Matrix{
            .xx = 1 * multiplier,
            .xy = 0 * multiplier,
            .yx = 0 * multiplier,
            .yy = -1 * multiplier,
        };
        self.face.glyph().outline().?.transform(matrix);
    }

    pub fn extractOutline(self: *Self) !void {
        try self.path_stream.writer().writeAll("<path d='");
        var callbacks = freetype.Outline.Funcs(*Self){
            .move_to = moveToFunction,
            .line_to = lineToFunction,
            .conic_to = conicToFunction,
            .cubic_to = cubicToFunction,
            .shift = 0,
            .delta = 0,
        };
        try self.face.glyph().outline().?.decompose(self, callbacks);
        try self.path_stream.writer().writeAll("' fill='#000'/>");
    }

    pub fn computeViewBox(self: *Self) !void {
        const boundingBox = try self.face.glyph().outline().?.bbox();
        self.xMin = boundingBox.xMin;
        self.yMin = boundingBox.yMin;
        self.width = boundingBox.xMax - boundingBox.xMin;
        self.height = boundingBox.yMax - boundingBox.yMin;
    }

    pub fn printSVG(self: Self) !void {
        try self.output_file.writer().print(
            \\<svg xmlns='http://www.w3.org/2000/svg'
            \\  xmlns:xlink='http://www.w3.org/1999/xlink'
            \\  viewBox='{d} {d} {d} {d}'>
            \\  {s}
            \\</svg>
        , .{ self.xMin, self.yMin, self.width, self.height, self.path_stream.getWritten() });
    }

    pub fn moveToFunction(self: *Self, to: freetype.Vector) freetype.Error!void {
        self.path_stream.writer().print("M {d} {d}\t", .{ to.x, to.y }) catch unreachable;
    }

    pub fn lineToFunction(self: *Self, to: freetype.Vector) freetype.Error!void {
        self.path_stream.writer().print("L {d} {d}\t", .{ to.x, to.y }) catch unreachable;
    }

    pub fn conicToFunction(self: *Self, control: freetype.Vector, to: freetype.Vector) freetype.Error!void {
        self.path_stream.writer().print("Q {d} {d}, {d} {d}\t", .{ control.x, control.y, to.x, to.y }) catch unreachable;
    }

    pub fn cubicToFunction(self: *Self, control_0: freetype.Vector, control_1: freetype.Vector, to: freetype.Vector) freetype.Error!void {
        self.path_stream.writer().print("C {d} {d}, {d} {d}, {d} {d}\t", .{ control_0.x, control_0.y, control_1.x, control_1.y, to.x, to.y }) catch unreachable;
    }

    pub fn run(self: *Self, symbol: u32) !void {
        try self.face.loadChar(symbol, .{ .no_scale = true, .no_bitmap = true });

        if (!self.outlineExists())
            return error.OutlineDoesntExists;

        self.flipOutline();
        try self.extractOutline();
        try self.computeViewBox();
        try self.printSVG();
    }
};

pub fn main() !void {
    var file = try std.fs.cwd().createFile("out.svg", .{});
    defer file.close();

    var outline_printer = try OutlinePrinter.init(file);
    defer outline_printer.deinit();
    try outline_printer.run(@as(u32, 'ë'));
}
