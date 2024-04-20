const std = @import("std");

const mach = @import("mach");
const core = mach.core;
const gpu = mach.gpu;

const zigimg = @import("zigimg");
const assets = @import("assets");

title_timer: core.Timer,
blur_pipeline: *gpu.ComputePipeline,
fullscreen_quad_pipeline: *gpu.RenderPipeline,
cube_texture: *gpu.Texture,
textures: [2]*gpu.Texture,
blur_params_buffer: *gpu.Buffer,
compute_constants: *gpu.BindGroup,
compute_bind_group_0: *gpu.BindGroup,
compute_bind_group_1: *gpu.BindGroup,
compute_bind_group_2: *gpu.BindGroup,
show_result_bind_group: *gpu.BindGroup,
img_size: gpu.Extent3D,

pub const App = @This();

// Use experimental sysgpu graphics API
pub const use_sysgpu = true;

// Constants from the blur.wgsl shader
const tile_dimension: u32 = 128;
const batch: [2]u32 = .{ 4, 4 };

// Currently hardcoded
const filter_size: u32 = 15;
const iterations: u32 = 2;
var block_dimension: u32 = tile_dimension - (filter_size - 1);
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

pub fn init(app: *App) !void {
    try core.init(.{});
    const allocator = gpa.allocator();

    const queue = core.queue;

    const blur_shader_module = core.device.createShaderModuleWGSL("blur.wgsl", @embedFile("blur.wgsl"));

    const blur_pipeline_descriptor = gpu.ComputePipeline.Descriptor{
        .compute = gpu.ProgrammableStageDescriptor{
            .module = blur_shader_module,
            .entry_point = "main",
        },
    };

    const blur_pipeline = core.device.createComputePipeline(&blur_pipeline_descriptor);
    blur_shader_module.release();

    const fullscreen_quad_vs_module = core.device.createShaderModuleWGSL(
        "fullscreen_textured_quad.wgsl",
        @embedFile("fullscreen_textured_quad.wgsl"),
    );

    const fullscreen_quad_fs_module = core.device.createShaderModuleWGSL(
        "fullscreen_textured_quad.wgsl",
        @embedFile("fullscreen_textured_quad.wgsl"),
    );

    const blend = gpu.BlendState{};
    const color_target = gpu.ColorTargetState{
        .format = core.descriptor.format,
        .blend = &blend,
        .write_mask = gpu.ColorWriteMaskFlags.all,
    };

    const fragment_state = gpu.FragmentState.init(.{
        .module = fullscreen_quad_fs_module,
        .entry_point = "frag_main",
        .targets = &.{color_target},
    });

    const fullscreen_quad_pipeline_descriptor = gpu.RenderPipeline.Descriptor{
        .fragment = &fragment_state,
        .vertex = .{
            .module = fullscreen_quad_vs_module,
            .entry_point = "vert_main",
        },
    };

    const fullscreen_quad_pipeline = core.device.createRenderPipeline(&fullscreen_quad_pipeline_descriptor);
    fullscreen_quad_vs_module.release();
    fullscreen_quad_fs_module.release();

    const sampler = core.device.createSampler(&.{
        .mag_filter = .linear,
        .min_filter = .linear,
    });

    var img = try zigimg.Image.fromMemory(allocator, assets.gotta_go_fast_png);
    defer img.deinit();

    const img_size = gpu.Extent3D{ .width = @as(u32, @intCast(img.width)), .height = @as(u32, @intCast(img.height)) };

    const cube_texture = core.device.createTexture(&.{
        .size = img_size,
        .format = .rgba8_unorm,
        .usage = .{
            .texture_binding = true,
            .copy_dst = true,
            .render_attachment = true,
        },
    });

    const data_layout = gpu.Texture.DataLayout{
        .bytes_per_row = @as(u32, @intCast(img.width * 4)),
        .rows_per_image = @as(u32, @intCast(img.height)),
    };

    switch (img.pixels) {
        .rgba32 => |pixels| queue.writeTexture(&.{ .texture = cube_texture }, &data_layout, &img_size, pixels),
        .rgb24 => |pixels| {
            const data = try rgb24ToRgba32(allocator, pixels);
            defer data.deinit(allocator);
            queue.writeTexture(&.{ .texture = cube_texture }, &data_layout, &img_size, data.rgba32);
        },
        else => @panic("unsupported image color format"),
    }

    var textures: [2]*gpu.Texture = undefined;
    for (textures, 0..) |_, i| {
        textures[i] = core.device.createTexture(&.{
            .size = img_size,
            .format = .rgba8_unorm,
            .usage = .{
                .storage_binding = true,
                .texture_binding = true,
                .copy_dst = true,
            },
        });
    }

    // the shader blurs the input texture in one direction,
    // depending on whether flip value is 0 or 1
    var flip: [2]*gpu.Buffer = undefined;
    for (flip, 0..) |_, i| {
        const buffer = core.device.createBuffer(&.{
            .usage = .{ .uniform = true },
            .size = @sizeOf(u32),
            .mapped_at_creation = .true,
        });

        const buffer_mapped = buffer.getMappedRange(u32, 0, 1);
        buffer_mapped.?[0] = @as(u32, @intCast(i));
        buffer.unmap();

        flip[i] = buffer;
    }

    const blur_params_buffer = core.device.createBuffer(&.{
        .size = 8,
        .usage = .{ .copy_dst = true, .uniform = true },
    });

    const blur_bind_group_layout0 = blur_pipeline.getBindGroupLayout(0);
    const blur_bind_group_layout1 = blur_pipeline.getBindGroupLayout(1);
    const fullscreen_bind_group_layout = fullscreen_quad_pipeline.getBindGroupLayout(0);
    const cube_texture_view = cube_texture.createView(&gpu.TextureView.Descriptor{});
    const texture0_view = textures[0].createView(&gpu.TextureView.Descriptor{});
    const texture1_view = textures[1].createView(&gpu.TextureView.Descriptor{});

    const compute_constants = core.device.createBindGroup(&gpu.BindGroup.Descriptor.init(.{
        .layout = blur_bind_group_layout0,
        .entries = &.{
            gpu.BindGroup.Entry.sampler(0, sampler),
            gpu.BindGroup.Entry.buffer(1, blur_params_buffer, 0, 8, 8),
        },
    }));

    const compute_bind_group_0 = core.device.createBindGroup(&gpu.BindGroup.Descriptor.init(.{
        .layout = blur_bind_group_layout1,
        .entries = &.{
            gpu.BindGroup.Entry.textureView(1, cube_texture_view),
            gpu.BindGroup.Entry.textureView(2, texture0_view),
            gpu.BindGroup.Entry.buffer(3, flip[0], 0, 4, 4),
        },
    }));

    const compute_bind_group_1 = core.device.createBindGroup(&gpu.BindGroup.Descriptor.init(.{
        .layout = blur_bind_group_layout1,
        .entries = &.{
            gpu.BindGroup.Entry.textureView(1, texture0_view),
            gpu.BindGroup.Entry.textureView(2, texture1_view),
            gpu.BindGroup.Entry.buffer(3, flip[1], 0, 4, 4),
        },
    }));

    const compute_bind_group_2 = core.device.createBindGroup(&gpu.BindGroup.Descriptor.init(.{
        .layout = blur_bind_group_layout1,
        .entries = &.{
            gpu.BindGroup.Entry.textureView(1, texture1_view),
            gpu.BindGroup.Entry.textureView(2, texture0_view),
            gpu.BindGroup.Entry.buffer(3, flip[0], 0, 4, 4),
        },
    }));

    const show_result_bind_group = core.device.createBindGroup(&gpu.BindGroup.Descriptor.init(.{
        .layout = fullscreen_bind_group_layout,
        .entries = &.{
            gpu.BindGroup.Entry.sampler(0, sampler),
            gpu.BindGroup.Entry.textureView(1, texture1_view),
        },
    }));

    blur_bind_group_layout0.release();
    blur_bind_group_layout1.release();
    fullscreen_bind_group_layout.release();
    sampler.release();
    flip[0].release();
    flip[1].release();
    cube_texture_view.release();
    texture0_view.release();
    texture1_view.release();

    const blur_params_buffer_data = [_]u32{ filter_size, block_dimension };
    queue.writeBuffer(blur_params_buffer, 0, &blur_params_buffer_data);

    app.title_timer = try core.Timer.start();
    app.blur_pipeline = blur_pipeline;
    app.fullscreen_quad_pipeline = fullscreen_quad_pipeline;
    app.cube_texture = cube_texture;
    app.textures = textures;
    app.blur_params_buffer = blur_params_buffer;
    app.compute_constants = compute_constants;
    app.compute_bind_group_0 = compute_bind_group_0;
    app.compute_bind_group_1 = compute_bind_group_1;
    app.compute_bind_group_2 = compute_bind_group_2;
    app.show_result_bind_group = show_result_bind_group;
    app.img_size = img_size;
}

