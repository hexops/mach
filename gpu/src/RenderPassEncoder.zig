const QuerySet = @import("QuerySet.zig");
const RenderPassColorAttachment = @import("structs.zig").RenderPassColorAttachment;
const RenderPassDepthStencilAttachment = @import("structs.zig").RenderPassDepthStencilAttachment;
const RenderPassTimestampWrite = @import("structs.zig").RenderPassTimestampWrite;
const RenderPipeline = @import("RenderPipeline.zig");
const Buffer = @import("Buffer.zig");
const RenderBundle = @import("RenderBundle.zig");
const BindGroup = @import("BindGroup.zig");
const Color = @import("data.zig").Color;
const IndexFormat = @import("enums.zig").IndexFormat;

const RenderPassEncoder = @This();

/// The type erased pointer to the RenderPassEncoder implementation
/// Equal to c.WGPURenderPassEncoder for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    draw: fn (ptr: *anyopaque, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void,
    drawIndexed: fn (
        ptr: *anyopaque,
        index_count: u32,
        instance_count: u32,
        first_index: u32,
        base_vertex: i32,
        first_instance: u32,
    ) void,
    drawIndexedIndirect: fn (ptr: *anyopaque, indirect_buffer: Buffer, indirect_offset: u64) void,
    drawIndirect: fn (ptr: *anyopaque, indirect_buffer: Buffer, indirect_offset: u64) void,
    beginOcclusionQuery: fn (ptr: *anyopaque, query_index: u32) void,
    endOcclusionQuery: fn (ptr: *anyopaque) void,
    end: fn (ptr: *anyopaque) void,
    executeBundles: fn (ptr: *anyopaque, bundles: []RenderBundle) void,
    insertDebugMarker: fn (ptr: *anyopaque, marker_label: [*:0]const u8) void,
    popDebugGroup: fn (ptr: *anyopaque) void,
    pushDebugGroup: fn (ptr: *anyopaque, group_label: [*:0]const u8) void,
    setBindGroup: fn (ptr: *anyopaque, group_index: u32, group: BindGroup, dynamic_offsets: ?[]const u32) void,
    setBlendConstant: fn (ptr: *anyopaque, color: *const Color) void,
    setIndexBuffer: fn (ptr: *anyopaque, buffer: Buffer, format: IndexFormat, offset: u64, size: u64) void,
    setLabel: fn (ptr: *anyopaque, label: [:0]const u8) void,
    setPipeline: fn (ptr: *anyopaque, pipeline: RenderPipeline) void,
    setScissorRect: fn (ptr: *anyopaque, x: u32, y: u32, width: u32, height: u32) void,
    setStencilReference: fn (ptr: *anyopaque, reference: u32) void,
    setVertexBuffer: fn (ptr: *anyopaque, slot: u32, buffer: Buffer, offset: u64, size: u64) void,
    setViewport: fn (ptr: *anyopaque, x: f32, y: f32, width: f32, height: f32, min_depth: f32, max_depth: f32) void,
    writeTimestamp: fn (ptr: *anyopaque, query_set: QuerySet, query_index: u32) void,
};

pub inline fn reference(pass: RenderPassEncoder) void {
    pass.vtable.reference(pass.ptr);
}

pub inline fn release(pass: RenderPassEncoder) void {
    pass.vtable.release(pass.ptr);
}

pub inline fn draw(
    pass: RenderPassEncoder,
    vertex_count: u32,
    instance_count: u32,
    first_vertex: u32,
    first_instance: u32,
) void {
    pass.vtable.draw(pass.ptr, vertex_count, instance_count, first_vertex, first_instance);
}

pub inline fn drawIndexed(
    pass: RenderPassEncoder,
    index_count: u32,
    instance_count: u32,
    first_index: u32,
    base_vertex: i32,
    first_instance: u32,
) void {
    pass.vtable.drawIndexed(pass.ptr, index_count, instance_count, first_index, base_vertex, first_instance);
}

pub inline fn drawIndexedIndirect(pass: RenderPassEncoder, indirect_buffer: Buffer, indirect_offset: u64) void {
    pass.vtable.drawIndexedIndirect(pass.ptr, indirect_buffer, indirect_offset);
}

pub inline fn drawIndirect(pass: RenderPassEncoder, indirect_buffer: Buffer, indirect_offset: u64) void {
    pass.vtable.drawIndirect(pass.ptr, indirect_buffer, indirect_offset);
}

