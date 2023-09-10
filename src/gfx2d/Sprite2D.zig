const std = @import("std");
const core = @import("core");
const gpu = core.gpu;
const ecs = @import("ecs");
const Engine = @import("../engine.zig").Engine;
const mach = @import("../main.zig");

const math = mach.math;
const vec2 = math.vec2;
const Vec2 = math.Vec2;
const Vec3 = math.Vec3;
const Mat3x3 = math.Mat3x3;
const Mat4x4 = math.Mat4x4;

/// Public state
texture: *gpu.Texture,

/// Internal state
pipeline: *gpu.RenderPipeline,
queue: *gpu.Queue,
bind_group: *gpu.BindGroup,
uniform_buffer: *gpu.Buffer,
sprite_transforms: *gpu.Buffer,
sprite_uv_transforms: *gpu.Buffer,
sprite_sizes: *gpu.Buffer,
texture_size: Vec2,

pub const name = .engine_sprite2d;

pub const components = struct {
    /// The sprite model transformation matrix. A sprite is measured in pixel units, starting from
    /// (0, 0) at the top-left corner and extending to the size of the sprite. By default, the world
    /// origin (0, 0) lives at the center of the window.
    ///
    /// Example: in a 500px by 500px window, a sprite located at (0, 0) with size (250, 250) will
    /// cover the top-right hand corner of the window.
    pub const transform = Mat4x4;

    /// UV coordinate transformation matrix describing top-left corner / origin of sprite, in pixels.
    pub const uv_transform = Mat3x3;

    /// The size of the sprite, in pixels.
    pub const size = Vec2;

    /// The ID of the pipeline this sprite belongs to. By default, zero.
    ///
    /// This determines which shader, textures, etc. are used for rendering the sprite.
    pub const pipeline = u8;
};

const Uniforms = extern struct {
    // WebGPU requires that the size of struct fields are multiples of 16
    // So we use align(16) and 'extern' to maintain field order

    /// The view * orthographic projection matrix
    view_projection: Mat4x4 align(16),

    /// Total size of the sprite texture in pixels
    texture_size: Vec2 align(16),
};

pub fn engineSprite2dInit(
    engine: *mach.Mod(.engine),
    sprite2d: *mach.Mod(.engine_sprite2d),
) !void {
    const device = engine.state.device;

    const uniform_buffer = device.createBuffer(&.{
        .usage = .{ .copy_dst = true, .uniform = true },
        .size = @sizeOf(Uniforms),
        .mapped_at_creation = .false,
    });

    // Create a sampler with linear filtering for smooth interpolation.
    const queue = device.getQueue();
    const texture_sampler = device.createSampler(&.{
        .mag_filter = .nearest,
        .min_filter = .nearest,
    });

    const sprite_buffer_cap = 1024 * 256; // TODO: allow user to specify preallocation
    const sprite_transforms = device.createBuffer(&.{
        .usage = .{ .storage = true, .copy_dst = true },
        .size = @sizeOf(Mat4x4) * sprite_buffer_cap,
        .mapped_at_creation = .false,
    });
    const sprite_uv_transforms = device.createBuffer(&.{
        .usage = .{ .storage = true, .copy_dst = true },
        .size = @sizeOf(Mat3x3) * sprite_buffer_cap,
        .mapped_at_creation = .false,
    });
    const sprite_sizes = device.createBuffer(&.{
        .usage = .{ .storage = true, .copy_dst = true },
        .size = @sizeOf(Vec2) * sprite_buffer_cap,
        .mapped_at_creation = .false,
    });

    const bind_group_layout = device.createBindGroupLayout(
        &gpu.BindGroupLayout.Descriptor.init(.{
            .entries = &.{
                gpu.BindGroupLayout.Entry.buffer(0, .{ .vertex = true }, .uniform, false, 0),
                gpu.BindGroupLayout.Entry.buffer(1, .{ .vertex = true }, .read_only_storage, false, 0),
                gpu.BindGroupLayout.Entry.buffer(2, .{ .vertex = true }, .read_only_storage, false, 0),
                gpu.BindGroupLayout.Entry.buffer(3, .{ .vertex = true }, .read_only_storage, false, 0),
                gpu.BindGroupLayout.Entry.sampler(4, .{ .fragment = true }, .filtering),
                gpu.BindGroupLayout.Entry.texture(5, .{ .fragment = true }, .float, .dimension_2d, false),
            },
        }),
    );
    var bind_group = device.createBindGroup(
        &gpu.BindGroup.Descriptor.init(.{
            .layout = bind_group_layout,
            .entries = &.{
                gpu.BindGroup.Entry.buffer(0, uniform_buffer, 0, @sizeOf(Uniforms)),
                gpu.BindGroup.Entry.buffer(1, sprite_transforms, 0, @sizeOf(Mat4x4) * sprite_buffer_cap),
                gpu.BindGroup.Entry.buffer(2, sprite_uv_transforms, 0, @sizeOf(Mat3x3) * sprite_buffer_cap),
                gpu.BindGroup.Entry.buffer(3, sprite_sizes, 0, @sizeOf(Vec2) * sprite_buffer_cap),
                gpu.BindGroup.Entry.sampler(4, texture_sampler),
                gpu.BindGroup.Entry.textureView(5, sprite2d.state.texture.createView(&gpu.TextureView.Descriptor{})),
            },
        }),
    );

    const shader_module = device.createShaderModuleWGSL("shader.wgsl", @embedFile("shader.wgsl"));
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
        .format = core.descriptor.format,
        .blend = &blend,
        .write_mask = gpu.ColorWriteMaskFlags.all,
    };
    const fragment = gpu.FragmentState.init(.{
        .module = shader_module,
        .entry_point = "frag_main",
        .targets = &.{color_target},
    });

    const bind_group_layouts = [_]*gpu.BindGroupLayout{bind_group_layout};
    const pipeline_layout = device.createPipelineLayout(&gpu.PipelineLayout.Descriptor.init(.{
        .bind_group_layouts = &bind_group_layouts,
    }));
    const pipeline_descriptor = gpu.RenderPipeline.Descriptor{
        .fragment = &fragment,
        .layout = pipeline_layout,
        .vertex = gpu.VertexState{
            .module = shader_module,
            .entry_point = "vertex_main",
        },
    };

    sprite2d.state = .{
        .pipeline = device.createRenderPipeline(&pipeline_descriptor),
        .queue = queue,
        .bind_group = bind_group,
        .uniform_buffer = uniform_buffer,
        .sprite_transforms = sprite_transforms,
        .sprite_uv_transforms = sprite_uv_transforms,
        .sprite_sizes = sprite_sizes,
        .texture_size = vec2(
            @as(f32, @floatFromInt(sprite2d.state.texture.getWidth())),
            @as(f32, @floatFromInt(sprite2d.state.texture.getHeight())),
        ),
        .texture = sprite2d.state.texture,
    };
    shader_module.release();
}

