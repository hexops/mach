const std = @import("std");

const mach = @import("mach");
const core = mach.core;
const gpu = mach.gpu;

const zm = @import("zmath");

const Vertex = @import("cube_mesh.zig").Vertex;
const vertices = @import("cube_mesh.zig").vertices;
const Quad = @import("quad_mesh.zig").Quad;
const quad = @import("quad_mesh.zig").quad;

pub const App = @This();

pub const mach_core_options = core.ComptimeOptions{
    .use_wgpu = false,
    .use_sysgpu = true,
};

const pixel_size = 8;

const UniformBufferObject = struct {
    mat: zm.Mat,
};
const PostUniformBufferObject = extern struct {
    width: u32,
    height: u32,
    pixel_size: u32 = pixel_size,
};
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

title_timer: core.Timer,
timer: core.Timer,

pipeline: *gpu.RenderPipeline,
normal_pipeline: *gpu.RenderPipeline,
vertex_buffer: *gpu.Buffer,
uniform_buffer: *gpu.Buffer,
bind_group: *gpu.BindGroup,

post_pipeline: *gpu.RenderPipeline,
post_vertex_buffer: *gpu.Buffer,
post_uniform_buffer: *gpu.Buffer,
post_bind_group: *gpu.BindGroup,

draw_texture_view: *gpu.TextureView,
depth_texture_view: *gpu.TextureView,
normal_texture_view: *gpu.TextureView,

pub fn init(app: *App) !void {
    try core.init(.{});
    app.title_timer = try core.Timer.start();
    app.timer = try core.Timer.start();

    try app.createRenderTextures();
    app.createDrawPipeline();
    app.createPostPipeline();
}

pub fn deinit(app: *App) void {
    defer _ = gpa.deinit();
    defer core.deinit();

    app.cleanup();
}

pub fn update(app: *App) !bool {
    var iter = core.pollEvents();
    while (iter.next()) |event| {
        switch (event) {
            .key_press => |ev| {
                if (ev.key == .space) return true;
            },
            .close => return true,
            .framebuffer_resize => {
                app.cleanup();
                try app.createRenderTextures();
                app.createDrawPipeline();
                app.createPostPipeline();
            },
            else => {},
        }
    }

    const size = core.size();
    const encoder = core.device.createCommandEncoder(null);
    encoder.writeBuffer(app.post_uniform_buffer, 0, &[_]PostUniformBufferObject{
        PostUniformBufferObject{
            .width = size.width,
            .height = size.height,
        },
    });

    {
        const time = app.timer.read() * 0.5;
        const model = zm.mul(zm.rotationX(time * (std.math.pi / 2.0)), zm.rotationZ(time * (std.math.pi / 2.0)));
        const view = zm.lookAtRh(
            zm.Vec{ 0, 5, 2, 1 },
            zm.Vec{ 0, 0, 0, 1 },
            zm.Vec{ 0, 0, 1, 0 },
        );
        const proj = zm.perspectiveFovRh(
            (std.math.pi / 4.0),
            @as(f32, @floatFromInt(core.descriptor.width)) / @as(f32, @floatFromInt(core.descriptor.height)),
            0.1,
            10,
        );
        const mvp = zm.mul(zm.mul(model, view), proj);
        const ubo = UniformBufferObject{
            .mat = zm.transpose(mvp),
        };
        encoder.writeBuffer(app.uniform_buffer, 0, &[_]UniformBufferObject{ubo});
    }

    {
        // render scene to downscaled texture
        const color_attachment = gpu.RenderPassColorAttachment{
            .view = app.draw_texture_view,
            .clear_value = std.mem.zeroes(gpu.Color),
            .load_op = .clear,
            .store_op = .store,
        };
        const render_pass_info = gpu.RenderPassDescriptor.init(.{
            .color_attachments = &.{color_attachment},
            .depth_stencil_attachment = &gpu.RenderPassDepthStencilAttachment{
                .view = app.depth_texture_view,
                .depth_load_op = .clear,
                .depth_store_op = .store,
                .depth_clear_value = 1.0,
            },
        });

        const pass = encoder.beginRenderPass(&render_pass_info);
        pass.setPipeline(app.pipeline);
        pass.setVertexBuffer(0, app.vertex_buffer, 0, @sizeOf(Vertex) * vertices.len);
        pass.setBindGroup(0, app.bind_group, &.{0});
        pass.draw(vertices.len, 1, 0, 0);
        pass.end();
        pass.release();
    }

    {
        // render scene normals to texture
        const normal_color_attachment = gpu.RenderPassColorAttachment{
            .view = app.normal_texture_view,
            .clear_value = .{ .r = 0.5, .b = 0.5, .g = 0.5, .a = 1.0 },
            .load_op = .clear,
            .store_op = .store,
        };
        const normal_render_pass_info = gpu.RenderPassDescriptor.init(.{
            .color_attachments = &.{normal_color_attachment},
        });

        const normal_pass = encoder.beginRenderPass(&normal_render_pass_info);
        normal_pass.setPipeline(app.normal_pipeline);
        normal_pass.setVertexBuffer(0, app.vertex_buffer, 0, @sizeOf(Vertex) * vertices.len);
        normal_pass.setBindGroup(0, app.bind_group, &.{0});
        normal_pass.draw(vertices.len, 1, 0, 0);
        normal_pass.end();
        normal_pass.release();
    }

    const back_buffer_view = core.swap_chain.getCurrentTextureView().?;
    {
        // render to swap chain using previous passes
        const post_color_attachment = gpu.RenderPassColorAttachment{
            .view = back_buffer_view,
            .clear_value = std.mem.zeroes(gpu.Color),
            .load_op = .clear,
            .store_op = .store,
        };
        const post_render_pass_info = gpu.RenderPassDescriptor.init(.{
            .color_attachments = &.{post_color_attachment},
        });

        const draw_pass = encoder.beginRenderPass(&post_render_pass_info);
        draw_pass.setPipeline(app.post_pipeline);
        draw_pass.setVertexBuffer(0, app.post_vertex_buffer, 0, @sizeOf(Quad) * quad.len);
        draw_pass.setBindGroup(0, app.post_bind_group, &.{0});
        draw_pass.draw(quad.len, 1, 0, 0);
        draw_pass.end();
        draw_pass.release();
    }

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
        try core.printTitle("Pixel Post Process [ {d}fps ] [ Input {d}hz ]", .{
            core.frameRate(),
            core.inputRate(),
        });
    }

    return false;
}

