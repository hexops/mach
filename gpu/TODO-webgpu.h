// WGPU_EXPORT bool wgpuAdapterHasFeature(WGPUAdapter adapter, WGPUFeatureName feature);
export fn wgpuAdapterHasFeature(adapter: gpu.Adapter, feature: gpu.FeatureName) bool {
assertDecl(Impl, "adapterHasFeature", fn (adapter: gpu.Adapter, feature: gpu.FeatureName) callconv(.Inline) bool);

// NOTE: descriptor is nullable, see https://bugs.chromium.org/p/dawn/issues/detail?id=1502
// WGPU_EXPORT void wgpuAdapterRequestDevice(WGPUAdapter adapter, WGPUDeviceDescriptor const * descriptor, WGPURequestDeviceCallback callback, void * userdata);
export fn wgpuAdapterRequestDevice(adapter: gpu.Adapter, descriptor: ?*const gpu.DeviceDescriptor, callback: gpu.RequestDeviceCallback, userdata: *anyopaque) void {
assertDecl(Impl, "adapterRequestDevice", fn (adapter: gpu.Adapter, descriptor: ?*const gpu.DeviceDescriptor, callback: gpu.RequestDeviceCallback, userdata: *anyopaque) callconv(.Inline) void);

// WGPU_EXPORT void wgpuAdapterReference(WGPUAdapter adapter);
export fn wgpuAdapterReference(adapter: gpu.Adapter) void {
assertDecl(Impl, "adapterReference", fn (adapter: gpu.Adapter) callconv(.Inline) void);

// WGPU_EXPORT void wgpuAdapterRelease(WGPUAdapter adapter);
export fn wgpuAdapterRelease(adapter: gpu.Adapter) void {
assertDecl(Impl, "adapterRelease", fn (adapter: gpu.Adapter) callconv(.Inline) void);

// WGPU_EXPORT void wgpuBindGroupSetLabel(WGPUBindGroup bindGroup, char const * label);
export fn wgpuBindGroupSetLabel(bind_group: gpu.BindGroup, label: [*:0]const u8) void {
assertDecl(Impl, "bindGroupSetLabel", fn (bind_group: gpu.BindGroup, label: [*:0]const u8) callconv(.Inline) void);

// WGPU_EXPORT void wgpuBindGroupReference(WGPUBindGroup bindGroup);
export fn wgpuBindGroupReference(bind_group: gpu.BindGroup) void {
assertDecl(Impl, "bindGroupReference", fn (bind_group: gpu.BindGroup) callconv(.Inline) void);

// WGPU_EXPORT void wgpuBindGroupRelease(WGPUBindGroup bindGroup);
export fn wgpuBindGroupRelease(bind_group: gpu.BindGroup) void {
assertDecl(Impl, "bindGroupRelease", fn (bind_group: gpu.BindGroup) callconv(.Inline) void);

// WGPU_EXPORT void wgpuBindGroupLayoutSetLabel(WGPUBindGroupLayout bindGroupLayout, char const * label);
export fn wgpuBindGroupLayoutSetLabel(bind_group_layout: gpu.BindGroupLayout, label: [*:0]const u8) void {
assertDecl(Impl, "bindGroupLayoutSetLabel", fn (bind_group_layout: gpu.BindGroupLayout, label: [*:0]const u8) callconv(.Inline) void);

// WGPU_EXPORT void wgpuBindGroupLayoutReference(WGPUBindGroupLayout bindGroupLayout);
export fn wgpuBindGroupLayoutReference(bind_group_layout: gpu.BindGroupLayout) void {
assertDecl(Impl, "bindGroupLayoutReference", fn (bind_group_layout: gpu.BindGroupLayout) callconv(.Inline) void);

// WGPU_EXPORT void wgpuBindGroupLayoutRelease(WGPUBindGroupLayout bindGroupLayout);
export fn wgpuBindGroupLayoutRelease(bind_group_layout: gpu.BindGroupLayout) void {
assertDecl(Impl, "bindGroupLayoutRelease", fn (bind_group_layout: gpu.BindGroupLayout) callconv(.Inline) void);

// WGPU_EXPORT void wgpuBufferDestroy(WGPUBuffer buffer);
export fn wgpuBufferDestroy(buffer: gpu.Buffer) void {
assertDecl(Impl, "bufferDestroy", fn (buffer: gpu.Buffer) callconv(.Inline) void);

// WGPU_EXPORT void const * wgpuBufferGetConstMappedRange(WGPUBuffer buffer, size_t offset, size_t size);
export fn wgpuBufferGetConstMappedRange(buffer: gpu.Buffer, offset: usize, size: usize) *const anyopaque {
assertDecl(Impl, "bufferGetConstMappedRange", fn (buffer: gpu.Buffer, offset: usize, size: usize) callconv(.Inline) *const anyopaque);

// WGPU_EXPORT void * wgpuBufferGetMappedRange(WGPUBuffer buffer, size_t offset, size_t size);
export fn wgpuBufferGetMappedRange(buffer: gpu.Buffer, offset: usize, size: usize) *anyopaque {
assertDecl(Impl, "bufferGetMappedRange", fn (buffer: gpu.Buffer, offset: usize, size: usize) callconv(.Inline) *anyopaque);

// WGPU_EXPORT uint64_t wgpuBufferGetSize(WGPUBuffer buffer);
export fn wgpuBufferGetSize(buffer: gpu.Buffer) u64 {
assertDecl(Impl, "bufferGetSize", fn (buffer: gpu.Buffer) callconv(.Inline) u64);

// WGPU_EXPORT WGPUBufferUsage wgpuBufferGetUsage(WGPUBuffer buffer);
export fn wgpuBufferGetUsage(buffer: gpu.Buffer) gpu.BufferUsage {
assertDecl(Impl, "bufferGetUsage", fn (buffer: gpu.Buffer) callconv(.Inline) gpu.BufferUsage);

// WGPU_EXPORT void wgpuBufferMapAsync(WGPUBuffer buffer, WGPUMapModeFlags mode, size_t offset, size_t size, WGPUBufferMapCallback callback, void * userdata);
export fn wgpuBufferMapAsync(buffer: gpu.Buffer, mode: gpu.MapModeFlags, offset: usize, size: usize, callback: BufferMapCallback, userdata: *anyopaque) u64 {
assertDecl(Impl, "bufferMapAsync", fn (buffer: gpu.Buffer, mode: gpu.MapModeFlags, offset: usize, size: usize, callback: BufferMapCallback, userdata: *anyopaque) callconv(.Inline) u64);

// WGPU_EXPORT void wgpuBufferSetLabel(WGPUBuffer buffer, char const * label);
export fn wgpuBufferSetLabel(buffer: gpu.Buffer, label: [*:0]const u8) void {
assertDecl(Impl, "bufferSetLabel", fn (buffer: gpu.Buffer, label: [*:0]const u8) callconv(.Inline) void);

// WGPU_EXPORT void wgpuBufferUnmap(WGPUBuffer buffer);
export fn wgpuBufferUnmap(buffer: gpu.Buffer) void {
assertDecl(Impl, "bufferUnmap", fn (buffer: gpu.Buffer) callconv(.Inline) void);

// WGPU_EXPORT void wgpuBufferReference(WGPUBuffer buffer);
export fn wgpuBufferReference(buffer: gpu.Buffer) void {
assertDecl(Impl, "bufferReference", fn (buffer: gpu.Buffer) callconv(.Inline) void);

// WGPU_EXPORT void wgpuBufferRelease(WGPUBuffer buffer);
export fn wgpuBufferRelease(buffer: gpu.Buffer) void {
assertDecl(Impl, "bufferRelease", fn (buffer: gpu.Buffer) callconv(.Inline) void);

// WGPU_EXPORT void wgpuCommandBufferSetLabel(WGPUCommandBuffer commandBuffer, char const * label);
export fn wgpuCommandBufferSetLabel(command_buffer: gpu.CommandBuffer, label: [*:0]const u8) void {
assertDecl(Impl, "commandBufferSetLabel", fn (command_buffer: gpu.CommandBuffer, label: [*:0]const u8) callconv(.Inline) void);

// WGPU_EXPORT void wgpuCommandBufferReference(WGPUCommandBuffer commandBuffer);
export fn wgpuCommandBufferReference(command_buffer: gpu.CommandBuffer) void {
assertDecl(Impl, "commandBufferReference", fn (command_buffer: gpu.CommandBuffer) callconv(.Inline) void);

// WGPU_EXPORT void wgpuCommandBufferRelease(WGPUCommandBuffer commandBuffer);
export fn wgpuCommandBufferRelease(command_buffer: gpu.CommandBuffer) void {
assertDecl(Impl, "commandBufferRelease", fn (command_buffer: gpu.CommandBuffer) callconv(.Inline) void);

// WGPU_EXPORT WGPUComputePassEncoder wgpuCommandEncoderBeginComputePass(WGPUCommandEncoder commandEncoder, WGPUComputePassDescriptor const * descriptor /* nullable */);
export fn wgpuCommandEncoderBeginComputePass(command_encoder: gpu.CommandEncoder, descriptor: ?*const gpu.ComputePassDescriptor) gpu.ComputePassEncoder {
assertDecl(Impl, "commandEncoderBeginComputePass", fn (command_encoder: gpu.CommandEncoder, descriptor: ?*const gpu.ComputePassDescriptor) callconv(.Inline) gpu.ComputePassEncoder);

// WGPU_EXPORT WGPURenderPassEncoder wgpuCommandEncoderBeginRenderPass(WGPUCommandEncoder commandEncoder, WGPURenderPassDescriptor const * descriptor);
export fn wgpuCommandEncoderBeginRenderPass(command_encoder: gpu.CommandEncoder, descriptor: *const gpu.RenderPassDescriptor) gpu.RenderPassEncoder {
assertDecl(Impl, "commandEncoderBeginRenderPass", fn (command_encoder: gpu.CommandEncoder, descriptor: *const gpu.RenderPassDescriptor) callconv(.Inline) gpu.RenderPassEncoder);

// WGPU_EXPORT void wgpuCommandEncoderClearBuffer(WGPUCommandEncoder commandEncoder, WGPUBuffer buffer, uint64_t offset, uint64_t size);
export fn wgpuCommandEncoderClearBuffer(command_encoder: gpu.CommandEncoder, buffer: gpu.Buffer, offset: u64, size: u64) void {
assertDecl(Impl, "commandEncoderClearBuffer", fn (command_encoder: gpu.CommandEncoder, buffer: gpu.Buffer, offset: u64, size: u64) callconv(.Inline) void);

// WGPU_EXPORT void wgpuCommandEncoderCopyBufferToBuffer(WGPUCommandEncoder commandEncoder, WGPUBuffer source, uint64_t sourceOffset, WGPUBuffer destination, uint64_t destinationOffset, uint64_t size);
export fn wgpuCommandEncoderCopyBufferToBuffer(command_encoder: gpu.CommandEncoder, source: gpu.Buffer, source_offset: u64, destination: gpu.Buffer, destination_offset: u64, size: u64) void {
assertDecl(Impl, "commandEncoderCopyBufferToBuffer", fn (command_encoder: gpu.CommandEncoder, source: gpu.Buffer, source_offset: u64, destination: gpu.Buffer, destination_offset: u64, size: u64) callconv(.Inline) void);

// WGPU_EXPORT void wgpuCommandEncoderCopyBufferToTexture(WGPUCommandEncoder commandEncoder, WGPUImageCopyBuffer const * source, WGPUImageCopyTexture const * destination, WGPUExtent3D const * copySize);
export fn wgpuCommandEncoderCopyBufferToTexture(command_encoder: gpu.CommandEncoder, source: *const gpu.ImageCopyBuffer, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) void {
assertDecl(Impl, "commandEncoderCopyBufferToTexture", fn (command_encoder: gpu.CommandEncoder, source: *const gpu.ImageCopyBuffer, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) callconv(.Inline) void);

// WGPU_EXPORT void wgpuCommandEncoderCopyTextureToBuffer(WGPUCommandEncoder commandEncoder, WGPUImageCopyTexture const * source, WGPUImageCopyBuffer const * destination, WGPUExtent3D const * copySize);
export fn wgpuCommandEncoderCopyTextureToBuffer(command_encoder: gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyBuffer, copy_size: *const gpu.Extent3D) void {
assertDecl(Impl, "commandEncoderCopyTextureToBuffer", fn (command_encoder: gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyBuffer, copy_size: *const gpu.Extent3D) callconv(.Inline) void);

// WGPU_EXPORT void wgpuCommandEncoderCopyTextureToTexture(WGPUCommandEncoder commandEncoder, WGPUImageCopyTexture const * source, WGPUImageCopyTexture const * destination, WGPUExtent3D const * copySize);
export fn wgpuCommandEncoderCopyTextureToTexture(command_encoder: gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) void {
assertDecl(Impl, "commandEncoderCopyTextureToTexture", fn (command_encoder: gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) callconv(.Inline) void);

// Note: the only difference between this and the non-internal variant is that this one checks
// internal usage.
// WGPU_EXPORT void wgpuCommandEncoderCopyTextureToTextureInternal(WGPUCommandEncoder commandEncoder, WGPUImageCopyTexture const * source, WGPUImageCopyTexture const * destination, WGPUExtent3D const * copySize);
export fn wgpuCommandEncoderCopyTextureToTextureInternal(command_encoder: gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) void {
assertDecl(Impl, "commandEncoderCopyTextureToTextureInternal", fn (command_encoder: gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) callconv(.Inline) void);

// WGPU_EXPORT WGPUCommandBuffer wgpuCommandEncoderFinish(WGPUCommandEncoder commandEncoder, WGPUCommandBufferDescriptor const * descriptor /* nullable */);
export fn wgpuCommandEncoderFinish(command_encoder: gpu.CommandEncoder, descriptor: ?*const gpu.CommandBufferDescriptor) gpu.CommandBuffer {
assertDecl(Impl, "commandEncoderFinish", fn (command_encoder: gpu.CommandEncoder, descriptor: ?*const gpu.CommandBufferDescriptor) callconv(.Inline) gpu.CommandBuffer);

// WGPU_EXPORT void wgpuCommandEncoderInjectValidationError(WGPUCommandEncoder commandEncoder, char const * message);
export fn wgpuCommandEncoderInjectValidationError(command_encoder: gpu.CommandEncoder, message: [*:0]const u8) void {
assertDecl(Impl, "commandEncoderInjectValidationError", fn (command_encoder: gpu.CommandEncoder, message: [*:0]const u8) void);

// WGPU_EXPORT void wgpuCommandEncoderInsertDebugMarker(WGPUCommandEncoder commandEncoder, char const * markerLabel);
export fn wgpuCommandEncoderInsertDebugMarker(command_encoder: gpu.CommandEncoder, marker_label: [*:0]const u8) void {
assertDecl(Impl, "commandEncoderInsertDebugMarker", fn (command_encoder: gpu.CommandEncoder, marker_label: [*:0]const u8) void);

// WGPU_EXPORT void wgpuCommandEncoderPopDebugGroup(WGPUCommandEncoder commandEncoder);
export fn wgpuCommandEncoderPopDebugGroup(command_encoder: gpu.CommandEncoder) void {
assertDecl(Impl, "commandEncoderPopDebugGroup", fn (command_encoder: gpu.CommandEncoder) void);

// WGPU_EXPORT void wgpuCommandEncoderPushDebugGroup(WGPUCommandEncoder commandEncoder, char const * groupLabel);
export fn wgpuCommandEncoderPushDebugGroup(command_encoder: gpu.CommandEncoder, group_label: [*:0]const u8) void {
assertDecl(Impl, "commandEncoderPushDebugGroup", fn (command_encoder: gpu.CommandEncoder, group_label: [*:0]const u8) void);

// WGPU_EXPORT void wgpuCommandEncoderResolveQuerySet(WGPUCommandEncoder commandEncoder, WGPUQuerySet querySet, uint32_t firstQuery, uint32_t queryCount, WGPUBuffer destination, uint64_t destinationOffset);
export fn wgpuCommandEncoderResolveQuerySet(command_encoder: gpu.CommandEncoder, query_set: gpu.QuerySet, first_query: u32, query_count: u32, destination: gpu.Buffer, destination_offset: u64) void {
assertDecl(Impl, "commandEncoderResolveQuerySet", fn (command_encoder: gpu.CommandEncoder, query_set: gpu.QuerySet, first_query: u32, query_count: u32, destination: gpu.Buffer, destination_offset: u64) void);

// WGPU_EXPORT void wgpuCommandEncoderSetLabel(WGPUCommandEncoder commandEncoder, char const * label);
export fn wgpuCommandEncoderSetLabel(command_encoder: gpu.CommandEncoder, label: [*:0]const u8) void {
assertDecl(Impl, "commandEncoderSetLabel", fn (command_encoder: gpu.CommandEncoder, label: [*:0]const u8) callconv(.Inline) void);

// WGPU_EXPORT void wgpuCommandEncoderWriteBuffer(WGPUCommandEncoder commandEncoder, WGPUBuffer buffer, uint64_t bufferOffset, uint8_t const * data, uint64_t size);
export fn wgpuCommandEncoderWriteBuffer(command_encoder: gpu.CommandEncoder, buffer: gpu.Buffer, buffer_offset: u64, data: [*]const u8, size: u64) void {
assertDecl(Impl, "commandEncoderWriteBuffer", fn (command_encoder: gpu.CommandEncoder, buffer: gpu.Buffer, buffer_offset: u64, data: [*]const u8, size: u64) void);

// WGPU_EXPORT void wgpuCommandEncoderWriteTimestamp(WGPUCommandEncoder commandEncoder, WGPUQuerySet querySet, uint32_t queryIndex);
export fn wgpuCommandEncoderWriteTimestamp(command_encoder: gpu.CommandEncoder, query_set: gpu.QuerySet, query_index: u32) void {
assertDecl(Impl, "commandEncoderWriteTimestamp", fn (command_encoder: gpu.CommandEncoder, query_set: gpu.QuerySet, query_index: u32) void);

// WGPU_EXPORT void wgpuCommandEncoderReference(WGPUCommandEncoder commandEncoder);
export fn wgpuCommandEncoderReference(command_encoder: gpu.CommandEncoder) void {
assertDecl(Impl, "commandEncoderReference", fn (command_encoder: gpu.CommandEncoder) callconv(.Inline) void);

// WGPU_EXPORT void wgpuCommandEncoderRelease(WGPUCommandEncoder commandEncoder);
export fn wgpuCommandEncoderRelease(command_encoder: gpu.CommandEncoder) void {
assertDecl(Impl, "commandEncoderRelease", fn (command_encoder: gpu.CommandEncoder) callconv(.Inline) void);

// WGPU_EXPORT void wgpuComputePassEncoderDispatch(WGPUComputePassEncoder computePassEncoder, uint32_t workgroupCountX, uint32_t workgroupCountY, uint32_t workgroupCountZ);
export fn wgpuComputePassEncoderDispatch(compute_pass_encoder: gpu.ComputePassEncoder, workgroup_count_x: u32, workgroup_count_y: u32, workgroup_count_z: u32) void {
assertDecl(Impl, "computePassEncoderDispatch", fn (compute_pass_encoder: gpu.ComputePassEncoder, workgroup_count_x: u32, workgroup_count_y: u32, workgroup_count_z: u32) callconv(.Inline) void);

// WGPU_EXPORT void wgpuComputePassEncoderDispatchIndirect(WGPUComputePassEncoder computePassEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
export fn wgpuComputePassEncoderDispatchIndirect(compute_pass_encoder: gpu.ComputePassEncoder, indirect_buffer: gpu.Buffer, indirect_offset: u64) void {
assertDecl(Impl, "computePassEncoderDispatchIndirect", fn (compute_pass_encoder: gpu.ComputePassEncoder, indirect_buffer: gpu.Buffer, indirect_offset: u64) callconv(.Inline) void);

// WGPU_EXPORT void wgpuComputePassEncoderDispatchWorkgroups(WGPUComputePassEncoder computePassEncoder, uint32_t workgroupCountX, uint32_t workgroupCountY, uint32_t workgroupCountZ);
export fn wgpuComputePassEncoderDispatchWorkgroups(compute_pass_encoder: gpu.ComputePassEncoder, workgroup_count_x: u32, workgroup_count_y: u32, workgroup_count_z: u32) void {
assertDecl(Impl, "computePassEncoderDispatchWorkgroups", fn (compute_pass_encoder: gpu.ComputePassEncoder, workgroup_count_x: u32, workgroup_count_y: u32, workgroup_count_z: u32) callconv(.Inline) void);

// WGPU_EXPORT void wgpuComputePassEncoderDispatchWorkgroupsIndirect(WGPUComputePassEncoder computePassEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
export fn wgpuComputePassEncoderDispatchWorkgroupsIndirect(compute_pass_encoder: gpu.ComputePassEncoder, indirect_buffer: gpu.Buffer, indirect_offset: u64) void {
assertDecl(Impl, "wgpuComputePassEncoderDispatchWorkgroupsIndirect", fn (compute_pass_encoder: gpu.ComputePassEncoder, indirect_buffer: gpu.Buffer, indirect_offset: u64) callconv(.Inline) void);

// WGPU_EXPORT void wgpuComputePassEncoderEnd(WGPUComputePassEncoder computePassEncoder);
export fn wgpuComputePassEncoderEnd(compute_pass_encoder: gpu.ComputePassEncoder) void {
assertDecl(Impl, "computePassEncoderEnd", fn (compute_pass_encoder: gpu.ComputePassEncoder) callconv(.Inline) void);

// WGPU_EXPORT void wgpuComputePassEncoderEndPass(WGPUComputePassEncoder computePassEncoder);
export fn wgpuComputePassEncoderEndPass(compute_pass_encoder: gpu.ComputePassEncoder) void {
assertDecl(Impl, "computePassEncoderEndPass", fn (compute_pass_encoder: gpu.ComputePassEncoder) callconv(.Inline) void);

// WGPU_EXPORT void wgpuComputePassEncoderInsertDebugMarker(WGPUComputePassEncoder computePassEncoder, char const * markerLabel);
export fn wgpuComputePassEncoderInsertDebugMarker(compute_pass_encoder: gpu.ComputePassEncoder, marker_label: [*:0]const u8) void {
assertDecl(Impl, "computePassEncoderInsertDebugMarker", fn (compute_pass_encoder: gpu.ComputePassEncoder, marker_label: [*:0]const u8) callconv(.Inline) void);

// WGPU_EXPORT void wgpuComputePassEncoderPopDebugGroup(WGPUComputePassEncoder computePassEncoder);
export fn wgpuComputePassEncoderPopDebugGroup(compute_pass_encoder: gpu.ComputePassEncoder) void {
assertDecl(Impl, "computePassEncoderPopDebugGroup", fn (compute_pass_encoder: gpu.ComputePassEncoder) callconv(.Inline) void);

// WGPU_EXPORT void wgpuComputePassEncoderPushDebugGroup(WGPUComputePassEncoder computePassEncoder, char const * groupLabel);
export fn wgpuComputePassEncoderPushDebugGroup(compute_pass_encoder: gpu.ComputePassEncoder, group_label: [*:0]const u8) void {
assertDecl(Impl, "computePassEncoderPushDebugGroup", fn (compute_pass_encoder: gpu.ComputePassEncoder, group_label: [*:0]const u8) callconv(.Inline) void);

// WGPU_EXPORT void wgpuComputePassEncoderSetBindGroup(WGPUComputePassEncoder computePassEncoder, uint32_t groupIndex, WGPUBindGroup group, uint32_t dynamicOffsetCount, uint32_t const * dynamicOffsets);
export fn wgpuComputePassEncoderSetBindGroup(compute_pass_encoder: gpu.ComputePassEncoder, group_index: u32, group: gpu.BindGroup, dynamic_offset_count: u32, dynamic_offsets: [*]const u32) void {
assertDecl(Impl, "computePassEncoderSetBindGroup", fn (compute_pass_encoder: gpu.ComputePassEncoder, group_index: u32, group: gpu.BindGroup, dynamic_offset_count: u32, dynamic_offsets: [*]const u32) callconv(.Inline) void);

// WGPU_EXPORT void wgpuComputePassEncoderSetLabel(WGPUComputePassEncoder computePassEncoder, char const * label);
export fn wgpuComputePassEncoderSetLabel(compute_pass_encoder: gpu.ComputePassEncoder, label: [*:0]const u8) void {
assertDecl(Impl, "computePassEncoderSetLabel", fn (compute_pass_encoder: gpu.ComputePassEncoder, label: [*:0]const u8) callconv(.Inline) void);

// WGPU_EXPORT void wgpuComputePassEncoderSetPipeline(WGPUComputePassEncoder computePassEncoder, WGPUComputePipeline pipeline);
export fn wgpuComputePassEncoderSetPipeline(compute_pass_encoder: gpu.ComputePassEncoder, pipeline: gpu.ComputePipeline) void {
assertDecl(Impl, "computePassEncoderSetPipeline", fn (compute_pass_encoder: gpu.ComputePassEncoder, pipeline: gpu.ComputePipeline) callconv(.Inline) void);

// WGPU_EXPORT void wgpuComputePassEncoderWriteTimestamp(WGPUComputePassEncoder computePassEncoder, WGPUQuerySet querySet, uint32_t queryIndex);
export fn wgpuComputePassEncoderWriteTimestamp(compute_pass_encoder: gpu.ComputePassEncoder, pipeline: gpu.ComputePipeline) void {
assertDecl(Impl, "computePassEncoderWriteTimestamp", fn (compute_pass_encoder: gpu.ComputePassEncoder, pipeline: gpu.ComputePipeline) callconv(.Inline) void);

// WGPU_EXPORT void wgpuComputePassEncoderReference(WGPUComputePassEncoder computePassEncoder);
export fn wgpuComputePassEncoderReference(compute_pass_encoder: gpu.ComputePassEncoder) void {
assertDecl(Impl, "computePassEncoderReference", fn (compute_pass_encoder: gpu.ComputePassEncoder) callconv(.Inline) void);

// WGPU_EXPORT void wgpuComputePassEncoderRelease(WGPUComputePassEncoder computePassEncoder);
export fn wgpuComputePassEncoderRelease(compute_pass_encoder: gpu.ComputePassEncoder) void {
assertDecl(Impl, "computePassEncoderRelease", fn (compute_pass_encoder: gpu.ComputePassEncoder) callconv(.Inline) void);

// WGPU_EXPORT WGPUBindGroupLayout wgpuComputePipelineGetBindGroupLayout(WGPUComputePipeline computePipeline, uint32_t groupIndex);
export fn wgpuComputePipelineGetBindGroupLayout(compute_pipeline: gpu.ComputePipeline, group_index: u32) gpu.BindGroupLayout {
assertDecl(Impl, "computePipelineGetBindGroupLayout", fn (compute_pipeline: gpu.ComputePipeline, group_index: u32) callconv(.Inline) gpu.BindGroupLayout);

// WGPU_EXPORT void wgpuComputePipelineSetLabel(WGPUComputePipeline computePipeline, char const * label);
export fn wgpuComputePipelineSetLabel(compute_pipeline: gpu.ComputePipeline, label: [*:0]const u8) void {
assertDecl(Impl, "computePipelineSetLabel", fn (compute_pipeline: gpu.ComputePipeline, label: [*:0]const u8) callconv(.Inline) void);

// WGPU_EXPORT void wgpuComputePipelineReference(WGPUComputePipeline computePipeline);
export fn wgpuComputePipelineReference(compute_pipeline: gpu.ComputePipeline) void {
assertDecl(Impl, "computePipelineReference", fn (compute_pipeline: gpu.ComputePipeline) callconv(.Inline) void);

// WGPU_EXPORT void wgpuComputePipelineRelease(WGPUComputePipeline computePipeline);
export fn wgpuComputePipelineRelease(compute_pipeline: gpu.ComputePipeline) void {
assertDecl(Impl, "computePipelineRelease", fn (compute_pipeline: gpu.ComputePipeline) callconv(.Inline) void);

// WGPU_EXPORT WGPUBindGroup wgpuDeviceCreateBindGroup(WGPUDevice device, WGPUBindGroupDescriptor const * descriptor);
export fn wgpuDeviceCreateBindGroup(device: gpu.Device, descriptor: *const gpu.BindGroupDescriptor) gpu.BindGroup {
assertDecl(Impl, "deviceCreateBindGroup", fn (device: gpu.Device, descriptor: *const gpu.BindGroupDescriptor) callconv(.Inline) gpu.BindGroup);

// WGPU_EXPORT WGPUBindGroupLayout wgpuDeviceCreateBindGroupLayout(WGPUDevice device, WGPUBindGroupLayoutDescriptor const * descriptor);
export fn wgpuDeviceCreateBindGroupLayout(device: gpu.Device, descriptor: *const gpu.BindGroupLayoutDescriptor) gpu.BindGroupLayout {
assertDecl(Impl, "deviceCreateBindGroupLayout", fn (device: gpu.Device, descriptor: *const gpu.BindGroupLayoutDescriptor) callconv(.Inline) gpu.BindGroupLayout);

// WGPU_EXPORT WGPUBuffer wgpuDeviceCreateBuffer(WGPUDevice device, WGPUBufferDescriptor const * descriptor);
export fn wgpuDeviceCreateBindGroup(device: gpu.Device, descriptor: *const gpu.BufferDescriptor) gpu.Buffer {
assertDecl(Impl, "deviceCreateBindGroup", fn (device: gpu.Device, descriptor: *const gpu.BufferDescriptor) callconv(.Inline) gpu.Buffer);

// WGPU_EXPORT WGPUCommandEncoder wgpuDeviceCreateCommandEncoder(WGPUDevice device, WGPUCommandEncoderDescriptor const * descriptor /* nullable */);
export fn wgpuDeviceCreateCommandEncoder(device: gpu.Device, descriptor: ?*const gpu.CommandEncoderDescriptor) gpu.CommandEncoder {
assertDecl(Impl, "deviceCreateCommandEncoder", fn (device: gpu.Device, descriptor: ?*const gpu.CommandEncoderDescriptor) callconv(.Inline) gpu.CommandEncoder);

// WGPU_EXPORT WGPUComputePipeline wgpuDeviceCreateComputePipeline(WGPUDevice device, WGPUComputePipelineDescriptor const * descriptor);
export fn wgpuDeviceCreateComputePipeline(device: gpu.Device, descriptor: *const gpu.ComputePipelineDescriptor) gpu.ComputePipeline {
assertDecl(Impl, "deviceCreateComputePipeline", fn (device: gpu.Device, descriptor: *const gpu.ComputePipelineDescriptor) callconv(.Inline) gpu.ComputePipeline);

// WGPU_EXPORT void wgpuDeviceCreateComputePipelineAsync(WGPUDevice device, WGPUComputePipelineDescriptor const * descriptor, WGPUCreateComputePipelineAsyncCallback callback, void * userdata);
export fn wgpuDeviceCreateComputePipelineAsync(device: gpu.Device, descriptor: *const gpu.ComputePipelineDescriptor, callback: gpu.CreateComputePipelineAsyncCallback, userdata: *anyopaque) void {
assertDecl(Impl, "deviceCreateComputePipelineAsync", fn (device: gpu.Device, descriptor: *const gpu.ComputePipelineDescriptor, callback: gpu.CreateComputePipelineAsyncCallback, userdata: *anyopaque) callconv(.Inline) void);

// WGPU_EXPORT WGPUBuffer wgpuDeviceCreateErrorBuffer(WGPUDevice device);
export fn wgpuDeviceCreateErrorBuffer(device: gpu.Device) gpu.Buffer {
assertDecl(Impl, "deviceCreateErrorBuffer", fn (device: gpu.Device) callconv(.Inline) gpu.Buffer);

// WGPU_EXPORT WGPUExternalTexture wgpuDeviceCreateErrorExternalTexture(WGPUDevice device);
export fn wgpuDeviceCreateErrorExternalTexture(device: gpu.Device) gpu.ExternalTexture {
assertDecl(Impl, "deviceCreateErrorExternalTexture", fn (device: gpu.Device) callconv(.Inline) gpu.ExternalTexture);

// WGPU_EXPORT WGPUExternalTexture wgpuDeviceCreateExternalTexture(WGPUDevice device, WGPUExternalTextureDescriptor const * externalTextureDescriptor);
export fn wgpuDeviceCreateExternalTexture(device: gpu.Device, external_texture_descriptor: *const gpu.ExternalTextureDescriptor) gpu.ExternalTexture {
assertDecl(Impl, "deviceCreateExternalTexture", fn (device: gpu.Device, external_texture_descriptor: *const gpu.ExternalTextureDescriptor) callconv(.Inline) gpu.ExternalTexture);

// WGPU_EXPORT WGPUPipelineLayout wgpuDeviceCreatePipelineLayout(WGPUDevice device, WGPUPipelineLayoutDescriptor const * descriptor);
export fn wgpuDeviceCreatePipelineLayout(device: gpu.Device, pipeline_layout_descriptor: *const gpu.PipelineLayoutDescriptor) gpu.PipelineLayout {
assertDecl(Impl, "deviceCreatePipelineLayout", fn (device: gpu.Device, pipeline_layout_descriptor: *const gpu.PipelineLayoutDescriptor) callconv(.Inline) gpu.PipelineLayout);

// WGPU_EXPORT WGPUQuerySet wgpuDeviceCreateQuerySet(WGPUDevice device, WGPUQuerySetDescriptor const * descriptor);
export fn wgpuDeviceCreateQuerySet(device: gpu.Device, descriptor: *const gpu.QuerySetDescriptor) gpu.QuerySet {
assertDecl(Impl, "deviceCreateQuerySet", fn (device: gpu.Device, descriptor: *const gpu.QuerySetDescriptor) callconv(.Inline) gpu.QuerySet);

// WGPU_EXPORT WGPURenderBundleEncoder wgpuDeviceCreateRenderBundleEncoder(WGPUDevice device, WGPURenderBundleEncoderDescriptor const * descriptor);
export fn wgpuDeviceCreateRenderBundleEncoder(device: gpu.Device, descriptor: *const gpu.RenderBundleEncoderDescriptor) gpu.RenderBundleEncoder {
assertDecl(Impl, "deviceCreateRenderBundleEncoder", fn (device: gpu.Device, descriptor: *const gpu.RenderBundleEncoderDescriptor) callconv(.Inline) gpu.RenderBundleEncoder);

// WGPU_EXPORT WGPURenderPipeline wgpuDeviceCreateRenderPipeline(WGPUDevice device, WGPURenderPipelineDescriptor const * descriptor);
export fn wgpuDeviceCreateRenderPipeline(device: gpu.Device, descriptor: *const gpu.RenderPipelineDescriptor) gpu.RenderPipeline {
assertDecl(Impl, "deviceCreateRenderPipeline", fn (device: gpu.Device, descriptor: *const gpu.RenderPipelineDescriptor) callconv(.Inline) gpu.RenderPipeline);

// WGPU_EXPORT void wgpuDeviceCreateRenderPipelineAsync(WGPUDevice device, WGPURenderPipelineDescriptor const * descriptor, WGPUCreateRenderPipelineAsyncCallback callback, void * userdata);
export fn wgpuDeviceCreateRenderPipelineAsync(device: gpu.Device, descriptor: *const gpu.RenderPipelineDescriptor, callback: gpu.CreateRenderPipelineAsyncCallback, userdata: *anyopaque) void {
assertDecl(Impl, "deviceCreateRenderPipelineAsync", fn (device: gpu.Device, descriptor: *const gpu.RenderPipelineDescriptor, callback: gpu.CreateRenderPipelineAsyncCallback, userdata: *anyopaque) callconv(.Inline) void);

// WGPU_EXPORT WGPUSampler wgpuDeviceCreateSampler(WGPUDevice device, WGPUSamplerDescriptor const * descriptor /* nullable */);
export fn wgpuDeviceCreateRenderPipeline(device: gpu.Device, descriptor: ?*const gpu.SamplerDescriptor) gpu.Sampler {
assertDecl(Impl, "deviceCreateRenderPipeline", fn (device: gpu.Device, descriptor: ?*const gpu.SamplerDescriptor) callconv(.Inline) gpu.Sampler);

// WGPU_EXPORT WGPUShaderModule wgpuDeviceCreateShaderModule(WGPUDevice device, WGPUShaderModuleDescriptor const * descriptor);
export fn wgpuDeviceCreateShaderModule(device: gpu.Device, descriptor: *const gpu.ShaderModuleDescriptor) gpu.ShaderModule {
assertDecl(Impl, "deviceCreateShaderModule", fn (device: gpu.Device, descriptor: *const gpu.ShaderModuleDescriptor) callconv(.Inline) gpu.ShaderModule);

// WGPU_EXPORT WGPUSwapChain wgpuDeviceCreateSwapChain(WGPUDevice device, WGPUSurface surface /* nullable */, WGPUSwapChainDescriptor const * descriptor);
export fn wgpuDeviceCreateShaderModule(device: gpu.Device, surface: ?Surface, descriptor: *const gpu.SwapChainDescriptor) gpu.SwapChain {
assertDecl(Impl, "deviceCreateShaderModule", fn (device: gpu.Device, surface: ?Surface, descriptor: *const gpu.SwapChainDescriptor) callconv(.Inline) gpu.SwapChain);

// WGPU_EXPORT WGPUTexture wgpuDeviceCreateTexture(WGPUDevice device, WGPUTextureDescriptor const * descriptor);
export fn wgpuDeviceCreateTexture(device: gpu.Device, descriptor: *const gpu.TextureDescriptor) gpu.Texture {
assertDecl(Impl, "deviceCreateTexture", fn (device: gpu.Device, descriptor: *const gpu.TextureDescriptor) callconv(.Inline) gpu.Texture);

// WGPU_EXPORT void wgpuDeviceDestroy(WGPUDevice device);
export fn wgpuDeviceDestroy(device: gpu.Device) void {
assertDecl(Impl, "deviceDestroy", fn (device: gpu.Device) callconv(.Inline) void);

// WGPU_EXPORT size_t wgpuDeviceEnumerateFeatures(WGPUDevice device, WGPUFeatureName * features);
export fn wgpuDeviceEnumerateFeatures(device: gpu.Device, features: [*]gpu.FeatureName) usize {
assertDecl(Impl, "deviceEnumerateFeatures", fn (device: gpu.Device, features: [*]gpu.FeatureName) callconv(.Inline) usize);

// WGPU_EXPORT bool wgpuDeviceGetLimits(WGPUDevice device, WGPUSupportedLimits * limits);
export fn wgpuDeviceGetLimits(device: gpu.Device, limits: *gpu.SupportedLimits) bool {
assertDecl(Impl, "deviceGetLimits", fn (device: gpu.Device, limits: *gpu.SupportedLimits) callconv(.Inline) bool);

// WGPU_EXPORT WGPUQueue wgpuDeviceGetQueue(WGPUDevice device);
export fn wgpuDeviceGetQueue(device: gpu.Device) gpu.Queue {
assertDecl(Impl, "deviceGetQueue", fn (device: gpu.Device) callconv(.Inline) gpu.Queue);

// WGPU_EXPORT bool wgpuDeviceHasFeature(WGPUDevice device, WGPUFeatureName feature);
export fn wgpuDeviceHasFeature(device: gpu.Device, feature: gpu.FeatureName) bool {
assertDecl(Impl, "deviceHasFeature", fn (device: gpu.Device, feature: gpu.FeatureName) callconv(.Inline) bool);

// WGPU_EXPORT void wgpuDeviceInjectError(WGPUDevice device, WGPUErrorType type, char const * message);
export fn wgpuDeviceInjectError(device: gpu.Device, typ: gpu.ErrorType, message: [*:0]const u8) void {
assertDecl(Impl, "deviceInjectError", fn (device: gpu.Device, typ: gpu.ErrorType, message: [*:0]const u8) callconv(.Inline) void);

// WGPU_EXPORT void wgpuDeviceLoseForTesting(WGPUDevice device);
export fn wgpuDeviceLoseForTesting(device: gpu.Device) void {
assertDecl(Impl, "deviceLoseForTesting", fn (device: gpu.Device) callconv(.Inline) void);

// WGPU_EXPORT bool wgpuDevicePopErrorScope(WGPUDevice device, WGPUErrorCallback callback, void * userdata);
export fn wgpuDevicePopErrorScope(device: gpu.Device, callback: gpu.ErrorCallback, userdata: *anyopaque) bool {
assertDecl(Impl, "devicePopErrorScope", fn (device: gpu.Device, callback: gpu.ErrorCallback, userdata: *anyopaque) callconv(.Inline) bool);

// WGPU_EXPORT void wgpuDevicePushErrorScope(WGPUDevice device, WGPUErrorFilter filter);
export fn wgpuDevicePushErrorScope(device: gpu.Device, filter: gpu.ErrorFilter) void {
assertDecl(Impl, "devicePushErrorScope", fn (device: gpu.Device, filter: gpu.ErrorFilter) callconv(.Inline) void);

// WGPU_EXPORT void wgpuDeviceSetDeviceLostCallback(WGPUDevice device, WGPUDeviceLostCallback callback, void * userdata);
export fn wgpuDeviceSetDeviceLostCallback(device: gpu.Device, callback: gpu.DeviceLostCallback, userdata: *anyopaque) void {
assertDecl(Impl, "deviceSetDeviceLostCallback", fn (device: gpu.Device, callback: gpu.DeviceLostCallback, userdata: *anyopaque) callconv(.Inline) void);

// WGPU_EXPORT void wgpuDeviceSetLabel(WGPUDevice device, char const * label);
export fn wgpuDeviceSetLabel(device: gpu.Device, label: [*:0]const u8) void {
assertDecl(Impl, "deviceSetLabel", fn (device: gpu.Device, label: [*:0]const u8) callconv(.Inline) void);

// WGPU_EXPORT void wgpuDeviceSetLoggingCallback(WGPUDevice device, WGPULoggingCallback callback, void * userdata);
export fn wgpuDeviceSetLoggingCallback(device: gpu.Device, callback: gpu.LoggingCallback, userdata: *anyopaque) void {
assertDecl(Impl, "deviceSetLoggingCallback", fn (device: gpu.Device, callback: gpu.LoggingCallback, userdata: *anyopaque) callconv(.Inline) void);

// WGPU_EXPORT void wgpuDeviceSetUncapturedErrorCallback(WGPUDevice device, WGPUErrorCallback callback, void * userdata);
export fn wgpuDeviceSetUncapturedErrorCallback(device: gpu.Device, callback: gpu.ErrorCallback, userdata: *anyopaque) void {
assertDecl(Impl, "deviceSetUncapturedErrorCallback", fn (device: gpu.Device, callback: gpu.ErrorCallback, userdata: *anyopaque) callconv(.Inline) void);

// WGPU_EXPORT void wgpuDeviceTick(WGPUDevice device);
export fn wgpuDeviceTick(device: gpu.Device) void {
assertDecl(Impl, "deviceTick", fn (device: gpu.Device) callconv(.Inline) void);

// WGPU_EXPORT void wgpuDeviceReference(WGPUDevice device);
export fn wgpuDeviceReference(device: gpu.Device) void {
assertDecl(Impl, "deviceReference", fn (device: gpu.Device) callconv(.Inline) void);

// WGPU_EXPORT void wgpuDeviceRelease(WGPUDevice device);
export fn wgpuDeviceRelease(device: gpu.Device) void {
assertDecl(Impl, "deviceRelease", fn (device: gpu.Device) callconv(.Inline) void);

// WGPU_EXPORT void wgpuExternalTextureDestroy(WGPUExternalTexture externalTexture);
export fn wgpuExternalTextureDestroy(external_texture: gpu.ExternalTexture) void {
assertDecl(Impl, "externalTextureDestroy", fn (external_texture: gpu.ExternalTexture) callconv(.Inline) void);

// WGPU_EXPORT void wgpuExternalTextureSetLabel(WGPUExternalTexture externalTexture, char const * label);
export fn wgpuExternalTextureSetLabel(external_texture: gpu.ExternalTexture, label: [*:0]const u8) void {
assertDecl(Impl, "externalTextureSetLabel", fn (external_texture: gpu.ExternalTexture, label: [*:0]const u8) callconv(.Inline) void);

// WGPU_EXPORT void wgpuExternalTextureReference(WGPUExternalTexture externalTexture);
export fn wgpuExternalTextureReference(external_texture: gpu.ExternalTexture) void {
assertDecl(Impl, "externalTextureReference", fn (external_texture: gpu.ExternalTexture) callconv(.Inline) void);

// WGPU_EXPORT void wgpuExternalTextureRelease(WGPUExternalTexture externalTexture);
export fn wgpuExternalTextureRelease(external_texture: gpu.ExternalTexture) void {
assertDecl(Impl, "externalTextureRelease", fn (external_texture: gpu.ExternalTexture) callconv(.Inline) void);

// WGPU_EXPORT WGPUSurface wgpuInstanceCreateSurface(WGPUInstance instance, WGPUSurfaceDescriptor const * descriptor);
export fn wgpuInstanceCreateSurface(instance: gpu.Instance, descriptor: *const gpu.SurfaceDescriptor) gpu.Surface {
assertDecl(Impl, "instanceCreateSurface", fn (instance: gpu.Instance, descriptor: *const gpu.SurfaceDescriptor) callconv(.Inline) gpu.Surface);

// WGPU_EXPORT void wgpuInstanceRequestAdapter(WGPUInstance instance, WGPURequestAdapterOptions const * options, WGPURequestAdapterCallback callback, void * userdata);
export fn wgpuInstanceRequestAdapter(instance: gpu.Instance, options: *const gpu.RequestAdapterOptions, callback: gpu.RequestAdapterCallback, userdata: *anyopaque) void {
assertDecl(Impl, "instanceRequestAdapter", fn (instance: gpu.Instance, options: *const gpu.RequestAdapterOptions, callback: gpu.RequestAdapterCallback, userdata: *anyopaque) callconv(.Inline) void);

// WGPU_EXPORT void wgpuInstanceReference(WGPUInstance instance);
export fn wgpuInstanceReference(instance: gpu.Instance) void {
assertDecl(Impl, "instanceReference", fn (instance: gpu.Instance) callconv(.Inline) void);

// WGPU_EXPORT void wgpuInstanceRelease(WGPUInstance instance);
export fn wgpuInstanceRelease(instance: gpu.Instance) void {
assertDecl(Impl, "instanceRelease", fn (instance: gpu.Instance) callconv(.Inline) void);

// WGPU_EXPORT void wgpuPipelineLayoutSetLabel(WGPUPipelineLayout pipelineLayout, char const * label);
export fn wgpuPipelineLayoutSetLabel(pipeline_layout: gpu.PipelineLayout, label: [*:0]const u8) void {
assertDecl(Impl, "pipelineLayoutSetLabel", fn (pipeline_layout: gpu.PipelineLayout, label: [*:0]const u8) callconv(.Inline) void);

// WGPU_EXPORT void wgpuPipelineLayoutReference(WGPUPipelineLayout pipelineLayout);
export fn wgpuPipelineLayoutReference(pipeline_layout: gpu.PipelineLayout) void {
assertDecl(Impl, "pipelineLayoutReference", fn (pipeline_layout: gpu.PipelineLayout) callconv(.Inline) void);

// WGPU_EXPORT void wgpuPipelineLayoutRelease(WGPUPipelineLayout pipelineLayout);
export fn wgpuPipelineLayoutRelease(pipeline_layout: gpu.PipelineLayout) void {
assertDecl(Impl, "pipelineLayoutRelease", fn (pipeline_layout: gpu.PipelineLayout) callconv(.Inline) void);

// WGPU_EXPORT void wgpuQuerySetDestroy(WGPUQuerySet querySet);
export fn wgpuQuerySetDestroy(query_set: gpu.QuerySet) void {
assertDecl(Impl, "querySetDestroy", fn (query_set: gpu.QuerySet) callconv(.Inline) void);

// WGPU_EXPORT uint32_t wgpuQuerySetGetCount(WGPUQuerySet querySet);
export fn wgpuQuerySetGetCount(query_set: gpu.QuerySet) u32 {
assertDecl(Impl, "querySetGetCount", fn (query_set: gpu.QuerySet) callconv(.Inline) u32);

// WGPU_EXPORT WGPUQueryType wgpuQuerySetGetType(WGPUQuerySet querySet);
export fn wgpuQuerySetGetType(query_set: gpu.QuerySet) gpu.QueryType {
assertDecl(Impl, "querySetGetType", fn (query_set: gpu.QuerySet) callconv(.Inline) gpu.QueryType);

// WGPU_EXPORT void wgpuQuerySetSetLabel(WGPUQuerySet querySet, char const * label);
export fn wgpuQuerySetSetLabel(query_set: gpu.QuerySet, label: [*:0]const u8) void {
assertDecl(Impl, "querySetSetLabel", fn (query_set: gpu.QuerySet, label: [*:0]const u8) callconv(.Inline) void);

// WGPU_EXPORT void wgpuQuerySetReference(WGPUQuerySet querySet);
export fn wgpuQuerySetReference(query_set: gpu.QuerySet) void {
assertDecl(Impl, "querySetReference", fn (query_set: gpu.QuerySet) callconv(.Inline) void);

// WGPU_EXPORT void wgpuQuerySetRelease(WGPUQuerySet querySet);
export fn wgpuQuerySetRelease(query_set: gpu.QuerySet) void {
assertDecl(Impl, "querySetRelease", fn (query_set: gpu.QuerySet) callconv(.Inline) void);

// WGPU_EXPORT void wgpuQueueCopyTextureForBrowser(WGPUQueue queue, WGPUImageCopyTexture const * source, WGPUImageCopyTexture const * destination, WGPUExtent3D const * copySize, WGPUCopyTextureForBrowserOptions const * options);
export fn wgpuQueueCopyTextureForBrowser(queue: gpu.Queue, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D, options: *const gpu.CopyTextureForBrowserOptions) void {
assertDecl(Impl, "queueCopyTextureForBrowser", fn (queue: gpu.Queue, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D, options: *const gpu.CopyTextureForBrowserOptions) callconv(.Inline) void);

// WGPU_EXPORT void wgpuQueueOnSubmittedWorkDone(WGPUQueue queue, uint64_t signalValue, WGPUQueueWorkDoneCallback callback, void * userdata);
export fn wgpuQueueOnSubmittedWorkDone(queue: gpu.Queue, signal_value: u64, callback: gpu.QueueWorkDoneCallback, userdata: *anyopaque) void {
assertDecl(Impl, "queueOnSubmittedWorkDone", fn (queue: gpu.Queue, signal_value: u64, callback: gpu.QueueWorkDoneCallback, userdata: *anyopaque) callconv(.Inline) void);

// WGPU_EXPORT void wgpuQueueSetLabel(WGPUQueue queue, char const * label);
export fn wgpuQueueSetLabel(queue: gpu.Queue, label: [*:0]const u8) void {
assertDecl(Impl, "queueSetLabel", fn (queue: gpu.Queue, label: [*:0]const u8) callconv(.Inline) void);

// WGPU_EXPORT void wgpuQueueSubmit(WGPUQueue queue, uint32_t commandCount, WGPUCommandBuffer const * commands);
export fn wgpuQueueSubmit(queue: gpu.Queue, command_count: u32, commands: [*]gpu.CommandBuffer) void {
assertDecl(Impl, "queueSubmit", fn (queue: gpu.Queue, command_count: u32, commands: [*]gpu.CommandBuffer) callconv(.Inline) void);

// WGPU_EXPORT void wgpuQueueWriteBuffer(WGPUQueue queue, WGPUBuffer buffer, uint64_t bufferOffset, void const * data, size_t size);
export fn wgpuQueueWriteBuffer(queue: gpu.Queue, buffer: gpu.Buffer, buffer_offset: u64, data: *anyopaque, size: usize) void {
assertDecl(Impl, "queueWriteBuffer", fn (queue: gpu.Queue, buffer: gpu.Buffer, buffer_offset: u64, data: *anyopaque, size: usize) callconv(.Inline) void);

// WGPU_EXPORT void wgpuQueueWriteTexture(WGPUQueue queue, WGPUImageCopyTexture const * destination, void const * data, size_t dataSize, WGPUTextureDataLayout const * dataLayout, WGPUExtent3D const * writeSize);
export fn wgpuQueueWriteTexture(queue: gpu.Queue, data: *anyopaque, data_size: usize, data_layout: *const gpu.TextureDataLayout, write_size: *const gpu.Extent3D) void {
assertDecl(Impl, "queueWriteTexture", fn (queue: gpu.Queue, data: *anyopaque, data_size: usize, data_layout: *const gpu.TextureDataLayout, write_size: *const gpu.Extent3D) callconv(.Inline) void);

// WGPU_EXPORT void wgpuQueueReference(WGPUQueue queue);
export fn wgpuQueueReference(queue: gpu.Queue) void {
assertDecl(Impl, "queueReference", fn (queue: gpu.Queue) callconv(.Inline) void);

// WGPU_EXPORT void wgpuQueueRelease(WGPUQueue queue);
export fn wgpuQueueRelease(queue: gpu.Queue) void {
assertDecl(Impl, "queueRelease", fn (queue: gpu.Queue) callconv(.Inline) void);

// WGPU_EXPORT void wgpuRenderBundleReference(WGPURenderBundle renderBundle);
export fn wgpuRenderBundleReference(render_bundle: gpu.RenderBundle) void {
assertDecl(Impl, "renderBundleReference", fn (render_bundle: gpu.RenderBundle) callconv(.Inline) void);

// WGPU_EXPORT void wgpuRenderBundleRelease(WGPURenderBundle renderBundle);
export fn wgpuRenderBundleRelease(render_bundle: gpu.RenderBundle) void {
assertDecl(Impl, "renderBundleRelease", fn (render_bundle: gpu.RenderBundle) callconv(.Inline) void);

// WGPU_EXPORT void wgpuRenderBundleEncoderDraw(WGPURenderBundleEncoder renderBundleEncoder, uint32_t vertexCount, uint32_t instanceCount, uint32_t firstVertex, uint32_t firstInstance);
export fn wgpuRenderBundleEncoderDraw(render_bundle_encoder: gpu.RenderBundleEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {
assertDecl(Impl, "renderBundleEncoderDraw", fn (render_bundle_encoder: gpu.RenderBundleEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) callconv(.Inline) void);

// WGPU_EXPORT void wgpuRenderBundleEncoderDrawIndexed(WGPURenderBundleEncoder renderBundleEncoder, uint32_t indexCount, uint32_t instanceCount, uint32_t firstIndex, int32_t baseVertex, uint32_t firstInstance);
export fn wgpuRenderBundleEncoderDrawIndexed(render_bundle_encoder: gpu.RenderBundleEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: u32, first_instance: u32) void {
assertDecl(Impl, "renderBundleEncoderDrawIndexed", fn (render_bundle_encoder: gpu.RenderBundleEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: u32, first_instance: u32) callconv(.Inline) void);

// WGPU_EXPORT void wgpuRenderBundleEncoderDrawIndexedIndirect(WGPURenderBundleEncoder renderBundleEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
export fn wgpuRenderBundleEncoderDrawIndexedIndirect(render_bundle_encoder: gpu.RenderBundleEncoder, indirect_buffer: gpu.Buffer, indirect_offset: u64) void {
assertDecl(Impl, "renderBundleEncoderDrawIndexedIndirect", fn (render_bundle_encoder: gpu.RenderBundleEncoder, indirect_buffer: gpu.Buffer, indirect_offset: u64) callconv(.Inline) void);

// WGPU_EXPORT void wgpuRenderBundleEncoderDrawIndirect(WGPURenderBundleEncoder renderBundleEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
export fn wgpuRenderBundleEncoderDrawIndirect(render_bundle_encoder: gpu.RenderBundleEncoder, indirect_buffer: gpu.Buffer, indirect_offset: u64) void {
assertDecl(Impl, "renderBundleEncoderDrawIndirect", fn (render_bundle_encoder: gpu.RenderBundleEncoder, indirect_buffer: gpu.Buffer, indirect_offset: u64) callconv(.Inline) void);

// WGPU_EXPORT WGPURenderBundle wgpuRenderBundleEncoderFinish(WGPURenderBundleEncoder renderBundleEncoder, WGPURenderBundleDescriptor const * descriptor /* nullable */);
export fn wgpuRenderBundleEncoderFinish(render_bundle_encoder: gpu.RenderBundleEncoder, descriptor: ?*const gpu.RenderBundleDescriptor) void {
assertDecl(Impl, "renderBundleEncoderFinish", fn (render_bundle_encoder: gpu.RenderBundleEncoder, descriptor: ?*const gpu.RenderBundleDescriptor) callconv(.Inline) void);

// WGPU_EXPORT void wgpuRenderBundleEncoderInsertDebugMarker(WGPURenderBundleEncoder renderBundleEncoder, char const * markerLabel);
export fn wgpuRenderBundleEncoderInsertDebugMarker(render_bundle_encoder: gpu.RenderBundleEncoder, marker_label: [*:0]const u8) void {
assertDecl(Impl, "renderBundleEncoderInsertDebugMarker", fn (render_bundle_encoder: gpu.RenderBundleEncoder, marker_label: [*:0]const u8) callconv(.Inline) void);

// WGPU_EXPORT void wgpuRenderBundleEncoderPopDebugGroup(WGPURenderBundleEncoder renderBundleEncoder);
export fn wgpuRenderBundleEncoderPopDebugGroup(render_bundle_encoder: gpu.RenderBundleEncoder) void {
assertDecl(Impl, "renderBundleEncoderPopDebugGroup", fn (render_bundle_encoder: gpu.RenderBundleEncoder) callconv(.Inline) void);

// WGPU_EXPORT void wgpuRenderBundleEncoderPushDebugGroup(WGPURenderBundleEncoder renderBundleEncoder, char const * groupLabel);
export fn wgpuRenderBundleEncoderPushDebugGroup(render_bundle_encoder: gpu.RenderBundleEncoder, group_label: [*:0]const u8) void {
assertDecl(Impl, "renderBundleEncoderPushDebugGroup", fn (render_bundle_encoder: gpu.RenderBundleEncoder, group_label: [*:0]const u8) callconv(.Inline) void);

// WGPU_EXPORT void wgpuRenderBundleEncoderSetBindGroup(WGPURenderBundleEncoder renderBundleEncoder, uint32_t groupIndex, WGPUBindGroup group, uint32_t dynamicOffsetCount, uint32_t const * dynamicOffsets);
export fn wgpuRenderBundleEncoderSetBindGroup(render_bundle_encoder: gpu.RenderBundleEncoder, group_index: u32, group: gpu.BindGroup, dynamic_offset_count: u32, dynamic_offsets: [*]const u32) void {
assertDecl(Impl, "renderBundleEncoderSetBindGroup", fn (render_bundle_encoder: gpu.RenderBundleEncoder, group_index: u32, group: gpu.BindGroup, dynamic_offset_count: u32, dynamic_offsets: [*]const u32) callconv(.Inline) void);

// WGPU_EXPORT void wgpuRenderBundleEncoderSetIndexBuffer(WGPURenderBundleEncoder renderBundleEncoder, WGPUBuffer buffer, WGPUIndexFormat format, uint64_t offset, uint64_t size);
export fn wgpuRenderBundleEncoderSetIndexBuffer(render_bundle_encoder: gpu.RenderBundleEncoder, buffer: gpu.Buffer, format: gpu.IndexFormat, offset: u64, size: u64) void {
assertDecl(Impl, "renderBundleEncoderSetIndexBuffer", fn (render_bundle_encoder: gpu.RenderBundleEncoder, buffer: gpu.Buffer, format: gpu.IndexFormat, offset: u64, size: u64) callconv(.Inline) void);

// WGPU_EXPORT void wgpuRenderBundleEncoderSetLabel(WGPURenderBundleEncoder renderBundleEncoder, char const * label);
export fn wgpuRenderBundleEncoderSetLabel(render_bundle_encoder: gpu.RenderBundleEncoder, label: [*:0]const u8) void {
assertDecl(Impl, "renderBundleEncoderSetLabel", fn (render_bundle_encoder: gpu.RenderBundleEncoder, label: [*:0]const u8) callconv(.Inline) void);

// WGPU_EXPORT void wgpuRenderBundleEncoderSetPipeline(WGPURenderBundleEncoder renderBundleEncoder, WGPURenderPipeline pipeline);
export fn wgpuRenderBundleEncoderSetPipeline(render_bundle_encoder: gpu.RenderBundleEncoder, pipeline: gpu.RenderPipeline) void {
assertDecl(Impl, "renderBundleEncoderSetPipeline", fn (render_bundle_encoder: gpu.RenderBundleEncoder, pipeline: gpu.RenderPipeline) callconv(.Inline) void);

// WGPU_EXPORT void wgpuRenderBundleEncoderSetVertexBuffer(WGPURenderBundleEncoder renderBundleEncoder, uint32_t slot, WGPUBuffer buffer, uint64_t offset, uint64_t size);
export fn wgpuRenderBundleEncoderSetVertexBuffer(render_bundle_encoder: gpu.RenderBundleEncoder, slot: u32, buffer: gpu.Buffer, offset: u64, size: u64) void {
assertDecl(Impl, "renderBundleEncoderSetVertexBuffer", fn (render_bundle_encoder: gpu.RenderBundleEncoder, slot: u32, buffer: gpu.Buffer, offset: u64, size: u64) callconv(.Inline) void);

// WGPU_EXPORT void wgpuRenderBundleEncoderReference(WGPURenderBundleEncoder renderBundleEncoder);
export fn wgpuRenderBundleEncoderReference(render_bundle_encoder: gpu.RenderBundleEncoder) void {
assertDecl(Impl, "renderBundleEncoderReference", fn (render_bundle_encoder: gpu.RenderBundleEncoder) callconv(.Inline) void);

// WGPU_EXPORT void wgpuRenderBundleEncoderRelease(WGPURenderBundleEncoder renderBundleEncoder);
export fn wgpuRenderBundleEncoderRelease(render_bundle_encoder: gpu.RenderBundleEncoder) void {
assertDecl(Impl, "renderBundleEncoderRelease", fn (render_bundle_encoder: gpu.RenderBundleEncoder) callconv(.Inline) void);

WGPU_EXPORT void wgpuRenderPassEncoderBeginOcclusionQuery(WGPURenderPassEncoder renderPassEncoder, uint32_t queryIndex);
WGPU_EXPORT void wgpuRenderPassEncoderDraw(WGPURenderPassEncoder renderPassEncoder, uint32_t vertexCount, uint32_t instanceCount, uint32_t firstVertex, uint32_t firstInstance);
WGPU_EXPORT void wgpuRenderPassEncoderDrawIndexed(WGPURenderPassEncoder renderPassEncoder, uint32_t indexCount, uint32_t instanceCount, uint32_t firstIndex, int32_t baseVertex, uint32_t firstInstance);
WGPU_EXPORT void wgpuRenderPassEncoderDrawIndexedIndirect(WGPURenderPassEncoder renderPassEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
WGPU_EXPORT void wgpuRenderPassEncoderDrawIndirect(WGPURenderPassEncoder renderPassEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
WGPU_EXPORT void wgpuRenderPassEncoderEnd(WGPURenderPassEncoder renderPassEncoder);
WGPU_EXPORT void wgpuRenderPassEncoderEndOcclusionQuery(WGPURenderPassEncoder renderPassEncoder);
WGPU_EXPORT void wgpuRenderPassEncoderEndPass(WGPURenderPassEncoder renderPassEncoder);
WGPU_EXPORT void wgpuRenderPassEncoderExecuteBundles(WGPURenderPassEncoder renderPassEncoder, uint32_t bundlesCount, WGPURenderBundle const * bundles);
WGPU_EXPORT void wgpuRenderPassEncoderInsertDebugMarker(WGPURenderPassEncoder renderPassEncoder, char const * markerLabel);
WGPU_EXPORT void wgpuRenderPassEncoderPopDebugGroup(WGPURenderPassEncoder renderPassEncoder);
WGPU_EXPORT void wgpuRenderPassEncoderPushDebugGroup(WGPURenderPassEncoder renderPassEncoder, char const * groupLabel);
WGPU_EXPORT void wgpuRenderPassEncoderSetBindGroup(WGPURenderPassEncoder renderPassEncoder, uint32_t groupIndex, WGPUBindGroup group, uint32_t dynamicOffsetCount, uint32_t const * dynamicOffsets);
WGPU_EXPORT void wgpuRenderPassEncoderSetBlendConstant(WGPURenderPassEncoder renderPassEncoder, WGPUColor const * color);
WGPU_EXPORT void wgpuRenderPassEncoderSetIndexBuffer(WGPURenderPassEncoder renderPassEncoder, WGPUBuffer buffer, WGPUIndexFormat format, uint64_t offset, uint64_t size);

// WGPU_EXPORT void wgpuRenderPassEncoderSetLabel(WGPURenderPassEncoder renderPassEncoder, char const * label);
export fn wgpuRenderPassEncoderSetLabel(render_pass_encoder: gpu.RenderPassEncoder, label: [*:0]const u8) void {
assertDecl(Impl, "renderPassEncoderSetLabel", fn (render_pass_encoder: gpu.RenderPassEncoder, label: [*:0]const u8) callconv(.Inline) void);

WGPU_EXPORT void wgpuRenderPassEncoderSetPipeline(WGPURenderPassEncoder renderPassEncoder, WGPURenderPipeline pipeline);
WGPU_EXPORT void wgpuRenderPassEncoderSetScissorRect(WGPURenderPassEncoder renderPassEncoder, uint32_t x, uint32_t y, uint32_t width, uint32_t height);
WGPU_EXPORT void wgpuRenderPassEncoderSetStencilReference(WGPURenderPassEncoder renderPassEncoder, uint32_t reference);
WGPU_EXPORT void wgpuRenderPassEncoderSetVertexBuffer(WGPURenderPassEncoder renderPassEncoder, uint32_t slot, WGPUBuffer buffer, uint64_t offset, uint64_t size);
WGPU_EXPORT void wgpuRenderPassEncoderSetViewport(WGPURenderPassEncoder renderPassEncoder, float x, float y, float width, float height, float minDepth, float maxDepth);
WGPU_EXPORT void wgpuRenderPassEncoderWriteTimestamp(WGPURenderPassEncoder renderPassEncoder, WGPUQuerySet querySet, uint32_t queryIndex);

// WGPU_EXPORT void wgpuRenderPassEncoderReference(WGPURenderPassEncoder renderPassEncoder);
export fn wgpuRenderPassEncoderReference(render_pass_encoder: gpu.RenderPassEncoder) void {
assertDecl(Impl, "renderPassEncoderReference", fn (render_pass_encoder: gpu.RenderPassEncoder) callconv(.Inline) void);

// WGPU_EXPORT void wgpuRenderPassEncoderRelease(WGPURenderPassEncoder renderPassEncoder);
export fn wgpuRenderPassEncoderRelease(render_pass_encoder: gpu.RenderPassEncoder) void {
assertDecl(Impl, "renderPassEncoderRelease", fn (render_pass_encoder: gpu.RenderPassEncoder) callconv(.Inline) void);

WGPU_EXPORT WGPUBindGroupLayout wgpuRenderPipelineGetBindGroupLayout(WGPURenderPipeline renderPipeline, uint32_t groupIndex);

// WGPU_EXPORT void wgpuRenderPipelineSetLabel(WGPURenderPipeline renderPipeline, char const * label);
export fn wgpuRenderPipelineSetLabel(render_pipeline: gpu.RenderPipeline, label: [*:0]const u8) void {
assertDecl(Impl, "renderPipelineSetLabel", fn (render_pipeline: gpu.RenderPipeline, label: [*:0]const u8) callconv(.Inline) void);

// WGPU_EXPORT void wgpuRenderPipelineReference(WGPURenderPipeline renderPipeline);
export fn wgpuRenderPipelineReference(render_pipeline: gpu.RenderPipeline) void {
assertDecl(Impl, "renderPipelineReference", fn (render_pipeline: gpu.RenderPipeline) callconv(.Inline) void);

// WGPU_EXPORT void wgpuRenderPipelineRelease(WGPURenderPipeline renderPipeline);
export fn wgpuRenderPipelineRelease(render_pipeline: gpu.RenderPipeline) void {
assertDecl(Impl, "renderPipelineRelease", fn (render_pipeline: gpu.RenderPipeline) callconv(.Inline) void);

// WGPU_EXPORT void wgpuSamplerSetLabel(WGPUSampler sampler, char const * label);
export fn wgpuSamplerSetLabel(sampler: gpu.Sampler, label: [*:0]const u8) void {
assertDecl(Impl, "samplerSetLabel", fn (sampler: gpu.Sampler, label: [*:0]const u8) callconv(.Inline) void);

// WGPU_EXPORT void wgpuSamplerReference(WGPUSampler sampler);
export fn wgpuSamplerReference(sampler: gpu.Sampler) void {
assertDecl(Impl, "samplerReference", fn (sampler: gpu.Sampler) callconv(.Inline) void);

// WGPU_EXPORT void wgpuSamplerRelease(WGPUSampler sampler);
export fn wgpuSamplerRelease(sampler: gpu.Sampler) void {
assertDecl(Impl, "samplerRelease", fn (sampler: gpu.Sampler) callconv(.Inline) void);

WGPU_EXPORT void wgpuShaderModuleGetCompilationInfo(WGPUShaderModule shaderModule, WGPUCompilationInfoCallback callback, void * userdata);

// WGPU_EXPORT void wgpuShaderModuleSetLabel(WGPUShaderModule shaderModule, char const * label);
export fn wgpuShaderModuleSetLabel(shader_module: gpu.ShaderModule, label: [*:0]const u8) void {
assertDecl(Impl, "shaderModuleSetLabel", fn (shader_module: gpu.ShaderModule, label: [*:0]const u8) callconv(.Inline) void);

// WGPU_EXPORT void wgpuShaderModuleReference(WGPUShaderModule shaderModule);
export fn wgpuShaderModuleReference(shader_module: gpu.ShaderModule) void {
assertDecl(Impl, "shaderModuleReference", fn (shader_module: gpu.ShaderModule) callconv(.Inline) void);

// WGPU_EXPORT void wgpuShaderModuleRelease(WGPUShaderModule shaderModule);
export fn wgpuShaderModuleRelease(shader_module: gpu.ShaderModule) void {
assertDecl(Impl, "shaderModuleRelease", fn (shader_module: gpu.ShaderModule) callconv(.Inline) void);

// WGPU_EXPORT void wgpuSurfaceReference(WGPUSurface surface);
export fn wgpuSurfaceReference(surface: gpu.Surface) void {
assertDecl(Impl, "surfaceReference", fn (surface: gpu.Surface) callconv(.Inline) void);

// WGPU_EXPORT void wgpuSurfaceRelease(WGPUSurface surface);
export fn wgpuSurfaceRelease(surface: gpu.Surface) void {
assertDecl(Impl, "surfaceRelease", fn (surface: gpu.Surface) callconv(.Inline) void);

WGPU_EXPORT void wgpuSwapChainConfigure(WGPUSwapChain swapChain, WGPUTextureFormat format, WGPUTextureUsageFlags allowedUsage, uint32_t width, uint32_t height);
WGPU_EXPORT WGPUTextureView wgpuSwapChainGetCurrentTextureView(WGPUSwapChain swapChain);
WGPU_EXPORT void wgpuSwapChainPresent(WGPUSwapChain swapChain);

// WGPU_EXPORT void wgpuSwapChainReference(WGPUSwapChain swapChain);
export fn wgpuSwapChainReference(swap_chain: gpu.SwapChain) void {
assertDecl(Impl, "swapChainReference", fn (swap_chain: gpu.SwapChain) callconv(.Inline) void);

// WGPU_EXPORT void wgpuSwapChainRelease(WGPUSwapChain swapChain);
export fn wgpuSwapChainRelease(swap_chain: gpu.SwapChain) void {
assertDecl(Impl, "swapChainRelease", fn (swap_chain: gpu.SwapChain) callconv(.Inline) void);

WGPU_EXPORT WGPUTextureView wgpuTextureCreateView(WGPUTexture texture, WGPUTextureViewDescriptor const * descriptor /* nullable */);

// WGPU_EXPORT void wgpuTextureDestroy(WGPUTexture texture);
export fn wgpuTextureDestroy(texture: gpu.Texture) void {
assertDecl(Impl, "textureDestroy", fn (texture: gpu.Texture) callconv(.Inline) void);

WGPU_EXPORT uint32_t wgpuTextureGetDepthOrArrayLayers(WGPUTexture texture);
WGPU_EXPORT WGPUTextureDimension wgpuTextureGetDimension(WGPUTexture texture);
WGPU_EXPORT WGPUTextureFormat wgpuTextureGetFormat(WGPUTexture texture);
WGPU_EXPORT uint32_t wgpuTextureGetHeight(WGPUTexture texture);
WGPU_EXPORT uint32_t wgpuTextureGetMipLevelCount(WGPUTexture texture);
WGPU_EXPORT uint32_t wgpuTextureGetSampleCount(WGPUTexture texture);
WGPU_EXPORT WGPUTextureUsage wgpuTextureGetUsage(WGPUTexture texture);
WGPU_EXPORT uint32_t wgpuTextureGetWidth(WGPUTexture texture);

// WGPU_EXPORT void wgpuTextureSetLabel(WGPUTexture texture, char const * label);
export fn wgpuTextureSetLabel(texture: gpu.Texture, label: [*:0]const u8) void {
assertDecl(Impl, "textureSetLabel", fn (texture: gpu.Texture, label: [*:0]const u8) callconv(.Inline) void);

// WGPU_EXPORT void wgpuTextureReference(WGPUTexture texture);
export fn wgpuTextureReference(texture: gpu.Texture) void {
assertDecl(Impl, "textureReference", fn (texture: gpu.Texture) callconv(.Inline) void);

// WGPU_EXPORT void wgpuTextureRelease(WGPUTexture texture);
export fn wgpuTextureRelease(texture: gpu.Texture) void {
assertDecl(Impl, "textureRelease", fn (texture: gpu.Texture) callconv(.Inline) void);

// WGPU_EXPORT void wgpuTextureViewSetLabel(WGPUTextureView textureView, char const * label);
export fn wgpuTextureViewSetLabel(texture_view: gpu.TextureView, label: [*:0]const u8) void {
assertDecl(Impl, "textureViewSetLabel", fn (texture_view: gpu.TextureView, label: [*:0]const u8) callconv(.Inline) void);

// WGPU_EXPORT void wgpuTextureViewReference(WGPUTextureView textureView);
export fn wgpuTextureViewReference(texture_view: gpu.TextureView) void {
assertDecl(Impl, "textureViewReference", fn (texture_view: gpu.TextureView) callconv(.Inline) void);

// WGPU_EXPORT void wgpuTextureViewRelease(WGPUTextureView textureView);
export fn wgpuTextureViewRelease(texture_view: gpu.TextureView) void {
assertDecl(Impl, "textureViewRelease", fn (texture_view: gpu.TextureView) callconv(.Inline) void);
