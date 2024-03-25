const std = @import("std");
const zigimg = @import("zigimg");
const assets = @import("assets");
const mach = @import("mach");
const core = mach.core;
const gpu = mach.gpu;
const ecs = mach.ecs;
const Sprite = mach.gfx.Sprite;
const math = mach.math;

const vec2 = math.vec2;
const vec3 = math.vec3;
const Vec2 = math.Vec2;
const Vec3 = math.Vec3;
const Mat3x3 = math.Mat3x3;
const Mat4x4 = math.Mat4x4;

timer: mach.Timer,
player: mach.ecs.EntityID,
direction: Vec2 = vec2(0, 0),
spawning: bool = false,
spawn_timer: mach.Timer,
fps_timer: mach.Timer,
frame_count: usize,
sprites: usize,
rand: std.rand.DefaultPrng,
time: f32,

const d0 = 0.000001;

// Each module must have a globally unique name declared, it is impossible to use two modules with
// the same name in a program. To avoid name conflicts, we follow naming conventions:
//
// 1. `.mach` and the `.mach_foobar` namespace is reserved for Mach itself and the modules it
//    provides.
// 2. Single-word names like `.game` are reserved for the application itself.
// 3. Libraries which provide modules MUST be prefixed with an "owner" name, e.g. `.ziglibs_imgui`
//    instead of `.imgui`. We encourage using e.g. your GitHub name, as these must be globally
//    unique.
//
pub const name = .game;
pub const Mod = mach.Mod(@This());

pub const events = .{
    .{ .global = .init, .handler = init },
    .{ .global = .tick, .handler = tick },
};

pub const Pipeline = enum(u32) {
    default,
};

fn init(
    engine: *mach.Engine.Mod,
    sprite_mod: *Sprite.Mod,
    game: *Mod,
) !void {
    // The Mach .core is where we set window options, etc.
    core.setTitle("gfx.Sprite example");

    // We can create entities, and set components on them. Note that components live in a module
    // namespace, e.g. the `.mach_gfx_sprite` module could have a 3D `.location` component with a different
    // type than the `.physics2d` module's `.location` component if you desire.

    const player = try engine.newEntity();
    try sprite_mod.set(player, .transform, Mat4x4.translate(vec3(-0.02, 0, 0)));
    try sprite_mod.set(player, .size, vec2(32, 32));
    try sprite_mod.set(player, .uv_transform, Mat3x3.translate(vec2(0, 0)));
    try sprite_mod.set(player, .pipeline, @intFromEnum(Pipeline.default));

    sprite_mod.send(.init, .{});
    sprite_mod.send(.initPipeline, .{Sprite.PipelineOptions{
        .pipeline = @intFromEnum(Pipeline.default),
        .texture = try loadTexture(engine),
    }});
    sprite_mod.send(.updated, .{@intFromEnum(Pipeline.default)});

    game.state = .{
        .timer = try mach.Timer.start(),
        .spawn_timer = try mach.Timer.start(),
        .player = player,
        .fps_timer = try mach.Timer.start(),
        .frame_count = 0,
        .sprites = 0,
        .rand = std.rand.DefaultPrng.init(1337),
        .time = 0,
    };
}