fn cleanup(app: *App) void {
    app.pipeline.release();
    app.normal_pipeline.release();
    app.vertex_buffer.release();
    app.uniform_buffer.release();
    app.bind_group.release();

    app.post_pipeline.release();
    app.post_vertex_buffer.release();
    app.post_uniform_buffer.release();
    app.post_bind_group.release();

    app.draw_texture_view.release();
    app.depth_texture_view.release();
    app.normal_texture_view.release();
}

fn createRenderTextures(app: *App) !void {
    const size = core.size();

    const draw_texture_desc = gpu.Texture.Descriptor.init(.{
        .size = .{ .width = size.width / pixel_size, .height = size.height / pixel_size },
        .format = .bgra8_unorm,
        .usage = .{ .texture_binding = true, .copy_dst = true, .render_attachment = true },
    });
    const draw_texture = core.device.createTexture(&draw_texture_desc);
    app.draw_texture_view = draw_texture.createView(null);
    draw_texture.release();

    const depth_texture_desc = gpu.Texture.Descriptor.init(.{
        .size = .{ .width = size.width / pixel_size, .height = size.height / pixel_size },
        .format = .depth32_float,
        .usage = .{ .texture_binding = true, .copy_dst = true, .render_attachment = true },
    });
    const depth_texture = core.device.createTexture(&depth_texture_desc);
    app.depth_texture_view = depth_texture.createView(null);
    depth_texture.release();

    const normal_texture_desc = gpu.Texture.Descriptor.init(.{
        .size = .{ .width = size.width / pixel_size, .height = size.height / pixel_size },
        .format = .bgra8_unorm,
        .usage = .{ .texture_binding = true, .copy_dst = true, .render_attachment = true },
    });
    const normal_texture = core.device.createTexture(&normal_texture_desc);
    app.normal_texture_view = normal_texture.createView(null);
    normal_texture.release();
}

