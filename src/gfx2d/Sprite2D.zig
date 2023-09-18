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

/// Internal state
pipelines: std.AutoArrayHashMapUnmanaged(u32, Pipeline),

pub const name = .engine_sprite2d;

pub const components = struct {
    /// The ID of the pipeline this sprite belongs to. By default, zero.
    ///
    /// This determines which shader, textures, etc. are used for rendering the sprite.
    pub const pipeline = u8;

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
};

const Uniforms = extern struct {
    // WebGPU requires that the size of struct fields are multiples of 16
    // So we use align(16) and 'extern' to maintain field order

    /// The view * orthographic projection matrix
    view_projection: Mat4x4 align(16),

    /// Total size of the sprite texture in pixels
    texture_size: Vec2 align(16),
};

const Pipeline = struct {
    render: *gpu.RenderPipeline,
    texture_sampler: *gpu.Sampler,
    texture: *gpu.Texture,
    texture2: ?*gpu.Texture,
    texture3: ?*gpu.Texture,
    texture4: ?*gpu.Texture,
    bind_group: *gpu.BindGroup,
    uniforms: *gpu.Buffer,

    // Storage buffers
    num_sprites: u32,
    transforms: *gpu.Buffer,
    uv_transforms: *gpu.Buffer,
    sizes: *gpu.Buffer,

    pub fn reference(p: *Pipeline) void {
        p.render.reference();
        p.texture_sampler.reference();
        p.texture.reference();
        if (p.texture2) |tex| tex.reference();
        if (p.texture3) |tex| tex.reference();
        if (p.texture4) |tex| tex.reference();
        p.bind_group.reference();
        p.uniforms.reference();
        p.transforms.reference();
        p.uv_transforms.reference();
        p.sizes.reference();
    }

    pub fn deinit(p: *Pipeline) void {
        p.render.release();
        p.texture_sampler.release();
        p.texture.release();
        if (p.texture2) |tex| tex.release();
        if (p.texture3) |tex| tex.release();
        if (p.texture4) |tex| tex.release();
        p.bind_group.release();
        p.uniforms.release();
        p.transforms.release();
        p.uv_transforms.release();
        p.sizes.release();
    }
};

pub const PipelineOptions = struct {
    pipeline: u32,

    /// Shader program to use when rendering.
    shader: ?*gpu.ShaderModule = null,

    /// Whether to use linear (blurry) or nearest (pixelated) upscaling/downscaling.
    texture_sampler: ?*gpu.Sampler = null,

    /// Textures to use when rendering. The default shader can handle one texture.
    texture: *gpu.Texture,
    texture2: ?*gpu.Texture = null,
    texture3: ?*gpu.Texture = null,
    texture4: ?*gpu.Texture = null,

    /// Alpha and color blending options.
    blend_state: ?gpu.BlendState = null,

    /// Pipeline overrides, these can be used to e.g. pass additional things to your shader program.
    bind_group_layout: ?*gpu.BindGroupLayout = null,
    bind_group: ?*gpu.BindGroup = null,
    color_target_state: ?gpu.ColorTargetState = null,
    fragment_state: ?gpu.FragmentState = null,
    pipeline_layout: ?*gpu.PipelineLayout = null,
};

pub fn engineSprite2dInit(
    sprite2d: *mach.Mod(.engine_sprite2d),
) !void {
    sprite2d.state = .{
        // TODO: struct default value initializers don't work
        .pipelines = .{},
    };
}

