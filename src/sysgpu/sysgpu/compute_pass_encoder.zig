const Buffer = @import("buffer.zig").Buffer;
const BindGroup = @import("bind_group.zig").BindGroup;
const ComputePipeline = @import("compute_pipeline.zig").ComputePipeline;
const QuerySet = @import("query_set.zig").QuerySet;
const Impl = @import("interface.zig").Impl;

pub const ComputePassEncoder = opaque {
    /// Default `workgroup_count_y`: 1
    /// Default `workgroup_count_z`: 1
    pub inline fn dispatchWorkgroups(compute_pass_encoder: *ComputePassEncoder, workgroup_count_x: u32, workgroup_count_y: u32, workgroup_count_z: u32) void {
        Impl.computePassEncoderDispatchWorkgroups(compute_pass_encoder, workgroup_count_x, workgroup_count_y, workgroup_count_z);
    }

    pub inline fn dispatchWorkgroupsIndirect(compute_pass_encoder: *ComputePassEncoder, indirect_buffer: *Buffer, indirect_offset: u64) void {
        Impl.computePassEncoderDispatchWorkgroupsIndirect(compute_pass_encoder, indirect_buffer, indirect_offset);
    }

    pub inline fn end(compute_pass_encoder: *ComputePassEncoder) void {
        Impl.computePassEncoderEnd(compute_pass_encoder);
    }

    pub inline fn insertDebugMarker(compute_pass_encoder: *ComputePassEncoder, marker_label: [*:0]const u8) void {
        Impl.computePassEncoderInsertDebugMarker(compute_pass_encoder, marker_label);
    }

    pub inline fn popDebugGroup(compute_pass_encoder: *ComputePassEncoder) void {
        Impl.computePassEncoderPopDebugGroup(compute_pass_encoder);
    }

    pub inline fn pushDebugGroup(compute_pass_encoder: *ComputePassEncoder, group_label: [*:0]const u8) void {
        Impl.computePassEncoderPushDebugGroup(compute_pass_encoder, group_label);
    }

    /// Default `dynamic_offsets`: null
    pub inline fn setBindGroup(compute_pass_encoder: *ComputePassEncoder, group_index: u32, group: *BindGroup, dynamic_offsets: ?[]const u32) void {
        Impl.computePassEncoderSetBindGroup(
            compute_pass_encoder,
            group_index,
            group,
            if (dynamic_offsets) |v| v.len else 0,
            if (dynamic_offsets) |v| v.ptr else null,
        );
    }

    pub inline fn setLabel(compute_pass_encoder: *ComputePassEncoder, label: [*:0]const u8) void {
        Impl.computePassEncoderSetLabel(compute_pass_encoder, label);
    }

    pub inline fn setPipeline(compute_pass_encoder: *ComputePassEncoder, pipeline: *ComputePipeline) void {
        Impl.computePassEncoderSetPipeline(compute_pass_encoder, pipeline);
    }

    pub inline fn writeTimestamp(compute_pass_encoder: *ComputePassEncoder, query_set: *QuerySet, query_index: u32) void {
        Impl.computePassEncoderWriteTimestamp(compute_pass_encoder, query_set, query_index);
    }

    pub inline fn reference(compute_pass_encoder: *ComputePassEncoder) void {
        Impl.computePassEncoderReference(compute_pass_encoder);
    }

    pub inline fn release(compute_pass_encoder: *ComputePassEncoder) void {
        Impl.computePassEncoderRelease(compute_pass_encoder);
    }
};
