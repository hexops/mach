const std = @import("std");
const mach = @import("../main.zig");
const gpu = mach.gpu;
const gfx = mach.gfx;

const math = mach.math;
const vec2 = math.vec2;
const vec4 = math.vec4;
const Vec4 = math.Vec4;
const Mat4x4 = math.Mat4x4;

const Text = @This();

pub const mach_module = .mach_gfx_text;

pub const mach_systems = .{ .tick, .init };

// TODO(text): currently not handling deinit properly

const buffer_cap = 1024 * 512; // TODO(text): allow user to specify preallocation

var cp_transforms: [buffer_cap]math.Mat4x4 = undefined;
var cp_colors: [buffer_cap]math.Vec4 = undefined;
var cp_glyphs: [buffer_cap]Glyph = undefined;

const Uniforms = extern struct {
    /// The view * orthographic projection matrix
    view_projection: math.Mat4x4 align(16),

    /// Total size of the font atlas texture in pixels
    texture_size: math.Vec2 align(16),
};

const BuiltPipeline = struct {
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

    fn deinit(p: *BuiltPipeline, allocator: std.mem.Allocator) void {
        p.render.release();
        p.texture_sampler.release();
        p.texture.release();
        p.bind_group.release();
        p.uniforms.release();
        p.texture_atlas.deinit(allocator);
        p.regions.deinit(allocator);
        p.transforms.release();
        p.colors.release();
        p.glyphs.release();
    }
};

const BuiltText = struct {
    glyphs: std.ArrayListUnmanaged(Glyph),
};

