// TODO:
// - handle textures better witexture atlas
// - handle adding and removing triangles and quads better

const std = @import("std");
const mach = @import("mach");
const gpu = @import("gpu");
const zm = @import("zmath");
const zigimg = @import("zigimg");
const glfw = @import("glfw");
const draw = @import("draw.zig");

pub const options = mach.Options{ .width = 640, .height = 480 };

pub const App = @This();

pipeline: gpu.RenderPipeline,
queue: gpu.Queue,
vertex_buffer: gpu.Buffer,
vertices: std.ArrayList(draw.Vertex),
update_vertex_buffer: bool,
vertex_uniform_buffer: gpu.Buffer,
update_vertex_uniform_buffer: bool,
frag_uniform_buffer: gpu.Buffer,
fragment_uniform_list: std.ArrayList(draw.FragUniform),
update_frag_uniform_buffer: bool,
bind_group: gpu.BindGroup,

pub fn init(app: *App, engine: *mach.Engine) !void {
    try engine.core.setSizeLimits(.{ .width = 20, .height = 20 }, .{ .width = null, .height = null });

    app.vertices = try std.ArrayList(draw.Vertex).initCapacity(engine.allocator, 9);
    app.fragment_uniform_list = try std.ArrayList(draw.FragUniform).initCapacity(engine.allocator, 3);

    const WINDOW_WIDTH = 640;
    const WINDOW_HEIGHT = 480;
    // const TRIANGLE_SCALE = 250;
    // try draw.equilateralTriangle(app, .{ WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2 }, TRIANGLE_SCALE, .{ .texture_index = 1 });
    // try draw.equilateralTriangle(app, .{ WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2 - TRIANGLE_SCALE }, TRIANGLE_SCALE, .{ .type = .concave, .texture_index = 1 });
    // try draw.equilateralTriangle(app, .{ WINDOW_WIDTH / 2 - TRIANGLE_SCALE, WINDOW_HEIGHT / 2 - TRIANGLE_SCALE / 2 }, TRIANGLE_SCALE, .{ .type = .convex });
    // try draw.quad(app, .{ 0, 0 }, .{ 200, 200 }, .{ .texture_index = 1 });
    try draw.circle(app, .{ WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2 }, WINDOW_HEIGHT / 2 - 10, .{ 0, 0.5, 0.75, 1.0 });

    const vs_module = engine.gpu_driver.device.createShaderModule(&.{
        .label = "my vertex shader",
        .code = .{ .wgsl = @embedFile("vert.wgsl") },
    });

    const fs_module = engine.gpu_driver.device.createShaderModule(&.{
        .label = "my fragment shader",
        .code = .{ .wgsl = @embedFile("frag.wgsl") },
    });

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
    const sbgle = gpu.BindGroupLayout.Entry.sampler(2, .{ .fragment = true }, .filtering);
    const tbgle = gpu.BindGroupLayout.Entry.texture(3, .{ .fragment = true }, .float, .dimension_2d_array, false);
    const bgl = engine.gpu_driver.device.createBindGroupLayout(
        &gpu.BindGroupLayout.Descriptor{
            .entries = &.{ vbgle, fbgle, sbgle, tbgle },
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
            .buffers = &.{draw.VERTEX_BUFFER_LAYOUT},
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
        .usage = .{ .copy_dst = true, .vertex = true },
        .size = @sizeOf(draw.Vertex) * app.vertices.items.len,
        .mapped_at_creation = false,
    });

    const vertex_uniform_buffer = engine.gpu_driver.device.createBuffer(&.{
        .usage = .{ .copy_dst = true, .uniform = true },
        .size = @sizeOf(draw.VertexUniform),
        .mapped_at_creation = false,
    });

    const frag_uniform_buffer = engine.gpu_driver.device.createBuffer(&.{
        .usage = .{ .copy_dst = true, .storage = true },
        .size = @sizeOf(draw.FragUniform) * app.fragment_uniform_list.items.len,
        .mapped_at_creation = false,
    });

    const sampler = engine.gpu_driver.device.createSampler(&.{
        .mag_filter = .linear,
        .min_filter = .linear,
    });

    const queue = engine.gpu_driver.device.getQueue();
    const img = try zigimg.Image.fromFilePath(engine.allocator, "examples/assets/gotta-go-fast.png");
    defer img.deinit();
    const img_size = gpu.Extent3D{ .width = @intCast(u32, img.width), .height = @intCast(u32, img.height), .depth_or_array_layers = 2 };
    const quad_texture = engine.gpu_driver.device.createTexture(&.{
        .size = img_size,
        .format = .rgba8_unorm,
        .usage = .{
            .texture_binding = true,
            .copy_dst = true,
            .render_attachment = true,
        },
    });
    const data_layout = gpu.Texture.DataLayout{
        .bytes_per_row = @intCast(u32, img.width * 4),
        .rows_per_image = @intCast(u32, img.height),
    };
    switch (img.pixels.?) {
        .Rgba32 => |pixels| queue.writeTexture(
            &.{ .texture = quad_texture, .origin = .{ .x = 0, .y = 0, .z = 1 } },
            pixels,
            &data_layout,
            &.{ .width = img_size.width, .height = img_size.height },
        ),
        .Rgb24 => |pixels| {
            const data = try rgb24ToRgba32(engine.allocator, pixels);
            defer data.deinit(engine.allocator);
            queue.writeTexture(
                &.{ .texture = quad_texture, .origin = .{ .x = 0, .y = 0, .z = 1 } },
                data.Rgba32,
                &data_layout,
                &.{ .width = img_size.width, .height = img_size.height },
            );
        },
        else => @panic("unsupported image color format"),
    }

    const white_texture_data = try engine.allocator.alloc(zigimg.color.Rgba32, img.width * img.height);
    defer engine.allocator.free(white_texture_data);
    std.mem.set(zigimg.color.Rgba32, white_texture_data, zigimg.color.Rgba32.initRGBA(0xff, 0xff, 0xff, 0xff));
    queue.writeTexture(
        &.{ .texture = quad_texture, .origin = .{ .x = 0, .y = 0, .z = 0 } },
        white_texture_data,
        &data_layout,
        &.{ .width = img_size.width, .height = img_size.height },
    );

    const bind_group = engine.gpu_driver.device.createBindGroup(
        &gpu.BindGroup.Descriptor{
            .layout = bgl,
            .entries = &.{
                gpu.BindGroup.Entry.buffer(0, vertex_uniform_buffer, 0, @sizeOf(draw.VertexUniform)),
                gpu.BindGroup.Entry.buffer(1, frag_uniform_buffer, 0, @sizeOf(draw.FragUniform) * app.vertices.items.len / 3),
                gpu.BindGroup.Entry.sampler(2, sampler),
                gpu.BindGroup.Entry.textureView(3, quad_texture.createView(&gpu.TextureView.Descriptor{ .dimension = .dimension_2d_array })),
            },
        },
    );

    app.pipeline = engine.gpu_driver.device.createRenderPipeline(&pipeline_descriptor);
    app.queue = queue;
    app.vertex_buffer = vertex_buffer;
    app.vertex_uniform_buffer = vertex_uniform_buffer;
    app.frag_uniform_buffer = frag_uniform_buffer;
    app.bind_group = bind_group;
    app.update_vertex_buffer = true;
    app.update_vertex_uniform_buffer = true;
    app.update_frag_uniform_buffer = true;

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
    app.vertices.deinit();
    app.fragment_uniform_list.deinit();
}

