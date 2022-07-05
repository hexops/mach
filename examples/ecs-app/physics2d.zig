const mach = @import("mach");
const ecs = mach.ecs;
const std = @import("std");

pub const Message = ecs.Messages(.{
    .tick = void,
});

pub const module = ecs.Module(.{
    .components = .{
        .location = Vec2,
        .rotation = Vec2,
        .velocity = Vec2,
    },
    .messages = Message,
    .system = system,
});

pub const Vec2 = struct { x: f32, y: f32 };

fn system(msg: Message) !void {
    switch (msg) {
        // TODO: implement queries, ability to set components, etc.
        .tick => std.debug.print("\nphysics tick!\n", .{}),
    }
}
