const core = @import("core");
const gpu = @import("core").gpu;
const std = @import("std");
const ecs = @import("ecs");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

/// The main Mach engine ECS module.
pub const Module = struct {
    device: *gpu.Device,
    exit: bool,

    pub const name = .mach;

    pub fn machInit(eng: *Engine) !void {
        core.allocator = allocator;
        try core.init(.{});
        eng.mod.mach.state.device = core.device;
        eng.mod.mach.state.exit = false;

        try eng.send(.init);
    }

    pub fn machDeinit(eng: *Engine) !void {
        try eng.send(.deinit);
        core.deinit();
        eng.deinit();
        _ = gpa.deinit();
    }

    pub fn machExit(eng: *Engine) !void {
        try eng.send(.exit);
        var state = eng.mod.mach.state;
        state.exit = true;
    }
};

pub const App = struct {
    engine: Engine,

    pub fn init(app: *@This()) !void {
        app.* = .{ .engine = try Engine.init(allocator) };
        try app.engine.send(.machInit);
    }

    pub fn deinit(app: *@This()) void {
        try app.engine.send(.machDeinit);
    }

    pub fn update(app: *@This()) !bool {
        try app.engine.send(.tick);
        return app.engine.mod.mach.state.exit;
    }
};

pub const Engine = ecs.World(modules());

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
