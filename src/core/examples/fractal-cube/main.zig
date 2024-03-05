//! To get the effect we want, we need a texture on which to render;
//! we can't use the swapchain texture directly, but we can get the effect
//! by doing the same render pass twice, on the texture and the swapchain.
//! We also need a second texture to use on the cube (after the render pass
//! it needs to copy the other texture.) We can't use the same texture since
//! it would interfere with the synchronization on the gpu during the render pass.
//! This demo currently does not work on opengl, because core.descriptor.width/height,
//! are set to 0 after core.init() and because webgpu does not implement copyTextureToTexture,
//! for opengl

const std = @import("std");
const core = @import("mach").core;
const gpu = core.gpu;
const zm = @import("zmath");
const Vertex = @import("cube_mesh.zig").Vertex;
const vertices = @import("cube_mesh.zig").vertices;

pub const App = @This();

const UniformBufferObject = struct {
    mat: zm.Mat,
};

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

title_timer: core.Timer,
timer: core.Timer,
pipeline: *gpu.RenderPipeline,
vertex_buffer: *gpu.Buffer,
uniform_buffer: *gpu.Buffer,
bind_group: *gpu.BindGroup,
depth_texture: ?*gpu.Texture,
depth_texture_view: *gpu.TextureView,
cube_texture: *gpu.Texture,
cube_texture_view: *gpu.TextureView,
cube_texture_render: *gpu.Texture,
cube_texture_view_render: *gpu.TextureView,
sampler: *gpu.Sampler,
bgl: *gpu.BindGroupLayout,

