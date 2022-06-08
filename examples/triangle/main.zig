const std = @import("std");
const mach = @import("mach");
const gpu = @import("gpu");

const App = @This();

pipeline: gpu.RenderPipeline,
queue: gpu.Queue,

pub fn init(app: *App, engine: *mach.Engine) !void {
    const vs_module = engine.device.createShaderModule(&.{
        .label = "my vertex shader",
        .code = .{ .wgsl = @embedFile("vert.wgsl") },
    });

    const fs_module = engine.device.createShaderModule(&.{
        .label = "my fragment shader",
        .code = .{ .wgsl = @embedFile("frag.wgsl") },
    });

    // Fragment state
    const blend = gpu.BlendState{
        .color = .{
            .operation = .add,
            .src_factor = .one,
            .dst_factor = .zero,
        },
        .alpha = .{
            .operation = .add,
            .src_factor = .one,
            .dst_factor = .zero,
        },
    };
    const color_target = gpu.ColorTargetState{
        .format = engine.swap_chain_format,
        .blend = &blend,
        .write_mask = gpu.ColorWriteMask.all,
    };
    const fragment = gpu.FragmentState{
        .module = fs_module,
        .entry_point = "main",
        .targets = &.{color_target},
        .constants = null,
    };
    const pipeline_descriptor = gpu.RenderPipeline.Descriptor{
        .fragment = &fragment,
        .layout = null,
        .depth_stencil = null,
        .vertex = .{
            .module = vs_module,
            .entry_point = "main",
            .buffers = null,
        },
        .multisample = .{
            .count = 1,
            .mask = 0xFFFFFFFF,
            .alpha_to_coverage_enabled = false,
        },
        .primitive = .{
            .front_face = .ccw,
            .cull_mode = .none,
            .topology = .triangle_list,
            .strip_index_format = .none,
        },
    };

    app.pipeline = engine.device.createRenderPipeline(&pipeline_descriptor);
    app.queue = engine.device.getQueue();

    vs_module.release();
    fs_module.release();
}

pub fn deinit(_: *App, _: *mach.Engine) void {}

pub fn update(app: *App, engine: *mach.Engine) !void {
    const back_buffer_view = engine.swap_chain.?.getCurrentTextureView();
    const color_attachment = gpu.RenderPassColorAttachment{
        .view = back_buffer_view,
        .resolve_target = null,
        .clear_value = std.mem.zeroes(gpu.Color),
        .load_op = .clear,
        .store_op = .store,
    };

    const encoder = engine.device.createCommandEncoder(null);
    const render_pass_info = gpu.RenderPassEncoder.Descriptor{
        .color_attachments = &.{color_attachment},
        .depth_stencil_attachment = null,
    };
    const pass = encoder.beginRenderPass(&render_pass_info);
    pass.setPipeline(app.pipeline);
    pass.draw(3, 1, 0, 0);
    pass.end();
    pass.release();

    var command = encoder.finish(null);
    encoder.release();

    app.queue.submit(&.{command});
    command.release();
    engine.swap_chain.?.present();
    back_buffer_view.release();
}
