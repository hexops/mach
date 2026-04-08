const std = @import("std");
const ft = @import("ft.zig").c;
const kb = @import("ft.zig").kb;
const TextRun = @import("TextRun.zig");
const px_per_pt = @import("../main.zig").px_per_pt;
const RenderedGlyph = @import("../main.zig").RenderedGlyph;
const RenderOptions = @import("../main.zig").RenderOptions;
const RGBA32 = @import("../main.zig").RGBA32;

const Font = @This();

var freetype_ready_mu: std.Thread.Mutex = .{};
var freetype_ready: bool = false;
var ft_library: ft.FT_Library = null;

face: ft.FT_Face,
font_bytes: []const u8,
bitmap: std.ArrayListUnmanaged(RGBA32) = .{},

pub fn initFreetype() !void {
    freetype_ready_mu.lock();
    defer freetype_ready_mu.unlock();
    if (!freetype_ready) {
        if (ft.FT_Init_FreeType(&ft_library) != 0) return error.FreetypeInitFailed;
        freetype_ready = true;
    }
}

/// font_bytes must remain valid until .deinit() is called.
pub fn initBytes(font_bytes: []const u8) anyerror!Font {
    try initFreetype();
    var face: ft.FT_Face = null;
    if (ft.FT_New_Memory_Face(ft_library, font_bytes.ptr, @intCast(font_bytes.len), 0, &face) != 0)
        return error.FreetypeError;
    return .{ .face = face, .font_bytes = font_bytes };
}

pub fn shape(f: *Font, r: *TextRun) anyerror!void {
    const kb_font = kb.kbts_ShapePushFontFromMemory(
        r.context,
        @constCast(f.font_bytes.ptr),
        @intCast(f.font_bytes.len),
        0,
    ) orelse return error.RenderError;

    // Get font metrics to know UnitsPerEm for scaling.
    var info: kb.kbts_font_info2_1 = std.mem.zeroes(kb.kbts_font_info2_1);
    info.Base.Size = @sizeOf(kb.kbts_font_info2_1);
    kb.kbts_GetFontInfo2(kb_font, @ptrCast(&info));
    if (info.UnitsPerEm == 0) return error.InvalidFont;
    r.units_per_em = @floatFromInt(info.UnitsPerEm);

    // Set FreeType face size for glyph rendering (still needed for rasterization).
    const font_size_pt = r.font_size_px / px_per_pt;
    const font_size_pt_frac: i32 = @intFromFloat(font_size_pt * 64.0);
    if (ft.FT_Set_Char_Size(f.face, font_size_pt_frac, font_size_pt_frac, 0, 0) != 0)
        return error.RenderError;

    // Store FreeType face for bearing lookups during glyph iteration.
    r.ft_face = f.face;

    // Perform the full shaping pass: begin → add text → end.
    // TODO(font): allow configuration of direction/language by user
    kb.kbts_ShapeBegin(r.context, kb.KBTS_DIRECTION_DONT_KNOW, kb.KBTS_LANGUAGE_DONT_KNOW);
    kb.kbts_ShapeUtf8(r.context, r.utf8_text.ptr, @intCast(r.utf8_text.len), kb.KBTS_USER_ID_GENERATION_MODE_CODEPOINT_INDEX);
    kb.kbts_ShapeEnd(r.context);
}

pub fn render(f: *Font, allocator: std.mem.Allocator, glyph_index: u32, opt: RenderOptions) anyerror!RenderedGlyph {
    _ = opt;
    if (ft.FT_Load_Glyph(f.face, glyph_index, ft.FT_LOAD_RENDER) != 0)
        return error.RenderError;

    const glyph = f.face.*.glyph;
    const glyph_bitmap = glyph.*.bitmap;
    const buffer: ?[*]const u8 = glyph_bitmap.buffer;
    const width = glyph_bitmap.width;
    const height = glyph_bitmap.rows;
    const abs_pitch: u32 = @intCast(@abs(glyph_bitmap.pitch));
    const margin = 1;

    const dst_width = width + (margin * 2);
    const dst_height = height + (margin * 2);

    if (buffer == null) return RenderedGlyph{
        .bitmap = null,
        .width = dst_width,
        .height = dst_height,
    };

    const num_pixels = dst_width * dst_height;

    // If we have negative pitch, rows are stored bottom-to-top. In that case, the buffer pointer
    // still points to the first byte of the bitmap data, but we need to start from the last row
    // and work backwards.
    const src: [*]const u8 = if (glyph_bitmap.pitch >= 0) buffer.? else buffer.? + (height - 1) * abs_pitch;

    // Add 1 pixel padding to texture to avoid bleeding over other textures. This is part of the
    // render() API contract.
    f.bitmap.clearRetainingCapacity();
    // TODO: handle OOM here
    f.bitmap.ensureTotalCapacity(allocator, num_pixels) catch return error.RenderError;
    f.bitmap.resize(allocator, num_pixels) catch return error.RenderError;

    @memset(f.bitmap.items, RGBA32{ .r = 0, .g = 0, .b = 0, .a = 0 });

    for (0..height) |y| {
        const src_row = if (glyph_bitmap.pitch >= 0) src[y * abs_pitch ..][0..width] else (src - y * abs_pitch)[0..width];
        const dst_y = y + margin;
        const dst_row_start = (dst_y * dst_width) + margin;
        const dst_row = f.bitmap.items[dst_row_start..][0..width];

        for (0..width) |x| {
            const alpha = src_row[x];
            dst_row[x] = RGBA32{ .r = 255, .g = 255, .b = 255, .a = alpha };
        }
    }

    return RenderedGlyph{
        .bitmap = f.bitmap.items,
        .width = dst_width,
        .height = dst_height,
    };
}

pub fn deinit(f: *Font, allocator: std.mem.Allocator) void {
    _ = ft.FT_Done_Face(f.face);
    f.bitmap.deinit(allocator);
}
