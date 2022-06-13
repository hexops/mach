const std = @import("std");
const mach = @import("mach");
const gpu = mach.gpu;
const ecs = mach.ecs;

// TODO: *mach.Engine would be renamed to *mach.Core
// TODO: the "ecs" package would be renamed to "engine"
// TODO: *ecs.World would be renamed to *engine.Engine

const renderer = @import("renderer.zig");
const physics2d = @import("physics2d.zig");

// This defines all of the modules in our application. Modules can have components, systems, state,
// and global values in them. In the future, modules can send and receive messages to coordinate
// with each-other.
const modules = ecs.Modules(.{
    .mach = mach.module,
    .renderer = renderer.module,
    .physics2d = physics2d.module,

    // Note: Modules themselves will interact with the ECS, say by calling
    // `.getComponent(.physics2d, .location)` and so the name here must match the module's
    // expectation. You can't rename modules. Instead, we avoid collisions using some conventions:
    //
    // * `mach` is always the Mach module.
    // * One-word module names (`renderer`, `physics`, etc.) are reserved by Mach, you may use
    //   one-word module names in your application but future versions of Mach may add modules with
    //   that name and you'll have to rename yours to use that new functionality.
    // * Two-word module names (`bullet_physics`, `ziglibs_box2d`) are encouraged for third-party
    //   modules. If two conflict, you can't use them together without renaming one.
    //
});

// Our Mach app, which tells Mach where to find our modules and init entry point.
// It must be public, else you get an error. Yeah, it's a little magical.
pub const App = mach.App(modules, init);

pub fn init(engine: *ecs.World(modules)) !void {
    // The engine *is* the ECS. That's where everything in Mach lives and operates.

    // We can get the Mach core (previously called *Engine) to set window options, etc.:
    const core = engine.get(.mach, .core);
    try core.setOptions(.{ .title = "Hello, ECS!" });

    // We can get the GPU device:
    const device = engine.get(.mach, .device);
    _ = device; // use the GPU device ...

    // We can create entities, and set components on them. Note that components live in a module
    // namespace, so we set the `.renderer, .location` component which is different than the
    // `.physics2d, .location` component.

    // TODO: we could cut out the `.entities.` in this API to make it more brief:
    const player = try engine.entities.new();
    try engine.entities.setComponent(player, .renderer, .location, .{ .x = 0, .y = 0, .z = 0 });
    try engine.entities.setComponent(player, .physics2d, .location, .{ .x = 0, .y = 0 });
    _ = player;

    // TODO: there could be an entities wrapper to interact with a single namespace so you don't
    // have to pass it in as a parameter always.
}
