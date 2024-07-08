const std = @import("std");
const mach = @import("../main.zig");

const gfx = mach.gfx;
const gpu = mach.gpu;
const math = mach.math;

pub const name = .mach_gfx_text_pipeline;
pub const Mod = mach.Mod(@This());

pub const components = .{
    .is_pipeline = .{ .type = void, .description = 
    \\ Tag to indicate an entity represents a text pipeline.
    },

    .view_projection = .{ .type = math.Mat4x4, .description = 
    \\ View*Projection matrix to use when rendering text with this pipeline. This controls both
    \\ the size of the 'virtual canvas' which is rendered onto, as well as the 'camera position'.
    \\
    \\ This should be configured before .pre_render runs.
    \\
    \\ By default, the size is configured to be equal to the window size in virtual pixels (e.g.
    \\ if the window size is 1920x1080, the virtual canvas will also be that size even if ran on a
    \\ HiDPI / Retina display where the actual framebuffer is larger than that.) The origin (0, 0)
    \\ is configured to be the center of the window:
    \\
    \\ ```
    \\ const width_px: f32 = @floatFromInt(mach.core.size().width);
    \\ const height_px: f32 = @floatFromInt(mach.core.size().height);
    \\ const projection = math.Mat4x4.projection2D(.{
    \\     .left = -width_px / 2.0,
    \\     .right = width_px / 2.0,
    \\     .bottom = -height_px / 2.0,
    \\     .top = height_px / 2.0,
    \\     .near = -0.1,
    \\     .far = 100000,
    \\ });
    \\ const view_projection = projection.mul(&Mat4x4.translate(vec3(0, 0, 0)));
    \\ try text_pipeline.set(my_text_pipeline, .view_projection, view_projection);
    \\ ```
    },

    .shader = .{ .type = *gpu.ShaderModule, .description = 
    \\ Shader program to use when rendering
    \\ Defaults to text.wgsl
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

    .num_texts = .{ .type = u32, .description = 
    \\ Number of texts this pipeline will render.
    \\ Read-only, updated as part of Text.update
    },
    .num_glyphs = .{ .type = u32, .description = 
    \\ Number of glyphs this pipeline will render.
    \\ Read-only, updated as part of Text.update
    },

    .built = .{ .type = BuiltPipeline, .description = "internal" },
};

pub const systems = .{
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

    /// Total size of the font atlas texture in pixels
    texture_size: math.Vec2 align(16),
};

const texts_buffer_cap = 1024 * 512; // TODO(text): allow user to specify preallocation

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

// TODO(text): eliminate these, see Text.updatePipeline for details on why these exist
// currently.
pub var cp_transforms: [texts_buffer_cap]math.Mat4x4 = undefined;
pub var cp_colors: [texts_buffer_cap]math.Vec4 = undefined;
pub var cp_glyphs: [texts_buffer_cap]Glyph = undefined;

/// Which render pass should be used during .render
render_pass: ?*gpu.RenderPassEncoder = null,

glyph_update_buffer: ?std.ArrayListUnmanaged(Glyph) = null,
allocator: std.mem.Allocator,

pub const Glyph = extern struct {
    /// Position of this glyph (top-left corner.)
    pos: math.Vec2,

    /// Width of the glyph in pixels.
    size: math.Vec2,

    /// Normalized position of the top-left UV coordinate
    uv_pos: math.Vec2,

    /// Which text this glyph belongs to; this is the index for transforms[i], colors[i].
    text_index: u32,
    text_padding: u32,

    /// Color of the glyph
    color: math.Vec4,
};

const GlyphKey = struct {
    index: u32,
    // Auto Hashing doesn't work for floats, so we bitcast to integer.
    size: u32,
};
const RegionMap = std.AutoArrayHashMapUnmanaged(GlyphKey, gfx.Atlas.Region);

pub const BuiltPipeline = struct {
    render: *gpu.RenderPipeline,
    texture_sampler: *gpu.Sampler,
    texture: *gpu.Texture,
    bind_group: *gpu.BindGroup,
    uniforms: *gpu.Buffer,
    texture_atlas: gfx.Atlas,
    regions: RegionMap = .{},

    // Storage buffers
    transforms: *gpu.Buffer,
    colors: *gpu.Buffer,
    glyphs: *gpu.Buffer,

    pub fn deinit(p: *BuiltPipeline, allocator: std.mem.Allocator) void {
        p.render.release();
        p.texture_sampler.release();
        p.texture.release();
        p.bind_group.release();
        p.uniforms.release();
        p.transforms.release();
        p.colors.release();
        p.glyphs.release();
        p.texture_atlas.deinit(allocator);
        p.regions.deinit(allocator);
    }
};

fn deinit(entities: *mach.Entities.Mod, text_pipeline: *Mod) !void {
    var q = try entities.query(.{
        .built_pipelines = Mod.write(.built),
    });
    while (q.next()) |v| {
        for (v.built_pipelines) |*built| {
            built.deinit(text_pipeline.state().allocator);
        }
    }
}

fn update(entities: *mach.Entities.Mod, core: *mach.Core.Mod, text_pipeline: *Mod) !void {
    text_pipeline.init(.{
        .allocator = gpa.allocator(),
    });

    // Destroy all text render pipelines. We will rebuild them all.
    try deinit(entities, text_pipeline);

    var q = try entities.query(.{
        .ids = mach.Entities.Mod.read(.id),
        .is_pipelines = Mod.read(.is_pipeline),
    });
    while (q.next()) |v| {
        for (v.ids) |pipeline_id| {
            try buildPipeline(core, text_pipeline, pipeline_id);
        }
    }
}

fn buildPipeline(
    core: *mach.Core.Mod,
    text_pipeline: *Mod,
    pipeline_id: mach.EntityID,
) !void {
    // TODO: optimize by removing the component get/set calls in this function where possible
    // and instead use .write() queries
    const opt_shader = text_pipeline.get(pipeline_id, .shader);
    const opt_texture_sampler = text_pipeline.get(pipeline_id, .texture_sampler);
    const opt_blend_state = text_pipeline.get(pipeline_id, .blend_state);
    const opt_bind_group_layout = text_pipeline.get(pipeline_id, .bind_group_layout);
    const opt_bind_group = text_pipeline.get(pipeline_id, .bind_group);
    const opt_color_target_state = text_pipeline.get(pipeline_id, .color_target_state);
    const opt_fragment_state = text_pipeline.get(pipeline_id, .fragment_state);
    const opt_layout = text_pipeline.get(pipeline_id, .layout);

    const device = core.state().device;

    // Prepare texture for the font atlas.
    // TODO(text): dynamic texture re-allocation when not large enough
    // TODO(text): better default allocation size
    const label = @tagName(name) ++ ".buildPipeline";
    const img_size = gpu.Extent3D{ .width = 1024, .height = 1024 };
    const texture = device.createTexture(&.{
        .label = label,
        .size = img_size,
        .format = .rgba8_unorm,
        .usage = .{
            .texture_binding = true,
            .copy_dst = true,
            .render_attachment = true,
        },
    });
    const texture_atlas = try gfx.Atlas.init(
        text_pipeline.state().allocator,
        img_size.width,
        .rgba,
    );

    // Storage buffers
    const transforms = device.createBuffer(&.{
        .label = label ++ " transforms",
        .usage = .{ .storage = true, .copy_dst = true },
        .size = @sizeOf(math.Mat4x4) * texts_buffer_cap,
        .mapped_at_creation = .false,
    });
    const colors = device.createBuffer(&.{
        .label = label ++ " colors",
        .usage = .{ .storage = true, .copy_dst = true },
        .size = @sizeOf(math.Vec4) * texts_buffer_cap,
        .mapped_at_creation = .false,
    });
    const glyphs = device.createBuffer(&.{
        .label = label ++ " glyphs",
        .usage = .{ .storage = true, .copy_dst = true },
        .size = @sizeOf(Glyph) * texts_buffer_cap,
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
            },
        }),
    );
    defer bind_group_layout.release();

    const texture_view = texture.createView(&gpu.TextureView.Descriptor{ .label = label });
    defer texture_view.release();

    const bind_group = opt_bind_group orelse device.createBindGroup(
        &gpu.BindGroup.Descriptor.init(.{
            .label = label,
            .layout = bind_group_layout,
            .entries = &.{
                gpu.BindGroup.Entry.buffer(0, uniforms, 0, @sizeOf(Uniforms), @sizeOf(Uniforms)),
                gpu.BindGroup.Entry.buffer(1, transforms, 0, @sizeOf(math.Mat4x4) * texts_buffer_cap, @sizeOf(math.Mat4x4)),
                gpu.BindGroup.Entry.buffer(2, colors, 0, @sizeOf(math.Vec4) * texts_buffer_cap, @sizeOf(math.Vec4)),
                gpu.BindGroup.Entry.buffer(3, glyphs, 0, @sizeOf(Glyph) * texts_buffer_cap, @sizeOf(Glyph)),
                gpu.BindGroup.Entry.sampler(4, texture_sampler),
                gpu.BindGroup.Entry.textureView(5, texture_view),
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

    const shader_module = opt_shader orelse device.createShaderModuleWGSL("text.wgsl", @embedFile("text.wgsl"));
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
        .bind_group = bind_group,
        .uniforms = uniforms,
        .transforms = transforms,
        .colors = colors,
        .glyphs = glyphs,
        .texture_atlas = texture_atlas,
    };
    try text_pipeline.set(pipeline_id, .built, built);
    try text_pipeline.set(pipeline_id, .num_texts, 0);
    try text_pipeline.set(pipeline_id, .num_glyphs, 0);
}

fn preRender(entities: *mach.Entities.Mod, core: *mach.Core.Mod, text_pipeline: *Mod) !void {
    const label = @tagName(name) ++ ".preRender";
    const encoder = core.state().device.createCommandEncoder(&.{ .label = label });
    defer encoder.release();

    var q = try entities.query(.{
        .ids = mach.Entities.Mod.read(.id),
        .built_pipelines = Mod.read(.built),
    });
    while (q.next()) |v| {
        for (v.ids, v.built_pipelines) |id, built| {
            const view_projection = text_pipeline.get(id, .view_projection) orelse blk: {
                const width_px: f32 = @floatFromInt(mach.core.size().width);
                const height_px: f32 = @floatFromInt(mach.core.size().height);
                break :blk math.Mat4x4.projection2D(.{
                    .left = -width_px / 2,
                    .right = width_px / 2,
                    .bottom = -height_px / 2,
                    .top = height_px / 2,
                    .near = -0.1,
                    .far = 100000,
                });
            };

            // Update uniform buffer
            const uniforms = Uniforms{
                .view_projection = view_projection,
                // TODO(text): dimensions of other textures, number of textures present
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

fn render(entities: *mach.Entities.Mod, text_pipeline: *Mod) !void {
    const render_pass = if (text_pipeline.state().render_pass) |rp| rp else std.debug.panic("text_pipeline.state().render_pass must be specified", .{});
    text_pipeline.state().render_pass = null;

    // TODO(text): need a way to specify order of rendering with multiple pipelines
    var q = try entities.query(.{
        .ids = mach.Entities.Mod.read(.id),
        .built_pipelines = Mod.read(.built),
    });
    while (q.next()) |v| {
        for (v.ids, v.built_pipelines) |pipeline_id, built| {
            // Draw the text batch
            const total_vertices = text_pipeline.get(pipeline_id, .num_glyphs).? * 6;
            render_pass.setPipeline(built.render);
            // TODO(text): remove dynamic offsets?
            render_pass.setBindGroup(0, built.bind_group, &.{});
            render_pass.draw(total_vertices, 1, 0, 0);
        }
    }
}
