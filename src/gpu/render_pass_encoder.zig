const Buffer = @import("buffer.zig").Buffer;
const RenderBundle = @import("render_bundle.zig").RenderBundle;
const BindGroup = @import("bind_group.zig").BindGroup;
const RenderPipeline = @import("render_pipeline.zig").RenderPipeline;
const QuerySet = @import("query_set.zig").QuerySet;
const Color = @import("main.zig").Color;
const IndexFormat = @import("main.zig").IndexFormat;
const Impl = @import("interface.zig").Impl;

pub const RenderPassEncoder = opaque {
    pub inline fn beginOcclusionQuery(render_pass_encoder: *RenderPassEncoder, query_index: u32) void {
        Impl.renderPassEncoderBeginOcclusionQuery(render_pass_encoder, query_index);
    }

    /// Default `instance_count`: 1
    /// Default `first_vertex`: 0
    /// Default `first_instance`: 0
    pub inline fn draw(render_pass_encoder: *RenderPassEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {
        Impl.renderPassEncoderDraw(render_pass_encoder, vertex_count, instance_count, first_vertex, first_instance);
    }

    /// Default `instance_count`: 1
    /// Default `first_index`: 0
    /// Default `base_vertex`: 0
    /// Default `first_instance`: 0
    pub inline fn drawIndexed(render_pass_encoder: *RenderPassEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: i32, first_instance: u32) void {
        Impl.renderPassEncoderDrawIndexed(render_pass_encoder, index_count, instance_count, first_index, base_vertex, first_instance);
    }

    pub inline fn drawIndexedIndirect(render_pass_encoder: *RenderPassEncoder, indirect_buffer: *Buffer, indirect_offset: u64) void {
        Impl.renderPassEncoderDrawIndexedIndirect(render_pass_encoder, indirect_buffer, indirect_offset);
    }

    pub inline fn drawIndirect(render_pass_encoder: *RenderPassEncoder, indirect_buffer: *Buffer, indirect_offset: u64) void {
        Impl.renderPassEncoderDrawIndirect(render_pass_encoder, indirect_buffer, indirect_offset);
    }

    pub inline fn end(render_pass_encoder: *RenderPassEncoder) void {
        Impl.renderPassEncoderEnd(render_pass_encoder);
    }

    pub inline fn endOcclusionQuery(render_pass_encoder: *RenderPassEncoder) void {
        Impl.renderPassEncoderEndOcclusionQuery(render_pass_encoder);
    }

    pub inline fn executeBundles(
        render_pass_encoder: *RenderPassEncoder,
        bundles: []*const RenderBundle,
    ) void {
        Impl.renderPassEncoderExecuteBundles(
            render_pass_encoder,
            bundles.len,
            bundles.ptr,
        );
    }

    pub inline fn insertDebugMarker(render_pass_encoder: *RenderPassEncoder, marker_label: [*:0]const u8) void {
        Impl.renderPassEncoderInsertDebugMarker(render_pass_encoder, marker_label);
    }

    pub inline fn popDebugGroup(render_pass_encoder: *RenderPassEncoder) void {
        Impl.renderPassEncoderPopDebugGroup(render_pass_encoder);
    }

    pub inline fn pushDebugGroup(render_pass_encoder: *RenderPassEncoder, group_label: [*:0]const u8) void {
        Impl.renderPassEncoderPushDebugGroup(render_pass_encoder, group_label);
    }

    /// Default `dynamic_offsets_count`: 0
    /// Default `dynamic_offsets`: `null`
    pub inline fn setBindGroup(render_pass_encoder: *RenderPassEncoder, group_index: u32, group: *BindGroup, dynamic_offsets: ?[]const u32) void {
        Impl.renderPassEncoderSetBindGroup(
            render_pass_encoder,
            group_index,
            group,
            if (dynamic_offsets) |v| v.len else 0,
            if (dynamic_offsets) |v| v.ptr else null,
        );
    }

    pub inline fn setBlendConstant(render_pass_encoder: *RenderPassEncoder, color: *const Color) void {
        Impl.renderPassEncoderSetBlendConstant(render_pass_encoder, color);
    }

    /// Default `offset`: 0
    /// Default `size`: `gpu.whole_size`
    pub inline fn setIndexBuffer(render_pass_encoder: *RenderPassEncoder, buffer: *Buffer, format: IndexFormat, offset: u64, size: u64) void {
        Impl.renderPassEncoderSetIndexBuffer(render_pass_encoder, buffer, format, offset, size);
    }

    pub inline fn setLabel(render_pass_encoder: *RenderPassEncoder, label: [*:0]const u8) void {
        Impl.renderPassEncoderSetLabel(render_pass_encoder, label);
    }

    pub inline fn setPipeline(render_pass_encoder: *RenderPassEncoder, pipeline: *RenderPipeline) void {
        Impl.renderPassEncoderSetPipeline(render_pass_encoder, pipeline);
    }

    pub inline fn setScissorRect(render_pass_encoder: *RenderPassEncoder, x: u32, y: u32, width: u32, height: u32) void {
        Impl.renderPassEncoderSetScissorRect(render_pass_encoder, x, y, width, height);
    }

    pub inline fn setStencilReference(render_pass_encoder: *RenderPassEncoder, _reference: u32) void {
        Impl.renderPassEncoderSetStencilReference(render_pass_encoder, _reference);
    }

    /// Default `offset`: 0
    /// Default `size`: `gpu.whole_size`
    pub inline fn setVertexBuffer(render_pass_encoder: *RenderPassEncoder, slot: u32, buffer: *Buffer, offset: u64, size: u64) void {
        Impl.renderPassEncoderSetVertexBuffer(render_pass_encoder, slot, buffer, offset, size);
    }

    pub inline fn setViewport(render_pass_encoder: *RenderPassEncoder, x: f32, y: f32, width: f32, height: f32, min_depth: f32, max_depth: f32) void {
        Impl.renderPassEncoderSetViewport(render_pass_encoder, x, y, width, height, min_depth, max_depth);
    }

    pub inline fn writeTimestamp(render_pass_encoder: *RenderPassEncoder, query_set: *QuerySet, query_index: u32) void {
        Impl.renderPassEncoderWriteTimestamp(render_pass_encoder, query_set, query_index);
    }

    pub inline fn reference(render_pass_encoder: *RenderPassEncoder) void {
        Impl.renderPassEncoderReference(render_pass_encoder);
    }

    pub inline fn release(render_pass_encoder: *RenderPassEncoder) void {
        Impl.renderPassEncoderRelease(render_pass_encoder);
    }
};
