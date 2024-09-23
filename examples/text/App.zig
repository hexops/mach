const std = @import("std");
const zigimg = @import("zigimg");
const assets = @import("assets");
const mach = @import("mach");
const gfx = mach.gfx;
const gpu = mach.gpu;
const math = mach.math;

const vec2 = math.vec2;
const vec3 = math.vec3;
const vec4 = math.vec4;
const Vec2 = math.Vec2;
const Vec3 = math.Vec3;
const Mat3x3 = math.Mat3x3;
const Mat4x4 = math.Mat4x4;

const App = @This();

pub const mach_module = .app;

pub const mach_systems = .{ .start, .init, .deinit, .tick, .end_frame };

timer: mach.time.Timer,
player: mach.EntityID,
direction: Vec2 = vec2(0, 0),
spawning: bool = false,
spawn_timer: mach.time.Timer,
fps_timer: mach.time.Timer,
frame_count: usize,
rand: std.Random.DefaultPrng,
time: f32,
style1: mach.EntityID,
pipeline: mach.EntityID,
frame_encoder: *gpu.CommandEncoder = undefined,
frame_render_pass: *gpu.RenderPassEncoder = undefined,

const upscale = 1.0;

const text1: []const []const u8 = &.{
    "Text but with spaces\n",
    "and\n",
    "newlines\n",
};

const text2: []const []const u8 = &.{"$!?"};

fn deinit(text_pipeline: *gfx.TextPipeline.Mod) !void {
    text_pipeline.schedule(.deinit);
}

fn start(
    core: *mach.Core,
    text: *gfx.Text.Mod,
    text_pipeline: *gfx.TextPipeline.Mod,
    app: *App,
) !void {
    core.schedule(.init);
    text.schedule(.init);
    text_pipeline.schedule(.init);
    app.schedule(.init);
}

fn init(
    entities: *mach.Entities.Mod,
    core: *mach.Core,
    text: *gfx.Text.Mod,
    text_pipeline: *gfx.TextPipeline.Mod,
    text_style: *gfx.TextStyle.Mod,
    app: *App,
    app_mod: mach.Functions(App),
) !void {
    core.on_tick = app_mod.id.tick;
    core.on_exit = app_mod.id.deinit;

    // TODO: a better way to initialize entities with default values
    // TODO(text): ability to specify other style options (custom font name, font color, italic/bold, etc.)
    const style1 = try entities.new();
    try text_style.set(style1, .font_size, 48 * gfx.px_per_pt); // 48pt

    // Create a text rendering pipeline
    const pipeline = try entities.new();
    try text_pipeline.set(pipeline, .is_pipeline, {});
    text_pipeline.schedule(.update);

    // Create some text
    const player = try entities.new();
    try text.set(player, .pipeline, pipeline);
    try text.set(player, .transform, Mat4x4.translate(vec3(0, 0, 0)));
    try gfx.Text.allocPrintText(text, player, style1,
        \\ Text with spaces
        \\ and newlines
        \\ but nothing fancy yet
    , .{});
    text.schedule(.update);

    app.init(.{
        .timer = try mach.time.Timer.start(),
        .spawn_timer = try mach.time.Timer.start(),
        .player = player,
        .fps_timer = try mach.time.Timer.start(),
        .frame_count = 0,
        .rand = std.Random.DefaultPrng.init(1337),
        .time = 0,
        .style1 = style1,
        .pipeline = pipeline,
    });
}

