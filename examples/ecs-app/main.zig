// Experimental ECS app example. Not yet ready for actual use.

const std = @import("std");
const mach = @import("mach");
const gpu = mach.gpu;
const ecs = mach.ecs;

// TODO: rename *ecs.World to *engine.Engine or something

const renderer = @import("renderer.zig");
const physics2d = @import("physics2d.zig");

// Define all the modules in our application. Modules can have components, systems, state,
// and/or global values in them. They can also send and receive messages to coordinate
// with each-other.
//
// Single-word module names (`.mach`, `.renderer`, etc.) are reserved for the application itself.
//
// Modules that come from libraries must be prefixed (e.g. `.bullet_physics`, `.ziglibs_box2d`)
// similar to GitHub repositories, to avoid conflicts with one another. Note that modules themselves
// will interact with the ECS using e.g. `.getComponent(.bullet_physics, .location)` internally and
// so cannot be renamed here.
// TODO: just make this a list so one cannot even think renaming is possible here
const modules = ecs.Modules(.{
    .mach = mach.module,
    .renderer = renderer.module,
    .physics2d = physics2d.module,
});

// Our Mach app, which tells Mach where to find our modules and init entry point.
pub const App = mach.App(modules, init);

pub fn init(engine: *ecs.World(modules)) !void {
    // The Mach .core is where we set window options, etc.
    const core = engine.get(.mach, .core);
    try core.setOptions(.{ .title = "Hello, ECS!" });

    // We can get the GPU device:
    const device = engine.get(.mach, .device);
    _ = device; // TODO: actually show off using the GPU device

    // We can create entities, and set components on them. Note that components live in a module
    // namespace, so we set the `.renderer, .location` component which is different than the
    // `.physics2d, .location` component.

    // TODO: cut out the `.entities.` in this API to make it more brief
    const player = try engine.entities.new();
    try engine.entities.setComponent(player, .renderer, .location, .{ .x = 0, .y = 0, .z = 0 });
    try engine.entities.setComponent(player, .physics2d, .location, .{ .x = 0, .y = 0 });
    _ = player;

    // TODO: there could be an entities wrapper to interact with a single namespace so you don't
    // have to pass it in as a parameter always?
}
