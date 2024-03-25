const std = @import("std");
const mach = @import("../main.zig");
const core = mach.core;
const gpu = mach.gpu;
const ecs = mach.ecs;
const Engine = mach.Engine;
const gfx = mach.gfx;

const math = mach.math;
const vec2 = math.vec2;
const Vec2 = math.Vec2;
const Vec3 = math.Vec3;
const Vec4 = math.Vec4;
const vec4 = math.vec4;
const Mat3x3 = math.Mat3x3;
const Mat4x4 = math.Mat4x4;

/// Internal state
pipelines: std.AutoArrayHashMapUnmanaged(u32, Pipeline),

pub const name = .mach_gfx_text;
pub const Mod = mach.Mod(@This());

// TODO: better/proper text layout, shaping
//
// TODO: integrate freetype integration
//
// TODO: allow user to specify projection matrix (3d-space flat text etc.)

pub const components = struct {
    /// The ID of the pipeline this text belongs to. By default, zero.
    ///
    /// This determines which shader, textures, etc. are used for rendering the text.
    pub const pipeline = u8;

    /// The text model transformation matrix. Text is measured in pixel units, starting from
    /// (0, 0) at the top-left corner and extending to the size of the text. By default, the world
    /// origin (0, 0) lives at the center of the window.
    pub const transform = Mat4x4;

    /// String segments of UTF-8 encoded text to render.
    ///
    /// Expected to match the length of the style component.
    pub const text = []const []const u8;

    /// The style to apply to each segment of text.
    ///
    /// Expected to match the length of the text component.
    pub const style = []const mach.ecs.EntityID;

    /// Style component: desired font to render text with.
    pub const font_name = []const u8; // TODO: ship a default font

    /// Style component: font size in pixels
    pub const font_size = f32; // e.g. 12 * mach.gfx.px_per_pt // 12pt

    /// Style component: font weight
    pub const font_weight = u16; // e.g. mach.gfx.font_weight_normal

    /// Style component: italic text
    pub const italic = bool; // e.g. false

    /// Style component: fill color
    pub const color = Vec4; // e.g. vec4(0, 0, 0, 1.0),
};

pub const events = .{
    .{ .global = .deinit, .handler = deinit },
    .{ .global = .init, .handler = init },
    .{ .local = .init_pipeline, .handler = initPipeline },
    .{ .local = .updated, .handler = updated },
    .{ .local = .pre_render, .handler = preRender },
    .{ .local = .render, .handler = render },
};

const Uniforms = extern struct {
    // WebGPU requires that the size of struct fields are multiples of 16
    // So we use align(16) and 'extern' to maintain field order

    /// The view * orthographic projection matrix
    view_projection: Mat4x4 align(16),

    /// Total size of the font atlas texture in pixels
    texture_size: Vec2 align(16),
};

const Glyph = extern struct {
    /// Position of this glyph (top-left corner.)
    pos: Vec2,

    /// Width of the glyph in pixels.
    size: Vec2,

    /// Normalized position of the top-left UV coordinate
    uv_pos: Vec2,

    /// Which text this glyph belongs to; this is the index for transforms[i], colors[i].
    text_index: u32,
};

const GlyphKey = struct {
    index: u32,
    // Auto Hashing doesn't work for floats, so we bitcast to integer.
    size: u32,
};
const RegionMap = std.AutoArrayHashMapUnmanaged(GlyphKey, gfx.Atlas.Region);

const Pipeline = struct {
    render: *gpu.RenderPipeline,
    texture_sampler: *gpu.Sampler,
    texture: *gpu.Texture,
    texture_atlas: gfx.Atlas,
    texture2: ?*gpu.Texture,
    texture3: ?*gpu.Texture,
    texture4: ?*gpu.Texture,
    bind_group: *gpu.BindGroup,
    uniforms: *gpu.Buffer,
    regions: RegionMap = .{},

    // Storage buffers
    num_texts: u32,
    num_glyphs: u32,
    transforms: *gpu.Buffer,
    colors: *gpu.Buffer,
    glyphs: *gpu.Buffer,

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
        p.colors.reference();
        p.glyphs.reference();
    }

    pub fn deinit(p: *Pipeline, allocator: std.mem.Allocator) void {
        p.render.release();
        p.texture_sampler.release();
        p.texture.release();
        p.texture_atlas.deinit(allocator);
        if (p.texture2) |tex| tex.release();
        if (p.texture3) |tex| tex.release();
        if (p.texture4) |tex| tex.release();
        p.bind_group.release();
        p.uniforms.release();
        p.regions.deinit(allocator);
        p.transforms.release();
        p.colors.release();
        p.glyphs.release();
    }
};

