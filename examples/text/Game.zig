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

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

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
allocator: std.mem.Allocator,
pipeline: mach.EntityID,
frame_encoder: *gpu.CommandEncoder = undefined,
frame_render_pass: *gpu.RenderPassEncoder = undefined,

// Define the globally unique name of our module. You can use any name here, but keep in mind no
// two modules in the program can have the same name.
pub const name = .game;
pub const Mod = mach.Mod(@This());

pub const global_events = .{
    .init = .{ .handler = init },
    .deinit = .{ .handler = deinit },
    .tick = .{ .handler = tick },
};

pub const local_events = .{
    .end_frame = .{ .handler = endFrame },
};

const upscale = 1.0;

const text1: []const []const u8 = &.{
    "Text but with spaces 😊\nand\n",
    "italics\nand\n",
    "bold\nand\n",
};

const text2: []const []const u8 = &.{"$!?😊"};

fn deinit(
    text_pipeline: *gfx.TextPipeline.Mod,
) !void {
    text_pipeline.send(.deinit, .{});
}

fn init(
    core: *mach.Core.Mod,
    text: *gfx.Text.Mod,
    text_pipeline: *gfx.TextPipeline.Mod,
    text_style: *gfx.TextStyle.Mod,
    game: *Mod,
) !void {
    text_pipeline.send(.init, .{});

    // TODO: a better way to initialize entities with default values
    // TODO(text): most of these style options are not respected yet.
    const style1 = try core.newEntity();
    try text_style.set(style1, .font_name, "Roboto Medium"); // TODO
    try text_style.set(style1, .font_size, 48 * gfx.px_per_pt); // 48pt
    try text_style.set(style1, .font_weight, gfx.font_weight_normal);
    try text_style.set(style1, .italic, false);
    try text_style.set(style1, .color, vec4(0.6, 1.0, 0.6, 1.0));

    const style2 = try core.newEntity();
    try text_style.set(style2, .font_name, "Roboto Medium"); // TODO
    try text_style.set(style2, .font_size, 48 * gfx.px_per_pt); // 48pt
    try text_style.set(style2, .font_weight, gfx.font_weight_normal);
    try text_style.set(style2, .italic, true);
    try text_style.set(style2, .color, vec4(0.6, 1.0, 0.6, 1.0));

    const style3 = try core.newEntity();
    try text_style.set(style3, .font_name, "Roboto Medium"); // TODO
    try text_style.set(style3, .font_size, 48 * gfx.px_per_pt); // 48pt
    try text_style.set(style3, .font_weight, gfx.font_weight_bold);
    try text_style.set(style3, .italic, false);
    try text_style.set(style3, .color, vec4(0.6, 1.0, 0.6, 1.0));

    // Create a text rendering pipeline
    const pipeline = try core.newEntity();
    try text_pipeline.set(pipeline, .is_pipeline, {});
    text_pipeline.send(.update, .{});

    // Create some text
    const player = try core.newEntity();
    try text.set(player, .pipeline, pipeline);
    try text.set(player, .transform, Mat4x4.scaleScalar(upscale).mul(&Mat4x4.translate(vec3(0, 0, 0))));

    // TODO: better storage mechanism for this
    // TODO: this is a leak
    const allocator = gpa.allocator();
    const styles = try allocator.alloc(mach.EntityID, 3);
    styles[0] = style1;
    styles[1] = style2;
    styles[2] = style3;
    try text.set(player, .text, text1);
    try text.set(player, .style, styles);
    try text.set(player, .dirty, true);

    game.init(.{
        .timer = try mach.Timer.start(),
        .spawn_timer = try mach.Timer.start(),
        .player = player,
        .fps_timer = try mach.Timer.start(),
        .frame_count = 0,
        .rand = std.rand.DefaultPrng.init(1337),
        .time = 0,
        .style1 = style1,
        .allocator = allocator,
        .pipeline = pipeline,
    });
}

