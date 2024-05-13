// TODO(important): review all code in this file in-depth
const std = @import("std");
const zigimg = @import("zigimg");
const assets = @import("assets");
const mach = @import("mach");
const gpu = mach.gpu;
const gfx = mach.gfx;
const math = mach.math;

const vec2 = math.vec2;
const vec3 = math.vec3;
const vec4 = math.vec4;
const Vec2 = math.Vec2;
const Vec3 = math.Vec3;
const Mat3x3 = math.Mat3x3;
const Mat4x4 = math.Mat4x4;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

info_text: mach.EntityID,
info_text_style: mach.EntityID,
timer: mach.Timer,
gotta_go_fast: bool = false,
spawn_timer: mach.Timer,
fps_timer: mach.Timer,
frame_count: usize,
frame_rate: usize,
num_sprites_spawned: usize,
score: usize,
rand: std.rand.DefaultPrng,
time: f32,
allocator: std.mem.Allocator,
pipeline: mach.EntityID,
frame_encoder: *gpu.CommandEncoder = undefined,
frame_render_pass: *gpu.RenderPassEncoder = undefined,
sfx: mach.Audio.Opus,

// Define the globally unique name of our module. You can use any name here, but keep in mind no
// two modules in the program can have the same name.
pub const name = .app;
pub const Mod = mach.Mod(@This());

pub const systems = .{
    .init = .{ .handler = init },
    .after_init = .{ .handler = afterInit },
    .deinit = .{ .handler = deinit },
    .tick = .{ .handler = tick },
    .end_frame = .{ .handler = endFrame },
    .audio_state_change = .{ .handler = audioStateChange },
};

fn deinit(
    core: *mach.Core.Mod,
    text_pipeline: *gfx.TextPipeline.Mod,
    sprite_pipeline: *gfx.SpritePipeline.Mod,
    audio: *mach.Audio.Mod,
) !void {
    text_pipeline.schedule(.deinit);
    sprite_pipeline.schedule(.deinit);
    core.schedule(.deinit);
    audio.schedule(.deinit);
}

fn init(
    audio: *mach.Audio.Mod,
    text_pipeline: *gfx.TextPipeline.Mod,
    text: *gfx.Text.Mod,
    sprite_pipeline: *gfx.SpritePipeline.Mod,
    core: *mach.Core.Mod,
    game: *Mod,
) !void {
    // If you want to try fullscreen:
    // try core.set(core.state().main_window, .fullscreen, true);

    core.schedule(.init);
    audio.schedule(.init);
    text.schedule(.init);
    text_pipeline.schedule(.init);
    sprite_pipeline.schedule(.init);
    game.schedule(.after_init);
}

fn afterInit(
    entities: *mach.Entities.Mod,
    core: *mach.Core.Mod,
    audio: *mach.Audio.Mod,
    text_pipeline: *gfx.TextPipeline.Mod,
    text_style: *gfx.TextStyle.Mod,
    text: *gfx.Text.Mod,
    sprite_pipeline: *gfx.SpritePipeline.Mod,
    game: *Mod,
) !void {
    // Configure the audio module to run our audio_state_change system when entities audio finishes
    // playing
    audio.state().on_state_change = game.system(.audio_state_change);

    // Create a sprite rendering pipeline
    const allocator = gpa.allocator();
    const pipeline = try entities.new();
    try sprite_pipeline.set(pipeline, .texture, try loadTexture(core, allocator));
    sprite_pipeline.schedule(.update);

    // TODO: a better way to initialize entities with default values
    // TODO(text): ability to specify other style options (custom font name, font color, italic/bold, etc.)
    const style1 = try entities.new();
    try text_style.set(style1, .font_size, 48 * gfx.px_per_pt); // 48pt

    // Create a text rendering pipeline
    const text_rendering_pipeline = try entities.new();
    try text_pipeline.set(text_rendering_pipeline, .is_pipeline, {});
    text_pipeline.schedule(.update);

    // Create some text
    const text1 = try entities.new();
    try text.set(text1, .pipeline, text_rendering_pipeline);
    try text.set(text1, .transform, Mat4x4.translate(vec3(0, 0, 0)));
    try gfx.Text.allocPrintText(text, text1, style1,
        \\ Mach is probably working if you:
        \\ * See this text
        \\ * See sprites to the left
        \\ * Hear sounds when sprites die
        \\ * Hold space and things go faster
    , .{});
    text.schedule(.update);

    const window_height: f32 = @floatFromInt(core.get(core.state().main_window, .height).?);
    const info_text = try entities.new();
    try text.set(info_text, .pipeline, text_rendering_pipeline);
    try text.set(info_text, .transform, Mat4x4.translate(vec3(0, (window_height / 2.0) - 50.0, 0)));
    try gfx.Text.allocPrintText(text, info_text, style1, "[info]", .{});

    // Load sfx
    const sfx_fbs = std.io.fixedBufferStream(assets.sfx.scifi_gun);
    const sfx_sound_stream = std.io.StreamSource{ .const_buffer = sfx_fbs };
    const sfx = try mach.Audio.Opus.decodeStream(gpa.allocator(), sfx_sound_stream);

    game.init(.{
        .info_text = info_text,
        .info_text_style = style1,
        .timer = try mach.Timer.start(),
        .spawn_timer = try mach.Timer.start(),
        .fps_timer = try mach.Timer.start(),
        .frame_count = 0,
        .frame_rate = 0,
        .num_sprites_spawned = 0,
        .score = 0,
        .rand = std.rand.DefaultPrng.init(1337),
        .time = 0,
        .allocator = allocator,
        .pipeline = pipeline,
        .sfx = sfx,
    });
    core.schedule(.start);
}

