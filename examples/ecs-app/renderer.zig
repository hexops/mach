const mach = @import("mach");
const ecs = mach.ecs;

pub const module = ecs.Module(.{
    .components = .{
        .location = Vec3,
        .rotation = Vec3,
    },
});

pub const Vec3 = struct { x: f32, y: f32, z: f32 };
