const std = @import("std");
const mach = @import("main.zig");
const core = mach.core;
const gpu = mach.core.gpu;
const ecs = mach.ecs;
const module = @import("module.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

/// The main Mach engine ECS module.
// TODO: move this to Engine.zig
pub const Engine = struct {
    device: *gpu.Device,
    queue: *gpu.Queue,
    should_exit: bool,
    pass: *gpu.RenderPassEncoder,
    encoder: *gpu.CommandEncoder,

    pub const name = .engine;
    pub const Mod = mach.Mod(@This());

    pub const global_events = .{
        .init = .{ .handler = fn () void },
        .deinit = .{ .handler = fn () void },
        .tick = .{ .handler = fn () void },
        .exit = .{ .handler = fn () void },
    };

    pub const local_events = .{
        .init = .{ .handler = init },
        .deinit = .{ .handler = deinit },
        .exit = .{ .handler = exit },
        .begin_pass = .{ .handler = beginPass },
        .end_pass = .{ .handler = endPass },
        .present = .{ .handler = present },
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
    modules: mach.Modules,

    pub fn init(app: *@This()) !void {
        app.* = .{ .modules = undefined };
        try app.modules.init(allocator);
        app.modules.sendToModule(.engine, .init, .{});
        try app.modules.dispatch();
    }

    pub fn deinit(app: *@This()) void {
        app.modules.sendToModule(.engine, .deinit, .{});
        // TODO: improve error handling
        app.modules.dispatch() catch |err| @panic(@errorName(err)); // dispatch .deinit
        app.modules.deinit(gpa.allocator());
        _ = gpa.deinit();
    }

    pub fn update(app: *@This()) !bool {
        // TODO: better dispatch implementation
        app.modules.mod.engine.sendGlobal(.tick, .{});
        try app.modules.dispatch(); // dispatch .tick
        try app.modules.dispatch(); // dispatch any events produced by .tick
        return app.modules.mod.engine.state.should_exit;
    }
};