pub fn init(app: *App) !void {
    try core.init(.{});

    const shader_module = core.device.createShaderModuleWGSL("shader.wgsl", @embedFile("shader.wgsl"));

    const vertex_attributes = [_]gpu.VertexAttribute{
        .{ .format = .float32x4, .offset = @offsetOf(Vertex, "pos"), .shader_location = 0 },
        .{ .format = .float32x2, .offset = @offsetOf(Vertex, "uv"), .shader_location = 1 },
    };
    const vertex_buffer_layout = gpu.VertexBufferLayout.init(.{
        .array_stride = @sizeOf(Vertex),
        .attributes = &vertex_attributes,
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

    const bgle_buffer = gpu.BindGroupLayout.Entry.buffer(0, .{ .vertex = true }, .uniform, true, 0);
    const bgle_sampler = gpu.BindGroupLayout.Entry.sampler(1, .{ .fragment = true }, .filtering);
    const bgle_textureview = gpu.BindGroupLayout.Entry.texture(2, .{ .fragment = true }, .float, .dimension_2d, false);
    const bgl = core.device.createBindGroupLayout(
        &gpu.BindGroupLayout.Descriptor.init(.{
            .entries = &.{ bgle_buffer, bgle_sampler, bgle_textureview },
        }),
    );

    const bind_group_layouts = [_]*gpu.BindGroupLayout{bgl};
    const pipeline_layout = core.device.createPipelineLayout(&gpu.PipelineLayout.Descriptor.init(.{
        .bind_group_layouts = &bind_group_layouts,
    }));

    const pipeline_descriptor = gpu.RenderPipeline.Descriptor{
        .fragment = &fragment,
        .layout = pipeline_layout,
        .depth_stencil = &.{
            .format = .depth24_plus,
            .depth_write_enabled = .true,
            .depth_compare = .less,
        },
        .vertex = gpu.VertexState.init(.{
            .module = shader_module,
            .entry_point = "vertex_main",
            .buffers = &.{vertex_buffer_layout},
        }),
        .primitive = .{
            .cull_mode = .back,
        },
    };

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

    // The texture to put on the cube
    const cube_texture = core.device.createTexture(&gpu.Texture.Descriptor{
        .usage = .{ .texture_binding = true, .copy_dst = true },
        .size = .{ .width = core.descriptor.width, .height = core.descriptor.height },
        .format = core.descriptor.format,
    });
    // The texture on which we render
    const cube_texture_render = core.device.createTexture(&gpu.Texture.Descriptor{
        .usage = .{ .render_attachment = true, .copy_src = true },
        .size = .{ .width = core.descriptor.width, .height = core.descriptor.height },
        .format = core.descriptor.format,
    });

    const sampler = core.device.createSampler(&gpu.Sampler.Descriptor{
        .mag_filter = .linear,
        .min_filter = .linear,
    });

    const cube_texture_view = cube_texture.createView(&gpu.TextureView.Descriptor{
        .format = core.descriptor.format,
        .dimension = .dimension_2d,
        .mip_level_count = 1,
        .array_layer_count = 1,
    });
    const cube_texture_view_render = cube_texture_render.createView(&gpu.TextureView.Descriptor{
        .format = core.descriptor.format,
        .dimension = .dimension_2d,
        .mip_level_count = 1,
        .array_layer_count = 1,
    });

    const bind_group = core.device.createBindGroup(
        &gpu.BindGroup.Descriptor.init(.{
            .layout = bgl,
            .entries = &.{
                gpu.BindGroup.Entry.buffer(0, uniform_buffer, 0, @sizeOf(UniformBufferObject)),
                gpu.BindGroup.Entry.sampler(1, sampler),
                gpu.BindGroup.Entry.textureView(2, cube_texture_view),
            },
        }),
    );

    const depth_texture = core.device.createTexture(&gpu.Texture.Descriptor{
        .usage = .{ .render_attachment = true },
        .size = .{ .width = core.descriptor.width, .height = core.descriptor.height },
        .format = .depth24_plus,
    });
    const depth_texture_view = depth_texture.createView(&gpu.TextureView.Descriptor{
        .format = .depth24_plus,
        .dimension = .dimension_2d,
        .array_layer_count = 1,
        .mip_level_count = 1,
    });

    app.timer = try core.Timer.start();
    app.title_timer = try core.Timer.start();
    app.pipeline = core.device.createRenderPipeline(&pipeline_descriptor);
    app.vertex_buffer = vertex_buffer;
    app.uniform_buffer = uniform_buffer;
    app.bind_group = bind_group;
    app.depth_texture = depth_texture;
    app.depth_texture_view = depth_texture_view;
    app.cube_texture = cube_texture;
    app.cube_texture_view = cube_texture_view;
    app.cube_texture_render = cube_texture_render;
    app.cube_texture_view_render = cube_texture_view_render;
    app.sampler = sampler;
    app.bgl = bgl;

    shader_module.release();
    pipeline_layout.release();
}

pub fn deinit(app: *App) void {
    defer _ = gpa.deinit();
    defer core.deinit();

    app.pipeline.release();
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

pub fn update(app: *App) !bool {
    var iter = core.pollEvents();
    while (iter.next()) |event| {
        switch (event) {
            .key_press => |ev| {
                if (ev.key == .space) return true;
            },
            .close => return true,
            .framebuffer_resize => |ev| {
                app.depth_texture.?.release();
                app.depth_texture = core.device.createTexture(&gpu.Texture.Descriptor{
                    .usage = .{ .render_attachment = true },
                    .size = .{ .width = ev.width, .height = ev.height },
                    .format = .depth24_plus,
                });

                app.cube_texture.release();
                app.cube_texture = core.device.createTexture(&gpu.Texture.Descriptor{
                    .usage = .{ .texture_binding = true, .copy_dst = true },
                    .size = .{ .width = ev.width, .height = ev.height },
                    .format = core.descriptor.format,
                });
                app.cube_texture_render.release();
                app.cube_texture_render = core.device.createTexture(&gpu.Texture.Descriptor{
                    .usage = .{ .render_attachment = true, .copy_src = true },
                    .size = .{ .width = ev.width, .height = ev.height },
                    .format = core.descriptor.format,
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
                    .format = core.descriptor.format,
                    .dimension = .dimension_2d,
                    .mip_level_count = 1,
                    .array_layer_count = 1,
                });
                app.cube_texture_view_render.release();
                app.cube_texture_view_render = app.cube_texture_render.createView(&gpu.TextureView.Descriptor{
                    .format = core.descriptor.format,
                    .dimension = .dimension_2d,
                    .mip_level_count = 1,
                    .array_layer_count = 1,
                });

                app.bind_group.release();
                app.bind_group = core.device.createBindGroup(
                    &gpu.BindGroup.Descriptor.init(.{
                        .layout = app.bgl,
                        .entries = &.{
                            gpu.BindGroup.Entry.buffer(0, app.uniform_buffer, 0, @sizeOf(UniformBufferObject)),
                            gpu.BindGroup.Entry.sampler(1, app.sampler),
                            gpu.BindGroup.Entry.textureView(2, app.cube_texture_view),
                        },
                    }),
                );
            },
            else => {},
        }
    }

    const cube_view = app.cube_texture_view_render;
    const back_buffer_view = core.swap_chain.getCurrentTextureView().?;

    const cube_color_attachment = gpu.RenderPassColorAttachment{
        .view = cube_view,
        .clear_value = gpu.Color{ .r = 0.5, .g = 0.5, .b = 0.5, .a = 1 },
        .load_op = .clear,
        .store_op = .store,
    };
    const color_attachment = gpu.RenderPassColorAttachment{
        .view = back_buffer_view,
        .clear_value = gpu.Color{ .r = 0.5, .g = 0.5, .b = 0.5, .a = 1 },
        .load_op = .clear,
        .store_op = .store,
    };

    const depth_stencil_attachment = gpu.RenderPassDepthStencilAttachment{
        .view = app.depth_texture_view,
        .depth_load_op = .clear,
        .depth_store_op = .store,
        .depth_clear_value = 1.0,
    };

    const encoder = core.device.createCommandEncoder(null);
    const cube_render_pass_info = gpu.RenderPassDescriptor.init(.{
        .color_attachments = &.{cube_color_attachment},
        .depth_stencil_attachment = &depth_stencil_attachment,
    });
    const render_pass_info = gpu.RenderPassDescriptor.init(.{
        .color_attachments = &.{color_attachment},
        .depth_stencil_attachment = &depth_stencil_attachment,
    });

    {
        const time = app.timer.read();
        const model = zm.mul(zm.rotationX(time * (std.math.pi / 2.0)), zm.rotationZ(time * (std.math.pi / 2.0)));
        const view = zm.lookAtRh(
            zm.Vec{ 0, -4, 0, 1 },
            zm.Vec{ 0, 0, 0, 1 },
            zm.Vec{ 0, 0, 1, 0 },
        );
        const proj = zm.perspectiveFovRh(
            (std.math.pi * 2.0 / 5.0),
            @as(f32, @floatFromInt(core.descriptor.width)) / @as(f32, @floatFromInt(core.descriptor.height)),
            1,
            100,
        );
        const ubo = UniformBufferObject{
            .mat = zm.transpose(zm.mul(zm.mul(model, view), proj)),
        };
        encoder.writeBuffer(app.uniform_buffer, 0, &[_]UniformBufferObject{ubo});
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
        &.{ .width = core.descriptor.width, .height = core.descriptor.height },
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

    const queue = core.queue;
    queue.submit(&[_]*gpu.CommandBuffer{command});
    command.release();
    core.swap_chain.present();
    back_buffer_view.release();

    // update the window title every second
    if (app.title_timer.read() >= 1.0) {
        app.title_timer.reset();
        try core.printTitle("Fractal Cube [ {d}fps ] [ Input {d}hz ]", .{
            core.frameRate(),
            core.inputRate(),
        });
    }

    return false;
}
