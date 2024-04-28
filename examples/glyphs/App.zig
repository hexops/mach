// TODO(important): review all code in this file in-depth
const std = @import("std");
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

const Glyphs = @import("Glyphs.zig");

timer: mach.Timer,
player: mach.EntityID,
direction: Vec2 = vec2(0, 0),
spawning: bool = false,
spawn_timer: mach.Timer,
fps_timer: mach.Timer,
frame_count: usize,
sprites: usize,
rand: std.rand.DefaultPrng,
time: f32,
pipeline: mach.EntityID,
frame_encoder: *gpu.CommandEncoder = undefined,
frame_render_pass: *gpu.RenderPassEncoder = undefined,

// Define the globally unique name of our module. You can use any name here, but keep in mind no
// two modules in the program can have the same name.
pub const name = .app;
pub const Mod = mach.Mod(@This());

pub const local_events = .{
    .init = .{ .handler = init },
    .deinit = .{ .handler = deinit },
    .tick = .{ .handler = tick },
    .after_init = .{ .handler = afterInit },
    .end_frame = .{ .handler = endFrame },
};

fn deinit(core: *mach.Core.Mod, sprite_pipeline: *gfx.SpritePipeline.Mod, glyphs: *Glyphs.Mod) !void {
    sprite_pipeline.send(.deinit, .{});
    glyphs.send(.deinit, .{});
    core.send(.deinit, .{});
}

fn init(sprite_pipeline: *gfx.SpritePipeline.Mod, glyphs: *Glyphs.Mod, game: *Mod) !void {
    sprite_pipeline.send(.init, .{});
    glyphs.send(.init, .{});

    // Prepare which glyphs we will render
    glyphs.send(.prepare, .{&[_]u21{ '?', '!', 'a', 'b', '#', '@', '%', '$', '&', '^', '*', '+', '=', '<', '>', '/', ':', ';', 'Q', '~' }});

    // Run our init code after glyphs module is initialized.
    game.send(.after_init, .{});
}

fn afterInit(
    sprite: *gfx.Sprite.Mod,
    sprite_pipeline: *gfx.SpritePipeline.Mod,
    glyphs: *Glyphs.Mod,
    game: *Mod,
) !void {
    // Create a sprite rendering pipeline
    const texture = glyphs.state().texture;
    const pipeline = try sprite_pipeline.newEntity();
    try sprite_pipeline.set(pipeline, .texture, texture);
    sprite_pipeline.send(.update, .{});

    // We can create entities, and set components on them. Note that components live in a module
    // namespace, e.g. the `Sprite` module could have a 3D `.location` component with a different
    // type than the `.physics2d` module's `.location` component if you desire.

    const r = glyphs.state().regions.get('?').?;
    const player = try sprite.newEntity();
    try sprite.set(player, .transform, Mat4x4.translate(vec3(-0.02, 0, 0)));
    try sprite.set(player, .pipeline, pipeline);
    try sprite.set(player, .size, vec2(@floatFromInt(r.width), @floatFromInt(r.height)));
    try sprite.set(player, .uv_transform, Mat3x3.translate(vec2(@floatFromInt(r.x), @floatFromInt(r.y))));
    sprite.send(.update, .{});

    game.init(.{
        .timer = try mach.Timer.start(),
        .spawn_timer = try mach.Timer.start(),
        .player = player,
        .fps_timer = try mach.Timer.start(),
        .frame_count = 0,
        .sprites = 0,
        .rand = std.rand.DefaultPrng.init(1337),
        .time = 0,
        .pipeline = pipeline,
    });
}

