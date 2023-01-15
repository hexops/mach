const std = @import("std");
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

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub fn App(
    comptime modules: anytype,
    comptime app_init: anytype, // fn (engine: *ecs.World(modules)) !void
) type {
    // TODO: validate modules.mach is the expected type.
    // TODO: validate init has the right function signature

    return struct {
        engine: ecs.World(modules),

        pub fn init(app: *@This()) !void {
            app.* = .{
                .engine = try ecs.World(modules).init(allocator),
            };
            var core = try allocator.create(Core);
            core.* = try Core.init(allocator, .{});
            app.engine.set(.mach, .core, core);
            app.engine.set(.mach, .device, core.device());
            try app_init(&app.engine);
        }

        pub fn deinit(app: *@This()) void {
            const core = app.engine.get(.mach, .core);
            core.deinit();
            allocator.destroy(core);
            app.engine.deinit();
            _ = gpa.deinit();
        }

        pub fn update(app: *@This()) !bool {
            app.engine.tick();
            return false;
        }
    };
}
