const ComputePassTimestampWrite = @import("structs.zig").ComputePassTimestampWrite;
const ComputePipeline = @import("ComputePipeline.zig");
const QuerySet = @import("QuerySet.zig");
const BindGroup = @import("BindGroup.zig");
const Buffer = @import("Buffer.zig");

const ComputePassEncoder = @This();

/// The type erased pointer to the ComputePassEncoder implementation
/// Equal to c.WGPUComputePassEncoder for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    dispatch: fn (ptr: *anyopaque, workgroup_count_x: u32, workgroup_count_y: u32, workgroup_count_z: u32) void,
    dispatchIndirect: fn (ptr: *anyopaque, indirect_buffer: Buffer, indirect_offset: u64) void,
    end: fn (ptr: *anyopaque) void,
    insertDebugMarker: fn (ptr: *anyopaque, marker_label: [*:0]const u8) void,
    popDebugGroup: fn (ptr: *anyopaque) void,
    pushDebugGroup: fn (ptr: *anyopaque, group_label: [*:0]const u8) void,
    setBindGroup: fn (ptr: *anyopaque, group_index: u32, group: BindGroup, dynamic_offsets: []u32) void,
    setLabel: fn (ptr: *anyopaque, label: [:0]const u8) void,
    setPipeline: fn (ptr: *anyopaque, pipeline: ComputePipeline) void,
    writeTimestamp: fn (ptr: *anyopaque, query_set: QuerySet, query_index: u32) void,
};

pub inline fn reference(enc: ComputePassEncoder) void {
    enc.vtable.reference(enc.ptr);
}

pub inline fn release(enc: ComputePassEncoder) void {
    enc.vtable.release(enc.ptr);
}

pub inline fn dispatch(
    enc: ComputePassEncoder,
    workgroup_count_x: u32,
    workgroup_count_y: u32,
    workgroup_count_z: u32,
) void {
    enc.vtable.dispatch(enc.ptr, workgroup_count_x, workgroup_count_y, workgroup_count_z);
}

pub inline fn dispatchIndirect(
    enc: ComputePassEncoder,
    indirect_buffer: Buffer,
    indirect_offset: u64,
) void {
    enc.vtable.dispatchIndirect(enc.ptr, indirect_buffer, indirect_offset);
}

pub inline fn end(enc: ComputePassEncoder) void {
    enc.vtable.end(enc.ptr);
}

pub inline fn insertDebugMarker(enc: ComputePassEncoder, marker_label: [*:0]const u8) void {
    enc.vtable.insertDebugMarker(enc.ptr, marker_label);
}

pub inline fn popDebugGroup(enc: ComputePassEncoder) void {
    enc.vtable.popDebugGroup(enc.ptr);
}

pub inline fn pushDebugGroup(enc: ComputePassEncoder, group_label: [*:0]const u8) void {
    enc.vtable.pushDebugGroup(enc.ptr, group_label);
}

pub inline fn setBindGroup(
    enc: ComputePassEncoder,
    group_index: u32,
    group: BindGroup,
    dynamic_offsets: []u32,
) void {
    enc.vtable.setBindGroup(enc.ptr, group_index, group, dynamic_offsets);
}

pub inline fn setLabel(enc: ComputePassEncoder, label: [:0]const u8) void {
    enc.vtable.setLabel(enc.ptr, label);
}

pub inline fn setPipeline(enc: ComputePassEncoder, pipeline: ComputePipeline) void {
    enc.vtable.setPipeline(enc.ptr, pipeline);
}

pub inline fn writeTimestamp(enc: ComputePassEncoder, query_set: QuerySet, query_index: u32) void {
    enc.vtable.writeTimestamp(enc.ptr, query_set, query_index);
}

pub const Descriptor = struct {
    label: ?[*:0]const u8 = null,
    timestamp_writes: []const ComputePassTimestampWrite,
};

test {
    _ = VTable;
    _ = reference;
    _ = release;
    _ = dispatch;
    _ = dispatchIndirect;
    _ = end;
    _ = insertDebugMarker;
    _ = popDebugGroup;
    _ = pushDebugGroup;
    _ = setBindGroup;
    _ = setLabel;
    _ = setPipeline;
    _ = writeTimestamp;
    _ = Descriptor;
}
