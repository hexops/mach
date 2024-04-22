const std = @import("std");
const mach = @import("mach");
const math = mach.math;
const Renderer = @import("Renderer.zig");

const vec3 = math.vec3;
const vec2 = math.vec2;
const Vec2 = math.Vec2;
const Vec3 = math.Vec3;

// Global state for our game module.
timer: mach.Timer,
player: mach.EntityID,
direction: Vec2 = vec2(0, 0),
spawning: bool = false,
spawn_timer: mach.Timer,

// Components our game module defines.
pub const components = .{
    // Whether an entity is a "follower" of our player entity or not. The type is void because we
    // don't need any information, this is just a tag we assign to an entity with no data.
    .follower = .{ .type = void },
};

// Global events that we will listen for.
pub const global_events = .{
    .init = .{ .handler = init }, // Event sent on app startup
    .tick = .{ .handler = tick }, // Event sent on each frame
};

// Define the globally unique name of our module. You can use any name here, but keep in mind no
// two modules in the program can have the same name.
pub const name = .game;

// The mach.Mod type corresponding to our module struct (this file.) This provides methods for
// working with this module (e.g. sending events, working with its components, etc.)
//
// Note that Mod.state() returns an instance of our module struct.
pub const Mod = mach.Mod(@This());

// TODO(important): remove need for returning an error here
fn init(
    // These are injected dependencies - as long as these modules were registered in the top-level
    // of the program we can have these types injected here, letting us work with other modules in
    // our program seamlessly and with a type-safe API:
    core: *mach.Core.Mod,
    renderer: *Renderer.Mod,
    game: *Mod,
) !void {
    // Create our player entity.
    const player = try core.newEntity();

    // Give our player entity a .renderer.position and .renderer.scale component. Note that these
    // are defined by the Renderer module, so we use `renderer: *Renderer.Mod` to interact with
    // them.
    //
    // Components live in a module's namespace, so e.g. a physics2d module and renderer3d module could
    // both define a .position component with a different data type, and both could be added to the
    // same entity.
    try renderer.set(player, .position, vec3(0, 0, 0));
    try renderer.set(player, .scale, 1.0);

    // Initialize our game module's state - these are the struct fields defined at the top of this
    // file. If this is not done, then game.state() will panic indicating the state was never
    // initialized.
    game.init(.{
        .timer = try mach.Timer.start(),
        .spawn_timer = try mach.Timer.start(),
        .player = player,
    });
}

// TODO(important): remove need for returning an error here
fn tick(
    core: *mach.Core.Mod,
    renderer: *Renderer.Mod,
    game: *Mod,
) !void {
    // TODO(important): event polling should occur in mach.Core module and get fired as ECS event.
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
            .close => core.send(.exit, .{}), // Send an event telling mach to exit the app
            else => {},
        }
    }

    // Keep track of which direction we want the player to move based on input, and whether we want
    // to be spawning entities.
    //
    // Note that game.state() simply returns a pointer to a global singleton of the struct defined
    // by this file, so we can access fields defined at the top of this file.
    game.state().direction = direction;
    game.state().spawning = spawning;

    // Get the current player position
    var player_pos = renderer.get(game.state().player, .position).?;

    // If we want to spawn new entities, then spawn them now. The timer just makes spawning rate
    // independent of frame rate.
    if (spawning and game.state().spawn_timer.read() > 1.0 / 60.0) {
        _ = game.state().spawn_timer.lap(); // Reset the timer
        for (0..5) |_| {
            // Spawn a new entity at the same position as the player, but smaller in scale.
            const new_entity = try core.newEntity();
            try renderer.set(new_entity, .position, player_pos);
            try renderer.set(new_entity, .scale, 1.0 / 6.0);

            // Tag the entity as one that follows the player
            try game.set(new_entity, .follower, {});
        }
    }

    // Multiply by delta_time to ensure that movement is the same speed regardless of the frame rate.
    const delta_time = game.state().timer.lap();

    // Calculate the player position, by moving in the direction the player wants to go
    // by the speed amount.
    const speed = 1.0;
    player_pos.v[0] += direction.x() * speed * delta_time;
    player_pos.v[1] += direction.y() * speed * delta_time;
    try renderer.set(game.state().player, .position, player_pos);

    // Query all the entities that have the .follower tag indicating they should follow the player.
    // TODO(important): better querying API
    var archetypes_iter = core.entities.query(.{ .all = &.{
        .{ .game = &.{.follower} },
    } });
    while (archetypes_iter.next()) |archetype| {
        // Iterate the ID and position of each entity
        const ids = archetype.slice(.entity, .id);
        const positions = archetype.slice(.renderer, .position);
        for (ids, positions) |id, position| {
            // Nested query to find all the other follower entities that we should move away from.
            // We will avoid all other follower entities if we're too close to them.
            // This is not very efficient, but it works!
            const close_dist = 1.0 / 15.0;
            var avoidance = Vec3.splat(0);
            var avoidance_div: f32 = 1.0;
            var archetypes_iter_2 = core.entities.query(.{ .all = &.{
                .{ .game = &.{.follower} },
            } });
            while (archetypes_iter_2.next()) |archetype_2| {
                const other_ids = archetype_2.slice(.entity, .id);
                const other_positions = archetype_2.slice(.renderer, .position);
                for (other_ids, other_positions) |other_id, other_position| {
                    if (id == other_id) continue;
                    if (position.dist(&other_position) < close_dist) {
                        avoidance = avoidance.sub(&position.dir(&other_position, 0.0000001));
                        avoidance_div += 1.0;
                    }
                }
            }

            // Avoid the player if we're too close to it
            var avoid_player_multiplier: f32 = 1.0;
            if (position.dist(&player_pos) < close_dist * 6.0) {
                avoidance = avoidance.sub(&position.dir(&player_pos, 0.0000001));
                avoidance_div += 1.0;
                avoid_player_multiplier = 4.0;
            }

            // Determine our new position, taking into account things we want to avoid
            const move_speed = 1.0 * delta_time;
            var new_position = position.add(&avoidance.divScalar(avoidance_div).mulScalar(move_speed * avoid_player_multiplier));

            // Try to move towards the center of the world if we don't need to avoid something else
            new_position = new_position.lerp(&vec3(0, 0, 0), move_speed / avoidance_div);

            // Finally, update our entity position.
            try renderer.set(id, .position, new_position);
        }
    }
}
