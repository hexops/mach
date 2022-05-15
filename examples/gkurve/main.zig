// TODO:
// - add texture and sampler.
// - find a way to use dynamic arrays in wgsl for ubos
// - understand how to move the triangles via matrix multplication

const std = @import("std");
const mach = @import("mach");
const gpu = @import("gpu");
const zm = @import("zmath");
const glfw = @import("glfw");

pub const Vertex = struct {
    pos: @Vector(4, f32),
    uv: @Vector(2, f32),
};
// Simple triangle
const WINDOW_WIDTH = 640;
const WINDOW_HEIGHT = 480;
const TRIANGLE_SCALE = 250;
const TRIANGLE_HEIGHT = TRIANGLE_SCALE * @sqrt(0.75);
pub const vertices = [_]Vertex{
    .{ .pos = .{ WINDOW_WIDTH / 2 + TRIANGLE_SCALE / 2, WINDOW_HEIGHT / 2 + TRIANGLE_HEIGHT, 0, 1 }, .uv = .{ 0.5, 1 } },
    .{ .pos = .{ WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2, 0, 1 }, .uv = .{ 0, 0 } },
    .{ .pos = .{ WINDOW_WIDTH / 2 + TRIANGLE_SCALE, WINDOW_HEIGHT / 2 + 0, 0, 1 }, .uv = .{ 1, 0 } },

    .{ .pos = .{ WINDOW_WIDTH / 2 + TRIANGLE_SCALE / 2, WINDOW_HEIGHT / 2, 0, 1 }, .uv = .{ 0.5, 1 } },
    .{ .pos = .{ WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2 - TRIANGLE_HEIGHT, 0, 1 }, .uv = .{ 0, 0 } },
    .{ .pos = .{ WINDOW_WIDTH / 2 + TRIANGLE_SCALE, WINDOW_HEIGHT / 2 - TRIANGLE_HEIGHT, 0, 1 }, .uv = .{ 1, 0 } },

    .{ .pos = .{ WINDOW_WIDTH / 2 - TRIANGLE_SCALE / 2, WINDOW_HEIGHT / 2 + TRIANGLE_HEIGHT, 0, 1 }, .uv = .{ 0.5, 1 } },
    .{ .pos = .{ WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2, 0, 1 }, .uv = .{ 0, 0 } },
    .{ .pos = .{ WINDOW_WIDTH / 2 - TRIANGLE_SCALE, WINDOW_HEIGHT / 2 + 0, 0, 1 }, .uv = .{ 1, 0 } },
};

pub const options = mach.Options{ .width = 512, .height = 512 };

// The uniform read by the vertex shader, it contains the matrix
// that will move vertices
const VertexUniform = struct {
    mat: zm.Mat,
};

const FragUniform = struct {
    // TODO use an enum? Remember that it will be casted to u32 in wgsl
    type: u32,
    // Padding for struct alignment to 16 bytes (minimum in WebGPU uniform).
    padding: @Vector(3, f32) = undefined,
};
// TODO texture and sampler, create buffers and use an index field
// in FragUniform to tell which texture to read
const App = @This();

pipeline: gpu.RenderPipeline,
queue: gpu.Queue,
vertex_buffer: gpu.Buffer,
vertex_uniform_buffer: gpu.Buffer,
frag_uniform_buffer: gpu.Buffer,
bind_group: gpu.BindGroup,