fn tick(
    entities: *mach.Entities.Mod,
    core: *mach.Core,
    text: *gfx.Text.Mod,
    text_pipeline: *gfx.TextPipeline.Mod,
    app: *App,
) !void {
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
            .close => core.exit(),
            else => {},
        }
    }
    app.direction = direction;
    app.spawning = spawning;

    var player_transform = text.get(app.player, .transform).?;
    var player_pos = player_transform.translation().divScalar(upscale);
    if (spawning and app.spawn_timer.read() > (1.0 / 60.0)) {
        // Spawn new entities
        _ = app.spawn_timer.lap();
        for (0..10) |_| {
            var new_pos = player_pos;
            new_pos.v[0] += app.rand.random().floatNorm(f32) * 50;
            new_pos.v[1] += app.rand.random().floatNorm(f32) * 50;

            // Create some text
            const new_entity = try entities.new();
            try text.set(new_entity, .pipeline, app.pipeline);
            try text.set(new_entity, .transform, Mat4x4.scaleScalar(upscale).mul(&Mat4x4.translate(new_pos)));
            try gfx.Text.allocPrintText(text, new_entity, app.style1, "?!$", .{});
        }
    }

    // Multiply by delta_time to ensure that movement is the same speed regardless of the frame rate.
    const delta_time = app.timer.lap();

    // Rotate entities
    var q = try entities.query(.{
        .transforms = gfx.Text.Mod.write(.transform),
    });
    while (q.next()) |v| {
        for (v.transforms) |*entity_transform| {
            const location = entity_transform.*.translation();
            // var transform = old_transform.mul(&Mat4x4.translate(-location));
            // transform = mat.rotateZ(0.3 * delta_time).mul(&transform);
            // transform = transform.mul(&Mat4x4.translate(location));
            var transform = Mat4x4.ident;
            transform = transform.mul(&Mat4x4.translate(location));
            transform = transform.mul(&Mat4x4.rotateZ(2 * math.pi * app.time));
            transform = transform.mul(&Mat4x4.scaleScalar(@min(math.cos(app.time / 2.0), 0.5)));
            entity_transform.* = transform;
        }
    }

    // Calculate the player position, by moving in the direction the player wants to go
    // by the speed amount.
    const speed = 200.0 / upscale;
    player_pos.v[0] += direction.x() * speed * delta_time;
    player_pos.v[1] += direction.y() * speed * delta_time;
    try text.set(app.player, .transform, Mat4x4.scaleScalar(upscale).mul(&Mat4x4.translate(player_pos)));
    try text.set(app.player, .dirty, true);
    text.schedule(.update);

    // Perform pre-render work
    text_pipeline.schedule(.pre_render);

    // Create a command encoder for this frame
    const label = @tagName(mach_module) ++ ".tick";
    app.frame_encoder = core.device.createCommandEncoder(&.{ .label = label });

    // Grab the back buffer of the swapchain
    // TODO(Core)
    const back_buffer_view = core.swap_chain.getCurrentTextureView().?;
    defer back_buffer_view.release();

    // Begin render pass
    const sky_blue = gpu.Color{ .r = 0.776, .g = 0.988, .b = 1, .a = 1 };
    const color_attachments = [_]gpu.RenderPassColorAttachment{.{
        .view = back_buffer_view,
        .clear_value = sky_blue,
        .load_op = .clear,
        .store_op = .store,
    }};
    app.frame_render_pass = app.frame_encoder.beginRenderPass(&gpu.RenderPassDescriptor.init(.{
        .label = label,
        .color_attachments = &color_attachments,
    }));

    // Render our text batch
    text_pipeline.state().render_pass = app.frame_render_pass;
    text_pipeline.schedule(.render);

    // Finish the frame once rendering is done.
    app.schedule(.end_frame);

    app.time += delta_time;
}

fn endFrame(
    entities: *mach.Entities.Mod,
    app: *App,
    core: *mach.Core,
) !void {
    // Finish render pass
    app.frame_render_pass.end();
    const label = @tagName(mach_module) ++ ".endFrame";
    var command = app.frame_encoder.finish(&.{ .label = label });
    core.queue.submit(&[_]*gpu.CommandBuffer{command});
    command.release();
    app.frame_encoder.release();
    app.frame_render_pass.release();

    // Every second, update the window title with the FPS
    if (app.fps_timer.read() >= 1.0) {
        // Gather some text rendering stats
        var num_texts: u32 = 0;
        var num_glyphs: usize = 0;
        var q = try entities.query(.{
            .built_pipelines = gfx.Text.Mod.read(.built),
        });
        while (q.next()) |v| {
            for (v.built_pipelines) |built| {
                num_texts += 1;
                num_glyphs += built.glyphs.items.len;
            }
        }

        try core.printTitle(
            core.main_window,
            "text [ FPS: {d} ] [ Texts: {d} ] [ Glyphs: {d} ]",
            .{ app.frame_count, num_texts, num_glyphs },
        );
        core.schedule(.update);
        app.fps_timer.reset();
        app.frame_count = 0;
    }
    app.frame_count += 1;
}
