const std = @import("std");
const mach = @import("mach");
const gpu = mach.gpu;

pub const name = .game;
pub const Mod = mach.Mod(@This());

pub const global_events = .{
    .init = .{ .handler = init },
    .tick = .{ .handler = tick },
};

title_timer: mach.Timer,
pipeline: *gpu.RenderPipeline,

fn init(game: *Mod) !void {
    const shader_module = mach.core.device.createShaderModuleWGSL("shader.wgsl", @embedFile("shader.wgsl"));
    defer shader_module.release();

    // Fragment state
    const blend = gpu.BlendState{};
    const color_target = gpu.ColorTargetState{
        .format = mach.core.descriptor.format,
        .blend = &blend,
        .write_mask = gpu.ColorWriteMaskFlags.all,
    };
    const fragment = gpu.FragmentState.init(.{
        .module = shader_module,
        .entry_point = "frag_main",
        .targets = &.{color_target},
    });
    const pipeline_descriptor = gpu.RenderPipeline.Descriptor{
        .fragment = &fragment,
        .vertex = gpu.VertexState{
            .module = shader_module,
            .entry_point = "vertex_main",
        },
    };
    const pipeline = mach.core.device.createRenderPipeline(&pipeline_descriptor);

    game.init(.{
        .title_timer = try mach.Timer.start(),
        .pipeline = pipeline,
    });
    try updateWindowTitle();
}

pub fn deinit(game: *Mod) void {
    game.state().pipeline.release();
}

// TODO(important): remove need for returning an error here
fn tick(
    core: *mach.Core.Mod,
    game: *Mod,
) !void {
    // TODO(important): event polling should occur in mach.Core module and get fired as ECS event.
    var iter = mach.core.pollEvents();
    while (iter.next()) |event| {
        switch (event) {
            .close => core.send(.exit, .{}), // Tell mach.Core to exit the app
            else => {},
        }
    }

    const queue = mach.core.queue;
    const back_buffer_view = mach.core.swap_chain.getCurrentTextureView().?;
    const color_attachment = gpu.RenderPassColorAttachment{
        .view = back_buffer_view,
        .clear_value = std.mem.zeroes(gpu.Color),
        .load_op = .clear,
        .store_op = .store,
    };

    const encoder = mach.core.device.createCommandEncoder(null);
    const render_pass_info = gpu.RenderPassDescriptor.init(.{
        .color_attachments = &.{color_attachment},
    });
    const pass = encoder.beginRenderPass(&render_pass_info);
    pass.setPipeline(game.state().pipeline);
    pass.draw(3, 1, 0, 0);
    pass.end();
    pass.release();

    var command = encoder.finish(null);
    encoder.release();

    queue.submit(&[_]*gpu.CommandBuffer{command});
    command.release();
    mach.core.swap_chain.present();
    back_buffer_view.release();

    // update the window title every second
    if (game.state().title_timer.read() >= 1.0) {
        game.state().title_timer.reset();
        try updateWindowTitle();
    }
}

fn updateWindowTitle() !void {
    try mach.core.printTitle("mach.Core - custom entrypoint [ {d}fps ] [ Input {d}hz ]", .{
        mach.core.frameRate(),
        mach.core.inputRate(),
    });
}
