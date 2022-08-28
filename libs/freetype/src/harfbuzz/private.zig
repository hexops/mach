const freetype = @import("freetype");
const c = @import("c.zig");
pub extern fn hb_ft_face_create_referenced(ft_face: freetype.c.FT_Face) ?*c.hb_face_t;
pub extern fn hb_ft_font_create_referenced(ft_face: freetype.c.FT_Face) ?*c.hb_font_t;
pub extern fn hb_ft_font_get_face(font: ?*c.hb_font_t) freetype.c.FT_Face;
