const std = @import("std");
const mach = @import("main.zig");
const core = mach.core;
const gpu = mach.core.gpu;

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
        .frame_done = .{ .handler = frameDone },
        .tick_done = .{ .handler = fn () void },
    };

    fn init(engine: *Mod) !void {
        core.allocator = allocator;
        try core.init(.{});
        engine.init(.{
            .device = core.device,
            .queue = core.device.getQueue(),
            .should_exit = false,
            .pass = undefined,
            .encoder = core.device.createCommandEncoder(&gpu.CommandEncoder.Descriptor{
                .label = "engine.state.encoder",
            }),
        });
        engine.sendGlobal(.init, .{});
    }

    fn deinit(engine: *Mod) void {
        const state = engine.state();
        // TODO: this triggers a device loss error, which we should handle correctly
        // state.device.release();
        state.queue.release();
        engine.sendGlobal(.deinit, .{});
        core.deinit();
    }

    // Engine module's exit handler
    fn exit(engine: *Mod) void {
        engine.sendGlobal(.exit, .{});
        const state = engine.state();
        state.should_exit = true;
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

        const state = engine.state();
        state.pass = state.encoder.beginRenderPass(&pass_info);
    }

    fn endPass(engine: *Mod) void {
        const state = engine.state();
        // End this pass
        state.pass.end();
        state.pass.release();

        var command = state.encoder.finish(null);
        defer command.release();
        state.encoder.release();
        state.queue.submit(&[_]*gpu.CommandBuffer{command});

        // Prepare for next pass
        state.encoder = state.device.createCommandEncoder(&gpu.CommandEncoder.Descriptor{
            .label = "engine.state.encoder",
        });
    }

    fn frameDone(engine: *Mod) void {
        core.swap_chain.present();
        engine.send(.tick_done, .{});
    }
};

pub const App = struct {
    modules: mach.Modules,

    pub fn init(app: *@This()) !void {
        app.* = .{ .modules = undefined };
        try app.modules.init(allocator);
        app.modules.mod.engine.send(.init, .{});
        try app.modules.dispatch(.{});
    }

    pub fn deinit(app: *@This()) void {
        app.modules.mod.engine.send(.deinit, .{});
        // TODO: could it be worth enforcing that deinit dispatch cannot return errors at event handler level?
        app.modules.dispatch(.{}) catch |err| std.debug.panic("mach: error during dispatching final .deinit event: {s}", .{@errorName(err)});
        app.modules.deinit(gpa.allocator());
        _ = gpa.deinit();
    }

    pub fn update(app: *@This()) !bool {
        // Send .tick to anyone interested
        app.modules.mod.engine.sendGlobal(.tick, .{});

        // Wait until the .engine module sends a .tick_done event
        try app.modules.dispatch(.{ .until = .{
            .module_name = app.modules.moduleNameToID(.engine),
            .local_event = app.modules.localEventToID(.engine, .tick_done),
        } });

        return app.modules.mod.engine.state().should_exit;
    }
};