fn tick(
    core: *mach.Core.Mod,
    sprite: *gfx.Sprite.Mod,
    sprite_pipeline: *gfx.SpritePipeline.Mod,
    glyphs: *Glyphs.Mod,
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

    var player_transform = sprite.get(game.state().player, .transform).?;
    var player_pos = player_transform.translation();
    if (!spawning and game.state().spawn_timer.read() > 1.0 / 60.0) {
        // Spawn new entities
        _ = game.state().spawn_timer.lap();
        for (0..50) |_| {
            var new_pos = player_pos;
            new_pos.v[0] += game.state().rand.random().floatNorm(f32) * 25;
            new_pos.v[1] += game.state().rand.random().floatNorm(f32) * 25;

            const rand_index = game.state().rand.random().intRangeAtMost(usize, 0, glyphs.state().regions.count() - 1);
            const r = glyphs.state().regions.entries.get(rand_index).value;

            const new_entity = try core.newEntity();
            try sprite.set(new_entity, .transform, Mat4x4.translate(new_pos).mul(&Mat4x4.scaleScalar(0.3)));
            try sprite.set(new_entity, .size, vec2(@floatFromInt(r.width), @floatFromInt(r.height)));
            try sprite.set(new_entity, .uv_transform, Mat3x3.translate(vec2(@floatFromInt(r.x), @floatFromInt(r.y))));
            try sprite.set(new_entity, .pipeline, game.state().pipeline);
            game.state().sprites += 1;
        }
    }

    // Multiply by delta_time to ensure that movement is the same speed regardless of the frame rate.
    const delta_time = game.state().timer.lap();

    // Animate entities
    var archetypes_iter = core.entities.query(.{ .all = &.{
        .{ .mach_gfx_sprite = &.{.transform} },
    } });
    while (archetypes_iter.next()) |archetype| {
        const ids = archetype.slice(.entity, .id);
        const transforms = archetype.slice(.mach_gfx_sprite, .transform);
        for (ids, transforms) |id, *old_transform| {
            var location = old_transform.translation();
            // TODO: formatting
            // TODO(Core)
            if (location.x() < -@as(f32, @floatFromInt(mach.core.size().width)) / 1.5 or location.x() > @as(f32, @floatFromInt(mach.core.size().width)) / 1.5 or location.y() < -@as(f32, @floatFromInt(mach.core.size().height)) / 1.5 or location.y() > @as(f32, @floatFromInt(mach.core.size().height)) / 1.5) {
                try core.entities.remove(id);
                game.state().sprites -= 1;
                continue;
            }

            var transform = Mat4x4.ident;
            transform = transform.mul(&Mat4x4.scale(Vec3.splat(1.0 + (0.2 * delta_time))));
            transform = transform.mul(&Mat4x4.translate(location));
            transform = transform.mul(&Mat4x4.rotateZ(2 * math.pi * game.state().time));
            transform = transform.mul(&Mat4x4.scale(Vec3.splat(@max(math.cos(game.state().time / 2.0), 0.2))));

            // TODO: .set() API is substantially slower due to internals
            // try sprite.set(id, .transform, transform);
            old_transform.* = transform;
        }
    }

    // Calculate the player position, by moving in the direction the player wants to go
    // by the speed amount.
    const speed = 200.0;
    player_pos.v[0] += direction.x() * speed * delta_time;
    player_pos.v[1] += direction.y() * speed * delta_time;
    player_transform = Mat4x4.translate(player_pos).mul(
        &Mat4x4.scale(Vec3.splat(1.0)),
    );
    try sprite.set(game.state().player, .transform, player_transform);
    sprite.send(.update, .{});

    // Perform pre-render work
    sprite_pipeline.send(.pre_render, .{});

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
    // TODO: can we eliminate this assignment
    game.state().frame_encoder = core.state().device.createCommandEncoder(&.{ .label = label });
    game.state().frame_render_pass = game.state().frame_encoder.beginRenderPass(&gpu.RenderPassDescriptor.init(.{
        .label = label,
        .color_attachments = &color_attachments,
    }));

    // Render our sprite batch
    sprite_pipeline.state().render_pass = game.state().frame_render_pass;
    sprite_pipeline.send(.render, .{});

    // Finish the frame once rendering is done.
    game.send(.end_frame, .{});

    game.state().time += delta_time;
}

fn endFrame(game: *Mod, core: *mach.Core.Mod) !void {
    // Finish render pass
    game.state().frame_render_pass.end();
    const label = @tagName(name) ++ ".endFrame";
    var command = game.state().frame_encoder.finish(&.{ .label = label });
    game.state().frame_encoder.release();
    defer command.release();
    core.state().queue.submit(&[_]*gpu.CommandBuffer{command});

    // Present the frame
    core.send(.present_frame, .{});

    // Every second, update the window title with the FPS
    if (game.state().fps_timer.read() >= 1.0) {
        try mach.Core.printTitle(
            core,
            core.state().main_window,
            "glyphs [ FPS: {d} ] [ Sprites: {d} ]",
            .{ game.state().frame_count, game.state().sprites },
        );
        core.send(.update, .{});
        game.state().fps_timer.reset();
        game.state().frame_count = 0;
    }
    game.state().frame_count += 1;
}
