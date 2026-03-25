const std = @import("std");
const c = @cImport({
    @cInclude("ft2build.h");
    @cInclude("freetype/freetype.h");
    @cInclude("harfbuzz/hb.h");
    @cInclude("harfbuzz/hb-ft.h");
});
const TextRun = @import("TextRun.zig");
const px_per_pt = @import("../main.zig").px_per_pt;
const RenderedGlyph = @import("../main.zig").RenderedGlyph;
const RenderOptions = @import("../main.zig").RenderOptions;
const RGBA32 = @import("../main.zig").RGBA32;

const Font = @This();

var freetype_ready_mu: std.Thread.Mutex = .{};
var freetype_ready: bool = false;
var ft_library: c.FT_Library = null;

face: c.FT_Face,
bitmap: std.ArrayListUnmanaged(RGBA32) = .{},

pub fn initFreetype() !void {
    freetype_ready_mu.lock();
    defer freetype_ready_mu.unlock();
    if (!freetype_ready) {
        if (c.FT_Init_FreeType(&ft_library) != 0) return error.FreetypeInitFailed;
        freetype_ready = true;
    }
}

pub fn initBytes(font_bytes: []const u8) anyerror!Font {
    try initFreetype();
    var face: c.FT_Face = null;
    if (c.FT_New_Memory_Face(ft_library, font_bytes.ptr, @intCast(font_bytes.len), 0, &face) != 0)
        return error.FreetypeError;
    return .{ .face = face };
}

pub fn shape(f: *const Font, r: *TextRun) anyerror!void {
    // Guess text segment properties.
    c.hb_buffer_guess_segment_properties(r.buffer);
    // TODO: Optionally override specific text segment properties?
    // hb_buffer_set_direction(r.buffer, ...);
    // hb_buffer_set_script(r.buffer, ...);
    // hb_buffer_set_language(r.buffer, hb_language_from_string("en", -1));

    const font_size_pt = r.font_size_px / px_per_pt;
    const font_size_pt_frac: i32 = @intFromFloat(font_size_pt * 64.0);
    if (c.FT_Set_Char_Size(f.face, font_size_pt_frac, font_size_pt_frac, 0, 0) != 0)
        return error.RenderError;

    const hb_face = c.hb_ft_face_create_referenced(f.face) orelse return error.RenderError;
    const hb_font = c.hb_font_create(hb_face) orelse return error.RenderError;
    defer c.hb_font_destroy(hb_font);

    c.hb_font_set_scale(hb_font, font_size_pt_frac, font_size_pt_frac);
    c.hb_font_set_ptem(hb_font, font_size_pt);

    // TODO: optionally pass shaping features?
    c.hb_shape(hb_font, r.buffer, null, 0);

    r.index = 0;
    var info_count: u32 = 0;
    const infos_ptr = c.hb_buffer_get_glyph_infos(r.buffer, &info_count);
    r.infos = if (infos_ptr) |p| p[0..info_count] else return error.OutOfMemory;

    var pos_count: u32 = 0;
    const pos_ptr = c.hb_buffer_get_glyph_positions(r.buffer, &pos_count);
    r.positions = if (pos_ptr) |p| p[0..pos_count] else return error.OutOfMemory;

    for (r.positions, r.infos) |*pos, info| {
        const glyph_index = info.codepoint;
        if (c.FT_Load_Glyph(f.face, glyph_index, c.FT_LOAD_DEFAULT) != 0)
            return error.RenderError;
        const glyph = f.face.*.glyph;
        const metrics = glyph.*.metrics;
        pos.*.x_offset += @intCast(metrics.horiBearingX);
        pos.*.y_offset += @intCast(metrics.horiBearingY);
        // TODO: use vertBearingX / vertBearingY for vertical layouts
    }
}

pub fn render(f: *Font, allocator: std.mem.Allocator, glyph_index: u32, opt: RenderOptions) anyerror!RenderedGlyph {
    _ = opt;
    if (c.FT_Load_Glyph(f.face, glyph_index, c.FT_LOAD_RENDER) != 0)
        return error.RenderError;

    const glyph = f.face.*.glyph;
    const glyph_bitmap = glyph.*.bitmap;
    const buffer: ?[*]const u8 = glyph_bitmap.buffer;
    const width = glyph_bitmap.width;
    const height = glyph_bitmap.rows;
    const margin = 1;

    if (buffer == null) return RenderedGlyph{
        .bitmap = null,
        .width = width + (margin * 2),
        .height = height + (margin * 2),
    };

    // Add 1 pixel padding to texture to avoid bleeding over other textures. This is part of the
    // render() API contract.
    f.bitmap.clearRetainingCapacity();
    const num_pixels = (width + (margin * 2)) * (height + (margin * 2));
    // TODO: handle OOM here
    f.bitmap.ensureTotalCapacity(allocator, num_pixels) catch return error.RenderError;
    f.bitmap.resize(allocator, num_pixels) catch return error.RenderError;
    for (f.bitmap.items, 0..) |*data, i| {
        const x = i % (width + (margin * 2));
        const y = i / (width + (margin * 2));
        if (x < margin or x > (width + margin) or y < margin or y > (height + margin)) {
            data.* = RGBA32{ .r = 0, .g = 0, .b = 0, .a = 0 };
        } else {
            const alpha = buffer.?[((y - margin) * width + (x - margin)) % (glyph_bitmap.pitch * height)];
            data.* = RGBA32{ .r = 0, .g = 0, .b = 0, .a = alpha };
        }
    }

    return RenderedGlyph{
        .bitmap = f.bitmap.items,
        .width = width + (margin * 2),
        .height = height + (margin * 2),
    };
}

pub fn deinit(f: *Font, allocator: std.mem.Allocator) void {
    _ = c.FT_Done_Face(f.face);
    f.bitmap.deinit(allocator);
}