pub fn update(app: *App, engine: *mach.Engine) !bool {
    while (engine.core.pollEvent()) |event| {
        switch (event) {
            .key_press => |ev| {
                if (ev.key == .space)
                    engine.core.setShouldClose(true);
            },
            else => {},
        }
    }

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
        if (app.update_vertex_buffer) {
            encoder.writeBuffer(app.vertex_buffer, 0, draw.Vertex, app.vertices.items);
            app.update_vertex_buffer = false;
        }
        if (app.update_frag_uniform_buffer) {
            encoder.writeBuffer(app.frag_uniform_buffer, 0, draw.FragUniform, app.fragment_uniform_list.items);
            app.update_frag_uniform_buffer = false;
        }
        if (app.update_vertex_uniform_buffer) {
            encoder.writeBuffer(app.vertex_uniform_buffer, 0, draw.VertexUniform, &.{getVertexUniformBufferObject(engine)});
            app.update_vertex_uniform_buffer = false;
        }
    }

    const pass = encoder.beginRenderPass(&render_pass_info);
    pass.setPipeline(app.pipeline);
    pass.setVertexBuffer(0, app.vertex_buffer, 0, @sizeOf(draw.Vertex) * app.vertices.items.len);
    pass.setBindGroup(0, app.bind_group, &.{ 0, 0 });
    pass.draw(@truncate(u32, app.vertices.items.len), 1, 0, 0);
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

pub fn resize(app: *App, _: *mach.Engine, _: u32, _: u32) !void {
    app.update_vertex_uniform_buffer = true;
}

fn rgb24ToRgba32(allocator: std.mem.Allocator, in: []zigimg.color.Rgb24) !zigimg.color.ColorStorage {
    const out = try zigimg.color.ColorStorage.init(allocator, .Rgba32, in.len);
    var i: usize = 0;
    while (i < in.len) : (i += 1) {
        out.Rgba32[i] = zigimg.color.Rgba32{ .R = in[i].R, .G = in[i].G, .B = in[i].B, .A = 255 };
    }
    return out;
}

// Move to draw.zig
pub fn getVertexUniformBufferObject(engine: *mach.Engine) draw.VertexUniform {
    // Using a view allows us to move the camera without having to change the actual
    // global poitions of each vertex
    // const view = zm.lookAtRh(
    //     zm.f32x4(0, 0, 1, 1),
    //     zm.f32x4(0, 0, 0, 1),
    //     zm.f32x4(0, 1, 0, 0),
    // );
    const proj = zm.orthographicRh(
        @intToFloat(f32, engine.gpu_driver.current_desc.width),
        @intToFloat(f32, engine.gpu_driver.current_desc.height),
        -100,
        100,
    );

    const mvp = zm.mul(proj, zm.translation(-1, -1, 0));
    return .{
        .mat = mvp,
    };
}
