const ComputePassTimestampWrite = @import("structs.zig").ComputePassTimestampWrite;

const ComputePassEncoder = @This();

/// The type erased pointer to the ComputePassEncoder implementation
/// Equal to c.WGPUComputePassEncoder for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    // dispatch: fn (ptr: *anyopaque, workgroup_count_x: u32, workgroup_count_y: u32, workgroup_count_z: u32) void,
    // WGPU_EXPORT void wgpuComputePassEncoderDispatch(WGPUComputePassEncoder computePassEncoder, uint32_t workgroupCountX, uint32_t workgroupCountY, uint32_t workgroupCountZ);
    // dispatchIndirect: fn (ptr: *anyopaque, indirect_buffer: Buffer, indirect_offset: u64) void,
    // WGPU_EXPORT void wgpuComputePassEncoderDispatchIndirect(WGPUComputePassEncoder computePassEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
    end: fn (ptr: *anyopaque) void,
    insertDebugMarker: fn (ptr: *anyopaque, marker_label: [*:0]const u8) void,
    // popDebugGroup: fn (ptr: *anyopaque) void,
    // WGPU_EXPORT void wgpuComputePassEncoderPopDebugGroup(WGPUComputePassEncoder computePassEncoder);
    // pushDebugGroup: fn (ptr: *anyopaque, group_label: [*:0]const u8) void,
    // WGPU_EXPORT void wgpuComputePassEncoderPushDebugGroup(WGPUComputePassEncoder computePassEncoder, char const * groupLabel);
    // setBindGroup: fn (ptr: *anyopaque, group_index: u32, group: BindGroup, dynamic_offsets: []u32) void,
    // WGPU_EXPORT void wgpuComputePassEncoderSetBindGroup(WGPUComputePassEncoder computePassEncoder, uint32_t groupIndex, WGPUBindGroup group, uint32_t dynamicOffsetCount, uint32_t const * dynamicOffsets);
    setLabel: fn (ptr: *anyopaque, label: [:0]const u8) void,
    // setPipeline: fn (ptr: *anyopaque, pipeline: ComputePipeline) void,
    // WGPU_EXPORT void wgpuComputePassEncoderSetPipeline(WGPUComputePassEncoder computePassEncoder, WGPUComputePipeline pipeline);
    // writeTimestamp: fn (ptr: *anyopaque, query_set: QuerySet, query_index: u32) void,
    // WGPU_EXPORT void wgpuComputePassEncoderWriteTimestamp(WGPUComputePassEncoder computePassEncoder, WGPUQuerySet querySet, uint32_t queryIndex);
};

pub inline fn reference(enc: ComputePassEncoder) void {
    enc.vtable.reference(enc.ptr);
}

pub inline fn release(enc: ComputePassEncoder) void {
    enc.vtable.release(enc.ptr);
}

pub inline fn end(enc: ComputePassEncoder) void {
    enc.vtable.end(enc.ptr);
}

pub inline fn insertDebugMarker(enc: ComputePassEncoder, marker_label: [*:0]const u8) void {
    enc.vtable.insertDebugMarker(enc.ptr, marker_label);
}

pub inline fn setLabel(enc: ComputePassEncoder, label: [:0]const u8) void {
    enc.vtable.setLabel(enc.ptr, label);
}

pub const Descriptor = struct {
    label: ?[*:0]const u8 = null,
    timestamp_writes: []const ComputePassTimestampWrite,
};

test {
    _ = VTable;
    _ = reference;
    _ = release;
    _ = end;
    _ = insertDebugMarker;
    _ = setLabel;
    _ = Descriptor;
}
