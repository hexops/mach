const mach = @import("mach");
const ecs = mach.ecs;

pub const module = ecs.Module(.{
    .components = .{
        .location = Vec3,
        .rotation = Vec3,
    },
    // TODO: there would be systems that we register here. Functions that iterate over entities
    // with renderer components like `.geometry` and render them for example!
});

pub const Vec3 = struct { x: f32, y: f32, z: f32 };
