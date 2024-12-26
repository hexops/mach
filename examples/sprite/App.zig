const std = @import("std");
const zigimg = @import("zigimg");
const assets = @import("assets");
const mach = @import("mach");
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

pub const mach_systems = .{ .main, .init, .tick, .deinit };

pub const main = mach.schedule(.{
    .{ mach.Core, .init },
    .{ App, .init },
    .{ mach.Core, .main },
});

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
spawning: bool = false,
player_id: mach.ObjectID = undefined,
pipeline_id: mach.ObjectID = undefined,

pub fn init(
    core: *mach.Core,
    app: *App,
    app_mod: mach.Mod(App),
    sprite: *gfx.Sprite,
) !void {
    _ = sprite; // autofix
    core.on_tick = app_mod.id.tick;
    core.on_exit = app_mod.id.deinit;

    const window = try core.windows.new(.{
        .title = "gfx.Sprite",
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

fn setupPipeline(
    core: *mach.Core,
    app: *App,
    sprite: *gfx.Sprite,
    window_id: mach.ObjectID,
) !void {
    const window = core.windows.getValue(window_id);

    // Create a sprite rendering pipeline
    app.pipeline_id = try sprite.pipelines.new(.{
        .window = window_id,
        .render_pass = undefined,
        .texture = try loadTexture(window.device, window.queue, app.allocator),
    });

    // Create our player sprite
    app.player_id = try sprite.sprites.new(.{
        .transform = Mat4x4.translate(vec3(-0.02, 0, 0)),
        .size = vec2(32, 32),
        .uv_transform = Mat3x3.translate(vec2(0, 0)),
    });
    // Attach the sprite to our sprite rendering pipeline.
    try sprite.pipelines.setParent(app.player_id, app.pipeline_id);
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

    var player = sprite.sprites.getValue(app.player_id);
    defer sprite.sprites.setValue(app.player_id, player);
    var player_pos = player.transform.translation();
    if (spawning and app.spawn_timer.read() > 1.0 / 60.0) {
        // Spawn new entities
        _ = app.spawn_timer.lap();
        for (0..100) |_| {
            var new_pos = player_pos;
            new_pos.v[0] += app.rand.random().floatNorm(f32) * 25;
            new_pos.v[1] += app.rand.random().floatNorm(f32) * 25;

            const new_sprite_id = try sprite.sprites.new(.{
                .transform = Mat4x4.translate(new_pos).mul(&Mat4x4.scale(Vec3.splat(0.3))),
                .size = vec2(32, 32),
                .uv_transform = Mat3x3.translate(vec2(0, 0)),
            });
            try sprite.pipelines.setParent(new_sprite_id, app.pipeline_id);
            app.sprites += 1;
        }
    }

    // Multiply by delta_time to ensure that movement is the same speed regardless of the frame rate.
    const delta_time = app.timer.lap();

    // Rotate all sprites in the pipeline.
    var pipeline_children = try sprite.pipelines.getChildren(app.pipeline_id);
    defer pipeline_children.deinit();
    for (pipeline_children.items) |sprite_id| {
        if (!sprite.sprites.is(sprite_id)) continue;
        if (sprite_id == app.player_id) continue; // don't rotate the player
        var s = sprite.sprites.getValue(sprite_id);
        defer sprite.sprites.setValue(sprite_id, s);
        const location = s.transform.translation();
        var transform = Mat4x4.ident;
        transform = transform.mul(&Mat4x4.translate(location));
        transform = transform.mul(&Mat4x4.rotateZ(2 * math.pi * app.time));
        transform = transform.mul(&Mat4x4.scaleScalar(@min(math.cos(app.time / 2.0), 0.5)));
        s.transform = transform;
    }

    // Calculate the player position, by moving in the direction the player wants to go
    // by the speed amount.
    const speed = 200.0;
    player_pos.v[0] += direction.x() * speed * delta_time;
    player_pos.v[1] += direction.y() * speed * delta_time;
    player.transform = Mat4x4.translate(player_pos);

    const window = core.windows.getValue(app.window);

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

    // TODO(object): window-title
    // // Every second, update the window title with the FPS
    // if (app.fps_timer.read() >= 1.0) {
    //     try core.printTitle(
    //         core.main_window,
    //         "sprite [ FPS: {d} ] [ Sprites: {d} ]",
    //         .{ app.frame_count, app.sprites },
    //     );
    //     core.schedule(.update);
    //     app.fps_timer.reset();
    //     app.frame_count = 0;
    // }
    app.frame_count += 1;
    app.time += delta_time;
}

pub fn deinit(
    app: *App,
    sprite: *gfx.Sprite,
) void {
    // Cleanup here, if desired.
    sprite.sprites.delete(app.player_id);
}

// TODO(sprite): don't require users to copy / write this helper themselves
fn loadTexture(device: *gpu.Device, queue: *gpu.Queue, allocator: std.mem.Allocator) !*gpu.Texture {
    // Load the image from memory
    var img = try zigimg.Image.fromMemory(allocator, assets.sprites_sheet_png);
    defer img.deinit();
    const img_size = gpu.Extent3D{ .width = @as(u32, @intCast(img.width)), .height = @as(u32, @intCast(img.height)) };

    // Create a GPU texture
    const label = @tagName(mach_module) ++ ".loadTexture";
    const texture = device.createTexture(&.{
        .label = label,
        .size = img_size,
        .format = .rgba8_unorm,
        .usage = .{
            .texture_binding = true,
            .copy_dst = true,
        },
    });
    const data_layout = gpu.Texture.DataLayout{
        .bytes_per_row = @as(u32, @intCast(img.width * 4)),
        .rows_per_image = @as(u32, @intCast(img.height)),
    };
    switch (img.pixels) {
        .rgba32 => |pixels| queue.writeTexture(&.{ .texture = texture }, &data_layout, &img_size, pixels),
        .rgb24 => |pixels| {
            const data = try rgb24ToRgba32(allocator, pixels);
            defer data.deinit(allocator);
            queue.writeTexture(&.{ .texture = texture }, &data_layout, &img_size, data.rgba32);
        },
        else => @panic("unsupported image color format"),
    }
    return texture;
}

fn rgb24ToRgba32(allocator: std.mem.Allocator, in: []zigimg.color.Rgb24) !zigimg.color.PixelStorage {
    const out = try zigimg.color.PixelStorage.init(allocator, .rgba32, in.len);
    var i: usize = 0;
    while (i < in.len) : (i += 1) {
        out.rgba32[i] = zigimg.color.Rgba32{ .r = in[i].r, .g = in[i].g, .b = in[i].b, .a = 255 };
    }
    return out;
}
