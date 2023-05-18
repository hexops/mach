const std = @import("std");
const gpu = @import("mach").gpu;
const ecs = @import("mach").ecs;

const math = @import("../math.zig");
const mat = math.mat;
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

pub const name = .mach_sprite2d;

pub const components = .{
    // TODO: these cannot be doc comments /// because this is a tuple, not a struct. Maybe it should
    // be a struct with decls?

    // The sprite model transformation matrix. A sprite is measured in pixel units, starting from
    // (0, 0) at the top-left corner and extending to the size of the sprite. By default, the world
    // origin (0, 0) lives at the center of the window.
    //
    // Example: in a 500px by 500px window, a sprite located at (0, 0) with size (250, 250) will
    // cover the top-right hand corner of the window.
    .transform = Mat4x4,

    // UV coordinate transformation matrix describing top-left corner / origin of sprite, in pixels.
    .uv_transform = Mat3x3,

    // The size of the sprite, in pixels.
    .size = Vec2,
};

const Uniforms = packed struct {
    /// The view * orthographic projection matrix
    view_projection: Mat4x4,

    /// Total size of the sprite texture in pixels
    texture_size: Vec2,
};

pub fn machSprite2DInit(adapter: anytype) !void {
    var mach = adapter.mod(.mach);
    var sprite2d = adapter.mod(.mach_sprite2d);
    const core = mach.state().core;
    const device = mach.state().device;

    const uniform_buffer = device.createBuffer(&.{
        .usage = .{ .copy_dst = true, .uniform = true },
        .size = @sizeOf(Uniforms),
        .mapped_at_creation = false,
    });

    // Create a sampler with linear filtering for smooth interpolation.
    const queue = device.getQueue();
    const texture_sampler = device.createSampler(&.{
        .mag_filter = .linear,
        .min_filter = .linear,
    });

    const sprite_buffer_cap = 1024 * 128; // TODO: allow user to specify preallocation
    const sprite_transforms = device.createBuffer(&.{
        .usage = .{ .storage = true, .copy_dst = true },
        .size = @sizeOf(Mat4x4) * sprite_buffer_cap,
        .mapped_at_creation = false,
    });
    const sprite_uv_transforms = device.createBuffer(&.{
        .usage = .{ .storage = true, .copy_dst = true },
        .size = @sizeOf(Mat3x3) * sprite_buffer_cap,
        .mapped_at_creation = false,
    });
    const sprite_sizes = device.createBuffer(&.{
        .usage = .{ .storage = true, .copy_dst = true },
        .size = @sizeOf(Vec2) * sprite_buffer_cap,
        .mapped_at_creation = false,
    });

    const bind_group_layout = device.createBindGroupLayout(
        &gpu.BindGroupLayout.Descriptor.init(.{
            .entries = &.{
                gpu.BindGroupLayout.Entry.buffer(0, .{ .vertex = true }, .uniform, true, 0),
                gpu.BindGroupLayout.Entry.buffer(1, .{ .vertex = true }, .read_only_storage, true, 0),
                gpu.BindGroupLayout.Entry.buffer(2, .{ .vertex = true }, .read_only_storage, true, 0),
                gpu.BindGroupLayout.Entry.buffer(3, .{ .vertex = true }, .read_only_storage, true, 0),
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
                gpu.BindGroup.Entry.textureView(5, sprite2d.state().texture.createView(&gpu.TextureView.Descriptor{})),
            },
        }),
    );

    const shader_module = device.createShaderModuleWGSL("shader.wgsl", @embedFile("shader.wgsl"));
    const blend = gpu.BlendState{};
    const color_target = gpu.ColorTargetState{
        .format = core.descriptor().format,
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

    sprite2d.initState(.{
        .pipeline = device.createRenderPipeline(&pipeline_descriptor),
        .queue = queue,
        .bind_group = bind_group,
        .uniform_buffer = uniform_buffer,
        .sprite_transforms = sprite_transforms,
        .sprite_uv_transforms = sprite_uv_transforms,
        .sprite_sizes = sprite_sizes,
        .texture_size = Vec2{
            @intToFloat(f32, sprite2d.state().texture.getWidth()),
            @intToFloat(f32, sprite2d.state().texture.getHeight()),
        },
        .texture = sprite2d.state().texture,
    });
    shader_module.release();
}

pub fn deinit(adapter: anytype) !void {
    var sprite2d = adapter.mod(.mach_sprite2d);

    sprite2d.state().texture.release();
    sprite2d.state().pipeline.release();
    sprite2d.state().queue.release();
    sprite2d.state().bind_group.release();
    sprite2d.state().uniform_buffer.release();
    sprite2d.state().sprite_transforms.release();
    sprite2d.state().sprite_uv_transforms.release();
    sprite2d.state().sprite_sizes.release();
}

pub fn tick(adapter: anytype) !void {
    var mach = adapter.mod(.mach);
    var sprite2d = adapter.mod(.mach_sprite2d);
    const core = mach.state().core;
    const device = mach.state().device;

    // Begin our render pass
    const back_buffer_view = core.swapChain().getCurrentTextureView();
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
    const ortho = mat.ortho(
        -@intToFloat(f32, core.size().width) / 2,
        @intToFloat(f32, core.size().width) / 2,
        -@intToFloat(f32, core.size().height) / 2,
        @intToFloat(f32, core.size().height) / 2,
        -0.1,
        100000,
    );
    const uniforms = Uniforms{
        .view_projection = ortho,
        .texture_size = sprite2d.state().texture_size,
    };
    encoder.writeBuffer(sprite2d.state().uniform_buffer, 0, &[_]Uniforms{uniforms});

    // Synchronize entity data into our GPU sprite buffer
    var archetypes_iter = adapter.entities.query(.{ .all = &.{
        .{ .mach_sprite2d = &.{
            .uv_transform,
            .transform,
            .size,
        } },
    } });

    // TODO: eliminate these
    var sprite_transforms = try std.ArrayListUnmanaged(Mat4x4).initCapacity(adapter.allocator, 1000);
    defer sprite_transforms.deinit(adapter.allocator);
    var sprite_uv_transforms = try std.ArrayListUnmanaged(Mat3x3).initCapacity(adapter.allocator, 1000);
    defer sprite_uv_transforms.deinit(adapter.allocator);
    var sprite_sizes = try std.ArrayListUnmanaged(Vec2).initCapacity(adapter.allocator, 1000);
    defer sprite_sizes.deinit(adapter.allocator);
    while (archetypes_iter.next()) |archetype| {
        var transforms = archetype.slice(.mach_sprite2d, .transform);
        var uv_transforms = archetype.slice(.mach_sprite2d, .uv_transform);
        var sizes = archetype.slice(.mach_sprite2d, .size);
        for (transforms, uv_transforms, sizes) |transform, uv_transform, size| {
            try sprite_transforms.append(adapter.allocator, transform);
            try sprite_uv_transforms.append(adapter.allocator, uv_transform);
            try sprite_sizes.append(adapter.allocator, size);
        }
    }
    const total_vertices = @intCast(u32, sprite_sizes.items.len * 6);
    if (sprite_transforms.items.len > 0) {
        encoder.writeBuffer(sprite2d.state().sprite_transforms, 0, sprite_transforms.items);
        encoder.writeBuffer(sprite2d.state().sprite_uv_transforms, 0, sprite_uv_transforms.items);
        encoder.writeBuffer(sprite2d.state().sprite_sizes, 0, sprite_sizes.items);
    }

    // Draw the sprite batch
    const pass = encoder.beginRenderPass(&render_pass_info);
    pass.setPipeline(sprite2d.state().pipeline);
    // TODO: remove dynamic offsets?
    pass.setBindGroup(0, sprite2d.state().bind_group, &.{ 0, 0, 0, 0 });
    pass.draw(total_vertices, 1, 0, 0);
    pass.end();
    pass.release();

    var command = encoder.finish(null);
    encoder.release();

    sprite2d.state().queue.submit(&[_]*gpu.CommandBuffer{command});
    command.release();
    core.swapChain().present();
    back_buffer_view.release();
}
