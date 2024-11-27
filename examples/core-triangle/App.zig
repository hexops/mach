const mach = @import("mach");
const gpu = mach.gpu;

const App = @This();

pub const mach_module = .app;

pub const mach_systems = .{ .main, .init, .tick, .deinit };

pub const main = mach.schedule(.{
    .{ mach.Core, .init },
    .{ App, .init },
    .{ mach.Core, .main },
});

title_timer: mach.time.Timer,
pipeline: *gpu.RenderPipeline,

pub fn init(
    core: *mach.Core,
    app: *App,
    app_mod: mach.Mod(App),
) !void {
    core.on_tick = app_mod.id.tick;
    core.on_exit = app_mod.id.deinit;

    // Create our shader module
    const shader_module = core.device.createShaderModuleWGSL("shader.wgsl", @embedFile("shader.wgsl"));
    defer shader_module.release();

    // Blend state describes how rendered colors get blended
    const blend = gpu.BlendState{};

    // Color target describes e.g. the pixel format of the window we are rendering to.
    const color_target = gpu.ColorTargetState{
        .format = core.windows.get(core.main_window, .framebuffer_format).?,
        .blend = &blend,
    };

    // Fragment state describes which shader and entrypoint to use for rendering fragments.
    const fragment = gpu.FragmentState.init(.{
        .module = shader_module,
        .entry_point = "frag_main",
        .targets = &.{color_target},
    });

    // Create our render pipeline that will ultimately get pixels onto the screen.
    const label = @tagName(mach_module) ++ ".init";
    const pipeline_descriptor = gpu.RenderPipeline.Descriptor{
        .label = label,
        .fragment = &fragment,
        .vertex = gpu.VertexState{
            .module = shader_module,
            .entry_point = "vertex_main",
        },
    };
    const pipeline = core.device.createRenderPipeline(&pipeline_descriptor);

    // Store our render pipeline in our module's state, so we can access it later on.
    app.* = .{
        .title_timer = try mach.time.Timer.start(),
        .pipeline = pipeline,
    };

    // TODO(object): window-title
    // try updateWindowTitle(core);
}

pub fn tick(app: *App, core: *mach.Core) void {
    while (core.nextEvent()) |event| {
        switch (event) {
            .close => core.exit(),
            else => {},
        }
    }

    // Grab the back buffer of the swapchain
    // TODO(Core)
    const back_buffer_view = core.swap_chain.getCurrentTextureView().?;
    defer back_buffer_view.release();

    // Create a command encoder
    const label = @tagName(mach_module) ++ ".tick";
    const encoder = core.device.createCommandEncoder(&.{ .label = label });
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
    render_pass.setPipeline(app.pipeline);
    render_pass.draw(3, 1, 0, 0);

    // Finish render pass
    render_pass.end();

    // Submit our commands to the queue
    var command = encoder.finish(&.{ .label = label });
    defer command.release();
    core.queue.submit(&[_]*gpu.CommandBuffer{command});

    // update the window title every second
    if (app.title_timer.read() >= 1.0) {
        app.title_timer.reset();
        // TODO(object): window-title
        // try updateWindowTitle(core);
    }
}

pub fn deinit(app: *App) void {
    app.pipeline.release();
}

// TODO(object): window-title
// fn updateWindowTitle(core: *mach.Core) !void {
//     try core.printTitle(
//         core.main_window,
//         "core-custom-entrypoint [ {d}fps ] [ Input {d}hz ]",
//         .{
//             // TODO(Core)
//             core.frameRate(),
//             core.inputRate(),
//         },
//     );
//     core.schedule(.update);
// }
