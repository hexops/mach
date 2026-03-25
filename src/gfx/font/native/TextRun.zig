const std = @import("std");
const c = @cImport({
    @cInclude("harfbuzz/hb.h");
});
const math = @import("../../../main.zig").math;
const vec2 = math.vec2;
const Vec2 = math.Vec2;
const Glyph = @import("../main.zig").Glyph;

const TextRun = @This();

font_size_px: f32 = 16.0,
px_density: u8 = 1,

// Internal / private fields.
buffer: *c.hb_buffer_t,
index: usize = 0,
infos: []c.hb_glyph_info_t = undefined,
positions: []c.hb_glyph_position_t = undefined,

pub fn init() anyerror!TextRun {
    return TextRun{
        .buffer = c.hb_buffer_create() orelse return error.OutOfMemory,
    };
}

pub fn addText(s: *const TextRun, utf8_text: []const u8) void {
    c.hb_buffer_add_utf8(s.buffer, utf8_text.ptr, @intCast(utf8_text.len), 0, @intCast(utf8_text.len));
}

pub fn next(s: *TextRun) ?Glyph {
    if (s.index >= s.infos.len) return null;
    const info = s.infos[s.index];
    const pos = s.positions[s.index];
    s.index += 1;
    return Glyph{
        .glyph_index = info.codepoint,
        // TODO: should we expose this? Is there a browser equivalent? do we need it?
        // .var1 = @intCast(info.var1),
        // .var2 = @intCast(info.var2),
        .cluster = info.cluster,
        .advance = vec2(@floatFromInt(pos.x_advance), @floatFromInt(pos.y_advance)).div(&Vec2.splat(64.0)),
        .offset = vec2(@floatFromInt(pos.x_offset), @floatFromInt(pos.y_offset)).div(&Vec2.splat(64.0)),
    };
}

pub fn deinit(s: *const TextRun) void {
    c.hb_buffer_destroy(s.buffer);
}
