const freetype = @import("freetype");

const firasnas_font_path = "test/assets/FiraSans-Regular.ttf";
const firasnas_font_data = @embedFile("assets/FiraSans-Regular.ttf");

test "new face from file" {
    const lib = try freetype.Library.init();
    _ = try lib.newFace(firasnas_font_path, 0);
}

test "new face from memory" {
    const lib = try freetype.Library.init();
    _ = try lib.newFaceMemory(firasnas_font_data, 0);
}

test "new stroker" {
    const lib = try freetype.Library.init();
    _ = try lib.newStroker();
}

test "set lcd filter" {
    if (@hasDecl(freetype.C, "FT_CONFIG_OPTION_SUBPIXEL_RENDERING")) {
        const lib = try freetype.Library.init();
        try lib.setLcdFilter(.default);
    } else {
        return error.SkipZigTest;
    }
}

test "load glyph" {
    const lib = try freetype.Library.init();
    const face = try lib.newFace(firasnas_font_path, 0);

    try face.setPixelSizes(100, 100);
    try face.setCharSize(10 * 10, 0, 72, 0);

    try face.loadGlyph(205, .{});
    try face.loadChar('A', .{});

    face.deinit();
}

test "attach file" {
    const lib = try freetype.Library.init();
    const face = try lib.newFace("test/assets/DejaVuSans.pfb", 0);
    try face.attachFile("test/assets/DejaVuSans.pfm");
}

test "attach from memory" {
    const lib = try freetype.Library.init();
    const face = try lib.newFace("test/assets/DejaVuSans.pfb", 0);
    const file = @embedFile("assets/DejaVuSans.pfm");
    try face.attachMemory(file);
}
