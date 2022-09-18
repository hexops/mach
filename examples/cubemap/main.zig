const std = @import("std");
const mach = @import("mach");
const gpu = @import("gpu");
const glfw = @import("glfw");
const zm = @import("zmath");
const zigimg = @import("zigimg");
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
depth_texture: ?*gpu.Texture,
depth_texture_view: *gpu.TextureView,

pub const App = @This();

pub fn init(app: *App, core: *mach.Core) !void {
    timer = try mach.Timer.start();

    const vs_module = core.device.createShaderModuleWGSL("vert.wgsl", @embedFile("vert.wgsl"));

    const vertex_attributes = [_]gpu.VertexAttribute{
        .{ .format = .float32x4, .offset = @offsetOf(Vertex, "pos"), .shader_location = 0 },
        .{ .format = .float32x2, .offset = @offsetOf(Vertex, "uv"), .shader_location = 1 },
    };

    const vertex_buffer_layout = gpu.VertexBufferLayout.init(.{
        .array_stride = @sizeOf(Vertex),
        .step_mode = .vertex,
        .attributes = &vertex_attributes,
    });

    const fs_module = core.device.createShaderModuleWGSL("frag.wgsl", @embedFile("frag.wgsl"));

    const blend = gpu.BlendState{
        .color = .{
            .operation = .add,
            .src_factor = .src_alpha,
            .dst_factor = .one_minus_src_alpha,
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
    const fragment = gpu.FragmentState.init(.{
        .module = fs_module,
        .entry_point = "main",
        .targets = &.{color_target},
    });

    const pipeline_descriptor = gpu.RenderPipeline.Descriptor{
        .fragment = &fragment,
        // Enable depth testing so that the fragment closest to the camera
        // is rendered in front.
        .depth_stencil = &.{
            .format = .depth24_plus,
            .depth_write_enabled = true,
            .depth_compare = .less,
        },
        .vertex = gpu.VertexState.init(.{
            .module = vs_module,
            .entry_point = "main",
            .buffers = &.{vertex_buffer_layout},
        }),
        .primitive = .{
            // Since the cube has its face pointing outwards, cull_mode must be
            // set to .front or .none here since we are inside the cube looking out.
            // Ideally you would set this to .back and have a custom cube primitive
            // with the faces pointing towards the inside of the cube.
            .cull_mode = .none,
        },
    };
    const pipeline = core.device.createRenderPipeline(&pipeline_descriptor);

    const vertex_buffer = core.device.createBuffer(&.{
        .usage = .{ .vertex = true },
        .size = @sizeOf(Vertex) * vertices.len,
        .mapped_at_creation = true,
    });
    var vertex_mapped = vertex_buffer.getMappedRange(Vertex, 0, vertices.len);
    std.mem.copy(Vertex, vertex_mapped.?, vertices[0..]);
    vertex_buffer.unmap();

    const uniform_buffer = core.device.createBuffer(&.{
        .usage = .{ .copy_dst = true, .uniform = true },
        .size = @sizeOf(UniformBufferObject),
        .mapped_at_creation = false,
    });

    // Create a sampler with linear filtering for smooth interpolation.
    const sampler = core.device.createSampler(&.{
        .mag_filter = .linear,
        .min_filter = .linear,
    });

    const queue = core.device.getQueue();

    // WebGPU expects the cubemap textures in this order: (+X,-X,+Y,-Y,+Z,-Z)
    var images: [6]zigimg.Image = undefined;
    images[0] = try zigimg.Image.fromMemory(core.allocator, @embedFile("./assets/skybox/posx.png"));
    defer images[0].deinit();
    images[1] = try zigimg.Image.fromMemory(core.allocator, @embedFile("./assets/skybox/negx.png"));
    defer images[1].deinit();
    images[2] = try zigimg.Image.fromMemory(core.allocator, @embedFile("./assets/skybox/posy.png"));
    defer images[2].deinit();
    images[3] = try zigimg.Image.fromMemory(core.allocator, @embedFile("./assets/skybox/negy.png"));
    defer images[3].deinit();
    images[4] = try zigimg.Image.fromMemory(core.allocator, @embedFile("./assets/skybox/posz.png"));
    defer images[4].deinit();
    images[5] = try zigimg.Image.fromMemory(core.allocator, @embedFile("./assets/skybox/negz.png"));
    defer images[5].deinit();

    // Use the first image of the set for sizing
    const img_size = gpu.Extent3D{
        .width = @intCast(u32, images[0].width),
        .height = @intCast(u32, images[0].height),
    };

    // We set depth_or_array_layers to 6 here to indicate there are 6 images in this texture
    const tex_size = gpu.Extent3D{
        .width = @intCast(u32, images[0].width),
        .height = @intCast(u32, images[0].height),
        .depth_or_array_layers = 6,
    };

    // Same as a regular texture, but with a Z of 6 (defined in tex_size)
    const cube_texture = core.device.createTexture(&.{
        .size = tex_size,
        .format = .rgba8_unorm,
        .dimension = .dimension_2d,
        .usage = .{
            .texture_binding = true,
            .copy_dst = true,
            .render_attachment = false,
        },
    });

    const data_layout = gpu.Texture.DataLayout{
        .bytes_per_row = @intCast(u32, images[0].width * 4),
        .rows_per_image = @intCast(u32, images[0].height),
    };

    const encoder = core.device.createCommandEncoder(null);

    // We have to create a staging buffer, copy all the image data into the
    // staging buffer at the correct Z offset, encode a command to copy
    // the buffer to the texture for each image, then push it to the command
    // queue
    var staging_buff: [6]*gpu.Buffer = undefined;
    var i: u32 = 0;
    while (i < 6) : (i += 1) {
        staging_buff[i] = core.device.createBuffer(&.{
            .usage = .{ .copy_src = true, .map_write = true },
            .size = @intCast(u64, images[0].width) * @intCast(u64, images[0].height) * @sizeOf(u32),
            .mapped_at_creation = true,
        });
        switch (images[i].pixels) {
            .rgba32 => |pixels| {
                // Map a section of the staging buffer
                var staging_map = staging_buff[i].getMappedRange(u32, 0, @intCast(u64, images[i].width) * @intCast(u64, images[i].height));
                // Copy the image data into the mapped buffer
                std.mem.copy(u32, staging_map.?, @ptrCast([]u32, pixels));
                // And release the mapping
                staging_buff[i].unmap();
            },
            .rgb24 => |pixels| {
                var staging_map = staging_buff[i].getMappedRange(u32, 0, @intCast(u64, images[i].width) * @intCast(u64, images[i].height));
                // In this case, we have to convert the data to rgba32 first
                const data = try rgb24ToRgba32(core.allocator, pixels);
                defer data.deinit(core.allocator);
                std.mem.copy(u32, staging_map.?, @ptrCast([]u32, data.rgba32));
                staging_buff[i].unmap();
            },
            else => @panic("unsupported image color format"),
        }

        // These define the source and target for the buffer to texture copy command
        const copy_buff = gpu.ImageCopyBuffer{
            .layout = data_layout,
            .buffer = staging_buff[i],
        };
        const copy_tex = gpu.ImageCopyTexture{
            .texture = cube_texture,
            .origin = gpu.Origin3D{ .x = 0, .y = 0, .z = i },
        };

        // Encode the copy command, we do this for every image in the texture.
        encoder.copyBufferToTexture(&copy_buff, &copy_tex, &img_size);
    }
    // Now that the commands to copy our buffer data to the texture is filled,
    // push the encoded commands over to the queue and execute to get the
    // texture filled with the image data.
    var command = encoder.finish(null);
    encoder.release();
    queue.submit(&.{command});
    command.release();

    // The textureView in the bind group needs dimension defined as "dimension_cube".
    const bind_group = core.device.createBindGroup(
        &gpu.BindGroup.Descriptor.init(.{
            .layout = pipeline.getBindGroupLayout(0),
            .entries = &.{
                gpu.BindGroup.Entry.buffer(0, uniform_buffer, 0, @sizeOf(UniformBufferObject)),
                gpu.BindGroup.Entry.sampler(1, sampler),
                gpu.BindGroup.Entry.textureView(2, cube_texture.createView(&gpu.TextureView.Descriptor{ .dimension = .dimension_cube })),
            },
        }),
    );

    app.pipeline = pipeline;
    app.queue = queue;
    app.vertex_buffer = vertex_buffer;
    app.uniform_buffer = uniform_buffer;
    app.bind_group = bind_group;
    app.depth_texture = null;
    app.depth_texture_view = undefined;

    vs_module.release();
    fs_module.release();
}

pub fn deinit(app: *App, _: *mach.Core) void {
    app.vertex_buffer.release();
    app.uniform_buffer.release();
    app.bind_group.release();
    app.depth_texture.?.release();
    app.depth_texture_view.release();
}

pub fn update(app: *App, core: *mach.Core) !void {
    while (core.pollEvent()) |event| {
        switch (event) {
            .key_press => |ev| {
                if (ev.key == .space)
                    core.close();
            },
            else => {},
        }
    }

    const back_buffer_view = core.swap_chain.?.getCurrentTextureView();
    const color_attachment = gpu.RenderPassColorAttachment{
        .view = back_buffer_view,
        .clear_value = .{ .r = 0.5, .g = 0.5, .b = 0.5, .a = 0.0 },
        .load_op = .clear,
        .store_op = .store,
    };

    const encoder = core.device.createCommandEncoder(null);
    const render_pass_info = gpu.RenderPassDescriptor.init(.{
        .color_attachments = &.{color_attachment},
        .depth_stencil_attachment = &.{
            .view = app.depth_texture_view,
            .depth_clear_value = 1.0,
            .depth_load_op = .clear,
            .depth_store_op = .store,
        },
    });

    {
        const time = timer.read();
        const aspect = @intToFloat(f32, core.current_desc.width) / @intToFloat(f32, core.current_desc.height);
        const proj = zm.perspectiveFovRh((2 * std.math.pi) / 5.0, aspect, 0.1, 3000);
        const model = zm.mul(
            zm.scaling(1000, 1000, 1000),
            zm.rotationX(std.math.pi / 2.0 * 3.0),
        );
        const view = zm.mul(
            zm.mul(
                zm.lookAtRh(
                    zm.f32x4(0, 0, 0, 1),
                    zm.f32x4(1, 0, 0, 1),
                    zm.f32x4(0, 0, 1, 0),
                ),
                zm.rotationY(time * 0.2),
            ),
            zm.rotationX((std.math.pi / 10.0) * std.math.sin(time)),
        );

        const mvp = zm.mul(zm.mul(zm.transpose(model), view), proj);
        const ubo = UniformBufferObject{ .mat = mvp };

        encoder.writeBuffer(app.uniform_buffer, 0, &[_]UniformBufferObject{ubo});
    }

    const pass = encoder.beginRenderPass(&render_pass_info);
    pass.setPipeline(app.pipeline);
    pass.setVertexBuffer(0, app.vertex_buffer, 0, @sizeOf(Vertex) * vertices.len);
    pass.setBindGroup(0, app.bind_group, &.{});
    pass.draw(vertices.len, 1, 0, 0);
    pass.end();
    pass.release();

    var command = encoder.finish(null);
    encoder.release();

    app.queue.submit(&.{command});
    command.release();
    core.swap_chain.?.present();
    back_buffer_view.release();
}

pub fn resize(app: *App, core: *mach.Core, width: u32, height: u32) !void {
    // If window is resized, recreate depth buffer otherwise we cannot use it.
    if (app.depth_texture != null) {
        app.depth_texture.?.release();
        app.depth_texture_view.release();
    }
    app.depth_texture = core.device.createTexture(&gpu.Texture.Descriptor{
        .size = gpu.Extent3D{
            .width = width,
            .height = height,
        },
        .format = .depth24_plus,
        .usage = .{
            .render_attachment = true,
            .texture_binding = true,
        },
    });

    app.depth_texture_view = app.depth_texture.?.createView(&gpu.TextureView.Descriptor{
        .format = .depth24_plus,
        .dimension = .dimension_2d,
        .array_layer_count = 1,
        .mip_level_count = 1,
    });
}

fn rgb24ToRgba32(allocator: std.mem.Allocator, in: []zigimg.color.Rgb24) !zigimg.color.PixelStorage {
    const out = try zigimg.color.PixelStorage.init(allocator, .rgba32, in.len);
    var i: usize = 0;
    while (i < in.len) : (i += 1) {
        out.rgba32[i] = zigimg.color.Rgba32{ .r = in[i].r, .g = in[i].g, .b = in[i].b, .a = 255 };
    }
    return out;
}
