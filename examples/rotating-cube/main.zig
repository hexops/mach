const std = @import("std");
const mach = @import("mach");
const gpu = @import("gpu");
const glfw = @import("glfw");
const zm = @import("zmath");
const Vertex = @import("cube_mesh.zig").Vertex;
const vertices = @import("cube_mesh.zig").vertices;

const App = mach.App(*FrameParams, .{});

const UniformBufferObject = struct {
    mat: zm.Mat,
};

var timer: std.time.Timer = undefined;

pub fn main() !void {
    timer = try std.time.Timer.start();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    const ctx = try allocator.create(FrameParams);
    var app = try App.init(allocator, ctx, .{});

    app.window.setKeyCallback(struct {
        fn callback(window: glfw.Window, key: glfw.Key, scancode: i32, action: glfw.Action, mods: glfw.Mods) void {
            _ = scancode;
            _ = mods;
            if (action == .press) {
                switch (key) {
                    .space => window.setShouldClose(true),
                    else => {},
                }
            }
        }
    }.callback);
    try app.window.setSizeLimits(.{ .width = 20, .height = 20 }, .{ .width = null, .height = null });

    const vs_module = app.device.createShaderModule(&.{
        .label = "my vertex shader",
        .code = .{ .wgsl = @embedFile("vert.wgsl") },
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

    const fs_module = app.device.createShaderModule(&.{
        .label = "my fragment shader",
        .code = .{ .wgsl = @embedFile("frag.wgsl") },
    });

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
        .format = app.swap_chain_format,
        .blend = &blend,
        .write_mask = gpu.ColorWriteMask.all,
    };
    const fragment = gpu.FragmentState{
        .module = fs_module,
        .entry_point = "main",
        .targets = &.{color_target},
        .constants = null,
    };

    const bgle = gpu.BindGroupLayout.Entry.buffer(0, .{ .vertex = true }, .uniform, true, 0);
    const bgl = app.device.createBindGroupLayout(
        &gpu.BindGroupLayout.Descriptor{
            .entries = &.{bgle},
        },
    );

    const bind_group_layouts = [_]gpu.BindGroupLayout{bgl};
    const pipeline_layout = app.device.createPipelineLayout(&.{
        .bind_group_layouts = &bind_group_layouts,
    });

    const pipeline_descriptor = gpu.RenderPipeline.Descriptor{
        .fragment = &fragment,
        .layout = pipeline_layout,
        .depth_stencil = null,
        .vertex = .{
            .module = vs_module,
            .entry_point = "main",
            .buffers = &.{vertex_buffer_layout},
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
            .strip_index_format = .none,
        },
    };

    const vertex_buffer = app.device.createBuffer(&.{
        .usage = .{ .vertex = true },
        .size = @sizeOf(Vertex) * vertices.len,
        .mapped_at_creation = true,
    });
    var vertex_mapped = vertex_buffer.getMappedRange(Vertex, 0, vertices.len);
    std.mem.copy(Vertex, vertex_mapped, vertices[0..]);
    vertex_buffer.unmap();
    defer vertex_buffer.release();

    const uniform_buffer = app.device.createBuffer(&.{
        .usage = .{ .copy_dst = true, .uniform = true },
        .size = @sizeOf(UniformBufferObject),
        .mapped_at_creation = false,
    });
    defer uniform_buffer.release();
    const bind_group = app.device.createBindGroup(
        &gpu.BindGroup.Descriptor{
            .layout = bgl,
            .entries = &.{
                gpu.BindGroup.Entry.buffer(0, uniform_buffer, 0, @sizeOf(UniformBufferObject)),
            },
        },
    );
    defer bind_group.release();

    ctx.* = FrameParams{
        .pipeline = app.device.createRenderPipeline(&pipeline_descriptor),
        .queue = app.device.getQueue(),
        .vertex_buffer = vertex_buffer,
        .uniform_buffer = uniform_buffer,
        .bind_group = bind_group,
    };

    vs_module.release();
    fs_module.release();
    pipeline_layout.release();
    bgl.release();

    try app.run(.{ .frame = frame });
}

const FrameParams = struct {
    pipeline: gpu.RenderPipeline,
    queue: gpu.Queue,
    vertex_buffer: gpu.Buffer,
    uniform_buffer: gpu.Buffer,
    bind_group: gpu.BindGroup,
};

fn frame(app: *App, params: *FrameParams) !void {
    const back_buffer_view = app.swap_chain.?.getCurrentTextureView();
    const color_attachment = gpu.RenderPassColorAttachment{
        .view = back_buffer_view,
        .resolve_target = null,
        .clear_value = std.mem.zeroes(gpu.Color),
        .load_op = .clear,
        .store_op = .store,
    };

    const encoder = app.device.createCommandEncoder(null);
    const render_pass_info = gpu.RenderPassEncoder.Descriptor{
        .color_attachments = &.{color_attachment},
        .depth_stencil_attachment = null,
    };

    {
        const time = @intToFloat(f32, timer.read()) / @as(f32, std.time.ns_per_s);
        const model = zm.mul(zm.rotationX(time * (std.math.pi / 2.0)), zm.rotationZ(time * (std.math.pi / 2.0)));
        const view = zm.lookAtRh(
            zm.f32x4(0, 4, 2, 1),
            zm.f32x4(0, 0, 0, 1),
            zm.f32x4(0, 0, 1, 0),
        );
        const proj = zm.perspectiveFovRh(
            (std.math.pi / 4.0),
            @intToFloat(f32, app.current_desc.width) / @intToFloat(f32, app.current_desc.height),
            0.1,
            10,
        );
        const mvp = zm.mul(zm.mul(model, view), proj);
        const ubo = UniformBufferObject{
            .mat = zm.transpose(mvp),
        };
        encoder.writeBuffer(params.uniform_buffer, 0, UniformBufferObject, &.{ubo});
    }

    const pass = encoder.beginRenderPass(&render_pass_info);
    pass.setPipeline(params.pipeline);
    pass.setVertexBuffer(0, params.vertex_buffer, 0, @sizeOf(Vertex) * vertices.len);
    pass.setBindGroup(0, params.bind_group, &.{0});
    pass.draw(vertices.len, 1, 0, 0);
    pass.end();
    pass.release();

    var command = encoder.finish(null);
    encoder.release();

    params.queue.submit(&.{command});
    command.release();
    app.swap_chain.?.present();
    back_buffer_view.release();
}
