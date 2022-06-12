const mach = @import("mach");
const ecs = mach.ecs;

pub const module = Module(.physics2d);

pub fn Module(namespace: anytype) type {
    _ = namespace;
    return ecs.Module(.{
        .components = .{
            .location = Vec2,
            .rotation = Vec2,
            .velocity = Vec2,
        },
        // TODO: there would be systems that we register here. Functions that iterate over entities
        // with physics2d components like `.velocity` and calculate physics updates for them!
    });
}

pub const Vec2 = struct { x: f32, y: f32 };
