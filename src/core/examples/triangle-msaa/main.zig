const std = @import("std");
const core = @import("mach").core;
const gpu = core.gpu;

pub const App = @This();

title_timer: core.Timer,
pipeline: *gpu.RenderPipeline,
texture: *gpu.Texture,
texture_view: *gpu.TextureView,

const sample_count = 4;

pub fn init(app: *App) !void {
    try core.init(.{});
    app.title_timer = try core.Timer.start();

    const shader_module = core.device.createShaderModuleWGSL("shader.wgsl", @embedFile("shader.wgsl"));
    defer shader_module.release();

    // Fragment state
    const blend = gpu.BlendState{};
    const color_target = gpu.ColorTargetState{
        .format = core.descriptor.format,
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
        .multisample = gpu.MultisampleState{
            .count = sample_count,
        },
    };

    app.pipeline = core.device.createRenderPipeline(&pipeline_descriptor);

    app.texture = core.device.createTexture(&gpu.Texture.Descriptor{
        .size = gpu.Extent3D{
            .width = core.descriptor.width,
            .height = core.descriptor.height,
        },
        .sample_count = sample_count,
        .format = core.descriptor.format,
        .usage = .{ .render_attachment = true },
    });
    app.texture_view = app.texture.createView(null);
}

pub fn deinit(app: *App) void {
    defer core.deinit();

    app.pipeline.release();
    app.texture.release();
    app.texture_view.release();
}

pub fn update(app: *App) !bool {
    var iter = core.pollEvents();
    while (iter.next()) |event| {
        switch (event) {
            .framebuffer_resize => |size| {
                app.texture.release();
                app.texture = core.device.createTexture(&gpu.Texture.Descriptor{
                    .size = gpu.Extent3D{
                        .width = size.width,
                        .height = size.height,
                    },
                    .sample_count = sample_count,
                    .format = core.descriptor.format,
                    .usage = .{ .render_attachment = true },
                });

                app.texture_view.release();
                app.texture_view = app.texture.createView(null);
            },
            .close => return true,
            else => {},
        }
    }

    const back_buffer_view = core.swap_chain.getCurrentTextureView().?;
    const color_attachment = gpu.RenderPassColorAttachment{
        .view = app.texture_view,
        .resolve_target = back_buffer_view,
        .clear_value = std.mem.zeroes(gpu.Color),
        .load_op = .clear,
        .store_op = .discard,
    };

    const encoder = core.device.createCommandEncoder(null);
    const render_pass_info = gpu.RenderPassDescriptor.init(.{
        .color_attachments = &.{color_attachment},
    });
    const pass = encoder.beginRenderPass(&render_pass_info);
    pass.setPipeline(app.pipeline);
    pass.draw(3, 1, 0, 0);
    pass.end();
    pass.release();

    var command = encoder.finish(null);
    encoder.release();

    const queue = core.queue;
    queue.submit(&[_]*gpu.CommandBuffer{command});
    command.release();
    core.swap_chain.present();
    back_buffer_view.release();

    // update the window title every second
    if (app.title_timer.read() >= 1.0) {
        app.title_timer.reset();
        try core.printTitle("Triangle MSAA [ {d}fps ] [ Input {d}hz ]", .{
            core.frameRate(),
            core.inputRate(),
        });
    }

    return false;
}
