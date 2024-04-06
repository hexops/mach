const std = @import("std");
const zigimg = @import("zigimg");
const assets = @import("assets");
const mach = @import("mach");
const core = mach.core;
const gfx = mach.gfx;
const gpu = mach.gpu;
const ecs = mach.ecs;
const Text = mach.gfx.Text;
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
player: mach.ecs.EntityID,
direction: Vec2 = vec2(0, 0),
spawning: bool = false,
spawn_timer: mach.Timer,
fps_timer: mach.Timer,
frame_count: usize,
texts: usize,
rand: std.rand.DefaultPrng,
time: f32,
style1: mach.ecs.EntityID,
allocator: std.mem.Allocator,

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

pub const global_events = .{
    .init = .{ .handler = init },
    .deinit = .{ .handler = deinit },
    .tick = .{ .handler = tick },
};

pub const Pipeline = enum(u32) {
    default,
};

const upscale = 1.0;

const text1: []const []const u8 = &.{
    "Text but with spaces 😊\nand\n",
    "italics\nand\n",
    "bold\nand\n",
};

const text2: []const []const u8 = &.{"!$?😊"};

fn init(
    engine: *mach.Engine.Mod,
    text_mod: *Text.Mod,
    game: *Mod,
) !void {
    // The Mach .core is where we set window options, etc.
    core.setTitle("gfx.Text example");

    // TODO: a better way to initialize entities with default values
    const style1 = try engine.newEntity();
    try text_mod.set(style1, .font_name, "Roboto Medium"); // TODO
    try text_mod.set(style1, .font_size, 48 * gfx.px_per_pt); // 48pt
    try text_mod.set(style1, .font_weight, gfx.font_weight_normal);
    try text_mod.set(style1, .italic, false);
    try text_mod.set(style1, .color, vec4(0.6, 1.0, 0.6, 1.0));

    const style2 = try engine.newEntity();
    try text_mod.set(style2, .font_name, "Roboto Medium"); // TODO
    try text_mod.set(style2, .font_size, 48 * gfx.px_per_pt); // 48pt
    try text_mod.set(style2, .font_weight, gfx.font_weight_normal);
    try text_mod.set(style2, .italic, true);
    try text_mod.set(style2, .color, vec4(0.6, 1.0, 0.6, 1.0));

    const style3 = try engine.newEntity();
    try text_mod.set(style3, .font_name, "Roboto Medium"); // TODO
    try text_mod.set(style3, .font_size, 48 * gfx.px_per_pt); // 48pt
    try text_mod.set(style3, .font_weight, gfx.font_weight_bold);
    try text_mod.set(style3, .italic, false);
    try text_mod.set(style3, .color, vec4(0.6, 1.0, 0.6, 1.0));

    // Create some text
    const player = try engine.newEntity();
    try text_mod.set(player, .pipeline, @intFromEnum(Pipeline.default));
    try text_mod.set(player, .transform, Mat4x4.scaleScalar(upscale).mul(&Mat4x4.translate(vec3(0, 0, 0))));

    // TODO: better storage mechanism for this
    // TODO: this is a leak
    const allocator = gpa.allocator();
    const styles = try allocator.alloc(mach.ecs.EntityID, 3);
    styles[0] = style1;
    styles[1] = style2;
    styles[2] = style3;
    try text_mod.set(player, .text, text1);
    try text_mod.set(player, .style, styles);

    text_mod.send(.init_pipeline, .{Text.PipelineOptions{
        .pipeline = @intFromEnum(Pipeline.default),
    }});
    engine.dispatchNoError(); // TODO: no dispatch in user code

    game.init(.{
        .timer = try mach.Timer.start(),
        .spawn_timer = try mach.Timer.start(),
        .player = player,
        .fps_timer = try mach.Timer.start(),
        .frame_count = 0,
        .texts = 0,
        .rand = std.rand.DefaultPrng.init(1337),
        .time = 0,
        .style1 = style1,
        .allocator = allocator,
    });
}

fn deinit(engine: *mach.Engine.Mod) !void {
    _ = engine;
}

fn tick(
    engine: *mach.Engine.Mod,
    text_mod: *Text.Mod,
    game: *Mod,
) !void {
    // TODO(engine): event polling should occur in mach.Engine module and get fired as ECS events.
    var iter = core.pollEvents();
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
            .close => engine.send(.exit, .{}),
            else => {},
        }
    }
    game.state().direction = direction;
    game.state().spawning = spawning;

    var player_transform = text_mod.get(game.state().player, .transform).?;
    var player_pos = player_transform.translation().divScalar(upscale);
    if (spawning and game.state().spawn_timer.read() > 1.0 / 60.0) {
        // Spawn new entities
        _ = game.state().spawn_timer.lap();
        for (0..1) |_| {
            var new_pos = player_pos;
            new_pos.v[0] += game.state().rand.random().floatNorm(f32) * 25;
            new_pos.v[1] += game.state().rand.random().floatNorm(f32) * 25;

            const new_entity = try engine.newEntity();
            try text_mod.set(new_entity, .pipeline, @intFromEnum(Pipeline.default));
            try text_mod.set(new_entity, .transform, Mat4x4.scaleScalar(upscale).mul(&Mat4x4.translate(new_pos)));

            // TODO: better storage mechanism for this
            // TODO: this is a leak
            const styles = try game.state().allocator.alloc(mach.ecs.EntityID, 1);
            styles[0] = game.state().style1;
            try text_mod.set(new_entity, .text, text2);
            try text_mod.set(new_entity, .style, styles);

            game.state().texts += 1;
        }
    }

    // Multiply by delta_time to ensure that movement is the same speed regardless of the frame rate.
    const delta_time = game.state().timer.lap();

    // Rotate entities
    var archetypes_iter = engine.entities.query(.{ .all = &.{
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
            // try text_mod.set(id, .transform, transform);
            old_transform.* = transform;
        }
    }

    // Calculate the player position, by moving in the direction the player wants to go
    // by the speed amount.
    const speed = 200.0 / upscale;
    player_pos.v[0] += direction.x() * speed * delta_time;
    player_pos.v[1] += direction.y() * speed * delta_time;
    try text_mod.set(game.state().player, .transform, Mat4x4.scaleScalar(upscale).mul(&Mat4x4.translate(player_pos)));
    text_mod.send(.updated, .{@intFromEnum(Pipeline.default)});

    // Perform pre-render work
    text_mod.send(.pre_render, .{@intFromEnum(Pipeline.default)});

    // Render a frame
    engine.send(.begin_pass, .{gpu.Color{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 }});
    text_mod.send(.render, .{@intFromEnum(Pipeline.default)});
    engine.send(.end_pass, .{});
    engine.send(.present, .{}); // Present the frame

    // Every second, update the window title with the FPS
    if (game.state().fps_timer.read() >= 1.0) {
        try core.printTitle("gfx.Text example [ FPS: {d} ] [ Texts: {d} ]", .{ game.state().frame_count, game.state().texts });
        game.state().fps_timer.reset();
        game.state().frame_count = 0;
    }
    game.state().frame_count += 1;
    game.state().time += delta_time;
}
