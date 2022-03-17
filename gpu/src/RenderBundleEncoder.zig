const Texture = @import("Texture.zig");
const Buffer = @import("Buffer.zig");
const RenderBundle = @import("RenderBundle.zig");
const BindGroup = @import("BindGroup.zig");
const RenderPipeline = @import("RenderPipeline.zig");
const IndexFormat = @import("enums.zig").IndexFormat;

const RenderBundleEncoder = @This();

/// The type erased pointer to the RenderBundleEncoder implementation
/// Equal to c.WGPURenderBundleEncoder for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    draw: fn (
        ptr: *anyopaque,
        vertex_count: u32,
        instance_count: u32,
        first_vertex: u32,
        first_instance: u32,
    ) void,
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
    finish: fn (ptr: *anyopaque, descriptor: *const RenderBundle.Descriptor) RenderBundle,
    insertDebugMarker: fn (ptr: *anyopaque, marker_label: [*:0]const u8) void,
    popDebugGroup: fn (ptr: *anyopaque) void,
    pushDebugGroup: fn (ptr: *anyopaque, group_label: [*:0]const u8) void,
    setBindGroup: fn (ptr: *anyopaque, group_index: u32, group: BindGroup, dynamic_offsets: []u32) void,
    setIndexBuffer: fn (ptr: *anyopaque, buffer: Buffer, format: IndexFormat, offset: u64, size: u64) void,
    setLabel: fn (ptr: *anyopaque, label: [:0]const u8) void,
    setPipeline: fn (ptr: *anyopaque, pipeline: RenderPipeline) void,
    // setVertexBuffer: fn (ptr: *anyopaque, slot: u32, buffer: Buffer, offset: u64, size: u64) void,
    // WGPU_EXPORT void wgpuRenderBundleEncoderSetVertexBuffer(WGPURenderBundleEncoder renderBundleEncoder, uint32_t slot, WGPUBuffer buffer, uint64_t offset, uint64_t size);
};

pub inline fn reference(enc: RenderBundleEncoder) void {
    enc.vtable.reference(enc.ptr);
}

pub inline fn release(enc: RenderBundleEncoder) void {
    enc.vtable.release(enc.ptr);
}

pub inline fn draw(
    enc: RenderBundleEncoder,
    vertex_count: u32,
    instance_count: u32,
    first_vertex: u32,
    first_instance: u32,
) void {
    enc.vtable.draw(enc.ptr, vertex_count, instance_count, first_vertex, first_instance);
}

pub inline fn drawIndexed(
    enc: RenderBundleEncoder,
    index_count: u32,
    instance_count: u32,
    first_index: u32,
    base_vertex: i32,
    first_instance: u32,
) void {
    enc.vtable.drawIndexed(enc.ptr, index_count, instance_count, first_index, base_vertex, first_instance);
}

pub inline fn drawIndexedIndirect(enc: RenderBundleEncoder, indirect_buffer: Buffer, indirect_offset: u64) void {
    enc.vtable.drawIndexedIndirect(enc.ptr, indirect_buffer, indirect_offset);
}

pub inline fn drawIndirect(enc: RenderBundleEncoder, indirect_buffer: Buffer, indirect_offset: u64) void {
    enc.vtable.drawIndirect(enc.ptr, indirect_buffer, indirect_offset);
}

pub inline fn finish(enc: RenderBundleEncoder, descriptor: *const RenderBundle.Descriptor) RenderBundle {
    return enc.vtable.finish(enc.ptr, descriptor);
}

pub inline fn insertDebugMarker(enc: RenderBundleEncoder, marker_label: [*:0]const u8) void {
    enc.vtable.insertDebugMarker(enc.ptr, marker_label);
}

pub inline fn popDebugGroup(enc: RenderBundleEncoder) void {
    enc.vtable.popDebugGroup(enc.ptr);
}

pub inline fn pushDebugGroup(enc: RenderBundleEncoder, group_label: [*:0]const u8) void {
    enc.vtable.pushDebugGroup(enc.ptr, group_label);
}

pub inline fn setBindGroup(
    enc: RenderBundleEncoder,
    group_index: u32,
    group: BindGroup,
    dynamic_offsets: []u32,
) void {
    enc.vtable.setBindGroup(enc.ptr, group_index, group, dynamic_offsets);
}

pub inline fn setIndexBuffer(
    enc: RenderBundleEncoder,
    buffer: Buffer,
    format: IndexFormat,
    offset: u64,
    size: u64,
) void {
    enc.vtable.setIndexBuffer(enc.ptr, buffer, format, offset, size);
}

// pub inline fn beginOcclusionQuery(enc: RenderBundleEncoder, query_index: u32) void {
//     enc.vtable.beginOcclusionQuery(enc.ptr, query_index);
// }

// pub inline fn endOcclusionQuery(enc: RenderBundleEncoder) void {
//     enc.vtable.endOcclusionQuery(enc.ptr);
// }

// pub inline fn executeBundles(enc: RenderBundleEncoder, bundles: []RenderBundle) void {
//     enc.vtable.executeBundles(enc.ptr, bundles);
// }

// pub inline fn setBlendConstant(enc: RenderBundleEncoder, color: *const Color) void {
//     enc.vtable.setBlendConstant(enc.ptr, color);
// }

pub inline fn setLabel(enc: RenderBundleEncoder, label: [:0]const u8) void {
    enc.vtable.setLabel(enc.ptr, label);
}

pub inline fn setPipeline(enc: RenderBundleEncoder, pipeline: RenderPipeline) void {
    enc.vtable.setPipeline(enc.ptr, pipeline);
}

// pub inline fn setScissorRect(enc: RenderBundleEncoder, x: u32, y: u32, width: u32, height: u32) void {
//     enc.vtable.setScissorRect(enc.ptr, x, y, width, height);
// }

// pub inline fn setStencilReference(enc: RenderBundleEncoder, ref: u32) void {
//     enc.vtable.setStencilReference(enc.ptr, ref);
// }

// pub inline fn setVertexBuffer(
//     enc: RenderBundleEncoder,
//     slot: u32,
//     buffer: Buffer,
//     offset: u64,
//     size: u64,
// ) void {
//     enc.vtable.setVertexBuffer(enc.ptr, slot, buffer, offset, size);
// }

// pub inline fn setViewport(
//     enc: RenderBundleEncoder,
//     x: f32,
//     y: f32,
//     width: f32,
//     height: f32,
//     min_depth: f32,
//     max_depth: f32,
// ) void {
//     enc.vtable.setViewport(enc.ptr, x, y, width, height, min_depth, max_depth);
// }

// pub inline fn writeTimestamp(enc: RenderBundleEncoder, query_set: QuerySet, query_index: u32) void {
//     enc.vtable.writeTimestamp(enc.ptr, query_set, query_index);
// }

pub const Descriptor = struct {
    label: ?[*:0]const u8 = null,
    color_formats: []Texture.Format,
    depth_stencil_format: Texture.Format,
    sample_count: u32,
    depth_read_only: bool,
    stencil_read_only: bool,
};

test {
    _ = VTable;
    _ = reference;
    _ = release;
    _ = draw;
    _ = drawIndexed;
    _ = drawIndexedIndirect;
    _ = drawIndirect;
    _ = finish;
    _ = insertDebugMarker;
    _ = popDebugGroup;
    _ = pushDebugGroup;
    _ = setBindGroup;
    _ = setIndexBuffer;
    _ = setLabel;
    _ = setPipeline;
    _ = Descriptor;
}