pub fn deinit(app: *App) void {
    defer _ = gpa.deinit();
    defer core.deinit();

    app.blur_pipeline.release();
    app.fullscreen_quad_pipeline.release();
    app.cube_texture.release();
    app.textures[0].release();
    app.textures[1].release();
    app.blur_params_buffer.release();
    app.compute_constants.release();
    app.compute_bind_group_0.release();
    app.compute_bind_group_1.release();
    app.compute_bind_group_2.release();
    app.show_result_bind_group.release();
}

pub fn update(app: *App) !bool {
    var iter = core.pollEvents();
    while (iter.next()) |event| {
        if (event == .close) return true;
    }

    const back_buffer_view = core.swap_chain.getCurrentTextureView().?;
    const encoder = core.device.createCommandEncoder(null);

    const compute_pass = encoder.beginComputePass(null);
    compute_pass.setPipeline(app.blur_pipeline);
    compute_pass.setBindGroup(0, app.compute_constants, &.{});

    const width: u32 = @as(u32, @intCast(app.img_size.width));
    const height: u32 = @as(u32, @intCast(app.img_size.height));
    compute_pass.setBindGroup(1, app.compute_bind_group_0, &.{});
    compute_pass.dispatchWorkgroups(try std.math.divCeil(u32, width, block_dimension), try std.math.divCeil(u32, height, batch[1]), 1);

    compute_pass.setBindGroup(1, app.compute_bind_group_1, &.{});
    compute_pass.dispatchWorkgroups(try std.math.divCeil(u32, height, block_dimension), try std.math.divCeil(u32, width, batch[1]), 1);

    var i: u32 = 0;
    while (i < iterations - 1) : (i += 1) {
        compute_pass.setBindGroup(1, app.compute_bind_group_2, &.{});
        compute_pass.dispatchWorkgroups(try std.math.divCeil(u32, width, block_dimension), try std.math.divCeil(u32, height, batch[1]), 1);

        compute_pass.setBindGroup(1, app.compute_bind_group_1, &.{});
        compute_pass.dispatchWorkgroups(try std.math.divCeil(u32, height, block_dimension), try std.math.divCeil(u32, width, batch[1]), 1);
    }
    compute_pass.end();
    compute_pass.release();

    const color_attachment = gpu.RenderPassColorAttachment{
        .view = back_buffer_view,
        .clear_value = std.mem.zeroes(gpu.Color),
        .load_op = .clear,
        .store_op = .store,
    };

    const render_pass_descriptor = gpu.RenderPassDescriptor.init(.{
        .color_attachments = &.{color_attachment},
    });

    const render_pass = encoder.beginRenderPass(&render_pass_descriptor);
    render_pass.setPipeline(app.fullscreen_quad_pipeline);
    render_pass.setBindGroup(0, app.show_result_bind_group, &.{});
    render_pass.draw(6, 1, 0, 0);
    render_pass.end();
    render_pass.release();

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
        try core.printTitle("Image Blur [ {d}fps ] [ Input {d}hz ]", .{
            core.frameRate(),
            core.inputRate(),
        });
    }

    return false;
}

fn rgb24ToRgba32(allocator: std.mem.Allocator, in: []zigimg.color.Rgb24) !zigimg.color.PixelStorage {
    const out = try zigimg.color.PixelStorage.init(allocator, .rgba32, in.len);
    var i: usize = 0;
    while (i < in.len) : (i += 1) {
        out.rgba32[i] = zigimg.color.Rgba32{ .r = in[i].r, .g = in[i].g, .b = in[i].b, .a = 255 };
    }
    return out;
}
