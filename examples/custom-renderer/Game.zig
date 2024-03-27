const std = @import("std");
const mach = @import("mach");
const ecs = mach.ecs;
const core = mach.core;
const math = mach.math;
const Renderer = @import("Renderer.zig");

const vec3 = math.vec3;
const vec2 = math.vec2;
const Vec2 = math.Vec2;
const Vec3 = math.Vec3;

timer: mach.Timer,
player: ecs.EntityID,
direction: Vec2 = vec2(0, 0),
spawning: bool = false,
spawn_timer: mach.Timer,

pub const components = .{
    .{ .name = .follower, .type = void },
};

pub const events = .{
    .{ .global = .init, .handler = init },
    .{ .global = .tick, .handler = tick },
};

// Each module must have a globally unique name declared, it is impossible to use two modules with
// the same name in a program. To avoid name conflicts, we follow naming conventions:
//
// 1. `.mach` and the `.mach_foobar` namespace is reserved for Mach itself and the modules it
//    provides.
// 2. Single-word names like `.renderer`, `.game`, etc. are reserved for the application itself.
// 3. Libraries which provide modules MUST be prefixed with an "owner" name, e.g. `.ziglibs_imgui`
//    instead of `.imgui`. We encourage using e.g. your GitHub name, as these must be globally
//    unique.
//
pub const name = .game;
pub const Mod = mach.Mod(@This());

// TODO(engine): remove need for returning an error here
fn init(
    engine: *mach.Engine.Mod,
    renderer: *Renderer.Mod,
    game: *Mod,
) !void {
    // The Mach .core is where we set window options, etc.
    core.setTitle("Hello, ECS!");

    // We can create entities, and set components on them. Note that components live in a module
    // namespace, e.g. the `.renderer` module could have a 3D `.location` component with a different
    // type than the `.physics2d` module's `.location` component if you desire.

    const player = try engine.newEntity();
    try renderer.set(player, .location, vec3(0, 0, 0));
    try renderer.set(player, .scale, 1.0);

    game.state = .{
        .timer = try mach.Timer.start(),
        .spawn_timer = try mach.Timer.start(),
        .player = player,
    };
}

// TODO(engine): remove need for returning an error here
fn tick(
    engine: *mach.Engine.Mod,
    renderer: *Renderer.Mod,
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

    var player_pos = renderer.get(game.state.player, .location).?;
    if (spawning and game.state.spawn_timer.read() > 1.0 / 60.0) {
        for (0..10) |_| {
            // Spawn a new follower entity
            _ = game.state.spawn_timer.lap();
            const new_entity = try engine.newEntity();
            try game.set(new_entity, .follower, {});
            try renderer.set(new_entity, .location, player_pos);
            try renderer.set(new_entity, .scale, 1.0 / 6.0);
        }
    }

    // Multiply by delta_time to ensure that movement is the same speed regardless of the frame rate.
    const delta_time = game.state.timer.lap();

    // Move following entities closer to us.
    var archetypes_iter = engine.entities.query(.{ .all = &.{
        .{ .game = &.{.follower} },
    } });
    while (archetypes_iter.next()) |archetype| {
        const ids = archetype.slice(.entity, .id);
        const locations = archetype.slice(.renderer, .location);
        for (ids, locations) |id, location| {
            // Avoid other follower entities by moving away from them if they are close to us.
            const close_dist = 1.0 / 15.0;
            var avoidance = Vec3.splat(0);
            var avoidance_div: f32 = 1.0;
            var archetypes_iter_2 = engine.entities.query(.{ .all = &.{
                .{ .game = &.{.follower} },
            } });
            while (archetypes_iter_2.next()) |archetype_2| {
                const other_ids = archetype_2.slice(.entity, .id);
                const other_locations = archetype_2.slice(.renderer, .location);
                for (other_ids, other_locations) |other_id, other_location| {
                    if (id == other_id) continue;
                    if (location.dist(&other_location) < close_dist) {
                        avoidance = avoidance.sub(&location.dir(&other_location, 0.0000001));
                        avoidance_div += 1.0;
                    }
                }
            }
            // Avoid the player
            var avoid_player_multiplier: f32 = 1.0;
            if (location.dist(&player_pos) < close_dist * 6.0) {
                avoidance = avoidance.sub(&location.dir(&player_pos, 0.0000001));
                avoidance_div += 1.0;
                avoid_player_multiplier = 4.0;
            }

            // Move away from things we want to avoid
            const move_speed = 1.0 * delta_time;
            var new_location = location.add(&avoidance.divScalar(avoidance_div).mulScalar(move_speed * avoid_player_multiplier));

            // Move towards the center
            new_location = new_location.lerp(&vec3(0, 0, 0), move_speed / avoidance_div);
            try renderer.set(id, .location, new_location);
        }
    }

    // Calculate the player position, by moving in the direction the player wants to go
    // by the speed amount.
    const speed = 1.0;
    player_pos.v[0] += direction.x() * speed * delta_time;
    player_pos.v[1] += direction.y() * speed * delta_time;
    try renderer.set(game.state.player, .location, player_pos);
}
