// zig build run-example-single-glyph -- B
const std = @import("std");
const freetype = @import("freetype");

// Remove once the stage2 compiler fixes pkg std not found
comptime {
    _ = @import("utils");
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const lib = try freetype.Library.init();
    defer lib.deinit();

    const face = try lib.newFace("upstream/assets/FiraSans-Regular.ttf", 0);
    try face.setCharSize(60 * 48, 0, 50, 0);
    try face.loadChar(args[1][0], .{ .render = true });
    const bitmap = face.glyph().bitmap();

    var i: usize = 0;
    while (i < bitmap.rows()) : (i += 1) {
        var j: usize = 0;
        while (j < bitmap.width()) : (j += 1) {
            const char: u8 = switch (bitmap.buffer().?[i * bitmap.width() + j]) {
                0 => ' ',
                1...128 => ';',
                else => '#',
            };
            std.debug.print("{c}", .{char});
        }
        std.debug.print("\n", .{});
    }
}