pub fn deinit(sprite2d: *mach.Mod(.engine_sprite2d)) !void {
    sprite2d.state.texture.release();
    sprite2d.state.pipeline.release();
    sprite2d.state.queue.release();
    sprite2d.state.bind_group.release();
    sprite2d.state.uniform_buffer.release();
    sprite2d.state.sprite_transforms.release();
    sprite2d.state.sprite_uv_transforms.release();
    sprite2d.state.sprite_sizes.release();
}

pub fn engineSprite2dUpdated(
    engine: *mach.Mod(.engine),
    sprite2d: *mach.Mod(.engine_sprite2d),
    pipeline: u32,
) !void {
    _ = pipeline;
    const device = engine.state.device;

    // TODO: make sure these entities only belong to the given pipeline
    // we need a better tagging mechanism
    var archetypes_iter = engine.entities.query(.{ .all = &.{
        .{ .engine_sprite2d = &.{
            .uv_transform,
            .transform,
            .size,
            .pipeline,
        } },
    } });

    const encoder = device.createCommandEncoder(null);
    var transforms_offset: usize = 0;
    var uv_transforms_offset: usize = 0;
    var sizes_offset: usize = 0;
    while (archetypes_iter.next()) |archetype| {
        var transforms = archetype.slice(.engine_sprite2d, .transform);
        var uv_transforms = archetype.slice(.engine_sprite2d, .uv_transform);
        var sizes = archetype.slice(.engine_sprite2d, .size);

        encoder.writeBuffer(sprite2d.state.sprite_transforms, transforms_offset, transforms);
        encoder.writeBuffer(sprite2d.state.sprite_uv_transforms, uv_transforms_offset, uv_transforms);
        encoder.writeBuffer(sprite2d.state.sprite_sizes, sizes_offset, sizes);

        transforms_offset += transforms.len;
        uv_transforms_offset += uv_transforms.len;
        sizes_offset += sizes.len;
    }

    var command = encoder.finish(null);
    encoder.release();
    sprite2d.state.queue.submit(&[_]*gpu.CommandBuffer{command});
    command.release();
}

pub fn tick(
    engine: *mach.Mod(.engine),
    sprite2d: *mach.Mod(.engine_sprite2d),
) !void {
    const device = engine.state.device;

    // Begin our render pass
    const back_buffer_view = core.swap_chain.getCurrentTextureView().?;
    const color_attachment = gpu.RenderPassColorAttachment{
        .view = back_buffer_view,
        .clear_value = gpu.Color{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 },
        .load_op = .clear,
        .store_op = .store,
    };

    const encoder = device.createCommandEncoder(null);
    const render_pass_info = gpu.RenderPassDescriptor.init(.{
        .color_attachments = &.{color_attachment},
    });

    // Update uniform buffer
    const ortho = Mat4x4.ortho(
        -@as(f32, @floatFromInt(core.size().width)) / 2,
        @as(f32, @floatFromInt(core.size().width)) / 2,
        -@as(f32, @floatFromInt(core.size().height)) / 2,
        @as(f32, @floatFromInt(core.size().height)) / 2,
        -0.1,
        100000,
    );
    const uniforms = Uniforms{
        .view_projection = ortho,
        .texture_size = sprite2d.state.texture_size,
    };
    encoder.writeBuffer(sprite2d.state.uniform_buffer, 0, &[_]Uniforms{uniforms});

    // Calculate number of vertices
    // TODO: eliminate this
    var total_vertices: u32 = 0;
    var archetypes_iter = engine.entities.query(.{ .all = &.{
        .{ .engine_sprite2d = &.{
            .pipeline,
        } },
    } });
    while (archetypes_iter.next()) |archetype| {
        total_vertices += 6;
        var pipelines = archetype.slice(.engine_sprite2d, .pipeline);
        for (pipelines) |_| total_vertices += 6;
    }

    // Draw the sprite batch
    const pass = encoder.beginRenderPass(&render_pass_info);
    pass.setPipeline(sprite2d.state.pipeline);
    // TODO: remove dynamic offsets?
    pass.setBindGroup(0, sprite2d.state.bind_group, &.{});
    pass.draw(total_vertices, 1, 0, 0);
    pass.end();
    pass.release();

    var command = encoder.finish(null);
    encoder.release();

    sprite2d.state.queue.submit(&[_]*gpu.CommandBuffer{command});
    command.release();
    core.swap_chain.present();
    back_buffer_view.release();
}
