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
const Mat3x3 = math.Mat3x3;
const Mat4x4 = math.Mat4x4;

const App = @This();

// The set of Mach modules our application may use.
pub const Modules = mach.Modules(.{
    mach.Core,
    mach.gfx.Sprite,
    mach.gfx.Text,
    mach.Audio,
    App,
});

pub const mach_module = .app;

pub const mach_systems = .{ .main, .init, .tick, .deinit, .deinit2, .audioStateChange };

pub const main = mach.schedule(.{
    .{ mach.Core, .init },
    .{ mach.Audio, .init },
    .{ gfx.Text, .init },
    .{ App, .init },
    .{ mach.Core, .main },
});

pub const deinit = mach.schedule(.{
    .{ mach.Audio, .deinit },
    .{ App, .deinit2 },
});

allocator: std.mem.Allocator,
window: mach.ObjectID,
timer: mach.time.Timer,
spawn_timer: mach.time.Timer,
fps_timer: mach.time.Timer,
rand: std.Random.DefaultPrng,

frame_count: usize = 0,
fps: usize = 0,
score: usize = 0,
num_sprites_spawned: usize = 0,
time: f32 = 0,
direction: Vec2 = vec2(0, 0),
spawning: bool = false,
gotta_go_fast: bool = false,

info_text: []u8 = undefined,
info_text_id: mach.ObjectID = undefined,
info_text_style_id: mach.ObjectID = undefined,
sprite_pipeline_id: mach.ObjectID = undefined,
text_pipeline_id: mach.ObjectID = undefined,
sfx: mach.Audio.Opus = undefined,

