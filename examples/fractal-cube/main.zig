//! To get the effect we want, we need a texture on which to render
//! (we can't use the swapchain texture directly, but we can get the effect
//! by doing the same render pass twice, on the texture and the swapchain.
//! We also need a second texture to use on the cube, that after the render pass
//! needs to copy the other texture. We can't use the same texture since
//! it would interfere with the sincronization on the gpu during the render pass.
//! This demo currently does not work on opengl, because engine.current_desc.width/height,
//! are set to 0 after engine.init() and because webgpu does not implement copyTextureToTexture,
//! for opengl

const std = @import("std");
const mach = @import("mach");
const gpu = @import("gpu");
const glfw = @import("glfw");
const zm = @import("zmath");
const Vertex = @import("cube_mesh.zig").Vertex;
const vertices = @import("cube_mesh.zig").vertices;

const App = @This();

const UniformBufferObject = struct {
    mat: zm.Mat,
};

var timer: mach.Timer = undefined;

pipeline: gpu.RenderPipeline,
queue: gpu.Queue,
vertex_buffer: gpu.Buffer,
uniform_buffer: gpu.Buffer,
bind_group: gpu.BindGroup,
depth_texture: ?gpu.Texture,
depth_texture_view: gpu.TextureView,
cube_texture: gpu.Texture,
cube_texture_view: gpu.TextureView,
cube_texture_render: gpu.Texture,
cube_texture_view_render: gpu.TextureView,
sampler: gpu.Sampler,
bgl: gpu.BindGroupLayout,