pub fn init(app: *App, engine: *mach.Engine) !void {
    engine.core.setKeyCallback(struct {
        fn callback(_: *App, eng: *mach.Engine, key: mach.Key, action: mach.Action) void {
            if (action == .press) {
                switch (key) {
                    .space => eng.core.setShouldClose(true),
                    else => {},
                }
            }
        }
    }.callback);
    try engine.core.setSizeLimits(.{ .width = 20, .height = 20 }, .{ .width = null, .height = null });

    const vs_module = engine.gpu_driver.device.createShaderModule(&.{
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

    const fs_module = engine.gpu_driver.device.createShaderModule(&.{
        .label = "my fragment shader",
        .code = .{ .wgsl = @embedFile("frag.wgsl") },
    });

    // Fragment state
    const color_target = gpu.ColorTargetState{
        .format = engine.gpu_driver.swap_chain_format,
        .blend = null,
        .write_mask = gpu.ColorWriteMask.all,
    };
    const fragment = gpu.FragmentState{
        .module = fs_module,
        .entry_point = "main",
        .targets = &.{color_target},
        .constants = null,
    };

    const vbgle = gpu.BindGroupLayout.Entry.buffer(0, .{ .vertex = true }, .uniform, true, 0);
    const fbgle = gpu.BindGroupLayout.Entry.buffer(1, .{ .fragment = true }, .read_only_storage, true, 0);
    const bgl = engine.gpu_driver.device.createBindGroupLayout(
        &gpu.BindGroupLayout.Descriptor{
            .entries = &.{ vbgle, fbgle },
        },
    );
    const bind_group_layouts = [_]gpu.BindGroupLayout{bgl};
    const pipeline_layout = engine.gpu_driver.device.createPipelineLayout(&.{
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
    const vertex_buffer = engine.gpu_driver.device.createBuffer(&.{
        .usage = .{ .vertex = true },
        .size = @sizeOf(Vertex) * vertices.len,
        .mapped_at_creation = true,
    });
    var vertex_mapped = vertex_buffer.getMappedRange(Vertex, 0, vertices.len);
    std.mem.copy(Vertex, vertex_mapped, vertices[0..]);
    vertex_buffer.unmap();

    const vertex_uniform_buffer = engine.gpu_driver.device.createBuffer(&.{
        .usage = .{ .copy_dst = true, .uniform = true },
        .size = @sizeOf(VertexUniform),
        .mapped_at_creation = false,
    });

    const frag_uniform_buffer = engine.gpu_driver.device.createBuffer(&.{
        .usage = .{ .storage = true },
        .size = @sizeOf(FragUniform) * vertices.len / 3,
        .mapped_at_creation = true,
    });
    var frag_uniform_mapped = frag_uniform_buffer.getMappedRange(FragUniform, 0, vertices.len / 3);
    const tmp_frag_ubo = [_]FragUniform{
        .{
            .type = 1,
        },
        .{
            .type = 0,
        },
        .{
            .type = 2,
        },
    };
    std.mem.copy(FragUniform, frag_uniform_mapped, &tmp_frag_ubo);
    frag_uniform_buffer.unmap();

    const bind_group = engine.gpu_driver.device.createBindGroup(
        &gpu.BindGroup.Descriptor{
            .layout = bgl,
            .entries = &.{
                gpu.BindGroup.Entry.buffer(0, vertex_uniform_buffer, 0, @sizeOf(VertexUniform)),
                gpu.BindGroup.Entry.buffer(1, frag_uniform_buffer, 0, @sizeOf(FragUniform) * vertices.len / 3),
            },
        },
    );

    app.pipeline = engine.gpu_driver.device.createRenderPipeline(&pipeline_descriptor);
    app.queue = engine.gpu_driver.device.getQueue();
    app.vertex_buffer = vertex_buffer;
    app.vertex_uniform_buffer = vertex_uniform_buffer;
    app.frag_uniform_buffer = frag_uniform_buffer;
    app.bind_group = bind_group;

    vs_module.release();
    fs_module.release();
    pipeline_layout.release();
    bgl.release();
}

pub fn deinit(app: *App, _: *mach.Engine) void {
    app.vertex_buffer.release();
    app.vertex_uniform_buffer.release();
    app.frag_uniform_buffer.release();
    app.bind_group.release();
}

pub fn update(app: *App, engine: *mach.Engine) !bool {
    const back_buffer_view = engine.gpu_driver.swap_chain.?.getCurrentTextureView();
    const color_attachment = gpu.RenderPassColorAttachment{
        .view = back_buffer_view,
        .resolve_target = null,
        .clear_value = std.mem.zeroes(gpu.Color),
        .load_op = .clear,
        .store_op = .store,
    };

    const encoder = engine.gpu_driver.device.createCommandEncoder(null);
    const render_pass_info = gpu.RenderPassEncoder.Descriptor{
        .color_attachments = &.{color_attachment},
    };

    {
        // Using a view allows us to move the camera without having to change the actual
        // global poitions of each vertex
        const view = zm.lookAtRh(
            zm.f32x4(0, 0, 1, 1),
            zm.f32x4(0, 0, 0, 1),
            zm.f32x4(0, 1, 0, 0),
        );
        const proj = zm.orthographicRh(
            @intToFloat(f32, engine.gpu_driver.current_desc.width),
            @intToFloat(f32, engine.gpu_driver.current_desc.height),
            -100,
            100,
        );

        const mvp = zm.mul(zm.mul(view, proj), zm.translation(-1, -1, 0));
        const ubos = VertexUniform{
            .mat = mvp,
        };
        encoder.writeBuffer(app.vertex_uniform_buffer, 0, VertexUniform, &.{ubos});
    }

    const pass = encoder.beginRenderPass(&render_pass_info);
    pass.setPipeline(app.pipeline);
    pass.setVertexBuffer(0, app.vertex_buffer, 0, @sizeOf(Vertex) * vertices.len);
    pass.setBindGroup(0, app.bind_group, &.{ 0, 0 });
    pass.draw(vertices.len, 1, 0, 0);
    pass.end();
    pass.release();

    var command = encoder.finish(null);
    encoder.release();

    app.queue.submit(&.{command});
    command.release();
    engine.gpu_driver.swap_chain.?.present();
    back_buffer_view.release();

    return true;
}
