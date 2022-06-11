const std = @import("std");
const mach = @import("mach");
const gpu = mach.gpu;
const ecs = mach.ecs;

const all_components = .{

};

pub const App = mach.App(all_components, init);

pub fn init(engine: *mach.Engine, world: *ecs.World(all_components)) !void {
    _ = engine;
    _ = world;
}