const Glyph = extern struct {
    /// Position of this glyph (top-left corner.)
    pos: math.Vec2,

    /// Width of the glyph in pixels.
    size: math.Vec2,

    /// Normalized position of the top-left UV coordinate
    uv_pos: math.Vec2,

    /// Which text this glyph belongs to; this is the index for transforms[i], colors[i].
    text_index: u32,

    // TODO(d3d12): this is a hack, having 7 floats before the color vec causes an error
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

pub const Segment = struct {
    /// UTF-8 encoded string of text to render
    text: []const u8,

    /// Style to apply when rendering the text
    style: mach.ObjectID,
};

allocator: std.mem.Allocator,
glyph_update_buffer: ?std.ArrayListUnmanaged(Glyph) = null,
font_once: ?gfx.Font = null,

styles: mach.Objects(.{ .track_fields = true }, struct {
    // TODO(text): not currently implemented
    // TODO(text): ship a default font
    /// Desired font to render text with
    font_name: []const u8 = "",

    /// Font size in pixels
    /// e.g. 12 * mach.gfx.px_per_pt for 12pt font size
    font_size: f32 = 12 * gfx.px_per_pt,

    // TODO(text): not currently implemented
    /// Font weight
    font_weight: u16 = gfx.font_weight_normal,

    // TODO(text): not currently implemented
    /// Fill color of text
    color: math.Vec4 = vec4(0, 0, 0, 1.0), // black

    // TODO(text): not currently implemented
    /// Italic style
    italic: bool = false,

    // TODO(text): allow user to specify projection matrix (3d-space flat text etc.)
}),

objects: mach.Objects(.{ .track_fields = true }, struct {
    /// The text model transformation matrix. Text is measured in pixel units, starting from
    /// (0, 0) at the top-left corner and extending to the size of the text. By default, the world
    /// origin (0, 0) lives at the center of the window.
    transform: Mat4x4,

    /// The segments of text
    segments: []const Segment,

    /// Internal text object state.
    built: ?BuiltText = null,
}),

/// A text pipeline renders all text objects that are parented to it.
pipelines: mach.Objects(.{ .track_fields = true }, struct {
    /// Which window (device/queue) to use. If not set, this pipeline will not be rendered.
    window: ?mach.ObjectID = null,

    /// Which render pass should be used during rendering. If not set, this pipeline will not be
    /// rendered.
    render_pass: ?*gpu.RenderPassEncoder = null,

    /// View*Projection matrix to use when rendering with this pipeline. This controls both
    /// the size of the 'virtual canvas' which is rendered onto, as well as the 'camera position'.
    ///
    /// By default, the size is configured to be equal to the window size in virtual pixels (e.g.
    /// if the window size is 1920x1080, the virtual canvas will also be that size even if ran on a
    /// HiDPI / Retina display where the actual framebuffer is larger than that.) The origin (0, 0)
    /// is configured to be the center of the window:
    ///
    /// ```
    /// const width_px: f32 = @floatFromInt(window.width);
    /// const height_px: f32 = @floatFromInt(window.height);
    /// const projection = math.Mat4x4.projection2D(.{
    ///     .left = -width_px / 2.0,
    ///     .right = width_px / 2.0,
    ///     .bottom = -height_px / 2.0,
    ///     .top = height_px / 2.0,
    ///     .near = -0.1,
    ///     .far = 100000,
    /// });
    /// const view_projection = projection.mul(&Mat4x4.translate(vec3(0, 0, 0)));
    /// ```
    view_projection: ?Mat4x4 = null,

    /// Shader program to use when rendering
    ///
    /// If null, defaults to text.wgsl
    shader: ?*gpu.ShaderModule = null,

    /// Whether to use linear (blurry) or nearest (pixelated) upscaling/downscaling.
    ///
    /// If null, defaults to nearest (pixelated)
    texture_sampler: ?*gpu.Sampler = null,

    /// Alpha and color blending options
    ///
    /// If null, defaults to
    /// .{
    ///   .color = .{ .operation = .add, .src_factor = .src_alpha .dst_factor = .one_minus_src_alpha },
    ///   .alpha = .{ .operation = .add, .src_factor = .one, .dst_factor = .zero },
    /// }
    blend_state: ?gpu.BlendState = null,

    /// Override to enable passing additional data to your shader program.
    bind_group_layout: ?*gpu.BindGroupLayout = null,

    /// Override to enable passing additional data to your shader program.
    bind_group: ?*gpu.BindGroup = null,

    /// Override to enable custom color target state for render pipeline.
    color_target_state: ?gpu.ColorTargetState = null,

    /// Override to enable custom fragment state for render pipeline.
    fragment_state: ?gpu.FragmentState = null,

    /// Override to enable custom pipeline layout.
    layout: ?*gpu.PipelineLayout = null,

    /// Number of text objects this pipeline will render.
    /// Read-only, updated as part of Text.tick
    num_texts: u32 = 0,

    /// Number of text segments this pipeline will render.
    /// Read-only, updated as part of Text.tick
    num_segments: u32 = 0,

    /// Total number of glyphs this pipeline will render.
    /// Read-only, updated as part of Text.tick
    num_glyphs: u32 = 0,

    /// Internal pipeline state.
    built: ?BuiltPipeline = null,
}),

pub fn init(text: *Text) !void {
    // TODO(allocator): find a better way to get an allocator here
    const allocator = std.heap.c_allocator;

    text.* = .{
        .allocator = allocator,
        .styles = text.styles,
        .objects = text.objects,
        .pipelines = text.pipelines,
    };
}

pub fn tick(text: *Text, core: *mach.Core) !void {
    var pipelines = text.pipelines.slice();
    while (pipelines.next()) |pipeline_id| {
        // Is this pipeline usable for rendering? If not, no need to process it.
        const pipeline = text.pipelines.getValue(pipeline_id);
        if (pipeline.window == null or pipeline.render_pass == null) continue;

        // Changing these fields shouldn't trigger a pipeline rebuild, so clear their update values:
        _ = text.pipelines.updated(pipeline_id, .window);
        _ = text.pipelines.updated(pipeline_id, .render_pass);
        _ = text.pipelines.updated(pipeline_id, .view_projection);

        // If any other fields of the pipeline have been updated, a pipeline rebuild is required.
        if (text.pipelines.anyUpdated(pipeline_id)) try rebuildPipeline(core, text, pipeline_id);

        // Find text objects parented to this pipeline.
        var pipeline_children = try text.pipelines.getChildren(pipeline_id);
        defer pipeline_children.deinit();

        // If any text objects were updated, we update the pipeline's storage buffers to have the new
        // information.
        const any_updated = blk: {
            for (pipeline_children.items) |text_id| {
                if (!text.objects.is(text_id)) continue;
                if (text.objects.peekAnyUpdated(text_id)) break :blk true;
            }
            break :blk false;
        };
        if (any_updated) try updatePipelineBuffers(text, core, pipeline_id, pipeline_children.items);

        // // Do we actually have any sprites to render?
        // pipeline = text.pipelines.getValue(pipeline_id);
        // if (pipeline.num_sprites == 0) continue;

        // TODO(text): need a way to specify order of rendering with multiple pipelines
        renderPipeline(text, core, pipeline_id);
    }
}

fn rebuildPipeline(
    core: *mach.Core,
    text: *Text,
    pipeline_id: mach.ObjectID,
) !void {
    // Destroy the current pipeline, if built.
    var pipeline = text.pipelines.getValue(pipeline_id);
    defer text.pipelines.setValueRaw(pipeline_id, pipeline);
    if (pipeline.built) |*built| built.deinit(text.allocator);

    // Reference any user-provided objects.
    if (pipeline.shader) |v| v.reference();
    if (pipeline.texture_sampler) |v| v.reference();
    if (pipeline.bind_group_layout) |v| v.reference();
    if (pipeline.bind_group) |v| v.reference();
    if (pipeline.layout) |v| v.reference();

    const window = core.windows.getValue(pipeline.window.?);
    const device = window.device;

    const label = @tagName(mach_module) ++ ".rebuildPipeline";

    // Prepare texture for the font atlas.
    // TODO(text): dynamic texture re-allocation when not large enough
    // TODO(text): better default allocation size
    const img_size = gpu.Extent3D{ .width = 1024, .height = 1024 };
    const texture = device.createTexture(&.{
        .label = label,
        .size = img_size,
        .format = .rgba8_unorm,
        .usage = .{
            .texture_binding = true,
            .copy_dst = true,
        },
    });
    const texture_atlas = try gfx.Atlas.init(
        text.allocator,
        img_size.width,
        .rgba,
    );

    // Storage buffers
    const transforms = device.createBuffer(&.{
        .label = label ++ " transforms",
        .usage = .{ .storage = true, .copy_dst = true },
        .size = @sizeOf(math.Mat4x4) * buffer_cap,
        .mapped_at_creation = .false,
    });
    const colors = device.createBuffer(&.{
        .label = label ++ " colors",
        .usage = .{ .storage = true, .copy_dst = true },
        .size = @sizeOf(math.Vec4) * buffer_cap,
        .mapped_at_creation = .false,
    });
    const glyphs = device.createBuffer(&.{
        .label = label ++ " glyphs",
        .usage = .{ .storage = true, .copy_dst = true },
        .size = @sizeOf(Glyph) * buffer_cap,
        .mapped_at_creation = .false,
    });

    const texture_sampler = pipeline.texture_sampler orelse device.createSampler(&.{
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
    const bind_group_layout = pipeline.bind_group_layout orelse device.createBindGroupLayout(
        &gpu.BindGroupLayout.Descriptor.init(.{
            .label = label,
            .entries = &.{
                gpu.BindGroupLayout.Entry.initBuffer(0, .{ .vertex = true }, .uniform, false, 0),
                gpu.BindGroupLayout.Entry.initBuffer(1, .{ .vertex = true }, .read_only_storage, false, 0),
                gpu.BindGroupLayout.Entry.initBuffer(2, .{ .vertex = true }, .read_only_storage, false, 0),
                gpu.BindGroupLayout.Entry.initBuffer(3, .{ .vertex = true }, .read_only_storage, false, 0),
                gpu.BindGroupLayout.Entry.initSampler(4, .{ .fragment = true }, .filtering),
                gpu.BindGroupLayout.Entry.initTexture(5, .{ .fragment = true }, .float, .dimension_2d, false),
            },
        }),
    );
    defer bind_group_layout.release();

    const texture_view = texture.createView(&gpu.TextureView.Descriptor{ .label = label });
    defer texture_view.release();

    const bind_group = pipeline.bind_group orelse device.createBindGroup(
        &gpu.BindGroup.Descriptor.init(.{
            .label = label,
            .layout = bind_group_layout,
            .entries = &.{
                gpu.BindGroup.Entry.initBuffer(0, uniforms, 0, @sizeOf(Uniforms), @sizeOf(Uniforms)),
                gpu.BindGroup.Entry.initBuffer(1, transforms, 0, @sizeOf(math.Mat4x4) * buffer_cap, @sizeOf(math.Mat4x4)),
                gpu.BindGroup.Entry.initBuffer(2, colors, 0, @sizeOf(math.Vec4) * buffer_cap, @sizeOf(math.Vec4)),
                gpu.BindGroup.Entry.initBuffer(3, glyphs, 0, @sizeOf(Glyph) * buffer_cap, @sizeOf(Glyph)),
                gpu.BindGroup.Entry.initSampler(4, texture_sampler),
                gpu.BindGroup.Entry.initTextureView(5, texture_view),
            },
        }),
    );

    const blend_state = pipeline.blend_state orelse gpu.BlendState{
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

    const shader_module = pipeline.shader orelse device.createShaderModuleWGSL("text.wgsl", @embedFile("text.wgsl"));
    defer shader_module.release();

    const color_target = pipeline.color_target_state orelse gpu.ColorTargetState{
        .format = window.framebuffer_format,
        .blend = &blend_state,
        .write_mask = gpu.ColorWriteMaskFlags.all,
    };
    const fragment = pipeline.fragment_state orelse gpu.FragmentState.init(.{
        .module = shader_module,
        .entry_point = "fragMain",
        .targets = &.{color_target},
    });

    const bind_group_layouts = [_]*gpu.BindGroupLayout{bind_group_layout};
    const pipeline_layout = pipeline.layout orelse device.createPipelineLayout(&gpu.PipelineLayout.Descriptor.init(.{
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

    pipeline.built = BuiltPipeline{
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
    pipeline.num_texts = 0;
    pipeline.num_segments = 0;
    pipeline.num_glyphs = 0;
}

fn updatePipelineBuffers(
    text: *Text,
    core: *mach.Core,
    pipeline_id: mach.ObjectID,
    pipeline_children: []const mach.ObjectID,
) !void {
    var pipeline = text.pipelines.getValue(pipeline_id);
    defer text.pipelines.setValueRaw(pipeline_id, pipeline);
    const window = core.windows.getValue(pipeline.window.?);
    const device = window.device;
    const queue = window.queue;

    const label = @tagName(mach_module) ++ ".updatePipelineBuffers";
    const encoder = device.createCommandEncoder(&.{ .label = label });
    defer encoder.release();

    var glyphs = if (text.glyph_update_buffer) |*b| b else blk: {
        // TODO(text): better default allocation size
        const b = try std.ArrayListUnmanaged(Glyph).initCapacity(text.allocator, 256);
        text.glyph_update_buffer = b;
        break :blk &text.glyph_update_buffer.?;
    };
    glyphs.clearRetainingCapacity();

    var texture_update = false;
    var num_segments: u32 = 0;
    var i: u32 = 0;
    for (pipeline_children) |text_id| {
        if (!text.objects.is(text_id)) continue;
        var t = text.objects.getValue(text_id);
        num_segments += @intCast(t.segments.len);

        cp_transforms[i] = t.transform;

        // Changing these fields shouldn't trigger a pipeline rebuild, so clear their update values:
        _ = text.objects.updated(text_id, .transform);

        // If the text has been built before, and nothing about it has changed, then we can just use
        // what we built already.
        if (t.built != null and !text.objects.anyUpdated(text_id)) {
            for (t.built.?.glyphs.items) |*glyph| glyph.text_index = i;
            try glyphs.appendSlice(text.allocator, t.built.?.glyphs.items);
            i += 1;
            continue;
        }

        // Where we will store the built glyphs for this text entity.
        var built_text = if (t.built) |bt| bt else BuiltText{
            // TODO(text): better default allocations
            .glyphs = try std.ArrayListUnmanaged(Glyph).initCapacity(text.allocator, 64),
        };
        built_text.glyphs.clearRetainingCapacity();

        const px_density = 2.0; // TODO(text): do not hard-code pixel density
        var origin_x: f32 = 0.0;
        var origin_y: f32 = 0.0;
        for (t.segments) |segment| {
            // Load the font
            // TODO(text): allow specifying a custom font
            // TODO(text): keep fonts around for reuse later
            // const font_name = text_style.get(style, .font_name).?;
            // _ = font_name; // TODO(text): actually use font name
            const font_bytes = @import("font-assets").fira_sans_regular_ttf;
            var font = if (text.font_once) |f| f else blk: {
                text.font_once = try gfx.Font.initBytes(font_bytes);
                break :blk text.font_once.?;
            };
            // TODO(text)
            // defer font.deinit(allocator);

            const style = text.styles.getValue(segment.style);

            // Create a text shaper
            var run = try gfx.TextRun.init();
            run.font_size_px = style.font_size;
            run.px_density = px_density;
            defer run.deinit();

            run.addText(segment.text);
            try font.shape(&run);

            while (run.next()) |glyph| {
                const codepoint = segment.text[glyph.cluster];
                // TODO(text): use flags(?) to detect newline, or at least something more reliable?
                if (codepoint == '\n') {
                    origin_x = 0;
                    origin_y -= style.font_size;
                    continue;
                }

                const region = try pipeline.built.?.regions.getOrPut(text.allocator, .{
                    .index = glyph.glyph_index,
                    .size = @bitCast(style.font_size),
                });
                if (!region.found_existing) {
                    const rendered_glyph = try font.render(text.allocator, glyph.glyph_index, .{
                        .font_size_px = run.font_size_px,
                    });
                    if (rendered_glyph.bitmap) |bitmap| {
                        var glyph_atlas_region = try pipeline.built.?.texture_atlas.reserve(text.allocator, rendered_glyph.width, rendered_glyph.height);
                        pipeline.built.?.texture_atlas.set(glyph_atlas_region, @as([*]const u8, @ptrCast(bitmap.ptr))[0 .. bitmap.len * 4]);
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
                try built_text.glyphs.append(text.allocator, .{
                    .pos = vec2(
                        origin_x + glyph.offset.x(),
                        origin_y - (size.y() - glyph.offset.y()),
                    ).divScalar(px_density),
                    .size = size.divScalar(px_density),
                    .text_index = i,
                    // TODO(d3d12): this is a hack, having 7 floats before the color vec causes an error
                    .text_padding = 0,
                    .uv_pos = vec2(@floatFromInt(r.x), @floatFromInt(r.y)),
                    .color = style.color,
                });
                origin_x += glyph.advance.x();
            }
        }
        // Update the text entity's built form
        t.built = built_text;
        text.objects.setValueRaw(text_id, t);

        // Add to the entire set of glyphs for this pipeline
        try glyphs.appendSlice(text.allocator, built_text.glyphs.items);
        i += 1;
    }

    // Every pipeline update, we copy updated glyph and text buffers to the GPU.
    pipeline.num_texts = i;
    pipeline.num_segments = num_segments;
    pipeline.num_glyphs = @intCast(glyphs.items.len);
    if (glyphs.items.len > 0) encoder.writeBuffer(pipeline.built.?.glyphs, 0, glyphs.items);
    if (i > 0) encoder.writeBuffer(pipeline.built.?.transforms, 0, cp_transforms[0..i]);

    if (texture_update) {
        // TODO(text): do not assume texture's data_layout and img_size here, instead get it from
        // somewhere known to be matching the actual texture.
        //
        // TODO(text): allow users to specify RGBA32 or other pixel formats
        const img_size = gpu.Extent3D{ .width = 1024, .height = 1024 };
        const data_layout = gpu.Texture.DataLayout{
            .bytes_per_row = @as(u32, @intCast(img_size.width * 4)),
            .rows_per_image = @as(u32, @intCast(img_size.height)),
        };
        queue.writeTexture(
            &.{ .texture = pipeline.built.?.texture },
            &data_layout,
            &img_size,
            pipeline.built.?.texture_atlas.data,
        );
    }

    if (i > 0 or glyphs.items.len > 0) {
        var command = encoder.finish(&.{ .label = label });
        defer command.release();
        queue.submit(&[_]*gpu.CommandBuffer{command});
    }
}

fn renderPipeline(
    text: *Text,
    core: *mach.Core,
    pipeline_id: mach.ObjectID,
) void {
    const pipeline = text.pipelines.getValue(pipeline_id);
    const window = core.windows.getValue(pipeline.window.?);
    const device = window.device;

    const label = @tagName(mach_module) ++ ".renderPipeline";
    const encoder = device.createCommandEncoder(&.{ .label = label });
    defer encoder.release();

    // Update uniform buffer
    const view_projection = pipeline.view_projection orelse blk: {
        const width_px: f32 = @floatFromInt(window.width);
        const height_px: f32 = @floatFromInt(window.height);
        break :blk math.Mat4x4.projection2D(.{
            .left = -width_px / 2,
            .right = width_px / 2,
            .bottom = -height_px / 2,
            .top = height_px / 2,
            .near = -0.1,
            .far = 100000,
        });
    };
    const uniforms = Uniforms{
        .view_projection = view_projection,
        .texture_size = math.vec2(
            @as(f32, @floatFromInt(pipeline.built.?.texture.getWidth())),
            @as(f32, @floatFromInt(pipeline.built.?.texture.getHeight())),
        ),
    };
    encoder.writeBuffer(pipeline.built.?.uniforms, 0, &[_]Uniforms{uniforms});
    var command = encoder.finish(&.{ .label = label });
    defer command.release();
    window.queue.submit(&[_]*gpu.CommandBuffer{command});

    // Draw the text batch
    const total_vertices = pipeline.num_glyphs * 6;
    pipeline.render_pass.?.setPipeline(pipeline.built.?.render);
    // TODO(text): can we remove unused dynamic offsets?
    pipeline.render_pass.?.setBindGroup(0, pipeline.built.?.bind_group, &.{});
    pipeline.render_pass.?.draw(total_vertices, 1, 0, 0);
}
