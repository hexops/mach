const Texture = @import("texture.zig").Texture;
const Buffer = @import("buffer.zig").Buffer;
const BindGroup = @import("bind_group.zig").BindGroup;
const RenderPipeline = @import("render_pipeline.zig").RenderPipeline;
const RenderBundle = @import("render_bundle.zig").RenderBundle;
const Bool32 = @import("main.zig").Bool32;
const ChainedStruct = @import("main.zig").ChainedStruct;
const IndexFormat = @import("main.zig").IndexFormat;
const Impl = @import("interface.zig").Impl;

pub const RenderBundleEncoder = opaque {
    pub const Descriptor = extern struct {
        next_in_chain: ?*const ChainedStruct = null,
        label: ?[*:0]const u8 = null,
        color_formats_count: usize = 0,
        color_formats: ?[*]const Texture.Format = null,
        depth_stencil_format: Texture.Format = .undefined,
        sample_count: u32 = 1,
        depth_read_only: Bool32 = .false,
        stencil_read_only: Bool32 = .false,

        /// Provides a slightly friendlier Zig API to initialize this structure.
        pub inline fn init(v: struct {
            next_in_chain: ?*const ChainedStruct = null,
            label: ?[*:0]const u8 = null,
            color_formats: ?[]const Texture.Format = null,
            depth_stencil_format: Texture.Format = .undefined,
            sample_count: u32 = 1,
            depth_read_only: bool = false,
            stencil_read_only: bool = false,
        }) Descriptor {
            return .{
                .next_in_chain = v.next_in_chain,
                .label = v.label,
                .color_formats_count = if (v.color_formats) |e| e.len else 0,
                .color_formats = if (v.color_formats) |e| e.ptr else null,
                .depth_stencil_format = v.depth_stencil_format,
                .sample_count = v.sample_count,
                .depth_read_only = Bool32.from(v.depth_read_only),
                .stencil_read_only = Bool32.from(v.stencil_read_only),
            };
        }
    };

    /// Default `instance_count`: 1
    /// Default `first_vertex`: 0
    /// Default `first_instance`: 0
    pub inline fn draw(render_bundle_encoder: *RenderBundleEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {
        Impl.renderBundleEncoderDraw(render_bundle_encoder, vertex_count, instance_count, first_vertex, first_instance);
    }

    /// Default `instance_count`: 1
    /// Default `first_index`: 0
    /// Default `base_vertex`: 0
    /// Default `first_instance`: 0
    pub inline fn drawIndexed(render_bundle_encoder: *RenderBundleEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: i32, first_instance: u32) void {
        Impl.renderBundleEncoderDrawIndexed(render_bundle_encoder, index_count, instance_count, first_index, base_vertex, first_instance);
    }

    pub inline fn drawIndexedIndirect(render_bundle_encoder: *RenderBundleEncoder, indirect_buffer: *Buffer, indirect_offset: u64) void {
        Impl.renderBundleEncoderDrawIndexedIndirect(render_bundle_encoder, indirect_buffer, indirect_offset);
    }

    pub inline fn drawIndirect(render_bundle_encoder: *RenderBundleEncoder, indirect_buffer: *Buffer, indirect_offset: u64) void {
        Impl.renderBundleEncoderDrawIndirect(render_bundle_encoder, indirect_buffer, indirect_offset);
    }

    pub inline fn finish(render_bundle_encoder: *RenderBundleEncoder, descriptor: ?*const RenderBundle.Descriptor) *RenderBundle {
        return Impl.renderBundleEncoderFinish(render_bundle_encoder, descriptor);
    }

    pub inline fn insertDebugMarker(render_bundle_encoder: *RenderBundleEncoder, marker_label: [*:0]const u8) void {
        Impl.renderBundleEncoderInsertDebugMarker(render_bundle_encoder, marker_label);
    }

    pub inline fn popDebugGroup(render_bundle_encoder: *RenderBundleEncoder) void {
        Impl.renderBundleEncoderPopDebugGroup(render_bundle_encoder);
    }

    pub inline fn pushDebugGroup(render_bundle_encoder: *RenderBundleEncoder, group_label: [*:0]const u8) void {
        Impl.renderBundleEncoderPushDebugGroup(render_bundle_encoder, group_label);
    }

    /// Default `dynamic_offsets`: `null`
    pub inline fn setBindGroup(render_bundle_encoder: *RenderBundleEncoder, group_index: u32, group: *BindGroup, dynamic_offsets: ?[]const u32) void {
        Impl.renderBundleEncoderSetBindGroup(
            render_bundle_encoder,
            group_index,
            group,
            if (dynamic_offsets) |v| v.len else 0,
            if (dynamic_offsets) |v| v.ptr else null,
        );
    }

    /// Default `offset`: 0
    /// Default `size`: `gpu.whole_size`
    pub inline fn setIndexBuffer(render_bundle_encoder: *RenderBundleEncoder, buffer: *Buffer, format: IndexFormat, offset: u64, size: u64) void {
        Impl.renderBundleEncoderSetIndexBuffer(render_bundle_encoder, buffer, format, offset, size);
    }

    pub inline fn setLabel(render_bundle_encoder: *RenderBundleEncoder, label: [*:0]const u8) void {
        Impl.renderBundleEncoderSetLabel(render_bundle_encoder, label);
    }

    pub inline fn setPipeline(render_bundle_encoder: *RenderBundleEncoder, pipeline: *RenderPipeline) void {
        Impl.renderBundleEncoderSetPipeline(render_bundle_encoder, pipeline);
    }

    /// Default `offset`: 0
    /// Default `size`: `gpu.whole_size`
    pub inline fn setVertexBuffer(render_bundle_encoder: *RenderBundleEncoder, slot: u32, buffer: *Buffer, offset: u64, size: u64) void {
        Impl.renderBundleEncoderSetVertexBuffer(render_bundle_encoder, slot, buffer, offset, size);
    }

    pub inline fn reference(render_bundle_encoder: *RenderBundleEncoder) void {
        Impl.renderBundleEncoderReference(render_bundle_encoder);
    }

    pub inline fn release(render_bundle_encoder: *RenderBundleEncoder) void {
        Impl.renderBundleEncoderRelease(render_bundle_encoder);
    }
};
