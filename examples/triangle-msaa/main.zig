const std = @import("std");
const mach = @import("mach");
const gpu = @import("gpu");

pub const App = @This();

pipeline: *gpu.RenderPipeline,
queue: *gpu.Queue,
texture: *gpu.Texture,
texture_view: *gpu.TextureView,
window_title_timer: mach.Timer,

const sample_count = 4;

pub fn init(app: *App, core: *mach.Core) !void {
    const vs_module = core.device.createShaderModuleWGSL("vert.wgsl", @embedFile("vert.wgsl"));
    const fs_module = core.device.createShaderModuleWGSL("frag.wgsl", @embedFile("frag.wgsl"));

    // Fragment state
    const blend = gpu.BlendState{};
    const color_target = gpu.ColorTargetState{
        .format = core.swap_chain_format,
        .blend = &blend,
        .write_mask = gpu.ColorWriteMaskFlags.all,
    };
    const fragment = gpu.FragmentState.init(.{
        .module = fs_module,
        .entry_point = "main",
        .targets = &.{color_target},
    });
    const pipeline_descriptor = gpu.RenderPipeline.Descriptor{
        .fragment = &fragment,
        .vertex = gpu.VertexState{
            .module = vs_module,
            .entry_point = "main",
        },
        .multisample = gpu.MultisampleState{
            .count = sample_count,
        },
    };

    app.pipeline = core.device.createRenderPipeline(&pipeline_descriptor);
    app.queue = core.device.getQueue();

    app.texture = core.device.createTexture(&gpu.Texture.Descriptor{
        .size = gpu.Extent3D{
            .width = core.current_desc.width,
            .height = core.current_desc.height,
        },
        .sample_count = sample_count,
        .format = core.swap_chain_format,
        .usage = .{ .render_attachment = true },
    });
    app.texture_view = app.texture.createView(null);

    vs_module.release();
    fs_module.release();
}

pub fn deinit(app: *App, _: *mach.Core) void {
    app.texture.release();
    app.texture_view.release();
}

pub fn update(app: *App, core: *mach.Core) !void {
    const back_buffer_view = core.swap_chain.?.getCurrentTextureView();
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

    app.queue.submit(&.{command});
    command.release();
    core.swap_chain.?.present();
    back_buffer_view.release();

    if (app.window_title_timer.read() >= 1.0) {
        const window_title = try std.fmt.allocPrintZ(core.allocator, "FPS: {d}", .{@floatToInt(u32, 1 / core.delta_time)});
        defer core.allocator.free(window_title);
        try core.internal.window.setTitle(window_title);
        app.window_title_timer.reset();
    }
}

pub fn resize(app: *App, core: *mach.Core, width: u32, height: u32) !void {
    app.texture.release();
    app.texture = core.device.createTexture(&gpu.Texture.Descriptor{
        .size = gpu.Extent3D{
            .width = width,
            .height = height,
        },
        .sample_count = sample_count,
        .format = core.swap_chain_format,
        .usage = .{ .render_attachment = true },
    });
    app.texture_view.release();
    app.texture_view = app.texture.createView(null);
}
