const std = @import("std");
const mach = @import("../main.zig");

const gpu = mach.gpu;
const math = mach.math;

pub const name = .mach_gfx_sprite_pipeline;
pub const Mod = mach.Mod(@This());

pub const components = .{
    .texture = .{ .type = *gpu.Texture, .description = 
    \\ Texture to use when rendering. The default shader can handle only one texture input.
    \\ Must be specified for a pipeline entity to be valid.
    },

    .texture2 = .{ .type = *gpu.Texture },
    .texture3 = .{ .type = *gpu.Texture },
    .texture4 = .{ .type = *gpu.Texture },

    .shader = .{ .type = *gpu.ShaderModule, .description = 
    \\ Shader program to use when rendering
    \\ Defaults to sprite.wgsl
    },

    .texture_sampler = .{ .type = *gpu.Sampler, .description = 
    \\ Whether to use linear (blurry) or nearest (pixelated) upscaling/downscaling.
    \\ Defaults to nearest (pixelated)
    },

    .blend_state = .{ .type = gpu.BlendState, .description = 
    \\ Alpha and color blending options
    \\ Defaults to
    \\ .{
    \\   .color = .{ .operation = .add, .src_factor = .src_alpha .dst_factor = .one_minus_src_alpha },
    \\   .alpha = .{ .operation = .add, .src_factor = .one, .dst_factor = .zero },
    \\ }
    },

    .bind_group_layout = .{ .type = *gpu.BindGroupLayout, .description = 
    \\ Override to enable passing additional data to your shader program.
    },
    .bind_group = .{ .type = *gpu.BindGroup, .description = 
    \\ Override to enable passing additional data to your shader program.
    },
    .color_target_state = .{ .type = gpu.ColorTargetState, .description = 
    \\ Override to enable custom color target state for render pipeline.
    },
    .fragment_state = .{ .type = gpu.FragmentState, .description = 
    \\ Override to enable custom fragment state for render pipeline.
    },
    .layout = .{ .type = *gpu.PipelineLayout, .description = 
    \\ Override to enable custom pipeline layout.
    },

    .num_sprites = .{ .type = u32, .description = 
    \\ Number of sprites this pipeline will render.
    \\ Read-only, updated as part of Sprite.update
    },
    .built = .{ .type = BuiltPipeline, .description = "internal" },
};

pub const events = .{
    .init = .{ .handler = fn () void },
    .deinit = .{ .handler = deinit },
    .update = .{ .handler = update },
    .pre_render = .{ .handler = preRender },
    .render = .{ .handler = render },
};

const Uniforms = extern struct {
    // WebGPU requires that the size of struct fields are multiples of 16
    // So we use align(16) and 'extern' to maintain field order

    /// The view * orthographic projection matrix
    view_projection: math.Mat4x4 align(16),

    /// Total size of the sprite texture in pixels
    texture_size: math.Vec2 align(16),
};

const sprite_buffer_cap = 1024 * 512; // TODO(sprite): allow user to specify preallocation

// TODO(sprite): eliminate these, see Sprite.updatePipeline for details on why these exist
// currently.
pub var cp_transforms: [sprite_buffer_cap]math.Mat4x4 = undefined;
pub var cp_uv_transforms: [sprite_buffer_cap]math.Mat3x3 = undefined;
pub var cp_sizes: [sprite_buffer_cap]math.Vec2 = undefined;

/// Which render pass should be used during .render
render_pass: ?*gpu.RenderPassEncoder = null,