pub fn engineSprite2dInitPipeline(
    engine: *mach.Mod(.engine),
    sprite2d: *mach.Mod(.engine_sprite2d),
    opt: PipelineOptions,
) !void {
    const device = engine.state.device;

    const pipeline = try sprite2d.state.pipelines.getOrPut(engine.allocator, opt.pipeline);
    if (pipeline.found_existing) {
        pipeline.value_ptr.*.deinit();
    }

    // Storage buffers
    const sprite_buffer_cap = 1024 * 512; // TODO: allow user to specify preallocation
    const transforms = device.createBuffer(&.{
        .usage = .{ .storage = true, .copy_dst = true },
        .size = @sizeOf(Mat4x4) * sprite_buffer_cap,
        .mapped_at_creation = .false,
    });
    const uv_transforms = device.createBuffer(&.{
        .usage = .{ .storage = true, .copy_dst = true },
        .size = @sizeOf(Mat3x3) * sprite_buffer_cap,
        .mapped_at_creation = .false,
    });
    const sizes = device.createBuffer(&.{
        .usage = .{ .storage = true, .copy_dst = true },
        .size = @sizeOf(Vec2) * sprite_buffer_cap,
        .mapped_at_creation = .false,
    });

    const texture_sampler = opt.texture_sampler orelse device.createSampler(&.{
        .mag_filter = .nearest,
        .min_filter = .nearest,
    });
    const uniforms = device.createBuffer(&.{
        .usage = .{ .copy_dst = true, .uniform = true },
        .size = @sizeOf(Uniforms),
        .mapped_at_creation = .false,
    });
    const bind_group_layout = opt.bind_group_layout orelse device.createBindGroupLayout(
        &gpu.BindGroupLayout.Descriptor.init(.{
            .entries = &.{
                gpu.BindGroupLayout.Entry.buffer(0, .{ .vertex = true }, .uniform, false, 0),
                gpu.BindGroupLayout.Entry.buffer(1, .{ .vertex = true }, .read_only_storage, false, 0),
                gpu.BindGroupLayout.Entry.buffer(2, .{ .vertex = true }, .read_only_storage, false, 0),
                gpu.BindGroupLayout.Entry.buffer(3, .{ .vertex = true }, .read_only_storage, false, 0),
                gpu.BindGroupLayout.Entry.sampler(4, .{ .fragment = true }, .filtering),
                gpu.BindGroupLayout.Entry.texture(5, .{ .fragment = true }, .float, .dimension_2d, false),
                gpu.BindGroupLayout.Entry.texture(6, .{ .fragment = true }, .float, .dimension_2d, false),
                gpu.BindGroupLayout.Entry.texture(7, .{ .fragment = true }, .float, .dimension_2d, false),
                gpu.BindGroupLayout.Entry.texture(8, .{ .fragment = true }, .float, .dimension_2d, false),
            },
        }),
    );
    defer bind_group_layout.release();

    const texture_view = opt.texture.createView(&gpu.TextureView.Descriptor{});
    const texture2_view = if (opt.texture2) |tex| tex.createView(&gpu.TextureView.Descriptor{}) else texture_view;
    const texture3_view = if (opt.texture3) |tex| tex.createView(&gpu.TextureView.Descriptor{}) else texture_view;
    const texture4_view = if (opt.texture4) |tex| tex.createView(&gpu.TextureView.Descriptor{}) else texture_view;
    defer texture_view.release();
    defer texture2_view.release();
    defer texture3_view.release();
    defer texture4_view.release();

    const bind_group = opt.bind_group orelse device.createBindGroup(
        &gpu.BindGroup.Descriptor.init(.{
            .layout = bind_group_layout,
            .entries = &.{
                gpu.BindGroup.Entry.buffer(0, uniforms, 0, @sizeOf(Uniforms)),
                gpu.BindGroup.Entry.buffer(1, transforms, 0, @sizeOf(Mat4x4) * sprite_buffer_cap),
                gpu.BindGroup.Entry.buffer(2, uv_transforms, 0, @sizeOf(Mat3x3) * sprite_buffer_cap),
                gpu.BindGroup.Entry.buffer(3, sizes, 0, @sizeOf(Vec2) * sprite_buffer_cap),
                gpu.BindGroup.Entry.sampler(4, texture_sampler),
                gpu.BindGroup.Entry.textureView(5, texture_view),
                gpu.BindGroup.Entry.textureView(6, texture2_view),
                gpu.BindGroup.Entry.textureView(7, texture3_view),
                gpu.BindGroup.Entry.textureView(8, texture4_view),
            },
        }),
    );

    const blend_state = opt.blend_state orelse gpu.BlendState{
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

    const shader_module = opt.shader orelse device.createShaderModuleWGSL("sprite2d.wgsl", @embedFile("sprite2d.wgsl"));
    defer shader_module.release();

    const color_target = opt.color_target_state orelse gpu.ColorTargetState{
        .format = core.descriptor.format,
        .blend = &blend_state,
        .write_mask = gpu.ColorWriteMaskFlags.all,
    };
    const fragment = opt.fragment_state orelse gpu.FragmentState.init(.{
        .module = shader_module,
        .entry_point = "fragMain",
        .targets = &.{color_target},
    });

    const bind_group_layouts = [_]*gpu.BindGroupLayout{bind_group_layout};
    const pipeline_layout = opt.pipeline_layout orelse device.createPipelineLayout(&gpu.PipelineLayout.Descriptor.init(.{
        .bind_group_layouts = &bind_group_layouts,
    }));
    defer pipeline_layout.release();
    const render = device.createRenderPipeline(&gpu.RenderPipeline.Descriptor{
        .fragment = &fragment,
        .layout = pipeline_layout,
        .vertex = gpu.VertexState{
            .module = shader_module,
            .entry_point = "vertMain",
        },
    });

    pipeline.value_ptr.* = Pipeline{
        .render = render,
        .texture_sampler = texture_sampler,
        .texture = opt.texture,
        .texture2 = opt.texture2,
        .texture3 = opt.texture3,
        .texture4 = opt.texture4,
        .bind_group = bind_group,
        .uniforms = uniforms,
        .num_sprites = 0,
        .transforms = transforms,
        .uv_transforms = uv_transforms,
        .sizes = sizes,
    };
    pipeline.value_ptr.reference();
}

pub fn deinit(sprite2d: *mach.Mod(.engine_sprite2d)) !void {
    for (sprite2d.state.pipelines.entries.items(.value)) |*pipeline| pipeline.deinit();
    sprite2d.state.pipelines.deinit(sprite2d.allocator);
}

pub fn engineSprite2dUpdated(
    engine: *mach.Mod(.engine),
    sprite2d: *mach.Mod(.engine_sprite2d),
    pipeline_id: u32,
) !void {
    const pipeline = sprite2d.state.pipelines.getPtr(pipeline_id).?;
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
    defer encoder.release();

    pipeline.num_sprites = 0;
    var transforms_offset: usize = 0;
    var uv_transforms_offset: usize = 0;
    var sizes_offset: usize = 0;
    while (archetypes_iter.next()) |archetype| {
        var transforms = archetype.slice(.engine_sprite2d, .transform);
        var uv_transforms = archetype.slice(.engine_sprite2d, .uv_transform);
        var sizes = archetype.slice(.engine_sprite2d, .size);

        // TODO: confirm the lifetime of these slices is OK for writeBuffer, how long do they need
        // to live?
        encoder.writeBuffer(pipeline.transforms, transforms_offset, transforms);
        encoder.writeBuffer(pipeline.uv_transforms, uv_transforms_offset, uv_transforms);
        encoder.writeBuffer(pipeline.sizes, sizes_offset, sizes);

        transforms_offset += transforms.len;
        uv_transforms_offset += uv_transforms.len;
        sizes_offset += sizes.len;
        pipeline.num_sprites += @intCast(transforms.len);
    }

    var command = encoder.finish(null);
    defer command.release();

    engine.state.queue.submit(&[_]*gpu.CommandBuffer{command});
}

pub fn engineSprite2dPreRender(
    engine: *mach.Mod(.engine),
    sprite2d: *mach.Mod(.engine_sprite2d),
    pipeline_id: u32,
) !void {
    const pipeline = sprite2d.state.pipelines.get(pipeline_id).?;

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
        // TODO: dimensions of other textures, number of textures present
        .texture_size = vec2(
            @as(f32, @floatFromInt(pipeline.texture.getWidth())),
            @as(f32, @floatFromInt(pipeline.texture.getHeight())),
        ),
    };

    engine.state.encoder.writeBuffer(pipeline.uniforms, 0, &[_]Uniforms{uniforms});
}

pub fn engineSprite2dRender(
    engine: *mach.Mod(.engine),
    sprite2d: *mach.Mod(.engine_sprite2d),
    pipeline_id: u32,
) !void {
    const pipeline = sprite2d.state.pipelines.get(pipeline_id).?;

    // Draw the sprite batch
    const pass = engine.state.pass;
    const total_vertices = pipeline.num_sprites * 6;
    pass.setPipeline(pipeline.render);
    // TODO: remove dynamic offsets?
    pass.setBindGroup(0, pipeline.bind_group, &.{});
    pass.draw(total_vertices, 1, 0, 0);
}
