const std = @import("std");
const mach = @import("mach");
const gpu = @import("gpu");
const glfw = @import("glfw");
const zm = @import("zmath");
const Vertex = @import("cube_mesh.zig").Vertex;
const vertices = @import("cube_mesh.zig").vertices;

const UniformBufferObject = struct {
    mat: zm.Mat,
};

var timer: mach.Timer = undefined;

pipeline: *gpu.RenderPipeline,
queue: *gpu.Queue,
vertex_buffer: *gpu.Buffer,
uniform_buffer: *gpu.Buffer,
bind_group: *gpu.BindGroup,

pub const App = @This();

pub fn init(app: *App, core: *mach.Core) !void {
    timer = try mach.Timer.start();

    try core.setOptions(.{
        .size_min = .{ .width = 20, .height = 20 },
    });

    const vs_module = core.device.createShaderModule(&.{
        .next_in_chain = .{ .wgsl_descriptor = &.{
            .source = @embedFile("vert.wgsl"),
        } },
        .label = "my vertex shader",
    });

    const vertex_attributes = [_]gpu.VertexAttribute{
        .{ .format = .float32x4, .offset = @offsetOf(Vertex, "pos"), .shader_location = 0 },
        .{ .format = .float32x2, .offset = @offsetOf(Vertex, "uv"), .shader_location = 1 },
    };
    const vertex_buffer_layout = gpu.VertexBufferLayout{
        .array_stride = @sizeOf(Vertex),
        .step_mode = .vertex,
        .attribute_count = vertex_attributes.len,
        .attributes = &vertex_attributes,
    };

    const fs_module = core.device.createShaderModule(&.{
        .next_in_chain = .{ .wgsl_descriptor = &.{
            .source = @embedFile("frag.wgsl"),
        } },
        .label = "my fragment shader",
    });

    const color_target = gpu.ColorTargetState{
        .format = core.swap_chain_format,
        .blend = null,
        .write_mask = gpu.ColorWriteMaskFlags.all,
    };
    const fragment = gpu.FragmentState{
        .module = fs_module,
        .entry_point = "main",
        .target_count = 1,
        .targets = &[_]gpu.ColorTargetState{color_target},
        .constants = null,
    };

    const bgle = gpu.BindGroupLayout.Entry.buffer(0, .{ .vertex = true }, .uniform, true, 0);
    const bgl = core.device.createBindGroupLayout(
        &gpu.BindGroupLayout.Descriptor{
            .entry_count = 1,
            .entries = &[_]gpu.BindGroupLayout.Entry{bgle},
        },
    );

    const bind_group_layouts = [_]*gpu.BindGroupLayout{bgl};
    const pipeline_layout = core.device.createPipelineLayout(&.{
        .bind_group_layout_count = 1,
        .bind_group_layouts = &bind_group_layouts,
    });

    const pipeline_descriptor = gpu.RenderPipeline.Descriptor{
        .fragment = &fragment,
        .layout = pipeline_layout,
        .depth_stencil = null,
        .vertex = .{
            .module = vs_module,
            .entry_point = "main",
            .buffer_count = 1,
            .buffers = &[_]gpu.VertexBufferLayout{vertex_buffer_layout},
        },
        .multisample = .{
            .count = 1,
            .mask = 0xFFFFFFFF,
            .alpha_to_coverage_enabled = false,
        },
        .primitive = .{
            .front_face = .ccw,
            .cull_mode = .back,
            .topology = .triangle_list,
            .strip_index_format = .undef,
        },
    };

    const vertex_buffer = core.device.createBuffer(&.{
        .usage = .{ .vertex = true },
        .size = @sizeOf(Vertex) * vertices.len,
        .mapped_at_creation = true,
    });
    var vertex_mapped = vertex_buffer.getMappedRange(Vertex, 0, vertices.len);
    std.mem.copy(Vertex, vertex_mapped.?, vertices[0..]);
    vertex_buffer.unmap();

    const x_count = 4;
    const y_count = 4;
    const num_instances = x_count * y_count;

    const uniform_buffer = core.device.createBuffer(&.{
        .usage = .{ .copy_dst = true, .uniform = true },
        .size = @sizeOf(UniformBufferObject) * num_instances,
        .mapped_at_creation = false,
    });
    const bind_group = core.device.createBindGroup(
        &gpu.BindGroup.Descriptor{
            .layout = bgl,
            .entry_count = 1,
            .entries = &[_]gpu.BindGroup.Entry{
                gpu.BindGroup.Entry.buffer(0, uniform_buffer, 0, @sizeOf(UniformBufferObject) * num_instances),
            },
        },
    );

    app.pipeline = core.device.createRenderPipeline(&pipeline_descriptor);
    app.queue = core.device.getQueue();
    app.vertex_buffer = vertex_buffer;
    app.uniform_buffer = uniform_buffer;
    app.bind_group = bind_group;

    vs_module.release();
    fs_module.release();
    pipeline_layout.release();
    bgl.release();
}

pub fn deinit(app: *App, _: *mach.Core) void {
    app.vertex_buffer.release();
    app.bind_group.release();
    app.uniform_buffer.release();
}

pub fn update(app: *App, core: *mach.Core) !void {
    while (core.pollEvent()) |event| {
        switch (event) {
            .key_press => |ev| {
                if (ev.key == .space)
                    core.setShouldClose(true);
            },
            else => {},
        }
    }

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
    };

    {
        const proj = zm.perspectiveFovRh(
            (std.math.pi / 3.0),
            @intToFloat(f32, core.current_desc.width) / @intToFloat(f32, core.current_desc.height),
            10,
            30,
        );

        var ubos: [16]UniformBufferObject = undefined;
        const time = timer.read();
        const step: f32 = 4.0;
        var m: u8 = 0;
        var x: u8 = 0;
        while (x < 4) : (x += 1) {
            var y: u8 = 0;
            while (y < 4) : (y += 1) {
                const trans = zm.translation(step * (@intToFloat(f32, x) - 2.0 + 0.5), step * (@intToFloat(f32, y) - 2.0 + 0.5), -20);
                const localTime = time + @intToFloat(f32, m) * 0.5;
                const model = zm.mul(zm.mul(zm.mul(zm.rotationX(localTime * (std.math.pi / 2.1)), zm.rotationY(localTime * (std.math.pi / 0.9))), zm.rotationZ(localTime * (std.math.pi / 1.3))), trans);
                const mvp = zm.mul(model, proj);
                const ubo = UniformBufferObject{
                    .mat = mvp,
                };
                ubos[m] = ubo;
                m += 1;
            }
        }
        encoder.writeBuffer(app.uniform_buffer, 0, &ubos);
    }

    const pass = encoder.beginRenderPass(&render_pass_info);
    pass.setPipeline(app.pipeline);
    pass.setVertexBuffer(0, app.vertex_buffer, 0, @sizeOf(Vertex) * vertices.len);
    pass.setBindGroup(0, app.bind_group, &.{0});
    pass.draw(vertices.len, 16, 0, 0);
    pass.end();
    pass.release();

    var command = encoder.finish(null);
    encoder.release();

    app.queue.submit(&.{command});
    command.release();
    core.swap_chain.?.present();
    back_buffer_view.release();
}
