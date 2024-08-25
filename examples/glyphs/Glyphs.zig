const mach = @import("mach");
const gpu = mach.gpu;
const ft = @import("freetype");
const std = @import("std");
const assets = @import("assets");

pub const name = .glyphs;
pub const Mod = mach.Mod(@This());

pub const systems = .{
    .init = .{ .handler = init },
    .deinit = .{ .handler = deinit },
    .prepare = .{ .handler = prepare },
};

const RegionMap = std.AutoArrayHashMapUnmanaged(u21, mach.gfx.Atlas.Region);

// TODO: banish global allocator
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
    core: *mach.Core.Mod,
    glyphs: *Mod,
) !void {
    const device = core.state().device;
    const allocator = gpa.allocator();

    // rgba32_pixels
    const img_size = gpu.Extent3D{ .width = 1024, .height = 1024 };

    // Create a GPU texture
    const label = @tagName(name) ++ ".init";
    const texture = device.createTexture(&.{
        .label = label,
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

fn prepare(core: *mach.Core.Mod, glyphs: *Mod) !void {
    var s = glyphs.state();

    // Prepare which glyphs we will render
    const codepoints: []const u21 = &[_]u21{ '?', '!', 'a', 'b', '#', '@', '%', '$', '&', '^', '*', '+', '=', '<', '>', '/', ':', ';', 'Q', '~' };
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
    core.state().queue.writeTexture(&.{ .texture = s.texture }, &data_layout, &img_size, s.texture_atlas.data);
}
