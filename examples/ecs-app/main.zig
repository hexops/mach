const std = @import("std");
const mach = @import("mach");
const gpu = mach.gpu;
const ecs = mach.ecs;

const renderer = @import("renderer.zig");
const physics2d = @import("physics2d.zig");

const modules = ecs.Modules(.{
    .mach = mach.module,
    .renderer = renderer.module,
    .physics2d = physics2d.module,
});

pub const App = mach.App(modules, init);

pub fn init(engine: *ecs.World(modules)) !void {
    const core = engine.get(.mach, .core);
    try core.setOptions(.{ .title = "Hello, ECS!" });

    const device = engine.get(.mach, .device);
    _ = device; // use the GPU device ...
}