pub inline fn beginOcclusionQuery(pass: RenderPassEncoder, query_index: u32) void {
    pass.vtable.beginOcclusionQuery(pass.ptr, query_index);
}

pub inline fn endOcclusionQuery(pass: RenderPassEncoder) void {
    pass.vtable.endOcclusionQuery(pass.ptr);
}

pub inline fn end(pass: RenderPassEncoder) void {
    pass.vtable.end(pass.ptr);
}

pub inline fn executeBundles(pass: RenderPassEncoder, bundles: []RenderBundle) void {
    pass.vtable.executeBundles(pass.ptr, bundles);
}

pub inline fn insertDebugMarker(pass: RenderPassEncoder, marker_label: [*:0]const u8) void {
    pass.vtable.insertDebugMarker(pass.ptr, marker_label);
}

pub inline fn popDebugGroup(pass: RenderPassEncoder) void {
    pass.vtable.popDebugGroup(pass.ptr);
}

pub inline fn pushDebugGroup(pass: RenderPassEncoder, group_label: [*:0]const u8) void {
    pass.vtable.pushDebugGroup(pass.ptr, group_label);
}

pub inline fn setBindGroup(
    pass: RenderPassEncoder,
    group_index: u32,
    group: BindGroup,
    dynamic_offsets: ?[]const u32,
) void {
    pass.vtable.setBindGroup(pass.ptr, group_index, group, dynamic_offsets);
}

pub inline fn setBlendConstant(pass: RenderPassEncoder, color: *const Color) void {
    pass.vtable.setBlendConstant(pass.ptr, color);
}

pub inline fn setIndexBuffer(
    pass: RenderPassEncoder,
    buffer: Buffer,
    format: IndexFormat,
    offset: u64,
    size: u64,
) void {
    pass.vtable.setIndexBuffer(pass.ptr, buffer, format, offset, size);
}

pub inline fn setLabel(pass: RenderPassEncoder, label: [:0]const u8) void {
    pass.vtable.setLabel(pass.ptr, label);
}

pub inline fn setPipeline(pass: RenderPassEncoder, pipeline: RenderPipeline) void {
    pass.vtable.setPipeline(pass.ptr, pipeline);
}

pub inline fn setScissorRect(pass: RenderPassEncoder, x: u32, y: u32, width: u32, height: u32) void {
    pass.vtable.setScissorRect(pass.ptr, x, y, width, height);
}

pub inline fn setStencilReference(pass: RenderPassEncoder, ref: u32) void {
    pass.vtable.setStencilReference(pass.ptr, ref);
}

pub inline fn setVertexBuffer(
    pass: RenderPassEncoder,
    slot: u32,
    buffer: Buffer,
    offset: u64,
    size: u64,
) void {
    pass.vtable.setVertexBuffer(pass.ptr, slot, buffer, offset, size);
}

pub inline fn setViewport(
    pass: RenderPassEncoder,
    x: f32,
    y: f32,
    width: f32,
    height: f32,
    min_depth: f32,
    max_depth: f32,
) void {
    pass.vtable.setViewport(pass.ptr, x, y, width, height, min_depth, max_depth);
}

pub inline fn writeTimestamp(pass: RenderPassEncoder, query_set: QuerySet, query_index: u32) void {
    pass.vtable.writeTimestamp(pass.ptr, query_set, query_index);
}

pub const Descriptor = struct {
    label: ?[*:0]const u8 = null,
    color_attachments: []const RenderPassColorAttachment,
    depth_stencil_attachment: ?*const RenderPassDepthStencilAttachment = null,
    occlusion_query_set: ?QuerySet = null,
    timestamp_writes: ?[]RenderPassTimestampWrite = null,
};

test {
    _ = VTable;
    _ = reference;
    _ = release;
    _ = draw;
    _ = drawIndexed;
    _ = drawIndexedIndirect;
    _ = drawIndirect;
    _ = beginOcclusionQuery;
    _ = endOcclusionQuery;
    _ = end;
    _ = executeBundles;
    _ = insertDebugMarker;
    _ = popDebugGroup;
    _ = pushDebugGroup;
    _ = setBindGroup;
    _ = setBlendConstant;
    _ = setIndexBuffer;
    _ = setLabel;
    _ = setPipeline;
    _ = setPipeline;
    _ = setStencilReference;
    _ = setVertexBuffer;
    _ = setViewport;
    _ = writeTimestamp;
    _ = Descriptor;
}