pub const BuiltPipeline = struct {
    render: *gpu.RenderPipeline,
    texture_sampler: *gpu.Sampler,
    texture: *gpu.Texture,
    texture2: ?*gpu.Texture,
    texture3: ?*gpu.Texture,
    texture4: ?*gpu.Texture,
    bind_group: *gpu.BindGroup,
    uniforms: *gpu.Buffer,

    // Storage buffers
    transforms: *gpu.Buffer,
    uv_transforms: *gpu.Buffer,
    sizes: *gpu.Buffer,

    pub fn deinit(p: *BuiltPipeline) void {
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

fn deinit(sprite_pipeline: *Mod) void {
    var archetypes_iter = sprite_pipeline.entities.query(.{ .all = &.{
        .{ .mach_gfx_sprite_pipeline = &.{
            .built,
        } },
    } });
    while (archetypes_iter.next()) |archetype| {
        for (archetype.slice(.mach_gfx_sprite_pipeline, .built)) |*p| p.deinit();
    }
}

fn update(core: *mach.Core.Mod, sprite_pipeline: *Mod) !void {
    sprite_pipeline.init(.{});

    // Destroy all sprite render pipelines. We will rebuild them all.
    deinit(sprite_pipeline);

    var archetypes_iter = sprite_pipeline.entities.query(.{ .all = &.{
        .{ .mach_gfx_sprite_pipeline = &.{
            .texture,
        } },
    } });
    while (archetypes_iter.next()) |archetype| {
        const ids = archetype.slice(.entity, .id);
        const textures = archetype.slice(.mach_gfx_sprite_pipeline, .texture);

        for (ids, textures) |pipeline_id, texture| {
            try buildPipeline(core, sprite_pipeline, pipeline_id, texture);
        }
    }
}

fn buildPipeline(
    core: *mach.Core.Mod,
    sprite_pipeline: *Mod,
    pipeline_id: mach.EntityID,
    texture: *gpu.Texture,
) !void {
    const opt_texture2 = sprite_pipeline.get(pipeline_id, .texture2);
    const opt_texture3 = sprite_pipeline.get(pipeline_id, .texture3);
    const opt_texture4 = sprite_pipeline.get(pipeline_id, .texture4);
    const opt_shader = sprite_pipeline.get(pipeline_id, .shader);
    const opt_texture_sampler = sprite_pipeline.get(pipeline_id, .texture_sampler);
    const opt_blend_state = sprite_pipeline.get(pipeline_id, .blend_state);
    const opt_bind_group_layout = sprite_pipeline.get(pipeline_id, .bind_group_layout);
    const opt_bind_group = sprite_pipeline.get(pipeline_id, .bind_group);
    const opt_color_target_state = sprite_pipeline.get(pipeline_id, .color_target_state);
    const opt_fragment_state = sprite_pipeline.get(pipeline_id, .fragment_state);
    const opt_layout = sprite_pipeline.get(pipeline_id, .layout);

    const device = core.state().device;
    const label = @tagName(name) ++ ".buildPipeline";

    // Storage buffers
    const transforms = device.createBuffer(&.{
        .label = label ++ " transforms",
        .usage = .{ .storage = true, .copy_dst = true },
        .size = @sizeOf(math.Mat4x4) * sprite_buffer_cap,
        .mapped_at_creation = .false,
    });
    const uv_transforms = device.createBuffer(&.{
        .label = label ++ " uv_transforms",
        .usage = .{ .storage = true, .copy_dst = true },
        .size = @sizeOf(math.Mat3x3) * sprite_buffer_cap,
        .mapped_at_creation = .false,
    });
    const sizes = device.createBuffer(&.{
        .label = label ++ " sizes",
        .usage = .{ .storage = true, .copy_dst = true },
        .size = @sizeOf(math.Vec2) * sprite_buffer_cap,
        .mapped_at_creation = .false,
    });

    const texture_sampler = opt_texture_sampler orelse device.createSampler(&.{
        .label = label ++ " sampler",
        .mag_filter = .nearest,
        .min_filter = .nearest,
    });
    const uniforms = device.createBuffer(&.{
        .label = label ++ " uniforms",
        .usage = .{ .copy_dst = true, .uniform = true },
        .size = @sizeOf(Uniforms),
        .mapped_at_creation = .false,
    });
    const bind_group_layout = opt_bind_group_layout orelse device.createBindGroupLayout(
        &gpu.BindGroupLayout.Descriptor.init(.{
            .label = label,
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

    const texture_view = texture.createView(&gpu.TextureView.Descriptor{ .label = label });
    const texture2_view = if (opt_texture2) |tex| tex.createView(&gpu.TextureView.Descriptor{ .label = label }) else texture_view;
    const texture3_view = if (opt_texture3) |tex| tex.createView(&gpu.TextureView.Descriptor{ .label = label }) else texture_view;
    const texture4_view = if (opt_texture4) |tex| tex.createView(&gpu.TextureView.Descriptor{ .label = label }) else texture_view;
    defer texture_view.release();

    const bind_group = opt_bind_group orelse device.createBindGroup(
        &gpu.BindGroup.Descriptor.init(.{
            .label = label,
            .layout = bind_group_layout,
            .entries = &.{
                if (mach.use_sysgpu)
                    gpu.BindGroup.Entry.buffer(0, uniforms, 0, @sizeOf(Uniforms), @sizeOf(Uniforms))
                else
                    gpu.BindGroup.Entry.buffer(0, uniforms, 0, @sizeOf(Uniforms)),
                if (mach.use_sysgpu)
                    gpu.BindGroup.Entry.buffer(1, transforms, 0, @sizeOf(math.Mat4x4) * sprite_buffer_cap, @sizeOf(math.Mat4x4))
                else
                    gpu.BindGroup.Entry.buffer(1, transforms, 0, @sizeOf(math.Mat4x4) * sprite_buffer_cap),
                if (mach.use_sysgpu)
                    gpu.BindGroup.Entry.buffer(2, uv_transforms, 0, @sizeOf(math.Mat3x3) * sprite_buffer_cap, @sizeOf(math.Mat3x3))
                else
                    gpu.BindGroup.Entry.buffer(2, uv_transforms, 0, @sizeOf(math.Mat3x3) * sprite_buffer_cap),
                if (mach.use_sysgpu)
                    gpu.BindGroup.Entry.buffer(3, sizes, 0, @sizeOf(math.Vec2) * sprite_buffer_cap, @sizeOf(math.Vec2))
                else
                    gpu.BindGroup.Entry.buffer(3, sizes, 0, @sizeOf(math.Vec2) * sprite_buffer_cap),
                gpu.BindGroup.Entry.sampler(4, texture_sampler),
                gpu.BindGroup.Entry.textureView(5, texture_view),
                gpu.BindGroup.Entry.textureView(6, texture2_view),
                gpu.BindGroup.Entry.textureView(7, texture3_view),
                gpu.BindGroup.Entry.textureView(8, texture4_view),
            },
        }),
    );

    const blend_state = opt_blend_state orelse gpu.BlendState{
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

    const shader_module = opt_shader orelse device.createShaderModuleWGSL("sprite.wgsl", @embedFile("sprite.wgsl"));
    defer shader_module.release();

    const color_target = opt_color_target_state orelse gpu.ColorTargetState{
        .format = core.get(core.state().main_window, .framebuffer_format).?,
        .blend = &blend_state,
        .write_mask = gpu.ColorWriteMaskFlags.all,
    };
    const fragment = opt_fragment_state orelse gpu.FragmentState.init(.{
        .module = shader_module,
        .entry_point = "fragMain",
        .targets = &.{color_target},
    });

    const bind_group_layouts = [_]*gpu.BindGroupLayout{bind_group_layout};
    const pipeline_layout = opt_layout orelse device.createPipelineLayout(&gpu.PipelineLayout.Descriptor.init(.{
        .label = label,
        .bind_group_layouts = &bind_group_layouts,
    }));
    defer pipeline_layout.release();
    const render_pipeline = device.createRenderPipeline(&gpu.RenderPipeline.Descriptor{
        .label = label,
        .fragment = &fragment,
        .layout = pipeline_layout,
        .vertex = gpu.VertexState{
            .module = shader_module,
            .entry_point = "vertMain",
        },
    });

    const built = BuiltPipeline{
        .render = render_pipeline,
        .texture_sampler = texture_sampler,
        .texture = texture,
        .texture2 = opt_texture2,
        .texture3 = opt_texture3,
        .texture4 = opt_texture4,
        .bind_group = bind_group,
        .uniforms = uniforms,
        .transforms = transforms,
        .uv_transforms = uv_transforms,
        .sizes = sizes,
    };
    try sprite_pipeline.set(pipeline_id, .built, built);
    try sprite_pipeline.set(pipeline_id, .num_sprites, 0);
}

fn preRender(sprite_pipeline: *Mod, core: *mach.Core.Mod) void {
    const label = @tagName(name) ++ ".preRender";
    const encoder = core.state().device.createCommandEncoder(&.{ .label = label });
    defer encoder.release();

    var archetypes_iter = sprite_pipeline.entities.query(.{ .all = &.{
        .{ .mach_gfx_sprite_pipeline = &.{
            .built,
        } },
    } });
    while (archetypes_iter.next()) |archetype| {
        const built_pipelines = archetype.slice(.mach_gfx_sprite_pipeline, .built);
        for (built_pipelines) |built| {
            // Create the projection matrix
            // TODO(sprite): move this out of the hot codepath
            const proj = math.Mat4x4.projection2D(.{
                // TODO(Core)
                .left = -@as(f32, @floatFromInt(mach.core.size().width)) / 2,
                .right = @as(f32, @floatFromInt(mach.core.size().width)) / 2,
                .bottom = -@as(f32, @floatFromInt(mach.core.size().height)) / 2,
                .top = @as(f32, @floatFromInt(mach.core.size().height)) / 2,
                .near = -0.1,
                .far = 100000,
            });

            // Update uniform buffer
            const uniforms = Uniforms{
                .view_projection = proj,
                // TODO(sprite): dimensions of other textures, number of textures present
                .texture_size = math.vec2(
                    @as(f32, @floatFromInt(built.texture.getWidth())),
                    @as(f32, @floatFromInt(built.texture.getHeight())),
                ),
            };
            encoder.writeBuffer(built.uniforms, 0, &[_]Uniforms{uniforms});
        }
    }

    var command = encoder.finish(&.{ .label = label });
    defer command.release();
    core.state().queue.submit(&[_]*gpu.CommandBuffer{command});
}

fn render(sprite_pipeline: *Mod) !void {
    const render_pass = if (sprite_pipeline.state().render_pass) |rp| rp else std.debug.panic("sprite_pipeline.state().render_pass must be specified", .{});
    sprite_pipeline.state().render_pass = null;

    // TODO(sprite): need a way to specify order of rendering with multiple pipelines
    var archetypes_iter = sprite_pipeline.entities.query(.{ .all = &.{
        .{ .mach_gfx_sprite_pipeline = &.{
            .built,
        } },
    } });
    while (archetypes_iter.next()) |archetype| {
        const ids = archetype.slice(.entity, .id);
        const built_pipelines = archetype.slice(.mach_gfx_sprite_pipeline, .built);
        for (ids, built_pipelines) |pipeline_id, built| {
            // Draw the sprite batch
            const total_vertices = sprite_pipeline.get(pipeline_id, .num_sprites).? * 6;
            render_pass.setPipeline(built.render);
            // TODO(sprite): remove dynamic offsets?
            render_pass.setBindGroup(0, built.bind_group, &.{});
            render_pass.draw(total_vertices, 1, 0, 0);
        }
    }
}
