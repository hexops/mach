const std = @import("std");
const mach = @import("mach");
const gpu = mach.gpu;

pub const name = .app;
pub const Mod = mach.Mod(@This());

pub const systems = .{
    .init = .{ .handler = init },
    .deinit = .{ .handler = deinit },
    .update = .{ .handler = update },
};

title_timer: mach.Timer,
pipeline: *gpu.RenderPipeline,

pub fn deinit(game: *Mod) void {
    game.state().pipeline.release();
}

fn init(game: *Mod, core: *mach.Core.Mod) !void {
    // Create our shader module
    const shader_module = core.state().device.createShaderModuleWGSL("shader.wgsl", @embedFile("shader.wgsl"));
    defer shader_module.release();

    // Blend state describes how rendered colors get blended
    const blend = gpu.BlendState{};

    // Color target describes e.g. the pixel format of the window we are rendering to.
    const color_target = gpu.ColorTargetState{
        .format = core.get(core.state().main_window, .framebuffer_format).?,
        .blend = &blend,
    };

    // Fragment state describes which shader and entrypoint to use for rendering fragments.
    const fragment = gpu.FragmentState.init(.{
        .module = shader_module,
        .entry_point = "frag_main",
        .targets = &.{color_target},
    });

    // Create our render pipeline that will ultimately get pixels onto the screen.
    const label = @tagName(name) ++ ".init";
    const pipeline_descriptor = gpu.RenderPipeline.Descriptor{
        .label = label,
        .fragment = &fragment,
        .vertex = gpu.VertexState{
            .module = shader_module,
            .entry_point = "vertex_main",
        },
    };
    const pipeline = core.state().device.createRenderPipeline(&pipeline_descriptor);

    // Store our render pipeline in our module's state, so we can access it later on.
    game.init(.{
        .title_timer = try mach.Timer.start(),
        .pipeline = pipeline,
    });
    // try updateWindowTitle(core);
}

fn update(core: *mach.Core.Mod, game: *Mod) !void {
    var iter = core.state().pollEvents();
    while (iter.next()) |event| {
        switch (event) {
            .close => core.schedule(.exit), // Tell mach.Core to exit the app
            else => {},
        }
    }

    // Grab the back buffer of the swapchain
    // TODO(Core)
    const back_buffer_view = core.state().swap_chain.getCurrentTextureView().?;
    defer back_buffer_view.release();

    // Create a command encoder
    const label = @tagName(name) ++ ".update";
    const encoder = core.state().device.createCommandEncoder(&.{ .label = label });
    defer encoder.release();

    // Begin render pass
    const sky_blue_background = gpu.Color{ .r = 0.776, .g = 0.988, .b = 1, .a = 1 };
    const color_attachments = [_]gpu.RenderPassColorAttachment{.{
        .view = back_buffer_view,
        .clear_value = sky_blue_background,
        .load_op = .clear,
        .store_op = .store,
    }};
    const render_pass = encoder.beginRenderPass(&gpu.RenderPassDescriptor.init(.{
        .label = label,
        .color_attachments = &color_attachments,
    }));
    defer render_pass.release();

    // Draw
    render_pass.setPipeline(game.state().pipeline);
    render_pass.draw(3, 1, 0, 0);

    // Finish render pass
    render_pass.end();

    // Submit our commands to the queue
    var command = encoder.finish(&.{ .label = label });
    defer command.release();
    core.state().queue.submit(&[_]*gpu.CommandBuffer{command});

    core.schedule(.present_frame);

    // update the window title every second
    if (game.state().title_timer.read() >= 1.0) {
        game.state().title_timer.reset();
        try updateWindowTitle(core);
    }
}

fn updateWindowTitle(core: *mach.Core.Mod) !void {
    try core.state().printTitle(
        core.state().main_window,
        "core-custom-entrypoint [ {d}fps ] [ Input {d}hz ]",
        .{
            // TODO(Core)
            core.state().frameRate(),
            core.state().inputRate(),
        },
    );
}