pub fn init(app: *App, engine: *mach.Engine) !void {
    timer = try mach.Timer.start();

    try engine.setSizeLimits(.{ .width = 20, .height = 20 }, .{ .width = null, .height = null });

    const vs_module = engine.device.createShaderModule(&.{
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

    const fs_module = engine.device.createShaderModule(&.{
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

    const bgle_buffer = gpu.BindGroupLayout.Entry.buffer(0, .{ .vertex = true }, .uniform, true, 0);
    const bgle_sampler = gpu.BindGroupLayout.Entry.sampler(1, .{ .fragment = true }, .filtering);
    const bgle_textureview = gpu.BindGroupLayout.Entry.texture(2, .{ .fragment = true }, .float, .dimension_2d, false);
    const bgl = engine.device.createBindGroupLayout(
        &gpu.BindGroupLayout.Descriptor{
            .entries = &.{ bgle_buffer, bgle_sampler, bgle_textureview },
        },
    );

    const bind_group_layouts = [_]gpu.BindGroupLayout{bgl};
    const pipeline_layout = engine.device.createPipelineLayout(&.{
        .bind_group_layouts = &bind_group_layouts,
    });

    const pipeline_descriptor = gpu.RenderPipeline.Descriptor{
        .fragment = &fragment,
        .layout = pipeline_layout,
        .depth_stencil = &.{
            .format = .depth24_plus,
            .depth_write_enabled = true,
            .depth_compare = .less,
        },
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

    const vertex_buffer = engine.device.createBuffer(&.{
        .usage = .{ .vertex = true },
        .size = @sizeOf(Vertex) * vertices.len,
        .mapped_at_creation = true,
    });
    var vertex_mapped = vertex_buffer.getMappedRange(Vertex, 0, vertices.len);
    std.mem.copy(Vertex, vertex_mapped, vertices[0..]);
    vertex_buffer.unmap();

    const uniform_buffer = engine.device.createBuffer(&.{
        .usage = .{ .copy_dst = true, .uniform = true },
        .size = @sizeOf(UniformBufferObject),
        .mapped_at_creation = false,
    });

    // The texture to put on the cube
    const cube_texture = engine.device.createTexture(&gpu.Texture.Descriptor{
        .usage = .{ .texture_binding = true, .copy_dst = true },
        .size = .{ .width = engine.current_desc.width, .height = engine.current_desc.height },
        .format = engine.swap_chain_format,
    });
    // The texture on which we render
    const cube_texture_render = engine.device.createTexture(&gpu.Texture.Descriptor{
        .usage = .{ .render_attachment = true, .copy_src = true },
        .size = .{ .width = engine.current_desc.width, .height = engine.current_desc.height },
        .format = engine.swap_chain_format,
    });

    const sampler = engine.device.createSampler(&gpu.Sampler.Descriptor{
        .mag_filter = .linear,
        .min_filter = .linear,
    });

    const cube_texture_view = cube_texture.createView(&gpu.TextureView.Descriptor{
        .format = engine.swap_chain_format,
        .dimension = .dimension_2d,
        .mip_level_count = 1,
        .array_layer_count = 1,
    });
    const cube_texture_view_render = cube_texture_render.createView(&gpu.TextureView.Descriptor{
        .format = engine.swap_chain_format,
        .dimension = .dimension_2d,
        .mip_level_count = 1,
        .array_layer_count = 1,
    });

    const bind_group = engine.device.createBindGroup(
        &gpu.BindGroup.Descriptor{
            .layout = bgl,
            .entries = &.{
                gpu.BindGroup.Entry.buffer(0, uniform_buffer, 0, @sizeOf(UniformBufferObject)),
                gpu.BindGroup.Entry.sampler(1, sampler),
                gpu.BindGroup.Entry.textureView(2, cube_texture_view),
            },
        },
    );

    app.pipeline = engine.device.createRenderPipeline(&pipeline_descriptor);
    app.queue = engine.device.getQueue();
    app.vertex_buffer = vertex_buffer;
    app.uniform_buffer = uniform_buffer;
    app.bind_group = bind_group;
    app.depth_texture = null;
    app.depth_texture_view = undefined;
    app.cube_texture = cube_texture;
    app.cube_texture_view = cube_texture_view;
    app.cube_texture_render = cube_texture_render;
    app.cube_texture_view_render = cube_texture_view_render;
    app.sampler = sampler;
    app.bgl = bgl;

    vs_module.release();
    fs_module.release();
    pipeline_layout.release();
}

pub fn deinit(app: *App, _: *mach.Engine) void {
    app.bgl.release();
    app.vertex_buffer.release();
    app.uniform_buffer.release();
    app.cube_texture.release();
    app.cube_texture_render.release();
    app.sampler.release();
    app.cube_texture_view.release();
    app.cube_texture_view_render.release();
    app.bind_group.release();
    app.depth_texture.?.release();
    app.depth_texture_view.release();
}

pub fn update(app: *App, engine: *mach.Engine) !bool {
    while (engine.pollEvent()) |event| {
        switch (event) {
            .key_press => |ev| {
                if (ev.key == .space)
                    engine.setShouldClose(true);
            },
            else => {},
        }
    }

    const cube_view = app.cube_texture_view_render;
    const back_buffer_view = engine.swap_chain.?.getCurrentTextureView();

    const cube_color_attachment = gpu.RenderPassColorAttachment{
        .view = cube_view,
        .resolve_target = null,
        .clear_value = gpu.Color{ .r = 0.5, .g = 0.5, .b = 0.5, .a = 1 },
        .load_op = .clear,
        .store_op = .store,
    };
    const color_attachment = gpu.RenderPassColorAttachment{
        .view = back_buffer_view,
        .resolve_target = null,
        .clear_value = gpu.Color{ .r = 0.5, .g = 0.5, .b = 0.5, .a = 1 },
        .load_op = .clear,
        .store_op = .store,
    };

    const depth_stencil_attachment = gpu.RenderPassDepthStencilAttachment{
        .view = app.depth_texture_view,
        .depth_load_op = .clear,
        .depth_store_op = .store,
        .depth_clear_value = 1.0,
        .stencil_load_op = .none,
        .stencil_store_op = .none,
    };

    const encoder = engine.device.createCommandEncoder(null);
    const cube_render_pass_info = gpu.RenderPassEncoder.Descriptor{
        .color_attachments = &.{cube_color_attachment},
        .depth_stencil_attachment = &depth_stencil_attachment,
    };
    const render_pass_info = gpu.RenderPassEncoder.Descriptor{
        .color_attachments = &.{color_attachment},
        .depth_stencil_attachment = &depth_stencil_attachment,
    };

    {
        const time = timer.read();
        const model = zm.mul(zm.rotationX(time * (std.math.pi / 2.0)), zm.rotationZ(time * (std.math.pi / 2.0)));
        const view = zm.lookAtRh(
            zm.f32x4(0, -4, 0, 1),
            zm.f32x4(0, 0, 0, 1),
            zm.f32x4(0, 0, 1, 0),
        );
        const proj = zm.perspectiveFovRh(
            (std.math.pi * 2.0 / 5.0),
            @intToFloat(f32, engine.current_desc.width) / @intToFloat(f32, engine.current_desc.height),
            1,
            100,
        );
        const ubo = UniformBufferObject{
            .mat = zm.transpose(zm.mul(zm.mul(model, view), proj)),
        };
        encoder.writeBuffer(app.uniform_buffer, 0, UniformBufferObject, &.{ubo});
    }

    const pass = encoder.beginRenderPass(&render_pass_info);
    pass.setPipeline(app.pipeline);
    pass.setBindGroup(0, app.bind_group, &.{0});
    pass.setVertexBuffer(0, app.vertex_buffer, 0, @sizeOf(Vertex) * vertices.len);
    pass.draw(vertices.len, 1, 0, 0);
    pass.end();
    pass.release();

    encoder.copyTextureToTexture(
        &gpu.ImageCopyTexture{
            .texture = app.cube_texture_render,
        },
        &gpu.ImageCopyTexture{
            .texture = app.cube_texture,
        },
        &.{ .width = engine.current_desc.width, .height = engine.current_desc.height },
    );

    const cube_pass = encoder.beginRenderPass(&cube_render_pass_info);
    cube_pass.setPipeline(app.pipeline);
    cube_pass.setBindGroup(0, app.bind_group, &.{0});
    cube_pass.setVertexBuffer(0, app.vertex_buffer, 0, @sizeOf(Vertex) * vertices.len);
    cube_pass.draw(vertices.len, 1, 0, 0);
    cube_pass.end();
    cube_pass.release();

    var command = encoder.finish(null);
    encoder.release();

    app.queue.submit(&.{command});
    command.release();
    engine.swap_chain.?.present();
    back_buffer_view.release();

    return true;
}

pub fn resize(app: *App, engine: *mach.Engine, width: u32, height: u32) !void {
    if (app.depth_texture != null) {
        app.depth_texture.?.release();
        app.depth_texture = engine.device.createTexture(&gpu.Texture.Descriptor{
            .usage = .{ .render_attachment = true },
            .size = .{ .width = width, .height = height },
            .format = .depth24_plus,
        });

        app.cube_texture.release();
        app.cube_texture = engine.device.createTexture(&gpu.Texture.Descriptor{
            .usage = .{ .texture_binding = true, .copy_dst = true },
            .size = .{ .width = width, .height = height },
            .format = engine.swap_chain_format,
        });
        app.cube_texture_render.release();
        app.cube_texture_render = engine.device.createTexture(&gpu.Texture.Descriptor{
            .usage = .{ .render_attachment = true, .copy_src = true },
            .size = .{ .width = width, .height = height },
            .format = engine.swap_chain_format,
        });

        app.depth_texture_view.release();
        app.depth_texture_view = app.depth_texture.?.createView(&gpu.TextureView.Descriptor{
            .format = .depth24_plus,
            .dimension = .dimension_2d,
            .array_layer_count = 1,
            .mip_level_count = 1,
        });

        app.cube_texture_view.release();
        app.cube_texture_view = app.cube_texture.createView(&gpu.TextureView.Descriptor{
            .format = engine.swap_chain_format,
            .dimension = .dimension_2d,
            .mip_level_count = 1,
            .array_layer_count = 1,
        });
        app.cube_texture_view_render.release();
        app.cube_texture_view_render = app.cube_texture_render.createView(&gpu.TextureView.Descriptor{
            .format = engine.swap_chain_format,
            .dimension = .dimension_2d,
            .mip_level_count = 1,
            .array_layer_count = 1,
        });

        app.bind_group.release();
        app.bind_group = engine.device.createBindGroup(
            &gpu.BindGroup.Descriptor{
                .layout = app.bgl,
                .entries = &.{
                    gpu.BindGroup.Entry.buffer(0, app.uniform_buffer, 0, @sizeOf(UniformBufferObject)),
                    gpu.BindGroup.Entry.sampler(1, app.sampler),
                    gpu.BindGroup.Entry.textureView(2, app.cube_texture_view),
                },
            },
        );
    } else {
        app.depth_texture = engine.device.createTexture(&gpu.Texture.Descriptor{
            .usage = .{ .render_attachment = true },
            .size = .{ .width = width, .height = height },
            .format = .depth24_plus,
        });
        app.depth_texture_view = app.depth_texture.?.createView(&gpu.TextureView.Descriptor{
            .format = .depth24_plus,
            .dimension = .dimension_2d,
            .array_layer_count = 1,
            .mip_level_count = 1,
        });
    }
}
