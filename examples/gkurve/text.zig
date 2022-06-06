//! At the moment we use only rgba32, but maybe it could be useful to use also other types

const std = @import("std");
const ft = @import("freetype");
const zigimg = @import("zigimg");
const Atlas = @import("atlas.zig").Atlas;
const UVData = @import("atlas.zig").UVData;
const App = @import("main.zig").App;
const draw = @import("draw.zig");

pub const Label = @This();

const Vec2 = @Vector(2, f32);
const Vec4 = @Vector(4, f32);

const GlyphInfo = struct {
    uv_data: UVData,
    metrics: ft.GlyphMetrics,
};

face: ft.Face,
size: i32,
char_map: std.AutoHashMap(u8, GlyphInfo),
allocator: std.mem.Allocator,

const WriterContext = struct {
    label: *Label,
    app: *App,
    position: Vec2,
    text_color: Vec4,
};
const Writer = std.io.Writer(WriterContext, ft.Error, write);

pub fn writer(label: *Label, app: *App, position: Vec2, text_color: Vec4) Writer {
    return Writer{
        .context = .{
            .label = label,
            .app = app,
            .position = position,
            .text_color = text_color,
        },
    };
}

pub fn init(lib: ft.Library, font_path: []const u8, face_index: i32, char_size: i32, allocator: std.mem.Allocator) !Label {
    return Label{
        .face = try lib.newFace(font_path, face_index),
        .size = char_size,
        .char_map = std.AutoHashMap(u8, GlyphInfo).init(allocator),
        .allocator = allocator,
    };
}

pub fn deinit(label: *Label) void {
    label.face.deinit();
    label.char_map.deinit();
}

// FIXME: union ft.error and hashmap error
fn write(ctx: WriterContext, bytes: []const u8) ft.Error!usize {
    var offset = Vec2{ 0, 0 };
    for (bytes) |char| {
        switch (char) {
            '\n' => {
                offset[0] = 0;
                offset[1] -= @intToFloat(f32, ctx.label.face.size().metrics().height >> 6);
            },
            ' ' => {
                const v = ctx.label.char_map.getOrPut(char) catch unreachable;
                if (!v.found_existing) {
                    try ctx.label.face.setCharSize(ctx.label.size * 64, 0, 50, 0);
                    try ctx.label.face.loadChar(char, .{ .render = true });
                    const glyph = ctx.label.face.glyph;
                    v.value_ptr.* = GlyphInfo{
                        .uv_data = undefined,
                        .metrics = glyph().metrics(),
                    };
                }
                offset[0] += @intToFloat(f32, v.value_ptr.metrics.horiAdvance >> 6);
            },
            else => {
                const v = ctx.label.char_map.getOrPut(char) catch unreachable;
                if (!v.found_existing) {
                    try ctx.label.face.setCharSize(ctx.label.size * 64, 0, 50, 0);
                    try ctx.label.face.loadChar(char, .{ .render = true });
                    const glyph = ctx.label.face.glyph();
                    const glyph_bitmap = glyph.bitmap();
                    const glyph_width = glyph_bitmap.width();
                    const glyph_height = glyph_bitmap.rows();
                    var glyph_data = ctx.label.allocator.alloc(zigimg.color.Rgba32, glyph_width * glyph_height) catch unreachable;
                    defer ctx.label.allocator.free(glyph_data);
                    const glyph_buffer = glyph_bitmap.buffer();
                    for (glyph_data) |*data, i| {
                        const x = i % glyph_width;
                        const y = i / glyph_width;
                        const glyph_col = glyph_buffer[y * glyph_width + x];
                        data.* = zigimg.color.Rgba32.initRGB(glyph_col, glyph_col, glyph_col);
                    }
                    const glyph_atlas_region = ctx.app.texture_atlas_data.reserve(ctx.label.allocator, glyph_width, glyph_height) catch unreachable;
                    const glyph_uv_data = glyph_atlas_region.getUVData(@intToFloat(f32, ctx.app.texture_atlas_data.size));
                    ctx.app.texture_atlas_data.set(glyph_atlas_region, glyph_data);

                    v.value_ptr.* = GlyphInfo{
                        .uv_data = glyph_uv_data,
                        .metrics = glyph.metrics(),
                    };
                }
                draw.quad(
                    ctx.app,
                    ctx.position + offset + Vec2{ @intToFloat(f32, v.value_ptr.metrics.horiBearingX >> 6), @intToFloat(f32, (v.value_ptr.metrics.horiBearingY - v.value_ptr.metrics.height) >> 6) },
                    .{ @intToFloat(f32, v.value_ptr.metrics.width >> 6), @intToFloat(f32, v.value_ptr.metrics.height >> 6) },
                    .{ .blend_color = ctx.text_color },
                    v.value_ptr.uv_data,
                ) catch unreachable;
                offset[0] += @intToFloat(f32, v.value_ptr.metrics.horiAdvance >> 6);
            },
        }
    }
    return bytes.len;
}

pub fn print(label: *Label, app: *App, comptime fmt: []const u8, args: anytype, position: Vec2, text_color: Vec4) !void {
    const w = writer(label, app, position, text_color);
    try w.print(fmt, args);
}
