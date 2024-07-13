// TODO(important): review all code in this file in-depth
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

timer: mach.Timer,
player: mach.EntityID,
direction: Vec2 = vec2(0, 0),
spawning: bool = false,
spawn_timer: mach.Timer,
fps_timer: mach.Timer,
frame_count: usize,
rand: std.rand.DefaultPrng,
time: f32,
style1: mach.EntityID,
pipeline: mach.EntityID,
frame_encoder: *gpu.CommandEncoder = undefined,
frame_render_pass: *gpu.RenderPassEncoder = undefined,

// Define the globally unique name of our module. You can use any name here, but keep in mind no
// two modules in the program can have the same name.
pub const name = .app;
pub const Mod = mach.Mod(@This());

pub const systems = .{
    .init = .{ .handler = init },
    .deinit = .{ .handler = deinit },
    .after_init = .{ .handler = afterInit },
    .update = .{ .handler = update },
    .end_frame = .{ .handler = endFrame },
};

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

fn init(
    text: *gfx.Text.Mod,
    text_pipeline: *gfx.TextPipeline.Mod,
    game: *Mod,
) !void {
    text.schedule(.init);
    text_pipeline.schedule(.init);
    game.schedule(.after_init);
}

fn afterInit(
    entities: *mach.Entities.Mod,
    text: *gfx.Text.Mod,
    text_pipeline: *gfx.TextPipeline.Mod,
    text_style: *gfx.TextStyle.Mod,
    game: *Mod,
) !void {
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

    game.init(.{
        .timer = try mach.Timer.start(),
        .spawn_timer = try mach.Timer.start(),
        .player = player,
        .fps_timer = try mach.Timer.start(),
        .frame_count = 0,
        .rand = std.rand.DefaultPrng.init(1337),
        .time = 0,
        .style1 = style1,
        .pipeline = pipeline,
    });
}

fn update(
    entities: *mach.Entities.Mod,
    core: *mach.Core.Mod,
    text: *gfx.Text.Mod,
    text_pipeline: *gfx.TextPipeline.Mod,
    game: *Mod,
) !void {
    // TODO(important): event polling should occur in mach.Core module and get fired as ECS events.
    // TODO(Core)
    var iter = core.state().pollEvents();
    var direction = game.state().direction;
    var spawning = game.state().spawning;
    while (iter.next()) |event| {
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
            .close => core.schedule(.exit),
            else => {},
        }
    }
    game.state().direction = direction;
    game.state().spawning = spawning;

    var player_transform = text.get(game.state().player, .transform).?;
    var player_pos = player_transform.translation().divScalar(upscale);
    if (spawning and game.state().spawn_timer.read() > (1.0 / 60.0)) {
        // Spawn new entities
        _ = game.state().spawn_timer.lap();
        for (0..10) |_| {
            var new_pos = player_pos;
            new_pos.v[0] += game.state().rand.random().floatNorm(f32) * 50;
            new_pos.v[1] += game.state().rand.random().floatNorm(f32) * 50;

            // Create some text
            const new_entity = try entities.new();
            try text.set(new_entity, .pipeline, game.state().pipeline);
            try text.set(new_entity, .transform, Mat4x4.scaleScalar(upscale).mul(&Mat4x4.translate(new_pos)));
            try gfx.Text.allocPrintText(text, new_entity, game.state().style1, "?!$", .{});
        }
    }

    // Multiply by delta_time to ensure that movement is the same speed regardless of the frame rate.
    const delta_time = game.state().timer.lap();

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
            transform = transform.mul(&Mat4x4.rotateZ(2 * math.pi * game.state().time));
            transform = transform.mul(&Mat4x4.scaleScalar(@min(math.cos(game.state().time / 2.0), 0.5)));
            entity_transform.* = transform;
        }
    }

    // Calculate the player position, by moving in the direction the player wants to go
    // by the speed amount.
    const speed = 200.0 / upscale;
    player_pos.v[0] += direction.x() * speed * delta_time;
    player_pos.v[1] += direction.y() * speed * delta_time;
    try text.set(game.state().player, .transform, Mat4x4.scaleScalar(upscale).mul(&Mat4x4.translate(player_pos)));
    try text.set(game.state().player, .dirty, true);
    text.schedule(.update);

    // Perform pre-render work
    text_pipeline.schedule(.pre_render);

    // Create a command encoder for this frame
    const label = @tagName(name) ++ ".tick";
    game.state().frame_encoder = core.state().device.createCommandEncoder(&.{ .label = label });

    // Grab the back buffer of the swapchain
    // TODO(Core)
    const back_buffer_view = core.state().swap_chain.getCurrentTextureView().?;
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

    // Render our text batch
    text_pipeline.state().render_pass = game.state().frame_render_pass;
    text_pipeline.schedule(.render);

    // Finish the frame once rendering is done.
    game.schedule(.end_frame);

    game.state().time += delta_time;
}

fn endFrame(
    entities: *mach.Entities.Mod,
    game: *Mod,
    core: *mach.Core.Mod,
) !void {
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

    // Every second, update the window title with the FPS
    if (game.state().fps_timer.read() >= 1.0) {
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

        try core.state().printTitle(
            core.state().main_window,
            "text [ FPS: {d} ] [ Texts: {d} ] [ Glyphs: {d} ]",
            .{ game.state().frame_count, num_texts, num_glyphs },
        );
        game.state().fps_timer.reset();
        game.state().frame_count = 0;
    }
    game.state().frame_count += 1;
}
