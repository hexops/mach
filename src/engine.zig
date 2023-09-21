const core = @import("mach-core");
const gpu = @import("mach-core").gpu;
const std = @import("std");
const ecs = @import("mach-ecs");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

/// The main Mach engine ECS module.
pub const Engine = struct {
    device: *gpu.Device,
    queue: *gpu.Queue,
    exit: bool,
    pass: *gpu.RenderPassEncoder,
    encoder: *gpu.CommandEncoder,

    pub const name = .engine;

    pub fn engineInit(world: *World) !void {
        core.allocator = allocator;
        try core.init(.{});
        const state = &world.mod.engine.state;
        state.device = core.device;
        state.queue = core.device.getQueue();
        state.exit = false;
        state.encoder = state.device.createCommandEncoder(&gpu.CommandEncoder.Descriptor{
            .label = "engine.state.encoder",
        });

        try world.send(.init, .{});
    }

    pub fn engineDeinit(
        world: *World,
        engine: *World.Mod(.engine),
    ) !void {
        // TODO: this triggers a device loss error, which we should handle correctly
        // engine.state.device.release();
        engine.state.queue.release();
        try world.send(.deinit, .{});
        core.deinit();
        world.deinit();
        _ = gpa.deinit();
    }

    pub fn engineExit(world: *World) !void {
        try world.send(.exit, .{});
        world.mod.engine.state.exit = true;
    }

    pub fn engineBeginPass(
        engine: *World.Mod(.engine),
        clear_color: gpu.Color,
    ) !void {
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

    pub fn engineEndPass(
        engine: *World.Mod(.engine),
    ) !void {
        // End this pass
        engine.state.pass.end();
        engine.state.pass.release();

        var command = engine.state.encoder.finish(null);
        defer command.release();
        engine.state.queue.submit(&[_]*gpu.CommandBuffer{command});

        // Prepare for next pass
        engine.state.encoder = engine.state.device.createCommandEncoder(&gpu.CommandEncoder.Descriptor{
            .label = "engine.state.encoder",
        });
    }

    pub fn enginePresent() !void {
        core.swap_chain.present();
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
