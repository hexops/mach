const RenderPassEncoder = @import("RenderPassEncoder.zig");
const CommandBuffer = @import("CommandBuffer.zig");

const CommandEncoder = @This();

/// The type erased pointer to the CommandEncoder implementation
/// Equal to c.WGPUCommandEncoder for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    // TODO:
    // beginComputePass: fn (ptr: *anyopaque, descriptor: *const ComputePassDescriptor) void,
    // WGPU_EXPORT WGPUComputePassEncoder wgpuCommandEncoderBeginComputePass(WGPUCommandEncoder commandEncoder, WGPUComputePassDescriptor const * descriptor);
    beginRenderPass: fn (ptr: *anyopaque, descriptor: *const RenderPassEncoder.Descriptor) RenderPassEncoder,
    // clearBuffer: fn (ptr: *anyopaque, buffer: Buffer, offset: u64, size: u64) void,
    // WGPU_EXPORT void wgpuCommandEncoderClearBuffer(WGPUCommandEncoder commandEncoder, WGPUBuffer buffer, uint64_t offset, uint64_t size);
    // copyBufferToBuffer: fn (ptr: *anyopaque, source: Buffer, source_offset: u64, destination: Buffer, destination_offset: u64, size: u64) void,
    // WGPU_EXPORT void wgpuCommandEncoderCopyBufferToBuffer(WGPUCommandEncoder commandEncoder, WGPUBuffer source, uint64_t sourceOffset, WGPUBuffer destination, uint64_t destinationOffset, uint64_t size);
    // copyBufferToTexture: fn (ptr: *anyopaque, source: *const ImageCopyBuffer, destination: *const ImageCopyTexture, copy_size: Extent3D) void,
    // WGPU_EXPORT void wgpuCommandEncoderCopyBufferToTexture(WGPUCommandEncoder commandEncoder, WGPUImageCopyBuffer const * source, WGPUImageCopyTexture const * destination, WGPUExtent3D const * copySize);
    // copyTextureToBuffer: fn (ptr: *anyopaque, source: *const ImageCopyTexture, destination: *const ImageCopyBuffer, copy_size: Extent3D) void,
    // WGPU_EXPORT void wgpuCommandEncoderCopyTextureToBuffer(WGPUCommandEncoder commandEncoder, WGPUImageCopyTexture const * source, WGPUImageCopyBuffer const * destination, WGPUExtent3D const * copySize);
    // copyTextureToTexture: fn (ptr: *anyopaque, source: *const ImageCopyTexture, destination: *const ImageCopyTexture, copy_size: Extent3D) void,
    // WGPU_EXPORT void wgpuCommandEncoderCopyTextureToTexture(WGPUCommandEncoder commandEncoder, WGPUImageCopyTexture const * source, WGPUImageCopyTexture const * destination, WGPUExtent3D const * copySize);
    finish: fn (ptr: *anyopaque, descriptor: ?*const CommandBuffer.Descriptor) CommandBuffer,
    // injectValidationError: fn (ptr: *anyopaque, message: [*:0]const u8) void,
    // WGPU_EXPORT void wgpuCommandEncoderInjectValidationError(WGPUCommandEncoder commandEncoder, char const * message);
    // insertDebugMarker: fn (ptr: *anyopaque, marker_label: [*:0]const u8) void,
    // WGPU_EXPORT void wgpuCommandEncoderInsertDebugMarker(WGPUCommandEncoder commandEncoder, char const * markerLabel);
    // popDebugGroup: fn (ptr: *anyopaque) void,
    // WGPU_EXPORT void wgpuCommandEncoderPopDebugGroup(WGPUCommandEncoder commandEncoder);
    // pushDebugGroup: fn (ptr: *anyopaque, group_label: [*:0]const u8) void,
    // WGPU_EXPORT void wgpuCommandEncoderPushDebugGroup(WGPUCommandEncoder commandEncoder, char const * groupLabel);
    // resolveQuerySet: fn (ptr: *anyopaque, query_set: QuerySet, first_query: u32, query_count: u32, destination: Buffer, destination_offset: u64) void,
    // WGPU_EXPORT void wgpuCommandEncoderResolveQuerySet(WGPUCommandEncoder commandEncoder, WGPUQuerySet querySet, uint32_t firstQuery, uint32_t queryCount, WGPUBuffer destination, uint64_t destinationOffset);
    setLabel: fn (ptr: *anyopaque, label: [:0]const u8) void,
    // TODO: typed buffer pointer?
    // WGPU_EXPORT void wgpuCommandEncoderWriteBuffer(WGPUCommandEncoder commandEncoder, WGPUBuffer buffer, uint64_t bufferOffset, uint8_t const * data, uint64_t size);
    // writeTimestamp: fn (ptr: *anyopaque, query_set: QuerySet, query_index: u32) void,
    // WGPU_EXPORT void wgpuCommandEncoderWriteTimestamp(WGPUCommandEncoder commandEncoder, WGPUQuerySet querySet, uint32_t queryIndex);
};

pub inline fn reference(enc: CommandEncoder) void {
    enc.vtable.reference(enc.ptr);
}

pub inline fn release(enc: CommandEncoder) void {
    enc.vtable.release(enc.ptr);
}

pub inline fn finish(enc: CommandEncoder, descriptor: ?*const CommandBuffer.Descriptor) CommandBuffer {
    return enc.vtable.finish(enc.ptr, descriptor);
}

pub inline fn setLabel(enc: CommandEncoder, label: [:0]const u8) void {
    enc.vtable.setLabel(enc.ptr, label);
}

pub inline fn beginRenderPass(enc: CommandEncoder, descriptor: *const RenderPassEncoder.Descriptor) RenderPassEncoder {
    return enc.vtable.beginRenderPass(enc.ptr, descriptor);
}

pub const Descriptor = struct {
    label: ?[*:0]const u8 = null,
};

test {
    _ = VTable;
    _ = reference;
    _ = release;
    _ = beginRenderPass;
    _ = Descriptor;
}
