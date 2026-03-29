pub const c = @cImport({
    @cInclude("ft2build.h");
    @cInclude("freetype/freetype.h");
});

pub const kb = @cImport({
    @cInclude("kb_text_shape.h");
});