fn createDrawPipeline(app: *App) void {
    const shader_module = core.device.createShaderModuleWGSL("shader.wgsl", @embedFile("shader.wgsl"));
    const vertex_attributes = [_]gpu.VertexAttribute{
        .{ .format = .float32x3, .offset = @offsetOf(Vertex, "pos"), .shader_location = 0 },
        .{ .format = .float32x3, .offset = @offsetOf(Vertex, "normal"), .shader_location = 1 },
        .{ .format = .float32x2, .offset = @offsetOf(Vertex, "uv"), .shader_location = 2 },
    };
    const vertex_buffer_layout = gpu.VertexBufferLayout.init(.{
        .array_stride = @sizeOf(Vertex),
        .step_mode = .vertex,
        .attributes = &vertex_attributes,
    });
    const vertex = gpu.VertexState.init(.{
        .module = shader_module,
        .entry_point = "vertex_main",
        .buffers = &.{vertex_buffer_layout},
    });

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

    const bgle = gpu.BindGroupLayout.Entry.buffer(0, .{ .vertex = true }, .uniform, true, 0);
    const bgl = core.device.createBindGroupLayout(
        &gpu.BindGroupLayout.Descriptor.init(.{
            .entries = &.{bgle},
        }),
    );

    const bind_group_layouts = [_]*gpu.BindGroupLayout{bgl};
    const pipeline_layout = core.device.createPipelineLayout(
        &gpu.PipelineLayout.Descriptor.init(.{
            .bind_group_layouts = &bind_group_layouts,
        }),
    );

    const vertex_buffer = core.device.createBuffer(&.{
        .usage = .{ .vertex = true },
        .size = @sizeOf(Vertex) * vertices.len,
        .mapped_at_creation = .true,
    });
    const vertex_mapped = vertex_buffer.getMappedRange(Vertex, 0, vertices.len);
    @memcpy(vertex_mapped.?, vertices[0..]);
    vertex_buffer.unmap();

    const uniform_buffer = core.device.createBuffer(&.{
        .usage = .{ .copy_dst = true, .uniform = true },
        .size = @sizeOf(UniformBufferObject),
        .mapped_at_creation = .false,
    });
    const bind_group = core.device.createBindGroup(
        &gpu.BindGroup.Descriptor.init(.{
            .layout = bgl,
            .entries = &.{
                gpu.BindGroup.Entry.buffer(0, uniform_buffer, 0, @sizeOf(UniformBufferObject), @sizeOf(UniformBufferObject)),
            },
        }),
    );

    const pipeline_descriptor = gpu.RenderPipeline.Descriptor{
        .fragment = &fragment,
        .layout = pipeline_layout,
        .vertex = vertex,
        .primitive = .{
            .cull_mode = .back,
        },
        .depth_stencil = &gpu.DepthStencilState{
            .format = .depth32_float,
            .depth_write_enabled = .true,
            .depth_compare = .less,
        },
    };

    {
        // "same" pipeline, different fragment shader to create a texture with normal information
        const normal_fs_module = core.device.createShaderModuleWGSL("normal_frag.wgsl", @embedFile("normal_frag.wgsl"));
        const normal_fragment = gpu.FragmentState.init(.{
            .module = normal_fs_module,
            .entry_point = "main",
            .targets = &.{color_target},
        });
        const normal_pipeline_descriptor = gpu.RenderPipeline.Descriptor{
            .fragment = &normal_fragment,
            .layout = pipeline_layout,
            .vertex = vertex,
            .primitive = .{
                .cull_mode = .back,
            },
        };
        app.normal_pipeline = core.device.createRenderPipeline(&normal_pipeline_descriptor);

        normal_fs_module.release();
    }

    app.pipeline = core.device.createRenderPipeline(&pipeline_descriptor);
    app.vertex_buffer = vertex_buffer;
    app.uniform_buffer = uniform_buffer;
    app.bind_group = bind_group;

    shader_module.release();
    pipeline_layout.release();
    bgl.release();
}

