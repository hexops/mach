const QuerySet = @import("QuerySet.zig");
const RenderPassColorAttachment = @import("structs.zig").RenderPassColorAttachment;
const RenderPassDepthStencilAttachment = @import("structs.zig").RenderPassDepthStencilAttachment;
const RenderPassTimestampWrite = @import("structs.zig").RenderPassTimestampWrite;

const RenderPassEncoder = @This();

/// The type erased pointer to the RenderPassEncoder implementation
/// Equal to c.WGPURenderPassEncoder for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    // TODO:
    // WGPU_EXPORT void wgpuRenderPassEncoderBeginOcclusionQuery(WGPURenderPassEncoder renderPassEncoder, uint32_t queryIndex);
    // WGPU_EXPORT void wgpuRenderPassEncoderDraw(WGPURenderPassEncoder renderPassEncoder, uint32_t vertexCount, uint32_t instanceCount, uint32_t firstVertex, uint32_t firstInstance);
    // WGPU_EXPORT void wgpuRenderPassEncoderDrawIndexed(WGPURenderPassEncoder renderPassEncoder, uint32_t indexCount, uint32_t instanceCount, uint32_t firstIndex, int32_t baseVertex, uint32_t firstInstance);
    // WGPU_EXPORT void wgpuRenderPassEncoderDrawIndexedIndirect(WGPURenderPassEncoder renderPassEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
    // WGPU_EXPORT void wgpuRenderPassEncoderDrawIndirect(WGPURenderPassEncoder renderPassEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
    // WGPU_EXPORT void wgpuRenderPassEncoderEnd(WGPURenderPassEncoder renderPassEncoder);
    // WGPU_EXPORT void wgpuRenderPassEncoderEndOcclusionQuery(WGPURenderPassEncoder renderPassEncoder);
    // WGPU_EXPORT void wgpuRenderPassEncoderEndPass(WGPURenderPassEncoder renderPassEncoder);
    // WGPU_EXPORT void wgpuRenderPassEncoderExecuteBundles(WGPURenderPassEncoder renderPassEncoder, uint32_t bundlesCount, WGPURenderBundle const * bundles);
    // WGPU_EXPORT void wgpuRenderPassEncoderInsertDebugMarker(WGPURenderPassEncoder renderPassEncoder, char const * markerLabel);
    // WGPU_EXPORT void wgpuRenderPassEncoderPopDebugGroup(WGPURenderPassEncoder renderPassEncoder);
    // WGPU_EXPORT void wgpuRenderPassEncoderPushDebugGroup(WGPURenderPassEncoder renderPassEncoder, char const * groupLabel);
    // WGPU_EXPORT void wgpuRenderPassEncoderSetBindGroup(WGPURenderPassEncoder renderPassEncoder, uint32_t groupIndex, WGPUBindGroup group, uint32_t dynamicOffsetCount, uint32_t const * dynamicOffsets);
    // WGPU_EXPORT void wgpuRenderPassEncoderSetBlendConstant(WGPURenderPassEncoder renderPassEncoder, WGPUColor const * color);
    // WGPU_EXPORT void wgpuRenderPassEncoderSetIndexBuffer(WGPURenderPassEncoder renderPassEncoder, WGPUBuffer buffer, WGPUIndexFormat format, uint64_t offset, uint64_t size);
    setLabel: fn (ptr: *anyopaque, label: [:0]const u8) void,
    // WGPU_EXPORT void wgpuRenderPassEncoderSetPipeline(WGPURenderPassEncoder renderPassEncoder, WGPURenderPipeline pipeline);
    // WGPU_EXPORT void wgpuRenderPassEncoderSetScissorRect(WGPURenderPassEncoder renderPassEncoder, uint32_t x, uint32_t y, uint32_t width, uint32_t height);
    // WGPU_EXPORT void wgpuRenderPassEncoderSetStencilReference(WGPURenderPassEncoder renderPassEncoder, uint32_t reference);
    // WGPU_EXPORT void wgpuRenderPassEncoderSetVertexBuffer(WGPURenderPassEncoder renderPassEncoder, uint32_t slot, WGPUBuffer buffer, uint64_t offset, uint64_t size);
    // WGPU_EXPORT void wgpuRenderPassEncoderSetViewport(WGPURenderPassEncoder renderPassEncoder, float x, float y, float width, float height, float minDepth, float maxDepth);
    // WGPU_EXPORT void wgpuRenderPassEncoderWriteTimestamp(WGPURenderPassEncoder renderPassEncoder, WGPUQuerySet querySet, uint32_t queryIndex);
};

pub inline fn reference(pass: RenderPassEncoder) void {
    pass.vtable.reference(pass.ptr);
}

pub inline fn release(pass: RenderPassEncoder) void {
    pass.vtable.release(pass.ptr);
}

pub inline fn setLabel(pass: RenderPassEncoder, label: [:0]const u8) void {
    pass.vtable.setLabel(pass.ptr, label);
}

pub const Descriptor = struct {
    label: ?[*:0]const u8 = null,
    color_attachments: []const RenderPassColorAttachment,
    depth_stencil_attachment: ?*const RenderPassDepthStencilAttachment,
    occlusion_query_set: ?QuerySet = null,
    timestamp_writes: ?[]RenderPassTimestampWrite = null,
};

test "syntax" {
    _ = VTable;
    _ = reference;
    _ = release;
    _ = Descriptor;
}