fn audioStateChange(entities: *mach.Entities.Mod) !void {
    // Find audio entities that are no longer playing
    var q = try entities.query(.{
        .ids = mach.Entities.Mod.read(.id),
        .playings = mach.Audio.Mod.read(.playing),
    });
    while (q.next()) |v| {
        for (v.ids, v.playings) |id, playing| {
            if (playing) continue;

            // Remove the entity for the old sound
            try entities.remove(id);
        }
    }
}

fn tick(
    entities: *mach.Entities.Mod,
    core: *mach.Core.Mod,
    sprite: *gfx.Sprite.Mod,
    sprite_pipeline: *gfx.SpritePipeline.Mod,
    text: *gfx.Text.Mod,
    text_pipeline: *gfx.TextPipeline.Mod,
    game: *Mod,
    audio: *mach.Audio.Mod,
) !void {
    // TODO(important): event polling should occur in mach.Core module and get fired as ECS events.
    // TODO(Core)
    var iter = mach.core.pollEvents();
    var gotta_go_fast = game.state().gotta_go_fast;
    while (iter.next()) |event| {
        switch (event) {
            .key_press => |ev| {
                switch (ev.key) {
                    .space => gotta_go_fast = true,
                    else => {},
                }
            },
            .key_release => |ev| {
                switch (ev.key) {
                    .space => gotta_go_fast = false,
                    else => {},
                }
            },
            .close => core.schedule(.exit),
            else => {},
        }
    }
    game.state().gotta_go_fast = gotta_go_fast;

    // Every second, update the frame rate
    if (game.state().fps_timer.read() >= 1.0) {
        game.state().frame_rate = game.state().frame_count;
        game.state().fps_timer.reset();
        game.state().frame_count = 0;
    }

    try gfx.Text.allocPrintText(
        text,
        game.state().info_text,
        game.state().info_text_style,
        "[ FPS: {d} ]\n[ Sprites spawned: {d} ]",
        .{ game.state().frame_rate, game.state().num_sprites_spawned },
    );
    text.schedule(.update);

    // var player_transform = sprite.get(game.state().player, .transform).?;
    // var player_pos = player_transform.translation();
    const window_width: f32 = @floatFromInt(core.get(core.state().main_window, .width).?);

    const entities_per_second: f32 = @floatFromInt(
        game.state().rand.random().intRangeAtMost(usize, 0, if (gotta_go_fast) 50 else 10),
    );
    if (game.state().spawn_timer.read() > 1.0 / entities_per_second) {
        // Spawn new entities
        _ = game.state().spawn_timer.lap();

        var new_pos = vec3(-(window_width / 2), 0, 0);
        new_pos.v[1] += game.state().rand.random().floatNorm(f32) * 50;

        const new_entity = try entities.new();
        try sprite.set(new_entity, .transform, Mat4x4.translate(new_pos));
        try sprite.set(new_entity, .size, vec2(32, 32));
        try sprite.set(new_entity, .uv_transform, Mat3x3.translate(vec2(0, 0)));
        try sprite.set(new_entity, .pipeline, game.state().pipeline);
        game.state().num_sprites_spawned += 1;
    }

    // Multiply by delta_time to ensure that movement is the same speed regardless of the frame rate.
    const delta_time = game.state().timer.lap();

    // Move entities to the right, and make them smaller the further they travel
    var q = try entities.query(.{
        .ids = mach.Entities.Mod.read(.id),
        .transforms = gfx.Sprite.Mod.write(.transform),
    });
    while (q.next()) |v| {
        for (v.ids, v.transforms) |id, *entity_transform| {
            const location = entity_transform.*.translation();
            const speed: f32 = if (gotta_go_fast) 2000 else 100;
            const progression = std.math.clamp((location.v[0] + (window_width / 2.0)) / window_width, 0, 1);
            const scale = mach.math.lerp(2, 0, progression);
            if (progression >= 0.6) {
                try entities.remove(id);

                // Play a new SFX
                const e = try entities.new();
                try audio.set(e, .samples, game.state().sfx.samples);
                try audio.set(e, .channels, game.state().sfx.channels);
                try audio.set(e, .index, 0);
                try audio.set(e, .playing, true);
                game.state().score += 1;
            } else {
                var transform = Mat4x4.ident;
                transform = transform.mul(&Mat4x4.translate(location.add(&vec3(speed * delta_time, (speed / 2.0) * delta_time * progression, 0))));
                transform = transform.mul(&Mat4x4.scaleScalar(scale));
                entity_transform.* = transform;
            }
        }
    }

    sprite.schedule(.update);

    // Perform pre-render work
    sprite_pipeline.schedule(.pre_render);
    text_pipeline.schedule(.pre_render);

    // Create a command encoder for this frame
    const label = @tagName(name) ++ ".tick";
    game.state().frame_encoder = core.state().device.createCommandEncoder(&.{ .label = label });

    // Grab the back buffer of the swapchain
    // TODO(Core)
    const back_buffer_view = mach.core.swap_chain.getCurrentTextureView().?;
    defer back_buffer_view.release();

    // Begin render pass
    const sky_blue = gpu.Color{ .r = 0.776, .g = 0.988, .b = 1, .a = 1 };
    const color_attachments = [_]gpu.RenderPassColorAttachment{.{
        .view = back_buffer_view,
        .clear_value = sky_blue,
        .load_op = .clear,
        .store_op = .store,
    }};
    game.state().frame_render_pass = game.state().frame_encoder.beginRenderPass(&gpu.RenderPassDescriptor.init(.{
        .label = label,
        .color_attachments = &color_attachments,
    }));

    // Render our sprite batch
    sprite_pipeline.state().render_pass = game.state().frame_render_pass;
    sprite_pipeline.schedule(.render);

    // Render our text batch
    text_pipeline.state().render_pass = game.state().frame_render_pass;
    text_pipeline.schedule(.render);

    // Finish the frame once rendering is done.
    game.schedule(.end_frame);

    game.state().time += delta_time;
}

fn endFrame(game: *Mod, core: *mach.Core.Mod) !void {
    // Finish render pass
    game.state().frame_render_pass.end();
    const label = @tagName(name) ++ ".endFrame";
    var command = game.state().frame_encoder.finish(&.{ .label = label });
    core.state().queue.submit(&[_]*gpu.CommandBuffer{command});
    command.release();
    game.state().frame_encoder.release();
    game.state().frame_render_pass.release();

    // Present the frame
    core.schedule(.present_frame);

    game.state().frame_count += 1;
}

// TODO: move this helper into gfx module
fn loadTexture(core: *mach.Core.Mod, allocator: std.mem.Allocator) !*gpu.Texture {
    const device = core.state().device;
    const queue = core.state().queue;

    // Load the image from memory
    var img = try zigimg.Image.fromMemory(allocator, assets.sprites_sheet_png);
    defer img.deinit();
    const img_size = gpu.Extent3D{ .width = @as(u32, @intCast(img.width)), .height = @as(u32, @intCast(img.height)) };

    // Create a GPU texture
    const label = @tagName(name) ++ ".loadTexture";
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
