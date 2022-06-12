pub usingnamespace @import("structs.zig");
pub usingnamespace @import("enums.zig");
pub const Core = @import("Core.zig");
pub const Timer = @import("Timer.zig");
pub const ResourceManager = @import("resource/ResourceManager.zig");
pub const gpu = @import("gpu");
pub const ecs = @import("ecs");

// TODO: rename Engine -> Core

/// The Mach engine ECS module. This enables access to `engine.get(.mach, .core)` `*Core` APIs, as
/// to for example `.setOptions(.{.title = "foobar"})`, or to access the GPU device via
/// `engine.get(.mach, .device)`
pub const module = ecs.Module(.{
    .globals = struct {
        core: *Engine,
        device: gpu.Device,
    },
});

pub fn App(
    modules: anytype,
    init: anytype, // fn (engine: *ecs.World(modules)) !void
) type {
    // TODO: validate modules.mach is the expected type.
    // TODO: validate init has the right function signature

    // Other modules would always allow the consumer to specify the selector, so they can rename the
    // module in the global namespace. The mach.module is special, though, its name is reserved.
    const selector = .mach;

    return struct {
        engine: ecs.World(modules),

        pub fn init(app: *@This(), core: *Engine) !void {
            app.* = .{
                .engine = try ecs.World(modules).init(core.allocator),
            };
            app.*.engine.set(selector, .core, core);
            app.*.engine.set(selector, .device, core.device);
            try init(&app.engine);
        }

        pub fn deinit(app: *@This(), core: *Engine) void {
            _ = app;
            _ = core;
            // TODO
        }

        pub fn update(app: *@This(), core: *Engine) !void {
            _ = app;
            _ = core;
            // TODO
        }

        pub fn resize(app: *@This(), core: *Engine, width: u32, height: u32) !void {
            _ = app;
            _ = core;
            _ = width;
            _ = height;
            // TODO
        }
    };
}
