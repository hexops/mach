const mach = @import("mach");
const ecs = mach.ecs;

pub const module = ecs.Module(.{
    .components = .{
        .location = Vec2,
        .rotation = Vec2,
        .velocity = Vec2,
    },
    // TODO: there would be systems that we register here. Functions that iterate over entities
    // with physics2d components like `.velocity` and calculate physics updates for them!
    .system = system,
});

pub const Vec2 = struct { x: f32, y: f32 };

// TODO: there is a real problem here, we cannot access `modules`: dependency loop.
// modules -> physics2d.module -> system -> modules
fn system(engine: *ecs.World(modules)) !void {
    _ = engine;

    // A real system would query the ECS for entities with components. This is just an example.
    const player = try engine.entities.new();
    try engine.entities.setComponent(player, .physics2d, .location, .{ .x = 0, .y = 0 });
}
