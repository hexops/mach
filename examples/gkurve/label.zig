//! At the moment we use only rgba32, but maybe it could be useful to use also other types

const std = @import("std");
const mach = @import("mach");
const ft = @import("freetype");
const zigimg = @import("zigimg");
const Atlas = mach.gfx.Atlas;
const AtlasErr = Atlas.Error;
const AtlasUV = Atlas.Region.UV;
const App = @import("main.zig").App;
const draw = @import("draw.zig");

pub const Label = @This();

const Vec2 = @Vector(2, f32);
const Vec4 = @Vector(4, f32);

const GlyphInfo = struct {
    uv_data: AtlasUV,
    metrics: ft.GlyphMetrics,
};

face: ft.Face,
size: i32,
char_map: std.AutoHashMap(u21, GlyphInfo),
allocator: std.mem.Allocator,

const WriterContext = struct {
    label: *Label,
    app: *App,
    position: Vec2,
    text_color: Vec4,
};
const WriterError = ft.Error || std.mem.Allocator.Error || AtlasErr;
const Writer = std.io.Writer(WriterContext, WriterError, write);

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

pub fn init(lib: ft.Library, font_path: [*:0]const u8, face_index: i32, char_size: i32, allocator: std.mem.Allocator) !Label {
    return Label{
        .face = try lib.createFace(font_path, face_index),
        .size = char_size,
        .char_map = std.AutoHashMap(u21, GlyphInfo).init(allocator),
        .allocator = allocator,
    };
}

pub fn deinit(label: *Label) void {
    label.face.deinit();
    label.char_map.deinit();
}

fn write(ctx: WriterContext, bytes: []const u8) WriterError!usize {
    var offset = Vec2{ 0, 0 };
    var j: usize = 0;
    while (j < bytes.len) {
        const len = std.unicode.utf8ByteSequenceLength(bytes[j]) catch unreachable;
        const char = std.unicode.utf8Decode(bytes[j..(j + len)]) catch unreachable;
        j += len;
        switch (char) {
            '\n' => {
                offset[0] = 0;
                offset[1] -= @as(f32, @floatFromInt(ctx.label.face.size().metrics().height >> 6));
            },
            ' ' => {
                const v = try ctx.label.char_map.getOrPut(char);
                if (!v.found_existing) {
                    try ctx.label.face.setCharSize(ctx.label.size * 64, 0, 50, 0);
                    try ctx.label.face.loadChar(char, .{ .render = true });
                    const glyph = ctx.label.face.glyph();
                    v.value_ptr.* = GlyphInfo{
                        .uv_data = undefined,
                        .metrics = glyph.metrics(),
                    };
                }
                offset[0] += @as(f32, @floatFromInt(v.value_ptr.metrics.horiAdvance >> 6));
            },
            else => {
                const v = try ctx.label.char_map.getOrPut(char);
                if (!v.found_existing) {
                    try ctx.label.face.setCharSize(ctx.label.size * 64, 0, 50, 0);
                    try ctx.label.face.loadChar(char, .{ .render = true });
                    const glyph = ctx.label.face.glyph();
                    const glyph_bitmap = glyph.bitmap();
                    const glyph_width = glyph_bitmap.width();
                    const glyph_height = glyph_bitmap.rows();

                    // Add 1 pixel padding to texture to avoid bleeding over other textures
                    const glyph_data = try ctx.label.allocator.alloc(zigimg.color.Rgba32, (glyph_width + 2) * (glyph_height + 2));
                    defer ctx.label.allocator.free(glyph_data);
                    const glyph_buffer = glyph_bitmap.buffer().?;
                    for (glyph_data, 0..) |*data, i| {
                        const x = i % (glyph_width + 2);
                        const y = i / (glyph_width + 2);

                        // zig fmt: off
                        const glyph_col =
                            if (x == 0 or x == (glyph_width + 1) or y == 0 or y == (glyph_height + 1))
                                0
                            else
                                glyph_buffer[(y - 1) * glyph_width + (x - 1)];
                        // zig fmt: on

                        data.* = zigimg.color.Rgba32.initRgb(glyph_col, glyph_col, glyph_col);
                    }
                    var glyph_atlas_region = try ctx.app.texture_atlas_data.reserve(ctx.label.allocator, glyph_width + 2, glyph_height + 2);
                    ctx.app.texture_atlas_data.set(glyph_atlas_region, @as([*]const u8, @ptrCast(glyph_data.ptr))[0 .. glyph_data.len * 4]);

                    glyph_atlas_region.x += 1;
                    glyph_atlas_region.y += 1;
                    glyph_atlas_region.width -= 2;
                    glyph_atlas_region.height -= 2;

                    v.value_ptr.* = GlyphInfo{
                        .uv_data = glyph_atlas_region.calculateUV(ctx.app.texture_atlas_data.size),
                        .metrics = glyph.metrics(),
                    };
                }

                try draw.quad(
                    ctx.app,
                    ctx.position + offset + Vec2{ @as(f32, @floatFromInt(v.value_ptr.metrics.horiBearingX >> 6)), @as(f32, @floatFromInt((v.value_ptr.metrics.horiBearingY - v.value_ptr.metrics.height) >> 6)) },
                    .{ @as(f32, @floatFromInt(v.value_ptr.metrics.width >> 6)), @as(f32, @floatFromInt(v.value_ptr.metrics.height >> 6)) },
                    .{ .blend_color = ctx.text_color },
                    v.value_ptr.uv_data,
                );
                offset[0] += @as(f32, @floatFromInt(v.value_ptr.metrics.horiAdvance >> 6));
            },
        }
    }
    return bytes.len;
}

pub fn print(label: *Label, app: *App, comptime fmt: []const u8, args: anytype, position: Vec2, text_color: Vec4) !void {
    const w = writer(label, app, position, text_color);
    try w.print(fmt, args);
}