fn tick(
    core: *mach.Core.Mod,
    text: *gfx.Text.Mod,
    text_pipeline: *gfx.TextPipeline.Mod,
    game: *Mod,
) !void {
    // TODO(important): event polling should occur in mach.Core module and get fired as ECS events.
    // TODO(Core)
    var iter = mach.core.pollEvents();
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
            .close => core.send(.exit, .{}),
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

            const new_entity = try core.newEntity();
            try text.set(new_entity, .pipeline, game.state().pipeline);
            try text.set(new_entity, .transform, Mat4x4.scaleScalar(upscale).mul(&Mat4x4.translate(new_pos)));

            // TODO: better storage mechanism for this
            // TODO: this is a leak
            const styles = try game.state().allocator.alloc(mach.EntityID, 1);
            styles[0] = game.state().style1;
            try text.set(new_entity, .text, text2);
            try text.set(new_entity, .style, styles);
            try text.set(new_entity, .dirty, true);
        }
    }

    // Multiply by delta_time to ensure that movement is the same speed regardless of the frame rate.
    const delta_time = game.state().timer.lap();

    // Rotate entities
    var archetypes_iter = core.entities.query(.{ .all = &.{
        .{ .mach_gfx_text = &.{.transform} },
    } });
    while (archetypes_iter.next()) |archetype| {
        const ids = archetype.slice(.entity, .id);
        const transforms = archetype.slice(.mach_gfx_text, .transform);
        for (ids, transforms) |id, *old_transform| {
            _ = id;
            const location = old_transform.*.translation();
            // var transform = old_transform.mul(&Mat4x4.translate(-location));
            // transform = mat.rotateZ(0.3 * delta_time).mul(&transform);
            // transform = transform.mul(&Mat4x4.translate(location));
            var transform = Mat4x4.ident;
            transform = transform.mul(&Mat4x4.translate(location));
            transform = transform.mul(&Mat4x4.rotateZ(2 * math.pi * game.state().time));
            transform = transform.mul(&Mat4x4.scaleScalar(@min(math.cos(game.state().time / 2.0), 0.5)));

            // TODO: .set() API is substantially slower due to internals
            // try text.set(id, .transform, transform);
            old_transform.* = transform;
        }
    }

    // Calculate the player position, by moving in the direction the player wants to go
    // by the speed amount.
    const speed = 200.0 / upscale;
    player_pos.v[0] += direction.x() * speed * delta_time;
    player_pos.v[1] += direction.y() * speed * delta_time;
    try text.set(game.state().player, .transform, Mat4x4.scaleScalar(upscale).mul(&Mat4x4.translate(player_pos)));
    try text.set(game.state().player, .dirty, true);
    text.send(.update, .{});

    // Perform pre-render work
    text_pipeline.send(.pre_render, .{});

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
    game.state().frame_encoder = core.state().device.createCommandEncoder(&.{ .label = label });
    game.state().frame_render_pass = game.state().frame_encoder.beginRenderPass(&gpu.RenderPassDescriptor.init(.{
        .label = label,
        .color_attachments = &color_attachments,
    }));

    // Render our text batch
    text_pipeline.state().render_pass = game.state().frame_render_pass;
    text_pipeline.send(.render, .{});

    // Finish the frame once rendering is done.
    game.send(.end_frame, .{});

    game.state().time += delta_time;
}

fn endFrame(game: *Mod, text: *gfx.Text.Mod, core: *mach.Core.Mod) !void {
    // Finish render pass
    game.state().frame_render_pass.end();
    const label = @tagName(name) ++ ".tick";
    var command = game.state().frame_encoder.finish(&.{ .label = label });
    game.state().frame_encoder.release();
    defer command.release();
    core.state().queue.submit(&[_]*gpu.CommandBuffer{command});

    // Present the frame
    core.send(.present_frame, .{});

    // Every second, update the window title with the FPS
    if (game.state().fps_timer.read() >= 1.0) {
        // Gather some text rendering stats
        var num_texts: u32 = 0;
        var num_glyphs: usize = 0;
        var archetypes_iter = text.entities.query(.{ .all = &.{
            .{ .mach_gfx_text = &.{
                .built,
            } },
        } });
        while (archetypes_iter.next()) |archetype| {
            const builts = archetype.slice(.mach_gfx_text, .built);
            for (builts) |built| {
                num_texts += 1;
                num_glyphs += built.glyphs.items.len;
            }
        }

        try mach.Core.printTitle(
            core,
            core.state().main_window,
            "text [ FPS: {d} ] [ Texts: {d} ] [ Glyphs: {d} ]",
            .{ game.state().frame_count, num_texts, num_glyphs },
        );
        core.send(.update, .{});
        game.state().fps_timer.reset();
        game.state().frame_count = 0;
    }
    game.state().frame_count += 1;
}
