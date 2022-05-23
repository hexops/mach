const std = @import("std");
const freetype = @import("freetype");

const WIDTH = 32;
const HEIGHT = 24;

fn drawBitmap(bitmap: freetype.Bitmap, x: usize, y: usize) [HEIGHT][WIDTH]u8 {
    var figure = std.mem.zeroes([HEIGHT][WIDTH]u8);
    var p: usize = 0;
    var q: usize = 0;
    const w = bitmap.width();
    const x_max = x + w;
    const y_max = y + bitmap.rows();
    var i: usize = 0;
    while (i < x_max - x) : (i += 1) {
        var j: usize = 0;
        while (j < y_max - y) : (j += 1) {
            if (i < WIDTH and j < HEIGHT) {
                figure[j][i] |= bitmap.buffer()[q * w + p];
                q += 1;
            }
        }
        q = 0;
        p += 1;
    }
    return figure;
}

pub fn main() !void {
    const lib = try freetype.Library.init();
    defer lib.deinit();

    const face = try lib.newFace("test/assets/FiraSans-Regular.ttf", 0);
    defer face.deinit();

    try face.setCharSize(40 * 64, 0, 50, 0);
    try face.loadChar('@', .{ .render = true });

    const glyph = face.glyph;
    const x = @intCast(usize, glyph.bitmapLeft());
    const y = HEIGHT - @intCast(usize, glyph.bitmapTop());

    var figure = drawBitmap(glyph.bitmap(), x, y);

    var i: usize = 0;
    while (i < HEIGHT) : (i += 1) {
        var j: usize = 0;
        while (j < WIDTH) : (j += 1) {
            const char: u8 = switch (figure[i][j]) {
                0 => ' ',
                1...128 => ';',
                else => '#',
            };
            std.debug.print("{c}", .{char});
        }
        std.debug.print("\n", .{});
    }
}
