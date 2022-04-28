//! To get the effect we want, we need a texture on which to render
//! (we can't use the swapchain texture directly, but we can get the effect
//! by doing the same render pass twice, on the texture and the swapchain.
//! We also need a second texture to use on the cube, that after the render pass
//! needs to copy the other texture. We can't use the same texture since
//! it would interfere with the sincronization on the gpu during the render pass.
//! This demo currently does not work on opengl, because app.current_desc.width/height,
//! are set to 0 after app.init() and because webgpu does not implement copyTextureToTexture,
//! for opengl

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

    const bgle_buffer = gpu.BindGroupLayout.Entry.buffer(0, .{ .vertex = true }, .uniform, true, 0);
    const bgle_sampler = gpu.BindGroupLayout.Entry.sampler(1, .{ .fragment = true }, .filtering);
    const bgle_textureview = gpu.BindGroupLayout.Entry.texture(2, .{ .fragment = true }, .float, .dimension_2d, false);
    const bgl = app.device.createBindGroupLayout(
        &gpu.BindGroupLayout.Descriptor{
            .entries = &.{ bgle_buffer, bgle_sampler, bgle_textureview },
        },
    );
    defer bgl.release();

    const bind_group_layouts = [_]gpu.BindGroupLayout{bgl};
    const pipeline_layout = app.device.createPipelineLayout(&.{
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

    // The texture to put on the cube
    const cube_texture = app.device.createTexture(&gpu.Texture.Descriptor{
        .usage = .{ .texture_binding = true, .copy_dst = true },
        .size = .{ .width = app.current_desc.width, .height = app.current_desc.height },
        .format = app.swap_chain_format,
    });
    defer cube_texture.release();
    // The texture on which we render
    const cube_texture_render = app.device.createTexture(&gpu.Texture.Descriptor{
        .usage = .{ .render_attachment = true, .copy_src = true },
        .size = .{ .width = app.current_desc.width, .height = app.current_desc.height },
        .format = app.swap_chain_format,
    });
    defer cube_texture_render.release();

    const sampler = app.device.createSampler(&gpu.Sampler.Descriptor{
        .mag_filter = .linear,
        .min_filter = .linear,
    });
    defer sampler.release();

    const cube_texture_view = cube_texture.createView(&gpu.TextureView.Descriptor{
        .format = app.swap_chain_format,
        .dimension = .dimension_2d,
        .mip_level_count = 1,
        .array_layer_count = 1,
    });
    defer cube_texture_view.release();
    const cube_texture_view_render = cube_texture_render.createView(&gpu.TextureView.Descriptor{
        .format = app.swap_chain_format,
        .dimension = .dimension_2d,
        .mip_level_count = 1,
        .array_layer_count = 1,
    });
    defer cube_texture_view_render.release();

    const bind_group = app.device.createBindGroup(
        &gpu.BindGroup.Descriptor{
            .layout = bgl,
            .entries = &.{
                gpu.BindGroup.Entry.buffer(0, uniform_buffer, 0, @sizeOf(UniformBufferObject)),
                gpu.BindGroup.Entry.sampler(1, sampler),
                gpu.BindGroup.Entry.textureView(2, cube_texture_view),
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
        .depth_texture = null,
        .cube_texture = cube_texture,
        .cube_texture_view = cube_texture_view,
        .cube_texture_render = cube_texture_render,
        .cube_texture_view_render = cube_texture_view_render,
        .sampler = sampler,
        .bgl = bgl,
    };

    vs_module.release();
    fs_module.release();
    pipeline_layout.release();

    try app.run(.{ .frame = frame, .resize = resize });
    ctx.depth_texture.?.release();
}

const FrameParams = struct {
    pipeline: gpu.RenderPipeline,
    queue: gpu.Queue,
    vertex_buffer: gpu.Buffer,
    uniform_buffer: gpu.Buffer,
    bind_group: gpu.BindGroup,
    depth_texture: ?gpu.Texture,
    cube_texture: gpu.Texture,
    cube_texture_view: gpu.TextureView,
    cube_texture_render: gpu.Texture,
    cube_texture_view_render: gpu.TextureView,
    sampler: gpu.Sampler,
    bgl: gpu.BindGroupLayout,
};

fn frame(app: *App, params: *FrameParams) !void {
    const cube_view = params.cube_texture_view_render;
    const back_buffer_view = app.swap_chain.?.getCurrentTextureView();

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
        .view = params.depth_texture.?.createView(&gpu.TextureView.Descriptor{
            .format = .depth24_plus,
            .dimension = .dimension_2d,
            .array_layer_count = 1,
            .mip_level_count = 1,
        }),
        .depth_load_op = .clear,
        .depth_store_op = .store,
        .depth_clear_value = 1.0,
        .stencil_load_op = .none,
        .stencil_store_op = .none,
    };

    const encoder = app.device.createCommandEncoder(null);
    const cube_render_pass_info = gpu.RenderPassEncoder.Descriptor{
        .color_attachments = &.{cube_color_attachment},
        .depth_stencil_attachment = &depth_stencil_attachment,
    };
    const render_pass_info = gpu.RenderPassEncoder.Descriptor{
        .color_attachments = &.{color_attachment},
        .depth_stencil_attachment = &depth_stencil_attachment,
    };

    {
        const time = @intToFloat(f32, timer.read()) / @as(f32, std.time.ns_per_s);
        const model = zm.mul(zm.rotationX(time * (std.math.pi / 2.0)), zm.rotationZ(time * (std.math.pi / 2.0)));
        const view = zm.lookAtRh(
            zm.f32x4(0, -4, 0, 1),
            zm.f32x4(0, 0, 0, 1),
            zm.f32x4(0, 0, 1, 0),
        );
        const proj = zm.perspectiveFovRh(
            (std.math.pi * 2.0 / 5.0),
            @intToFloat(f32, app.current_desc.width) / @intToFloat(f32, app.current_desc.height),
            1,
            100,
        );
        const ubo = UniformBufferObject{
            .mat = zm.transpose(zm.mul(zm.mul(model, view), proj)),
        };
        encoder.writeBuffer(params.uniform_buffer, 0, UniformBufferObject, &.{ubo});
    }

    const pass = encoder.beginRenderPass(&render_pass_info);
    pass.setPipeline(params.pipeline);
    pass.setBindGroup(0, params.bind_group, &.{0});
    pass.setVertexBuffer(0, params.vertex_buffer, 0, @sizeOf(Vertex) * vertices.len);
    pass.draw(vertices.len, 1, 0, 0);
    pass.end();
    pass.release();

    encoder.copyTextureToTexture(
        &gpu.ImageCopyTexture{
            .texture = params.cube_texture_render,
        },
        &gpu.ImageCopyTexture{
            .texture = params.cube_texture,
        },
        &.{ .width = app.current_desc.width, .height = app.current_desc.height },
    );

    const cube_pass = encoder.beginRenderPass(&cube_render_pass_info);
    cube_pass.setPipeline(params.pipeline);
    cube_pass.setBindGroup(0, params.bind_group, &.{0});
    cube_pass.setVertexBuffer(0, params.vertex_buffer, 0, @sizeOf(Vertex) * vertices.len);
    cube_pass.draw(vertices.len, 1, 0, 0);
    cube_pass.end();
    cube_pass.release();

    var command = encoder.finish(null);
    encoder.release();

    params.queue.submit(&.{command});
    command.release();
    app.swap_chain.?.present();
    back_buffer_view.release();
}

fn resize(app: *App, params: *FrameParams, width: u32, height: u32) !void {
    if (params.depth_texture != null) {
        params.depth_texture.?.release();
        params.depth_texture = app.device.createTexture(&gpu.Texture.Descriptor{
            .usage = .{ .render_attachment = true },
            .size = .{ .width = width, .height = height },
            .format = .depth24_plus,
        });

        params.cube_texture.release();
        params.cube_texture = app.device.createTexture(&gpu.Texture.Descriptor{
            .usage = .{ .texture_binding = true, .copy_dst = true },
            .size = .{ .width = width, .height = height },
            .format = app.swap_chain_format,
        });
        params.cube_texture_render.release();
        params.cube_texture_render = app.device.createTexture(&gpu.Texture.Descriptor{
            .usage = .{ .render_attachment = true, .copy_src = true },
            .size = .{ .width = width, .height = height },
            .format = app.swap_chain_format,
        });

        params.cube_texture_view.release();
        params.cube_texture_view = params.cube_texture.createView(&gpu.TextureView.Descriptor{
            .format = app.swap_chain_format,
            .dimension = .dimension_2d,
            .mip_level_count = 1,
            .array_layer_count = 1,
        });
        params.cube_texture_view_render.release();
        params.cube_texture_view_render = params.cube_texture_render.createView(&gpu.TextureView.Descriptor{
            .format = app.swap_chain_format,
            .dimension = .dimension_2d,
            .mip_level_count = 1,
            .array_layer_count = 1,
        });

        params.bind_group.release();
        params.bind_group = app.device.createBindGroup(
            &gpu.BindGroup.Descriptor{
                .layout = params.bgl,
                .entries = &.{
                    gpu.BindGroup.Entry.buffer(0, params.uniform_buffer, 0, @sizeOf(UniformBufferObject)),
                    gpu.BindGroup.Entry.sampler(1, params.sampler),
                    gpu.BindGroup.Entry.textureView(2, params.cube_texture_view),
                },
            },
        );
    } else {
        // The first time resize is called, width and height are set to 0
        params.depth_texture = app.device.createTexture(&gpu.Texture.Descriptor{
            .usage = .{ .render_attachment = true },
            .size = .{ .width = app.current_desc.width, .height = app.current_desc.height },
            .format = .depth24_plus,
        });
    }
}
