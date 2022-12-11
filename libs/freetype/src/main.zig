pub usingnamespace @import("color.zig");
pub usingnamespace @import("freetype.zig");
pub usingnamespace @import("glyph.zig");
pub usingnamespace @import("image.zig");
pub usingnamespace @import("lcdfilter.zig");
pub usingnamespace @import("stroke.zig");
pub usingnamespace @import("types.zig");
pub usingnamespace @import("computations.zig");
pub usingnamespace @import("error.zig");
pub const c = @import("c.zig");

const std = @import("std");
const testing = std.testing;
const ft = @import("freetype.zig");

fn sdkPath(comptime suffix: []const u8) []const u8 {
    if (suffix[0] != '/') @compileError("suffix must be an absolute path");
    return comptime blk: {
        const root_dir = std.fs.path.dirname(@src().file) orelse ".";
        break :blk root_dir ++ suffix;
    };
}

test {
    std.testing.refAllDeclsRecursive(@import("color.zig"));
    std.testing.refAllDeclsRecursive(@import("error.zig"));
    std.testing.refAllDeclsRecursive(@import("freetype.zig"));
    std.testing.refAllDeclsRecursive(@import("glyph.zig"));
    std.testing.refAllDeclsRecursive(@import("image.zig"));
    std.testing.refAllDeclsRecursive(@import("lcdfilter.zig"));
    std.testing.refAllDeclsRecursive(@import("stroke.zig"));
    std.testing.refAllDeclsRecursive(@import("types.zig"));
    std.testing.refAllDeclsRecursive(@import("computations.zig"));
}

const firasans_font_path = sdkPath("/../upstream/assets/FiraSans-Regular.ttf");
const firasans_font_data = @embedFile("../upstream/assets/FiraSans-Regular.ttf");

test "create face from file" {
    const lib = try ft.Library.init();
    _ = try lib.createFace(firasans_font_path, 0);
}

test "create face from memory" {
    const lib = try ft.Library.init();
    _ = try lib.createFaceMemory(firasans_font_data, 0);
}

test "create stroker" {
    const lib = try ft.Library.init();
    _ = try lib.createStroker();
}

test "load glyph" {
    const lib = try ft.Library.init();
    const face = try lib.createFace(firasans_font_path, 0);

    try face.setPixelSizes(100, 100);
    try face.setCharSize(10 * 10, 0, 72, 0);

    try face.loadGlyph(205, .{});
    try face.loadChar('A', .{});

    face.deinit();
}

test "charmap iterator" {
    const lib = try ft.Library.init();
    const face = try lib.createFace(firasans_font_path, 0);
    var iterator = face.iterateCharmap();
    var old_char: u32 = 0;
    while (iterator.next()) |char| {
        try testing.expect(old_char != char);
        old_char = char;
    }
}

test "get name index" {
    const lib = try ft.Library.init();
    const face = try lib.createFace(firasans_font_path, 0);
    try testing.expectEqual(@as(u32, 1120), face.getNameIndex("summation").?);
}

test "get index name" {
    const lib = try ft.Library.init();
    const face = try lib.createFace(firasans_font_path, 0);
    var buf: [32]u8 = undefined;
    try face.getGlyphName(1120, &buf);
    try testing.expectEqualStrings(std.mem.sliceTo(&buf, 0), "summation");
}