fn createPostPipeline(app: *App) void {
    const vs_module = core.device.createShaderModuleWGSL("pixel_vert.wgsl", @embedFile("pixel_vert.wgsl"));
    const vertex_attributes = [_]gpu.VertexAttribute{
        .{ .format = .float32x3, .offset = @offsetOf(Quad, "pos"), .shader_location = 0 },
        .{ .format = .float32x2, .offset = @offsetOf(Quad, "uv"), .shader_location = 1 },
    };
    const vertex_buffer_layout = gpu.VertexBufferLayout.init(.{
        .array_stride = @sizeOf(Quad),
        .step_mode = .vertex,
        .attributes = &vertex_attributes,
    });
    const vertex = gpu.VertexState.init(.{
        .module = vs_module,
        .entry_point = "main",
        .buffers = &.{vertex_buffer_layout},
    });

    const fs_module = core.device.createShaderModuleWGSL("pixel_frag.wgsl", @embedFile("pixel_frag.wgsl"));
    const blend = gpu.BlendState{};
    const color_target = gpu.ColorTargetState{
        .format = core.descriptor.format,
        .blend = &blend,
        .write_mask = gpu.ColorWriteMaskFlags.all,
    };
    const fragment = gpu.FragmentState.init(.{
        .module = fs_module,
        .entry_point = "main",
        .targets = &.{color_target},
    });

    const bgl = core.device.createBindGroupLayout(
        &gpu.BindGroupLayout.Descriptor.init(.{
            .entries = &.{
                gpu.BindGroupLayout.Entry.texture(0, .{ .fragment = true }, .float, .dimension_2d, false),
                gpu.BindGroupLayout.Entry.sampler(1, .{ .fragment = true }, .filtering),
                gpu.BindGroupLayout.Entry.texture(2, .{ .fragment = true }, .depth, .dimension_2d, false),
                gpu.BindGroupLayout.Entry.sampler(3, .{ .fragment = true }, .filtering),
                gpu.BindGroupLayout.Entry.texture(4, .{ .fragment = true }, .float, .dimension_2d, false),
                gpu.BindGroupLayout.Entry.sampler(5, .{ .fragment = true }, .filtering),
                gpu.BindGroupLayout.Entry.buffer(6, .{ .fragment = true }, .uniform, true, 0),
            },
        }),
    );

    const bind_group_layouts = [_]*gpu.BindGroupLayout{bgl};
    const pipeline_layout = core.device.createPipelineLayout(&gpu.PipelineLayout.Descriptor.init(.{
        .bind_group_layouts = &bind_group_layouts,
    }));

    const vertex_buffer = core.device.createBuffer(&.{
        .usage = .{ .vertex = true },
        .size = @sizeOf(Quad) * quad.len,
        .mapped_at_creation = .true,
    });
    const vertex_mapped = vertex_buffer.getMappedRange(Quad, 0, quad.len);
    @memcpy(vertex_mapped.?, quad[0..]);
    vertex_buffer.unmap();

    const draw_sampler = core.device.createSampler(null);
    const depth_sampler = core.device.createSampler(null);
    const normal_sampler = core.device.createSampler(null);
    const uniform_buffer = core.device.createBuffer(&.{
        .usage = .{ .copy_dst = true, .uniform = true },
        .size = @sizeOf(PostUniformBufferObject),
        .mapped_at_creation = .false,
    });
    const bind_group = core.device.createBindGroup(
        &gpu.BindGroup.Descriptor.init(.{
            .layout = bgl,
            .entries = &[_]gpu.BindGroup.Entry{
                gpu.BindGroup.Entry.textureView(0, app.draw_texture_view),
                gpu.BindGroup.Entry.sampler(1, draw_sampler),
                gpu.BindGroup.Entry.textureView(2, app.depth_texture_view),
                gpu.BindGroup.Entry.sampler(3, depth_sampler),
                gpu.BindGroup.Entry.textureView(4, app.normal_texture_view),
                gpu.BindGroup.Entry.sampler(5, normal_sampler),
                gpu.BindGroup.Entry.buffer(6, uniform_buffer, 0, @sizeOf(PostUniformBufferObject), @sizeOf(PostUniformBufferObject)),
            },
        }),
    );
    draw_sampler.release();
    depth_sampler.release();
    normal_sampler.release();

    const pipeline_descriptor = gpu.RenderPipeline.Descriptor{
        .fragment = &fragment,
        .layout = pipeline_layout,
        .vertex = vertex,
        .primitive = .{
            .cull_mode = .back,
        },
    };

    app.post_pipeline = core.device.createRenderPipeline(&pipeline_descriptor);
    app.post_vertex_buffer = vertex_buffer;
    app.post_uniform_buffer = uniform_buffer;
    app.post_bind_group = bind_group;

    vs_module.release();
    fs_module.release();
    pipeline_layout.release();
    bgl.release();
}
