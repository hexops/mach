const std = @import("std");

const mach = @import("mach");
const core = mach.core;
const gpu = mach.gpu;

const zigimg = @import("zigimg");
const assets = @import("assets");

pub const mach_core_options = core.ComptimeOptions{
    .use_wgpu = false,
    .use_sysgpu = true,
};

title_timer: core.Timer,
pipeline: *gpu.RenderPipeline,
texture: *gpu.Texture,
bind_group: *gpu.BindGroup,
img_size: gpu.Extent3D,

pub const App = @This();

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

pub fn init(app: *App) !void {
    try core.init(.{});
    const allocator = gpa.allocator();

    // Load our shader that will render a fullscreen textured quad using two triangles, needed to
    // get the image on screen.
    const fullscreen_quad_vs_module = core.device.createShaderModuleWGSL(
        "fullscreen_textured_quad.wgsl",
        @embedFile("fullscreen_textured_quad.wgsl"),
    );
    defer fullscreen_quad_vs_module.release();
    const fullscreen_quad_fs_module = core.device.createShaderModuleWGSL(
        "fullscreen_textured_quad.wgsl",
        @embedFile("fullscreen_textured_quad.wgsl"),
    );
    defer fullscreen_quad_fs_module.release();

    // Create our render pipeline
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
    const pipeline_descriptor = gpu.RenderPipeline.Descriptor{
        .fragment = &fragment_state,
        .vertex = .{
            .module = fullscreen_quad_vs_module,
            .entry_point = "vert_main",
        },
    };
    const pipeline = core.device.createRenderPipeline(&pipeline_descriptor);

    // Create a texture sampler. This determines what happens when the texture doesn't match the
    // dimensions of the screen it's being displayed on. If the image needs to be magnified or
    // minified to fit, it can be linearly interpolated (i.e. 'blurred', .linear) or the nearest
    // pixel may be used (i.e. 'pixelated', .nearest)
    const sampler = core.device.createSampler(&.{
        .mag_filter = .linear,
        .min_filter = .linear,
    });
    defer sampler.release();

    // Load the pixels of the image
    var img = try zigimg.Image.fromMemory(allocator, assets.gotta_go_fast_png);
    defer img.deinit();
    const img_size = gpu.Extent3D{ .width = @as(u32, @intCast(img.width)), .height = @as(u32, @intCast(img.height)) };

    // Create a texture
    const texture = core.device.createTexture(&.{
        .size = img_size,
        .format = .rgba8_unorm,
        .usage = .{
            .texture_binding = true,
            .copy_dst = true,
            .render_attachment = true,
        },
    });

    // Upload the pixels (from the CPU) to the GPU. You could e.g. do this once per frame if you
    // wanted the image to be updated dynamically.
    const data_layout = gpu.Texture.DataLayout{
        .bytes_per_row = @as(u32, @intCast(img.width * 4)),
        .rows_per_image = @as(u32, @intCast(img.height)),
    };
    switch (img.pixels) {
        .rgba32 => |pixels| core.queue.writeTexture(&.{ .texture = texture }, &data_layout, &img_size, pixels),
        .rgb24 => |pixels| {
            const data = try rgb24ToRgba32(allocator, pixels);
            defer data.deinit(allocator);
            core.queue.writeTexture(&.{ .texture = texture }, &data_layout, &img_size, data.rgba32);
        },
        else => @panic("unsupported image color format"),
    }

    // Describe which data we will pass to our shader (GPU program)
    const bind_group_layout = pipeline.getBindGroupLayout(0);
    defer bind_group_layout.release();
    const texture_view = texture.createView(&gpu.TextureView.Descriptor{});
    defer texture_view.release();
    const bind_group = core.device.createBindGroup(&gpu.BindGroup.Descriptor.init(.{
        .layout = bind_group_layout,
        .entries = &.{
            gpu.BindGroup.Entry.sampler(0, sampler),
            gpu.BindGroup.Entry.textureView(1, texture_view),
        },
    }));

    app.* = .{
        .title_timer = try core.Timer.start(),
        .pipeline = pipeline,
        .texture = texture,
        .bind_group = bind_group,
        .img_size = img_size,
    };
}

pub fn deinit(app: *App) void {
    defer _ = gpa.deinit();
    defer core.deinit();
    app.pipeline.release();
    app.texture.release();
    app.bind_group.release();
}

pub fn update(app: *App) !bool {
    const back_buffer_view = core.swap_chain.getCurrentTextureView().?;
    defer back_buffer_view.release();

    // Poll for events (keyboard input, etc.)
    var iter = core.pollEvents();
    while (iter.next()) |event| {
        if (event == .close) return true;
    }

    const encoder = core.device.createCommandEncoder(null);
    defer encoder.release();

    // Begin our render pass by clearing the pixels that were on the screen from the previous frame.
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
    defer render_pass.release();

    // Render using our pipeline
    render_pass.setPipeline(app.pipeline);
    render_pass.setBindGroup(0, app.bind_group, &.{});
    render_pass.draw(6, 1, 0, 0); // Tell the GPU to draw 6 vertices, one object
    render_pass.end();

    // Submit all the commands to the GPU and render the frame.
    var command = encoder.finish(null);
    defer command.release();
    core.queue.submit(&[_]*gpu.CommandBuffer{command});
    core.swap_chain.present();

    // update the window title every second to have the FPS
    if (app.title_timer.read() >= 1.0) {
        app.title_timer.reset();
        try core.printTitle("Image [ {d}fps ] [ Input {d}hz ]", .{
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
