const std = @import("std");
const mach = @import("mach");
const freetype = @import("freetype");
const assets = @import("assets");

const gpu = mach.gpu;
const gfx = mach.gfx;
const math = mach.math;

const vec2 = math.vec2;
const vec3 = math.vec3;
const Vec2 = math.Vec2;
const Vec3 = math.Vec3;
const Mat3x3 = math.Mat3x3;
const Mat4x4 = math.Mat4x4;

const App = @This();

pub const mach_module = .app;

pub const mach_systems = .{ .main, .init, .deinit, .tick };

const RegionMap = std.AutoArrayHashMapUnmanaged(u21, mach.gfx.Atlas.Region);

allocator: std.mem.Allocator,
window: mach.ObjectID,
timer: mach.time.Timer,
spawn_timer: mach.time.Timer,
fps_timer: mach.time.Timer,
rand: std.Random.DefaultPrng,

frame_count: usize = 0,
sprites: usize = 0,
time: f32 = 0,
direction: Vec2 = vec2(0, 0),
spawning: bool = true,
player_id: mach.ObjectID = undefined,
pipeline_id: mach.ObjectID = undefined,
texture_atlas: mach.gfx.Atlas = undefined,
texture: *gpu.Texture = undefined,
ft: freetype.Library = undefined,
face: freetype.Face = undefined,
regions: RegionMap = .{},

pub const main = mach.schedule(.{
    .{ mach.Core, .init },
    .{ App, .init },
    .{ mach.Core, .main },
});

pub fn init(
    app: *App,
    core: *mach.Core,
    app_mod: mach.Mod(App),
) !void {
    core.on_tick = app_mod.id.tick;
    core.on_exit = app_mod.id.deinit;

    const window = try core.windows.new(.{
        .title = "glyphs",
    });

    // TODO(allocator): find a better way to get an allocator here
    const allocator = std.heap.c_allocator;

    app.* = .{
        .allocator = allocator,
        .window = window,
        .timer = try mach.time.Timer.start(),
        .spawn_timer = try mach.time.Timer.start(),
        .fps_timer = try mach.time.Timer.start(),
        .rand = std.Random.DefaultPrng.init(1337),
    };
}

pub fn deinit(app: *App) void {
    app.texture_atlas.deinit(app.allocator);
    app.texture.release();
    app.face.deinit();
    app.ft.deinit();
    app.regions.deinit(app.allocator);
}

fn setupPipeline(
    core: *mach.Core,
    app: *App,
    sprite: *gfx.Sprite,
    window_id: mach.ObjectID,
) !void {
    const window = core.windows.getValue(app.window);

    // rgba32_pixels
    const img_size = gpu.Extent3D{ .width = 1024, .height = 1024 };

    // Create a GPU texture
    const label = @tagName(mach_module) ++ ".createPipeline";
    app.texture = window.device.createTexture(&.{
        .label = label,
        .size = img_size,
        .format = .rgba8_unorm,
        .usage = .{
            .texture_binding = true,
            .copy_dst = true,
            .render_attachment = true,
        },
    });

    app.texture_atlas = try mach.gfx.Atlas.init(
        app.allocator,
        img_size.width,
        .rgba,
    );

    app.ft = try freetype.Library.init();
    app.face = try app.ft.createFaceMemory(assets.roboto_medium_ttf, 0);
    try prepareGlyphs(window.queue, app);

    // Create a sprite rendering pipeline
    app.pipeline_id = try sprite.pipelines.new(.{
        .window = window_id,
        .render_pass = undefined,
        .texture = app.texture,
    });

    // Create our player sprite
    const r = app.regions.get('?').?;
    app.player_id = try sprite.objects.new(.{
        .transform = Mat4x4.translate(vec3(-0.02, 0, 0)),
        .size = vec2(@floatFromInt(r.width), @floatFromInt(r.height)),
        .uv_transform = Mat3x3.translate(vec2(@floatFromInt(r.x), @floatFromInt(r.y))),
    });
    // Attach the sprite to our sprite rendering pipeline.
    try sprite.pipelines.setParent(app.player_id, app.pipeline_id);
}