fn tick(
    engine: *mach.Engine.Mod,
    sprite_mod: *Sprite.Mod,
    game: *Mod,
) !void {
    // TODO(engine): event polling should occur in mach.Engine module and get fired as ECS events.
    var iter = core.pollEvents();
    var direction = game.state.direction;
    var spawning = game.state.spawning;
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
            .close => engine.send(.exit, .{}),
            else => {},
        }
    }
    game.state.direction = direction;
    game.state.spawning = spawning;

    var player_transform = sprite_mod.get(game.state.player, .transform).?;
    var player_pos = player_transform.translation();
    if (spawning and game.state.spawn_timer.read() > 1.0 / 60.0) {
        // Spawn new entities
        _ = game.state.spawn_timer.lap();
        for (0..100) |_| {
            var new_pos = player_pos;
            new_pos.v[0] += game.state.rand.random().floatNorm(f32) * 25;
            new_pos.v[1] += game.state.rand.random().floatNorm(f32) * 25;

            const new_entity = try engine.newEntity();
            try sprite_mod.set(new_entity, .transform, Mat4x4.translate(new_pos).mul(&Mat4x4.scale(Vec3.splat(0.3))));
            try sprite_mod.set(new_entity, .size, vec2(32, 32));
            try sprite_mod.set(new_entity, .uv_transform, Mat3x3.translate(vec2(0, 0)));
            try sprite_mod.set(new_entity, .pipeline, @intFromEnum(Pipeline.default));
            game.state.sprites += 1;
        }
    }

    // Multiply by delta_time to ensure that movement is the same speed regardless of the frame rate.
    const delta_time = game.state.timer.lap();

    // Rotate entities
    var archetypes_iter = engine.entities.query(.{ .all = &.{
        .{ .mach_gfx_sprite = &.{.transform} },
    } });
    while (archetypes_iter.next()) |archetype| {
        const ids = archetype.slice(.entity, .id);
        const transforms = archetype.slice(.mach_gfx_sprite, .transform);
        for (ids, transforms) |id, *old_transform| {
            _ = id;
            const location = old_transform.*.translation();
            // var transform = old_transform.mul(&Mat4x4.translate(-location));
            // transform = mat.rotateZ(0.3 * delta_time).mul(&transform);
            // transform = transform.mul(&Mat4x4.translate(location));
            var transform = Mat4x4.ident;
            transform = transform.mul(&Mat4x4.translate(location));
            transform = transform.mul(&Mat4x4.rotateZ(2 * math.pi * game.state.time));
            transform = transform.mul(&Mat4x4.scaleScalar(@min(math.cos(game.state.time / 2.0), 0.5)));

            // TODO: .set() API is substantially slower due to internals
            // try sprite_mod.set(id, .transform, transform);
            old_transform.* = transform;
        }
    }

    // Calculate the player position, by moving in the direction the player wants to go
    // by the speed amount.
    const speed = 200.0;
    player_pos.v[0] += direction.x() * speed * delta_time;
    player_pos.v[1] += direction.y() * speed * delta_time;
    try sprite_mod.set(game.state.player, .transform, Mat4x4.translate(player_pos));
    sprite_mod.send(.updated, .{@intFromEnum(Pipeline.default)});

    // Perform pre-render work
    sprite_mod.send(.preRender, .{@intFromEnum(Pipeline.default)});

    // Render a frame
    engine.send(.beginPass, .{gpu.Color{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 }});
    sprite_mod.send(.render, .{@intFromEnum(Pipeline.default)});
    engine.send(.endPass, .{});
    engine.send(.present, .{}); // Present the frame

    // Every second, update the window title with the FPS
    if (game.state.fps_timer.read() >= 1.0) {
        try core.printTitle("gfx.Sprite example [ FPS: {d} ] [ Sprites: {d} ]", .{ game.state.frame_count, game.state.sprites });
        game.state.fps_timer.reset();
        game.state.frame_count = 0;
    }
    game.state.frame_count += 1;
    game.state.time += delta_time;
}

// TODO: move this helper into gfx module
fn loadTexture(
    engine: *mach.Engine.Mod,
) !*gpu.Texture {
    const device = engine.state.device;
    const queue = device.getQueue();

    // Load the image from memory
    var img = try zigimg.Image.fromMemory(engine.allocator, assets.sprites_sheet_png);
    defer img.deinit();
    const img_size = gpu.Extent3D{ .width = @as(u32, @intCast(img.width)), .height = @as(u32, @intCast(img.height)) };

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
    const data_layout = gpu.Texture.DataLayout{
        .bytes_per_row = @as(u32, @intCast(img.width * 4)),
        .rows_per_image = @as(u32, @intCast(img.height)),
    };
    switch (img.pixels) {
        .rgba32 => |pixels| queue.writeTexture(&.{ .texture = texture }, &data_layout, &img_size, pixels),
        .rgb24 => |pixels| {
            const data = try rgb24ToRgba32(engine.allocator, pixels);
            defer data.deinit(engine.allocator);
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
