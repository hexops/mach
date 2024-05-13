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

pub const systems = .{
    .init = .{ .handler = init },
    .deinit = .{ .handler = deinit },
    .tick = .{ .handler = tick },
};

// Define the globally unique name of our module. You can use any name here, but keep in mind no
// two modules in the program can have the same name.
pub const name = .app;

// The mach.Mod type corresponding to our module struct (this file.) This provides methods for
// working with this module (e.g. sending events, working with its components, etc.)
//
// Note that Mod.state() returns an instance of our module struct.
pub const Mod = mach.Mod(@This());

pub fn deinit(core: *mach.Core.Mod, renderer: *Renderer.Mod) void {
    renderer.schedule(.deinit);
    core.schedule(.deinit);
}

fn init(
    // These are injected dependencies - as long as these modules were registered in the top-level
    // of the program we can have these types injected here, letting us work with other modules in
    // our program seamlessly and with a type-safe API:
    entities: *mach.Entities.Mod,
    core: *mach.Core.Mod,
    renderer: *Renderer.Mod,
    game: *Mod,
) !void {
    core.schedule(.init);
    renderer.schedule(.init);

    // Create our player entity.
    const player = try entities.new();

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

    core.schedule(.start);
}

fn tick(
    entities: *mach.Entities.Mod,
    core: *mach.Core.Mod,
    renderer: *Renderer.Mod,
    game: *Mod,
) !void {
    // TODO(important): event polling should occur in mach.Core module and get fired as ECS event.
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
            .close => core.schedule(.exit), // Send an event telling mach to exit the app
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
            const new_entity = try entities.new();
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

    // Iterate the ID and position of each follower entity
    var q = try entities.query(.{
        .ids = mach.Entities.Mod.read(.id),
        .followers = Mod.read(.follower),
        .positions = Renderer.Mod.write(.position),
    });
    while (q.next()) |v| {
        for (v.ids, v.positions) |id, *position| {
            // Nested query to find all the other follower entities that we should move away from.
            // We will avoid all other follower entities if we're too close to them.
            // This is not very efficient, but it works!
            const close_dist = 1.0 / 15.0;
            var avoidance = Vec3.splat(0);
            var avoidance_div: f32 = 1.0;

            var q2 = try entities.query(.{
                .ids = mach.Entities.Mod.read(.id),
                .followers = Mod.read(.follower),
                .positions = Renderer.Mod.read(.position),
            });
            while (q2.next()) |v2| {
                for (v2.ids, v2.positions) |other_id, other_position| {
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
            position.* = new_position;
        }
    }

    renderer.schedule(.render_frame);
}
