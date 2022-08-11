const gpu = @import("main.zig");

/// The gpu.Interface implementation that is used by the entire program. Only one may exist, since
/// it is resolved fully at comptime with no vtable indirection, etc.
///
/// Depending on the implementation, it may need to be `.init()`ialized before use.
pub const Impl = blk: {
    if (@import("builtin").is_test) {
        break :blk StubInterface;
    } else {
        const root = @import("root");
        if (!@hasDecl(root, "GPUInterface")) @compileError("expected to find `pub const GPUInterface = T;` in root file");
        _ = gpu.Interface(root.GPUInterface); // verify the type
        break :blk root.GPUInterface;
    }
};

/// Verifies that a gpu.Interface implementation exposes the expected function declarations.
pub fn Interface(comptime T: type) type {
    assertDecl(T, "createInstance", fn (descriptor: ?*const gpu.Instance.Descriptor) callconv(.Inline) ?*gpu.Instance);
    assertDecl(T, "getProcAddress", fn (device: *gpu.Device, proc_name: [*:0]const u8) callconv(.Inline) ?gpu.Proc);
    assertDecl(T, "adapterCreateDevice", fn (adapter: *gpu.Adapter, descriptor: ?*const gpu.Device.Descriptor) callconv(.Inline) ?*gpu.Device);
    assertDecl(T, "adapterEnumerateFeatures", fn (adapter: *gpu.Adapter, features: ?[*]gpu.FeatureName) callconv(.Inline) usize);
    assertDecl(T, "adapterGetLimits", fn (adapter: *gpu.Adapter, limits: *gpu.SupportedLimits) callconv(.Inline) bool);
    assertDecl(T, "adapterGetProperties", fn (adapter: *gpu.Adapter, properties: *gpu.Adapter.Properties) callconv(.Inline) void);
    assertDecl(T, "adapterHasFeature", fn (adapter: *gpu.Adapter, feature: gpu.FeatureName) callconv(.Inline) bool);
    assertDecl(T, "adapterRequestDevice", fn (adapter: *gpu.Adapter, descriptor: ?*const gpu.Device.Descriptor, callback: gpu.RequestDeviceCallback, userdata: ?*anyopaque) callconv(.Inline) void);
    assertDecl(T, "adapterReference", fn (adapter: *gpu.Adapter) callconv(.Inline) void);
    assertDecl(T, "adapterRelease", fn (adapter: *gpu.Adapter) callconv(.Inline) void);
    assertDecl(T, "bindGroupSetLabel", fn (bind_group: *gpu.BindGroup, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "bindGroupReference", fn (bind_group: *gpu.BindGroup) callconv(.Inline) void);
    assertDecl(T, "bindGroupRelease", fn (bind_group: *gpu.BindGroup) callconv(.Inline) void);
    assertDecl(T, "bindGroupLayoutSetLabel", fn (bind_group_layout: *gpu.BindGroupLayout, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "bindGroupLayoutReference", fn (bind_group_layout: *gpu.BindGroupLayout) callconv(.Inline) void);
    assertDecl(T, "bindGroupLayoutRelease", fn (bind_group_layout: *gpu.BindGroupLayout) callconv(.Inline) void);
    assertDecl(T, "bufferDestroy", fn (buffer: *gpu.Buffer) callconv(.Inline) void);
    assertDecl(T, "bufferGetConstMappedRange", fn (buffer: *gpu.Buffer, offset: usize, size: usize) callconv(.Inline) ?*const anyopaque);
    assertDecl(T, "bufferGetMappedRange", fn (buffer: *gpu.Buffer, offset: usize, size: usize) callconv(.Inline) ?*anyopaque);
    assertDecl(T, "bufferGetSize", fn (buffer: *gpu.Buffer) callconv(.Inline) u64);
    assertDecl(T, "bufferGetUsage", fn (buffer: *gpu.Buffer) callconv(.Inline) gpu.Buffer.UsageFlags);
    assertDecl(T, "bufferMapAsync", fn (buffer: *gpu.Buffer, mode: gpu.MapModeFlags, offset: usize, size: usize, callback: gpu.Buffer.MapCallback, userdata: ?*anyopaque) callconv(.Inline) void);
    assertDecl(T, "bufferSetLabel", fn (buffer: *gpu.Buffer, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "bufferUnmap", fn (buffer: *gpu.Buffer) callconv(.Inline) void);
    assertDecl(T, "bufferReference", fn (buffer: *gpu.Buffer) callconv(.Inline) void);
    assertDecl(T, "bufferRelease", fn (buffer: *gpu.Buffer) callconv(.Inline) void);
    assertDecl(T, "commandBufferSetLabel", fn (command_buffer: *gpu.CommandBuffer, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "commandBufferReference", fn (command_buffer: *gpu.CommandBuffer) callconv(.Inline) void);
    assertDecl(T, "commandBufferRelease", fn (command_buffer: *gpu.CommandBuffer) callconv(.Inline) void);
    assertDecl(T, "commandEncoderBeginComputePass", fn (command_encoder: *gpu.CommandEncoder, descriptor: ?*const gpu.ComputePassDescriptor) callconv(.Inline) *gpu.ComputePassEncoder);
    assertDecl(T, "commandEncoderBeginRenderPass", fn (command_encoder: *gpu.CommandEncoder, descriptor: *const gpu.RenderPassDescriptor) callconv(.Inline) *gpu.RenderPassEncoder);
    assertDecl(T, "commandEncoderClearBuffer", fn (command_encoder: *gpu.CommandEncoder, buffer: *gpu.Buffer, offset: u64, size: u64) callconv(.Inline) void);
    assertDecl(T, "commandEncoderCopyBufferToBuffer", fn (command_encoder: *gpu.CommandEncoder, source: *gpu.Buffer, source_offset: u64, destination: *gpu.Buffer, destination_offset: u64, size: u64) callconv(.Inline) void);
    assertDecl(T, "commandEncoderCopyBufferToTexture", fn (command_encoder: *gpu.CommandEncoder, source: *const gpu.ImageCopyBuffer, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) callconv(.Inline) void);
    assertDecl(T, "commandEncoderCopyTextureToBuffer", fn (command_encoder: *gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyBuffer, copy_size: *const gpu.Extent3D) callconv(.Inline) void);
    assertDecl(T, "commandEncoderCopyTextureToTexture", fn (command_encoder: *gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) callconv(.Inline) void);
    assertDecl(T, "commandEncoderCopyTextureToTextureInternal", fn (command_encoder: *gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) callconv(.Inline) void);
    assertDecl(T, "commandEncoderFinish", fn (command_encoder: *gpu.CommandEncoder, descriptor: ?*const gpu.CommandBuffer.Descriptor) callconv(.Inline) *gpu.CommandBuffer);
    assertDecl(T, "commandEncoderInjectValidationError", fn (command_encoder: *gpu.CommandEncoder, message: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "commandEncoderInsertDebugMarker", fn (command_encoder: *gpu.CommandEncoder, marker_label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "commandEncoderPopDebugGroup", fn (command_encoder: *gpu.CommandEncoder) callconv(.Inline) void);
    assertDecl(T, "commandEncoderPushDebugGroup", fn (command_encoder: *gpu.CommandEncoder, group_label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "commandEncoderResolveQuerySet", fn (command_encoder: *gpu.CommandEncoder, query_set: *gpu.QuerySet, first_query: u32, query_count: u32, destination: *gpu.Buffer, destination_offset: u64) callconv(.Inline) void);
    assertDecl(T, "commandEncoderSetLabel", fn (command_encoder: *gpu.CommandEncoder, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "commandEncoderWriteBuffer", fn (command_encoder: *gpu.CommandEncoder, buffer: *gpu.Buffer, buffer_offset: u64, data: [*]const u8, size: u64) callconv(.Inline) void);
    assertDecl(T, "commandEncoderWriteTimestamp", fn (command_encoder: *gpu.CommandEncoder, query_set: *gpu.QuerySet, query_index: u32) callconv(.Inline) void);
    assertDecl(T, "commandEncoderReference", fn (command_encoder: *gpu.CommandEncoder) callconv(.Inline) void);
    assertDecl(T, "commandEncoderRelease", fn (command_encoder: *gpu.CommandEncoder) callconv(.Inline) void);
    assertDecl(T, "computePassEncoderDispatchWorkgroups", fn (compute_pass_encoder: *gpu.ComputePassEncoder, workgroup_count_x: u32, workgroup_count_y: u32, workgroup_count_z: u32) callconv(.Inline) void);
    assertDecl(T, "computePassEncoderDispatchWorkgroupsIndirect", fn (compute_pass_encoder: *gpu.ComputePassEncoder, indirect_buffer: *gpu.Buffer, indirect_offset: u64) callconv(.Inline) void);
    assertDecl(T, "computePassEncoderEnd", fn (compute_pass_encoder: *gpu.ComputePassEncoder) callconv(.Inline) void);
    assertDecl(T, "computePassEncoderInsertDebugMarker", fn (compute_pass_encoder: *gpu.ComputePassEncoder, marker_label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "computePassEncoderPopDebugGroup", fn (compute_pass_encoder: *gpu.ComputePassEncoder) callconv(.Inline) void);
    assertDecl(T, "computePassEncoderPushDebugGroup", fn (compute_pass_encoder: *gpu.ComputePassEncoder, group_label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "computePassEncoderSetBindGroup", fn (compute_pass_encoder: *gpu.ComputePassEncoder, group_index: u32, group: *gpu.BindGroup, dynamic_offset_count: u32, dynamic_offsets: ?[*]const u32) callconv(.Inline) void);
    assertDecl(T, "computePassEncoderSetLabel", fn (compute_pass_encoder: *gpu.ComputePassEncoder, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "computePassEncoderSetPipeline", fn (compute_pass_encoder: *gpu.ComputePassEncoder, pipeline: *gpu.ComputePipeline) callconv(.Inline) void);
    assertDecl(T, "computePassEncoderWriteTimestamp", fn (compute_pass_encoder: *gpu.ComputePassEncoder, query_set: *gpu.QuerySet, query_index: u32) callconv(.Inline) void);
    assertDecl(T, "computePassEncoderReference", fn (compute_pass_encoder: *gpu.ComputePassEncoder) callconv(.Inline) void);
    assertDecl(T, "computePassEncoderRelease", fn (compute_pass_encoder: *gpu.ComputePassEncoder) callconv(.Inline) void);
    assertDecl(T, "computePipelineGetBindGroupLayout", fn (compute_pipeline: *gpu.ComputePipeline, group_index: u32) callconv(.Inline) *gpu.BindGroupLayout);
    assertDecl(T, "computePipelineSetLabel", fn (compute_pipeline: *gpu.ComputePipeline, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "computePipelineReference", fn (compute_pipeline: *gpu.ComputePipeline) callconv(.Inline) void);
    assertDecl(T, "computePipelineRelease", fn (compute_pipeline: *gpu.ComputePipeline) callconv(.Inline) void);
    assertDecl(T, "deviceCreateBindGroup", fn (device: *gpu.Device, descriptor: *const gpu.BindGroup.Descriptor) callconv(.Inline) *gpu.BindGroup);
    assertDecl(T, "deviceCreateBindGroupLayout", fn (device: *gpu.Device, descriptor: *const gpu.BindGroupLayout.Descriptor) callconv(.Inline) *gpu.BindGroupLayout);
    assertDecl(T, "deviceCreateBuffer", fn (device: *gpu.Device, descriptor: *const gpu.Buffer.Descriptor) callconv(.Inline) *gpu.Buffer);
    assertDecl(T, "deviceCreateCommandEncoder", fn (device: *gpu.Device, descriptor: ?*const gpu.CommandEncoder.Descriptor) callconv(.Inline) *gpu.CommandEncoder);
    assertDecl(T, "deviceCreateComputePipeline", fn (device: *gpu.Device, descriptor: *const gpu.ComputePipeline.Descriptor) callconv(.Inline) *gpu.ComputePipeline);
    assertDecl(T, "deviceCreateComputePipelineAsync", fn (device: *gpu.Device, descriptor: *const gpu.ComputePipeline.Descriptor, callback: gpu.CreateComputePipelineAsyncCallback, userdata: ?*anyopaque) callconv(.Inline) void);
    assertDecl(T, "deviceCreateErrorBuffer", fn (device: *gpu.Device) callconv(.Inline) *gpu.Buffer);
    assertDecl(T, "deviceCreateErrorExternalTexture", fn (device: *gpu.Device) callconv(.Inline) *gpu.ExternalTexture);
    assertDecl(T, "deviceCreateErrorTexture", fn (device: *gpu.Device, descriptor: *const gpu.Texture.Descriptor) callconv(.Inline) *gpu.Texture);
    assertDecl(T, "deviceCreateExternalTexture", fn (device: *gpu.Device, external_texture_descriptor: *const gpu.ExternalTexture.Descriptor) callconv(.Inline) *gpu.ExternalTexture);
    assertDecl(T, "deviceCreatePipelineLayout", fn (device: *gpu.Device, pipeline_layout_descriptor: *const gpu.PipelineLayout.Descriptor) callconv(.Inline) *gpu.PipelineLayout);
    assertDecl(T, "deviceCreateQuerySet", fn (device: *gpu.Device, descriptor: *const gpu.QuerySet.Descriptor) callconv(.Inline) *gpu.QuerySet);
    assertDecl(T, "deviceCreateRenderBundleEncoder", fn (device: *gpu.Device, descriptor: *const gpu.RenderBundleEncoder.Descriptor) callconv(.Inline) *gpu.RenderBundleEncoder);
    assertDecl(T, "deviceCreateRenderPipeline", fn (device: *gpu.Device, descriptor: *const gpu.RenderPipeline.Descriptor) callconv(.Inline) *gpu.RenderPipeline);
    assertDecl(T, "deviceCreateRenderPipelineAsync", fn (device: *gpu.Device, descriptor: *const gpu.RenderPipeline.Descriptor, callback: gpu.CreateRenderPipelineAsyncCallback, userdata: ?*anyopaque) callconv(.Inline) void);
    assertDecl(T, "deviceCreateSampler", fn (device: *gpu.Device, descriptor: ?*const gpu.Sampler.Descriptor) callconv(.Inline) *gpu.Sampler);
    assertDecl(T, "deviceCreateShaderModule", fn (device: *gpu.Device, descriptor: *const gpu.ShaderModule.Descriptor) callconv(.Inline) *gpu.ShaderModule);
    assertDecl(T, "deviceCreateSwapChain", fn (device: *gpu.Device, surface: ?*gpu.Surface, descriptor: *const gpu.SwapChain.Descriptor) callconv(.Inline) *gpu.SwapChain);
    assertDecl(T, "deviceCreateTexture", fn (device: *gpu.Device, descriptor: *const gpu.Texture.Descriptor) callconv(.Inline) *gpu.Texture);
    assertDecl(T, "deviceDestroy", fn (device: *gpu.Device) callconv(.Inline) void);
    assertDecl(T, "deviceEnumerateFeatures", fn (device: *gpu.Device, features: [*]gpu.FeatureName) callconv(.Inline) usize);
    assertDecl(T, "deviceGetLimits", fn (device: *gpu.Device, limits: *gpu.SupportedLimits) callconv(.Inline) bool);
    assertDecl(T, "deviceGetQueue", fn (device: *gpu.Device) callconv(.Inline) *gpu.Queue);
    assertDecl(T, "deviceHasFeature", fn (device: *gpu.Device, feature: gpu.FeatureName) callconv(.Inline) bool);
    assertDecl(T, "deviceInjectError", fn (device: *gpu.Device, typ: gpu.ErrorType, message: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "deviceLoseForTesting", fn (device: *gpu.Device) callconv(.Inline) void);
    assertDecl(T, "devicePopErrorScope", fn (device: *gpu.Device, callback: gpu.ErrorCallback, userdata: ?*anyopaque) callconv(.Inline) bool);
    assertDecl(T, "devicePushErrorScope", fn (device: *gpu.Device, filter: gpu.ErrorFilter) callconv(.Inline) void);
    assertDecl(T, "deviceSetDeviceLostCallback", fn (device: *gpu.Device, callback: gpu.Device.LostCallback, userdata: ?*anyopaque) callconv(.Inline) void);
    assertDecl(T, "deviceSetLabel", fn (device: *gpu.Device, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "deviceSetLoggingCallback", fn (device: *gpu.Device, callback: gpu.LoggingCallback, userdata: ?*anyopaque) callconv(.Inline) void);
    assertDecl(T, "deviceSetUncapturedErrorCallback", fn (device: *gpu.Device, callback: gpu.ErrorCallback, userdata: ?*anyopaque) callconv(.Inline) void);
    assertDecl(T, "deviceTick", fn (device: *gpu.Device) callconv(.Inline) void);
    assertDecl(T, "deviceReference", fn (device: *gpu.Device) callconv(.Inline) void);
    assertDecl(T, "deviceRelease", fn (device: *gpu.Device) callconv(.Inline) void);
    assertDecl(T, "externalTextureDestroy", fn (external_texture: *gpu.ExternalTexture) callconv(.Inline) void);
    assertDecl(T, "externalTextureSetLabel", fn (external_texture: *gpu.ExternalTexture, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "externalTextureReference", fn (external_texture: *gpu.ExternalTexture) callconv(.Inline) void);
    assertDecl(T, "externalTextureRelease", fn (external_texture: *gpu.ExternalTexture) callconv(.Inline) void);
    assertDecl(T, "instanceCreateSurface", fn (instance: *gpu.Instance, descriptor: *const gpu.Surface.Descriptor) callconv(.Inline) *gpu.Surface);
    assertDecl(T, "instanceRequestAdapter", fn (instance: *gpu.Instance, options: ?*const gpu.RequestAdapterOptions, callback: gpu.RequestAdapterCallback, userdata: ?*anyopaque) callconv(.Inline) void);
    assertDecl(T, "instanceReference", fn (instance: *gpu.Instance) callconv(.Inline) void);
    assertDecl(T, "instanceRelease", fn (instance: *gpu.Instance) callconv(.Inline) void);
    assertDecl(T, "pipelineLayoutSetLabel", fn (pipeline_layout: *gpu.PipelineLayout, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "pipelineLayoutReference", fn (pipeline_layout: *gpu.PipelineLayout) callconv(.Inline) void);
    assertDecl(T, "pipelineLayoutRelease", fn (pipeline_layout: *gpu.PipelineLayout) callconv(.Inline) void);
    assertDecl(T, "querySetDestroy", fn (query_set: *gpu.QuerySet) callconv(.Inline) void);
    assertDecl(T, "querySetGetCount", fn (query_set: *gpu.QuerySet) callconv(.Inline) u32);
    assertDecl(T, "querySetGetType", fn (query_set: *gpu.QuerySet) callconv(.Inline) gpu.QueryType);
    assertDecl(T, "querySetSetLabel", fn (query_set: *gpu.QuerySet, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "querySetReference", fn (query_set: *gpu.QuerySet) callconv(.Inline) void);
    assertDecl(T, "querySetRelease", fn (query_set: *gpu.QuerySet) callconv(.Inline) void);
    assertDecl(T, "queueCopyTextureForBrowser", fn (queue: *gpu.Queue, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D, options: *const gpu.CopyTextureForBrowserOptions) callconv(.Inline) void);
    assertDecl(T, "queueOnSubmittedWorkDone", fn (queue: *gpu.Queue, signal_value: u64, callback: gpu.Queue.WorkDoneCallback, userdata: ?*anyopaque) callconv(.Inline) void);
    assertDecl(T, "queueSetLabel", fn (queue: *gpu.Queue, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "queueSubmit", fn (queue: *gpu.Queue, command_count: u32, commands: [*]*const gpu.CommandBuffer) callconv(.Inline) void);
    assertDecl(T, "queueWriteBuffer", fn (queue: *gpu.Queue, buffer: *gpu.Buffer, buffer_offset: u64, data: *anyopaque, size: usize) callconv(.Inline) void);
    assertDecl(T, "queueWriteTexture", fn (queue: *gpu.Queue, destination: *const gpu.ImageCopyTexture, data: *const anyopaque, data_size: usize, data_layout: *const gpu.Texture.DataLayout, write_size: *const gpu.Extent3D) callconv(.Inline) void);
    assertDecl(T, "queueReference", fn (queue: *gpu.Queue) callconv(.Inline) void);
    assertDecl(T, "queueRelease", fn (queue: *gpu.Queue) callconv(.Inline) void);
    assertDecl(T, "renderBundleReference", fn (render_bundle: *gpu.RenderBundle) callconv(.Inline) void);
    assertDecl(T, "renderBundleRelease", fn (render_bundle: *gpu.RenderBundle) callconv(.Inline) void);
    assertDecl(T, "renderBundleEncoderDraw", fn (render_bundle_encoder: *gpu.RenderBundleEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) callconv(.Inline) void);
    assertDecl(T, "renderBundleEncoderDrawIndexed", fn (render_bundle_encoder: *gpu.RenderBundleEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: i32, first_instance: u32) callconv(.Inline) void);
    assertDecl(T, "renderBundleEncoderDrawIndexedIndirect", fn (render_bundle_encoder: *gpu.RenderBundleEncoder, indirect_buffer: *gpu.Buffer, indirect_offset: u64) callconv(.Inline) void);
    assertDecl(T, "renderBundleEncoderDrawIndirect", fn (render_bundle_encoder: *gpu.RenderBundleEncoder, indirect_buffer: *gpu.Buffer, indirect_offset: u64) callconv(.Inline) void);
    assertDecl(T, "renderBundleEncoderFinish", fn (render_bundle_encoder: *gpu.RenderBundleEncoder, descriptor: ?*const gpu.RenderBundle.Descriptor) callconv(.Inline) *gpu.RenderBundle);
    assertDecl(T, "renderBundleEncoderInsertDebugMarker", fn (render_bundle_encoder: *gpu.RenderBundleEncoder, marker_label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "renderBundleEncoderPopDebugGroup", fn (render_bundle_encoder: *gpu.RenderBundleEncoder) callconv(.Inline) void);
    assertDecl(T, "renderBundleEncoderPushDebugGroup", fn (render_bundle_encoder: *gpu.RenderBundleEncoder, group_label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "renderBundleEncoderSetBindGroup", fn (render_bundle_encoder: *gpu.RenderBundleEncoder, group_index: u32, group: *gpu.BindGroup, dynamic_offset_count: u32, dynamic_offsets: ?[*]const u32) callconv(.Inline) void);
    assertDecl(T, "renderBundleEncoderSetIndexBuffer", fn (render_bundle_encoder: *gpu.RenderBundleEncoder, buffer: *gpu.Buffer, format: gpu.IndexFormat, offset: u64, size: u64) callconv(.Inline) void);
    assertDecl(T, "renderBundleEncoderSetLabel", fn (render_bundle_encoder: *gpu.RenderBundleEncoder, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "renderBundleEncoderSetPipeline", fn (render_bundle_encoder: *gpu.RenderBundleEncoder, pipeline: *gpu.RenderPipeline) callconv(.Inline) void);
    assertDecl(T, "renderBundleEncoderSetVertexBuffer", fn (render_bundle_encoder: *gpu.RenderBundleEncoder, slot: u32, buffer: *gpu.Buffer, offset: u64, size: u64) callconv(.Inline) void);
    assertDecl(T, "renderBundleEncoderReference", fn (render_bundle_encoder: *gpu.RenderBundleEncoder) callconv(.Inline) void);
    assertDecl(T, "renderBundleEncoderRelease", fn (render_bundle_encoder: *gpu.RenderBundleEncoder) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderBeginOcclusionQuery", fn (render_pass_encoder: *gpu.RenderPassEncoder, query_index: u32) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderDraw", fn (render_pass_encoder: *gpu.RenderPassEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderDrawIndexed", fn (render_pass_encoder: *gpu.RenderPassEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: i32, first_instance: u32) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderDrawIndexedIndirect", fn (render_pass_encoder: *gpu.RenderPassEncoder, indirect_buffer: *gpu.Buffer, indirect_offset: u64) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderDrawIndirect", fn (render_pass_encoder: *gpu.RenderPassEncoder, indirect_buffer: *gpu.Buffer, indirect_offset: u64) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderEnd", fn (render_pass_encoder: *gpu.RenderPassEncoder) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderEndOcclusionQuery", fn (render_pass_encoder: *gpu.RenderPassEncoder) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderExecuteBundles", fn (render_pass_encoder: *gpu.RenderPassEncoder, bundles_count: u32, bundles: [*]const *const gpu.RenderBundle) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderInsertDebugMarker", fn (render_pass_encoder: *gpu.RenderPassEncoder, marker_label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderPopDebugGroup", fn (render_pass_encoder: *gpu.RenderPassEncoder) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderPushDebugGroup", fn (render_pass_encoder: *gpu.RenderPassEncoder, group_label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderSetBindGroup", fn (render_pass_encoder: *gpu.RenderPassEncoder, group_index: u32, group: *gpu.BindGroup, dynamic_offset_count: u32, dynamic_offsets: ?[*]const u32) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderSetBlendConstant", fn (render_pass_encoder: *gpu.RenderPassEncoder, color: *const gpu.Color) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderSetIndexBuffer", fn (render_pass_encoder: *gpu.RenderPassEncoder, buffer: *gpu.Buffer, format: gpu.IndexFormat, offset: u64, size: u64) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderSetLabel", fn (render_pass_encoder: *gpu.RenderPassEncoder, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderSetPipeline", fn (render_pass_encoder: *gpu.RenderPassEncoder, pipeline: *gpu.RenderPipeline) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderSetScissorRect", fn (render_pass_encoder: *gpu.RenderPassEncoder, x: u32, y: u32, width: u32, height: u32) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderSetStencilReference", fn (render_pass_encoder: *gpu.RenderPassEncoder, reference: u32) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderSetVertexBuffer", fn (render_pass_encoder: *gpu.RenderPassEncoder, slot: u32, buffer: *gpu.Buffer, offset: u64, size: u64) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderSetViewport", fn (render_pass_encoder: *gpu.RenderPassEncoder, x: f32, y: f32, width: f32, height: f32, min_depth: f32, max_depth: f32) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderWriteTimestamp", fn (render_pass_encoder: *gpu.RenderPassEncoder, query_set: *gpu.QuerySet, query_index: u32) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderReference", fn (render_pass_encoder: *gpu.RenderPassEncoder) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderRelease", fn (render_pass_encoder: *gpu.RenderPassEncoder) callconv(.Inline) void);
    assertDecl(T, "renderPipelineGetBindGroupLayout", fn (render_pipeline: *gpu.RenderPipeline, group_index: u32) callconv(.Inline) *gpu.BindGroupLayout);
    assertDecl(T, "renderPipelineSetLabel", fn (render_pipeline: *gpu.RenderPipeline, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "renderPipelineReference", fn (render_pipeline: *gpu.RenderPipeline) callconv(.Inline) void);
    assertDecl(T, "renderPipelineRelease", fn (render_pipeline: *gpu.RenderPipeline) callconv(.Inline) void);
    assertDecl(T, "samplerSetLabel", fn (sampler: *gpu.Sampler, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "samplerReference", fn (sampler: *gpu.Sampler) callconv(.Inline) void);
    assertDecl(T, "samplerRelease", fn (sampler: *gpu.Sampler) callconv(.Inline) void);
    assertDecl(T, "shaderModuleGetCompilationInfo", fn (shader_module: *gpu.ShaderModule, callback: gpu.CompilationInfoCallback, userdata: ?*anyopaque) callconv(.Inline) void);
    assertDecl(T, "shaderModuleSetLabel", fn (shader_module: *gpu.ShaderModule, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "shaderModuleReference", fn (shader_module: *gpu.ShaderModule) callconv(.Inline) void);
    assertDecl(T, "shaderModuleRelease", fn (shader_module: *gpu.ShaderModule) callconv(.Inline) void);
    assertDecl(T, "surfaceReference", fn (surface: *gpu.Surface) callconv(.Inline) void);
    assertDecl(T, "surfaceRelease", fn (surface: *gpu.Surface) callconv(.Inline) void);
    assertDecl(T, "swapChainConfigure", fn (swap_chain: *gpu.SwapChain, format: gpu.Texture.Format, allowed_usage: gpu.Texture.UsageFlags, width: u32, height: u32) callconv(.Inline) void);
    assertDecl(T, "swapChainGetCurrentTextureView", fn (swap_chain: *gpu.SwapChain) callconv(.Inline) *gpu.TextureView);
    assertDecl(T, "swapChainPresent", fn (swap_chain: *gpu.SwapChain) callconv(.Inline) void);
    assertDecl(T, "swapChainReference", fn (swap_chain: *gpu.SwapChain) callconv(.Inline) void);
    assertDecl(T, "swapChainRelease", fn (swap_chain: *gpu.SwapChain) callconv(.Inline) void);
    assertDecl(T, "textureCreateView", fn (texture: *gpu.Texture, descriptor: ?*const gpu.TextureView.Descriptor) callconv(.Inline) *gpu.TextureView);
    assertDecl(T, "textureDestroy", fn (texture: *gpu.Texture) callconv(.Inline) void);
    assertDecl(T, "textureGetDepthOrArrayLayers", fn (texture: *gpu.Texture) callconv(.Inline) u32);
    assertDecl(T, "textureGetDimension", fn (texture: *gpu.Texture) callconv(.Inline) gpu.Texture.Dimension);
    assertDecl(T, "textureGetFormat", fn (texture: *gpu.Texture) callconv(.Inline) gpu.Texture.Format);
    assertDecl(T, "textureGetHeight", fn (texture: *gpu.Texture) callconv(.Inline) u32);
    assertDecl(T, "textureGetMipLevelCount", fn (texture: *gpu.Texture) callconv(.Inline) u32);
    assertDecl(T, "textureGetSampleCount", fn (texture: *gpu.Texture) callconv(.Inline) u32);
    assertDecl(T, "textureGetUsage", fn (texture: *gpu.Texture) callconv(.Inline) gpu.Texture.UsageFlags);
    assertDecl(T, "textureGetWidth", fn (texture: *gpu.Texture) callconv(.Inline) u32);
    assertDecl(T, "textureSetLabel", fn (texture: *gpu.Texture, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "textureReference", fn (texture: *gpu.Texture) callconv(.Inline) void);
    assertDecl(T, "textureRelease", fn (texture: *gpu.Texture) callconv(.Inline) void);
    assertDecl(T, "textureViewSetLabel", fn (texture_view: *gpu.TextureView, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "textureViewReference", fn (texture_view: *gpu.TextureView) callconv(.Inline) void);
    assertDecl(T, "textureViewRelease", fn (texture_view: *gpu.TextureView) callconv(.Inline) void);
    return T;
}

fn assertDecl(comptime T: anytype, comptime name: []const u8, comptime Decl: type) void {
    if (!@hasDecl(T, name)) @compileError("gpu.Interface missing declaration: " ++ @typeName(Decl));
    const FoundDecl = @TypeOf(@field(T, name));
    if (FoundDecl != Decl) @compileError("gpu.Interface field '" ++ name ++ "'\n\texpected type: " ++ @typeName(Decl) ++ "\n\t   found type: " ++ @typeName(FoundDecl));
}

/// Exports C ABI function declarations for the given gpu.Interface implementation.
pub fn Export(comptime T: type) type {
    _ = Interface(T); // verify implementation is a valid interface
    return struct {
        // WGPU_EXPORT WGPUInstance wgpuCreateInstance(WGPUInstanceDescriptor const * descriptor);
        export fn wgpuCreateInstance(descriptor: ?*const gpu.Instance.Descriptor) ?*gpu.Instance {
            return T.createInstance(descriptor);
        }

        // WGPU_EXPORT WGPUProc wgpuGetProcAddress(WGPUDevice device, char const * procName);
        export fn wgpuGetProcAddress(device: *gpu.Device, proc_name: [*:0]const u8) ?gpu.Proc {
            return T.getProcAddress(device, proc_name);
        }

        // WGPU_EXPORT WGPUDevice wgpuAdapterCreateDevice(WGPUAdapter adapter, WGPUDeviceDescriptor const * descriptor /* nullable */);
        export fn wgpuAdapterCreateDevice(adapter: *gpu.Adapter, descriptor: ?*const gpu.Device.Descriptor) ?*gpu.Device {
            return T.adapterCreateDevice(adapter, descriptor);
        }

        // WGPU_EXPORT size_t wgpuAdapterEnumerateFeatures(WGPUAdapter adapter, WGPUFeatureName * features);
        export fn wgpuAdapterEnumerateFeatures(adapter: *gpu.Adapter, features: ?[*]gpu.FeatureName) usize {
            return T.adapterEnumerateFeatures(adapter, features);
        }

        // WGPU_EXPORT bool wgpuAdapterGetLimits(WGPUAdapter adapter, WGPUSupportedLimits * limits);
        export fn wgpuAdapterGetLimits(adapter: *gpu.Adapter, limits: *gpu.SupportedLimits) bool {
            return T.adapterGetLimits(adapter, limits);
        }

        // WGPU_EXPORT void wgpuAdapterGetProperties(WGPUAdapter adapter, WGPUAdapterProperties * properties);
        export fn wgpuAdapterGetProperties(adapter: *gpu.Adapter, properties: *gpu.Adapter.Properties) void {
            return T.adapterGetProperties(adapter, properties);
        }

        // WGPU_EXPORT bool wgpuAdapterHasFeature(WGPUAdapter adapter, WGPUFeatureName feature);
        export fn wgpuAdapterHasFeature(adapter: *gpu.Adapter, feature: gpu.FeatureName) bool {
            return T.adapterHasFeature(adapter, feature);
        }

        // WGPU_EXPORT void wgpuAdapterRequestDevice(WGPUAdapter adapter, WGPUDeviceDescriptor const * descriptor /* nullable */, WGPURequestDeviceCallback callback, void * userdata);
        export fn wgpuAdapterRequestDevice(adapter: *gpu.Adapter, descriptor: ?*const gpu.Device.Descriptor, callback: gpu.RequestDeviceCallback, userdata: ?*anyopaque) void {
            T.adapterRequestDevice(adapter, descriptor, callback, userdata);
        }

        // WGPU_EXPORT void wgpuAdapterReference(WGPUAdapter adapter);
        export fn wgpuAdapterReference(adapter: *gpu.Adapter) void {
            T.adapterReference(adapter);
        }

        // WGPU_EXPORT void wgpuAdapterRelease(WGPUAdapter adapter);
        export fn wgpuAdapterRelease(adapter: *gpu.Adapter) void {
            T.adapterRelease(adapter);
        }

        // WGPU_EXPORT void wgpuBindGroupSetLabel(WGPUBindGroup bindGroup, char const * label);
        export fn wgpuBindGroupSetLabel(bind_group: *gpu.BindGroup, label: [*:0]const u8) void {
            T.bindGroupSetLabel(bind_group, label);
        }

        // WGPU_EXPORT void wgpuBindGroupReference(WGPUBindGroup bindGroup);
        export fn wgpuBindGroupReference(bind_group: *gpu.BindGroup) void {
            T.bindGroupReference(bind_group);
        }

        // WGPU_EXPORT void wgpuBindGroupRelease(WGPUBindGroup bindGroup);
        export fn wgpuBindGroupRelease(bind_group: *gpu.BindGroup) void {
            T.bindGroupRelease(bind_group);
        }

        // WGPU_EXPORT void wgpuBindGroupLayoutSetLabel(WGPUBindGroupLayout bindGroupLayout, char const * label);
        export fn wgpuBindGroupLayoutSetLabel(bind_group_layout: *gpu.BindGroupLayout, label: [*:0]const u8) void {
            T.bindGroupLayoutSetLabel(bind_group_layout, label);
        }

        // WGPU_EXPORT void wgpuBindGroupLayoutReference(WGPUBindGroupLayout bindGroupLayout);
        export fn wgpuBindGroupLayoutReference(bind_group_layout: *gpu.BindGroupLayout) void {
            T.bindGroupLayoutReference(bind_group_layout);
        }

        // WGPU_EXPORT void wgpuBindGroupLayoutRelease(WGPUBindGroupLayout bindGroupLayout);
        export fn wgpuBindGroupLayoutRelease(bind_group_layout: *gpu.BindGroupLayout) void {
            T.bindGroupLayoutRelease(bind_group_layout);
        }

        // WGPU_EXPORT void wgpuBufferDestroy(WGPUBuffer buffer);
        export fn wgpuBufferDestroy(buffer: *gpu.Buffer) void {
            T.bufferDestroy(buffer);
        }

        // WGPU_EXPORT void const * wgpuBufferGetConstMappedRange(WGPUBuffer buffer, size_t offset, size_t size);
        export fn wgpuBufferGetConstMappedRange(buffer: *gpu.Buffer, offset: usize, size: usize) ?*const anyopaque {
            return T.bufferGetConstMappedRange(buffer, offset, size);
        }

        // WGPU_EXPORT void * wgpuBufferGetMappedRange(WGPUBuffer buffer, size_t offset, size_t size);
        export fn wgpuBufferGetMappedRange(buffer: *gpu.Buffer, offset: usize, size: usize) ?*anyopaque {
            return T.bufferGetMappedRange(buffer, offset, size);
        }

        // WGPU_EXPORT uint64_t wgpuBufferGetSize(WGPUBuffer buffer);
        export fn wgpuBufferGetSize(buffer: *gpu.Buffer) u64 {
            return T.bufferGetSize(buffer);
        }

        // WGPU_EXPORT WGPUBufferUsage wgpuBufferGetUsage(WGPUBuffer buffer);
        export fn wgpuBufferGetUsage(buffer: *gpu.Buffer) gpu.Buffer.UsageFlags {
            return T.bufferGetUsage(buffer);
        }

        // TODO: Zig cannot currently export a packed struct gpu.MapModeFlags, so we use a u32 for
        // now.
        // WGPU_EXPORT void wgpuBufferMapAsync(WGPUBuffer buffer, WGPUMapModeFlags mode, size_t offset, size_t size, WGPUBufferMapCallback callback, void * userdata);
        export fn wgpuBufferMapAsync(buffer: *gpu.Buffer, mode: u32, offset: usize, size: usize, callback: gpu.Buffer.MapCallback, userdata: ?*anyopaque) void {
            T.bufferMapAsync(buffer, @bitCast(gpu.MapModeFlags, mode), offset, size, callback, userdata);
        }

        // WGPU_EXPORT void wgpuBufferSetLabel(WGPUBuffer buffer, char const * label);
        export fn wgpuBufferSetLabel(buffer: *gpu.Buffer, label: [*:0]const u8) void {
            T.bufferSetLabel(buffer, label);
        }

        // WGPU_EXPORT void wgpuBufferUnmap(WGPUBuffer buffer);
        export fn wgpuBufferUnmap(buffer: *gpu.Buffer) void {
            T.bufferUnmap(buffer);
        }

        // WGPU_EXPORT void wgpuBufferReference(WGPUBuffer buffer);
        export fn wgpuBufferReference(buffer: *gpu.Buffer) void {
            T.bufferReference(buffer);
        }

        // WGPU_EXPORT void wgpuBufferRelease(WGPUBuffer buffer);
        export fn wgpuBufferRelease(buffer: *gpu.Buffer) void {
            T.bufferRelease(buffer);
        }

        // WGPU_EXPORT void wgpuCommandBufferSetLabel(WGPUCommandBuffer commandBuffer, char const * label);
        export fn wgpuCommandBufferSetLabel(command_buffer: *gpu.CommandBuffer, label: [*:0]const u8) void {
            T.commandBufferSetLabel(command_buffer, label);
        }

        // WGPU_EXPORT void wgpuCommandBufferReference(WGPUCommandBuffer commandBuffer);
        export fn wgpuCommandBufferReference(command_buffer: *gpu.CommandBuffer) void {
            T.commandBufferReference(command_buffer);
        }

        // WGPU_EXPORT void wgpuCommandBufferRelease(WGPUCommandBuffer commandBuffer);
        export fn wgpuCommandBufferRelease(command_buffer: *gpu.CommandBuffer) void {
            T.commandBufferRelease(command_buffer);
        }

        // WGPU_EXPORT WGPUComputePassEncoder wgpuCommandEncoderBeginComputePass(WGPUCommandEncoder commandEncoder, WGPUComputePassDescriptor const * descriptor /* nullable */);
        export fn wgpuCommandEncoderBeginComputePass(command_encoder: *gpu.CommandEncoder, descriptor: ?*const gpu.ComputePassDescriptor) *gpu.ComputePassEncoder {
            return T.commandEncoderBeginComputePass(command_encoder, descriptor);
        }

        // WGPU_EXPORT WGPURenderPassEncoder wgpuCommandEncoderBeginRenderPass(WGPUCommandEncoder commandEncoder, WGPURenderPassDescriptor const * descriptor);
        export fn wgpuCommandEncoderBeginRenderPass(command_encoder: *gpu.CommandEncoder, descriptor: *const gpu.RenderPassDescriptor) *gpu.RenderPassEncoder {
            return T.commandEncoderBeginRenderPass(command_encoder, descriptor);
        }

        // WGPU_EXPORT void wgpuCommandEncoderClearBuffer(WGPUCommandEncoder commandEncoder, WGPUBuffer buffer, uint64_t offset, uint64_t size);
        export fn wgpuCommandEncoderClearBuffer(command_encoder: *gpu.CommandEncoder, buffer: *gpu.Buffer, offset: u64, size: u64) void {
            T.commandEncoderClearBuffer(command_encoder, buffer, offset, size);
        }

        // WGPU_EXPORT void wgpuCommandEncoderCopyBufferToBuffer(WGPUCommandEncoder commandEncoder, WGPUBuffer source, uint64_t sourceOffset, WGPUBuffer destination, uint64_t destinationOffset, uint64_t size);
        export fn wgpuCommandEncoderCopyBufferToBuffer(command_encoder: *gpu.CommandEncoder, source: *gpu.Buffer, source_offset: u64, destination: *gpu.Buffer, destination_offset: u64, size: u64) void {
            T.commandEncoderCopyBufferToBuffer(command_encoder, source, source_offset, destination, destination_offset, size);
        }

        // WGPU_EXPORT void wgpuCommandEncoderCopyBufferToTexture(WGPUCommandEncoder commandEncoder, WGPUImageCopyBuffer const * source, WGPUImageCopyTexture const * destination, WGPUExtent3D const * copySize);
        export fn wgpuCommandEncoderCopyBufferToTexture(command_encoder: *gpu.CommandEncoder, source: *const gpu.ImageCopyBuffer, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) void {
            T.commandEncoderCopyBufferToTexture(command_encoder, source, destination, copy_size);
        }

        // WGPU_EXPORT void wgpuCommandEncoderCopyTextureToBuffer(WGPUCommandEncoder commandEncoder, WGPUImageCopyTexture const * source, WGPUImageCopyBuffer const * destination, WGPUExtent3D const * copySize);
        export fn wgpuCommandEncoderCopyTextureToBuffer(command_encoder: *gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyBuffer, copy_size: *const gpu.Extent3D) void {
            T.commandEncoderCopyTextureToBuffer(command_encoder, source, destination, copy_size);
        }

        // WGPU_EXPORT void wgpuCommandEncoderCopyTextureToTexture(WGPUCommandEncoder commandEncoder, WGPUImageCopyTexture const * source, WGPUImageCopyTexture const * destination, WGPUExtent3D const * copySize);
        export fn wgpuCommandEncoderCopyTextureToTexture(command_encoder: *gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) void {
            T.commandEncoderCopyTextureToTexture(command_encoder, source, destination, copy_size);
        }

        // WGPU_EXPORT void wgpuCommandEncoderCopyTextureToTextureInternal(WGPUCommandEncoder commandEncoder, WGPUImageCopyTexture const * source, WGPUImageCopyTexture const * destination, WGPUExtent3D const * copySize);
        export fn wgpuCommandEncoderCopyTextureToTextureInternal(command_encoder: *gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) void {
            T.commandEncoderCopyTextureToTextureInternal(command_encoder, source, destination, copy_size);
        }

        // WGPU_EXPORT WGPUCommandBuffer wgpuCommandEncoderFinish(WGPUCommandEncoder commandEncoder, WGPUCommandBufferDescriptor const * descriptor /* nullable */);
        export fn wgpuCommandEncoderFinish(command_encoder: *gpu.CommandEncoder, descriptor: ?*const gpu.CommandBuffer.Descriptor) *gpu.CommandBuffer {
            return T.commandEncoderFinish(command_encoder, descriptor);
        }

        // WGPU_EXPORT void wgpuCommandEncoderInjectValidationError(WGPUCommandEncoder commandEncoder, char const * message);
        export fn wgpuCommandEncoderInjectValidationError(command_encoder: *gpu.CommandEncoder, message: [*:0]const u8) void {
            T.commandEncoderInjectValidationError(command_encoder, message);
        }

        // WGPU_EXPORT void wgpuCommandEncoderInsertDebugMarker(WGPUCommandEncoder commandEncoder, char const * markerLabel);
        export fn wgpuCommandEncoderInsertDebugMarker(command_encoder: *gpu.CommandEncoder, marker_label: [*:0]const u8) void {
            T.commandEncoderInsertDebugMarker(command_encoder, marker_label);
        }

        // WGPU_EXPORT void wgpuCommandEncoderPopDebugGroup(WGPUCommandEncoder commandEncoder);
        export fn wgpuCommandEncoderPopDebugGroup(command_encoder: *gpu.CommandEncoder) void {
            T.commandEncoderPopDebugGroup(command_encoder);
        }

        // WGPU_EXPORT void wgpuCommandEncoderPushDebugGroup(WGPUCommandEncoder commandEncoder, char const * groupLabel);
        export fn wgpuCommandEncoderPushDebugGroup(command_encoder: *gpu.CommandEncoder, group_label: [*:0]const u8) void {
            T.commandEncoderPushDebugGroup(command_encoder, group_label);
        }

        // WGPU_EXPORT void wgpuCommandEncoderResolveQuerySet(WGPUCommandEncoder commandEncoder, WGPUQuerySet querySet, uint32_t firstQuery, uint32_t queryCount, WGPUBuffer destination, uint64_t destinationOffset);
        export fn wgpuCommandEncoderResolveQuerySet(command_encoder: *gpu.CommandEncoder, query_set: *gpu.QuerySet, first_query: u32, query_count: u32, destination: *gpu.Buffer, destination_offset: u64) void {
            T.commandEncoderResolveQuerySet(command_encoder, query_set, first_query, query_count, destination, destination_offset);
        }

        // WGPU_EXPORT void wgpuCommandEncoderSetLabel(WGPUCommandEncoder commandEncoder, char const * label);
        export fn wgpuCommandEncoderSetLabel(command_encoder: *gpu.CommandEncoder, label: [*:0]const u8) void {
            T.commandEncoderSetLabel(command_encoder, label);
        }

        // WGPU_EXPORT void wgpuCommandEncoderWriteBuffer(WGPUCommandEncoder commandEncoder, WGPUBuffer buffer, uint64_t bufferOffset, uint8_t const * data, uint64_t size);
        export fn wgpuCommandEncoderWriteBuffer(command_encoder: *gpu.CommandEncoder, buffer: *gpu.Buffer, buffer_offset: u64, data: [*]const u8, size: u64) void {
            T.commandEncoderWriteBuffer(command_encoder, buffer, buffer_offset, data, size);
        }

        // WGPU_EXPORT void wgpuCommandEncoderWriteTimestamp(WGPUCommandEncoder commandEncoder, WGPUQuerySet querySet, uint32_t queryIndex);
        export fn wgpuCommandEncoderWriteTimestamp(command_encoder: *gpu.CommandEncoder, query_set: *gpu.QuerySet, query_index: u32) void {
            T.commandEncoderWriteTimestamp(command_encoder, query_set, query_index);
        }

        // WGPU_EXPORT void wgpuCommandEncoderReference(WGPUCommandEncoder commandEncoder);
        export fn wgpuCommandEncoderReference(command_encoder: *gpu.CommandEncoder) void {
            T.commandEncoderReference(command_encoder);
        }

        // WGPU_EXPORT void wgpuCommandEncoderRelease(WGPUCommandEncoder commandEncoder);
        export fn wgpuCommandEncoderRelease(command_encoder: *gpu.CommandEncoder) void {
            T.commandEncoderRelease(command_encoder);
        }

        // WGPU_EXPORT void wgpuComputePassEncoderDispatchWorkgroups(WGPUComputePassEncoder computePassEncoder, uint32_t workgroupCountX, uint32_t workgroupCountY, uint32_t workgroupCountZ);
        export fn wgpuComputePassEncoderDispatchWorkgroups(compute_pass_encoder: *gpu.ComputePassEncoder, workgroup_count_x: u32, workgroup_count_y: u32, workgroup_count_z: u32) void {
            T.computePassEncoderDispatchWorkgroups(compute_pass_encoder, workgroup_count_x, workgroup_count_y, workgroup_count_z);
        }

        // WGPU_EXPORT void wgpuComputePassEncoderDispatchWorkgroupsIndirect(WGPUComputePassEncoder computePassEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
        export fn wgpuComputePassEncoderDispatchWorkgroupsIndirect(compute_pass_encoder: *gpu.ComputePassEncoder, indirect_buffer: *gpu.Buffer, indirect_offset: u64) void {
            T.computePassEncoderDispatchWorkgroupsIndirect(compute_pass_encoder, indirect_buffer, indirect_offset);
        }

        // WGPU_EXPORT void wgpuComputePassEncoderEnd(WGPUComputePassEncoder computePassEncoder);
        export fn wgpuComputePassEncoderEnd(compute_pass_encoder: *gpu.ComputePassEncoder) void {
            T.computePassEncoderEnd(compute_pass_encoder);
        }

        // WGPU_EXPORT void wgpuComputePassEncoderInsertDebugMarker(WGPUComputePassEncoder computePassEncoder, char const * markerLabel);
        export fn wgpuComputePassEncoderInsertDebugMarker(compute_pass_encoder: *gpu.ComputePassEncoder, marker_label: [*:0]const u8) void {
            T.computePassEncoderInsertDebugMarker(compute_pass_encoder, marker_label);
        }

        // WGPU_EXPORT void wgpuComputePassEncoderPopDebugGroup(WGPUComputePassEncoder computePassEncoder);
        export fn wgpuComputePassEncoderPopDebugGroup(compute_pass_encoder: *gpu.ComputePassEncoder) void {
            T.computePassEncoderPopDebugGroup(compute_pass_encoder);
        }

        // WGPU_EXPORT void wgpuComputePassEncoderPushDebugGroup(WGPUComputePassEncoder computePassEncoder, char const * groupLabel);
        export fn wgpuComputePassEncoderPushDebugGroup(compute_pass_encoder: *gpu.ComputePassEncoder, group_label: [*:0]const u8) void {
            T.computePassEncoderPushDebugGroup(compute_pass_encoder, group_label);
        }

        // WGPU_EXPORT void wgpuComputePassEncoderSetBindGroup(WGPUComputePassEncoder computePassEncoder, uint32_t groupIndex, WGPUBindGroup group, uint32_t dynamicOffsetCount, uint32_t const * dynamicOffsets);
        export fn wgpuComputePassEncoderSetBindGroup(compute_pass_encoder: *gpu.ComputePassEncoder, group_index: u32, group: *gpu.BindGroup, dynamic_offset_count: u32, dynamic_offsets: ?[*]const u32) void {
            T.computePassEncoderSetBindGroup(compute_pass_encoder, group_index, group, dynamic_offset_count, dynamic_offsets);
        }

        // WGPU_EXPORT void wgpuComputePassEncoderSetLabel(WGPUComputePassEncoder computePassEncoder, char const * label);
        export fn wgpuComputePassEncoderSetLabel(compute_pass_encoder: *gpu.ComputePassEncoder, label: [*:0]const u8) void {
            T.computePassEncoderSetLabel(compute_pass_encoder, label);
        }

        // WGPU_EXPORT void wgpuComputePassEncoderSetPipeline(WGPUComputePassEncoder computePassEncoder, WGPUComputePipeline pipeline);
        export fn wgpuComputePassEncoderSetPipeline(compute_pass_encoder: *gpu.ComputePassEncoder, pipeline: *gpu.ComputePipeline) void {
            T.computePassEncoderSetPipeline(compute_pass_encoder, pipeline);
        }

        // WGPU_EXPORT void wgpuComputePassEncoderWriteTimestamp(WGPUComputePassEncoder computePassEncoder, WGPUQuerySet querySet, uint32_t queryIndex);
        export fn wgpuComputePassEncoderWriteTimestamp(compute_pass_encoder: *gpu.ComputePassEncoder, query_set: *gpu.QuerySet, query_index: u32) void {
            T.computePassEncoderWriteTimestamp(compute_pass_encoder, query_set, query_index);
        }

        // WGPU_EXPORT void wgpuComputePassEncoderReference(WGPUComputePassEncoder computePassEncoder);
        export fn wgpuComputePassEncoderReference(compute_pass_encoder: *gpu.ComputePassEncoder) void {
            T.computePassEncoderReference(compute_pass_encoder);
        }

        // WGPU_EXPORT void wgpuComputePassEncoderRelease(WGPUComputePassEncoder computePassEncoder);
        export fn wgpuComputePassEncoderRelease(compute_pass_encoder: *gpu.ComputePassEncoder) void {
            T.computePassEncoderRelease(compute_pass_encoder);
        }

        // WGPU_EXPORT WGPUBindGroupLayout wgpuComputePipelineGetBindGroupLayout(WGPUComputePipeline computePipeline, uint32_t groupIndex);
        export fn wgpuComputePipelineGetBindGroupLayout(compute_pipeline: *gpu.ComputePipeline, group_index: u32) *gpu.BindGroupLayout {
            return T.computePipelineGetBindGroupLayout(compute_pipeline, group_index);
        }

        // WGPU_EXPORT void wgpuComputePipelineSetLabel(WGPUComputePipeline computePipeline, char const * label);
        export fn wgpuComputePipelineSetLabel(compute_pipeline: *gpu.ComputePipeline, label: [*:0]const u8) void {
            T.computePipelineSetLabel(compute_pipeline, label);
        }

        // WGPU_EXPORT void wgpuComputePipelineReference(WGPUComputePipeline computePipeline);
        export fn wgpuComputePipelineReference(compute_pipeline: *gpu.ComputePipeline) void {
            T.computePipelineReference(compute_pipeline);
        }

        // WGPU_EXPORT void wgpuComputePipelineRelease(WGPUComputePipeline computePipeline);
        export fn wgpuComputePipelineRelease(compute_pipeline: *gpu.ComputePipeline) void {
            T.computePipelineRelease(compute_pipeline);
        }

        // WGPU_EXPORT WGPUBindGroup wgpuDeviceCreateBindGroup(WGPUDevice device, WGPUBindGroupDescriptor const * descriptor);
        export fn wgpuDeviceCreateBindGroup(device: *gpu.Device, descriptor: *const gpu.BindGroup.Descriptor) *gpu.BindGroup {
            return T.deviceCreateBindGroup(device, descriptor);
        }

        // WGPU_EXPORT WGPUBindGroupLayout wgpuDeviceCreateBindGroupLayout(WGPUDevice device, WGPUBindGroupLayout.Descriptor const * descriptor);
        export fn wgpuDeviceCreateBindGroupLayout(device: *gpu.Device, descriptor: *const gpu.BindGroupLayout.Descriptor) *gpu.BindGroupLayout {
            return T.deviceCreateBindGroupLayout(device, descriptor);
        }

        // WGPU_EXPORT WGPUBuffer wgpuDeviceCreateBuffer(WGPUDevice device, WGPUBuffer.Descriptor const * descriptor);
        export fn wgpuDeviceCreateBuffer(device: *gpu.Device, descriptor: *const gpu.Buffer.Descriptor) *gpu.Buffer {
            return T.deviceCreateBuffer(device, descriptor);
        }

        // WGPU_EXPORT WGPUCommandEncoder wgpuDeviceCreateCommandEncoder(WGPUDevice device, WGPUCommandEncoderDescriptor const * descriptor /* nullable */);
        export fn wgpuDeviceCreateCommandEncoder(device: *gpu.Device, descriptor: ?*const gpu.CommandEncoder.Descriptor) *gpu.CommandEncoder {
            return T.deviceCreateCommandEncoder(device, descriptor);
        }

        // WGPU_EXPORT WGPUComputePipeline wgpuDeviceCreateComputePipeline(WGPUDevice device, WGPUComputePipelineDescriptor const * descriptor);
        export fn wgpuDeviceCreateComputePipeline(device: *gpu.Device, descriptor: *const gpu.ComputePipeline.Descriptor) *gpu.ComputePipeline {
            return T.deviceCreateComputePipeline(device, descriptor);
        }

        // WGPU_EXPORT void wgpuDeviceCreateComputePipelineAsync(WGPUDevice device, WGPUComputePipelineDescriptor const * descriptor, WGPUCreateComputePipelineAsyncCallback callback, void * userdata);
        export fn wgpuDeviceCreateComputePipelineAsync(device: *gpu.Device, descriptor: *const gpu.ComputePipeline.Descriptor, callback: gpu.CreateComputePipelineAsyncCallback, userdata: ?*anyopaque) void {
            T.deviceCreateComputePipelineAsync(device, descriptor, callback, userdata);
        }

        // WGPU_EXPORT WGPUBuffer wgpuDeviceCreateErrorBuffer(WGPUDevice device);
        export fn wgpuDeviceCreateErrorBuffer(device: *gpu.Device) *gpu.Buffer {
            return T.deviceCreateErrorBuffer(device);
        }

        // WGPU_EXPORT WGPUExternalTexture wgpuDeviceCreateErrorExternalTexture(WGPUDevice device);
        export fn wgpuDeviceCreateErrorExternalTexture(device: *gpu.Device) *gpu.ExternalTexture {
            return T.deviceCreateErrorExternalTexture(device);
        }

        // WGPU_EXPORT WGPUTexture wgpuDeviceCreateErrorTexture(WGPUDevice device, WGPUTextureDescriptor const * descriptor);
        export fn wgpuDeviceCreateErrorTexture(device: *gpu.Device, descriptor: *const gpu.Texture.Descriptor) *gpu.Texture {
            return T.deviceCreateErrorTexture(device, descriptor);
        }

        // WGPU_EXPORT WGPUExternalTexture wgpuDeviceCreateExternalTexture(WGPUDevice device, WGPUExternalTextureDescriptor const * externalTextureDescriptor);
        export fn wgpuDeviceCreateExternalTexture(device: *gpu.Device, external_texture_descriptor: *const gpu.ExternalTexture.Descriptor) *gpu.ExternalTexture {
            return T.deviceCreateExternalTexture(device, external_texture_descriptor);
        }

        // WGPU_EXPORT WGPUPipelineLayout wgpuDeviceCreatePipelineLayout(WGPUDevice device, WGPUPipelineLayoutDescriptor const * descriptor);
        export fn wgpuDeviceCreatePipelineLayout(device: *gpu.Device, pipeline_layout_descriptor: *const gpu.PipelineLayout.Descriptor) *gpu.PipelineLayout {
            return T.deviceCreatePipelineLayout(device, pipeline_layout_descriptor);
        }

        // WGPU_EXPORT WGPUQuerySet wgpuDeviceCreateQuerySet(WGPUDevice device, WGPUQuerySetDescriptor const * descriptor);
        export fn wgpuDeviceCreateQuerySet(device: *gpu.Device, descriptor: *const gpu.QuerySet.Descriptor) *gpu.QuerySet {
            return T.deviceCreateQuerySet(device, descriptor);
        }

        // WGPU_EXPORT WGPURenderBundleEncoder wgpuDeviceCreateRenderBundleEncoder(WGPUDevice device, WGPURenderBundleEncoderDescriptor const * descriptor);
        export fn wgpuDeviceCreateRenderBundleEncoder(device: *gpu.Device, descriptor: *const gpu.RenderBundleEncoder.Descriptor) *gpu.RenderBundleEncoder {
            return T.deviceCreateRenderBundleEncoder(device, descriptor);
        }

        // WGPU_EXPORT WGPURenderPipeline wgpuDeviceCreateRenderPipeline(WGPUDevice device, WGPURenderPipelineDescriptor const * descriptor);
        export fn wgpuDeviceCreateRenderPipeline(device: *gpu.Device, descriptor: *const gpu.RenderPipeline.Descriptor) *gpu.RenderPipeline {
            return T.deviceCreateRenderPipeline(device, descriptor);
        }

        // WGPU_EXPORT void wgpuDeviceCreateRenderPipelineAsync(WGPUDevice device, WGPURenderPipelineDescriptor const * descriptor, WGPUCreateRenderPipelineAsyncCallback callback, void * userdata);
        export fn wgpuDeviceCreateRenderPipelineAsync(device: *gpu.Device, descriptor: *const gpu.RenderPipeline.Descriptor, callback: gpu.CreateRenderPipelineAsyncCallback, userdata: ?*anyopaque) void {
            T.deviceCreateRenderPipelineAsync(device, descriptor, callback, userdata);
        }

        // WGPU_EXPORT WGPUSampler wgpuDeviceCreateSampler(WGPUDevice device, WGPUSamplerDescriptor const * descriptor /* nullable */);
        export fn wgpuDeviceCreateSampler(device: *gpu.Device, descriptor: ?*const gpu.Sampler.Descriptor) *gpu.Sampler {
            return T.deviceCreateSampler(device, descriptor);
        }

        // WGPU_EXPORT WGPUShaderModule wgpuDeviceCreateShaderModule(WGPUDevice device, WGPUShaderModuleDescriptor const * descriptor);
        export fn wgpuDeviceCreateShaderModule(device: *gpu.Device, descriptor: *const gpu.ShaderModule.Descriptor) *gpu.ShaderModule {
            return T.deviceCreateShaderModule(device, descriptor);
        }

        // WGPU_EXPORT WGPUSwapChain wgpuDeviceCreateSwapChain(WGPUDevice device, WGPUSurface surface /* nullable */, WGPUSwapChainDescriptor const * descriptor);
        export fn wgpuDeviceCreateSwapChain(device: *gpu.Device, surface: ?*gpu.Surface, descriptor: *const gpu.SwapChain.Descriptor) *gpu.SwapChain {
            return T.deviceCreateSwapChain(device, surface, descriptor);
        }

        // WGPU_EXPORT WGPUTexture wgpuDeviceCreateTexture(WGPUDevice device, WGPUTextureDescriptor const * descriptor);
        export fn wgpuDeviceCreateTexture(device: *gpu.Device, descriptor: *const gpu.Texture.Descriptor) *gpu.Texture {
            return T.deviceCreateTexture(device, descriptor);
        }

        // WGPU_EXPORT void wgpuDeviceDestroy(WGPUDevice device);
        export fn wgpuDeviceDestroy(device: *gpu.Device) void {
            T.deviceDestroy(device);
        }

        // WGPU_EXPORT size_t wgpuDeviceEnumerateFeatures(WGPUDevice device, WGPUFeatureName * features);
        export fn wgpuDeviceEnumerateFeatures(device: *gpu.Device, features: [*]gpu.FeatureName) usize {
            return T.deviceEnumerateFeatures(device, features);
        }

        // WGPU_EXPORT bool wgpuDeviceGetLimits(WGPUDevice device, WGPUSupportedLimits * limits);
        export fn wgpuDeviceGetLimits(device: *gpu.Device, limits: *gpu.SupportedLimits) bool {
            return T.deviceGetLimits(device, limits);
        }

        // WGPU_EXPORT WGPUQueue wgpuDeviceGetQueue(WGPUDevice device);
        export fn wgpuDeviceGetQueue(device: *gpu.Device) *gpu.Queue {
            return T.deviceGetQueue(device);
        }

        // WGPU_EXPORT bool wgpuDeviceHasFeature(WGPUDevice device, WGPUFeatureName feature);
        export fn wgpuDeviceHasFeature(device: *gpu.Device, feature: gpu.FeatureName) bool {
            return T.deviceHasFeature(device, feature);
        }

        // WGPU_EXPORT void wgpuDeviceInjectError(WGPUDevice device, WGPUErrorType type, char const * message);
        export fn wgpuDeviceInjectError(device: *gpu.Device, typ: gpu.ErrorType, message: [*:0]const u8) void {
            T.deviceInjectError(device, typ, message);
        }

        // WGPU_EXPORT void wgpuDeviceLoseForTesting(WGPUDevice device);
        export fn wgpuDeviceLoseForTesting(device: *gpu.Device) void {
            T.deviceLoseForTesting(device);
        }

        // WGPU_EXPORT bool wgpuDevicePopErrorScope(WGPUDevice device, WGPUErrorCallback callback, void * userdata);
        export fn wgpuDevicePopErrorScope(device: *gpu.Device, callback: gpu.ErrorCallback, userdata: ?*anyopaque) bool {
            return T.devicePopErrorScope(device, callback, userdata);
        }

        // WGPU_EXPORT void wgpuDevicePushErrorScope(WGPUDevice device, WGPUErrorFilter filter);
        export fn wgpuDevicePushErrorScope(device: *gpu.Device, filter: gpu.ErrorFilter) void {
            T.devicePushErrorScope(device, filter);
        }

        // WGPU_EXPORT void wgpuDeviceSetDeviceLostCallback(WGPUDevice device, WGPUDeviceLostCallback callback, void * userdata);
        export fn wgpuDeviceSetDeviceLostCallback(device: *gpu.Device, callback: gpu.Device.LostCallback, userdata: ?*anyopaque) void {
            T.deviceSetDeviceLostCallback(device, callback, userdata);
        }

        // WGPU_EXPORT void wgpuDeviceSetLabel(WGPUDevice device, char const * label);
        export fn wgpuDeviceSetLabel(device: *gpu.Device, label: [*:0]const u8) void {
            T.deviceSetLabel(device, label);
        }

        // WGPU_EXPORT void wgpuDeviceSetLoggingCallback(WGPUDevice device, WGPULoggingCallback callback, void * userdata);
        export fn wgpuDeviceSetLoggingCallback(device: *gpu.Device, callback: gpu.LoggingCallback, userdata: ?*anyopaque) void {
            T.deviceSetLoggingCallback(device, callback, userdata);
        }

        // WGPU_EXPORT void wgpuDeviceSetUncapturedErrorCallback(WGPUDevice device, WGPUErrorCallback callback, void * userdata);
        export fn wgpuDeviceSetUncapturedErrorCallback(device: *gpu.Device, callback: gpu.ErrorCallback, userdata: ?*anyopaque) void {
            T.deviceSetUncapturedErrorCallback(device, callback, userdata);
        }

        // WGPU_EXPORT void wgpuDeviceTick(WGPUDevice device);
        export fn wgpuDeviceTick(device: *gpu.Device) void {
            T.deviceTick(device);
        }

        // WGPU_EXPORT void wgpuDeviceReference(WGPUDevice device);
        export fn wgpuDeviceReference(device: *gpu.Device) void {
            T.deviceReference(device);
        }

        // WGPU_EXPORT void wgpuDeviceRelease(WGPUDevice device);
        export fn wgpuDeviceRelease(device: *gpu.Device) void {
            T.deviceRelease(device);
        }

        // WGPU_EXPORT void wgpuExternalTextureDestroy(WGPUExternalTexture externalTexture);
        export fn wgpuExternalTextureDestroy(external_texture: *gpu.ExternalTexture) void {
            T.externalTextureDestroy(external_texture);
        }

        // WGPU_EXPORT void wgpuExternalTextureSetLabel(WGPUExternalTexture externalTexture, char const * label);
        export fn wgpuExternalTextureSetLabel(external_texture: *gpu.ExternalTexture, label: [*:0]const u8) void {
            T.externalTextureSetLabel(external_texture, label);
        }

        // WGPU_EXPORT void wgpuExternalTextureReference(WGPUExternalTexture externalTexture);
        export fn wgpuExternalTextureReference(external_texture: *gpu.ExternalTexture) void {
            T.externalTextureReference(external_texture);
        }

        // WGPU_EXPORT void wgpuExternalTextureRelease(WGPUExternalTexture externalTexture);
        export fn wgpuExternalTextureRelease(external_texture: *gpu.ExternalTexture) void {
            T.externalTextureRelease(external_texture);
        }

        // WGPU_EXPORT WGPUSurface wgpuInstanceCreateSurface(WGPUInstance instance, WGPUSurfaceDescriptor const * descriptor);
        export fn wgpuInstanceCreateSurface(instance: *gpu.Instance, descriptor: *const gpu.Surface.Descriptor) *gpu.Surface {
            return T.instanceCreateSurface(instance, descriptor);
        }

        // WGPU_EXPORT void wgpuInstanceRequestAdapter(WGPUInstance instance, WGPURequestAdapterOptions const * options /* nullable */, WGPURequestAdapterCallback callback, void * userdata);
        export fn wgpuInstanceRequestAdapter(instance: *gpu.Instance, options: ?*const gpu.RequestAdapterOptions, callback: gpu.RequestAdapterCallback, userdata: ?*anyopaque) void {
            T.instanceRequestAdapter(instance, options, callback, userdata);
        }

        // WGPU_EXPORT void wgpuInstanceReference(WGPUInstance instance);
        export fn wgpuInstanceReference(instance: *gpu.Instance) void {
            T.instanceReference(instance);
        }

        // WGPU_EXPORT void wgpuInstanceRelease(WGPUInstance instance);
        export fn wgpuInstanceRelease(instance: *gpu.Instance) void {
            T.instanceRelease(instance);
        }

        // WGPU_EXPORT void wgpuPipelineLayoutSetLabel(WGPUPipelineLayout pipelineLayout, char const * label);
        export fn wgpuPipelineLayoutSetLabel(pipeline_layout: *gpu.PipelineLayout, label: [*:0]const u8) void {
            T.pipelineLayoutSetLabel(pipeline_layout, label);
        }

        // WGPU_EXPORT void wgpuPipelineLayoutReference(WGPUPipelineLayout pipelineLayout);
        export fn wgpuPipelineLayoutReference(pipeline_layout: *gpu.PipelineLayout) void {
            T.pipelineLayoutReference(pipeline_layout);
        }

        // WGPU_EXPORT void wgpuPipelineLayoutRelease(WGPUPipelineLayout pipelineLayout);
        export fn wgpuPipelineLayoutRelease(pipeline_layout: *gpu.PipelineLayout) void {
            T.pipelineLayoutRelease(pipeline_layout);
        }

        // WGPU_EXPORT void wgpuQuerySetDestroy(WGPUQuerySet querySet);
        export fn wgpuQuerySetDestroy(query_set: *gpu.QuerySet) void {
            T.querySetDestroy(query_set);
        }

        // WGPU_EXPORT uint32_t wgpuQuerySetGetCount(WGPUQuerySet querySet);
        export fn wgpuQuerySetGetCount(query_set: *gpu.QuerySet) u32 {
            return T.querySetGetCount(query_set);
        }

        // WGPU_EXPORT WGPUQueryType wgpuQuerySetGetType(WGPUQuerySet querySet);
        export fn wgpuQuerySetGetType(query_set: *gpu.QuerySet) gpu.QueryType {
            return T.querySetGetType(query_set);
        }

        // WGPU_EXPORT void wgpuQuerySetSetLabel(WGPUQuerySet querySet, char const * label);
        export fn wgpuQuerySetSetLabel(query_set: *gpu.QuerySet, label: [*:0]const u8) void {
            T.querySetSetLabel(query_set, label);
        }

        // WGPU_EXPORT void wgpuQuerySetReference(WGPUQuerySet querySet);
        export fn wgpuQuerySetReference(query_set: *gpu.QuerySet) void {
            T.querySetReference(query_set);
        }

        // WGPU_EXPORT void wgpuQuerySetRelease(WGPUQuerySet querySet);
        export fn wgpuQuerySetRelease(query_set: *gpu.QuerySet) void {
            T.querySetRelease(query_set);
        }

        // WGPU_EXPORT void wgpuQueueCopyTextureForBrowser(WGPUQueue queue, WGPUImageCopyTexture const * source, WGPUImageCopyTexture const * destination, WGPUExtent3D const * copySize, WGPUCopyTextureForBrowserOptions const * options);
        export fn wgpuQueueCopyTextureForBrowser(queue: *gpu.Queue, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D, options: *const gpu.CopyTextureForBrowserOptions) void {
            T.queueCopyTextureForBrowser(queue, source, destination, copy_size, options);
        }

        // WGPU_EXPORT void wgpuQueueOnSubmittedWorkDone(WGPUQueue queue, uint64_t signalValue, WGPUQueueWorkDoneCallback callback, void * userdata);
        export fn wgpuQueueOnSubmittedWorkDone(queue: *gpu.Queue, signal_value: u64, callback: gpu.Queue.WorkDoneCallback, userdata: ?*anyopaque) void {
            T.queueOnSubmittedWorkDone(queue, signal_value, callback, userdata);
        }

        // WGPU_EXPORT void wgpuQueueSetLabel(WGPUQueue queue, char const * label);
        export fn wgpuQueueSetLabel(queue: *gpu.Queue, label: [*:0]const u8) void {
            T.queueSetLabel(queue, label);
        }

        // WGPU_EXPORT void wgpuQueueSubmit(WGPUQueue queue, uint32_t commandCount, WGPUCommandBuffer const * commands);
        export fn wgpuQueueSubmit(queue: *gpu.Queue, command_count: u32, commands: [*]*const gpu.CommandBuffer) void {
            T.queueSubmit(queue, command_count, commands);
        }

        // WGPU_EXPORT void wgpuQueueWriteBuffer(WGPUQueue queue, WGPUBuffer buffer, uint64_t bufferOffset, void const * data, size_t size);
        export fn wgpuQueueWriteBuffer(queue: *gpu.Queue, buffer: *gpu.Buffer, buffer_offset: u64, data: *anyopaque, size: usize) void {
            T.queueWriteBuffer(queue, buffer, buffer_offset, data, size);
        }

        // WGPU_EXPORT void wgpuQueueWriteTexture(WGPUQueue queue, WGPUImageCopyTexture const * destination, void const * data, size_t dataSize, WGPUTextureDataLayout const * dataLayout, WGPUExtent3D const * writeSize);
        export fn wgpuQueueWriteTexture(queue: *gpu.Queue, destination: *const gpu.ImageCopyTexture, data: *const anyopaque, data_size: usize, data_layout: *const gpu.Texture.DataLayout, write_size: *const gpu.Extent3D) void {
            T.queueWriteTexture(queue, destination, data, data_size, data_layout, write_size);
        }

        // WGPU_EXPORT void wgpuQueueReference(WGPUQueue queue);
        export fn wgpuQueueReference(queue: *gpu.Queue) void {
            T.queueReference(queue);
        }

        // WGPU_EXPORT void wgpuQueueRelease(WGPUQueue queue);
        export fn wgpuQueueRelease(queue: *gpu.Queue) void {
            T.queueRelease(queue);
        }

        // WGPU_EXPORT void wgpuRenderBundleReference(WGPURenderBundle renderBundle);
        export fn wgpuRenderBundleReference(render_bundle: *gpu.RenderBundle) void {
            T.renderBundleReference(render_bundle);
        }

        // WGPU_EXPORT void wgpuRenderBundleRelease(WGPURenderBundle renderBundle);
        export fn wgpuRenderBundleRelease(render_bundle: *gpu.RenderBundle) void {
            T.renderBundleRelease(render_bundle);
        }

        // WGPU_EXPORT void wgpuRenderBundleEncoderDraw(WGPURenderBundleEncoder renderBundleEncoder, uint32_t vertexCount, uint32_t instanceCount, uint32_t firstVertex, uint32_t firstInstance);
        export fn wgpuRenderBundleEncoderDraw(render_bundle_encoder: *gpu.RenderBundleEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {
            T.renderBundleEncoderDraw(render_bundle_encoder, vertex_count, instance_count, first_vertex, first_instance);
        }

        // WGPU_EXPORT void wgpuRenderBundleEncoderDrawIndexed(WGPURenderBundleEncoder renderBundleEncoder, uint32_t indexCount, uint32_t instanceCount, uint32_t firstIndex, int32_t baseVertex, uint32_t firstInstance);
        export fn wgpuRenderBundleEncoderDrawIndexed(render_bundle_encoder: *gpu.RenderBundleEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: i32, first_instance: u32) void {
            T.renderBundleEncoderDrawIndexed(render_bundle_encoder, index_count, instance_count, first_index, base_vertex, first_instance);
        }

        // WGPU_EXPORT void wgpuRenderBundleEncoderDrawIndexedIndirect(WGPURenderBundleEncoder renderBundleEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
        export fn wgpuRenderBundleEncoderDrawIndexedIndirect(render_bundle_encoder: *gpu.RenderBundleEncoder, indirect_buffer: *gpu.Buffer, indirect_offset: u64) void {
            T.renderBundleEncoderDrawIndexedIndirect(render_bundle_encoder, indirect_buffer, indirect_offset);
        }

        // WGPU_EXPORT void wgpuRenderBundleEncoderDrawIndirect(WGPURenderBundleEncoder renderBundleEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
        export fn wgpuRenderBundleEncoderDrawIndirect(render_bundle_encoder: *gpu.RenderBundleEncoder, indirect_buffer: *gpu.Buffer, indirect_offset: u64) void {
            T.renderBundleEncoderDrawIndirect(render_bundle_encoder, indirect_buffer, indirect_offset);
        }

        // WGPU_EXPORT WGPURenderBundle wgpuRenderBundleEncoderFinish(WGPURenderBundleEncoder renderBundleEncoder, WGPURenderBundleDescriptor const * descriptor /* nullable */);
        export fn wgpuRenderBundleEncoderFinish(render_bundle_encoder: *gpu.RenderBundleEncoder, descriptor: ?*const gpu.RenderBundle.Descriptor) *gpu.RenderBundle {
            return T.renderBundleEncoderFinish(render_bundle_encoder, descriptor);
        }

        // WGPU_EXPORT void wgpuRenderBundleEncoderInsertDebugMarker(WGPURenderBundleEncoder renderBundleEncoder, char const * markerLabel);
        export fn wgpuRenderBundleEncoderInsertDebugMarker(render_bundle_encoder: *gpu.RenderBundleEncoder, marker_label: [*:0]const u8) void {
            T.renderBundleEncoderInsertDebugMarker(render_bundle_encoder, marker_label);
        }

        // WGPU_EXPORT void wgpuRenderBundleEncoderPopDebugGroup(WGPURenderBundleEncoder renderBundleEncoder);
        export fn wgpuRenderBundleEncoderPopDebugGroup(render_bundle_encoder: *gpu.RenderBundleEncoder) void {
            T.renderBundleEncoderPopDebugGroup(render_bundle_encoder);
        }

        // WGPU_EXPORT void wgpuRenderBundleEncoderPushDebugGroup(WGPURenderBundleEncoder renderBundleEncoder, char const * groupLabel);
        export fn wgpuRenderBundleEncoderPushDebugGroup(render_bundle_encoder: *gpu.RenderBundleEncoder, group_label: [*:0]const u8) void {
            T.renderBundleEncoderPushDebugGroup(render_bundle_encoder, group_label);
        }

        // WGPU_EXPORT void wgpuRenderBundleEncoderSetBindGroup(WGPURenderBundleEncoder renderBundleEncoder, uint32_t groupIndex, WGPUBindGroup group, uint32_t dynamicOffsetCount, uint32_t const * dynamicOffsets);
        export fn wgpuRenderBundleEncoderSetBindGroup(render_bundle_encoder: *gpu.RenderBundleEncoder, group_index: u32, group: *gpu.BindGroup, dynamic_offset_count: u32, dynamic_offsets: ?[*]const u32) void {
            T.renderBundleEncoderSetBindGroup(render_bundle_encoder, group_index, group, dynamic_offset_count, dynamic_offsets);
        }

        // WGPU_EXPORT void wgpuRenderBundleEncoderSetIndexBuffer(WGPURenderBundleEncoder renderBundleEncoder, WGPUBuffer buffer, WGPUIndexFormat format, uint64_t offset, uint64_t size);
        export fn wgpuRenderBundleEncoderSetIndexBuffer(render_bundle_encoder: *gpu.RenderBundleEncoder, buffer: *gpu.Buffer, format: gpu.IndexFormat, offset: u64, size: u64) void {
            T.renderBundleEncoderSetIndexBuffer(render_bundle_encoder, buffer, format, offset, size);
        }

        // WGPU_EXPORT void wgpuRenderBundleEncoderSetLabel(WGPURenderBundleEncoder renderBundleEncoder, char const * label);
        export fn wgpuRenderBundleEncoderSetLabel(render_bundle_encoder: *gpu.RenderBundleEncoder, label: [*:0]const u8) void {
            T.renderBundleEncoderSetLabel(render_bundle_encoder, label);
        }

        // WGPU_EXPORT void wgpuRenderBundleEncoderSetPipeline(WGPURenderBundleEncoder renderBundleEncoder, WGPURenderPipeline pipeline);
        export fn wgpuRenderBundleEncoderSetPipeline(render_bundle_encoder: *gpu.RenderBundleEncoder, pipeline: *gpu.RenderPipeline) void {
            T.renderBundleEncoderSetPipeline(render_bundle_encoder, pipeline);
        }

        // WGPU_EXPORT void wgpuRenderBundleEncoderSetVertexBuffer(WGPURenderBundleEncoder renderBundleEncoder, uint32_t slot, WGPUBuffer buffer, uint64_t offset, uint64_t size);
        export fn wgpuRenderBundleEncoderSetVertexBuffer(render_bundle_encoder: *gpu.RenderBundleEncoder, slot: u32, buffer: *gpu.Buffer, offset: u64, size: u64) void {
            T.renderBundleEncoderSetVertexBuffer(render_bundle_encoder, slot, buffer, offset, size);
        }

        // WGPU_EXPORT void wgpuRenderBundleEncoderReference(WGPURenderBundleEncoder renderBundleEncoder);
        export fn wgpuRenderBundleEncoderReference(render_bundle_encoder: *gpu.RenderBundleEncoder) void {
            T.renderBundleEncoderReference(render_bundle_encoder);
        }

        // WGPU_EXPORT void wgpuRenderBundleEncoderRelease(WGPURenderBundleEncoder renderBundleEncoder);
        export fn wgpuRenderBundleEncoderRelease(render_bundle_encoder: *gpu.RenderBundleEncoder) void {
            T.renderBundleEncoderRelease(render_bundle_encoder);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderBeginOcclusionQuery(WGPURenderPassEncoder renderPassEncoder, uint32_t queryIndex);
        export fn wgpuRenderPassEncoderBeginOcclusionQuery(render_pass_encoder: *gpu.RenderPassEncoder, query_index: u32) void {
            T.renderPassEncoderBeginOcclusionQuery(render_pass_encoder, query_index);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderDraw(WGPURenderPassEncoder renderPassEncoder, uint32_t vertexCount, uint32_t instanceCount, uint32_t firstVertex, uint32_t firstInstance);
        export fn wgpuRenderPassEncoderDraw(render_pass_encoder: *gpu.RenderPassEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {
            T.renderPassEncoderDraw(render_pass_encoder, vertex_count, instance_count, first_vertex, first_instance);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderDrawIndexed(WGPURenderPassEncoder renderPassEncoder, uint32_t indexCount, uint32_t instanceCount, uint32_t firstIndex, int32_t baseVertex, uint32_t firstInstance);
        export fn wgpuRenderPassEncoderDrawIndexed(render_pass_encoder: *gpu.RenderPassEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: i32, first_instance: u32) void {
            T.renderPassEncoderDrawIndexed(render_pass_encoder, index_count, instance_count, first_index, base_vertex, first_instance);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderDrawIndexedIndirect(WGPURenderPassEncoder renderPassEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
        export fn wgpuRenderPassEncoderDrawIndexedIndirect(render_pass_encoder: *gpu.RenderPassEncoder, indirect_buffer: *gpu.Buffer, indirect_offset: u64) void {
            T.renderPassEncoderDrawIndexedIndirect(render_pass_encoder, indirect_buffer, indirect_offset);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderDrawIndirect(WGPURenderPassEncoder renderPassEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
        export fn wgpuRenderPassEncoderDrawIndirect(render_pass_encoder: *gpu.RenderPassEncoder, indirect_buffer: *gpu.Buffer, indirect_offset: u64) void {
            T.renderPassEncoderDrawIndirect(render_pass_encoder, indirect_buffer, indirect_offset);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderEnd(WGPURenderPassEncoder renderPassEncoder);
        export fn wgpuRenderPassEncoderEnd(render_pass_encoder: *gpu.RenderPassEncoder) void {
            T.renderPassEncoderEnd(render_pass_encoder);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderEndOcclusionQuery(WGPURenderPassEncoder renderPassEncoder);
        export fn wgpuRenderPassEncoderEndOcclusionQuery(render_pass_encoder: *gpu.RenderPassEncoder) void {
            T.renderPassEncoderEndOcclusionQuery(render_pass_encoder);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderExecuteBundles(WGPURenderPassEncoder renderPassEncoder, uint32_t bundlesCount, WGPURenderBundle const * bundles);
        export fn wgpuRenderPassEncoderExecuteBundles(render_pass_encoder: *gpu.RenderPassEncoder, bundles_count: u32, bundles: [*]const *const gpu.RenderBundle) void {
            T.renderPassEncoderExecuteBundles(render_pass_encoder, bundles_count, bundles);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderInsertDebugMarker(WGPURenderPassEncoder renderPassEncoder, char const * markerLabel);
        export fn wgpuRenderPassEncoderInsertDebugMarker(render_pass_encoder: *gpu.RenderPassEncoder, marker_label: [*:0]const u8) void {
            T.renderPassEncoderInsertDebugMarker(render_pass_encoder, marker_label);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderPopDebugGroup(WGPURenderPassEncoder renderPassEncoder);
        export fn wgpuRenderPassEncoderPopDebugGroup(render_pass_encoder: *gpu.RenderPassEncoder) void {
            T.renderPassEncoderPopDebugGroup(render_pass_encoder);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderPushDebugGroup(WGPURenderPassEncoder renderPassEncoder, char const * groupLabel);
        export fn wgpuRenderPassEncoderPushDebugGroup(render_pass_encoder: *gpu.RenderPassEncoder, group_label: [*:0]const u8) void {
            T.renderPassEncoderPushDebugGroup(render_pass_encoder, group_label);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderSetBindGroup(WGPURenderPassEncoder renderPassEncoder, uint32_t groupIndex, WGPUBindGroup group, uint32_t dynamicOffsetCount, uint32_t const * dynamicOffsets);
        export fn wgpuRenderPassEncoderSetBindGroup(render_pass_encoder: *gpu.RenderPassEncoder, group_index: u32, group: *gpu.BindGroup, dynamic_offset_count: u32, dynamic_offsets: ?[*]const u32) void {
            T.renderPassEncoderSetBindGroup(render_pass_encoder, group_index, group, dynamic_offset_count, dynamic_offsets);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderSetBlendConstant(WGPURenderPassEncoder renderPassEncoder, WGPUColor const * color);
        export fn wgpuRenderPassEncoderSetBlendConstant(render_pass_encoder: *gpu.RenderPassEncoder, color: *const gpu.Color) void {
            T.renderPassEncoderSetBlendConstant(render_pass_encoder, color);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderSetIndexBuffer(WGPURenderPassEncoder renderPassEncoder, WGPUBuffer buffer, WGPUIndexFormat format, uint64_t offset, uint64_t size);
        export fn wgpuRenderPassEncoderSetIndexBuffer(render_pass_encoder: *gpu.RenderPassEncoder, buffer: *gpu.Buffer, format: gpu.IndexFormat, offset: u64, size: u64) void {
            T.renderPassEncoderSetIndexBuffer(render_pass_encoder, buffer, format, offset, size);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderSetLabel(WGPURenderPassEncoder renderPassEncoder, char const * label);
        export fn wgpuRenderPassEncoderSetLabel(render_pass_encoder: *gpu.RenderPassEncoder, label: [*:0]const u8) void {
            T.renderPassEncoderSetLabel(render_pass_encoder, label);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderSetPipeline(WGPURenderPassEncoder renderPassEncoder, WGPURenderPipeline pipeline);
        export fn wgpuRenderPassEncoderSetPipeline(render_pass_encoder: *gpu.RenderPassEncoder, pipeline: *gpu.RenderPipeline) void {
            T.renderPassEncoderSetPipeline(render_pass_encoder, pipeline);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderSetScissorRect(WGPURenderPassEncoder renderPassEncoder, uint32_t x, uint32_t y, uint32_t width, uint32_t height);
        export fn wgpuRenderPassEncoderSetScissorRect(render_pass_encoder: *gpu.RenderPassEncoder, x: u32, y: u32, width: u32, height: u32) void {
            T.renderPassEncoderSetScissorRect(render_pass_encoder, x, y, width, height);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderSetStencilReference(WGPURenderPassEncoder renderPassEncoder, uint32_t reference);
        export fn wgpuRenderPassEncoderSetStencilReference(render_pass_encoder: *gpu.RenderPassEncoder, reference: u32) void {
            T.renderPassEncoderSetStencilReference(render_pass_encoder, reference);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderSetVertexBuffer(WGPURenderPassEncoder renderPassEncoder, uint32_t slot, WGPUBuffer buffer, uint64_t offset, uint64_t size);
        export fn wgpuRenderPassEncoderSetVertexBuffer(render_pass_encoder: *gpu.RenderPassEncoder, slot: u32, buffer: *gpu.Buffer, offset: u64, size: u64) void {
            T.renderPassEncoderSetVertexBuffer(render_pass_encoder, slot, buffer, offset, size);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderSetViewport(WGPURenderPassEncoder renderPassEncoder, float x, float y, float width, float height, float minDepth, float maxDepth);
        export fn wgpuRenderPassEncoderSetViewport(render_pass_encoder: *gpu.RenderPassEncoder, x: f32, y: f32, width: f32, height: f32, min_depth: f32, max_depth: f32) void {
            T.renderPassEncoderSetViewport(render_pass_encoder, x, y, width, height, min_depth, max_depth);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderWriteTimestamp(WGPURenderPassEncoder renderPassEncoder, WGPUQuerySet querySet, uint32_t queryIndex);
        export fn wgpuRenderPassEncoderWriteTimestamp(render_pass_encoder: *gpu.RenderPassEncoder, query_set: *gpu.QuerySet, query_index: u32) void {
            T.renderPassEncoderWriteTimestamp(render_pass_encoder, query_set, query_index);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderReference(WGPURenderPassEncoder renderPassEncoder);
        export fn wgpuRenderPassEncoderReference(render_pass_encoder: *gpu.RenderPassEncoder) void {
            T.renderPassEncoderReference(render_pass_encoder);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderRelease(WGPURenderPassEncoder renderPassEncoder);
        export fn wgpuRenderPassEncoderRelease(render_pass_encoder: *gpu.RenderPassEncoder) void {
            T.renderPassEncoderRelease(render_pass_encoder);
        }

        // WGPU_EXPORT WGPUBindGroupLayout wgpuRenderPipelineGetBindGroupLayout(WGPURenderPipeline renderPipeline, uint32_t groupIndex);
        export fn wgpuRenderPipelineGetBindGroupLayout(render_pipeline: *gpu.RenderPipeline, group_index: u32) *gpu.BindGroupLayout {
            return T.renderPipelineGetBindGroupLayout(render_pipeline, group_index);
        }

        // WGPU_EXPORT void wgpuRenderPipelineSetLabel(WGPURenderPipeline renderPipeline, char const * label);
        export fn wgpuRenderPipelineSetLabel(render_pipeline: *gpu.RenderPipeline, label: [*:0]const u8) void {
            T.renderPipelineSetLabel(render_pipeline, label);
        }

        // WGPU_EXPORT void wgpuRenderPipelineReference(WGPURenderPipeline renderPipeline);
        export fn wgpuRenderPipelineReference(render_pipeline: *gpu.RenderPipeline) void {
            T.renderPipelineReference(render_pipeline);
        }

        // WGPU_EXPORT void wgpuRenderPipelineRelease(WGPURenderPipeline renderPipeline);
        export fn wgpuRenderPipelineRelease(render_pipeline: *gpu.RenderPipeline) void {
            T.renderPipelineRelease(render_pipeline);
        }

        // WGPU_EXPORT void wgpuSamplerSetLabel(WGPUSampler sampler, char const * label);
        export fn wgpuSamplerSetLabel(sampler: *gpu.Sampler, label: [*:0]const u8) void {
            T.samplerSetLabel(sampler, label);
        }

        // WGPU_EXPORT void wgpuSamplerReference(WGPUSampler sampler);
        export fn wgpuSamplerReference(sampler: *gpu.Sampler) void {
            T.samplerReference(sampler);
        }

        // WGPU_EXPORT void wgpuSamplerRelease(WGPUSampler sampler);
        export fn wgpuSamplerRelease(sampler: *gpu.Sampler) void {
            T.samplerRelease(sampler);
        }

        // WGPU_EXPORT void wgpuShaderModuleGetCompilationInfo(WGPUShaderModule shaderModule, WGPUCompilationInfoCallback callback, void * userdata);
        export fn wgpuShaderModuleGetCompilationInfo(shader_module: *gpu.ShaderModule, callback: gpu.CompilationInfoCallback, userdata: ?*anyopaque) void {
            T.shaderModuleGetCompilationInfo(shader_module, callback, userdata);
        }

        // WGPU_EXPORT void wgpuShaderModuleSetLabel(WGPUShaderModule shaderModule, char const * label);
        export fn wgpuShaderModuleSetLabel(shader_module: *gpu.ShaderModule, label: [*:0]const u8) void {
            T.shaderModuleSetLabel(shader_module, label);
        }

        // WGPU_EXPORT void wgpuShaderModuleReference(WGPUShaderModule shaderModule);
        export fn wgpuShaderModuleReference(shader_module: *gpu.ShaderModule) void {
            T.shaderModuleReference(shader_module);
        }

        // WGPU_EXPORT void wgpuShaderModuleRelease(WGPUShaderModule shaderModule);
        export fn wgpuShaderModuleRelease(shader_module: *gpu.ShaderModule) void {
            T.shaderModuleRelease(shader_module);
        }

        // WGPU_EXPORT void wgpuSurfaceReference(WGPUSurface surface);
        export fn wgpuSurfaceReference(surface: *gpu.Surface) void {
            T.surfaceReference(surface);
        }

        // WGPU_EXPORT void wgpuSurfaceRelease(WGPUSurface surface);
        export fn wgpuSurfaceRelease(surface: *gpu.Surface) void {
            T.surfaceRelease(surface);
        }

        // TODO: Zig cannot currently export a packed struct gpu.Texture.UsageFlags, so we use a u32
        // for now.
        // WGPU_EXPORT void wgpuSwapChainConfigure(WGPUSwapChain swapChain, WGPUTextureFormat format, WGPUTextureUsageFlags allowedUsage, uint32_t width, uint32_t height);
        export fn wgpuSwapChainConfigure(swap_chain: *gpu.SwapChain, format: gpu.Texture.Format, allowed_usage: u32, width: u32, height: u32) void {
            T.swapChainConfigure(swap_chain, format, @bitCast(gpu.Texture.UsageFlags, allowed_usage), width, height);
        }

        // WGPU_EXPORT WGPUTextureView wgpuSwapChainGetCurrentTextureView(WGPUSwapChain swapChain);
        export fn wgpuSwapChainGetCurrentTextureView(swap_chain: *gpu.SwapChain) *gpu.TextureView {
            return T.swapChainGetCurrentTextureView(swap_chain);
        }

        // WGPU_EXPORT void wgpuSwapChainPresent(WGPUSwapChain swapChain);
        export fn wgpuSwapChainPresent(swap_chain: *gpu.SwapChain) void {
            T.swapChainPresent(swap_chain);
        }

        // WGPU_EXPORT void wgpuSwapChainReference(WGPUSwapChain swapChain);
        export fn wgpuSwapChainReference(swap_chain: *gpu.SwapChain) void {
            T.swapChainReference(swap_chain);
        }

        // WGPU_EXPORT void wgpuSwapChainRelease(WGPUSwapChain swapChain);
        export fn wgpuSwapChainRelease(swap_chain: *gpu.SwapChain) void {
            T.swapChainRelease(swap_chain);
        }

        // WGPU_EXPORT WGPUTextureView wgpuTextureCreateView(WGPUTexture texture, WGPUTextureViewDescriptor const * descriptor /* nullable */);
        export fn wgpuTextureCreateView(texture: *gpu.Texture, descriptor: ?*const gpu.TextureView.Descriptor) *gpu.TextureView {
            return T.textureCreateView(texture, descriptor);
        }

        // WGPU_EXPORT void wgpuTextureDestroy(WGPUTexture texture);
        export fn wgpuTextureDestroy(texture: *gpu.Texture) void {
            T.textureDestroy(texture);
        }

        // WGPU_EXPORT uint32_t wgpuTextureGetDepthOrArrayLayers(WGPUTexture texture);
        export fn wgpuTextureGetDepthOrArrayLayers(texture: *gpu.Texture) u32 {
            return T.textureGetDepthOrArrayLayers(texture);
        }

        // WGPU_EXPORT WGPUTextureDimension wgpuTextureGetDimension(WGPUTexture texture);
        export fn wgpuTextureGetDimension(texture: *gpu.Texture) gpu.Texture.Dimension {
            return T.textureGetDimension(texture);
        }

        // WGPU_EXPORT WGPUTextureFormat wgpuTextureGetFormat(WGPUTexture texture);
        export fn wgpuTextureGetFormat(texture: *gpu.Texture) gpu.Texture.Format {
            return T.textureGetFormat(texture);
        }

        // WGPU_EXPORT uint32_t wgpuTextureGetHeight(WGPUTexture texture);
        export fn wgpuTextureGetHeight(texture: *gpu.Texture) u32 {
            return T.textureGetHeight(texture);
        }

        // WGPU_EXPORT uint32_t wgpuTextureGetMipLevelCount(WGPUTexture texture);
        export fn wgpuTextureGetMipLevelCount(texture: *gpu.Texture) u32 {
            return T.textureGetMipLevelCount(texture);
        }

        // WGPU_EXPORT uint32_t wgpuTextureGetSampleCount(WGPUTexture texture);
        export fn wgpuTextureGetSampleCount(texture: *gpu.Texture) u32 {
            return T.textureGetSampleCount(texture);
        }

        // WGPU_EXPORT WGPUTextureUsage wgpuTextureGetUsage(WGPUTexture texture);
        export fn wgpuTextureGetUsage(texture: *gpu.Texture) gpu.Texture.UsageFlags {
            return T.textureGetUsage(texture);
        }

        // WGPU_EXPORT uint32_t wgpuTextureGetWidth(WGPUTexture texture);
        export fn wgpuTextureGetWidth(texture: *gpu.Texture) u32 {
            return T.textureGetWidth(texture);
        }

        // WGPU_EXPORT void wgpuTextureSetLabel(WGPUTexture texture, char const * label);
        export fn wgpuTextureSetLabel(texture: *gpu.Texture, label: [*:0]const u8) void {
            T.textureSetLabel(texture, label);
        }

        // WGPU_EXPORT void wgpuTextureReference(WGPUTexture texture);
        export fn wgpuTextureReference(texture: *gpu.Texture) void {
            T.textureReference(texture);
        }

        // WGPU_EXPORT void wgpuTextureRelease(WGPUTexture texture);
        export fn wgpuTextureRelease(texture: *gpu.Texture) void {
            T.textureRelease(texture);
        }

        // WGPU_EXPORT void wgpuTextureViewSetLabel(WGPUTextureView textureView, char const * label);
        export fn wgpuTextureViewSetLabel(texture_view: *gpu.TextureView, label: [*:0]const u8) void {
            T.textureViewSetLabel(texture_view, label);
        }

        // WGPU_EXPORT void wgpuTextureViewReference(WGPUTextureView textureView);
        export fn wgpuTextureViewReference(texture_view: *gpu.TextureView) void {
            T.textureViewReference(texture_view);
        }

        // WGPU_EXPORT void wgpuTextureViewRelease(WGPUTextureView textureView);
        export fn wgpuTextureViewRelease(texture_view: *gpu.TextureView) void {
            T.textureViewRelease(texture_view);
        }
    };
}

/// A stub gpu.Interface in which every function is implemented by `unreachable;`
pub const StubInterface = Interface(struct {
    pub inline fn createInstance(descriptor: ?*const gpu.Instance.Descriptor) ?*gpu.Instance {
        _ = descriptor;
        unreachable;
    }

    pub inline fn getProcAddress(device: *gpu.Device, proc_name: [*:0]const u8) ?gpu.Proc {
        _ = device;
        _ = proc_name;
        unreachable;
    }

    pub inline fn adapterCreateDevice(adapter: *gpu.Adapter, descriptor: ?*const gpu.Device.Descriptor) ?*gpu.Device {
        _ = adapter;
        _ = descriptor;
        unreachable;
    }

    pub inline fn adapterEnumerateFeatures(adapter: *gpu.Adapter, features: ?[*]gpu.FeatureName) usize {
        _ = adapter;
        _ = features;
        unreachable;
    }

    pub inline fn adapterGetLimits(adapter: *gpu.Adapter, limits: *gpu.SupportedLimits) bool {
        _ = adapter;
        _ = limits;
        unreachable;
    }

    pub inline fn adapterGetProperties(adapter: *gpu.Adapter, properties: *gpu.Adapter.Properties) void {
        _ = adapter;
        _ = properties;
        unreachable;
    }

    pub inline fn adapterHasFeature(adapter: *gpu.Adapter, feature: gpu.FeatureName) bool {
        _ = adapter;
        _ = feature;
        unreachable;
    }

    pub inline fn adapterRequestDevice(adapter: *gpu.Adapter, descriptor: ?*const gpu.Device.Descriptor, callback: gpu.RequestDeviceCallback, userdata: ?*anyopaque) void {
        _ = adapter;
        _ = descriptor;
        _ = callback;
        _ = userdata;
        unreachable;
    }

    pub inline fn adapterReference(adapter: *gpu.Adapter) void {
        _ = adapter;
        unreachable;
    }

    pub inline fn adapterRelease(adapter: *gpu.Adapter) void {
        _ = adapter;
        unreachable;
    }

    pub inline fn bindGroupSetLabel(bind_group: *gpu.BindGroup, label: [*:0]const u8) void {
        _ = bind_group;
        _ = label;
        unreachable;
    }

    pub inline fn bindGroupReference(bind_group: *gpu.BindGroup) void {
        _ = bind_group;
        unreachable;
    }

    pub inline fn bindGroupRelease(bind_group: *gpu.BindGroup) void {
        _ = bind_group;
        unreachable;
    }

    pub inline fn bindGroupLayoutSetLabel(bind_group_layout: *gpu.BindGroupLayout, label: [*:0]const u8) void {
        _ = bind_group_layout;
        _ = label;
        unreachable;
    }

    pub inline fn bindGroupLayoutReference(bind_group_layout: *gpu.BindGroupLayout) void {
        _ = bind_group_layout;
        unreachable;
    }

    pub inline fn bindGroupLayoutRelease(bind_group_layout: *gpu.BindGroupLayout) void {
        _ = bind_group_layout;
        unreachable;
    }

    pub inline fn bufferDestroy(buffer: *gpu.Buffer) void {
        _ = buffer;
        unreachable;
    }

    // TODO: file a bug on Dawn docstrings, this returns null but is not documented as such.
    pub inline fn bufferGetConstMappedRange(buffer: *gpu.Buffer, offset: usize, size: usize) ?*const anyopaque {
        _ = buffer;
        _ = offset;
        _ = size;
        unreachable;
    }

    // TODO: file a bug on Dawn docstrings, this returns null but is not documented as such.
    pub inline fn bufferGetMappedRange(buffer: *gpu.Buffer, offset: usize, size: usize) ?*anyopaque {
        _ = buffer;
        _ = offset;
        _ = size;
        unreachable;
    }

    pub inline fn bufferGetSize(buffer: *gpu.Buffer) u64 {
        _ = buffer;
        unreachable;
    }

    pub inline fn bufferGetUsage(buffer: *gpu.Buffer) gpu.Buffer.UsageFlags {
        _ = buffer;
        unreachable;
    }

    pub inline fn bufferMapAsync(buffer: *gpu.Buffer, mode: gpu.MapModeFlags, offset: usize, size: usize, callback: gpu.Buffer.MapCallback, userdata: ?*anyopaque) void {
        _ = buffer;
        _ = mode;
        _ = offset;
        _ = size;
        _ = callback;
        _ = userdata;
        unreachable;
    }

    pub inline fn bufferSetLabel(buffer: *gpu.Buffer, label: [*:0]const u8) void {
        _ = buffer;
        _ = label;
        unreachable;
    }

    pub inline fn bufferUnmap(buffer: *gpu.Buffer) void {
        _ = buffer;
        unreachable;
    }

    pub inline fn bufferReference(buffer: *gpu.Buffer) void {
        _ = buffer;
        unreachable;
    }

    pub inline fn bufferRelease(buffer: *gpu.Buffer) void {
        _ = buffer;
        unreachable;
    }

    pub inline fn commandBufferSetLabel(command_buffer: *gpu.CommandBuffer, label: [*:0]const u8) void {
        _ = command_buffer;
        _ = label;
        unreachable;
    }

    pub inline fn commandBufferReference(command_buffer: *gpu.CommandBuffer) void {
        _ = command_buffer;
        unreachable;
    }

    pub inline fn commandBufferRelease(command_buffer: *gpu.CommandBuffer) void {
        _ = command_buffer;
        unreachable;
    }

    pub inline fn commandEncoderBeginComputePass(command_encoder: *gpu.CommandEncoder, descriptor: ?*const gpu.ComputePassDescriptor) *gpu.ComputePassEncoder {
        _ = command_encoder;
        _ = descriptor;
        unreachable;
    }

    pub inline fn commandEncoderBeginRenderPass(command_encoder: *gpu.CommandEncoder, descriptor: *const gpu.RenderPassDescriptor) *gpu.RenderPassEncoder {
        _ = command_encoder;
        _ = descriptor;
        unreachable;
    }

    pub inline fn commandEncoderClearBuffer(command_encoder: *gpu.CommandEncoder, buffer: *gpu.Buffer, offset: u64, size: u64) void {
        _ = command_encoder;
        _ = buffer;
        _ = offset;
        _ = size;
        unreachable;
    }

    pub inline fn commandEncoderCopyBufferToBuffer(command_encoder: *gpu.CommandEncoder, source: *gpu.Buffer, source_offset: u64, destination: *gpu.Buffer, destination_offset: u64, size: u64) void {
        _ = command_encoder;
        _ = source;
        _ = source_offset;
        _ = destination;
        _ = destination_offset;
        _ = size;
        unreachable;
    }

    pub inline fn commandEncoderCopyBufferToTexture(command_encoder: *gpu.CommandEncoder, source: *const gpu.ImageCopyBuffer, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) void {
        _ = command_encoder;
        _ = source;
        _ = destination;
        _ = copy_size;
        unreachable;
    }

    pub inline fn commandEncoderCopyTextureToBuffer(command_encoder: *gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyBuffer, copy_size: *const gpu.Extent3D) void {
        _ = command_encoder;
        _ = source;
        _ = destination;
        _ = copy_size;
        unreachable;
    }

    pub inline fn commandEncoderCopyTextureToTexture(command_encoder: *gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) void {
        _ = command_encoder;
        _ = source;
        _ = destination;
        _ = copy_size;
        unreachable;
    }

    pub inline fn commandEncoderCopyTextureToTextureInternal(command_encoder: *gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) void {
        _ = command_encoder;
        _ = source;
        _ = destination;
        _ = copy_size;
        unreachable;
    }

    pub inline fn commandEncoderFinish(command_encoder: *gpu.CommandEncoder, descriptor: ?*const gpu.CommandBuffer.Descriptor) *gpu.CommandBuffer {
        _ = command_encoder;
        _ = descriptor;
        unreachable;
    }

    pub inline fn commandEncoderInjectValidationError(command_encoder: *gpu.CommandEncoder, message: [*:0]const u8) void {
        _ = command_encoder;
        _ = message;
        unreachable;
    }

    pub inline fn commandEncoderInsertDebugMarker(command_encoder: *gpu.CommandEncoder, marker_label: [*:0]const u8) void {
        _ = command_encoder;
        _ = marker_label;
        unreachable;
    }

    pub inline fn commandEncoderPopDebugGroup(command_encoder: *gpu.CommandEncoder) void {
        _ = command_encoder;
        unreachable;
    }

    pub inline fn commandEncoderPushDebugGroup(command_encoder: *gpu.CommandEncoder, group_label: [*:0]const u8) void {
        _ = command_encoder;
        _ = group_label;
        unreachable;
    }

    pub inline fn commandEncoderResolveQuerySet(command_encoder: *gpu.CommandEncoder, query_set: *gpu.QuerySet, first_query: u32, query_count: u32, destination: *gpu.Buffer, destination_offset: u64) void {
        _ = command_encoder;
        _ = query_set;
        _ = first_query;
        _ = query_count;
        _ = destination;
        _ = destination_offset;
        unreachable;
    }

    pub inline fn commandEncoderSetLabel(command_encoder: *gpu.CommandEncoder, label: [*:0]const u8) void {
        _ = command_encoder;
        _ = label;
        unreachable;
    }

    pub inline fn commandEncoderWriteBuffer(command_encoder: *gpu.CommandEncoder, buffer: *gpu.Buffer, buffer_offset: u64, data: [*]const u8, size: u64) void {
        _ = command_encoder;
        _ = buffer;
        _ = buffer_offset;
        _ = data;
        _ = size;
        unreachable;
    }

    pub inline fn commandEncoderWriteTimestamp(command_encoder: *gpu.CommandEncoder, query_set: *gpu.QuerySet, query_index: u32) void {
        _ = command_encoder;
        _ = query_set;
        _ = query_index;
        unreachable;
    }

    pub inline fn commandEncoderReference(command_encoder: *gpu.CommandEncoder) void {
        _ = command_encoder;
        unreachable;
    }

    pub inline fn commandEncoderRelease(command_encoder: *gpu.CommandEncoder) void {
        _ = command_encoder;
        unreachable;
    }

    pub inline fn computePassEncoderDispatchWorkgroups(compute_pass_encoder: *gpu.ComputePassEncoder, workgroup_count_x: u32, workgroup_count_y: u32, workgroup_count_z: u32) void {
        _ = compute_pass_encoder;
        _ = workgroup_count_x;
        _ = workgroup_count_y;
        _ = workgroup_count_z;
        unreachable;
    }

    pub inline fn computePassEncoderDispatchWorkgroupsIndirect(compute_pass_encoder: *gpu.ComputePassEncoder, indirect_buffer: *gpu.Buffer, indirect_offset: u64) void {
        _ = compute_pass_encoder;
        _ = indirect_buffer;
        _ = indirect_offset;
        unreachable;
    }

    pub inline fn computePassEncoderEnd(compute_pass_encoder: *gpu.ComputePassEncoder) void {
        _ = compute_pass_encoder;
        unreachable;
    }

    pub inline fn computePassEncoderInsertDebugMarker(compute_pass_encoder: *gpu.ComputePassEncoder, marker_label: [*:0]const u8) void {
        _ = compute_pass_encoder;
        _ = marker_label;
        unreachable;
    }

    pub inline fn computePassEncoderPopDebugGroup(compute_pass_encoder: *gpu.ComputePassEncoder) void {
        _ = compute_pass_encoder;
        unreachable;
    }

    pub inline fn computePassEncoderPushDebugGroup(compute_pass_encoder: *gpu.ComputePassEncoder, group_label: [*:0]const u8) void {
        _ = compute_pass_encoder;
        _ = group_label;
        unreachable;
    }

    pub inline fn computePassEncoderSetBindGroup(compute_pass_encoder: *gpu.ComputePassEncoder, group_index: u32, group: *gpu.BindGroup, dynamic_offset_count: u32, dynamic_offsets: ?[*]const u32) void {
        _ = compute_pass_encoder;
        _ = group_index;
        _ = group;
        _ = dynamic_offset_count;
        _ = dynamic_offsets;
        unreachable;
    }

    pub inline fn computePassEncoderSetLabel(compute_pass_encoder: *gpu.ComputePassEncoder, label: [*:0]const u8) void {
        _ = compute_pass_encoder;
        _ = label;
        unreachable;
    }

    pub inline fn computePassEncoderSetPipeline(compute_pass_encoder: *gpu.ComputePassEncoder, pipeline: *gpu.ComputePipeline) void {
        _ = compute_pass_encoder;
        _ = pipeline;
        unreachable;
    }

    pub inline fn computePassEncoderWriteTimestamp(compute_pass_encoder: *gpu.ComputePassEncoder, query_set: *gpu.QuerySet, query_index: u32) void {
        _ = compute_pass_encoder;
        _ = query_set;
        _ = query_index;
        unreachable;
    }

    pub inline fn computePassEncoderReference(compute_pass_encoder: *gpu.ComputePassEncoder) void {
        _ = compute_pass_encoder;
        unreachable;
    }

    pub inline fn computePassEncoderRelease(compute_pass_encoder: *gpu.ComputePassEncoder) void {
        _ = compute_pass_encoder;
        unreachable;
    }

    pub inline fn computePipelineGetBindGroupLayout(compute_pipeline: *gpu.ComputePipeline, group_index: u32) *gpu.BindGroupLayout {
        _ = compute_pipeline;
        _ = group_index;
        unreachable;
    }

    pub inline fn computePipelineSetLabel(compute_pipeline: *gpu.ComputePipeline, label: [*:0]const u8) void {
        _ = compute_pipeline;
        _ = label;
        unreachable;
    }

    pub inline fn computePipelineReference(compute_pipeline: *gpu.ComputePipeline) void {
        _ = compute_pipeline;
        unreachable;
    }

    pub inline fn computePipelineRelease(compute_pipeline: *gpu.ComputePipeline) void {
        _ = compute_pipeline;
        unreachable;
    }

    pub inline fn deviceCreateBindGroup(device: *gpu.Device, descriptor: *const gpu.BindGroup.Descriptor) *gpu.BindGroup {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceCreateBindGroupLayout(device: *gpu.Device, descriptor: *const gpu.BindGroupLayout.Descriptor) *gpu.BindGroupLayout {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceCreateBuffer(device: *gpu.Device, descriptor: *const gpu.Buffer.Descriptor) *gpu.Buffer {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceCreateCommandEncoder(device: *gpu.Device, descriptor: ?*const gpu.CommandEncoder.Descriptor) *gpu.CommandEncoder {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceCreateComputePipeline(device: *gpu.Device, descriptor: *const gpu.ComputePipeline.Descriptor) *gpu.ComputePipeline {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceCreateComputePipelineAsync(device: *gpu.Device, descriptor: *const gpu.ComputePipeline.Descriptor, callback: gpu.CreateComputePipelineAsyncCallback, userdata: ?*anyopaque) void {
        _ = device;
        _ = descriptor;
        _ = callback;
        _ = userdata;
        unreachable;
    }

    pub inline fn deviceCreateErrorBuffer(device: *gpu.Device) *gpu.Buffer {
        _ = device;
        unreachable;
    }

    pub inline fn deviceCreateErrorExternalTexture(device: *gpu.Device) *gpu.ExternalTexture {
        _ = device;
        unreachable;
    }

    pub inline fn deviceCreateErrorTexture(device: *gpu.Device, descriptor: *const gpu.Texture.Descriptor) *gpu.Texture {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceCreateExternalTexture(device: *gpu.Device, external_texture_descriptor: *const gpu.ExternalTexture.Descriptor) *gpu.ExternalTexture {
        _ = device;
        _ = external_texture_descriptor;
        unreachable;
    }

    pub inline fn deviceCreatePipelineLayout(device: *gpu.Device, pipeline_layout_descriptor: *const gpu.PipelineLayout.Descriptor) *gpu.PipelineLayout {
        _ = device;
        _ = pipeline_layout_descriptor;
        unreachable;
    }

    pub inline fn deviceCreateQuerySet(device: *gpu.Device, descriptor: *const gpu.QuerySet.Descriptor) *gpu.QuerySet {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceCreateRenderBundleEncoder(device: *gpu.Device, descriptor: *const gpu.RenderBundleEncoder.Descriptor) *gpu.RenderBundleEncoder {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceCreateRenderPipeline(device: *gpu.Device, descriptor: *const gpu.RenderPipeline.Descriptor) *gpu.RenderPipeline {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceCreateRenderPipelineAsync(device: *gpu.Device, descriptor: *const gpu.RenderPipeline.Descriptor, callback: gpu.CreateRenderPipelineAsyncCallback, userdata: ?*anyopaque) void {
        _ = device;
        _ = descriptor;
        _ = callback;
        _ = userdata;
        unreachable;
    }

    pub inline fn deviceCreateSampler(device: *gpu.Device, descriptor: ?*const gpu.Sampler.Descriptor) *gpu.Sampler {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceCreateShaderModule(device: *gpu.Device, descriptor: *const gpu.ShaderModule.Descriptor) *gpu.ShaderModule {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceCreateSwapChain(device: *gpu.Device, surface: ?*gpu.Surface, descriptor: *const gpu.SwapChain.Descriptor) *gpu.SwapChain {
        _ = device;
        _ = surface;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceCreateTexture(device: *gpu.Device, descriptor: *const gpu.Texture.Descriptor) *gpu.Texture {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceDestroy(device: *gpu.Device) void {
        _ = device;
        unreachable;
    }

    pub inline fn deviceEnumerateFeatures(device: *gpu.Device, features: [*]gpu.FeatureName) usize {
        _ = device;
        _ = features;
        unreachable;
    }

    pub inline fn deviceGetLimits(device: *gpu.Device, limits: *gpu.SupportedLimits) bool {
        _ = device;
        _ = limits;
        unreachable;
    }

    pub inline fn deviceGetQueue(device: *gpu.Device) *gpu.Queue {
        _ = device;
        unreachable;
    }

    pub inline fn deviceHasFeature(device: *gpu.Device, feature: gpu.FeatureName) bool {
        _ = device;
        _ = feature;
        unreachable;
    }

    pub inline fn deviceInjectError(device: *gpu.Device, typ: gpu.ErrorType, message: [*:0]const u8) void {
        _ = device;
        _ = typ;
        _ = message;
        unreachable;
    }

    pub inline fn deviceLoseForTesting(device: *gpu.Device) void {
        _ = device;
        unreachable;
    }

    pub inline fn devicePopErrorScope(device: *gpu.Device, callback: gpu.ErrorCallback, userdata: ?*anyopaque) bool {
        _ = device;
        _ = callback;
        _ = userdata;
        unreachable;
    }

    pub inline fn devicePushErrorScope(device: *gpu.Device, filter: gpu.ErrorFilter) void {
        _ = device;
        _ = filter;
        unreachable;
    }

    pub inline fn deviceSetDeviceLostCallback(device: *gpu.Device, callback: gpu.Device.LostCallback, userdata: ?*anyopaque) void {
        _ = device;
        _ = callback;
        _ = userdata;
        unreachable;
    }

    pub inline fn deviceSetLabel(device: *gpu.Device, label: [*:0]const u8) void {
        _ = device;
        _ = label;
        unreachable;
    }

    pub inline fn deviceSetLoggingCallback(device: *gpu.Device, callback: gpu.LoggingCallback, userdata: ?*anyopaque) void {
        _ = device;
        _ = callback;
        _ = userdata;
        unreachable;
    }

    pub inline fn deviceSetUncapturedErrorCallback(device: *gpu.Device, callback: gpu.ErrorCallback, userdata: ?*anyopaque) void {
        _ = device;
        _ = callback;
        _ = userdata;
        unreachable;
    }

    pub inline fn deviceTick(device: *gpu.Device) void {
        _ = device;
        unreachable;
    }

    pub inline fn deviceReference(device: *gpu.Device) void {
        _ = device;
        unreachable;
    }

    pub inline fn deviceRelease(device: *gpu.Device) void {
        _ = device;
        unreachable;
    }

    pub inline fn externalTextureDestroy(external_texture: *gpu.ExternalTexture) void {
        _ = external_texture;
        unreachable;
    }

    pub inline fn externalTextureSetLabel(external_texture: *gpu.ExternalTexture, label: [*:0]const u8) void {
        _ = external_texture;
        _ = label;
        unreachable;
    }

    pub inline fn externalTextureReference(external_texture: *gpu.ExternalTexture) void {
        _ = external_texture;
        unreachable;
    }

    pub inline fn externalTextureRelease(external_texture: *gpu.ExternalTexture) void {
        _ = external_texture;
        unreachable;
    }

    pub inline fn instanceCreateSurface(instance: *gpu.Instance, descriptor: *const gpu.Surface.Descriptor) *gpu.Surface {
        _ = instance;
        _ = descriptor;
        unreachable;
    }

    pub inline fn instanceRequestAdapter(instance: *gpu.Instance, options: ?*const gpu.RequestAdapterOptions, callback: gpu.RequestAdapterCallback, userdata: ?*anyopaque) void {
        _ = instance;
        _ = options;
        _ = callback;
        _ = userdata;
        unreachable;
    }

    pub inline fn instanceReference(instance: *gpu.Instance) void {
        _ = instance;
        unreachable;
    }

    pub inline fn instanceRelease(instance: *gpu.Instance) void {
        _ = instance;
        unreachable;
    }

    pub inline fn pipelineLayoutSetLabel(pipeline_layout: *gpu.PipelineLayout, label: [*:0]const u8) void {
        _ = pipeline_layout;
        _ = label;
        unreachable;
    }

    pub inline fn pipelineLayoutReference(pipeline_layout: *gpu.PipelineLayout) void {
        _ = pipeline_layout;
        unreachable;
    }

    pub inline fn pipelineLayoutRelease(pipeline_layout: *gpu.PipelineLayout) void {
        _ = pipeline_layout;
        unreachable;
    }

    pub inline fn querySetDestroy(query_set: *gpu.QuerySet) void {
        _ = query_set;
        unreachable;
    }

    pub inline fn querySetGetCount(query_set: *gpu.QuerySet) u32 {
        _ = query_set;
        unreachable;
    }

    pub inline fn querySetGetType(query_set: *gpu.QuerySet) gpu.QueryType {
        _ = query_set;
        unreachable;
    }

    pub inline fn querySetSetLabel(query_set: *gpu.QuerySet, label: [*:0]const u8) void {
        _ = query_set;
        _ = label;
        unreachable;
    }

    pub inline fn querySetReference(query_set: *gpu.QuerySet) void {
        _ = query_set;
        unreachable;
    }

    pub inline fn querySetRelease(query_set: *gpu.QuerySet) void {
        _ = query_set;
        unreachable;
    }

    pub inline fn queueCopyTextureForBrowser(queue: *gpu.Queue, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D, options: *const gpu.CopyTextureForBrowserOptions) void {
        _ = queue;
        _ = source;
        _ = destination;
        _ = copy_size;
        _ = options;
        unreachable;
    }

    pub inline fn queueOnSubmittedWorkDone(queue: *gpu.Queue, signal_value: u64, callback: gpu.Queue.WorkDoneCallback, userdata: ?*anyopaque) void {
        _ = queue;
        _ = signal_value;
        _ = callback;
        _ = userdata;
        unreachable;
    }

    pub inline fn queueSetLabel(queue: *gpu.Queue, label: [*:0]const u8) void {
        _ = queue;
        _ = label;
        unreachable;
    }

    pub inline fn queueSubmit(queue: *gpu.Queue, command_count: u32, commands: [*]*const gpu.CommandBuffer) void {
        _ = queue;
        _ = command_count;
        _ = commands;
        unreachable;
    }

    pub inline fn queueWriteBuffer(queue: *gpu.Queue, buffer: *gpu.Buffer, buffer_offset: u64, data: *anyopaque, size: usize) void {
        _ = queue;
        _ = buffer;
        _ = buffer_offset;
        _ = data;
        _ = size;
        unreachable;
    }

    pub inline fn queueWriteTexture(queue: *gpu.Queue, destination: *const gpu.ImageCopyTexture, data: *const anyopaque, data_size: usize, data_layout: *const gpu.Texture.DataLayout, write_size: *const gpu.Extent3D) void {
        _ = queue;
        _ = destination;
        _ = data;
        _ = data_size;
        _ = data_layout;
        _ = write_size;
        unreachable;
    }

    pub inline fn queueReference(queue: *gpu.Queue) void {
        _ = queue;
        unreachable;
    }

    pub inline fn queueRelease(queue: *gpu.Queue) void {
        _ = queue;
        unreachable;
    }

    pub inline fn renderBundleReference(render_bundle: *gpu.RenderBundle) void {
        _ = render_bundle;
        unreachable;
    }

    pub inline fn renderBundleRelease(render_bundle: *gpu.RenderBundle) void {
        _ = render_bundle;
        unreachable;
    }

    pub inline fn renderBundleEncoderDraw(render_bundle_encoder: *gpu.RenderBundleEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {
        _ = render_bundle_encoder;
        _ = vertex_count;
        _ = instance_count;
        _ = first_vertex;
        _ = first_instance;
        unreachable;
    }

    pub inline fn renderBundleEncoderDrawIndexed(render_bundle_encoder: *gpu.RenderBundleEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: i32, first_instance: u32) void {
        _ = render_bundle_encoder;
        _ = index_count;
        _ = instance_count;
        _ = first_index;
        _ = base_vertex;
        _ = first_instance;
        unreachable;
    }

    pub inline fn renderBundleEncoderDrawIndexedIndirect(render_bundle_encoder: *gpu.RenderBundleEncoder, indirect_buffer: *gpu.Buffer, indirect_offset: u64) void {
        _ = render_bundle_encoder;
        _ = indirect_buffer;
        _ = indirect_offset;
        unreachable;
    }

    pub inline fn renderBundleEncoderDrawIndirect(render_bundle_encoder: *gpu.RenderBundleEncoder, indirect_buffer: *gpu.Buffer, indirect_offset: u64) void {
        _ = render_bundle_encoder;
        _ = indirect_buffer;
        _ = indirect_offset;
        unreachable;
    }

    pub inline fn renderBundleEncoderFinish(render_bundle_encoder: *gpu.RenderBundleEncoder, descriptor: ?*const gpu.RenderBundle.Descriptor) *gpu.RenderBundle {
        _ = render_bundle_encoder;
        _ = descriptor;
        unreachable;
    }

    pub inline fn renderBundleEncoderInsertDebugMarker(render_bundle_encoder: *gpu.RenderBundleEncoder, marker_label: [*:0]const u8) void {
        _ = render_bundle_encoder;
        _ = marker_label;
        unreachable;
    }

    pub inline fn renderBundleEncoderPopDebugGroup(render_bundle_encoder: *gpu.RenderBundleEncoder) void {
        _ = render_bundle_encoder;
        unreachable;
    }

    pub inline fn renderBundleEncoderPushDebugGroup(render_bundle_encoder: *gpu.RenderBundleEncoder, group_label: [*:0]const u8) void {
        _ = render_bundle_encoder;
        _ = group_label;
        unreachable;
    }

    pub inline fn renderBundleEncoderSetBindGroup(render_bundle_encoder: *gpu.RenderBundleEncoder, group_index: u32, group: *gpu.BindGroup, dynamic_offset_count: u32, dynamic_offsets: ?[*]const u32) void {
        _ = render_bundle_encoder;
        _ = group_index;
        _ = group;
        _ = dynamic_offset_count;
        _ = dynamic_offsets;
        unreachable;
    }

    pub inline fn renderBundleEncoderSetIndexBuffer(render_bundle_encoder: *gpu.RenderBundleEncoder, buffer: *gpu.Buffer, format: gpu.IndexFormat, offset: u64, size: u64) void {
        _ = render_bundle_encoder;
        _ = buffer;
        _ = format;
        _ = offset;
        _ = size;
        unreachable;
    }

    pub inline fn renderBundleEncoderSetLabel(render_bundle_encoder: *gpu.RenderBundleEncoder, label: [*:0]const u8) void {
        _ = render_bundle_encoder;
        _ = label;
        unreachable;
    }

    pub inline fn renderBundleEncoderSetPipeline(render_bundle_encoder: *gpu.RenderBundleEncoder, pipeline: *gpu.RenderPipeline) void {
        _ = render_bundle_encoder;
        _ = pipeline;
        unreachable;
    }

    pub inline fn renderBundleEncoderSetVertexBuffer(render_bundle_encoder: *gpu.RenderBundleEncoder, slot: u32, buffer: *gpu.Buffer, offset: u64, size: u64) void {
        _ = render_bundle_encoder;
        _ = slot;
        _ = buffer;
        _ = offset;
        _ = size;
        unreachable;
    }

    pub inline fn renderBundleEncoderReference(render_bundle_encoder: *gpu.RenderBundleEncoder) void {
        _ = render_bundle_encoder;
        unreachable;
    }

    pub inline fn renderBundleEncoderRelease(render_bundle_encoder: *gpu.RenderBundleEncoder) void {
        _ = render_bundle_encoder;
        unreachable;
    }

    pub inline fn renderPassEncoderBeginOcclusionQuery(render_pass_encoder: *gpu.RenderPassEncoder, query_index: u32) void {
        _ = render_pass_encoder;
        _ = query_index;
        unreachable;
    }

    pub inline fn renderPassEncoderDraw(render_pass_encoder: *gpu.RenderPassEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {
        _ = render_pass_encoder;
        _ = vertex_count;
        _ = instance_count;
        _ = first_vertex;
        _ = first_instance;
        unreachable;
    }

    pub inline fn renderPassEncoderDrawIndexed(render_pass_encoder: *gpu.RenderPassEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: i32, first_instance: u32) void {
        _ = render_pass_encoder;
        _ = index_count;
        _ = instance_count;
        _ = first_index;
        _ = base_vertex;
        _ = first_instance;
        unreachable;
    }

    pub inline fn renderPassEncoderDrawIndexedIndirect(render_pass_encoder: *gpu.RenderPassEncoder, indirect_buffer: *gpu.Buffer, indirect_offset: u64) void {
        _ = render_pass_encoder;
        _ = indirect_buffer;
        _ = indirect_offset;
        unreachable;
    }

    pub inline fn renderPassEncoderDrawIndirect(render_pass_encoder: *gpu.RenderPassEncoder, indirect_buffer: *gpu.Buffer, indirect_offset: u64) void {
        _ = render_pass_encoder;
        _ = indirect_buffer;
        _ = indirect_offset;
        unreachable;
    }

    pub inline fn renderPassEncoderEnd(render_pass_encoder: *gpu.RenderPassEncoder) void {
        _ = render_pass_encoder;
        unreachable;
    }

    pub inline fn renderPassEncoderEndOcclusionQuery(render_pass_encoder: *gpu.RenderPassEncoder) void {
        _ = render_pass_encoder;
        unreachable;
    }

    pub inline fn renderPassEncoderExecuteBundles(render_pass_encoder: *gpu.RenderPassEncoder, bundles_count: u32, bundles: [*]const *const gpu.RenderBundle) void {
        _ = render_pass_encoder;
        _ = bundles_count;
        _ = bundles;
        unreachable;
    }

    pub inline fn renderPassEncoderInsertDebugMarker(render_pass_encoder: *gpu.RenderPassEncoder, marker_label: [*:0]const u8) void {
        _ = render_pass_encoder;
        _ = marker_label;
        unreachable;
    }

    pub inline fn renderPassEncoderPopDebugGroup(render_pass_encoder: *gpu.RenderPassEncoder) void {
        _ = render_pass_encoder;
        unreachable;
    }

    pub inline fn renderPassEncoderPushDebugGroup(render_pass_encoder: *gpu.RenderPassEncoder, group_label: [*:0]const u8) void {
        _ = render_pass_encoder;
        _ = group_label;
        unreachable;
    }

    pub inline fn renderPassEncoderSetBindGroup(render_pass_encoder: *gpu.RenderPassEncoder, group_index: u32, group: *gpu.BindGroup, dynamic_offset_count: u32, dynamic_offsets: ?[*]const u32) void {
        _ = render_pass_encoder;
        _ = group_index;
        _ = group;
        _ = dynamic_offset_count;
        _ = dynamic_offsets;
        unreachable;
    }

    pub inline fn renderPassEncoderSetBlendConstant(render_pass_encoder: *gpu.RenderPassEncoder, color: *const gpu.Color) void {
        _ = render_pass_encoder;
        _ = color;
        unreachable;
    }

    pub inline fn renderPassEncoderSetIndexBuffer(render_pass_encoder: *gpu.RenderPassEncoder, buffer: *gpu.Buffer, format: gpu.IndexFormat, offset: u64, size: u64) void {
        _ = render_pass_encoder;
        _ = buffer;
        _ = format;
        _ = offset;
        _ = size;
        unreachable;
    }

    pub inline fn renderPassEncoderSetLabel(render_pass_encoder: *gpu.RenderPassEncoder, label: [*:0]const u8) void {
        _ = render_pass_encoder;
        _ = label;
        unreachable;
    }

    pub inline fn renderPassEncoderSetPipeline(render_pass_encoder: *gpu.RenderPassEncoder, pipeline: *gpu.RenderPipeline) void {
        _ = render_pass_encoder;
        _ = pipeline;
        unreachable;
    }

    pub inline fn renderPassEncoderSetScissorRect(render_pass_encoder: *gpu.RenderPassEncoder, x: u32, y: u32, width: u32, height: u32) void {
        _ = render_pass_encoder;
        _ = x;
        _ = y;
        _ = width;
        _ = height;
        unreachable;
    }

    pub inline fn renderPassEncoderSetStencilReference(render_pass_encoder: *gpu.RenderPassEncoder, reference: u32) void {
        _ = render_pass_encoder;
        _ = reference;
        unreachable;
    }

    pub inline fn renderPassEncoderSetVertexBuffer(render_pass_encoder: *gpu.RenderPassEncoder, slot: u32, buffer: *gpu.Buffer, offset: u64, size: u64) void {
        _ = render_pass_encoder;
        _ = slot;
        _ = buffer;
        _ = offset;
        _ = size;
        unreachable;
    }

    pub inline fn renderPassEncoderSetViewport(render_pass_encoder: *gpu.RenderPassEncoder, x: f32, y: f32, width: f32, height: f32, min_depth: f32, max_depth: f32) void {
        _ = render_pass_encoder;
        _ = x;
        _ = y;
        _ = width;
        _ = height;
        _ = min_depth;
        _ = max_depth;
        unreachable;
    }

    pub inline fn renderPassEncoderWriteTimestamp(render_pass_encoder: *gpu.RenderPassEncoder, query_set: *gpu.QuerySet, query_index: u32) void {
        _ = render_pass_encoder;
        _ = query_set;
        _ = query_index;
        unreachable;
    }

    pub inline fn renderPassEncoderReference(render_pass_encoder: *gpu.RenderPassEncoder) void {
        _ = render_pass_encoder;
        unreachable;
    }

    pub inline fn renderPassEncoderRelease(render_pass_encoder: *gpu.RenderPassEncoder) void {
        _ = render_pass_encoder;
        unreachable;
    }

    pub inline fn renderPipelineGetBindGroupLayout(render_pipeline: *gpu.RenderPipeline, group_index: u32) *gpu.BindGroupLayout {
        _ = render_pipeline;
        _ = group_index;
        unreachable;
    }

    pub inline fn renderPipelineSetLabel(render_pipeline: *gpu.RenderPipeline, label: [*:0]const u8) void {
        _ = render_pipeline;
        _ = label;
        unreachable;
    }

    pub inline fn renderPipelineReference(render_pipeline: *gpu.RenderPipeline) void {
        _ = render_pipeline;
        unreachable;
    }

    pub inline fn renderPipelineRelease(render_pipeline: *gpu.RenderPipeline) void {
        _ = render_pipeline;
        unreachable;
    }

    pub inline fn samplerSetLabel(sampler: *gpu.Sampler, label: [*:0]const u8) void {
        _ = sampler;
        _ = label;
        unreachable;
    }

    pub inline fn samplerReference(sampler: *gpu.Sampler) void {
        _ = sampler;
        unreachable;
    }

    pub inline fn samplerRelease(sampler: *gpu.Sampler) void {
        _ = sampler;
        unreachable;
    }

    pub inline fn shaderModuleGetCompilationInfo(shader_module: *gpu.ShaderModule, callback: gpu.CompilationInfoCallback, userdata: ?*anyopaque) void {
        _ = shader_module;
        _ = callback;
        _ = userdata;
        unreachable;
    }

    pub inline fn shaderModuleSetLabel(shader_module: *gpu.ShaderModule, label: [*:0]const u8) void {
        _ = shader_module;
        _ = label;
        unreachable;
    }

    pub inline fn shaderModuleReference(shader_module: *gpu.ShaderModule) void {
        _ = shader_module;
        unreachable;
    }

    pub inline fn shaderModuleRelease(shader_module: *gpu.ShaderModule) void {
        _ = shader_module;
        unreachable;
    }

    pub inline fn surfaceReference(surface: *gpu.Surface) void {
        _ = surface;
        unreachable;
    }

    pub inline fn surfaceRelease(surface: *gpu.Surface) void {
        _ = surface;
        unreachable;
    }

    pub inline fn swapChainConfigure(swap_chain: *gpu.SwapChain, format: gpu.Texture.Format, allowed_usage: gpu.Texture.UsageFlags, width: u32, height: u32) void {
        _ = swap_chain;
        _ = format;
        _ = allowed_usage;
        _ = width;
        _ = height;
        unreachable;
    }

    pub inline fn swapChainGetCurrentTextureView(swap_chain: *gpu.SwapChain) *gpu.TextureView {
        _ = swap_chain;
        unreachable;
    }

    pub inline fn swapChainPresent(swap_chain: *gpu.SwapChain) void {
        _ = swap_chain;
        unreachable;
    }

    pub inline fn swapChainReference(swap_chain: *gpu.SwapChain) void {
        _ = swap_chain;
        unreachable;
    }

    pub inline fn swapChainRelease(swap_chain: *gpu.SwapChain) void {
        _ = swap_chain;
        unreachable;
    }

    pub inline fn textureCreateView(texture: *gpu.Texture, descriptor: ?*const gpu.TextureView.Descriptor) *gpu.TextureView {
        _ = texture;
        _ = descriptor;
        unreachable;
    }

    pub inline fn textureDestroy(texture: *gpu.Texture) void {
        _ = texture;
        unreachable;
    }

    pub inline fn textureGetDepthOrArrayLayers(texture: *gpu.Texture) u32 {
        _ = texture;
        unreachable;
    }

    pub inline fn textureGetDimension(texture: *gpu.Texture) gpu.Texture.Dimension {
        _ = texture;
        unreachable;
    }

    pub inline fn textureGetFormat(texture: *gpu.Texture) gpu.Texture.Format {
        _ = texture;
        unreachable;
    }

    pub inline fn textureGetHeight(texture: *gpu.Texture) u32 {
        _ = texture;
        unreachable;
    }

    pub inline fn textureGetMipLevelCount(texture: *gpu.Texture) u32 {
        _ = texture;
        unreachable;
    }

    pub inline fn textureGetSampleCount(texture: *gpu.Texture) u32 {
        _ = texture;
        unreachable;
    }

    pub inline fn textureGetUsage(texture: *gpu.Texture) gpu.Texture.UsageFlags {
        _ = texture;
        unreachable;
    }

    pub inline fn textureGetWidth(texture: *gpu.Texture) u32 {
        _ = texture;
        unreachable;
    }

    pub inline fn textureSetLabel(texture: *gpu.Texture, label: [*:0]const u8) void {
        _ = texture;
        _ = label;
        unreachable;
    }

    pub inline fn textureReference(texture: *gpu.Texture) void {
        _ = texture;
        unreachable;
    }

    pub inline fn textureRelease(texture: *gpu.Texture) void {
        _ = texture;
        unreachable;
    }

    pub inline fn textureViewSetLabel(texture_view: *gpu.TextureView, label: [*:0]const u8) void {
        _ = texture_view;
        _ = label;
        unreachable;
    }

    pub inline fn textureViewReference(texture_view: *gpu.TextureView) void {
        _ = texture_view;
        unreachable;
    }

    pub inline fn textureViewRelease(texture_view: *gpu.TextureView) void {
        _ = texture_view;
        unreachable;
    }
});

test "stub" {
    _ = StubInterface;
}
