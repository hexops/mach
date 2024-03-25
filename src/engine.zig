const std = @import("std");
const mach = @import("main.zig");
const core = mach.core;
const gpu = mach.core.gpu;
const ecs = mach.ecs;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

/// The main Mach engine ECS module.
pub const Engine = struct {
    device: *gpu.Device,
    queue: *gpu.Queue,
    should_exit: bool,
    pass: *gpu.RenderPassEncoder,
    encoder: *gpu.CommandEncoder,

    pub const name = .engine;
    pub const Mod = World.Mod(@This());

    pub const events = .{
        .{ .local = .init, .handler = init },
        .{ .local = .deinit, .handler = deinit },
        .{ .local = .exit, .handler = exit },
        .{ .local = .beginPass, .handler = beginPass },
        .{ .local = .endPass, .handler = endPass },
        .{ .local = .present, .handler = present },
        .{ .global = .tick, .handler = fn () void },
        .{ .global = .exit, .handler = fn () void },
    };

    fn init(world: *World) !void {
        core.allocator = allocator;
        try core.init(.{});
        const state = &world.mod.engine.state;
        state.device = core.device;
        state.queue = core.device.getQueue();
        state.should_exit = false;
        state.encoder = state.device.createCommandEncoder(&gpu.CommandEncoder.Descriptor{
            .label = "engine.state.encoder",
        });

        world.modules.send(.init, .{});
    }

    fn deinit(world: *World, engine: *Mod) void {
        // TODO: this triggers a device loss error, which we should handle correctly
        // engine.state.device.release();
        engine.state.queue.release();
        world.modules.send(.deinit, .{});
        core.deinit();
        world.deinit();
        _ = gpa.deinit();
    }

    // Engine module's exit handler
    fn exit(world: *World) void {
        world.modules.send(.exit, .{});
        world.mod.engine.state.should_exit = true;
    }

    fn beginPass(engine: *Mod, clear_color: gpu.Color) void {
        const back_buffer_view = core.swap_chain.getCurrentTextureView().?;
        defer back_buffer_view.release();

        // TODO: expose options
        const color_attachment = gpu.RenderPassColorAttachment{
            .view = back_buffer_view,
            .clear_value = clear_color,
            .load_op = .clear,
            .store_op = .store,
        };
        const pass_info = gpu.RenderPassDescriptor.init(.{
            .color_attachments = &.{color_attachment},
        });

        engine.state.pass = engine.state.encoder.beginRenderPass(&pass_info);
    }

    fn endPass(engine: *Mod) void {
        // End this pass
        engine.state.pass.end();
        engine.state.pass.release();

        var command = engine.state.encoder.finish(null);
        defer command.release();
        engine.state.encoder.release();
        engine.state.queue.submit(&[_]*gpu.CommandBuffer{command});

        // Prepare for next pass
        engine.state.encoder = engine.state.device.createCommandEncoder(&gpu.CommandEncoder.Descriptor{
            .label = "engine.state.encoder",
        });
    }

    fn present() void {
        core.swap_chain.present();
    }
};

pub const App = struct {
    world: World,

    pub fn init(app: *@This()) !void {
        app.* = .{ .world = undefined };
        try app.world.init(allocator);
        app.world.modules.sendToModule(.engine, .init, .{});
        try app.world.dispatch();
    }

    pub fn deinit(app: *@This()) void {
        app.world.modules.sendToModule(.engine, .deinit, .{});
    }

    pub fn update(app: *@This()) !bool {
        // TODO: better dispatch implementation
        app.world.modules.send(.tick, .{});
        try app.world.dispatch(); // dispatch .tick
        try app.world.dispatch(); // dispatch any events produced by .tick
        return app.world.mod.engine.state.should_exit;
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
