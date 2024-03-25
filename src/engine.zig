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
        .{ .local = .begin_pass, .handler = beginPass },
        .{ .local = .end_pass, .handler = endPass },
        .{ .local = .present, .handler = present },
        .{ .global = .tick, .handler = fn () void },
        .{ .global = .exit, .handler = fn () void },
    };

    fn init(engine: *Mod) !void {
        core.allocator = allocator;
        try core.init(.{});
        const state = &engine.state;
        state.device = core.device;
        state.queue = core.device.getQueue();
        state.should_exit = false;
        state.encoder = state.device.createCommandEncoder(&gpu.CommandEncoder.Descriptor{
            .label = "engine.state.encoder",
        });
        engine.sendGlobal(.init, .{});
    }

    fn deinit(engine: *Mod) void {
        // TODO: this triggers a device loss error, which we should handle correctly
        // engine.state.device.release();
        engine.state.queue.release();
        engine.sendGlobal(.deinit, .{});
        core.deinit();
    }

    // Engine module's exit handler
    fn exit(engine: *Mod) void {
        engine.sendGlobal(.exit, .{});
        engine.state.should_exit = true;
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
        // TODO: improve error handling
        app.world.dispatch() catch |err| @panic(@errorName(err)); // dispatch .deinit
        app.world.deinit();
        _ = gpa.deinit();
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
    // TODO: verify modules (causes loop currently)
    // _ = @import("module.zig").Modules(@import("root").modules);
    return @import("root").modules;
}
