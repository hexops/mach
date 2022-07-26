// WGPU_EXPORT void wgpuAdapterReference(WGPUAdapter adapter);
export fn wgpuAdapterReference(adapter: gpu.Adapter) void {
    impl.adapterReference(adapter);
}
pub inline fn adapterReference(adapter: gpu.Adapter) void {
    _ = adapter;
}
pub inline fn reference(adapter: Adapter) void {
    impl.adapterReference(adapter);
}

// WGPU_EXPORT void wgpuAdapterRelease(WGPUAdapter adapter);
export fn wgpuAdapterRelease(adapter: gpu.Adapter) void {
    impl.adapterRelease(adapter);
}
pub inline fn adapterRelease(adapter: gpu.Adapter) void {
    _ = adapter;
}
pub inline fn release(adapter: Adapter) void {
    impl.adapterRelease(adapter);
}

// WGPU_EXPORT void wgpuBindGroupSetLabel(WGPUBindGroup bindGroup, char const * label);
export fn wgpuBindGroupSetLabel(bind_group: gpu.BindGroup, label: [*:0]const u8) void {

// WGPU_EXPORT void wgpuBindGroupReference(WGPUBindGroup bindGroup);
export fn wgpuBindGroupReference(bind_group: gpu.BindGroup) void {
    impl.bindGroupReference(bind_group);
}
pub inline fn bindGroupReference(bind_group: gpu.BindGroup) void {
    _ = bind_group;
}
pub inline fn reference(bind_group: BindGroup) void {
    impl.bindGroupReference(bind_group);
}

// WGPU_EXPORT void wgpuBindGroupRelease(WGPUBindGroup bindGroup);
export fn wgpuBindGroupRelease(bind_group: gpu.BindGroup) void {

// WGPU_EXPORT void wgpuBindGroupLayoutSetLabel(WGPUBindGroupLayout bindGroupLayout, char const * label);
export fn wgpuBindGroupLayoutSetLabel(bind_group_layout: gpu.BindGroupLayout, label: [*:0]const u8) void {

// WGPU_EXPORT void wgpuBindGroupLayoutReference(WGPUBindGroupLayout bindGroupLayout);
export fn wgpuBindGroupLayoutReference(bind_group_layout: gpu.BindGroupLayout) void {

// WGPU_EXPORT void wgpuBindGroupLayoutRelease(WGPUBindGroupLayout bindGroupLayout);
export fn wgpuBindGroupLayoutRelease(bind_group_layout: gpu.BindGroupLayout) void {

// WGPU_EXPORT void wgpuBufferDestroy(WGPUBuffer buffer);
export fn wgpuBufferDestroy(buffer: gpu.Buffer) void {

// WGPU_EXPORT void const * wgpuBufferGetConstMappedRange(WGPUBuffer buffer, size_t offset, size_t size);
export fn wgpuBufferGetConstMappedRange(buffer: gpu.Buffer, offset: usize, size: usize) *const anyopaque {

// WGPU_EXPORT void * wgpuBufferGetMappedRange(WGPUBuffer buffer, size_t offset, size_t size);
export fn wgpuBufferGetMappedRange(buffer: gpu.Buffer, offset: usize, size: usize) *anyopaque {

// WGPU_EXPORT uint64_t wgpuBufferGetSize(WGPUBuffer buffer);
export fn wgpuBufferGetSize(buffer: gpu.Buffer) u64 {

// WGPU_EXPORT WGPUBufferUsage wgpuBufferGetUsage(WGPUBuffer buffer);
export fn wgpuBufferGetUsage(buffer: gpu.Buffer) gpu.BufferUsage {

// WGPU_EXPORT void wgpuBufferMapAsync(WGPUBuffer buffer, WGPUMapModeFlags mode, size_t offset, size_t size, WGPUBufferMapCallback callback, void * userdata);
export fn wgpuBufferMapAsync(buffer: gpu.Buffer, mode: gpu.MapModeFlags, offset: usize, size: usize, callback: BufferMapCallback, userdata: *anyopaque) u64 {

// WGPU_EXPORT void wgpuBufferSetLabel(WGPUBuffer buffer, char const * label);
export fn wgpuBufferSetLabel(buffer: gpu.Buffer, label: [*:0]const u8) void {

// WGPU_EXPORT void wgpuBufferUnmap(WGPUBuffer buffer);
export fn wgpuBufferUnmap(buffer: gpu.Buffer) void {

// WGPU_EXPORT void wgpuBufferReference(WGPUBuffer buffer);
export fn wgpuBufferReference(buffer: gpu.Buffer) void {

// WGPU_EXPORT void wgpuBufferRelease(WGPUBuffer buffer);
export fn wgpuBufferRelease(buffer: gpu.Buffer) void {

// WGPU_EXPORT void wgpuCommandBufferSetLabel(WGPUCommandBuffer commandBuffer, char const * label);
export fn wgpuCommandBufferSetLabel(command_buffer: gpu.CommandBuffer, label: [*:0]const u8) void {

// WGPU_EXPORT void wgpuCommandBufferReference(WGPUCommandBuffer commandBuffer);
export fn wgpuCommandBufferReference(command_buffer: gpu.CommandBuffer) void {

// WGPU_EXPORT void wgpuCommandBufferRelease(WGPUCommandBuffer commandBuffer);
export fn wgpuCommandBufferRelease(command_buffer: gpu.CommandBuffer) void {

// WGPU_EXPORT WGPUComputePassEncoder wgpuCommandEncoderBeginComputePass(WGPUCommandEncoder commandEncoder, WGPUComputePassDescriptor const * descriptor /* nullable */);
export fn wgpuCommandEncoderBeginComputePass(command_encoder: gpu.CommandEncoder, descriptor: ?*const gpu.ComputePassDescriptor) gpu.ComputePassEncoder {

// WGPU_EXPORT WGPURenderPassEncoder wgpuCommandEncoderBeginRenderPass(WGPUCommandEncoder commandEncoder, WGPURenderPassDescriptor const * descriptor);
export fn wgpuCommandEncoderBeginRenderPass(command_encoder: gpu.CommandEncoder, descriptor: *const gpu.RenderPassDescriptor) gpu.RenderPassEncoder {

// WGPU_EXPORT void wgpuCommandEncoderClearBuffer(WGPUCommandEncoder commandEncoder, WGPUBuffer buffer, uint64_t offset, uint64_t size);
export fn wgpuCommandEncoderClearBuffer(command_encoder: gpu.CommandEncoder, buffer: gpu.Buffer, offset: u64, size: u64) void {

// WGPU_EXPORT void wgpuCommandEncoderCopyBufferToBuffer(WGPUCommandEncoder commandEncoder, WGPUBuffer source, uint64_t sourceOffset, WGPUBuffer destination, uint64_t destinationOffset, uint64_t size);
export fn wgpuCommandEncoderCopyBufferToBuffer(command_encoder: gpu.CommandEncoder, source: gpu.Buffer, source_offset: u64, destination: gpu.Buffer, destination_offset: u64, size: u64) void {

// WGPU_EXPORT void wgpuCommandEncoderCopyBufferToTexture(WGPUCommandEncoder commandEncoder, WGPUImageCopyBuffer const * source, WGPUImageCopyTexture const * destination, WGPUExtent3D const * copySize);
export fn wgpuCommandEncoderCopyBufferToTexture(command_encoder: gpu.CommandEncoder, source: *const gpu.ImageCopyBuffer, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) void {

// WGPU_EXPORT void wgpuCommandEncoderCopyTextureToBuffer(WGPUCommandEncoder commandEncoder, WGPUImageCopyTexture const * source, WGPUImageCopyBuffer const * destination, WGPUExtent3D const * copySize);
export fn wgpuCommandEncoderCopyTextureToBuffer(command_encoder: gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyBuffer, copy_size: *const gpu.Extent3D) void {

// WGPU_EXPORT void wgpuCommandEncoderCopyTextureToTexture(WGPUCommandEncoder commandEncoder, WGPUImageCopyTexture const * source, WGPUImageCopyTexture const * destination, WGPUExtent3D const * copySize);
export fn wgpuCommandEncoderCopyTextureToTexture(command_encoder: gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) void {

// Note: the only difference between this and the non-internal variant is that this one checks
// internal usage.
// WGPU_EXPORT void wgpuCommandEncoderCopyTextureToTextureInternal(WGPUCommandEncoder commandEncoder, WGPUImageCopyTexture const * source, WGPUImageCopyTexture const * destination, WGPUExtent3D const * copySize);
export fn wgpuCommandEncoderCopyTextureToTextureInternal(command_encoder: gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) void {

// WGPU_EXPORT WGPUCommandBuffer wgpuCommandEncoderFinish(WGPUCommandEncoder commandEncoder, WGPUCommandBufferDescriptor const * descriptor /* nullable */);
export fn wgpuCommandEncoderFinish(command_encoder: gpu.CommandEncoder, descriptor: ?*const gpu.CommandBufferDescriptor) gpu.CommandBuffer {

// WGPU_EXPORT void wgpuCommandEncoderInjectValidationError(WGPUCommandEncoder commandEncoder, char const * message);
export fn wgpuCommandEncoderInjectValidationError(command_encoder: gpu.CommandEncoder, message: [*:0]const u8) void {

// WGPU_EXPORT void wgpuCommandEncoderInsertDebugMarker(WGPUCommandEncoder commandEncoder, char const * markerLabel);
export fn wgpuCommandEncoderInsertDebugMarker(command_encoder: gpu.CommandEncoder, marker_label: [*:0]const u8) void {

// WGPU_EXPORT void wgpuCommandEncoderPopDebugGroup(WGPUCommandEncoder commandEncoder);
export fn wgpuCommandEncoderPopDebugGroup(command_encoder: gpu.CommandEncoder) void {

// WGPU_EXPORT void wgpuCommandEncoderPushDebugGroup(WGPUCommandEncoder commandEncoder, char const * groupLabel);
export fn wgpuCommandEncoderPushDebugGroup(command_encoder: gpu.CommandEncoder, group_label: [*:0]const u8) void {

// WGPU_EXPORT void wgpuCommandEncoderResolveQuerySet(WGPUCommandEncoder commandEncoder, WGPUQuerySet querySet, uint32_t firstQuery, uint32_t queryCount, WGPUBuffer destination, uint64_t destinationOffset);
export fn wgpuCommandEncoderResolveQuerySet(command_encoder: gpu.CommandEncoder, query_set: gpu.QuerySet, first_query: u32, query_count: u32, destination: gpu.Buffer, destination_offset: u64) void {

// WGPU_EXPORT void wgpuCommandEncoderSetLabel(WGPUCommandEncoder commandEncoder, char const * label);
export fn wgpuCommandEncoderSetLabel(command_encoder: gpu.CommandEncoder, label: [*:0]const u8) void {

// WGPU_EXPORT void wgpuCommandEncoderWriteBuffer(WGPUCommandEncoder commandEncoder, WGPUBuffer buffer, uint64_t bufferOffset, uint8_t const * data, uint64_t size);
export fn wgpuCommandEncoderWriteBuffer(command_encoder: gpu.CommandEncoder, buffer: gpu.Buffer, buffer_offset: u64, data: [*]const u8, size: u64) void {

// WGPU_EXPORT void wgpuCommandEncoderWriteTimestamp(WGPUCommandEncoder commandEncoder, WGPUQuerySet querySet, uint32_t queryIndex);
export fn wgpuCommandEncoderWriteTimestamp(command_encoder: gpu.CommandEncoder, query_set: gpu.QuerySet, query_index: u32) void {

// WGPU_EXPORT void wgpuCommandEncoderReference(WGPUCommandEncoder commandEncoder);
export fn wgpuCommandEncoderReference(command_encoder: gpu.CommandEncoder) void {

// WGPU_EXPORT void wgpuCommandEncoderRelease(WGPUCommandEncoder commandEncoder);
export fn wgpuCommandEncoderRelease(command_encoder: gpu.CommandEncoder) void {

// WGPU_EXPORT void wgpuComputePassEncoderDispatch(WGPUComputePassEncoder computePassEncoder, uint32_t workgroupCountX, uint32_t workgroupCountY, uint32_t workgroupCountZ);
export fn wgpuComputePassEncoderDispatch(compute_pass_encoder: gpu.ComputePassEncoder, workgroup_count_x: u32, workgroup_count_y: u32, workgroup_count_z: u32) void {

// WGPU_EXPORT void wgpuComputePassEncoderDispatchIndirect(WGPUComputePassEncoder computePassEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
export fn wgpuComputePassEncoderDispatchIndirect(compute_pass_encoder: gpu.ComputePassEncoder, indirect_buffer: gpu.Buffer, indirect_offset: u64) void {

// WGPU_EXPORT void wgpuComputePassEncoderDispatchWorkgroups(WGPUComputePassEncoder computePassEncoder, uint32_t workgroupCountX, uint32_t workgroupCountY, uint32_t workgroupCountZ);
export fn wgpuComputePassEncoderDispatchWorkgroups(compute_pass_encoder: gpu.ComputePassEncoder, workgroup_count_x: u32, workgroup_count_y: u32, workgroup_count_z: u32) void {

// WGPU_EXPORT void wgpuComputePassEncoderDispatchWorkgroupsIndirect(WGPUComputePassEncoder computePassEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
export fn wgpuComputePassEncoderDispatchWorkgroupsIndirect(compute_pass_encoder: gpu.ComputePassEncoder, indirect_buffer: gpu.Buffer, indirect_offset: u64) void {

// WGPU_EXPORT void wgpuComputePassEncoderEnd(WGPUComputePassEncoder computePassEncoder);
export fn wgpuComputePassEncoderEnd(compute_pass_encoder: gpu.ComputePassEncoder) void {

// WGPU_EXPORT void wgpuComputePassEncoderEndPass(WGPUComputePassEncoder computePassEncoder);
export fn wgpuComputePassEncoderEndPass(compute_pass_encoder: gpu.ComputePassEncoder) void {

// WGPU_EXPORT void wgpuComputePassEncoderInsertDebugMarker(WGPUComputePassEncoder computePassEncoder, char const * markerLabel);
export fn wgpuComputePassEncoderInsertDebugMarker(compute_pass_encoder: gpu.ComputePassEncoder, marker_label: [*:0]const u8) void {

// WGPU_EXPORT void wgpuComputePassEncoderPopDebugGroup(WGPUComputePassEncoder computePassEncoder);
export fn wgpuComputePassEncoderPopDebugGroup(compute_pass_encoder: gpu.ComputePassEncoder) void {

// WGPU_EXPORT void wgpuComputePassEncoderPushDebugGroup(WGPUComputePassEncoder computePassEncoder, char const * groupLabel);
export fn wgpuComputePassEncoderPushDebugGroup(compute_pass_encoder: gpu.ComputePassEncoder, group_label: [*:0]const u8) void {

// WGPU_EXPORT void wgpuComputePassEncoderSetBindGroup(WGPUComputePassEncoder computePassEncoder, uint32_t groupIndex, WGPUBindGroup group, uint32_t dynamicOffsetCount, uint32_t const * dynamicOffsets);
export fn wgpuComputePassEncoderSetBindGroup(compute_pass_encoder: gpu.ComputePassEncoder, group_index: u32, group: gpu.BindGroup, dynamic_offset_count: u32, dynamic_offsets: [*]const u32) void {

// WGPU_EXPORT void wgpuComputePassEncoderSetLabel(WGPUComputePassEncoder computePassEncoder, char const * label);
export fn wgpuComputePassEncoderSetLabel(compute_pass_encoder: gpu.ComputePassEncoder, label: [*:0]const u8) void {

// WGPU_EXPORT void wgpuComputePassEncoderSetPipeline(WGPUComputePassEncoder computePassEncoder, WGPUComputePipeline pipeline);
export fn wgpuComputePassEncoderSetPipeline(compute_pass_encoder: gpu.ComputePassEncoder, pipeline: gpu.ComputePipeline) void {

// WGPU_EXPORT void wgpuComputePassEncoderWriteTimestamp(WGPUComputePassEncoder computePassEncoder, WGPUQuerySet querySet, uint32_t queryIndex);
export fn wgpuComputePassEncoderWriteTimestamp(compute_pass_encoder: gpu.ComputePassEncoder, pipeline: gpu.ComputePipeline) void {

// WGPU_EXPORT void wgpuComputePassEncoderReference(WGPUComputePassEncoder computePassEncoder);
export fn wgpuComputePassEncoderReference(compute_pass_encoder: gpu.ComputePassEncoder) void {

// WGPU_EXPORT void wgpuComputePassEncoderRelease(WGPUComputePassEncoder computePassEncoder);
export fn wgpuComputePassEncoderRelease(compute_pass_encoder: gpu.ComputePassEncoder) void {

// WGPU_EXPORT WGPUBindGroupLayout wgpuComputePipelineGetBindGroupLayout(WGPUComputePipeline computePipeline, uint32_t groupIndex);
export fn wgpuComputePipelineGetBindGroupLayout(compute_pipeline: gpu.ComputePipeline, group_index: u32) gpu.BindGroupLayout {

// WGPU_EXPORT void wgpuComputePipelineSetLabel(WGPUComputePipeline computePipeline, char const * label);
export fn wgpuComputePipelineSetLabel(compute_pipeline: gpu.ComputePipeline, label: [*:0]const u8) void {

// WGPU_EXPORT void wgpuComputePipelineReference(WGPUComputePipeline computePipeline);
export fn wgpuComputePipelineReference(compute_pipeline: gpu.ComputePipeline) void {

// WGPU_EXPORT void wgpuComputePipelineRelease(WGPUComputePipeline computePipeline);
export fn wgpuComputePipelineRelease(compute_pipeline: gpu.ComputePipeline) void {

// WGPU_EXPORT WGPUBindGroup wgpuDeviceCreateBindGroup(WGPUDevice device, WGPUBindGroupDescriptor const * descriptor);
export fn wgpuDeviceCreateBindGroup(device: gpu.Device, descriptor: *const gpu.BindGroupDescriptor) gpu.BindGroup {

// WGPU_EXPORT WGPUBindGroupLayout wgpuDeviceCreateBindGroupLayout(WGPUDevice device, WGPUBindGroupLayoutDescriptor const * descriptor);
export fn wgpuDeviceCreateBindGroupLayout(device: gpu.Device, descriptor: *const gpu.BindGroupLayoutDescriptor) gpu.BindGroupLayout {

// WGPU_EXPORT WGPUBuffer wgpuDeviceCreateBuffer(WGPUDevice device, WGPUBufferDescriptor const * descriptor);
export fn wgpuDeviceCreateBindGroup(device: gpu.Device, descriptor: *const gpu.BufferDescriptor) gpu.Buffer {

// WGPU_EXPORT WGPUCommandEncoder wgpuDeviceCreateCommandEncoder(WGPUDevice device, WGPUCommandEncoderDescriptor const * descriptor /* nullable */);
export fn wgpuDeviceCreateCommandEncoder(device: gpu.Device, descriptor: ?*const gpu.CommandEncoderDescriptor) gpu.CommandEncoder {

// WGPU_EXPORT WGPUComputePipeline wgpuDeviceCreateComputePipeline(WGPUDevice device, WGPUComputePipelineDescriptor const * descriptor);
export fn wgpuDeviceCreateComputePipeline(device: gpu.Device, descriptor: *const gpu.ComputePipelineDescriptor) gpu.ComputePipeline {

// WGPU_EXPORT void wgpuDeviceCreateComputePipelineAsync(WGPUDevice device, WGPUComputePipelineDescriptor const * descriptor, WGPUCreateComputePipelineAsyncCallback callback, void * userdata);
export fn wgpuDeviceCreateComputePipelineAsync(device: gpu.Device, descriptor: *const gpu.ComputePipelineDescriptor, callback: gpu.CreateComputePipelineAsyncCallback, userdata: *anyopaque) void {

// WGPU_EXPORT WGPUBuffer wgpuDeviceCreateErrorBuffer(WGPUDevice device);
export fn wgpuDeviceCreateErrorBuffer(device: gpu.Device) gpu.Buffer {

// WGPU_EXPORT WGPUExternalTexture wgpuDeviceCreateErrorExternalTexture(WGPUDevice device);
export fn wgpuDeviceCreateErrorExternalTexture(device: gpu.Device) gpu.ExternalTexture {

// WGPU_EXPORT WGPUExternalTexture wgpuDeviceCreateExternalTexture(WGPUDevice device, WGPUExternalTextureDescriptor const * externalTextureDescriptor);
export fn wgpuDeviceCreateExternalTexture(device: gpu.Device, external_texture_descriptor: *const gpu.ExternalTextureDescriptor) gpu.ExternalTexture {

// WGPU_EXPORT WGPUPipelineLayout wgpuDeviceCreatePipelineLayout(WGPUDevice device, WGPUPipelineLayoutDescriptor const * descriptor);
export fn wgpuDeviceCreatePipelineLayout(device: gpu.Device, pipeline_layout_descriptor: *const gpu.PipelineLayoutDescriptor) gpu.PipelineLayout {

// WGPU_EXPORT WGPUQuerySet wgpuDeviceCreateQuerySet(WGPUDevice device, WGPUQuerySetDescriptor const * descriptor);
export fn wgpuDeviceCreateQuerySet(device: gpu.Device, descriptor: *const gpu.QuerySetDescriptor) gpu.QuerySet {

// WGPU_EXPORT WGPURenderBundleEncoder wgpuDeviceCreateRenderBundleEncoder(WGPUDevice device, WGPURenderBundleEncoderDescriptor const * descriptor);
export fn wgpuDeviceCreateRenderBundleEncoder(device: gpu.Device, descriptor: *const gpu.RenderBundleEncoderDescriptor) gpu.RenderBundleEncoder {

// WGPU_EXPORT WGPURenderPipeline wgpuDeviceCreateRenderPipeline(WGPUDevice device, WGPURenderPipelineDescriptor const * descriptor);
export fn wgpuDeviceCreateRenderPipeline(device: gpu.Device, descriptor: *const gpu.RenderPipelineDescriptor) gpu.RenderPipeline {

// WGPU_EXPORT void wgpuDeviceCreateRenderPipelineAsync(WGPUDevice device, WGPURenderPipelineDescriptor const * descriptor, WGPUCreateRenderPipelineAsyncCallback callback, void * userdata);
export fn wgpuDeviceCreateRenderPipelineAsync(device: gpu.Device, descriptor: *const gpu.RenderPipelineDescriptor, callback: gpu.CreateRenderPipelineAsyncCallback, userdata: *anyopaque) void {

// WGPU_EXPORT WGPUSampler wgpuDeviceCreateSampler(WGPUDevice device, WGPUSamplerDescriptor const * descriptor /* nullable */);
export fn wgpuDeviceCreateRenderPipeline(device: gpu.Device, descriptor: ?*const gpu.SamplerDescriptor) gpu.Sampler {

// WGPU_EXPORT WGPUShaderModule wgpuDeviceCreateShaderModule(WGPUDevice device, WGPUShaderModuleDescriptor const * descriptor);
export fn wgpuDeviceCreateShaderModule(device: gpu.Device, descriptor: *const gpu.ShaderModuleDescriptor) gpu.ShaderModule {

// WGPU_EXPORT WGPUSwapChain wgpuDeviceCreateSwapChain(WGPUDevice device, WGPUSurface surface /* nullable */, WGPUSwapChainDescriptor const * descriptor);
export fn wgpuDeviceCreateShaderModule(device: gpu.Device, surface: ?Surface, descriptor: *const gpu.SwapChainDescriptor) gpu.SwapChain {

// WGPU_EXPORT WGPUTexture wgpuDeviceCreateTexture(WGPUDevice device, WGPUTextureDescriptor const * descriptor);
export fn wgpuDeviceCreateTexture(device: gpu.Device, descriptor: *const gpu.TextureDescriptor) gpu.Texture {

// WGPU_EXPORT void wgpuDeviceDestroy(WGPUDevice device);
export fn wgpuDeviceDestroy(device: gpu.Device) void {

// WGPU_EXPORT size_t wgpuDeviceEnumerateFeatures(WGPUDevice device, WGPUFeatureName * features);
export fn wgpuDeviceEnumerateFeatures(device: gpu.Device, features: [*]gpu.FeatureName) usize {

// WGPU_EXPORT bool wgpuDeviceGetLimits(WGPUDevice device, WGPUSupportedLimits * limits);
export fn wgpuDeviceGetLimits(device: gpu.Device, limits: *gpu.SupportedLimits) bool {

// WGPU_EXPORT WGPUQueue wgpuDeviceGetQueue(WGPUDevice device);
export fn wgpuDeviceGetQueue(device: gpu.Device) gpu.Queue {

// WGPU_EXPORT bool wgpuDeviceHasFeature(WGPUDevice device, WGPUFeatureName feature);
export fn wgpuDeviceHasFeature(device: gpu.Device, feature: gpu.FeatureName) bool {

// WGPU_EXPORT void wgpuDeviceInjectError(WGPUDevice device, WGPUErrorType type, char const * message);
export fn wgpuDeviceInjectError(device: gpu.Device, typ: gpu.ErrorType, message: [*:0]const u8) void {

// WGPU_EXPORT void wgpuDeviceLoseForTesting(WGPUDevice device);
export fn wgpuDeviceLoseForTesting(device: gpu.Device) void {

// WGPU_EXPORT bool wgpuDevicePopErrorScope(WGPUDevice device, WGPUErrorCallback callback, void * userdata);
export fn wgpuDevicePopErrorScope(device: gpu.Device, callback: gpu.ErrorCallback, userdata: *anyopaque) bool {

// WGPU_EXPORT void wgpuDevicePushErrorScope(WGPUDevice device, WGPUErrorFilter filter);
export fn wgpuDevicePushErrorScope(device: gpu.Device, filter: gpu.ErrorFilter) void {

// WGPU_EXPORT void wgpuDeviceSetDeviceLostCallback(WGPUDevice device, WGPUDeviceLostCallback callback, void * userdata);
export fn wgpuDeviceSetDeviceLostCallback(device: gpu.Device, callback: gpu.DeviceLostCallback, userdata: *anyopaque) void {

// WGPU_EXPORT void wgpuDeviceSetLabel(WGPUDevice device, char const * label);
export fn wgpuDeviceSetLabel(device: gpu.Device, label: [*:0]const u8) void {

// WGPU_EXPORT void wgpuDeviceSetLoggingCallback(WGPUDevice device, WGPULoggingCallback callback, void * userdata);
export fn wgpuDeviceSetLoggingCallback(device: gpu.Device, callback: gpu.LoggingCallback, userdata: *anyopaque) void {

// WGPU_EXPORT void wgpuDeviceSetUncapturedErrorCallback(WGPUDevice device, WGPUErrorCallback callback, void * userdata);
export fn wgpuDeviceSetUncapturedErrorCallback(device: gpu.Device, callback: gpu.ErrorCallback, userdata: *anyopaque) void {

// WGPU_EXPORT void wgpuDeviceTick(WGPUDevice device);
export fn wgpuDeviceTick(device: gpu.Device) void {

// WGPU_EXPORT void wgpuDeviceReference(WGPUDevice device);
export fn wgpuDeviceReference(device: gpu.Device) void {

// WGPU_EXPORT void wgpuDeviceRelease(WGPUDevice device);
export fn wgpuDeviceRelease(device: gpu.Device) void {

// WGPU_EXPORT void wgpuExternalTextureDestroy(WGPUExternalTexture externalTexture);
export fn wgpuExternalTextureDestroy(external_texture: gpu.ExternalTexture) void {

// WGPU_EXPORT void wgpuExternalTextureSetLabel(WGPUExternalTexture externalTexture, char const * label);
export fn wgpuExternalTextureSetLabel(external_texture: gpu.ExternalTexture, label: [*:0]const u8) void {

// WGPU_EXPORT void wgpuExternalTextureReference(WGPUExternalTexture externalTexture);
export fn wgpuExternalTextureReference(external_texture: gpu.ExternalTexture) void {

// WGPU_EXPORT void wgpuExternalTextureRelease(WGPUExternalTexture externalTexture);
export fn wgpuExternalTextureRelease(external_texture: gpu.ExternalTexture) void {

// WGPU_EXPORT WGPUSurface wgpuInstanceCreateSurface(WGPUInstance instance, WGPUSurfaceDescriptor const * descriptor);
export fn wgpuInstanceCreateSurface(instance: gpu.Instance, descriptor: *const gpu.SurfaceDescriptor) gpu.Surface {

// WGPU_EXPORT void wgpuInstanceRequestAdapter(WGPUInstance instance, WGPURequestAdapterOptions const * options, WGPURequestAdapterCallback callback, void * userdata);
export fn wgpuInstanceRequestAdapter(instance: gpu.Instance, options: *const gpu.RequestAdapterOptions, callback: gpu.RequestAdapterCallback, userdata: *anyopaque) void {

// WGPU_EXPORT void wgpuInstanceReference(WGPUInstance instance);
export fn wgpuInstanceReference(instance: gpu.Instance) void {

// WGPU_EXPORT void wgpuInstanceRelease(WGPUInstance instance);
export fn wgpuInstanceRelease(instance: gpu.Instance) void {

// WGPU_EXPORT void wgpuPipelineLayoutSetLabel(WGPUPipelineLayout pipelineLayout, char const * label);
export fn wgpuPipelineLayoutSetLabel(pipeline_layout: gpu.PipelineLayout, label: [*:0]const u8) void {

// WGPU_EXPORT void wgpuPipelineLayoutReference(WGPUPipelineLayout pipelineLayout);
export fn wgpuPipelineLayoutReference(pipeline_layout: gpu.PipelineLayout) void {

// WGPU_EXPORT void wgpuPipelineLayoutRelease(WGPUPipelineLayout pipelineLayout);
export fn wgpuPipelineLayoutRelease(pipeline_layout: gpu.PipelineLayout) void {

// WGPU_EXPORT void wgpuQuerySetDestroy(WGPUQuerySet querySet);
export fn wgpuQuerySetDestroy(query_set: gpu.QuerySet) void {

// WGPU_EXPORT uint32_t wgpuQuerySetGetCount(WGPUQuerySet querySet);
export fn wgpuQuerySetGetCount(query_set: gpu.QuerySet) u32 {

// WGPU_EXPORT WGPUQueryType wgpuQuerySetGetType(WGPUQuerySet querySet);
export fn wgpuQuerySetGetType(query_set: gpu.QuerySet) gpu.QueryType {

// WGPU_EXPORT void wgpuQuerySetSetLabel(WGPUQuerySet querySet, char const * label);
export fn wgpuQuerySetSetLabel(query_set: gpu.QuerySet, label: [*:0]const u8) void {

// WGPU_EXPORT void wgpuQuerySetReference(WGPUQuerySet querySet);
export fn wgpuQuerySetReference(query_set: gpu.QuerySet) void {

// WGPU_EXPORT void wgpuQuerySetRelease(WGPUQuerySet querySet);
export fn wgpuQuerySetRelease(query_set: gpu.QuerySet) void {

// WGPU_EXPORT void wgpuQueueCopyTextureForBrowser(WGPUQueue queue, WGPUImageCopyTexture const * source, WGPUImageCopyTexture const * destination, WGPUExtent3D const * copySize, WGPUCopyTextureForBrowserOptions const * options);
export fn wgpuQueueCopyTextureForBrowser(queue: gpu.Queue, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D, options: *const gpu.CopyTextureForBrowserOptions) void {

// WGPU_EXPORT void wgpuQueueOnSubmittedWorkDone(WGPUQueue queue, uint64_t signalValue, WGPUQueueWorkDoneCallback callback, void * userdata);
export fn wgpuQueueOnSubmittedWorkDone(queue: gpu.Queue, signal_value: u64, callback: gpu.QueueWorkDoneCallback, userdata: *anyopaque) void {

// WGPU_EXPORT void wgpuQueueSetLabel(WGPUQueue queue, char const * label);
export fn wgpuQueueSetLabel(queue: gpu.Queue, label: [*:0]const u8) void {

// WGPU_EXPORT void wgpuQueueSubmit(WGPUQueue queue, uint32_t commandCount, WGPUCommandBuffer const * commands);
export fn wgpuQueueSubmit(queue: gpu.Queue, command_count: u32, commands: [*]gpu.CommandBuffer) void {

// WGPU_EXPORT void wgpuQueueWriteBuffer(WGPUQueue queue, WGPUBuffer buffer, uint64_t bufferOffset, void const * data, size_t size);
export fn wgpuQueueWriteBuffer(queue: gpu.Queue, buffer: gpu.Buffer, buffer_offset: u64, data: *anyopaque, size: usize) void {

// WGPU_EXPORT void wgpuQueueWriteTexture(WGPUQueue queue, WGPUImageCopyTexture const * destination, void const * data, size_t dataSize, WGPUTextureDataLayout const * dataLayout, WGPUExtent3D const * writeSize);
export fn wgpuQueueWriteTexture(queue: gpu.Queue, data: *anyopaque, data_size: usize, data_layout: *const gpu.TextureDataLayout, write_size: *const gpu.Extent3D) void {

// WGPU_EXPORT void wgpuQueueReference(WGPUQueue queue);
export fn wgpuQueueReference(queue: gpu.Queue) void {

// WGPU_EXPORT void wgpuQueueRelease(WGPUQueue queue);
export fn wgpuQueueRelease(queue: gpu.Queue) void {

// WGPU_EXPORT void wgpuRenderBundleReference(WGPURenderBundle renderBundle);
export fn wgpuRenderBundleReference(render_bundle: gpu.RenderBundle) void {

// WGPU_EXPORT void wgpuRenderBundleRelease(WGPURenderBundle renderBundle);
export fn wgpuRenderBundleRelease(render_bundle: gpu.RenderBundle) void {

// WGPU_EXPORT void wgpuRenderBundleEncoderDraw(WGPURenderBundleEncoder renderBundleEncoder, uint32_t vertexCount, uint32_t instanceCount, uint32_t firstVertex, uint32_t firstInstance);
export fn wgpuRenderBundleEncoderDraw(render_bundle_encoder: gpu.RenderBundleEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {

// WGPU_EXPORT void wgpuRenderBundleEncoderDrawIndexed(WGPURenderBundleEncoder renderBundleEncoder, uint32_t indexCount, uint32_t instanceCount, uint32_t firstIndex, int32_t baseVertex, uint32_t firstInstance);
export fn wgpuRenderBundleEncoderDrawIndexed(render_bundle_encoder: gpu.RenderBundleEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: u32, first_instance: u32) void {

// WGPU_EXPORT void wgpuRenderBundleEncoderDrawIndexedIndirect(WGPURenderBundleEncoder renderBundleEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
export fn wgpuRenderBundleEncoderDrawIndexedIndirect(render_bundle_encoder: gpu.RenderBundleEncoder, indirect_buffer: gpu.Buffer, indirect_offset: u64) void {

// WGPU_EXPORT void wgpuRenderBundleEncoderDrawIndirect(WGPURenderBundleEncoder renderBundleEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
export fn wgpuRenderBundleEncoderDrawIndirect(render_bundle_encoder: gpu.RenderBundleEncoder, indirect_buffer: gpu.Buffer, indirect_offset: u64) void {

// WGPU_EXPORT WGPURenderBundle wgpuRenderBundleEncoderFinish(WGPURenderBundleEncoder renderBundleEncoder, WGPURenderBundleDescriptor const * descriptor /* nullable */);
export fn wgpuRenderBundleEncoderFinish(render_bundle_encoder: gpu.RenderBundleEncoder, descriptor: ?*const gpu.RenderBundleDescriptor) void {

// WGPU_EXPORT void wgpuRenderBundleEncoderInsertDebugMarker(WGPURenderBundleEncoder renderBundleEncoder, char const * markerLabel);
export fn wgpuRenderBundleEncoderInsertDebugMarker(render_bundle_encoder: gpu.RenderBundleEncoder, marker_label: [*:0]const u8) void {

// WGPU_EXPORT void wgpuRenderBundleEncoderPopDebugGroup(WGPURenderBundleEncoder renderBundleEncoder);
export fn wgpuRenderBundleEncoderPopDebugGroup(render_bundle_encoder: gpu.RenderBundleEncoder) void {

// WGPU_EXPORT void wgpuRenderBundleEncoderPushDebugGroup(WGPURenderBundleEncoder renderBundleEncoder, char const * groupLabel);
export fn wgpuRenderBundleEncoderPushDebugGroup(render_bundle_encoder: gpu.RenderBundleEncoder, group_label: [*:0]const u8) void {

// WGPU_EXPORT void wgpuRenderBundleEncoderSetBindGroup(WGPURenderBundleEncoder renderBundleEncoder, uint32_t groupIndex, WGPUBindGroup group, uint32_t dynamicOffsetCount, uint32_t const * dynamicOffsets);
export fn wgpuRenderBundleEncoderSetBindGroup(render_bundle_encoder: gpu.RenderBundleEncoder, group_index: u32, group: gpu.BindGroup, dynamic_offset_count: u32, dynamic_offsets: [*]const u32) void {

// WGPU_EXPORT void wgpuRenderBundleEncoderSetIndexBuffer(WGPURenderBundleEncoder renderBundleEncoder, WGPUBuffer buffer, WGPUIndexFormat format, uint64_t offset, uint64_t size);
export fn wgpuRenderBundleEncoderSetIndexBuffer(render_bundle_encoder: gpu.RenderBundleEncoder, buffer: gpu.Buffer, format: gpu.IndexFormat, offset: u64, size: u64) void {

// WGPU_EXPORT void wgpuRenderBundleEncoderSetLabel(WGPURenderBundleEncoder renderBundleEncoder, char const * label);
export fn wgpuRenderBundleEncoderSetLabel(render_bundle_encoder: gpu.RenderBundleEncoder, label: [*:0]const u8) void {

// WGPU_EXPORT void wgpuRenderBundleEncoderSetPipeline(WGPURenderBundleEncoder renderBundleEncoder, WGPURenderPipeline pipeline);
export fn wgpuRenderBundleEncoderSetPipeline(render_bundle_encoder: gpu.RenderBundleEncoder, pipeline: gpu.RenderPipeline) void {

// WGPU_EXPORT void wgpuRenderBundleEncoderSetVertexBuffer(WGPURenderBundleEncoder renderBundleEncoder, uint32_t slot, WGPUBuffer buffer, uint64_t offset, uint64_t size);
export fn wgpuRenderBundleEncoderSetVertexBuffer(render_bundle_encoder: gpu.RenderBundleEncoder, slot: u32, buffer: gpu.Buffer, offset: u64, size: u64) void {

// WGPU_EXPORT void wgpuRenderBundleEncoderReference(WGPURenderBundleEncoder renderBundleEncoder);
export fn wgpuRenderBundleEncoderReference(render_bundle_encoder: gpu.RenderBundleEncoder) void {

// WGPU_EXPORT void wgpuRenderBundleEncoderRelease(WGPURenderBundleEncoder renderBundleEncoder);
export fn wgpuRenderBundleEncoderRelease(render_bundle_encoder: gpu.RenderBundleEncoder) void {

// WGPU_EXPORT void wgpuRenderPassEncoderBeginOcclusionQuery(WGPURenderPassEncoder renderPassEncoder, uint32_t queryIndex);
export fn wgpuRenderPassEncoderBeginOcclusionQuery(render_pass_encoder: gpu.RenderPassEncoder, query_index: u32) void {

// WGPU_EXPORT void wgpuRenderPassEncoderDraw(WGPURenderPassEncoder renderPassEncoder, uint32_t vertexCount, uint32_t instanceCount, uint32_t firstVertex, uint32_t firstInstance);
export fn wgpuRenderPassEncoderDraw(render_pass_encoder: gpu.RenderPassEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {

// WGPU_EXPORT void wgpuRenderPassEncoderDrawIndexed(WGPURenderPassEncoder renderPassEncoder, uint32_t indexCount, uint32_t instanceCount, uint32_t firstIndex, int32_t baseVertex, uint32_t firstInstance);
export fn wgpuRenderPassEncoderDrawIndexed(render_pass_encoder: gpu.RenderPassEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: u32, first_instance: u32) void {

// WGPU_EXPORT void wgpuRenderPassEncoderDrawIndexedIndirect(WGPURenderPassEncoder renderPassEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
export fn wgpuRenderPassEncoderDrawIndexedIndirect(render_pass_encoder: gpu.RenderPassEncoder, indirect_buffer: gpu.Buffer, indirect_offset: u64) void {

// WGPU_EXPORT void wgpuRenderPassEncoderDrawIndirect(WGPURenderPassEncoder renderPassEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
export fn wgpuRenderPassEncoderDrawIndirect(render_pass_encoder: gpu.RenderPassEncoder, indirect_buffer: gpu.Buffer, indirect_offset: u64) void {

// WGPU_EXPORT void wgpuRenderPassEncoderEnd(WGPURenderPassEncoder renderPassEncoder);
export fn wgpuRenderPassEncoderEnd(render_pass_encoder: gpu.RenderPassEncoder) void {

// WGPU_EXPORT void wgpuRenderPassEncoderEndOcclusionQuery(WGPURenderPassEncoder renderPassEncoder);
export fn wgpuRenderPassEncoderEndOcclusionQuery(render_pass_encoder: gpu.RenderPassEncoder) void {

// WGPU_EXPORT void wgpuRenderPassEncoderEndPass(WGPURenderPassEncoder renderPassEncoder);
export fn wgpuRenderPassEncoderEndPass(render_pass_encoder: gpu.RenderPassEncoder) void {

// WGPU_EXPORT void wgpuRenderPassEncoderExecuteBundles(WGPURenderPassEncoder renderPassEncoder, uint32_t bundlesCount, WGPURenderBundle const * bundles);
export fn wgpuRenderPassEncoderExecuteBundles(render_pass_encoder: gpu.RenderPassEncoder, bundles_count: u32, bundles: [*]const gpu.RenderBundle) void {

// WGPU_EXPORT void wgpuRenderPassEncoderInsertDebugMarker(WGPURenderPassEncoder renderPassEncoder, char const * markerLabel);
export fn wgpuRenderPassEncoderInsertDebugMarker(render_pass_encoder: gpu.RenderPassEncoder, marker_label: [*:0]const u8) void {

// WGPU_EXPORT void wgpuRenderPassEncoderPopDebugGroup(WGPURenderPassEncoder renderPassEncoder);
export fn wgpuRenderPassEncoderPopDebugGroup(render_pass_encoder: gpu.RenderPassEncoder) void {

// WGPU_EXPORT void wgpuRenderPassEncoderPushDebugGroup(WGPURenderPassEncoder renderPassEncoder, char const * groupLabel);
export fn wgpuRenderPassEncoderPushDebugGroup(render_pass_encoder: gpu.RenderPassEncoder, group_label: [*:0]const u8) void {

// WGPU_EXPORT void wgpuRenderPassEncoderSetBindGroup(WGPURenderPassEncoder renderPassEncoder, uint32_t groupIndex, WGPUBindGroup group, uint32_t dynamicOffsetCount, uint32_t const * dynamicOffsets);
export fn wgpuRenderPassEncoderSetBindGroup(render_pass_encoder: gpu.RenderPassEncoder, group_index: u32, group: gpu.BindGroup, dynamic_offset_count: u32, dynamic_offsets: [*]const u32) void {

// WGPU_EXPORT void wgpuRenderPassEncoderSetBlendConstant(WGPURenderPassEncoder renderPassEncoder, WGPUColor const * color);
export fn wgpuRenderPassEncoderSetBlendConstant(render_pass_encoder: gpu.RenderPassEncoder, color: *const gpu.Color) void {

// WGPU_EXPORT void wgpuRenderPassEncoderSetIndexBuffer(WGPURenderPassEncoder renderPassEncoder, WGPUBuffer buffer, WGPUIndexFormat format, uint64_t offset, uint64_t size);
export fn wgpuRenderPassEncoderSetIndexBuffer(render_pass_encoder: gpu.RenderPassEncoder, buffer: gpu.Buffer, format: gpu.IndexFormat, offset: u64, size: u64) void {

// WGPU_EXPORT void wgpuRenderPassEncoderSetLabel(WGPURenderPassEncoder renderPassEncoder, char const * label);
export fn wgpuRenderPassEncoderSetLabel(render_pass_encoder: gpu.RenderPassEncoder, label: [*:0]const u8) void {

// WGPU_EXPORT void wgpuRenderPassEncoderSetPipeline(WGPURenderPassEncoder renderPassEncoder, WGPURenderPipeline pipeline);
export fn wgpuRenderPassEncoderSetPipeline(render_pass_encoder: gpu.RenderPassEncoder, pipeline: gpu.RenderPipeline) void {

// WGPU_EXPORT void wgpuRenderPassEncoderSetScissorRect(WGPURenderPassEncoder renderPassEncoder, uint32_t x, uint32_t y, uint32_t width, uint32_t height);
export fn wgpuRenderPassEncoderSetScissorRect(render_pass_encoder: gpu.RenderPassEncoder, x: u32, y: u32, width: u32, height: u32) void {

// WGPU_EXPORT void wgpuRenderPassEncoderSetStencilReference(WGPURenderPassEncoder renderPassEncoder, uint32_t reference);
export fn wgpuRenderPassEncoderSetStencilReference(render_pass_encoder: gpu.RenderPassEncoder, reference: u32) void {

// WGPU_EXPORT void wgpuRenderPassEncoderSetVertexBuffer(WGPURenderPassEncoder renderPassEncoder, uint32_t slot, WGPUBuffer buffer, uint64_t offset, uint64_t size);
export fn wgpuRenderPassEncoderSetVertexBuffer(render_pass_encoder: gpu.RenderPassEncoder, slot: u32, buffer: gpu.Buffer, offset: u64, size: u64) void {

// WGPU_EXPORT void wgpuRenderPassEncoderSetViewport(WGPURenderPassEncoder renderPassEncoder, float x, float y, float width, float height, float minDepth, float maxDepth);
export fn wgpuRenderPassEncoderSetViewport(render_pass_encoder: gpu.RenderPassEncoder, x: f32, y: f32, width: f32, height: f32, min_depth: f32, max_depth: f32) void {

// WGPU_EXPORT void wgpuRenderPassEncoderWriteTimestamp(WGPURenderPassEncoder renderPassEncoder, WGPUQuerySet querySet, uint32_t queryIndex);
export fn wgpuRenderPassEncoderWriteTimestamp(render_pass_encoder: gpu.RenderPassEncoder, query_set: gpu.QuerySet, query_index: u32) void {

// WGPU_EXPORT void wgpuRenderPassEncoderReference(WGPURenderPassEncoder renderPassEncoder);
export fn wgpuRenderPassEncoderReference(render_pass_encoder: gpu.RenderPassEncoder) void {

// WGPU_EXPORT void wgpuRenderPassEncoderRelease(WGPURenderPassEncoder renderPassEncoder);
export fn wgpuRenderPassEncoderRelease(render_pass_encoder: gpu.RenderPassEncoder) void {

// WGPU_EXPORT WGPUBindGroupLayout wgpuRenderPipelineGetBindGroupLayout(WGPURenderPipeline renderPipeline, uint32_t groupIndex);
export fn wgpuRenderPipelineGetBindGroupLayout(render_pipeline: gpu.RenderPipeline, group_index: u32) gpu.BindGroupLayout {

// WGPU_EXPORT void wgpuRenderPipelineSetLabel(WGPURenderPipeline renderPipeline, char const * label);
export fn wgpuRenderPipelineSetLabel(render_pipeline: gpu.RenderPipeline, label: [*:0]const u8) void {

// WGPU_EXPORT void wgpuRenderPipelineReference(WGPURenderPipeline renderPipeline);
export fn wgpuRenderPipelineReference(render_pipeline: gpu.RenderPipeline) void {

// WGPU_EXPORT void wgpuRenderPipelineRelease(WGPURenderPipeline renderPipeline);
export fn wgpuRenderPipelineRelease(render_pipeline: gpu.RenderPipeline) void {

// WGPU_EXPORT void wgpuSamplerSetLabel(WGPUSampler sampler, char const * label);
export fn wgpuSamplerSetLabel(sampler: gpu.Sampler, label: [*:0]const u8) void {

// WGPU_EXPORT void wgpuSamplerReference(WGPUSampler sampler);
export fn wgpuSamplerReference(sampler: gpu.Sampler) void {

// WGPU_EXPORT void wgpuSamplerRelease(WGPUSampler sampler);
export fn wgpuSamplerRelease(sampler: gpu.Sampler) void {

// WGPU_EXPORT void wgpuShaderModuleGetCompilationInfo(WGPUShaderModule shaderModule, WGPUCompilationInfoCallback callback, void * userdata);
export fn wgpuShaderModuleGetCompilationInfo(shader_module: gpu.ShaderModule, callback: gpu.CompilationInfoCallback, userdata: *anyopaque) void {

// WGPU_EXPORT void wgpuShaderModuleSetLabel(WGPUShaderModule shaderModule, char const * label);
export fn wgpuShaderModuleSetLabel(shader_module: gpu.ShaderModule, label: [*:0]const u8) void {

// WGPU_EXPORT void wgpuShaderModuleReference(WGPUShaderModule shaderModule);
export fn wgpuShaderModuleReference(shader_module: gpu.ShaderModule) void {

// WGPU_EXPORT void wgpuShaderModuleRelease(WGPUShaderModule shaderModule);
export fn wgpuShaderModuleRelease(shader_module: gpu.ShaderModule) void {

// WGPU_EXPORT void wgpuSurfaceReference(WGPUSurface surface);
export fn wgpuSurfaceReference(surface: gpu.Surface) void {

// WGPU_EXPORT void wgpuSurfaceRelease(WGPUSurface surface);
export fn wgpuSurfaceRelease(surface: gpu.Surface) void {

// WGPU_EXPORT void wgpuSwapChainConfigure(WGPUSwapChain swapChain, WGPUTextureFormat format, WGPUTextureUsageFlags allowedUsage, uint32_t width, uint32_t height);
export fn wgpuSwapChainConfigure(swap_chain: gpu.SwapChain, format: gpu.TextureFormat, allowed_usage: gpu.TextureUsageFlags, width: u32, height: u32) void {

// WGPU_EXPORT WGPUTextureView wgpuSwapChainGetCurrentTextureView(WGPUSwapChain swapChain);
export fn wgpuSwapChainGetCurrentTextureView(swap_chain: gpu.SwapChain) gpu.TextureView {

// WGPU_EXPORT void wgpuSwapChainPresent(WGPUSwapChain swapChain);
export fn wgpuSwapChainPresent(swap_chain: gpu.SwapChain) void {

// WGPU_EXPORT void wgpuSwapChainReference(WGPUSwapChain swapChain);
export fn wgpuSwapChainReference(swap_chain: gpu.SwapChain) void {

// WGPU_EXPORT void wgpuSwapChainRelease(WGPUSwapChain swapChain);
export fn wgpuSwapChainRelease(swap_chain: gpu.SwapChain) void {

// WGPU_EXPORT WGPUTextureView wgpuTextureCreateView(WGPUTexture texture, WGPUTextureViewDescriptor const * descriptor /* nullable */);
export fn wgpuTextureCreateView(texture: gpu.Texture, descriptor: ?*const gpu.TextureViewDescriptor) gpu.TextureView {

// WGPU_EXPORT void wgpuTextureDestroy(WGPUTexture texture);
export fn wgpuTextureDestroy(texture: gpu.Texture) void {

// WGPU_EXPORT uint32_t wgpuTextureGetDepthOrArrayLayers(WGPUTexture texture);
export fn wgpuTextureGetDepthOrArrayLayers(texture: gpu.Texture) u32 {

// WGPU_EXPORT WGPUTextureDimension wgpuTextureGetDimension(WGPUTexture texture);
export fn wgpuTextureGetDimension(texture: gpu.Texture) gpu.TextureDimension {

// WGPU_EXPORT WGPUTextureFormat wgpuTextureGetFormat(WGPUTexture texture);
export fn wgpuTextureGetFormat(texture: gpu.Texture) gpu.TextureFormat {

// WGPU_EXPORT uint32_t wgpuTextureGetHeight(WGPUTexture texture);
export fn wgpuTextureGetHeight(texture: gpu.Texture) u32 {

// WGPU_EXPORT uint32_t wgpuTextureGetMipLevelCount(WGPUTexture texture);
export fn wgpuTextureGetMipLevelCount(texture: gpu.Texture) u32 {

// WGPU_EXPORT uint32_t wgpuTextureGetSampleCount(WGPUTexture texture);
export fn wgpuTextureGetSampleCount(texture: gpu.Texture) u32 {

// WGPU_EXPORT WGPUTextureUsage wgpuTextureGetUsage(WGPUTexture texture);
export fn wgpuTextureGetUsage(texture: gpu.Texture) gpu.TextureUsage {

// WGPU_EXPORT uint32_t wgpuTextureGetWidth(WGPUTexture texture);
export fn wgpuTextureGetWidth(texture: gpu.Texture) u32 {

// WGPU_EXPORT void wgpuTextureSetLabel(WGPUTexture texture, char const * label);
export fn wgpuTextureSetLabel(texture: gpu.Texture, label: [*:0]const u8) void {

// WGPU_EXPORT void wgpuTextureReference(WGPUTexture texture);
export fn wgpuTextureReference(texture: gpu.Texture) void {

// WGPU_EXPORT void wgpuTextureRelease(WGPUTexture texture);
export fn wgpuTextureRelease(texture: gpu.Texture) void {

// WGPU_EXPORT void wgpuTextureViewSetLabel(WGPUTextureView textureView, char const * label);
export fn wgpuTextureViewSetLabel(texture_view: gpu.TextureView, label: [*:0]const u8) void {

// WGPU_EXPORT void wgpuTextureViewReference(WGPUTextureView textureView);
export fn wgpuTextureViewReference(texture_view: gpu.TextureView) void {

// WGPU_EXPORT void wgpuTextureViewRelease(WGPUTextureView textureView);
export fn wgpuTextureViewRelease(texture_view: gpu.TextureView) void {
