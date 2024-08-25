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

pub const systems = .{
    .start = .{ .handler = start },
    .init = .{ .handler = init },
    .deinit = .{ .handler = deinit },
    .tick = .{ .handler = tick },
    .end_frame = .{ .handler = endFrame },
};

fn deinit(core: *mach.Core.Mod, sprite_pipeline: *gfx.SpritePipeline.Mod, glyphs: *Glyphs.Mod) !void {
    sprite_pipeline.schedule(.deinit);
    glyphs.schedule(.deinit);
    core.schedule(.deinit);
}

fn start(core: *mach.Core.Mod, sprite_pipeline: *gfx.SpritePipeline.Mod, glyphs: *Glyphs.Mod, app: *Mod) !void {
    core.schedule(.init);
    sprite_pipeline.schedule(.init);
    glyphs.schedule(.init);

    // Prepare which glyphs we will render
    glyphs.schedule(.prepare);

    // Run our init code after glyphs module is initialized.
    app.schedule(.init);
}

fn init(
    entities: *mach.Entities.Mod,
    sprite: *gfx.Sprite.Mod,
    sprite_pipeline: *gfx.SpritePipeline.Mod,
    glyphs: *Glyphs.Mod,
    app: *Mod,
    core: *mach.Core.Mod,
) !void {
    core.state().on_tick = app.system(.tick);
    core.state().on_exit = app.system(.deinit);

    // Create a sprite rendering pipeline
    const texture = glyphs.state().texture;
    const pipeline = try entities.new();
    texture.reference();
    try sprite_pipeline.set(pipeline, .texture, texture);
    sprite_pipeline.schedule(.update);

    // We can create entities, and set components on them. Note that components live in a module
    // namespace, e.g. the `Sprite` module could have a 3D `.location` component with a different
    // type than the `.physics2d` module's `.location` component if you desire.

    const r = glyphs.state().regions.get('?').?;
    const player = try entities.new();
    try sprite.set(player, .transform, Mat4x4.translate(vec3(-0.02, 0, 0)));
    try sprite.set(player, .pipeline, pipeline);
    try sprite.set(player, .size, vec2(@floatFromInt(r.width), @floatFromInt(r.height)));
    try sprite.set(player, .uv_transform, Mat3x3.translate(vec2(@floatFromInt(r.x), @floatFromInt(r.y))));
    sprite.schedule(.update);

    app.init(.{
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

    core.schedule(.start);
}

fn tick(
    entities: *mach.Entities.Mod,
    core: *mach.Core.Mod,
    sprite: *gfx.Sprite.Mod,
    sprite_pipeline: *gfx.SpritePipeline.Mod,
    glyphs: *Glyphs.Mod,
    app: *Mod,
) !void {
    // TODO(important): event polling should occur in mach.Core module and get fired as ECS events.
    // TODO(Core)
    var iter = core.state().pollEvents();
    var direction = app.state().direction;
    var spawning = app.state().spawning;
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
    app.state().direction = direction;
    app.state().spawning = spawning;

    var player_transform = sprite.get(app.state().player, .transform).?;
    var player_pos = player_transform.translation();
    if (!spawning and app.state().spawn_timer.read() > 1.0 / 60.0) {
        // Spawn new entities
        _ = app.state().spawn_timer.lap();
        for (0..50) |_| {
            var new_pos = player_pos;
            new_pos.v[0] += app.state().rand.random().floatNorm(f32) * 25;
            new_pos.v[1] += app.state().rand.random().floatNorm(f32) * 25;

            const rand_index = app.state().rand.random().intRangeAtMost(usize, 0, glyphs.state().regions.count() - 1);
            const r = glyphs.state().regions.entries.get(rand_index).value;

            const new_entity = try entities.new();
            try sprite.set(new_entity, .transform, Mat4x4.translate(new_pos).mul(&Mat4x4.scaleScalar(0.3)));
            try sprite.set(new_entity, .size, vec2(@floatFromInt(r.width), @floatFromInt(r.height)));
            try sprite.set(new_entity, .uv_transform, Mat3x3.translate(vec2(@floatFromInt(r.x), @floatFromInt(r.y))));
            try sprite.set(new_entity, .pipeline, app.state().pipeline);
            app.state().sprites += 1;
        }
    }

    // Multiply by delta_time to ensure that movement is the same speed regardless of the frame rate.
    const delta_time = app.state().timer.lap();

    // Animate entities
    var q = try entities.query(.{
        .ids = mach.Entities.Mod.read(.id),
        .transforms = gfx.Sprite.Mod.write(.transform),
    });
    while (q.next()) |v| {
        for (v.ids, v.transforms) |id, *entity_transform| {
            var location = entity_transform.translation();
            // TODO: formatting
            // TODO(Core)
            if (location.x() < -@as(f32, @floatFromInt(core.state().size().width)) / 1.5 or location.x() > @as(f32, @floatFromInt(core.state().size().width)) / 1.5 or location.y() < -@as(f32, @floatFromInt(core.state().size().height)) / 1.5 or location.y() > @as(f32, @floatFromInt(core.state().size().height)) / 1.5) {
                try entities.remove(id);
                app.state().sprites -= 1;
                continue;
            }

            var transform = Mat4x4.ident;
            transform = transform.mul(&Mat4x4.scale(Vec3.splat(1.0 + (0.2 * delta_time))));
            transform = transform.mul(&Mat4x4.translate(location));
            transform = transform.mul(&Mat4x4.rotateZ(2 * math.pi * app.state().time));
            transform = transform.mul(&Mat4x4.scale(Vec3.splat(@max(math.cos(app.state().time / 2.0), 0.2))));
            entity_transform.* = transform;
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
    try sprite.set(app.state().player, .transform, player_transform);
    sprite.schedule(.update);

    // Perform pre-render work
    sprite_pipeline.schedule(.pre_render);

    // Create a command encoder for this frame
    const label = @tagName(name) ++ ".tick";
    app.state().frame_encoder = core.state().device.createCommandEncoder(&.{ .label = label });

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
    app.state().frame_render_pass = app.state().frame_encoder.beginRenderPass(&gpu.RenderPassDescriptor.init(.{
        .label = label,
        .color_attachments = &color_attachments,
    }));

    // Render our sprite batch
    sprite_pipeline.state().render_pass = app.state().frame_render_pass;
    sprite_pipeline.schedule(.render);

    // Finish the frame once rendering is done.
    app.schedule(.end_frame);

    app.state().time += delta_time;
}

fn endFrame(app: *Mod, core: *mach.Core.Mod) !void {
    // Finish render pass
    app.state().frame_render_pass.end();
    const label = @tagName(name) ++ ".endFrame";
    var command = app.state().frame_encoder.finish(&.{ .label = label });
    core.state().queue.submit(&[_]*gpu.CommandBuffer{command});
    command.release();
    app.state().frame_encoder.release();
    app.state().frame_render_pass.release();

    // Present the frame
    core.schedule(.present_frame);

    // Every second, update the window title with the FPS
    if (app.state().fps_timer.read() >= 1.0) {
        try core.state().printTitle(
            core.state().main_window,
            "glyphs [ FPS: {d} ] [ Sprites: {d} ]",
            .{ app.state().frame_count, app.state().sprites },
        );
        core.schedule(.update);
        app.state().fps_timer.reset();
        app.state().frame_count = 0;
    }
    app.state().frame_count += 1;
}
