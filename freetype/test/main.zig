const std = @import("std");
const testing = std.testing;
const freetype = @import("freetype");

const firasans_font_path = "upstream/assets/FiraSans-Regular.ttf";
const firasans_font_data = @embedFile("../upstream/assets/FiraSans-Regular.ttf");

// Remove once the stage2 compiler fixes pkg std not found
comptime {
    _ = @import("utils");
}

test "create face from file" {
    const lib = try freetype.Library.init();
    _ = try lib.createFace(firasans_font_path, 0);
}

test "create face from memory" {
    const lib = try freetype.Library.init();
    _ = try lib.createFaceMemory(firasans_font_data, 0);
}

test "create stroker" {
    const lib = try freetype.Library.init();
    _ = try lib.createStroker();
}

test "set lcd filter" {
    if (@hasDecl(freetype.c, "FT_CONFIG_OPTION_SUBPIXEL_RENDERING")) {
        const lib = try freetype.Library.init();
        try lib.setLcdFilter(.default);
    } else {
        return error.SkipZigTest;
    }
}

test "load glyph" {
    const lib = try freetype.Library.init();
    const face = try lib.createFace(firasans_font_path, 0);

    try face.setPixelSizes(100, 100);
    try face.setCharSize(10 * 10, 0, 72, 0);

    try face.loadGlyph(205, .{});
    try face.loadChar('A', .{});

    face.deinit();
}

test "attach file" {
    const lib = try freetype.Library.init();
    const face = try lib.createFace("upstream/assets/DejaVuSans.pfb", 0);
    try face.attachFile("upstream/assets/DejaVuSans.pfm");
}

test "attach from memory" {
    const lib = try freetype.Library.init();
    const face = try lib.createFace("upstream/assets/DejaVuSans.pfb", 0);
    const file = @embedFile("../upstream/assets/DejaVuSans.pfm");
    try face.attachMemory(file);
}

test "charmap iterator" {
    const lib = try freetype.Library.init();
    const face = try lib.createFace(firasans_font_path, 0);
    var iterator = face.getCharmapIterator();
    var old_char: usize = 0;
    while (iterator.next()) |c| {
        try testing.expect(old_char != c);
        old_char = c;
    }
}

test "get name index" {
    const lib = try freetype.Library.init();
    const face = try lib.createFace(firasans_font_path, 0);
    try testing.expectEqual(@as(u32, 1120), face.getNameIndex("summation").?);
}

test "get index name" {
    const lib = try freetype.Library.init();
    const face = try lib.createFace(firasans_font_path, 0);
    var buf: [32]u8 = undefined;
    try face.getGlyphName(1120, &buf);
    try testing.expectEqualStrings(std.mem.sliceTo(&buf, 0), "summation");
}