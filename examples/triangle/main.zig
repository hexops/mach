const std = @import("std");
const mach = @import("mach");
const gpu = @import("gpu");

pub const App = @This();

pipeline: *gpu.RenderPipeline,
queue: *gpu.Queue,

pub fn init(app: *App, core: *mach.Core) !void {
    const vs_module = core.device.createShaderModule(&.{
        .next_in_chain = .{ .wgsl_descriptor = &.{
            .source = @embedFile("vert.wgsl"),
        } },
        .label = "my vertex shader",
    });

    const fs_module = core.device.createShaderModule(&.{
        .next_in_chain = .{ .wgsl_descriptor = &.{
            .source = @embedFile("frag.wgsl"),
        } },
        .label = "my fragment shader",
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
        .format = core.swap_chain_format,
        .blend = &blend,
        .write_mask = gpu.ColorWriteMaskFlags.all,
    };
    const fragment = gpu.FragmentState{
        .module = fs_module,
        .entry_point = "main",
        .target_count = 1,
        .targets = &[_]gpu.ColorTargetState{color_target},
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
            .strip_index_format = .undef,
        },
    };

    app.pipeline = core.device.createRenderPipeline(&pipeline_descriptor);
    app.queue = core.device.getQueue();

    vs_module.release();
    fs_module.release();
}

pub fn deinit(_: *App, _: *mach.Core) void {}

pub fn update(app: *App, core: *mach.Core) !void {
    const back_buffer_view = core.swap_chain.?.getCurrentTextureView();
    const color_attachment = gpu.RenderPassColorAttachment{
        .view = back_buffer_view,
        .resolve_target = null,
        .clear_value = std.mem.zeroes(gpu.Color),
        .load_op = .clear,
        .store_op = .store,
    };

    const encoder = core.device.createCommandEncoder(null);
    const render_pass_info = gpu.RenderPassDescriptor{
        .color_attachment_count = 1,
        .color_attachments = &[_]gpu.RenderPassColorAttachment{color_attachment},
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
    core.swap_chain.?.present();
    back_buffer_view.release();
}
