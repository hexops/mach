const mach = @import("mach");
const gpu = mach.gpu;
const ecs = mach.ecs;
const ft = @import("freetype");
const std = @import("std");
const assets = @import("assets");

pub const name = .game_text;
pub const Mod = mach.Mod(@This());

pub const events = .{
    .{ .global = .deinit, .handler = deinit },
    .{ .global = .init, .handler = init },
    .{ .local = .prepare, .handler = prepare },
};

const RegionMap = std.AutoArrayHashMapUnmanaged(u21, mach.gfx.Atlas.Region);

texture_atlas: mach.gfx.Atlas,
texture: *gpu.Texture,
ft: ft.Library,
face: ft.Face,
regions: RegionMap = .{},

fn deinit(
    engine: *mach.Engine.Mod,
    text_mod: *Mod,
) !void {
    text_mod.state.texture_atlas.deinit(engine.allocator);
    text_mod.state.texture.release();
    text_mod.state.face.deinit();
    text_mod.state.ft.deinit();
    text_mod.state.regions.deinit(engine.allocator);
}

fn init(
    engine: *mach.Engine.Mod,
    text_mod: *Mod,
) !void {
    const device = engine.state.device;

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

    var s = &text_mod.state;
    s.texture = texture;
    s.texture_atlas = try mach.gfx.Atlas.init(
        engine.allocator,
        img_size.width,
        .rgba,
    );

    // TODO: state fields' default values do not work
    s.regions = .{};

    s.ft = try ft.Library.init();
    s.face = try s.ft.createFaceMemory(assets.roboto_medium_ttf, 0);

    text_mod.send(.prepare, .{ .@"0" = &[_]u21{ '?', '!', 'a', 'b', '#', '@', '%', '$', '&', '^', '*', '+', '=', '<', '>', '/', ':', ';', 'Q', '~' } });
}

fn prepare(
    engine: *mach.Engine.Mod,
    text_mod: *Mod,
    codepoints: []const u21,
) !void {
    const device = engine.state.device;
    const queue = device.getQueue();
    var s = &text_mod.state;

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
        const glyph_data = try engine.allocator.alloc([4]u8, (glyph_width + (margin * 2)) * (glyph_height + (margin * 2)));
        defer engine.allocator.free(glyph_data);
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
        var glyph_atlas_region = try s.texture_atlas.reserve(engine.allocator, glyph_width + (margin * 2), glyph_height + (margin * 2));
        s.texture_atlas.set(glyph_atlas_region, @as([*]const u8, @ptrCast(glyph_data.ptr))[0 .. glyph_data.len * 4]);

        glyph_atlas_region.x += margin;
        glyph_atlas_region.y += margin;
        glyph_atlas_region.width -= margin * 2;
        glyph_atlas_region.height -= margin * 2;

        try s.regions.put(engine.allocator, codepoint, glyph_atlas_region);
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
