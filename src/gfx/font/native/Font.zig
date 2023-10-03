const std = @import("std");
const ft = @import("mach-freetype");
const harfbuzz = @import("mach-harfbuzz");
const TextRun = @import("TextRun.zig");
const px_per_pt = @import("../main.zig").px_per_pt;

const Font = @This();

var freetype_ready_mu: std.Thread.Mutex = .{};
var freetype_ready: bool = false;
var freetype: ft.Library = undefined;

face: ft.Face,

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
    // buffer.setDirection(.ltr);
    // buffer.setScript(.latin);
    // buffer.setLanguage(harfbuzz.Language.fromString("en"));

    const hb_face = harfbuzz.Face.fromFreetypeFace(f.face);
    const hb_font = harfbuzz.Font.init(hb_face);
    defer hb_font.deinit();

    const font_size_pt = @as(f32, @floatFromInt(r.font_size_px)) / px_per_pt;
    hb_font.setScale(@as(i32, @intFromFloat(font_size_pt)) * 256, @as(i32, @intFromFloat(font_size_pt)) * 256);
    hb_font.setPTEM(font_size_pt);

    // TODO: optionally pass shaping features?
    hb_font.shape(r.buffer, null);

    r.index = 0;
    r.infos = r.buffer.getGlyphInfos();
    r.positions = r.buffer.getGlyphPositions() orelse return error.OutOfMemory;
}

pub fn deinit(f: *const Font) void {
    f.face.deinit();
}