fn prepareGlyphs(queue: *gpu.Queue, app: *App) !void {
    // Prepare which glyphs we will render
    const codepoints: []const u21 = &[_]u21{ '?', '!', 'a', 'b', '#', '@', '%', '$', '&', '^', '*', '+', '=', '<', '>', '/', ':', ';', 'Q', '~' };
    for (codepoints) |codepoint| {
        const font_size = 48 * 1;
        try app.face.setCharSize(font_size * 64, 0, 50, 0);
        try app.face.loadChar(codepoint, .{ .render = true });
        const glyph = app.face.glyph();
        const metrics = glyph.metrics();

        const glyph_bitmap = glyph.bitmap();
        const glyph_width = glyph_bitmap.width();
        const glyph_height = glyph_bitmap.rows();

        // Add 1 pixel padding to texture to avoid bleeding over other textures
        const margin = 1;
        const glyph_data = try app.allocator.alloc([4]u8, (glyph_width + (margin * 2)) * (glyph_height + (margin * 2)));
        defer app.allocator.free(glyph_data);
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
        var glyph_atlas_region = try app.texture_atlas.reserve(app.allocator, glyph_width + (margin * 2), glyph_height + (margin * 2));
        app.texture_atlas.set(glyph_atlas_region, @as([*]const u8, @ptrCast(glyph_data.ptr))[0 .. glyph_data.len * 4]);

        glyph_atlas_region.x += margin;
        glyph_atlas_region.y += margin;
        glyph_atlas_region.width -= margin * 2;
        glyph_atlas_region.height -= margin * 2;

        try app.regions.put(app.allocator, codepoint, glyph_atlas_region);
        _ = metrics;
    }

    // rgba32_pixels
    const img_size = gpu.Extent3D{ .width = 1024, .height = 1024 };
    const data_layout = gpu.Texture.DataLayout{
        .bytes_per_row = @as(u32, @intCast(img_size.width * 4)),
        .rows_per_image = @as(u32, @intCast(img_size.height)),
    };
    queue.writeTexture(&.{ .texture = app.texture }, &data_layout, &img_size, app.texture_atlas.data);
}

