pub usingnamespace @import("structs.zig");
pub usingnamespace @import("enums.zig");
pub const Core = @import("Core.zig");
pub const Timer = @import("Timer.zig");
pub const ResourceManager = @import("resource/ResourceManager.zig");
pub const gpu = @import("gpu");
pub const ecs = @import("ecs");

pub fn App(
    all_components: anytype,
    init: fn(
        engine: *Engine,
        world: *ecs.World(all_components),
    ) error{OutOfMemory}!void,
) type {
    return struct {
        world: ecs.World(all_components),

        pub fn init(app: *@This(), engine: *Engine) !void {
            app.* = .{
                .world = try ecs.World(all_components).init(engine.allocator),
            };
            try init(engine, &app.world);
        }
        
        pub fn deinit(app: *@This(), engine: *Engine) void {
            _ = app;
            _ = engine;
            // TODO
        }
        
        pub fn update(app: *@This(), engine: *Engine) !void {
            _ = app;
            _ = engine;
            // TODO
        }
        
        pub fn resize(app: *@This(), engine: *Engine, width: u32, height: u32) !void {
            _ = app;
            _ = engine;
            _ = width;
            _ = height;
            // TODO
        }
    };
}
