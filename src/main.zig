pub usingnamespace @import("structs.zig");
pub usingnamespace @import("enums.zig");
pub const Core = @import("Core.zig");
pub const Timer = @import("Timer.zig");
pub const ResourceManager = @import("resource/ResourceManager.zig");
pub const gpu = @import("gpu");
pub const ecs = @import("ecs");

// TODO: rename Engine -> Core

/// The core module of Mach engine. This enables access to *Core APIs, such as
/// to `.setOptions(.{.title = "foobar"})`, or to access the GPU `.device`.
pub const module = ecs.Singleton(*Engine);

pub fn App(
    modules: anytype,
    init: anytype, // fn (engine: *ecs.World(modules)) !void
) type {
    return struct {
        engine: ecs.World(modules),

        pub fn init(app: *@This(), core: *Engine) !void {
            app.* = .{
                .engine = try ecs.World(modules).init(core.allocator),
            };
            app.*.engine.singletons.core = core;
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