pub fn tick(
    core: *mach.Core,
    app: *App,
    sprite: *gfx.Sprite,
    sprite_mod: mach.Mod(gfx.Sprite),
) !void {
    const label = @tagName(mach_module) ++ ".tick";

    var direction = app.direction;
    var spawning = app.spawning;
    while (core.nextEvent()) |event| {
        switch (event) {
            .key_press => |ev| {
                switch (ev.key) {
                    .left => direction.v[0] -= 1,
                    .right => direction.v[0] += 1,
                    .up => direction.v[1] += 1,
                    .down => direction.v[1] -= 1,
                    .space => spawning = true,
                    else => {},
                }
            },
            .key_release => |ev| {
                switch (ev.key) {
                    .left => direction.v[0] += 1,
                    .right => direction.v[0] -= 1,
                    .up => direction.v[1] -= 1,
                    .down => direction.v[1] += 1,
                    .space => spawning = false,
                    else => {},
                }
            },
            .window_open => |ev| try setupPipeline(core, app, sprite, ev.window_id),
            .close => core.exit(),
            else => {},
        }
    }
    app.direction = direction;
    app.spawning = spawning;

    var player = sprite.objects.getValue(app.player_id);
    defer sprite.objects.setValue(app.player_id, player);
    var player_pos = player.transform.translation();
    if (spawning and app.spawn_timer.read() > 1.0 / 60.0) {
        // Spawn new entities
        _ = app.spawn_timer.lap();
        for (0..50) |_| {
            var new_pos = player_pos;
            new_pos.v[0] += app.rand.random().floatNorm(f32) * 25;
            new_pos.v[1] += app.rand.random().floatNorm(f32) * 25;

            const rand_index = app.rand.random().intRangeAtMost(usize, 0, app.regions.count() - 1);
            const r = app.regions.entries.get(rand_index).value;

            const new_sprite_id = try sprite.objects.new(.{
                .transform = Mat4x4.translate(new_pos).mul(&Mat4x4.scaleScalar(0.3)),
                .size = vec2(@floatFromInt(r.width), @floatFromInt(r.height)),
                .uv_transform = Mat3x3.translate(vec2(@floatFromInt(r.x), @floatFromInt(r.y))),
            });
            try sprite.pipelines.setParent(new_sprite_id, app.pipeline_id);
            app.sprites += 1;
        }
    }

    // Multiply by delta_time to ensure that movement is the same speed regardless of the frame rate.
    const delta_time = app.timer.lap();

    const window = core.windows.getValue(app.window);

    // Rotate all sprites in the pipeline.
    var pipeline_children = try sprite.pipelines.getChildren(app.pipeline_id);
    defer pipeline_children.deinit();
    for (pipeline_children.items) |sprite_id| {
        if (!sprite.objects.is(sprite_id)) continue;
        if (sprite_id == app.player_id) continue; // don't rotate the player
        var s = sprite.objects.getValue(sprite_id);
        const location = s.transform.translation();

        if (location.x() < -@as(f32, @floatFromInt(window.width)) / 1.5 or location.x() > @as(f32, @floatFromInt(window.width)) / 1.5 or location.y() < -@as(f32, @floatFromInt(window.height)) / 1.5 or location.y() > @as(f32, @floatFromInt(window.height)) / 1.5) {
            try sprite.objects.setParent(sprite_id, null);
            sprite.objects.delete(sprite_id);
            app.sprites -= 1;
            continue;
        }

        var transform = Mat4x4.ident;
        transform = transform.mul(&Mat4x4.scale(Vec3.splat(1.0 + (0.2 * delta_time))));
        transform = transform.mul(&Mat4x4.translate(location));
        transform = transform.mul(&Mat4x4.rotateZ(2 * math.pi * app.time));
        transform = transform.mul(&Mat4x4.scale(Vec3.splat(@max(math.cos(app.time / 2.0), 0.2))));
        s.transform = transform;
        sprite.objects.setValue(sprite_id, s);
    }

    // Calculate the player position, by moving in the direction the player wants to go
    // by the speed amount.
    const speed = 200.0;
    player_pos.v[0] += direction.x() * speed * delta_time;
    player_pos.v[1] += direction.y() * speed * delta_time;
    player.transform = Mat4x4.translate(player_pos);

    // Grab the back buffer of the swapchain
    // TODO(Core)
    const back_buffer_view = window.swap_chain.getCurrentTextureView().?;
    defer back_buffer_view.release();

    // Create a command encoder
    const encoder = window.device.createCommandEncoder(&.{ .label = label });
    defer encoder.release();

    // Begin render pass
    const sky_blue = gpu.Color{ .r = 0.776, .g = 0.988, .b = 1, .a = 1 };
    const color_attachments = [_]gpu.RenderPassColorAttachment{.{
        .view = back_buffer_view,
        .clear_value = sky_blue,
        .load_op = .clear,
        .store_op = .store,
    }};
    const render_pass = encoder.beginRenderPass(&gpu.RenderPassDescriptor.init(.{
        .label = label,
        .color_attachments = &color_attachments,
    }));

    // Render sprites
    sprite.pipelines.set(app.pipeline_id, .render_pass, render_pass);
    sprite_mod.call(.tick);

    // Finish render pass
    render_pass.end();
    var command = encoder.finish(&.{ .label = label });
    window.queue.submit(&[_]*gpu.CommandBuffer{command});
    command.release();
    render_pass.release();

    app.frame_count += 1;
    app.time += delta_time;

    // TODO(object): window-title
    // // Every second, update the window title with the FPS
    // if (app.fps_timer.read() >= 1.0) {
    //     try core.printTitle(
    //         core.main_window,
    //         "glyphs [ FPS: {d} ] [ Sprites: {d} ]",
    //         .{ app.frame_count, app.sprites },
    //     );
    //     core.schedule(.update);
    //     app.fps_timer.reset();
    //     app.frame_count = 0;
    // }
}
