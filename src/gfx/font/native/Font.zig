const std = @import("std");
const ft = @import("mach-freetype");
const harfbuzz = @import("mach-harfbuzz");
const TextRun = @import("TextRun.zig");
const px_per_pt = @import("../main.zig").px_per_pt;
const RenderedGlyph = @import("../main.zig").RenderedGlyph;
const RenderOptions = @import("../main.zig").RenderOptions;
const RGBA32 = @import("../main.zig").RGBA32;

const Font = @This();

var freetype_ready_mu: std.Thread.Mutex = .{};
var freetype_ready: bool = false;
var freetype: ft.Library = undefined;

face: ft.Face,
bitmap: std.ArrayListUnmanaged(RGBA32) = .{},

pub fn initFreetype() !void {
    freetype_ready_mu.lock();
    defer freetype_ready_mu.unlock();
    if (!freetype_ready) {
        freetype = try ft.Library.init();
        freetype_ready = true;
    }
}

pub fn initBytes(font_bytes: []const u8) anyerror!Font {
    try initFreetype();
    return .{
        .face = try freetype.createFaceMemory(font_bytes, 0),
    };
}

pub fn shape(f: *const Font, r: *TextRun) anyerror!void {
    // Guess text segment properties.
    r.buffer.guessSegmentProps();
    // TODO: Optionally override specific text segment properties?
    // r.buffer.setDirection(.ltr);
    // r.buffer.setScript(.latin);
    // r.buffer.setLanguage(harfbuzz.Language.fromString("en"));

    const font_size_pt = r.font_size_px / px_per_pt;
    const font_size_pt_frac: i32 = @intFromFloat(font_size_pt * 64.0);
    f.face.setCharSize(font_size_pt_frac, font_size_pt_frac, 0, 0) catch return error.RenderError;

    const hb_face = harfbuzz.Face.fromFreetypeFace(f.face);
    const hb_font = harfbuzz.Font.init(hb_face);
    defer hb_font.deinit();

    hb_font.setScale(font_size_pt_frac, font_size_pt_frac);
    hb_font.setPTEM(font_size_pt);

    // TODO: optionally pass shaping features?
    hb_font.shape(r.buffer, null);

    r.index = 0;
    r.infos = r.buffer.getGlyphInfos();
    r.positions = r.buffer.getGlyphPositions() orelse return error.OutOfMemory;

    for (r.positions, r.infos) |*pos, info| {
        const glyph_index = info.codepoint;
        f.face.loadGlyph(glyph_index, .{ .render = false }) catch return error.RenderError;
        const glyph = f.face.glyph();
        const metrics = glyph.metrics();
        pos.*.x_offset += @intCast(metrics.horiBearingX);
        pos.*.y_offset += @intCast(metrics.horiBearingY);
        // TODO: use vertBearingX / vertBearingY for vertical layouts
    }
}

pub fn render(f: *Font, allocator: std.mem.Allocator, glyph_index: u32, opt: RenderOptions) anyerror!RenderedGlyph {
    _ = opt;
    f.face.loadGlyph(glyph_index, .{ .render = true }) catch return error.RenderError;

    const glyph = f.face.glyph();
    const glyph_bitmap = glyph.bitmap();
    const buffer = glyph_bitmap.buffer();
    const width = glyph_bitmap.width();
    const height = glyph_bitmap.rows();
    const pitch = @as(u32, @intCast(glyph_bitmap.pitch())); // TODO handle negative could be negative
    const margin = 1;

    const dst_width = width + (margin * 2);
    const dst_height = height + (margin * 2);

    if (buffer == null) return RenderedGlyph{
        .bitmap = null,
        .width = dst_width,
        .height = dst_height,
    };

    const num_pixels = dst_width * dst_height;

    // Add 1 pixel padding to texture to avoid bleeding over other textures. This is part of the
    // render() API contract.
    f.bitmap.clearRetainingCapacity();
    // TODO: handle OOM here
    f.bitmap.ensureTotalCapacity(allocator, num_pixels) catch return error.RenderError;
    f.bitmap.resize(allocator, num_pixels) catch return error.RenderError;

    @memset(f.bitmap.items, RGBA32{ .r = 0, .g = 0, .b = 0, .a = 0 });

    for (0..height) |y| {
        const src_row = buffer.?[y * pitch ..][0..width];

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
    f.face.deinit();
    f.bitmap.deinit(allocator);
}
