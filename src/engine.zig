const Core = @import("core").Core;
const gpu = @import("core").gpu;

const std = @import("std");
const ecs = @import("ecs");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

/// The main Mach engine ECS module.
pub const Module = struct {
    _core: Core,
    core: *Core,
    device: *gpu.Device,
    exit: bool,

    pub const name = .mach;

    pub fn machInit(adapter: anytype) !void {
        var mach = adapter.mod(.mach);

        mach.initState(.{
            ._core = undefined,
            .core = undefined,
            .device = undefined,
            .exit = false,
        });

        var state = mach.state();
        try state._core.init(allocator, .{});
        state.core = &state._core;
        state.device = state.core.device();
        try adapter.send(.init);
    }

    pub fn machDeinit(adapter: anytype) !void {
        try adapter.send(.deinit);

        var state = adapter.mod(.mach).state();
        state.core.deinit();
        adapter.deinit();
        _ = gpa.deinit();
    }

    pub fn machExit(adapter: anytype) !void {
        try adapter.send(.exit);

        var state = adapter.mod(.mach).state();
        state.exit = true;
    }
};

pub fn App(comptime modules: anytype) type {
    return struct {
        engine: ecs.World(modules),

        pub fn init(app: *@This()) !void {
            app.* = .{ .engine = try ecs.World(modules).init(allocator) };
            try app.engine.send(.machInit);
        }

        pub fn deinit(app: *@This()) void {
            try app.engine.send(.machDeinit);
        }

        pub fn update(app: *@This()) !bool {
            try app.engine.send(.tick);
            return app.engine.mod(.mach).state().exit;
        }
    };
}
