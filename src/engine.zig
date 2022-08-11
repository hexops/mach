pub const Core = @import("Core.zig");
pub const gpu = @import("gpu");
pub const ecs = @import("ecs");

/// The Mach engine ECS module. This enables access to `engine.get(.mach, .core)` `*Core` APIs, as
/// to for example `.setOptions(.{.title = "foobar"})`, or to access the GPU device via
/// `engine.get(.mach, .device)`
pub const module = ecs.Module(.{
    .globals = struct {
        core: *Core,
        device: *gpu.Device,
    },
});

pub fn App(
    modules: anytype,
    init: anytype, // fn (engine: *ecs.World(modules)) !void
) type {
    // TODO: validate modules.mach is the expected type.
    // TODO: validate init has the right function signature

    return struct {
        engine: ecs.World(modules),

        pub fn init(app: *@This(), core: *Core) !void {
            app.* = .{
                .engine = try ecs.World(modules).init(core.allocator),
            };
            app.*.engine.set(.mach, .core, core);
            app.*.engine.set(.mach, .device, core.device);
            try init(&app.engine);
        }

        pub fn deinit(app: *@This(), _: *Core) void {
            app.engine.deinit();
        }

        pub fn update(app: *@This(), _: *Core) !void {
            app.engine.tick();
        }

        pub fn resize(app: *@This(), core: *Core, width: u32, height: u32) !void {
            _ = app;
            _ = core;
            _ = width;
            _ = height;
            // TODO: send resize messages to ECS modules
        }
    };
}
