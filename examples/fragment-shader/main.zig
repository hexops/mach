const std = @import("std");
const mach = @import("mach");
const gpu = @import("gpu");
const glfw = @import("glfw");
const zm = @import("zmath");

const App = mach.App(*FrameParams, .{});

const Vertex = struct {
    pos: @Vector(3, f32),
    uv: @Vector(2, f32),
};

// These vertices will make a simple square, on which we will draw with our fragment shader
const vertices = [_]Vertex{
    .{ .pos = .{ -0.5, 0, -0.5 }, .uv = .{ 0, 0 } },
    .{ .pos = .{ 0.5, 0, -0.5 }, .uv = .{ 1, 0 } },
    .{ .pos = .{ 0.5, 0, 0.5 }, .uv = .{ 1, 1 } },
    .{ .pos = .{ -0.5, 0, 0.5 }, .uv = .{ 0, 1 } },
};
// GPUs expext triangles so we can either rewrite some vertices in the Vertex buffer,
// Or we can use an Index buffer so that we can send less data to the gpu
const indices = [_]u16{ 0, 1, 2, 2, 3, 0 };

// The data we will send to the gpu on each frame.
// In other gpu APIs we may want to send this data using
// different methods (like push constants on vulkan) but
// these are not defined yet in the current gpuweb specification
const UniformBufferObject = struct {
    mat: zm.Mat,
    time: f32,
};

var timer: std.time.Timer = undefined;

pub fn main() !void {
    timer = try std.time.Timer.start();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    const ctx = try allocator.create(FrameParams);
    var app = try App.init(allocator, ctx, .{});

    // I prefer closing the example windows pressing space for simple examples
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
    // On linux it has a strange effect when you try to minimize the width or height to zero
    // This prevents the problem, note that it doesn't stop you from minimizing the window
    try app.window.setSizeLimits(.{ .width = 20, .height = 20 }, .{ .width = null, .height = null });

    const vs_module = app.device.createShaderModule(&.{
        .label = "my vertex shader",
        .code = .{ .wgsl = @embedFile("vert.wgsl") },
    });
    // Tell the vertex shader how to read the Vertex buffer
    const vertex_attributes = [_]gpu.VertexAttribute{
        .{ .format = .float32x3, .offset = @offsetOf(Vertex, "pos"), .shader_location = 0 }, // main( @location(0) .... check vert.wgsl
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
            .dst_factor = .one,
        },
        .alpha = .{
            .operation = .add,
            .src_factor = .one,
            .dst_factor = .one,
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

    // Tell the vertex and fragment shader they will receive a uniform buffer
    // The binding is the @binding(0) in our shaders
    const bgle = gpu.BindGroupLayout.Entry.buffer(0, .{ .vertex = true, .fragment = true }, .uniform, true, 0);
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
            .cull_mode = .none,
            .topology = .triangle_list,
            .strip_index_format = .none,
        },
    };

    const queue = app.device.getQueue();

    // Create and write the buffers to GPU memory
    const vertex_buffer = app.device.createBuffer(&.{
        .usage = .{ .copy_dst = true, .vertex = true },
        .size = @sizeOf(Vertex) * vertices.len,
        .mapped_at_creation = false,
    });
    queue.writeBuffer(vertex_buffer, 0, Vertex, vertices[0..]);
    defer vertex_buffer.release();

    const index_buffer = app.device.createBuffer(&.{
        .usage = .{ .copy_dst = true, .index = true },
        .size = @sizeOf(u16) * indices.len,
        .mapped_at_creation = false,
    });
    queue.writeBuffer(index_buffer, 0, @TypeOf(indices[0]), indices[0..]);
    defer index_buffer.release();

    const uniform_buffer = app.device.createBuffer(&.{
        .usage = .{ .copy_dst = true, .uniform = true },
        .size = @sizeOf(UniformBufferObject),
        .mapped_at_creation = false,
    });
    defer uniform_buffer.release();
    // Specify which buffer corresponds to the UniformBufferObject to send to the GPU
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
        .queue = queue,
        .vertex_buffer = vertex_buffer,
        .index_buffer = index_buffer,
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
    index_buffer: gpu.Buffer,
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

    // The data to send to the UniformBufferObject
    {
        const time = @intToFloat(f32, timer.read()) / @as(f32, std.time.ns_per_s);

        // These matrices multiplied together will translate our vertices
        // in world coordinates, instead of relative to the viewport,
        // check https://www.opengl-tutorial.org/beginners-tutorials/tutorial-3-matrices/
        // for a better explaination
        const model = zm.rotationY(time * (std.math.pi / 1.0));
        const view = zm.lookAtRh(
            zm.f32x4(0, 2, 0, 1),
            zm.f32x4(0, 0, 0, 1),
            zm.f32x4(0, 0, 1, 0),
        );
        const proj = zm.perspectiveFovRh(
            (std.math.pi / 4.0),
            @intToFloat(f32, app.current_desc.width) / @intToFloat(f32, app.current_desc.height),
            0.1,
            10,
        );
        const ubo = UniformBufferObject{
            .mat = zm.mul(zm.mul(model, view), proj),
            .time = time,
        };
        encoder.writeBuffer(params.uniform_buffer, 0, UniformBufferObject, &.{ubo});
    }

    // Set the vertex/index buffers, the bind group, and use indexed draw
    const pass = encoder.beginRenderPass(&render_pass_info);
    pass.setVertexBuffer(0, params.vertex_buffer, 0, @sizeOf(Vertex) * vertices.len);
    pass.setIndexBuffer(params.index_buffer, .uint16, 0, @sizeOf(u16) * indices.len);
    pass.setPipeline(params.pipeline);
    pass.setBindGroup(0, params.bind_group, &.{0});
    pass.drawIndexed(indices.len, 1, 0, 0, 0);
    pass.end();
    pass.release();

    var command = encoder.finish(null);
    encoder.release();

    params.queue.submit(&.{command});
    command.release();
    app.swap_chain.?.present();
    back_buffer_view.release();
}