pub const PipelineOptions = struct {
    pipeline: u32,

    /// Shader program to use when rendering.
    shader: ?*gpu.ShaderModule = null,

    /// Whether to use linear (blurry) or nearest (pixelated) upscaling/downscaling.
    texture_sampler: ?*gpu.Sampler = null,

    /// Textures to use when rendering. The default shader can handle one texture (the font atlas.)
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

fn deinit(text_mod: *Mod) !void {
    for (text_mod.state.pipelines.entries.items(.value)) |*pipeline| pipeline.deinit(text_mod.allocator);
    text_mod.state.pipelines.deinit(text_mod.allocator);
}

fn init(
    text_mod: *Mod,
) !void {
    text_mod.state = .{
        // TODO: struct default value initializers don't work
        .pipelines = .{},
    };
}

fn initPipeline(
    engine: *Engine.Mod,
    text_mod: *Mod,
    opt: PipelineOptions,
) !void {
    const device = engine.state.device;

    const pipeline = try text_mod.state.pipelines.getOrPut(engine.allocator, opt.pipeline);
    if (pipeline.found_existing) {
        pipeline.value_ptr.*.deinit(engine.allocator);
    }

    // Prepare texture for the font atlas.
    const img_size = gpu.Extent3D{ .width = 1024, .height = 1024 };
    const texture = device.createTexture(&.{
        .size = img_size,
        .format = .rgba8_unorm,
        .usage = .{
            .texture_binding = true,
            .copy_dst = true,
            .render_attachment = true,
        },
    });
    const texture_atlas = try gfx.Atlas.init(
        engine.allocator,
        img_size.width,
        .rgba,
    );

    // Storage buffers
    const buffer_cap = 1024 * 128; // TODO: allow user to specify preallocation
    const glyph_buffer_cap = 1024 * 512; // TODO: allow user to specify preallocation
    const transforms = device.createBuffer(&.{
        .usage = .{ .storage = true, .copy_dst = true },
        .size = @sizeOf(Mat4x4) * buffer_cap,
        .mapped_at_creation = .false,
    });
    const colors = device.createBuffer(&.{
        .usage = .{ .storage = true, .copy_dst = true },
        .size = @sizeOf(Vec4) * buffer_cap,
        .mapped_at_creation = .false,
    });
    const glyphs = device.createBuffer(&.{
        .usage = .{ .storage = true, .copy_dst = true },
        .size = @sizeOf(Glyph) * glyph_buffer_cap,
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

    const texture_view = texture.createView(&gpu.TextureView.Descriptor{});
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
                gpu.BindGroup.Entry.buffer(1, transforms, 0, @sizeOf(Mat4x4) * buffer_cap),
                gpu.BindGroup.Entry.buffer(2, colors, 0, @sizeOf(Vec4) * buffer_cap),
                gpu.BindGroup.Entry.buffer(3, glyphs, 0, @sizeOf(Glyph) * glyph_buffer_cap),
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

    const shader_module = opt.shader orelse device.createShaderModuleWGSL("text.wgsl", @embedFile("text.wgsl"));
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
    const render_pipeline = device.createRenderPipeline(&gpu.RenderPipeline.Descriptor{
        .fragment = &fragment,
        .layout = pipeline_layout,
        .vertex = gpu.VertexState{
            .module = shader_module,
            .entry_point = "vertMain",
        },
    });

    pipeline.value_ptr.* = Pipeline{
        .render = render_pipeline,
        .texture_sampler = texture_sampler,
        .texture = texture,
        .texture_atlas = texture_atlas,
        .texture2 = opt.texture2,
        .texture3 = opt.texture3,
        .texture4 = opt.texture4,
        .bind_group = bind_group,
        .uniforms = uniforms,
        .num_texts = 0,
        .num_glyphs = 0,
        .transforms = transforms,
        .colors = colors,
        .glyphs = glyphs,
    };
    pipeline.value_ptr.reference();
}

fn updated(
    engine: *Engine.Mod,
    text_mod: *Mod,
    pipeline_id: u32,
) !void {
    const pipeline = text_mod.state.pipelines.getPtr(pipeline_id).?;
    const device = engine.state.device;

    // TODO: make sure these entities only belong to the given pipeline
    // we need a better tagging mechanism
    var archetypes_iter = engine.entities.query(.{ .all = &.{
        .{ .mach_gfx_text = &.{
            .pipeline,
            .transform,
            .text,
        } },
    } });

    const encoder = device.createCommandEncoder(null);
    defer encoder.release();

    pipeline.num_texts = 0;
    pipeline.num_glyphs = 0;
    var glyphs = std.ArrayListUnmanaged(Glyph){};
    var transforms_offset: usize = 0;
    var texture_update = false;
    while (archetypes_iter.next()) |archetype| {
        const transforms = archetype.slice(.mach_gfx_text, .transform);

        // TODO: confirm the lifetime of these slices is OK for writeBuffer, how long do they need
        // to live?
        encoder.writeBuffer(pipeline.transforms, transforms_offset, transforms);
        // encoder.writeBuffer(pipeline.colors, colors_offset, colors);

        transforms_offset += transforms.len;
        // colors_offset += colors.len;
        pipeline.num_texts += @intCast(transforms.len);

        // Render texts
        // TODO: this is very expensive and shouldn't be done here, should be done only on detected
        // text change.
        const px_density = 2.0;
        const segment_lists = archetype.slice(.mach_gfx_text, .text);
        const style_lists = archetype.slice(.mach_gfx_text, .style);
        for (segment_lists, style_lists) |segments, styles| {
            var origin_x: f32 = 0.0;
            var origin_y: f32 = 0.0;

            for (segments, styles) |segment, style| {
                // Load a font
                const font_name = engine.entities.getComponent(style, .mach_gfx_text, .font_name).?;
                _ = font_name; // TODO: actually use font name
                const font_bytes = @import("font-assets").fira_sans_regular_ttf;
                var font = try gfx.Font.initBytes(font_bytes);
                defer font.deinit(engine.allocator);

                const font_size = engine.entities.getComponent(style, .mach_gfx_text, .font_size).?;
                const font_weight = engine.entities.getComponent(style, .mach_gfx_text, .font_weight);
                const italic = engine.entities.getComponent(style, .mach_gfx_text, .italic);
                const color = engine.entities.getComponent(style, .mach_gfx_text, .color);
                // TODO: actually apply these
                _ = font_weight;
                _ = italic;
                _ = color;

                // Create a text shaper
                var run = try gfx.TextRun.init();
                run.font_size_px = font_size;
                run.px_density = 2; // TODO

                defer run.deinit();

                run.addText(segment);
                try font.shape(&run);

                while (run.next()) |glyph| {
                    const codepoint = segment[glyph.cluster];
                    // TODO: use flags(?) to detect newline, or at least something more reliable?
                    if (codepoint != '\n') {
                        const region = try pipeline.regions.getOrPut(engine.allocator, .{
                            .index = glyph.glyph_index,
                            .size = @bitCast(font_size),
                        });
                        if (!region.found_existing) {
                            const rendered_glyph = try font.render(engine.allocator, glyph.glyph_index, .{
                                .font_size_px = run.font_size_px,
                            });
                            if (rendered_glyph.bitmap) |bitmap| {
                                var glyph_atlas_region = try pipeline.texture_atlas.reserve(engine.allocator, rendered_glyph.width, rendered_glyph.height);
                                pipeline.texture_atlas.set(glyph_atlas_region, @as([*]const u8, @ptrCast(bitmap.ptr))[0 .. bitmap.len * 4]);
                                texture_update = true;

                                // Exclude the 1px blank space margin when describing the region of the texture
                                // that actually represents the glyph.
                                const margin = 1;
                                glyph_atlas_region.x += margin;
                                glyph_atlas_region.y += margin;
                                glyph_atlas_region.width -= margin * 2;
                                glyph_atlas_region.height -= margin * 2;
                                region.value_ptr.* = glyph_atlas_region;
                            } else {
                                // whitespace
                                region.value_ptr.* = gfx.Atlas.Region{
                                    .width = 0,
                                    .height = 0,
                                    .x = 0,
                                    .y = 0,
                                };
                            }
                        }

                        const r = region.value_ptr.*;
                        const size = vec2(@floatFromInt(r.width), @floatFromInt(r.height));
                        try glyphs.append(engine.allocator, .{
                            .pos = vec2(
                                origin_x + glyph.offset.x(),
                                origin_y - (size.y() - glyph.offset.y()),
                            ).divScalar(px_density),
                            .size = size.divScalar(px_density),
                            .text_index = 0,
                            .uv_pos = vec2(@floatFromInt(r.x), @floatFromInt(r.y)),
                        });
                        pipeline.num_glyphs += 1;
                    }

                    if (codepoint == '\n') {
                        origin_x = 0;
                        origin_y -= font_size;
                    } else {
                        origin_x += glyph.advance.x();
                    }
                }
            }
        }
    }

    // TODO: could writeBuffer check for zero?
    if (glyphs.items.len > 0) encoder.writeBuffer(pipeline.glyphs, 0, glyphs.items);
    defer glyphs.deinit(engine.allocator);
    if (texture_update) {
        // rgba32_pixels
        // TODO: use proper texture dimensions here
        const img_size = gpu.Extent3D{ .width = 1024, .height = 1024 };
        const data_layout = gpu.Texture.DataLayout{
            .bytes_per_row = @as(u32, @intCast(img_size.width * 4)),
            .rows_per_image = @as(u32, @intCast(img_size.height)),
        };
        engine.state.queue.writeTexture(
            &.{ .texture = pipeline.texture },
            &data_layout,
            &img_size,
            pipeline.texture_atlas.data,
        );
    }

    var command = encoder.finish(null);
    defer command.release();

    engine.state.queue.submit(&[_]*gpu.CommandBuffer{command});
}

fn preRender(
    engine: *Engine.Mod,
    text_mod: *Mod,
    pipeline_id: u32,
) !void {
    const pipeline = text_mod.state.pipelines.get(pipeline_id).?;

    // Update uniform buffer
    const proj = Mat4x4.projection2D(.{
        .left = -@as(f32, @floatFromInt(core.size().width)) / 2,
        .right = @as(f32, @floatFromInt(core.size().width)) / 2,
        .bottom = -@as(f32, @floatFromInt(core.size().height)) / 2,
        .top = @as(f32, @floatFromInt(core.size().height)) / 2,
        .near = -0.1,
        .far = 100000,
    });
    const uniforms = Uniforms{
        .view_projection = proj,
        // TODO: dimensions of other textures, number of textures present
        .texture_size = vec2(
            @as(f32, @floatFromInt(pipeline.texture.getWidth())),
            @as(f32, @floatFromInt(pipeline.texture.getHeight())),
        ),
    };

    engine.state.encoder.writeBuffer(pipeline.uniforms, 0, &[_]Uniforms{uniforms});
}

fn render(
    engine: *Engine.Mod,
    text_mod: *Mod,
    pipeline_id: u32,
) !void {
    const pipeline = text_mod.state.pipelines.get(pipeline_id).?;

    // Draw the text batch
    const pass = engine.state.pass;
    const total_vertices = pipeline.num_glyphs * 6;
    pass.setPipeline(pipeline.render);
    // TODO: remove dynamic offsets?
    pass.setBindGroup(0, pipeline.bind_group, &.{});
    pass.draw(total_vertices, 1, 0, 0);
}
