const mach = @import("mach");
const ecs = mach.ecs;

pub const module = Module(.renderer);

pub fn Module(namespace: anytype) type {
    _ = namespace;
    return ecs.Module(.{
        .components = .{
            .location = Vec3,
            .rotation = Vec3,
        },
        // TODO: there would be systems that we register here. Functions that iterate over entities
        // with renderer components like `.geometry` and render them for example!
        //
        // When calling ECS APIs, we would write this:
        //
        // .getComponent(namespace, .geometry);
        //
        // Not this:
        //
        // .getComponent(.renderer, .geometry);
        //
        // So as to be namespace-agonistic, letting the consumer of our module change the namespace
        // name where we access our components if needed.
    });
}

pub const Vec3 = struct { x: f32, y: f32, z: f32 };