pub fn init(
    core: *mach.Core,
    audio: *mach.Audio,
    app: *App,
    app_mod: mach.Mod(App),
) !void {
    core.on_tick = app_mod.id.tick;
    core.on_exit = app_mod.id.deinit;

    // Configure the audio module to call our App.audioStateChange function when a sound buffer
    // finishes playing.
    audio.on_state_change = app_mod.id.audioStateChange;

    const window = try core.windows.new(.{
        .title = "hardware check",
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

pub fn deinit2(
    app: *App,
    text: *gfx.Text,
) void {
    // Cleanup here, if desired.
    text.objects.delete(app.info_text_id);
}

/// Called on the high-priority audio OS thread when the audio driver needs more audio samples, so
/// this callback should be fast to respond.
pub fn audioStateChange(audio: *mach.Audio, app: *App) !void {
    audio.buffers.lock();
    defer audio.buffers.unlock();

    // Find audio objects that are no longer playing
    var buffers = audio.buffers.slice();
    while (buffers.next()) |buf_id| {
        if (audio.buffers.get(buf_id, .playing)) continue;

        // Remove the audio buffer that is no longer playing
        const samples = audio.buffers.get(buf_id, .samples);
        audio.buffers.delete(buf_id);
        app.allocator.free(samples);
    }
}

fn setupPipeline(
    core: *mach.Core,
    app: *App,
    sprite: *gfx.Sprite,
    text: *gfx.Text,
    window_id: mach.ObjectID,
) !void {
    const window = core.windows.getValue(window_id);

    // Load sfx
    const sfx_fbs = std.io.fixedBufferStream(assets.sfx.scifi_gun);
    const sfx_sound_stream = std.io.StreamSource{ .const_buffer = sfx_fbs };
    app.sfx = try mach.Audio.Opus.decodeStream(app.allocator, sfx_sound_stream);

    // Create a sprite rendering pipeline
    app.sprite_pipeline_id = try sprite.pipelines.new(.{
        .window = window_id,
        .render_pass = undefined,
        .texture = try loadTexture(window.device, window.queue, app.allocator),
    });

    // Create a text rendering pipeline
    app.text_pipeline_id = try text.pipelines.new(.{
        .window = window_id,
        .render_pass = undefined,
    });

    // Create a text style
    app.info_text_style_id = try text.styles.new(.{
        .font_size = 48 * gfx.px_per_pt, // 48pt
    });

    // Create documentation text
    {
        // TODO(text): release this memory somewhere
        const text_value =
            \\ Mach is probably working if you:
            \\ * See this text
            \\ * See sprites to the left
            \\ * Hear sounds when sprites disappear
            \\ * Hold space and things go faster
        ;
        const text_buf = try app.allocator.alloc(u8, text_value.len);
        @memcpy(text_buf, text_value);
        const segments = try app.allocator.alloc(gfx.Text.Segment, 1);
        segments[0] = .{
            .text = text_buf,
            .style = app.info_text_style_id,
        };

        // Create our player text
        const text_id = try text.objects.new(.{
            .transform = Mat4x4.translate(vec3(-0.02, 0, 0)),
            .segments = segments,
        });
        // Attach the text object to our text rendering pipeline.
        try text.pipelines.setParent(text_id, app.text_pipeline_id);
    }

    // Create info text to be updated dynamically later
    {
        // TODO(text): release this memory somewhere
        const text_value = "[info]";
        app.info_text = try app.allocator.alloc(u8, text_value.len);
        @memcpy(app.info_text, text_value);
        const segments = try app.allocator.alloc(gfx.Text.Segment, 1);
        segments[0] = .{
            .text = app.info_text,
            .style = app.info_text_style_id,
        };

        // Create our player text
        app.info_text_id = try text.objects.new(.{
            .transform = Mat4x4.translate(vec3(0, (@as(f32, @floatFromInt(window.height)) / 2.0) - 50.0, 0)),
            .segments = segments,
        });
        // Attach the text object to our text rendering pipeline.
        try text.pipelines.setParent(app.info_text_id, app.sprite_pipeline_id);
    }
}

pub fn tick(
    core: *mach.Core,
    app: *App,
    sprite: *gfx.Sprite,
    sprite_mod: mach.Mod(gfx.Sprite),
    text: *gfx.Text,
    text_mod: mach.Mod(gfx.Text),
    audio: *mach.Audio,
) !void {
    const label = @tagName(mach_module) ++ ".tick";
    const window = core.windows.getValue(app.window);

    while (core.nextEvent()) |event| {
        switch (event) {
            .key_press => |ev| {
                switch (ev.key) {
                    .space => app.gotta_go_fast = true,
                    else => {},
                }
            },
            .key_release => |ev| {
                switch (ev.key) {
                    .space => app.gotta_go_fast = false,
                    else => {},
                }
            },
            .window_open => |ev| try setupPipeline(core, app, sprite, text, ev.window_id),
            .close => core.exit(),
            else => {},
        }
    }

    // TODO(text): make updating text easier
    app.allocator.free(app.info_text);
    app.info_text = try std.fmt.allocPrint(
        app.allocator,
        "[ FPS: {d} ]\n[ Sprites spawned: {d} ]",
        .{ app.fps, app.num_sprites_spawned },
    );
    var segments: []gfx.Text.Segment = @constCast(text.objects.get(app.info_text_id, .segments));
    segments[0] = .{
        .text = app.info_text,
        .style = segments[0].style,
    };
    text.objects.set(app.info_text_id, .segments, segments);

    const entities_per_second: f32 = @floatFromInt(
        app.rand.random().intRangeAtMost(usize, 0, if (app.gotta_go_fast) 50 else 10),
    );
    if (app.spawn_timer.read() > 1.0 / entities_per_second) {
        // Spawn new entities
        _ = app.spawn_timer.lap();

        var new_pos = vec3(-(@as(f32, @floatFromInt(window.width)) / 2), 0, 0);
        new_pos.v[1] += app.rand.random().floatNorm(f32) * 50;

        const new_sprite_id = try sprite.objects.new(.{
            .transform = Mat4x4.translate(new_pos),
            .size = vec2(32, 32),
            .uv_transform = Mat3x3.translate(vec2(0, 0)),
        });
        try sprite.pipelines.setParent(new_sprite_id, app.sprite_pipeline_id);
        app.num_sprites_spawned += 1;
    }

    // Multiply by delta_time to ensure that movement is the same speed regardless of the frame rate.
    const delta_time = app.timer.lap();

    // Move sprites to the right, and make them smaller the further they travel
    var pipeline_children = try sprite.pipelines.getChildren(app.sprite_pipeline_id);
    defer pipeline_children.deinit();
    for (pipeline_children.items) |sprite_id| {
        if (!sprite.objects.is(sprite_id)) continue;
        var s = sprite.objects.getValue(sprite_id);

        const location = s.transform.translation();
        const speed: f32 = if (app.gotta_go_fast) 2000 else 100;
        const progression = std.math.clamp((location.v[0] + (@as(f32, @floatFromInt(window.height)) / 2.0)) / @as(f32, @floatFromInt(window.height)), 0, 1);
        const scale = mach.math.lerp(2, 0, progression);
        if (progression >= 0.6) {
            try sprite.pipelines.removeChild(app.sprite_pipeline_id, sprite_id);
            sprite.objects.delete(sprite_id);

            // Play a new sound
            const samples = try app.allocator.alignedAlloc(f32, mach.Audio.alignment, app.sfx.samples.len);
            @memcpy(samples, app.sfx.samples);
            audio.buffers.lock();
            defer audio.buffers.unlock();
            const sound_id = try audio.buffers.new(.{
                .samples = samples,
                .channels = app.sfx.channels,
            });
            _ = sound_id;
            app.score += 1;
        } else {
            var transform = Mat4x4.ident;
            transform = transform.mul(&Mat4x4.translate(location.add(&vec3(speed * delta_time, (speed / 2.0) * delta_time * progression, 0))));
            transform = transform.mul(&Mat4x4.scaleScalar(scale));
            sprite.objects.set(sprite_id, .transform, transform);
        }
    }

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
    sprite.pipelines.set(app.sprite_pipeline_id, .render_pass, render_pass);
    sprite_mod.call(.tick);

    // Render text
    text.pipelines.set(app.text_pipeline_id, .render_pass, render_pass);
    text_mod.call(.tick);

    // Finish render pass
    render_pass.end();
    var command = encoder.finish(&.{ .label = label });
    window.queue.submit(&[_]*gpu.CommandBuffer{command});
    command.release();
    render_pass.release();

    mach.sysgpu.Impl.deviceTick(window.device);

    window.swap_chain.present();

    app.frame_count += 1;
    app.time += delta_time;

    // Every second, update the window title with the FPS
    if (app.fps_timer.read() >= 1.0) {
        app.fps_timer.reset();
        app.fps = app.frame_count;
        app.frame_count = 0;
    }
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
