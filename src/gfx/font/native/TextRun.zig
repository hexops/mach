const std = @import("std");
const ft = @import("ft.zig").c;
const kb = @import("ft.zig").kb;
const math = @import("../../../main.zig").math;
const vec2 = math.vec2;
const Vec2 = math.Vec2;
const Glyph = @import("../main.zig").Glyph;
const px_per_pt = @import("../main.zig").px_per_pt;

const TextRun = @This();

font_size_px: f32 = 16.0,
px_density: u8 = 1,

// Internal / private fields.
context: *kb.kbts_shape_context,
utf8_text: []const u8 = &.{},
run: kb.kbts_run = undefined,
has_run: bool = false,
units_per_em: f32 = undefined,
ft_face: ft.FT_Face = null,

pub fn init() anyerror!TextRun {
    return TextRun{
        .context = kb.kbts_CreateShapeContext(null, null) orelse return error.OutOfMemory,
    };
}

/// utf8_text must remain valid until .deinit() is called.
pub fn addText(s: *TextRun, utf8_text: []const u8) void {
    s.utf8_text = utf8_text;
}

pub fn next(s: *TextRun) ?Glyph {
    while (true) {
        if (s.has_run) {
            var glyph_ptr: ?*kb.kbts_glyph = null;
            if (kb.kbts_GlyphIteratorNext(&s.run.Glyphs, &glyph_ptr) != 0) {
                const glyph = glyph_ptr.?;
                // Scale from font design units to points (not pixels) to match
                // the convention used by FreeType's bearing metrics.
                const font_size_pt = s.font_size_px / px_per_pt;
                const scale = font_size_pt / s.units_per_em;

                // Get FreeType bearing offsets for baseline-relative positioning.
                // kb handles shaping but not rasterization metrics; FreeType's
                // horiBearingX/Y position the bitmap relative to the pen/baseline.
                var bearing_x: f32 = 0;
                var bearing_y: f32 = 0;
                if (ft.FT_Load_Glyph(s.ft_face, glyph.Id, ft.FT_LOAD_DEFAULT) == 0) {
                    const metrics = s.ft_face.*.glyph.*.metrics;
                    bearing_x = @as(f32, @floatFromInt(metrics.horiBearingX)) / 64.0;
                    bearing_y = @as(f32, @floatFromInt(metrics.horiBearingY)) / 64.0;
                }

                return Glyph{
                    .glyph_index = @intCast(glyph.Id),
                    .cluster = @intCast(glyph.UserIdOrCodepointIndex),
                    .advance = vec2(
                        @as(f32, @floatFromInt(glyph.AdvanceX)) * scale,
                        @as(f32, @floatFromInt(glyph.AdvanceY)) * scale,
                    ),
                    .offset = vec2(
                        @as(f32, @floatFromInt(glyph.OffsetX)) * scale + bearing_x,
                        @as(f32, @floatFromInt(glyph.OffsetY)) * scale + bearing_y,
                    ),
                };
            }
        }
        // Try to get the next run.
        if (kb.kbts_ShapeRun(s.context, &s.run) != 0) {
            s.has_run = true;
            continue;
        }
        // No more runs.
        s.has_run = false;
        return null;
    }
}

pub fn deinit(s: *const TextRun) void {
    kb.kbts_DestroyShapeContext(s.context);
}
