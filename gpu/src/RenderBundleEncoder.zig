const Texture = @import("Texture.zig");

const RenderBundleEncoder = @This();

/// The type erased pointer to the RenderBundleEncoder implementation
/// Equal to c.WGPURenderBundleEncoder for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    // draw: fn (
    //     ptr: *anyopaque,
    //     vertex_count: u32,
    //     instance_count: u32,
    //     first_vertex: u32,
    //     first_instance: u32,
    // ) void,
    // WGPU_EXPORT void wgpuRenderBundleEncoderDraw(WGPURenderBundleEncoder renderBundleEncoder, uint32_t vertexCount, uint32_t instanceCount, uint32_t firstVertex, uint32_t firstInstance);
    // drawIndexed: fn (
    //     ptr: *anyopaque,
    //     index_count: u32,
    //     instance_count: u32,
    //     first_index: u32,
    //     base_vertex: i32,
    //     first_instance: u32,
    // ) void,
    // WGPU_EXPORT void wgpuRenderBundleEncoderDrawIndexed(WGPURenderBundleEncoder renderBundleEncoder, uint32_t indexCount, uint32_t instanceCount, uint32_t firstIndex, int32_t baseVertex, uint32_t firstInstance);
    // drawIndexedIndirect: fn (ptr: *anyopaque, indirect_buffer: Buffer, indirect_offset: u64) void,
    // WGPU_EXPORT void wgpuRenderBundleEncoderDrawIndexedIndirect(WGPURenderBundleEncoder renderBundleEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
    // drawIndirect: fn (ptr: *anyopaque, indirect_buffer: Buffer, indirect_offset: u64) void,
    // WGPU_EXPORT void wgpuRenderBundleEncoderDrawIndirect(WGPURenderBundleEncoder renderBundleEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
    // finish: fn (ptr: *anyopaque, descriptor: *const RenderBundle.Descriptor) void,
    // WGPU_EXPORT WGPURenderBundle wgpuRenderBundleEncoderFinish(WGPURenderBundleEncoder renderBundleEncoder, WGPURenderBundleDescriptor const * descriptor);
    // insertDebugMarker: fn (ptr: *anyopaque, marker_label: [*:0]const u8) void,
    // WGPU_EXPORT void wgpuRenderBundleEncoderInsertDebugMarker(WGPURenderBundleEncoder renderBundleEncoder, char const * markerLabel);
    // popDebugGroup: fn (ptr: *anyopaque) void,
    // WGPU_EXPORT void wgpuRenderBundleEncoderPopDebugGroup(WGPURenderBundleEncoder renderBundleEncoder);
    // pushDebugGroup: fn (ptr: *anyopaque, group_label: [*:0]const u8) void,
    // WGPU_EXPORT void wgpuRenderBundleEncoderPushDebugGroup(WGPURenderBundleEncoder renderBundleEncoder, char const * groupLabel);
    // setBindGroup: fn (ptr: *anyopaque, group_index: u32, group: BindGroup, dynamic_offsets: []u32) void,
    // WGPU_EXPORT void wgpuRenderBundleEncoderSetBindGroup(WGPURenderBundleEncoder renderBundleEncoder, uint32_t groupIndex, WGPUBindGroup group, uint32_t dynamicOffsetCount, uint32_t const * dynamicOffsets);
    // setIndexBuffer: fn (ptr: *anyopaque, buffer: Buffer, format: IndexFormat, offset: u64, size: u64) void,
    // WGPU_EXPORT void wgpuRenderBundleEncoderSetIndexBuffer(WGPURenderBundleEncoder renderBundleEncoder, WGPUBuffer buffer, WGPUIndexFormat format, uint64_t offset, uint64_t size);
    setLabel: fn (ptr: *anyopaque, label: [:0]const u8) void,
    // setPipeline: fn (ptr: *anyopaque, pipeline: RenderPipeline) void,
    // WGPU_EXPORT void wgpuRenderBundleEncoderSetPipeline(WGPURenderBundleEncoder renderBundleEncoder, WGPURenderPipeline pipeline);
    // setVertexBuffer: fn (ptr: *anyopaque, slot: u32, buffer: Buffer, offset: u64, size: u64) void,
    // WGPU_EXPORT void wgpuRenderBundleEncoderSetVertexBuffer(WGPURenderBundleEncoder renderBundleEncoder, uint32_t slot, WGPUBuffer buffer, uint64_t offset, uint64_t size);
};

pub inline fn reference(enc: RenderBundleEncoder) void {
    enc.vtable.reference(enc.ptr);
}

pub inline fn release(enc: RenderBundleEncoder) void {
    enc.vtable.release(enc.ptr);
}

pub inline fn setLabel(enc: RenderBundleEncoder, label: [:0]const u8) void {
    enc.vtable.setLabel(enc.ptr, label);
}

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
    _ = Descriptor;
}
