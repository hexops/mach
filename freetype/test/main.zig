const testing = @import("std").testing;
const freetype = @import("freetype");

const test_option = @import("test_option");
const firasans_font_path = "upstream/assets/FiraSans-Regular.ttf";
const firasans_font_data = test_option.font;

// Remove once the stage2 compiler fixes pkg std not found
comptime {
    _ = @import("utils");
}

test "new face from file" {
    const lib = try freetype.Library.init();
    _ = try lib.newFace(firasans_font_path, 0);
}

test "new face from memory" {
    const lib = try freetype.Library.init();
    _ = try lib.newFaceMemory(firasans_font_data, 0);
}

test "new stroker" {
    const lib = try freetype.Library.init();
    _ = try lib.newStroker();
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
    const face = try lib.newFace(firasans_font_path, 0);

    try face.setPixelSizes(100, 100);
    try face.setCharSize(10 * 10, 0, 72, 0);

    try face.loadGlyph(205, .{});
    try face.loadChar('A', .{});

    face.deinit();
}

test "attach file" {
    const lib = try freetype.Library.init();
    const face = try lib.newFace("upstream/assets/DejaVuSans.pfb", 0);
    try face.attachFile("upstream/assets/DejaVuSans.pfm");
}

test "attach from memory" {
    const lib = try freetype.Library.init();
    const face = try lib.newFace("upstream/assets/DejaVuSans.pfb", 0);
    const file = test_option.file;
    try face.attachMemory(file);
}

test "charmap iterator" {
    const lib = try freetype.Library.init();
    const face = try lib.newFace(firasans_font_path, 0);
    var iterator = face.getCharmapIterator();
    var old_char: usize = 0;
    while (iterator.next()) |c| {
        try testing.expect(old_char != c);
        old_char = c;
    }
}

test "get name index" {
    const lib = try freetype.Library.init();
    const face = try lib.newFace(firasans_font_path, 0);
    try testing.expectEqual(@as(u32, 1120), face.getNameIndex("summation").?);
}

test "get index name" {
    const lib = try freetype.Library.init();
    const face = try lib.newFace(firasans_font_path, 0);
    var name_buf: [30]u8 = undefined;
    try testing.expectEqualStrings("summation", try face.getGlyphName(1120, &name_buf));
}
