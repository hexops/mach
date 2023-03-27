const Core = @import("core").Core;
const gpu = @import("core").gpu;

const std = @import("std");
const ecs = @import("ecs");

/// The Mach engine ECS module. This enables access to `engine.get(.mach, .core)` `*Core` APIs, as
/// to for example `.setOptions(.{.title = "foobar"})`, or to access the GPU device via
/// `engine.get(.mach, .device)`
pub const Module = struct {
    core: *Core,
    device: *gpu.Device,
    exit: bool,

    pub const name = .mach;
};

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub fn App(comptime modules: anytype) type {
    // TODO: validate modules.mach is the expected type.

    return struct {
        engine: ecs.World(modules),
        core: Core,

        pub fn init(app: *@This()) !void {
            try app.core.init(allocator, .{});
            app.* = .{
                .core = app.core,
                .engine = try ecs.World(modules).init(allocator),
            };
            var mach = app.engine.mod(.mach);
            mach.setState(.core, &app.core);
            mach.setState(.device, app.core.device());
            try app.engine.send(.init);
        }

        pub fn deinit(app: *@This()) void {
            app.core.deinit();
            app.engine.deinit();
            _ = gpa.deinit();
        }

        pub fn update(app: *@This()) !bool {
            try app.engine.send(.tick);
            return app.engine.mod(.mach).getState(.exit);
        }
    };
}
