const core = @import("core");
const gpu = @import("core").gpu;
const std = @import("std");
const ecs = @import("ecs");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

/// The main Mach engine ECS module.
pub const Engine = struct {
    device: *gpu.Device,
    exit: bool,

    pub const name = .engine;

    pub fn engineInit(world: *World) !void {
        core.allocator = allocator;
        try core.init(.{});
        world.mod.engine.state.device = core.device;
        world.mod.engine.state.exit = false;

        try world.send(.init, .{});
    }

    pub fn engineDeinit(world: *World) !void {
        try world.send(.deinit, .{});
        core.deinit();
        world.deinit();
        _ = gpa.deinit();
    }

    pub fn engineExit(world: *World) !void {
        try world.send(.exit, .{});
        world.mod.engine.state.exit = true;
    }
};

pub const App = struct {
    world: World,

    pub fn init(app: *@This()) !void {
        app.* = .{ .world = try World.init(allocator) };
        try app.world.send(.engineInit, .{});
    }

    pub fn deinit(app: *@This()) void {
        try app.world.send(.engineDeinit, .{});
    }

    pub fn update(app: *@This()) !bool {
        try app.world.send(.tick, .{});
        return app.world.mod.engine.state.exit;
    }
};

pub const World = ecs.World(modules());

fn Modules() type {
    if (!@hasDecl(@import("root"), "modules")) {
        @compileError("expected `pub const modules = .{};` in root file");
    }
    return @TypeOf(@import("root").modules);
}

fn modules() Modules() {
    if (!@hasDecl(@import("root"), "modules")) {
        @compileError("expected `pub const modules = .{};` in root file");
    }
    return @import("root").modules;
}
