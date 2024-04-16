// TODO(important): review all code in this file in-depth
const mach = @import("mach");
const gpu = mach.gpu;
const ft = @import("freetype");
const std = @import("std");
const assets = @import("assets");

pub const name = .glyphs;
pub const Mod = mach.Mod(@This());

pub const global_events = .{
    .deinit = .{ .handler = deinit },
};

pub const local_events = .{
    .init = .{ .handler = init },
    .prepare = .{ .handler = prepare },
};

const RegionMap = std.AutoArrayHashMapUnmanaged(u21, mach.gfx.Atlas.Region);

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

texture_atlas: mach.gfx.Atlas,
texture: *gpu.Texture,
ft: ft.Library,
face: ft.Face,
regions: RegionMap = .{},
allocator: std.mem.Allocator,

fn deinit(glyphs: *Mod) !void {
    const state = glyphs.state();
    state.texture_atlas.deinit(glyphs.state().allocator);
    state.texture.release();
    state.face.deinit();
    state.ft.deinit();
    state.regions.deinit(state.allocator);
}

fn init(
    engine: *mach.Engine.Mod,
    glyphs: *Mod,
) !void {
    const device = engine.state().device;
    const allocator = gpa.allocator();

    // rgba32_pixels
    const img_size = gpu.Extent3D{ .width = 1024, .height = 1024 };

    // Create a GPU texture
    const texture = device.createTexture(&.{
        .size = img_size,
        .format = .rgba8_unorm,
        .usage = .{
            .texture_binding = true,
            .copy_dst = true,
            .render_attachment = true,
        },
    });

    const texture_atlas = try mach.gfx.Atlas.init(
        allocator,
        img_size.width,
        .rgba,
    );

    const ft_lib = try ft.Library.init();
    const face = try ft_lib.createFaceMemory(assets.roboto_medium_ttf, 0);

    glyphs.init(.{
        .texture_atlas = texture_atlas,
        .texture = texture,
        .ft = ft_lib,
        .face = face,
        .allocator = allocator,
    });
}

fn prepare(
    engine: *mach.Engine.Mod,
    glyphs: *Mod,
    codepoints: []const u21,
) !void {
    const device = engine.state().device;
    const queue = device.getQueue();
    var s = glyphs.state();

    for (codepoints) |codepoint| {
        const font_size = 48 * 1;
        try s.face.setCharSize(font_size * 64, 0, 50, 0);
        try s.face.loadChar(codepoint, .{ .render = true });
        const glyph = s.face.glyph();
        const metrics = glyph.metrics();

        const glyph_bitmap = glyph.bitmap();
        const glyph_width = glyph_bitmap.width();
        const glyph_height = glyph_bitmap.rows();

        // Add 1 pixel padding to texture to avoid bleeding over other textures
        const margin = 1;
        const glyph_data = try s.allocator.alloc([4]u8, (glyph_width + (margin * 2)) * (glyph_height + (margin * 2)));
        defer s.allocator.free(glyph_data);
        const glyph_buffer = glyph_bitmap.buffer().?;
        for (glyph_data, 0..) |*data, i| {
            const x = i % (glyph_width + (margin * 2));
            const y = i / (glyph_width + (margin * 2));
            if (x < margin or x > (glyph_width + margin) or y < margin or y > (glyph_height + margin)) {
                data.* = [4]u8{ 0, 0, 0, 0 };
            } else {
                const alpha = glyph_buffer[((y - margin) * glyph_width + (x - margin)) % glyph_buffer.len];
                data.* = [4]u8{ 0, 0, 0, alpha };
            }
        }
        var glyph_atlas_region = try s.texture_atlas.reserve(s.allocator, glyph_width + (margin * 2), glyph_height + (margin * 2));
        s.texture_atlas.set(glyph_atlas_region, @as([*]const u8, @ptrCast(glyph_data.ptr))[0 .. glyph_data.len * 4]);

        glyph_atlas_region.x += margin;
        glyph_atlas_region.y += margin;
        glyph_atlas_region.width -= margin * 2;
        glyph_atlas_region.height -= margin * 2;

        try s.regions.put(s.allocator, codepoint, glyph_atlas_region);
        _ = metrics;
    }

    // rgba32_pixels
    const img_size = gpu.Extent3D{ .width = 1024, .height = 1024 };
    const data_layout = gpu.Texture.DataLayout{
        .bytes_per_row = @as(u32, @intCast(img_size.width * 4)),
        .rows_per_image = @as(u32, @intCast(img_size.height)),
    };
    queue.writeTexture(&.{ .texture = s.texture }, &data_layout, &img_size, s.texture_atlas.data);
}
