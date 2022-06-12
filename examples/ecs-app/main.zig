const std = @import("std");
const mach = @import("mach");
const gpu = mach.gpu;
const ecs = mach.ecs;

const modules = .{
    .core = mach.module,
};

pub const App = mach.App(modules, init);

pub fn init(engine: *ecs.World(modules)) !void {
    const core = engine.get(.core);
    try core.setOptions(.{ .title = "Hello, ECS!" });

    const device = core.device;
    _ = device; // use the GPU device ...
}
