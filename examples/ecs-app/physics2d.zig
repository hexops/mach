const mach = @import("mach");
const ecs = mach.ecs;

pub const module = ecs.Module(.{
    .components = .{
        .location = Vec2,
        .rotation = Vec2,
        .velocity = Vec2,
    },
});

pub const Vec2 = struct { x: f32, y: f32 };
