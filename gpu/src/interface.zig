const Instance = @import("instance.zig").Instance;
const InstanceDescriptor = @import("instance.zig").InstanceDescriptor;
const gpu = @import("main.zig");

/// The gpu.Interface implementation that is used by the entire program. Only one may exist, since
/// it is resolved fully at comptime with no vtable indirection, etc.
pub const impl = blk: {
    if (@import("builtin").is_test) {
        break :blk StubInterface{};
    } else {
        const root = @import("root");
        if (!@hasField(root, "gpu_interface")) @compileError("expected to find `pub const gpu_interface: gpu.Interface(T) = T{};` in root file");
        _ = gpu.Interface(@TypeOf(root.gpu_interface)); // verify the type
        break :blk root.gpu_interface;
    }
};

/// Verifies that a gpu.Interface implementation exposes the expected function declarations.
pub fn Interface(comptime Impl: type) type {
    assertDecl(Impl, "createInstance", fn (descriptor: *const InstanceDescriptor) callconv(.Inline) ?Instance);
    assertDecl(Impl, "getProcAddress", fn (device: gpu.Device, proc_name: [*:0]const u8) callconv(.Inline) ?gpu.Proc);
    assertDecl(Impl, "adapterCreateDevice", fn (adapter: gpu.Adapter, descriptor: ?*const gpu.DeviceDescriptor) callconv(.Inline) ?gpu.Device);
    assertDecl(Impl, "adapterEnumerateFeatures", fn (adapter: gpu.Adapter, features: ?[*]gpu.FeatureName) callconv(.Inline) usize);
    assertDecl(Impl, "adapterGetLimits", fn (adapter: gpu.Adapter, limits: *gpu.SupportedLimits) callconv(.Inline) bool);
    assertDecl(Impl, "adapterGetProperties", fn (adapter: gpu.Adapter, properties: *gpu.AdapterProperties) callconv(.Inline) void);
    assertDecl(Impl, "adapterHasFeature", fn (adapter: gpu.Adapter, feature: gpu.FeatureName) callconv(.Inline) bool);
    assertDecl(Impl, "adapterRequestDevice", fn (adapter: gpu.Adapter, descriptor: ?*const gpu.DeviceDescriptor, callback: gpu.RequestDeviceCallback, userdata: *anyopaque) callconv(.Inline) void);
    assertDecl(Impl, "adapterReference", fn (adapter: gpu.Adapter) callconv(.Inline) void);
    assertDecl(Impl, "adapterRelease", fn (adapter: gpu.Adapter) callconv(.Inline) void);
    assertDecl(Impl, "bindGroupSetLabel", fn (bind_group: gpu.BindGroup, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(Impl, "bindGroupReference", fn (bind_group: gpu.BindGroup) callconv(.Inline) void);
    assertDecl(Impl, "bindGroupRelease", fn (bind_group: gpu.BindGroup) callconv(.Inline) void);
    assertDecl(Impl, "bindGroupLayoutSetLabel", fn (bind_group_layout: gpu.BindGroupLayout, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(Impl, "bindGroupLayoutReference", fn (bind_group_layout: gpu.BindGroupLayout) callconv(.Inline) void);
    assertDecl(Impl, "bindGroupLayoutRelease", fn (bind_group_layout: gpu.BindGroupLayout) callconv(.Inline) void);
    assertDecl(Impl, "bufferDestroy", fn (buffer: gpu.Buffer) callconv(.Inline) void);
    assertDecl(Impl, "bufferGetConstMappedRange", fn (buffer: gpu.Buffer, offset: usize, size: usize) callconv(.Inline) *const anyopaque);
    assertDecl(Impl, "bufferGetMappedRange", fn (buffer: gpu.Buffer, offset: usize, size: usize) callconv(.Inline) *anyopaque);
    assertDecl(Impl, "bufferGetSize", fn (buffer: gpu.Buffer) callconv(.Inline) u64);
    assertDecl(Impl, "bufferGetUsage", fn (buffer: gpu.Buffer) callconv(.Inline) gpu.BufferUsage);
    assertDecl(Impl, "bufferMapAsync", fn (buffer: gpu.Buffer, mode: gpu.MapMode, offset: usize, size: usize, callback: gpu.BufferMapCallback, userdata: *anyopaque) callconv(.Inline) u64);
    assertDecl(Impl, "bufferSetLabel", fn (buffer: gpu.Buffer, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(Impl, "bufferUnmap", fn (buffer: gpu.Buffer) callconv(.Inline) void);
    assertDecl(Impl, "bufferReference", fn (buffer: gpu.Buffer) callconv(.Inline) void);
    assertDecl(Impl, "bufferRelease", fn (buffer: gpu.Buffer) callconv(.Inline) void);
    assertDecl(Impl, "commandBufferSetLabel", fn (command_buffer: gpu.CommandBuffer, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(Impl, "commandBufferReference", fn (command_buffer: gpu.CommandBuffer) callconv(.Inline) void);
    assertDecl(Impl, "commandBufferRelease", fn (command_buffer: gpu.CommandBuffer) callconv(.Inline) void);
    assertDecl(Impl, "commandEncoderBeginComputePass", fn (command_encoder: gpu.CommandEncoder, descriptor: ?*const gpu.ComputePassDescriptor) callconv(.Inline) gpu.ComputePassEncoder);
    assertDecl(Impl, "commandEncoderBeginRenderPass", fn (command_encoder: gpu.CommandEncoder, descriptor: *const gpu.RenderPassDescriptor) callconv(.Inline) gpu.RenderPassEncoder);
    assertDecl(Impl, "commandEncoderClearBuffer", fn (command_encoder: gpu.CommandEncoder, buffer: gpu.Buffer, offset: u64, size: u64) callconv(.Inline) void);
    assertDecl(Impl, "commandEncoderCopyBufferToBuffer", fn (command_encoder: gpu.CommandEncoder, source: gpu.Buffer, source_offset: u64, destination: gpu.Buffer, destination_offset: u64, size: u64) callconv(.Inline) void);
    assertDecl(Impl, "commandEncoderCopyBufferToTexture", fn (command_encoder: gpu.CommandEncoder, source: *const gpu.ImageCopyBuffer, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) callconv(.Inline) void);
    assertDecl(Impl, "commandEncoderCopyTextureToBuffer", fn (command_encoder: gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyBuffer, copy_size: *const gpu.Extent3D) callconv(.Inline) void);
    assertDecl(Impl, "commandEncoderCopyTextureToTexture", fn (command_encoder: gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) callconv(.Inline) void);
    assertDecl(Impl, "commandEncoderCopyTextureToTextureInternal", fn (command_encoder: gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) callconv(.Inline) void);
    assertDecl(Impl, "commandEncoderFinish", fn (command_encoder: gpu.CommandEncoder, descriptor: ?*const gpu.CommandBufferDescriptor) callconv(.Inline) gpu.CommandBuffer);
    assertDecl(Impl, "commandEncoderInjectValidationError", fn (command_encoder: gpu.CommandEncoder, message: [*:0]const u8) callconv(.Inline) void);
    assertDecl(Impl, "commandEncoderInsertDebugMarker", fn (command_encoder: gpu.CommandEncoder, marker_label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(Impl, "commandEncoderPopDebugGroup", fn (command_encoder: gpu.CommandEncoder) callconv(.Inline) void);
    assertDecl(Impl, "commandEncoderPushDebugGroup", fn (command_encoder: gpu.CommandEncoder, group_label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(Impl, "commandEncoderResolveQuerySet", fn (command_encoder: gpu.CommandEncoder, query_set: gpu.QuerySet, first_query: u32, query_count: u32, destination: gpu.Buffer, destination_offset: u64) callconv(.Inline) void);
    assertDecl(Impl, "commandEncoderSetLabel", fn (command_encoder: gpu.CommandEncoder, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(Impl, "commandEncoderWriteBuffer", fn (command_encoder: gpu.CommandEncoder, buffer: gpu.Buffer, buffer_offset: u64, data: [*]const u8, size: u64) callconv(.Inline) void);
    assertDecl(Impl, "commandEncoderWriteTimestamp", fn (command_encoder: gpu.CommandEncoder, query_set: gpu.QuerySet, query_index: u32) callconv(.Inline) void);
    assertDecl(Impl, "commandEncoderReference", fn (command_encoder: gpu.CommandEncoder) callconv(.Inline) void);
    assertDecl(Impl, "commandEncoderRelease", fn (command_encoder: gpu.CommandEncoder) callconv(.Inline) void);
    assertDecl(Impl, "computePassEncoderDispatch", fn (compute_pass_encoder: gpu.ComputePassEncoder, workgroup_count_x: u32, workgroup_count_y: u32, workgroup_count_z: u32) callconv(.Inline) void);
    assertDecl(Impl, "computePassEncoderDispatchIndirect", fn (compute_pass_encoder: gpu.ComputePassEncoder, indirect_buffer: gpu.Buffer, indirect_offset: u64) callconv(.Inline) void);
    assertDecl(Impl, "computePassEncoderDispatchWorkgroups", fn (compute_pass_encoder: gpu.ComputePassEncoder, workgroup_count_x: u32, workgroup_count_y: u32, workgroup_count_z: u32) callconv(.Inline) void);
    assertDecl(Impl, "computePassEncoderDispatchWorkgroupsIndirect", fn (compute_pass_encoder: gpu.ComputePassEncoder, indirect_buffer: gpu.Buffer, indirect_offset: u64) callconv(.Inline) void);
    assertDecl(Impl, "computePassEncoderEnd", fn (compute_pass_encoder: gpu.ComputePassEncoder) callconv(.Inline) void);
    assertDecl(Impl, "computePassEncoderEndPass", fn (compute_pass_encoder: gpu.ComputePassEncoder) callconv(.Inline) void);
    assertDecl(Impl, "computePassEncoderInsertDebugMarker", fn (compute_pass_encoder: gpu.ComputePassEncoder, marker_label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(Impl, "computePassEncoderPopDebugGroup", fn (compute_pass_encoder: gpu.ComputePassEncoder) callconv(.Inline) void);
    assertDecl(Impl, "computePassEncoderPushDebugGroup", fn (compute_pass_encoder: gpu.ComputePassEncoder, group_label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(Impl, "computePassEncoderSetBindGroup", fn (compute_pass_encoder: gpu.ComputePassEncoder, group_index: u32, group: gpu.BindGroup, dynamic_offset_count: u32, dynamic_offsets: [*]const u32) callconv(.Inline) void);
    assertDecl(Impl, "computePassEncoderSetLabel", fn (compute_pass_encoder: gpu.ComputePassEncoder, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(Impl, "computePassEncoderSetPipeline", fn (compute_pass_encoder: gpu.ComputePassEncoder, pipeline: gpu.ComputePipeline) callconv(.Inline) void);
    assertDecl(Impl, "computePassEncoderWriteTimestamp", fn (compute_pass_encoder: gpu.ComputePassEncoder, pipeline: gpu.ComputePipeline) callconv(.Inline) void);
    assertDecl(Impl, "computePassEncoderReference", fn (compute_pass_encoder: gpu.ComputePassEncoder) callconv(.Inline) void);
    assertDecl(Impl, "computePassEncoderRelease", fn (compute_pass_encoder: gpu.ComputePassEncoder) callconv(.Inline) void);
    assertDecl(Impl, "computePipelineGetBindGroupLayout", fn (compute_pipeline: gpu.ComputePipeline, group_index: u32) callconv(.Inline) gpu.BindGroupLayout);
    assertDecl(Impl, "computePipelineSetLabel", fn (compute_pipeline: gpu.ComputePipeline, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(Impl, "computePipelineReference", fn (compute_pipeline: gpu.ComputePipeline) callconv(.Inline) void);
    assertDecl(Impl, "computePipelineRelease", fn (compute_pipeline: gpu.ComputePipeline) callconv(.Inline) void);
    assertDecl(Impl, "deviceCreateBindGroup", fn (device: gpu.Device, descriptor: *const gpu.BindGroupDescriptor) callconv(.Inline) gpu.BindGroup);
    assertDecl(Impl, "deviceCreateBindGroupLayout", fn (device: gpu.Device, descriptor: *const gpu.BindGroupLayoutDescriptor) callconv(.Inline) gpu.BindGroupLayout);
    assertDecl(Impl, "deviceCreateBuffer", fn (device: gpu.Device, descriptor: *const gpu.BufferDescriptor) callconv(.Inline) gpu.Buffer);
    assertDecl(Impl, "deviceCreateCommandEncoder", fn (device: gpu.Device, descriptor: ?*const gpu.CommandEncoderDescriptor) callconv(.Inline) gpu.CommandEncoder);
    assertDecl(Impl, "deviceCreateComputePipeline", fn (device: gpu.Device, descriptor: *const gpu.ComputePipelineDescriptor) callconv(.Inline) gpu.ComputePipeline);
    assertDecl(Impl, "deviceCreateComputePipelineAsync", fn (device: gpu.Device, descriptor: *const gpu.ComputePipelineDescriptor, callback: gpu.CreateComputePipelineAsyncCallback, userdata: *anyopaque) callconv(.Inline) void);
    assertDecl(Impl, "deviceCreateErrorBuffer", fn (device: gpu.Device) callconv(.Inline) gpu.Buffer);
    assertDecl(Impl, "deviceCreateErrorExternalTexture", fn (device: gpu.Device) callconv(.Inline) gpu.ExternalTexture);
    assertDecl(Impl, "deviceCreateExternalTexture", fn (device: gpu.Device, external_texture_descriptor: *const gpu.ExternalTextureDescriptor) callconv(.Inline) gpu.ExternalTexture);
    assertDecl(Impl, "deviceCreatePipelineLayout", fn (device: gpu.Device, pipeline_layout_descriptor: *const gpu.PipelineLayoutDescriptor) callconv(.Inline) gpu.PipelineLayout);
    assertDecl(Impl, "deviceCreateQuerySet", fn (device: gpu.Device, descriptor: *const gpu.QuerySetDescriptor) callconv(.Inline) gpu.QuerySet);
    assertDecl(Impl, "deviceCreateRenderBundleEncoder", fn (device: gpu.Device, descriptor: *const gpu.RenderBundleEncoderDescriptor) callconv(.Inline) gpu.RenderBundleEncoder);
    assertDecl(Impl, "deviceCreateRenderPipeline", fn (device: gpu.Device, descriptor: *const gpu.RenderPipelineDescriptor) callconv(.Inline) gpu.RenderPipeline);
    assertDecl(Impl, "deviceCreateRenderPipelineAsync", fn (device: gpu.Device, descriptor: *const gpu.RenderPipelineDescriptor, callback: gpu.CreateRenderPipelineAsyncCallback, userdata: *anyopaque) callconv(.Inline) void);
    assertDecl(Impl, "deviceCreateSampler", fn (device: gpu.Device, descriptor: ?*const gpu.SamplerDescriptor) callconv(.Inline) gpu.Sampler);
    assertDecl(Impl, "deviceCreateShaderModule", fn (device: gpu.Device, descriptor: *const gpu.ShaderModuleDescriptor) callconv(.Inline) gpu.ShaderModule);
    assertDecl(Impl, "deviceCreateSwapChain", fn (device: gpu.Device, surface: ?gpu.Surface, descriptor: *const gpu.SwapChainDescriptor) callconv(.Inline) gpu.SwapChain);
    assertDecl(Impl, "deviceCreateTexture", fn (device: gpu.Device, descriptor: *const gpu.TextureDescriptor) callconv(.Inline) gpu.Texture);
    assertDecl(Impl, "deviceDestroy", fn (device: gpu.Device) callconv(.Inline) void);
    assertDecl(Impl, "deviceEnumerateFeatures", fn (device: gpu.Device, features: [*]gpu.FeatureName) callconv(.Inline) usize);
    assertDecl(Impl, "deviceGetLimits", fn (device: gpu.Device, limits: *gpu.SupportedLimits) callconv(.Inline) bool);
    assertDecl(Impl, "deviceGetQueue", fn (device: gpu.Device) callconv(.Inline) gpu.Queue);
    assertDecl(Impl, "deviceHasFeature", fn (device: gpu.Device, feature: gpu.FeatureName) callconv(.Inline) bool);
    assertDecl(Impl, "deviceInjectError", fn (device: gpu.Device, typ: gpu.ErrorType, message: [*:0]const u8) callconv(.Inline) void);
    assertDecl(Impl, "deviceLoseForTesting", fn (device: gpu.Device) callconv(.Inline) void);
    assertDecl(Impl, "devicePopErrorScope", fn (device: gpu.Device, callback: gpu.ErrorCallback, userdata: *anyopaque) callconv(.Inline) bool);
    assertDecl(Impl, "devicePushErrorScope", fn (device: gpu.Device, filter: gpu.ErrorFilter) callconv(.Inline) void);
    assertDecl(Impl, "deviceSetDeviceLostCallback", fn (device: gpu.Device, callback: gpu.DeviceLostCallback, userdata: *anyopaque) callconv(.Inline) void);
    assertDecl(Impl, "deviceSetLabel", fn (device: gpu.Device, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(Impl, "deviceSetLoggingCallback", fn (device: gpu.Device, callback: gpu.LoggingCallback, userdata: *anyopaque) callconv(.Inline) void);
    assertDecl(Impl, "deviceSetUncapturedErrorCallback", fn (device: gpu.Device, callback: gpu.ErrorCallback, userdata: *anyopaque) callconv(.Inline) void);
    assertDecl(Impl, "deviceTick", fn (device: gpu.Device) callconv(.Inline) void);
    assertDecl(Impl, "deviceReference", fn (device: gpu.Device) callconv(.Inline) void);
    assertDecl(Impl, "deviceRelease", fn (device: gpu.Device) callconv(.Inline) void);
    assertDecl(Impl, "externalTextureDestroy", fn (external_texture: gpu.ExternalTexture) callconv(.Inline) void);
    assertDecl(Impl, "externalTextureSetLabel", fn (external_texture: gpu.ExternalTexture, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(Impl, "externalTextureReference", fn (external_texture: gpu.ExternalTexture) callconv(.Inline) void);
    assertDecl(Impl, "externalTextureRelease", fn (external_texture: gpu.ExternalTexture) callconv(.Inline) void);
    assertDecl(Impl, "instanceCreateSurface", fn (instance: gpu.Instance, descriptor: *const gpu.SurfaceDescriptor) callconv(.Inline) gpu.Surface);
    assertDecl(Impl, "instanceRequestAdapter", fn (instance: gpu.Instance, options: *const gpu.RequestAdapterOptions, callback: gpu.RequestAdapterCallback, userdata: *anyopaque) callconv(.Inline) void);
    assertDecl(Impl, "instanceReference", fn (instance: gpu.Instance) callconv(.Inline) void);
    assertDecl(Impl, "instanceRelease", fn (instance: gpu.Instance) callconv(.Inline) void);
    assertDecl(Impl, "pipelineLayoutSetLabel", fn (pipeline_layout: gpu.PipelineLayout, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(Impl, "pipelineLayoutReference", fn (pipeline_layout: gpu.PipelineLayout) callconv(.Inline) void);
    assertDecl(Impl, "pipelineLayoutRelease", fn (pipeline_layout: gpu.PipelineLayout) callconv(.Inline) void);
    assertDecl(Impl, "querySetDestroy", fn (query_set: gpu.QuerySet) callconv(.Inline) void);
    assertDecl(Impl, "querySetGetCount", fn (query_set: gpu.QuerySet) callconv(.Inline) u32);
    assertDecl(Impl, "querySetGetType", fn (query_set: gpu.QuerySet) callconv(.Inline) gpu.QueryType);
    assertDecl(Impl, "querySetSetLabel", fn (query_set: gpu.QuerySet, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(Impl, "querySetReference", fn (query_set: gpu.QuerySet) callconv(.Inline) void);
    assertDecl(Impl, "querySetRelease", fn (query_set: gpu.QuerySet) callconv(.Inline) void);
    // assertDecl(Impl, "queueCopyTextureForBrowser", fn (queue: gpu.Queue, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D, options: *const gpu.CopyTextureForBrowserOptions) callconv(.Inline) void);
    // assertDecl(Impl, "queueOnSubmittedWorkDone", fn (queue: gpu.Queue, signal_value: u64, callback: gpu.QueueWorkDoneCallback, userdata: *anyopaque) callconv(.Inline) void);
    // assertDecl(Impl, "queueSetLabel", fn (queue: gpu.Queue, label: [*:0]const u8) callconv(.Inline) void);
    // assertDecl(Impl, "queueSubmit", fn (queue: gpu.Queue, command_count: u32, commands: [*]gpu.CommandBuffer) callconv(.Inline) void);
    // assertDecl(Impl, "queueWriteBuffer", fn (queue: gpu.Queue, buffer: gpu.Buffer, buffer_offset: u64, data: *anyopaque, size: usize) callconv(.Inline) void);
    // assertDecl(Impl, "queueWriteTexture", fn (queue: gpu.Queue, data: *anyopaque, data_size: usize, data_layout: *const gpu.TextureDataLayout, write_size: *const gpu.Extent3D) callconv(.Inline) void);
    // assertDecl(Impl, "queueReference", fn (queue: gpu.Queue) callconv(.Inline) void);
    // assertDecl(Impl, "queueRelease", fn (queue: gpu.Queue) callconv(.Inline) void);
    // assertDecl(Impl, "renderBundleReference", fn (render_bundle: gpu.RenderBundle) callconv(.Inline) void);
    // assertDecl(Impl, "renderBundleRelease", fn (render_bundle: gpu.RenderBundle) callconv(.Inline) void);
    // assertDecl(Impl, "renderBundleEncoderDraw", fn (render_bundle_encoder: gpu.RenderBundleEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) callconv(.Inline) void);
    // assertDecl(Impl, "renderBundleEncoderDrawIndexed", fn (render_bundle_encoder: gpu.RenderBundleEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: u32, first_instance: u32) callconv(.Inline) void);
    // assertDecl(Impl, "renderBundleEncoderDrawIndexedIndirect", fn (render_bundle_encoder: gpu.RenderBundleEncoder, indirect_buffer: gpu.Buffer, indirect_offset: u64) callconv(.Inline) void);
    // assertDecl(Impl, "renderBundleEncoderDrawIndirect", fn (render_bundle_encoder: gpu.RenderBundleEncoder, indirect_buffer: gpu.Buffer, indirect_offset: u64) callconv(.Inline) void);
    // assertDecl(Impl, "renderBundleEncoderFinish", fn (render_bundle_encoder: gpu.RenderBundleEncoder, descriptor: ?*const gpu.RenderBundleDescriptor) callconv(.Inline) void);
    // assertDecl(Impl, "renderBundleEncoderInsertDebugMarker", fn (render_bundle_encoder: gpu.RenderBundleEncoder, marker_label: [*:0]const u8) callconv(.Inline) void);
    // assertDecl(Impl, "renderBundleEncoderPopDebugGroup", fn (render_bundle_encoder: gpu.RenderBundleEncoder) callconv(.Inline) void);
    // assertDecl(Impl, "renderBundleEncoderPushDebugGroup", fn (render_bundle_encoder: gpu.RenderBundleEncoder, group_label: [*:0]const u8) callconv(.Inline) void);
    // assertDecl(Impl, "renderBundleEncoderSetBindGroup", fn (render_bundle_encoder: gpu.RenderBundleEncoder, group_index: u32, group: gpu.BindGroup, dynamic_offset_count: u32, dynamic_offsets: [*]const u32) callconv(.Inline) void);
    // assertDecl(Impl, "renderBundleEncoderSetIndexBuffer", fn (render_bundle_encoder: gpu.RenderBundleEncoder, buffer: gpu.Buffer, format: gpu.IndexFormat, offset: u64, size: u64) callconv(.Inline) void);
    // assertDecl(Impl, "renderBundleEncoderSetLabel", fn (render_bundle_encoder: gpu.RenderBundleEncoder, label: [*:0]const u8) callconv(.Inline) void);
    // assertDecl(Impl, "renderBundleEncoderSetPipeline", fn (render_bundle_encoder: gpu.RenderBundleEncoder, pipeline: gpu.RenderPipeline) callconv(.Inline) void);
    // assertDecl(Impl, "renderBundleEncoderSetVertexBuffer", fn (render_bundle_encoder: gpu.RenderBundleEncoder, slot: u32, buffer: gpu.Buffer, offset: u64, size: u64) callconv(.Inline) void);
    // assertDecl(Impl, "renderBundleEncoderReference", fn (render_bundle_encoder: gpu.RenderBundleEncoder) callconv(.Inline) void);
    // assertDecl(Impl, "renderBundleEncoderRelease", fn (render_bundle_encoder: gpu.RenderBundleEncoder) callconv(.Inline) void);
    // assertDecl(Impl, "renderPassEncoderBeginOcclusionQuery", fn (render_pass_encoder: gpu.RenderPassEncoder, query_index: u32) callconv(.Inline) void);
    // assertDecl(Impl, "renderPassEncoderDraw", fn (render_pass_encoder: gpu.RenderPassEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) callconv(.Inline) void);
    // assertDecl(Impl, "renderPassEncoderDrawIndexed", fn (render_pass_encoder: gpu.RenderPassEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: u32, first_instance: u32) callconv(.Inline) void);
    // assertDecl(Impl, "renderPassEncoderDrawIndexedIndirect", fn (render_pass_encoder: gpu.RenderPassEncoder, indirect_buffer: gpu.Buffer, indirect_offset: u64) callconv(.Inline) void);
    // assertDecl(Impl, "renderPassEncoderDrawIndirect", fn (render_pass_encoder: gpu.RenderPassEncoder, indirect_buffer: gpu.Buffer, indirect_offset: u64) callconv(.Inline) void);
    // assertDecl(Impl, "renderPassEncoderEnd", fn (render_pass_encoder: gpu.RenderPassEncoder) callconv(.Inline) void);
    // assertDecl(Impl, "renderPassEncoderEndOcclusionQuery", fn (render_pass_encoder: gpu.RenderPassEncoder) callconv(.Inline) void);
    // assertDecl(Impl, "renderPassEncoderEndPass", fn (render_pass_encoder: gpu.RenderPassEncoder) callconv(.Inline) void);
    // assertDecl(Impl, "renderPassEncoderExecuteBundles", fn (render_pass_encoder: gpu.RenderPassEncoder, bundles_count: u32, bundles: [*]const gpu.RenderBundle) callconv(.Inline) void);
    // assertDecl(Impl, "renderPassEncoderInsertDebugMarker", fn (render_pass_encoder: gpu.RenderPassEncoder, marker_label: [*:0]const u8) callconv(.Inline) void);
    // assertDecl(Impl, "renderPassEncoderPopDebugGroup", fn (render_pass_encoder: gpu.RenderPassEncoder) callconv(.Inline) void);
    // assertDecl(Impl, "renderPassEncoderPushDebugGroup", fn (render_pass_encoder: gpu.RenderPassEncoder, group_label: [*:0]const u8) callconv(.Inline) void);
    // assertDecl(Impl, "renderPassEncoderSetBindGroup", fn (render_pass_encoder: gpu.RenderPassEncoder, group_index: u32, group: gpu.BindGroup, dynamic_offset_count: u32, dynamic_offsets: [*]const u32) callconv(.Inline) void);
    // assertDecl(Impl, "renderPassEncoderSetBlendConstant", fn (render_pass_encoder: gpu.RenderPassEncoder, color: *const gpu.Color) callconv(.Inline) void);
    // assertDecl(Impl, "renderPassEncoderSetIndexBuffer", fn (render_pass_encoder: gpu.RenderPassEncoder, buffer: gpu.Buffer, format: gpu.IndexFormat, offset: u64, size: u64) callconv(.Inline) void);
    // assertDecl(Impl, "renderPassEncoderSetLabel", fn (render_pass_encoder: gpu.RenderPassEncoder, label: [*:0]const u8) callconv(.Inline) void);
    // assertDecl(Impl, "renderPassEncoderSetPipeline", fn (render_pass_encoder: gpu.RenderPassEncoder, pipeline: gpu.RenderPipeline) callconv(.Inline) void);
    // assertDecl(Impl, "renderPassEncoderSetScissorRect", fn (render_pass_encoder: gpu.RenderPassEncoder, x: u32, y: u32, width: u32, height: u32) callconv(.Inline) void);
    // assertDecl(Impl, "renderPassEncoderSetStencilReference", fn (render_pass_encoder: gpu.RenderPassEncoder, reference: u32) callconv(.Inline) void);
    // assertDecl(Impl, "renderPassEncoderSetVertexBuffer", fn (render_pass_encoder: gpu.RenderPassEncoder, slot: u32, buffer: gpu.Buffer, offset: u64, size: u64) callconv(.Inline) void);
    // assertDecl(Impl, "renderPassEncoderSetViewport", fn (render_pass_encoder: gpu.RenderPassEncoder, x: f32, y: f32, width: f32, height: f32, min_depth: f32, max_depth: f32) callconv(.Inline) void);
    // assertDecl(Impl, "renderPassEncoderWriteTimestamp", fn (render_pass_encoder: gpu.RenderPassEncoder, query_set: gpu.QuerySet, query_index: u32) callconv(.Inline) void);
    // assertDecl(Impl, "renderPassEncoderReference", fn (render_pass_encoder: gpu.RenderPassEncoder) callconv(.Inline) void);
    // assertDecl(Impl, "renderPassEncoderRelease", fn (render_pass_encoder: gpu.RenderPassEncoder) callconv(.Inline) void);
    // assertDecl(Impl, "renderPipelineGetBindGroupLayout", fn (render_pipeline: gpu.RenderPipeline, group_index: u32) callconv(.Inline) gpu.BindGroupLayout);
    // assertDecl(Impl, "renderPipelineSetLabel", fn (render_pipeline: gpu.RenderPipeline, label: [*:0]const u8) callconv(.Inline) void);
    // assertDecl(Impl, "renderPipelineReference", fn (render_pipeline: gpu.RenderPipeline) callconv(.Inline) void);
    // assertDecl(Impl, "renderPipelineRelease", fn (render_pipeline: gpu.RenderPipeline) callconv(.Inline) void);
    // assertDecl(Impl, "samplerSetLabel", fn (sampler: gpu.Sampler, label: [*:0]const u8) callconv(.Inline) void);
    // assertDecl(Impl, "samplerReference", fn (sampler: gpu.Sampler) callconv(.Inline) void);
    // assertDecl(Impl, "samplerRelease", fn (sampler: gpu.Sampler) callconv(.Inline) void);
    // assertDecl(Impl, "shaderModuleGetCompilationInfo", fn (shader_module: gpu.ShaderModule, callback: gpu.CompilationInfoCallback, userdata: *anyopaque) callconv(.Inline) void);
    // assertDecl(Impl, "shaderModuleSetLabel", fn (shader_module: gpu.ShaderModule, label: [*:0]const u8) callconv(.Inline) void);
    // assertDecl(Impl, "shaderModuleReference", fn (shader_module: gpu.ShaderModule) callconv(.Inline) void);
    // assertDecl(Impl, "shaderModuleRelease", fn (shader_module: gpu.ShaderModule) callconv(.Inline) void);
    // assertDecl(Impl, "surfaceReference", fn (surface: gpu.Surface) callconv(.Inline) void);
    // assertDecl(Impl, "surfaceRelease", fn (surface: gpu.Surface) callconv(.Inline) void);
    // assertDecl(Impl, "swapChainConfigure", fn (swap_chain: gpu.SwapChain, format: gpu.TextureFormat, allowed_usage: gpu.TextureUsageFlags, width: u32, height: u32) callconv(.Inline) void);
    // assertDecl(Impl, "swapChainGetCurrentTextureView", fn (swap_chain: gpu.SwapChain) callconv(.Inline) gpu.TextureView);
    // assertDecl(Impl, "swapChainPresent", fn (swap_chain: gpu.SwapChain) callconv(.Inline) void);
    // assertDecl(Impl, "swapChainReference", fn (swap_chain: gpu.SwapChain) callconv(.Inline) void);
    // assertDecl(Impl, "swapChainRelease", fn (swap_chain: gpu.SwapChain) callconv(.Inline) void);
    // assertDecl(Impl, "wgpuTextureCreateView", fn (texture: gpu.Texture, descriptor: ?*const gpu.TextureViewDescriptor) callconv(.Inline) gpu.TextureView);
    // assertDecl(Impl, "textureDestroy", fn (texture: gpu.Texture) callconv(.Inline) void);
    // assertDecl(Impl, "textureGetDepthOrArrayLayers", fn (texture: gpu.Texture) callconv(.Inline) u32);
    // assertDecl(Impl, "textureGetDimension", fn (texture: gpu.Texture) callconv(.Inline) gpu.TextureDimension);
    // assertDecl(Impl, "textureGetFormat", fn (texture: gpu.Texture) callconv(.Inline) gpu.TextureFormat);
    // assertDecl(Impl, "textureGetHeight", fn (texture: gpu.Texture) callconv(.Inline) u32);
    // assertDecl(Impl, "textureGetMipLevelCount", fn (texture: gpu.Texture) callconv(.Inline) u32);
    // assertDecl(Impl, "textureGetSampleCount", fn (texture: gpu.Texture) callconv(.Inline) u32);
    // assertDecl(Impl, "textureGetUsage", fn (texture: gpu.Texture) callconv(.Inline) gpu.TextureUsageFlags);
    // assertDecl(Impl, "textureGetWidth", fn (texture: gpu.Texture) callconv(.Inline) u32);
    // assertDecl(Impl, "textureSetLabel", fn (texture: gpu.Texture, label: [*:0]const u8) callconv(.Inline) void);
    // assertDecl(Impl, "textureReference", fn (texture: gpu.Texture) callconv(.Inline) void);
    // assertDecl(Impl, "textureRelease", fn (texture: gpu.Texture) callconv(.Inline) void);
    // assertDecl(Impl, "textureViewSetLabel", fn (texture_view: gpu.TextureView, label: [*:0]const u8) callconv(.Inline) void);
    // assertDecl(Impl, "textureViewReference", fn (texture_view: gpu.TextureView) callconv(.Inline) void);
    // assertDecl(Impl, "textureViewRelease", fn (texture_view: gpu.TextureView) callconv(.Inline) void);
    return Impl;
}

fn assertDecl(comptime Impl: anytype, comptime name: []const u8, comptime T: type) void {
    if (!@hasDecl(Impl, name)) @compileError("gpu.Interface missing declaration: " ++ @typeName(T));
    const Decl = @TypeOf(@field(Impl, name));
    if (Decl != T) @compileError("gpu.Interface field '" ++ name ++ "'\n\texpected type: " ++ @typeName(T) ++ "\n\t   found type: " ++ @typeName(Decl));
}

/// Exports C ABI function declarations for the given gpu.Interface implementation.
pub fn Export(comptime Impl: type) type {
    _ = Interface(Impl); // verify implementation is a valid interface
    return struct {
        // WGPU_EXPORT WGPUInstance wgpuCreateInstance(WGPUInstanceDescriptor const * descriptor);
        export fn wgpuCreateInstance(descriptor: *const InstanceDescriptor) ?Instance {
            return Impl.createInstance(descriptor);
        }

        // WGPU_EXPORT WGPUProc wgpuGetProcAddress(WGPUDevice device, char const * procName);
        export fn wgpuGetProcAddress(device: gpu.Device, proc_name: [*:0]const u8) ?gpu.Proc {
            return Impl.getProcAddress(device, proc_name);
        }

        // WGPU_EXPORT WGPUDevice wgpuAdapterCreateDevice(WGPUAdapter adapter, WGPUDeviceDescriptor const * descriptor /* nullable */);
        export fn wgpuAdapterCreateDevice(adapter: gpu.Adapter, descriptor: ?*const gpu.DeviceDescriptor) ?gpu.Device {
            return Impl.adapterCreateDevice(adapter, descriptor);
        }

        // WGPU_EXPORT size_t wgpuAdapterEnumerateFeatures(WGPUAdapter adapter, WGPUFeatureName * features);
        export fn wgpuAdapterEnumerateFeatures(adapter: gpu.Adapter, features: ?[*]gpu.FeatureName) usize {
            return Impl.adapterEnumerateFeatures(adapter, features);
        }

        // WGPU_EXPORT bool wgpuAdapterGetLimits(WGPUAdapter adapter, WGPUSupportedLimits * limits);
        export fn wgpuAdapterGetLimits(adapter: gpu.Adapter, limits: *gpu.SupportedLimits) bool {
            return Impl.adapterGetLimits(adapter, limits);
        }

        // WGPU_EXPORT void wgpuAdapterGetProperties(WGPUAdapter adapter, WGPUAdapterProperties * properties);
        export fn wgpuAdapterGetProperties(adapter: gpu.Adapter, properties: *gpu.AdapterProperties) void {
            return Impl.adapterGetProperties(adapter, properties);
        }

        // WGPU_EXPORT bool wgpuAdapterHasFeature(WGPUAdapter adapter, WGPUFeatureName feature);
        export fn wgpuAdapterHasFeature(adapter: gpu.Adapter, feature: gpu.FeatureName) bool {
            return Impl.adapterHasFeature(adapter, feature);
        }

        // NOTE: descriptor is nullable, see https://bugs.chromium.org/p/dawn/issues/detail?id=1502
        // WGPU_EXPORT void wgpuAdapterRequestDevice(WGPUAdapter adapter, WGPUDeviceDescriptor const * descriptor, WGPURequestDeviceCallback callback, void * userdata);
        export fn wgpuAdapterRequestDevice(adapter: gpu.Adapter, descriptor: ?*const gpu.DeviceDescriptor, callback: gpu.RequestDeviceCallback, userdata: *anyopaque) void {
            Impl.adapterRequestDevice(adapter, descriptor, callback, userdata);
        }

        // WGPU_EXPORT void wgpuAdapterReference(WGPUAdapter adapter);
        export fn wgpuAdapterReference(adapter: gpu.Adapter) void {
            Impl.adapterReference(adapter);
        }

        // WGPU_EXPORT void wgpuAdapterRelease(WGPUAdapter adapter);
        export fn wgpuAdapterRelease(adapter: gpu.Adapter) void {
            Impl.adapterRelease(adapter);
        }

        // WGPU_EXPORT void wgpuBindGroupSetLabel(WGPUBindGroup bindGroup, char const * label);
        export fn wgpuBindGroupSetLabel(bind_group: gpu.BindGroup, label: [*:0]const u8) void {
            Impl.bindGroupSetLabel(bind_group, label);
        }

        // WGPU_EXPORT void wgpuBindGroupReference(WGPUBindGroup bindGroup);
        export fn wgpuBindGroupReference(bind_group: gpu.BindGroup) void {
            Impl.bindGroupReference(bind_group);
        }

        // WGPU_EXPORT void wgpuBindGroupRelease(WGPUBindGroup bindGroup);
        export fn wgpuBindGroupRelease(bind_group: gpu.BindGroup) void {
            Impl.bindGroupRelease(bind_group);
        }

        // WGPU_EXPORT void wgpuBindGroupLayoutSetLabel(WGPUBindGroupLayout bindGroupLayout, char const * label);
        export fn wgpuBindGroupLayoutSetLabel(bind_group_layout: gpu.BindGroupLayout, label: [*:0]const u8) void {
            Impl.bindGroupLayoutSetLabel(bind_group_layout, label);
        }

        // WGPU_EXPORT void wgpuBindGroupLayoutReference(WGPUBindGroupLayout bindGroupLayout);
        export fn wgpuBindGroupLayoutReference(bind_group_layout: gpu.BindGroupLayout) void {
            Impl.bindGroupLayoutReference(bind_group_layout);
        }

        // WGPU_EXPORT void wgpuBindGroupLayoutRelease(WGPUBindGroupLayout bindGroupLayout);
        export fn wgpuBindGroupLayoutRelease(bind_group_layout: gpu.BindGroupLayout) void {
            Impl.bindGroupLayoutRelease(bind_group_layout);
        }

        // WGPU_EXPORT void wgpuBufferDestroy(WGPUBuffer buffer);
        export fn wgpuBufferDestroy(buffer: gpu.Buffer) void {
            Impl.bufferDestroy(buffer);
        }

        // WGPU_EXPORT void const * wgpuBufferGetConstMappedRange(WGPUBuffer buffer, size_t offset, size_t size);
        export fn wgpuBufferGetConstMappedRange(buffer: gpu.Buffer, offset: usize, size: usize) *const anyopaque {
            return Impl.bufferGetConstMappedRange(buffer, offset, size);
        }

        // WGPU_EXPORT void * wgpuBufferGetMappedRange(WGPUBuffer buffer, size_t offset, size_t size);
        export fn wgpuBufferGetMappedRange(buffer: gpu.Buffer, offset: usize, size: usize) *anyopaque {
            return Impl.bufferGetMappedRange(buffer, offset, size);
        }

        // WGPU_EXPORT uint64_t wgpuBufferGetSize(WGPUBuffer buffer);
        export fn wgpuBufferGetSize(buffer: gpu.Buffer) u64 {
            return Impl.bufferGetSize(buffer);
        }

        // WGPU_EXPORT WGPUBufferUsage wgpuBufferGetUsage(WGPUBuffer buffer);
        export fn wgpuBufferGetUsage(buffer: gpu.Buffer) gpu.BufferUsage {
            return Impl.bufferGetUsage(buffer);
        }

        // TODO: Zig cannot currently export a packed struct gpu.MapModeFlags, so we use a u32 for
        // now.
        // WGPU_EXPORT void wgpuBufferMapAsync(WGPUBuffer buffer, WGPUMapModeFlags mode, size_t offset, size_t size, WGPUBufferMapCallback callback, void * userdata);
        export fn wgpuBufferMapAsync(buffer: gpu.Buffer, mode: u32, offset: usize, size: usize, callback: gpu.BufferMapCallback, userdata: *anyopaque) u64 {
            return Impl.bufferMapAsync(buffer, @bitCast(gpu.MapMode, mode), offset, size, callback, userdata);
        }

        // WGPU_EXPORT void wgpuBufferSetLabel(WGPUBuffer buffer, char const * label);
        export fn wgpuBufferSetLabel(buffer: gpu.Buffer, label: [*:0]const u8) void {
            Impl.bufferSetLabel(buffer, label);
        }

        // WGPU_EXPORT void wgpuBufferUnmap(WGPUBuffer buffer);
        export fn wgpuBufferUnmap(buffer: gpu.Buffer) void {
            Impl.bufferUnmap(buffer);
        }

        // WGPU_EXPORT void wgpuBufferReference(WGPUBuffer buffer);
        export fn wgpuBufferReference(buffer: gpu.Buffer) void {
            Impl.bufferReference(buffer);
        }

        // WGPU_EXPORT void wgpuBufferRelease(WGPUBuffer buffer);
        export fn wgpuBufferRelease(buffer: gpu.Buffer) void {
            Impl.bufferRelease(buffer);
        }

        // WGPU_EXPORT void wgpuCommandBufferSetLabel(WGPUCommandBuffer commandBuffer, char const * label);
        export fn wgpuCommandBufferSetLabel(command_buffer: gpu.CommandBuffer, label: [*:0]const u8) void {
            Impl.commandBufferSetLabel(command_buffer, label);
        }

        // WGPU_EXPORT void wgpuCommandBufferReference(WGPUCommandBuffer commandBuffer);
        export fn wgpuCommandBufferReference(command_buffer: gpu.CommandBuffer) void {
            Impl.commandBufferReference(command_buffer);
        }

        // WGPU_EXPORT void wgpuCommandBufferRelease(WGPUCommandBuffer commandBuffer);
        export fn wgpuCommandBufferRelease(command_buffer: gpu.CommandBuffer) void {
            Impl.commandBufferRelease(command_buffer);
        }

        // WGPU_EXPORT WGPUComputePassEncoder wgpuCommandEncoderBeginComputePass(WGPUCommandEncoder commandEncoder, WGPUComputePassDescriptor const * descriptor /* nullable */);
        export fn wgpuCommandEncoderBeginComputePass(command_encoder: gpu.CommandEncoder, descriptor: ?*const gpu.ComputePassDescriptor) gpu.ComputePassEncoder {
            return Impl.commandEncoderBeginComputePass(command_encoder, descriptor);
        }

        // WGPU_EXPORT WGPURenderPassEncoder wgpuCommandEncoderBeginRenderPass(WGPUCommandEncoder commandEncoder, WGPURenderPassDescriptor const * descriptor);
        export fn wgpuCommandEncoderBeginRenderPass(command_encoder: gpu.CommandEncoder, descriptor: *const gpu.RenderPassDescriptor) gpu.RenderPassEncoder {
            return Impl.commandEncoderBeginRenderPass(command_encoder, descriptor);
        }

        // WGPU_EXPORT void wgpuCommandEncoderClearBuffer(WGPUCommandEncoder commandEncoder, WGPUBuffer buffer, uint64_t offset, uint64_t size);
        export fn wgpuCommandEncoderClearBuffer(command_encoder: gpu.CommandEncoder, buffer: gpu.Buffer, offset: u64, size: u64) void {
            Impl.commandEncoderClearBuffer(command_encoder, buffer, offset, size);
        }

        // WGPU_EXPORT void wgpuCommandEncoderCopyBufferToBuffer(WGPUCommandEncoder commandEncoder, WGPUBuffer source, uint64_t sourceOffset, WGPUBuffer destination, uint64_t destinationOffset, uint64_t size);
        export fn wgpuCommandEncoderCopyBufferToBuffer(command_encoder: gpu.CommandEncoder, source: gpu.Buffer, source_offset: u64, destination: gpu.Buffer, destination_offset: u64, size: u64) void {
            Impl.commandEncoderCopyBufferToBuffer(command_encoder, source, source_offset, destination, destination_offset, size);
        }

        // WGPU_EXPORT void wgpuCommandEncoderCopyBufferToTexture(WGPUCommandEncoder commandEncoder, WGPUImageCopyBuffer const * source, WGPUImageCopyTexture const * destination, WGPUExtent3D const * copySize);
        export fn wgpuCommandEncoderCopyBufferToTexture(command_encoder: gpu.CommandEncoder, source: *const gpu.ImageCopyBuffer, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) void {
            Impl.commandEncoderCopyBufferToTexture(command_encoder, source, destination, copy_size);
        }

        // WGPU_EXPORT void wgpuCommandEncoderCopyTextureToBuffer(WGPUCommandEncoder commandEncoder, WGPUImageCopyTexture const * source, WGPUImageCopyBuffer const * destination, WGPUExtent3D const * copySize);
        export fn wgpuCommandEncoderCopyTextureToBuffer(command_encoder: gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyBuffer, copy_size: *const gpu.Extent3D) void {
            Impl.commandEncoderCopyTextureToBuffer(command_encoder, source, destination, copy_size);
        }

        // WGPU_EXPORT void wgpuCommandEncoderCopyTextureToTexture(WGPUCommandEncoder commandEncoder, WGPUImageCopyTexture const * source, WGPUImageCopyTexture const * destination, WGPUExtent3D const * copySize);
        export fn wgpuCommandEncoderCopyTextureToTexture(command_encoder: gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) void {
            Impl.commandEncoderCopyTextureToTexture(command_encoder, source, destination, copy_size);
        }

        // WGPU_EXPORT void wgpuCommandEncoderCopyTextureToTextureInternal(WGPUCommandEncoder commandEncoder, WGPUImageCopyTexture const * source, WGPUImageCopyTexture const * destination, WGPUExtent3D const * copySize);
        export fn wgpuCommandEncoderCopyTextureToTextureInternal(command_encoder: gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) void {
            Impl.commandEncoderCopyTextureToTextureInternal(command_encoder, source, destination, copy_size);
        }

        // WGPU_EXPORT WGPUCommandBuffer wgpuCommandEncoderFinish(WGPUCommandEncoder commandEncoder, WGPUCommandBufferDescriptor const * descriptor /* nullable */);
        export fn wgpuCommandEncoderFinish(command_encoder: gpu.CommandEncoder, descriptor: ?*const gpu.CommandBufferDescriptor) gpu.CommandBuffer {
            return Impl.commandEncoderFinish(command_encoder, descriptor);
        }

        // WGPU_EXPORT void wgpuCommandEncoderInjectValidationError(WGPUCommandEncoder commandEncoder, char const * message);
        export fn wgpuCommandEncoderInjectValidationError(command_encoder: gpu.CommandEncoder, message: [*:0]const u8) void {
            Impl.commandEncoderInjectValidationError(command_encoder, message);
        }

        // WGPU_EXPORT void wgpuCommandEncoderInsertDebugMarker(WGPUCommandEncoder commandEncoder, char const * markerLabel);
        export fn wgpuCommandEncoderInsertDebugMarker(command_encoder: gpu.CommandEncoder, marker_label: [*:0]const u8) void {
            Impl.commandEncoderInsertDebugMarker(command_encoder, marker_label);
        }

        // WGPU_EXPORT void wgpuCommandEncoderPopDebugGroup(WGPUCommandEncoder commandEncoder);
        export fn wgpuCommandEncoderPopDebugGroup(command_encoder: gpu.CommandEncoder) void {
            Impl.commandEncoderPopDebugGroup(command_encoder);
        }

        // WGPU_EXPORT void wgpuCommandEncoderPushDebugGroup(WGPUCommandEncoder commandEncoder, char const * groupLabel);
        export fn wgpuCommandEncoderPushDebugGroup(command_encoder: gpu.CommandEncoder, group_label: [*:0]const u8) void {
            Impl.commandEncoderPushDebugGroup(command_encoder, group_label);
        }

        // WGPU_EXPORT void wgpuCommandEncoderResolveQuerySet(WGPUCommandEncoder commandEncoder, WGPUQuerySet querySet, uint32_t firstQuery, uint32_t queryCount, WGPUBuffer destination, uint64_t destinationOffset);
        export fn wgpuCommandEncoderResolveQuerySet(command_encoder: gpu.CommandEncoder, query_set: gpu.QuerySet, first_query: u32, query_count: u32, destination: gpu.Buffer, destination_offset: u64) void {
            Impl.commandEncoderResolveQuerySet(command_encoder, query_set, first_query, query_count, destination, destination_offset);
        }

        // WGPU_EXPORT void wgpuCommandEncoderSetLabel(WGPUCommandEncoder commandEncoder, char const * label);
        export fn wgpuCommandEncoderSetLabel(command_encoder: gpu.CommandEncoder, label: [*:0]const u8) void {
            Impl.commandEncoderSetLabel(command_encoder, label);
        }

        // WGPU_EXPORT void wgpuCommandEncoderWriteBuffer(WGPUCommandEncoder commandEncoder, WGPUBuffer buffer, uint64_t bufferOffset, uint8_t const * data, uint64_t size);
        export fn wgpuCommandEncoderWriteBuffer(command_encoder: gpu.CommandEncoder, buffer: gpu.Buffer, buffer_offset: u64, data: [*]const u8, size: u64) void {
            Impl.commandEncoderWriteBuffer(command_encoder, buffer, buffer_offset, data, size);
        }

        // WGPU_EXPORT void wgpuCommandEncoderWriteTimestamp(WGPUCommandEncoder commandEncoder, WGPUQuerySet querySet, uint32_t queryIndex);
        export fn wgpuCommandEncoderWriteTimestamp(command_encoder: gpu.CommandEncoder, query_set: gpu.QuerySet, query_index: u32) void {
            Impl.commandEncoderWriteTimestamp(command_encoder, query_set, query_index);
        }

        // WGPU_EXPORT void wgpuCommandEncoderReference(WGPUCommandEncoder commandEncoder);
        export fn wgpuCommandEncoderReference(command_encoder: gpu.CommandEncoder) void {
            Impl.commandEncoderReference(command_encoder);
        }

        // WGPU_EXPORT void wgpuCommandEncoderRelease(WGPUCommandEncoder commandEncoder);
        export fn wgpuCommandEncoderRelease(command_encoder: gpu.CommandEncoder) void {
            Impl.commandEncoderRelease(command_encoder);
        }

        // WGPU_EXPORT void wgpuComputePassEncoderDispatch(WGPUComputePassEncoder computePassEncoder, uint32_t workgroupCountX, uint32_t workgroupCountY, uint32_t workgroupCountZ);
        export fn wgpuComputePassEncoderDispatch(compute_pass_encoder: gpu.ComputePassEncoder, workgroup_count_x: u32, workgroup_count_y: u32, workgroup_count_z: u32) void {
            Impl.computePassEncoderDispatch(compute_pass_encoder, workgroup_count_x, workgroup_count_y, workgroup_count_z);
        }

        // WGPU_EXPORT void wgpuComputePassEncoderDispatchIndirect(WGPUComputePassEncoder computePassEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
        export fn wgpuComputePassEncoderDispatchIndirect(compute_pass_encoder: gpu.ComputePassEncoder, indirect_buffer: gpu.Buffer, indirect_offset: u64) void {
            Impl.computePassEncoderDispatchIndirect(compute_pass_encoder, indirect_buffer, indirect_offset);
        }

        // WGPU_EXPORT void wgpuComputePassEncoderDispatchWorkgroups(WGPUComputePassEncoder computePassEncoder, uint32_t workgroupCountX, uint32_t workgroupCountY, uint32_t workgroupCountZ);
        export fn wgpuComputePassEncoderDispatchWorkgroups(compute_pass_encoder: gpu.ComputePassEncoder, workgroup_count_x: u32, workgroup_count_y: u32, workgroup_count_z: u32) void {
            Impl.computePassEncoderDispatchWorkgroups(compute_pass_encoder, workgroup_count_x, workgroup_count_y, workgroup_count_z);
        }

        // WGPU_EXPORT void wgpuComputePassEncoderDispatchWorkgroupsIndirect(WGPUComputePassEncoder computePassEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
        export fn wgpuComputePassEncoderDispatchWorkgroupsIndirect(compute_pass_encoder: gpu.ComputePassEncoder, indirect_buffer: gpu.Buffer, indirect_offset: u64) void {
            Impl.computePassEncoderDispatchWorkgroupsIndirect(compute_pass_encoder, indirect_buffer, indirect_offset);
        }

        // WGPU_EXPORT void wgpuComputePassEncoderEnd(WGPUComputePassEncoder computePassEncoder);
        export fn wgpuComputePassEncoderEnd(compute_pass_encoder: gpu.ComputePassEncoder) void {
            Impl.computePassEncoderEnd(compute_pass_encoder);
        }

        // WGPU_EXPORT void wgpuComputePassEncoderEndPass(WGPUComputePassEncoder computePassEncoder);
        export fn wgpuComputePassEncoderEndPass(compute_pass_encoder: gpu.ComputePassEncoder) void {
            Impl.computePassEncoderEndPass(compute_pass_encoder);
        }

        // WGPU_EXPORT void wgpuComputePassEncoderInsertDebugMarker(WGPUComputePassEncoder computePassEncoder, char const * markerLabel);
        export fn wgpuComputePassEncoderInsertDebugMarker(compute_pass_encoder: gpu.ComputePassEncoder, marker_label: [*:0]const u8) void {
            Impl.computePassEncoderInsertDebugMarker(compute_pass_encoder, marker_label);
        }

        // WGPU_EXPORT void wgpuComputePassEncoderPopDebugGroup(WGPUComputePassEncoder computePassEncoder);
        export fn wgpuComputePassEncoderPopDebugGroup(compute_pass_encoder: gpu.ComputePassEncoder) void {
            Impl.computePassEncoderPopDebugGroup(compute_pass_encoder);
        }

        // WGPU_EXPORT void wgpuComputePassEncoderPushDebugGroup(WGPUComputePassEncoder computePassEncoder, char const * groupLabel);
        export fn wgpuComputePassEncoderPushDebugGroup(compute_pass_encoder: gpu.ComputePassEncoder, group_label: [*:0]const u8) void {
            Impl.computePassEncoderPushDebugGroup(compute_pass_encoder, group_label);
        }

        // WGPU_EXPORT void wgpuComputePassEncoderSetBindGroup(WGPUComputePassEncoder computePassEncoder, uint32_t groupIndex, WGPUBindGroup group, uint32_t dynamicOffsetCount, uint32_t const * dynamicOffsets);
        export fn wgpuComputePassEncoderSetBindGroup(compute_pass_encoder: gpu.ComputePassEncoder, group_index: u32, group: gpu.BindGroup, dynamic_offset_count: u32, dynamic_offsets: [*]const u32) void {
            Impl.computePassEncoderSetBindGroup(compute_pass_encoder, group_index, group, dynamic_offset_count, dynamic_offsets);
        }

        // WGPU_EXPORT void wgpuComputePassEncoderSetLabel(WGPUComputePassEncoder computePassEncoder, char const * label);
        export fn wgpuComputePassEncoderSetLabel(compute_pass_encoder: gpu.ComputePassEncoder, label: [*:0]const u8) void {
            Impl.computePassEncoderSetLabel(compute_pass_encoder, label);
        }

        // WGPU_EXPORT void wgpuComputePassEncoderSetPipeline(WGPUComputePassEncoder computePassEncoder, WGPUComputePipeline pipeline);
        export fn wgpuComputePassEncoderSetPipeline(compute_pass_encoder: gpu.ComputePassEncoder, pipeline: gpu.ComputePipeline) void {
            Impl.computePassEncoderSetPipeline(compute_pass_encoder, pipeline);
        }

        // WGPU_EXPORT void wgpuComputePassEncoderWriteTimestamp(WGPUComputePassEncoder computePassEncoder, WGPUQuerySet querySet, uint32_t queryIndex);
        export fn wgpuComputePassEncoderWriteTimestamp(compute_pass_encoder: gpu.ComputePassEncoder, pipeline: gpu.ComputePipeline) void {
            Impl.computePassEncoderWriteTimestamp(compute_pass_encoder, pipeline);
        }

        // WGPU_EXPORT void wgpuComputePassEncoderReference(WGPUComputePassEncoder computePassEncoder);
        export fn wgpuComputePassEncoderReference(compute_pass_encoder: gpu.ComputePassEncoder) void {
            Impl.computePassEncoderReference(compute_pass_encoder);
        }

        // WGPU_EXPORT void wgpuComputePassEncoderRelease(WGPUComputePassEncoder computePassEncoder);
        export fn wgpuComputePassEncoderRelease(compute_pass_encoder: gpu.ComputePassEncoder) void {
            Impl.computePassEncoderRelease(compute_pass_encoder);
        }

        // WGPU_EXPORT WGPUBindGroupLayout wgpuComputePipelineGetBindGroupLayout(WGPUComputePipeline computePipeline, uint32_t groupIndex);
        export fn wgpuComputePipelineGetBindGroupLayout(compute_pipeline: gpu.ComputePipeline, group_index: u32) gpu.BindGroupLayout {
            return Impl.computePipelineGetBindGroupLayout(compute_pipeline, group_index);
        }

        // WGPU_EXPORT void wgpuComputePipelineSetLabel(WGPUComputePipeline computePipeline, char const * label);
        export fn wgpuComputePipelineSetLabel(compute_pipeline: gpu.ComputePipeline, label: [*:0]const u8) void {
            Impl.computePipelineSetLabel(compute_pipeline, label);
        }

        // WGPU_EXPORT void wgpuComputePipelineReference(WGPUComputePipeline computePipeline);
        export fn wgpuComputePipelineReference(compute_pipeline: gpu.ComputePipeline) void {
            Impl.computePipelineReference(compute_pipeline);
        }

        // WGPU_EXPORT void wgpuComputePipelineRelease(WGPUComputePipeline computePipeline);
        export fn wgpuComputePipelineRelease(compute_pipeline: gpu.ComputePipeline) void {
            Impl.computePipelineRelease(compute_pipeline);
        }

        // WGPU_EXPORT WGPUBindGroup wgpuDeviceCreateBindGroup(WGPUDevice device, WGPUBindGroupDescriptor const * descriptor);
        export fn wgpuDeviceCreateBindGroup(device: gpu.Device, descriptor: *const gpu.BindGroupDescriptor) gpu.BindGroup {
            return Impl.deviceCreateBindGroup(device, descriptor);
        }

        // WGPU_EXPORT WGPUBindGroupLayout wgpuDeviceCreateBindGroupLayout(WGPUDevice device, WGPUBindGroupLayoutDescriptor const * descriptor);
        export fn wgpuDeviceCreateBindGroupLayout(device: gpu.Device, descriptor: *const gpu.BindGroupLayoutDescriptor) gpu.BindGroupLayout {
            return Impl.deviceCreateBindGroupLayout(device, descriptor);
        }

        // WGPU_EXPORT WGPUBuffer wgpuDeviceCreateBuffer(WGPUDevice device, WGPUBufferDescriptor const * descriptor);
        export fn wgpuDeviceCreateBuffer(device: gpu.Device, descriptor: *const gpu.BufferDescriptor) gpu.Buffer {
            return Impl.deviceCreateBuffer(device, descriptor);
        }

        // WGPU_EXPORT WGPUCommandEncoder wgpuDeviceCreateCommandEncoder(WGPUDevice device, WGPUCommandEncoderDescriptor const * descriptor /* nullable */);
        export fn wgpuDeviceCreateCommandEncoder(device: gpu.Device, descriptor: ?*const gpu.CommandEncoderDescriptor) gpu.CommandEncoder {
            return Impl.deviceCreateCommandEncoder(device, descriptor);
        }

        // WGPU_EXPORT WGPUComputePipeline wgpuDeviceCreateComputePipeline(WGPUDevice device, WGPUComputePipelineDescriptor const * descriptor);
        export fn wgpuDeviceCreateComputePipeline(device: gpu.Device, descriptor: *const gpu.ComputePipelineDescriptor) gpu.ComputePipeline {
            return Impl.deviceCreateComputePipeline(device, descriptor);
        }

        // WGPU_EXPORT void wgpuDeviceCreateComputePipelineAsync(WGPUDevice device, WGPUComputePipelineDescriptor const * descriptor, WGPUCreateComputePipelineAsyncCallback callback, void * userdata);
        export fn wgpuDeviceCreateComputePipelineAsync(device: gpu.Device, descriptor: *const gpu.ComputePipelineDescriptor, callback: gpu.CreateComputePipelineAsyncCallback, userdata: *anyopaque) void {
            Impl.deviceCreateComputePipelineAsync(device, descriptor, callback, userdata);
        }

        // WGPU_EXPORT WGPUBuffer wgpuDeviceCreateErrorBuffer(WGPUDevice device);
        export fn wgpuDeviceCreateErrorBuffer(device: gpu.Device) gpu.Buffer {
            return Impl.deviceCreateErrorBuffer(device);
        }

        // WGPU_EXPORT WGPUExternalTexture wgpuDeviceCreateErrorExternalTexture(WGPUDevice device);
        export fn wgpuDeviceCreateErrorExternalTexture(device: gpu.Device) gpu.ExternalTexture {
            return Impl.deviceCreateErrorExternalTexture(device);
        }

        // WGPU_EXPORT WGPUExternalTexture wgpuDeviceCreateExternalTexture(WGPUDevice device, WGPUExternalTextureDescriptor const * externalTextureDescriptor);
        export fn wgpuDeviceCreateExternalTexture(device: gpu.Device, external_texture_descriptor: *const gpu.ExternalTextureDescriptor) gpu.ExternalTexture {
            return Impl.deviceCreateExternalTexture(device, external_texture_descriptor);
        }

        // WGPU_EXPORT WGPUPipelineLayout wgpuDeviceCreatePipelineLayout(WGPUDevice device, WGPUPipelineLayoutDescriptor const * descriptor);
        export fn wgpuDeviceCreatePipelineLayout(device: gpu.Device, pipeline_layout_descriptor: *const gpu.PipelineLayoutDescriptor) gpu.PipelineLayout {
            return Impl.deviceCreatePipelineLayout(device, pipeline_layout_descriptor);
        }

        // WGPU_EXPORT WGPUQuerySet wgpuDeviceCreateQuerySet(WGPUDevice device, WGPUQuerySetDescriptor const * descriptor);
        export fn wgpuDeviceCreateQuerySet(device: gpu.Device, descriptor: *const gpu.QuerySetDescriptor) gpu.QuerySet {
            return Impl.deviceCreateQuerySet(device, descriptor);
        }

        // WGPU_EXPORT WGPURenderBundleEncoder wgpuDeviceCreateRenderBundleEncoder(WGPUDevice device, WGPURenderBundleEncoderDescriptor const * descriptor);
        export fn wgpuDeviceCreateRenderBundleEncoder(device: gpu.Device, descriptor: *const gpu.RenderBundleEncoderDescriptor) gpu.RenderBundleEncoder {
            return Impl.deviceCreateRenderBundleEncoder(device, descriptor);
        }

        // WGPU_EXPORT WGPURenderPipeline wgpuDeviceCreateRenderPipeline(WGPUDevice device, WGPURenderPipelineDescriptor const * descriptor);
        export fn wgpuDeviceCreateRenderPipeline(device: gpu.Device, descriptor: *const gpu.RenderPipelineDescriptor) gpu.RenderPipeline {
            return Impl.deviceCreateRenderPipeline(device, descriptor);
        }

        // WGPU_EXPORT void wgpuDeviceCreateRenderPipelineAsync(WGPUDevice device, WGPURenderPipelineDescriptor const * descriptor, WGPUCreateRenderPipelineAsyncCallback callback, void * userdata);
        export fn wgpuDeviceCreateRenderPipelineAsync(device: gpu.Device, descriptor: *const gpu.RenderPipelineDescriptor, callback: gpu.CreateRenderPipelineAsyncCallback, userdata: *anyopaque) void {
            Impl.deviceCreateRenderPipelineAsync(device, descriptor, callback, userdata);
        }

        // WGPU_EXPORT WGPUSampler wgpuDeviceCreateSampler(WGPUDevice device, WGPUSamplerDescriptor const * descriptor /* nullable */);
        export fn wgpuDeviceCreateSampler(device: gpu.Device, descriptor: ?*const gpu.SamplerDescriptor) gpu.Sampler {
            return Impl.deviceCreateSampler(device, descriptor);
        }

        // WGPU_EXPORT WGPUShaderModule wgpuDeviceCreateShaderModule(WGPUDevice device, WGPUShaderModuleDescriptor const * descriptor);
        export fn wgpuDeviceCreateShaderModule(device: gpu.Device, descriptor: *const gpu.ShaderModuleDescriptor) gpu.ShaderModule {
            return Impl.deviceCreateShaderModule(device, descriptor);
        }

        // WGPU_EXPORT WGPUSwapChain wgpuDeviceCreateSwapChain(WGPUDevice device, WGPUSurface surface /* nullable */, WGPUSwapChainDescriptor const * descriptor);
        export fn wgpuDeviceCreateSwapChain(device: gpu.Device, surface: ?gpu.Surface, descriptor: *const gpu.SwapChainDescriptor) gpu.SwapChain {
            return Impl.deviceCreateSwapChain(device, surface, descriptor);
        }

        // WGPU_EXPORT WGPUTexture wgpuDeviceCreateTexture(WGPUDevice device, WGPUTextureDescriptor const * descriptor);
        export fn wgpuDeviceCreateTexture(device: gpu.Device, descriptor: *const gpu.TextureDescriptor) gpu.Texture {
            return Impl.deviceCreateTexture(device, descriptor);
        }

        // WGPU_EXPORT void wgpuDeviceDestroy(WGPUDevice device);
        export fn wgpuDeviceDestroy(device: gpu.Device) void {
            Impl.deviceDestroy(device);
        }

        // WGPU_EXPORT size_t wgpuDeviceEnumerateFeatures(WGPUDevice device, WGPUFeatureName * features);
        export fn wgpuDeviceEnumerateFeatures(device: gpu.Device, features: [*]gpu.FeatureName) usize {
            return Impl.deviceEnumerateFeatures(device, features);
        }

        // WGPU_EXPORT bool wgpuDeviceGetLimits(WGPUDevice device, WGPUSupportedLimits * limits);
        export fn wgpuDeviceGetLimits(device: gpu.Device, limits: *gpu.SupportedLimits) bool {
            return Impl.deviceGetLimits(device, limits);
        }

        // WGPU_EXPORT WGPUQueue wgpuDeviceGetQueue(WGPUDevice device);
        export fn wgpuDeviceGetQueue(device: gpu.Device) gpu.Queue {
            return Impl.deviceGetQueue(device);
        }

        // WGPU_EXPORT bool wgpuDeviceHasFeature(WGPUDevice device, WGPUFeatureName feature);
        export fn wgpuDeviceHasFeature(device: gpu.Device, feature: gpu.FeatureName) bool {
            return Impl.deviceHasFeature(device, feature);
        }

        // WGPU_EXPORT void wgpuDeviceInjectError(WGPUDevice device, WGPUErrorType type, char const * message);
        export fn wgpuDeviceInjectError(device: gpu.Device, typ: gpu.ErrorType, message: [*:0]const u8) void {
            Impl.deviceInjectError(device, typ, message);
        }

        // WGPU_EXPORT void wgpuDeviceLoseForTesting(WGPUDevice device);
        export fn wgpuDeviceLoseForTesting(device: gpu.Device) void {
            Impl.deviceLoseForTesting(device);
        }

        // WGPU_EXPORT bool wgpuDevicePopErrorScope(WGPUDevice device, WGPUErrorCallback callback, void * userdata);
        export fn wgpuDevicePopErrorScope(device: gpu.Device, callback: gpu.ErrorCallback, userdata: *anyopaque) bool {
            return Impl.devicePopErrorScope(device, callback, userdata);
        }

        // WGPU_EXPORT void wgpuDevicePushErrorScope(WGPUDevice device, WGPUErrorFilter filter);
        export fn wgpuDevicePushErrorScope(device: gpu.Device, filter: gpu.ErrorFilter) void {
            Impl.devicePushErrorScope(device, filter);
        }

        // WGPU_EXPORT void wgpuDeviceSetDeviceLostCallback(WGPUDevice device, WGPUDeviceLostCallback callback, void * userdata);
        export fn wgpuDeviceSetDeviceLostCallback(device: gpu.Device, callback: gpu.DeviceLostCallback, userdata: *anyopaque) void {
            Impl.deviceSetDeviceLostCallback(device, callback, userdata);
        }

        // WGPU_EXPORT void wgpuDeviceSetLabel(WGPUDevice device, char const * label);
        export fn wgpuDeviceSetLabel(device: gpu.Device, label: [*:0]const u8) void {
            Impl.deviceSetLabel(device, label);
        }

        // WGPU_EXPORT void wgpuDeviceSetLoggingCallback(WGPUDevice device, WGPULoggingCallback callback, void * userdata);
        export fn wgpuDeviceSetLoggingCallback(device: gpu.Device, callback: gpu.LoggingCallback, userdata: *anyopaque) void {
            Impl.deviceSetLoggingCallback(device, callback, userdata);
        }

        // WGPU_EXPORT void wgpuDeviceSetUncapturedErrorCallback(WGPUDevice device, WGPUErrorCallback callback, void * userdata);
        export fn wgpuDeviceSetUncapturedErrorCallback(device: gpu.Device, callback: gpu.ErrorCallback, userdata: *anyopaque) void {
            Impl.deviceSetUncapturedErrorCallback(device, callback, userdata);
        }

        // WGPU_EXPORT void wgpuDeviceTick(WGPUDevice device);
        export fn wgpuDeviceTick(device: gpu.Device) void {
            Impl.deviceTick(device);
        }

        // WGPU_EXPORT void wgpuDeviceReference(WGPUDevice device);
        export fn wgpuDeviceReference(device: gpu.Device) void {
            Impl.deviceReference(device);
        }

        // WGPU_EXPORT void wgpuDeviceRelease(WGPUDevice device);
        export fn wgpuDeviceRelease(device: gpu.Device) void {
            Impl.deviceRelease(device);
        }

        // WGPU_EXPORT void wgpuExternalTextureDestroy(WGPUExternalTexture externalTexture);
        export fn wgpuExternalTextureDestroy(external_texture: gpu.ExternalTexture) void {
            Impl.externalTextureDestroy(external_texture);
        }

        // WGPU_EXPORT void wgpuExternalTextureSetLabel(WGPUExternalTexture externalTexture, char const * label);
        export fn wgpuExternalTextureSetLabel(external_texture: gpu.ExternalTexture, label: [*:0]const u8) void {
            Impl.externalTextureSetLabel(external_texture, label);
        }

        // WGPU_EXPORT void wgpuExternalTextureReference(WGPUExternalTexture externalTexture);
        export fn wgpuExternalTextureReference(external_texture: gpu.ExternalTexture) void {
            Impl.externalTextureReference(external_texture);
        }

        // WGPU_EXPORT void wgpuExternalTextureRelease(WGPUExternalTexture externalTexture);
        export fn wgpuExternalTextureRelease(external_texture: gpu.ExternalTexture) void {
            Impl.externalTextureRelease(external_texture);
        }

        // WGPU_EXPORT WGPUSurface wgpuInstanceCreateSurface(WGPUInstance instance, WGPUSurfaceDescriptor const * descriptor);
        export fn wgpuInstanceCreateSurface(instance: gpu.Instance, descriptor: *const gpu.SurfaceDescriptor) gpu.Surface {
            return Impl.instanceCreateSurface(instance, descriptor);
        }

        // WGPU_EXPORT void wgpuInstanceRequestAdapter(WGPUInstance instance, WGPURequestAdapterOptions const * options, WGPURequestAdapterCallback callback, void * userdata);
        export fn wgpuInstanceRequestAdapter(instance: gpu.Instance, options: *const gpu.RequestAdapterOptions, callback: gpu.RequestAdapterCallback, userdata: *anyopaque) void {
            Impl.instanceRequestAdapter(instance, options, callback, userdata);
        }

        // WGPU_EXPORT void wgpuInstanceReference(WGPUInstance instance);
        export fn wgpuInstanceReference(instance: gpu.Instance) void {
            Impl.instanceReference(instance);
        }

        // WGPU_EXPORT void wgpuInstanceRelease(WGPUInstance instance);
        export fn wgpuInstanceRelease(instance: gpu.Instance) void {
            Impl.instanceRelease(instance);
        }

        // WGPU_EXPORT void wgpuPipelineLayoutSetLabel(WGPUPipelineLayout pipelineLayout, char const * label);
        export fn wgpuPipelineLayoutSetLabel(pipeline_layout: gpu.PipelineLayout, label: [*:0]const u8) void {
            Impl.pipelineLayoutSetLabel(pipeline_layout, label);
        }

        // WGPU_EXPORT void wgpuPipelineLayoutReference(WGPUPipelineLayout pipelineLayout);
        export fn wgpuPipelineLayoutReference(pipeline_layout: gpu.PipelineLayout) void {
            Impl.pipelineLayoutReference(pipeline_layout);
        }

        // WGPU_EXPORT void wgpuPipelineLayoutRelease(WGPUPipelineLayout pipelineLayout);
        export fn wgpuPipelineLayoutRelease(pipeline_layout: gpu.PipelineLayout) void {
            Impl.pipelineLayoutRelease(pipeline_layout);
        }

        // WGPU_EXPORT void wgpuQuerySetDestroy(WGPUQuerySet querySet);
        export fn wgpuQuerySetDestroy(query_set: gpu.QuerySet) void {
            Impl.querySetDestroy(query_set);
        }

        // WGPU_EXPORT uint32_t wgpuQuerySetGetCount(WGPUQuerySet querySet);
        export fn wgpuQuerySetGetCount(query_set: gpu.QuerySet) u32 {
            return Impl.querySetGetCount(query_set);
        }

        // WGPU_EXPORT WGPUQueryType wgpuQuerySetGetType(WGPUQuerySet querySet);
        export fn wgpuQuerySetGetType(query_set: gpu.QuerySet) gpu.QueryType {
            return Impl.querySetGetType(query_set);
        }

        // WGPU_EXPORT void wgpuQuerySetSetLabel(WGPUQuerySet querySet, char const * label);
        export fn wgpuQuerySetSetLabel(query_set: gpu.QuerySet, label: [*:0]const u8) void {
            Impl.querySetSetLabel(query_set, label);
        }

        // WGPU_EXPORT void wgpuQuerySetReference(WGPUQuerySet querySet);
        export fn wgpuQuerySetReference(query_set: gpu.QuerySet) void {
            Impl.querySetReference(query_set);
        }

        // WGPU_EXPORT void wgpuQuerySetRelease(WGPUQuerySet querySet);
        export fn wgpuQuerySetRelease(query_set: gpu.QuerySet) void {
            Impl.querySetRelease(query_set);
        }

        // WGPU_EXPORT void wgpuQueueCopyTextureForBrowser(WGPUQueue queue, WGPUImageCopyTexture const * source, WGPUImageCopyTexture const * destination, WGPUExtent3D const * copySize, WGPUCopyTextureForBrowserOptions const * options);
        export fn wgpuQueueCopyTextureForBrowser(queue: gpu.Queue, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D, options: *const gpu.CopyTextureForBrowserOptions) void {
            Impl.queueCopyTextureForBrowser(queue, source, destination, copy_size, options);
        }

        // WGPU_EXPORT void wgpuQueueOnSubmittedWorkDone(WGPUQueue queue, uint64_t signalValue, WGPUQueueWorkDoneCallback callback, void * userdata);
        export fn wgpuQueueOnSubmittedWorkDone(queue: gpu.Queue, signal_value: u64, callback: gpu.QueueWorkDoneCallback, userdata: *anyopaque) void {
            Impl.queueOnSubmittedWorkDone(queue, signal_value, callback, userdata);
        }

        // WGPU_EXPORT void wgpuQueueSetLabel(WGPUQueue queue, char const * label);
        export fn wgpuQueueSetLabel(queue: gpu.Queue, label: [*:0]const u8) void {
            Impl.queueSetLabel(queue, label);
        }

        // WGPU_EXPORT void wgpuQueueSubmit(WGPUQueue queue, uint32_t commandCount, WGPUCommandBuffer const * commands);
        export fn wgpuQueueSubmit(queue: gpu.Queue, command_count: u32, commands: [*]gpu.CommandBuffer) void {
            Impl.queueSubmit(queue, command_count, commands);
        }

        // WGPU_EXPORT void wgpuQueueWriteBuffer(WGPUQueue queue, WGPUBuffer buffer, uint64_t bufferOffset, void const * data, size_t size);
        export fn wgpuQueueWriteBuffer(queue: gpu.Queue, buffer: gpu.Buffer, buffer_offset: u64, data: *anyopaque, size: usize) void {
            Impl.queueWriteBuffer(queue, buffer, buffer_offset, data, size);
        }

        // WGPU_EXPORT void wgpuQueueWriteTexture(WGPUQueue queue, WGPUImageCopyTexture const * destination, void const * data, size_t dataSize, WGPUTextureDataLayout const * dataLayout, WGPUExtent3D const * writeSize);
        export fn wgpuQueueWriteTexture(queue: gpu.Queue, data: *anyopaque, data_size: usize, data_layout: *const gpu.TextureDataLayout, write_size: *const gpu.Extent3D) void {
            Impl.queueWriteTexture(queue, data, data_size, data_layout, write_size);
        }

        // WGPU_EXPORT void wgpuQueueReference(WGPUQueue queue);
        export fn wgpuQueueReference(queue: gpu.Queue) void {
            Impl.queueReference(queue);
        }

        // WGPU_EXPORT void wgpuQueueRelease(WGPUQueue queue);
        export fn wgpuQueueRelease(queue: gpu.Queue) void {
            Impl.queueRelease(queue);
        }

        // WGPU_EXPORT void wgpuRenderBundleReference(WGPURenderBundle renderBundle);
        export fn wgpuRenderBundleReference(render_bundle: gpu.RenderBundle) void {
            Impl.renderBundleReference(render_bundle);
        }

        // WGPU_EXPORT void wgpuRenderBundleRelease(WGPURenderBundle renderBundle);
        export fn wgpuRenderBundleRelease(render_bundle: gpu.RenderBundle) void {
            Impl.renderBundleRelease(render_bundle);
        }

        // WGPU_EXPORT void wgpuRenderBundleEncoderDraw(WGPURenderBundleEncoder renderBundleEncoder, uint32_t vertexCount, uint32_t instanceCount, uint32_t firstVertex, uint32_t firstInstance);
        export fn wgpuRenderBundleEncoderDraw(render_bundle_encoder: gpu.RenderBundleEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {
            Impl.renderBundleEncoderDraw(render_bundle_encoder, vertex_count, instance_count, first_vertex, first_instance);
        }

        // WGPU_EXPORT void wgpuRenderBundleEncoderDrawIndexed(WGPURenderBundleEncoder renderBundleEncoder, uint32_t indexCount, uint32_t instanceCount, uint32_t firstIndex, int32_t baseVertex, uint32_t firstInstance);
        export fn wgpuRenderBundleEncoderDrawIndexed(render_bundle_encoder: gpu.RenderBundleEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: u32, first_instance: u32) void {
            Impl.renderBundleEncoderDrawIndexed(render_bundle_encoder, index_count, instance_count, first_index, base_vertex, first_instance);
        }

        // WGPU_EXPORT void wgpuRenderBundleEncoderDrawIndexedIndirect(WGPURenderBundleEncoder renderBundleEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
        export fn wgpuRenderBundleEncoderDrawIndexedIndirect(render_bundle_encoder: gpu.RenderBundleEncoder, indirect_buffer: gpu.Buffer, indirect_offset: u64) void {
            Impl.renderBundleEncoderDrawIndexedIndirect(render_bundle_encoder, indirect_buffer, indirect_offset);
        }

        // WGPU_EXPORT void wgpuRenderBundleEncoderDrawIndirect(WGPURenderBundleEncoder renderBundleEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
        export fn wgpuRenderBundleEncoderDrawIndirect(render_bundle_encoder: gpu.RenderBundleEncoder, indirect_buffer: gpu.Buffer, indirect_offset: u64) void {
            Impl.renderBundleEncoderDrawIndirect(render_bundle_encoder, indirect_buffer, indirect_offset);
        }

        // WGPU_EXPORT WGPURenderBundle wgpuRenderBundleEncoderFinish(WGPURenderBundleEncoder renderBundleEncoder, WGPURenderBundleDescriptor const * descriptor /* nullable */);
        export fn wgpuRenderBundleEncoderFinish(render_bundle_encoder: gpu.RenderBundleEncoder, descriptor: ?*const gpu.RenderBundleDescriptor) void {
            Impl.renderBundleEncoderFinish(render_bundle_encoder, descriptor);
        }

        // WGPU_EXPORT void wgpuRenderBundleEncoderInsertDebugMarker(WGPURenderBundleEncoder renderBundleEncoder, char const * markerLabel);
        export fn wgpuRenderBundleEncoderInsertDebugMarker(render_bundle_encoder: gpu.RenderBundleEncoder, marker_label: [*:0]const u8) void {
            Impl.renderBundleEncoderInsertDebugMarker(render_bundle_encoder, marker_label);
        }

        // WGPU_EXPORT void wgpuRenderBundleEncoderPopDebugGroup(WGPURenderBundleEncoder renderBundleEncoder);
        export fn wgpuRenderBundleEncoderPopDebugGroup(render_bundle_encoder: gpu.RenderBundleEncoder) void {
            Impl.renderBundleEncoderPopDebugGroup(render_bundle_encoder);
        }

        // WGPU_EXPORT void wgpuRenderBundleEncoderPushDebugGroup(WGPURenderBundleEncoder renderBundleEncoder, char const * groupLabel);
        export fn wgpuRenderBundleEncoderPushDebugGroup(render_bundle_encoder: gpu.RenderBundleEncoder, group_label: [*:0]const u8) void {
            Impl.renderBundleEncoderPushDebugGroup(render_bundle_encoder, group_label);
        }

        // WGPU_EXPORT void wgpuRenderBundleEncoderSetBindGroup(WGPURenderBundleEncoder renderBundleEncoder, uint32_t groupIndex, WGPUBindGroup group, uint32_t dynamicOffsetCount, uint32_t const * dynamicOffsets);
        export fn wgpuRenderBundleEncoderSetBindGroup(render_bundle_encoder: gpu.RenderBundleEncoder, group_index: u32, group: gpu.BindGroup, dynamic_offset_count: u32, dynamic_offsets: [*]const u32) void {
            Impl.renderBundleEncoderSetBindGroup(render_bundle_encoder, group_index, group, dynamic_offset_count, dynamic_offsets);
        }

        // WGPU_EXPORT void wgpuRenderBundleEncoderSetIndexBuffer(WGPURenderBundleEncoder renderBundleEncoder, WGPUBuffer buffer, WGPUIndexFormat format, uint64_t offset, uint64_t size);
        export fn wgpuRenderBundleEncoderSetIndexBuffer(render_bundle_encoder: gpu.RenderBundleEncoder, buffer: gpu.Buffer, format: gpu.IndexFormat, offset: u64, size: u64) void {
            Impl.renderBundleEncoderSetIndexBuffer(render_bundle_encoder, buffer, format, offset, size);
        }

        // WGPU_EXPORT void wgpuRenderBundleEncoderSetLabel(WGPURenderBundleEncoder renderBundleEncoder, char const * label);
        export fn wgpuRenderBundleEncoderSetLabel(render_bundle_encoder: gpu.RenderBundleEncoder, label: [*:0]const u8) void {
            Impl.renderBundleEncoderSetLabel(render_bundle_encoder, label);
        }

        // WGPU_EXPORT void wgpuRenderBundleEncoderSetPipeline(WGPURenderBundleEncoder renderBundleEncoder, WGPURenderPipeline pipeline);
        export fn wgpuRenderBundleEncoderSetPipeline(render_bundle_encoder: gpu.RenderBundleEncoder, pipeline: gpu.RenderPipeline) void {
            Impl.renderBundleEncoderSetPipeline(render_bundle_encoder, pipeline);
        }

        // WGPU_EXPORT void wgpuRenderBundleEncoderSetVertexBuffer(WGPURenderBundleEncoder renderBundleEncoder, uint32_t slot, WGPUBuffer buffer, uint64_t offset, uint64_t size);
        export fn wgpuRenderBundleEncoderSetVertexBuffer(render_bundle_encoder: gpu.RenderBundleEncoder, slot: u32, buffer: gpu.Buffer, offset: u64, size: u64) void {
            Impl.renderBundleEncoderSetVertexBuffer(render_bundle_encoder, slot, buffer, offset, size);
        }

        // WGPU_EXPORT void wgpuRenderBundleEncoderReference(WGPURenderBundleEncoder renderBundleEncoder);
        export fn wgpuRenderBundleEncoderReference(render_bundle_encoder: gpu.RenderBundleEncoder) void {
            Impl.renderBundleEncoderReference(render_bundle_encoder);
        }

        // WGPU_EXPORT void wgpuRenderBundleEncoderRelease(WGPURenderBundleEncoder renderBundleEncoder);
        export fn wgpuRenderBundleEncoderRelease(render_bundle_encoder: gpu.RenderBundleEncoder) void {
            Impl.renderBundleEncoderRelease(render_bundle_encoder);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderBeginOcclusionQuery(WGPURenderPassEncoder renderPassEncoder, uint32_t queryIndex);
        export fn wgpuRenderPassEncoderBeginOcclusionQuery(render_pass_encoder: gpu.RenderPassEncoder, query_index: u32) void {
            Impl.renderPassEncoderBeginOcclusionQuery(render_pass_encoder, query_index);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderDraw(WGPURenderPassEncoder renderPassEncoder, uint32_t vertexCount, uint32_t instanceCount, uint32_t firstVertex, uint32_t firstInstance);
        export fn wgpuRenderPassEncoderDraw(render_pass_encoder: gpu.RenderPassEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {
            Impl.renderPassEncoderDraw(render_pass_encoder, vertex_count, instance_count, first_vertex, first_instance);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderDrawIndexed(WGPURenderPassEncoder renderPassEncoder, uint32_t indexCount, uint32_t instanceCount, uint32_t firstIndex, int32_t baseVertex, uint32_t firstInstance);
        export fn wgpuRenderPassEncoderDrawIndexed(render_pass_encoder: gpu.RenderPassEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: u32, first_instance: u32) void {
            Impl.renderPassEncoderDrawIndexed(render_pass_encoder, index_count, instance_count, first_index, base_vertex, first_instance);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderDrawIndexedIndirect(WGPURenderPassEncoder renderPassEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
        export fn wgpuRenderPassEncoderDrawIndexedIndirect(render_pass_encoder: gpu.RenderPassEncoder, indirect_buffer: gpu.Buffer, indirect_offset: u64) void {
            Impl.renderPassEncoderDrawIndexedIndirect(render_pass_encoder, indirect_buffer, indirect_offset);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderDrawIndirect(WGPURenderPassEncoder renderPassEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
        export fn wgpuRenderPassEncoderDrawIndirect(render_pass_encoder: gpu.RenderPassEncoder, indirect_buffer: gpu.Buffer, indirect_offset: u64) void {
            Impl.renderPassEncoderDrawIndirect(render_pass_encoder, indirect_buffer, indirect_offset);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderEnd(WGPURenderPassEncoder renderPassEncoder);
        export fn wgpuRenderPassEncoderEnd(render_pass_encoder: gpu.RenderPassEncoder) void {
            Impl.renderPassEncoderEnd(render_pass_encoder);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderEndOcclusionQuery(WGPURenderPassEncoder renderPassEncoder);
        export fn wgpuRenderPassEncoderEndOcclusionQuery(render_pass_encoder: gpu.RenderPassEncoder) void {
            Impl.renderPassEncoderEndOcclusionQuery(render_pass_encoder);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderEndPass(WGPURenderPassEncoder renderPassEncoder);
        export fn wgpuRenderPassEncoderEndPass(render_pass_encoder: gpu.RenderPassEncoder) void {
            Impl.renderPassEncoderEndPass(render_pass_encoder);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderExecuteBundles(WGPURenderPassEncoder renderPassEncoder, uint32_t bundlesCount, WGPURenderBundle const * bundles);
        export fn wgpuRenderPassEncoderExecuteBundles(render_pass_encoder: gpu.RenderPassEncoder, bundles_count: u32, bundles: [*]const gpu.RenderBundle) void {
            Impl.renderPassEncoderExecuteBundles(render_pass_encoder, bundles_count, bundles);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderInsertDebugMarker(WGPURenderPassEncoder renderPassEncoder, char const * markerLabel);
        export fn wgpuRenderPassEncoderInsertDebugMarker(render_pass_encoder: gpu.RenderPassEncoder, marker_label: [*:0]const u8) void {
            Impl.renderPassEncoderInsertDebugMarker(render_pass_encoder, marker_label);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderPopDebugGroup(WGPURenderPassEncoder renderPassEncoder);
        export fn wgpuRenderPassEncoderPopDebugGroup(render_pass_encoder: gpu.RenderPassEncoder) void {
            Impl.renderPassEncoderPopDebugGroup(render_pass_encoder);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderPushDebugGroup(WGPURenderPassEncoder renderPassEncoder, char const * groupLabel);
        export fn wgpuRenderPassEncoderPushDebugGroup(render_pass_encoder: gpu.RenderPassEncoder, group_label: [*:0]const u8) void {
            Impl.renderPassEncoderPushDebugGroup(render_pass_encoder, group_label);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderSetBindGroup(WGPURenderPassEncoder renderPassEncoder, uint32_t groupIndex, WGPUBindGroup group, uint32_t dynamicOffsetCount, uint32_t const * dynamicOffsets);
        export fn wgpuRenderPassEncoderSetBindGroup(render_pass_encoder: gpu.RenderPassEncoder, group_index: u32, group: gpu.BindGroup, dynamic_offset_count: u32, dynamic_offsets: [*]const u32) void {
            Impl.renderPassEncoderSetBindGroup(render_pass_encoder, group_index, group, dynamic_offset_count, dynamic_offsets);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderSetBlendConstant(WGPURenderPassEncoder renderPassEncoder, WGPUColor const * color);
        export fn wgpuRenderPassEncoderSetBlendConstant(render_pass_encoder: gpu.RenderPassEncoder, color: *const gpu.Color) void {
            Impl.renderPassEncoderSetBlendConstant(render_pass_encoder, color);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderSetIndexBuffer(WGPURenderPassEncoder renderPassEncoder, WGPUBuffer buffer, WGPUIndexFormat format, uint64_t offset, uint64_t size);
        export fn wgpuRenderPassEncoderSetIndexBuffer(render_pass_encoder: gpu.RenderPassEncoder, buffer: gpu.Buffer, format: gpu.IndexFormat, offset: u64, size: u64) void {
            Impl.renderPassEncoderSetIndexBuffer(render_pass_encoder, buffer, format, offset, size);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderSetLabel(WGPURenderPassEncoder renderPassEncoder, char const * label);
        export fn wgpuRenderPassEncoderSetLabel(render_pass_encoder: gpu.RenderPassEncoder, label: [*:0]const u8) void {
            Impl.renderPassEncoderSetLabel(render_pass_encoder, label);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderSetPipeline(WGPURenderPassEncoder renderPassEncoder, WGPURenderPipeline pipeline);
        export fn wgpuRenderPassEncoderSetPipeline(render_pass_encoder: gpu.RenderPassEncoder, pipeline: gpu.RenderPipeline) void {
            Impl.renderPassEncoderSetPipeline(render_pass_encoder, pipeline);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderSetScissorRect(WGPURenderPassEncoder renderPassEncoder, uint32_t x, uint32_t y, uint32_t width, uint32_t height);
        export fn wgpuRenderPassEncoderSetScissorRect(render_pass_encoder: gpu.RenderPassEncoder, x: u32, y: u32, width: u32, height: u32) void {
            Impl.renderPassEncoderSetScissorRect(render_pass_encoder, x, y, width, height);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderSetStencilReference(WGPURenderPassEncoder renderPassEncoder, uint32_t reference);
        export fn wgpuRenderPassEncoderSetStencilReference(render_pass_encoder: gpu.RenderPassEncoder, reference: u32) void {
            Impl.renderPassEncoderSetStencilReference(render_pass_encoder, reference);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderSetVertexBuffer(WGPURenderPassEncoder renderPassEncoder, uint32_t slot, WGPUBuffer buffer, uint64_t offset, uint64_t size);
        export fn wgpuRenderPassEncoderSetVertexBuffer(render_pass_encoder: gpu.RenderPassEncoder, slot: u32, buffer: gpu.Buffer, offset: u64, size: u64) void {
            Impl.renderPassEncoderSetVertexBuffer(render_pass_encoder, slot, buffer, offset, size);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderSetViewport(WGPURenderPassEncoder renderPassEncoder, float x, float y, float width, float height, float minDepth, float maxDepth);
        export fn wgpuRenderPassEncoderSetViewport(render_pass_encoder: gpu.RenderPassEncoder, x: f32, y: f32, width: f32, height: f32, min_depth: f32, max_depth: f32) void {
            Impl.renderPassEncoderSetViewport(render_pass_encoder, x, y, width, height, min_depth, max_depth);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderWriteTimestamp(WGPURenderPassEncoder renderPassEncoder, WGPUQuerySet querySet, uint32_t queryIndex);
        export fn wgpuRenderPassEncoderWriteTimestamp(render_pass_encoder: gpu.RenderPassEncoder, query_set: gpu.QuerySet, query_index: u32) void {
            Impl.renderPassEncoderWriteTimestamp(render_pass_encoder, query_set, query_index);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderReference(WGPURenderPassEncoder renderPassEncoder);
        export fn wgpuRenderPassEncoderReference(render_pass_encoder: gpu.RenderPassEncoder) void {
            Impl.renderPassEncoderReference(render_pass_encoder);
        }

        // WGPU_EXPORT void wgpuRenderPassEncoderRelease(WGPURenderPassEncoder renderPassEncoder);
        export fn wgpuRenderPassEncoderRelease(render_pass_encoder: gpu.RenderPassEncoder) void {
            Impl.renderPassEncoderRelease(render_pass_encoder);
        }

        // WGPU_EXPORT WGPUBindGroupLayout wgpuRenderPipelineGetBindGroupLayout(WGPURenderPipeline renderPipeline, uint32_t groupIndex);
        export fn wgpuRenderPipelineGetBindGroupLayout(render_pipeline: gpu.RenderPipeline, group_index: u32) gpu.BindGroupLayout {
            return Impl.renderPipelineGetBindGroupLayout(render_pipeline, group_index);
        }

        // WGPU_EXPORT void wgpuRenderPipelineSetLabel(WGPURenderPipeline renderPipeline, char const * label);
        export fn wgpuRenderPipelineSetLabel(render_pipeline: gpu.RenderPipeline, label: [*:0]const u8) void {
            Impl.renderPipelineSetLabel(render_pipeline, label);
        }

        // WGPU_EXPORT void wgpuRenderPipelineReference(WGPURenderPipeline renderPipeline);
        export fn wgpuRenderPipelineReference(render_pipeline: gpu.RenderPipeline) void {
            Impl.renderPipelineReference(render_pipeline);
        }

        // WGPU_EXPORT void wgpuRenderPipelineRelease(WGPURenderPipeline renderPipeline);
        export fn wgpuRenderPipelineRelease(render_pipeline: gpu.RenderPipeline) void {
            Impl.renderPipelineRelease(render_pipeline);
        }

        // WGPU_EXPORT void wgpuSamplerSetLabel(WGPUSampler sampler, char const * label);
        export fn wgpuSamplerSetLabel(sampler: gpu.Sampler, label: [*:0]const u8) void {
            Impl.samplerSetLabel(sampler, label);
        }

        // WGPU_EXPORT void wgpuSamplerReference(WGPUSampler sampler);
        export fn wgpuSamplerReference(sampler: gpu.Sampler) void {
            Impl.samplerReference(sampler);
        }

        // WGPU_EXPORT void wgpuSamplerRelease(WGPUSampler sampler);
        export fn wgpuSamplerRelease(sampler: gpu.Sampler) void {
            Impl.samplerRelease(sampler);
        }

        // WGPU_EXPORT void wgpuShaderModuleGetCompilationInfo(WGPUShaderModule shaderModule, WGPUCompilationInfoCallback callback, void * userdata);
        export fn wgpuShaderModuleGetCompilationInfo(shader_module: gpu.ShaderModule, callback: gpu.CompilationInfoCallback, userdata: *anyopaque) void {
            Impl.shaderModuleGetCompilationInfo(shader_module, callback, userdata);
        }

        // WGPU_EXPORT void wgpuShaderModuleSetLabel(WGPUShaderModule shaderModule, char const * label);
        export fn wgpuShaderModuleSetLabel(shader_module: gpu.ShaderModule, label: [*:0]const u8) void {
            Impl.shaderModuleSetLabel(shader_module, label);
        }

        // WGPU_EXPORT void wgpuShaderModuleReference(WGPUShaderModule shaderModule);
        export fn wgpuShaderModuleReference(shader_module: gpu.ShaderModule) void {
            Impl.shaderModuleReference(shader_module);
        }

        // WGPU_EXPORT void wgpuShaderModuleRelease(WGPUShaderModule shaderModule);
        export fn wgpuShaderModuleRelease(shader_module: gpu.ShaderModule) void {
            Impl.shaderModuleRelease(shader_module);
        }

        // WGPU_EXPORT void wgpuSurfaceReference(WGPUSurface surface);
        export fn wgpuSurfaceReference(surface: gpu.Surface) void {
            Impl.surfaceReference(surface);
        }

        // WGPU_EXPORT void wgpuSurfaceRelease(WGPUSurface surface);
        export fn wgpuSurfaceRelease(surface: gpu.Surface) void {
            Impl.surfaceRelease(surface);
        }

        // TODO: Zig cannot currently export a packed struct gpu.TextureUsageFlags, so we use a u32
        // for now.
        // WGPU_EXPORT void wgpuSwapChainConfigure(WGPUSwapChain swapChain, WGPUTextureFormat format, WGPUTextureUsageFlags allowedUsage, uint32_t width, uint32_t height);
        export fn wgpuSwapChainConfigure(swap_chain: gpu.SwapChain, format: gpu.TextureFormat, allowed_usage: u32, width: u32, height: u32) void {
            Impl.swapChainConfigure(swap_chain, format, @bitCast(gpu.TextureUsageFlags, allowed_usage), width, height);
        }

        // WGPU_EXPORT WGPUTextureView wgpuSwapChainGetCurrentTextureView(WGPUSwapChain swapChain);
        export fn wgpuSwapChainGetCurrentTextureView(swap_chain: gpu.SwapChain) gpu.TextureView {
            return Impl.swapChainGetCurrentTextureView(swap_chain);
        }

        // WGPU_EXPORT void wgpuSwapChainPresent(WGPUSwapChain swapChain);
        export fn wgpuSwapChainPresent(swap_chain: gpu.SwapChain) void {
            Impl.swapChainPresent(swap_chain);
        }

        // WGPU_EXPORT void wgpuSwapChainReference(WGPUSwapChain swapChain);
        export fn wgpuSwapChainReference(swap_chain: gpu.SwapChain) void {
            Impl.swapChainReference(swap_chain);
        }

        // WGPU_EXPORT void wgpuSwapChainRelease(WGPUSwapChain swapChain);
        export fn wgpuSwapChainRelease(swap_chain: gpu.SwapChain) void {
            Impl.swapChainRelease(swap_chain);
        }

        // WGPU_EXPORT WGPUTextureView wgpuTextureCreateView(WGPUTexture texture, WGPUTextureViewDescriptor const * descriptor /* nullable */);
        export fn wgpuTextureCreateView(texture: gpu.Texture, descriptor: ?*const gpu.TextureViewDescriptor) gpu.TextureView {
            return Impl.textureCreateView(texture, descriptor);
        }

        // WGPU_EXPORT void wgpuTextureDestroy(WGPUTexture texture);
        export fn wgpuTextureDestroy(texture: gpu.Texture) void {
            Impl.textureDestroy(texture);
        }

        // WGPU_EXPORT uint32_t wgpuTextureGetDepthOrArrayLayers(WGPUTexture texture);
        export fn wgpuTextureGetDepthOrArrayLayers(texture: gpu.Texture) u32 {
            return Impl.textureGetDepthOrArrayLayers(texture);
        }

        // WGPU_EXPORT WGPUTextureDimension wgpuTextureGetDimension(WGPUTexture texture);
        export fn wgpuTextureGetDimension(texture: gpu.Texture) gpu.TextureDimension {
            return Impl.textureGetDimension(texture);
        }

        // WGPU_EXPORT WGPUTextureFormat wgpuTextureGetFormat(WGPUTexture texture);
        export fn wgpuTextureGetFormat(texture: gpu.Texture) gpu.TextureFormat {
            return Impl.textureGetFormat(texture);
        }

        // WGPU_EXPORT uint32_t wgpuTextureGetHeight(WGPUTexture texture);
        export fn wgpuTextureGetHeight(texture: gpu.Texture) u32 {
            return Impl.textureGetHeight(texture);
        }

        // WGPU_EXPORT uint32_t wgpuTextureGetMipLevelCount(WGPUTexture texture);
        export fn wgpuTextureGetMipLevelCount(texture: gpu.Texture) u32 {
            return Impl.textureGetMipLevelCount(texture);
        }

        // WGPU_EXPORT uint32_t wgpuTextureGetSampleCount(WGPUTexture texture);
        export fn wgpuTextureGetSampleCount(texture: gpu.Texture) u32 {
            return Impl.textureGetSampleCount(texture);
        }

        // WGPU_EXPORT WGPUTextureUsage wgpuTextureGetUsage(WGPUTexture texture);
        export fn wgpuTextureGetUsage(texture: gpu.Texture) gpu.TextureUsageFlags {
            return Impl.textureGetUsage(texture);
        }

        // WGPU_EXPORT uint32_t wgpuTextureGetWidth(WGPUTexture texture);
        export fn wgpuTextureGetWidth(texture: gpu.Texture) u32 {
            return Impl.textureGetWidth(texture);
        }

        // WGPU_EXPORT void wgpuTextureSetLabel(WGPUTexture texture, char const * label);
        export fn wgpuTextureSetLabel(texture: gpu.Texture, label: [*:0]const u8) void {
            Impl.textureSetLabel(texture, label);
        }

        // WGPU_EXPORT void wgpuTextureReference(WGPUTexture texture);
        export fn wgpuTextureReference(texture: gpu.Texture) void {
            Impl.textureReference(texture);
        }

        // WGPU_EXPORT void wgpuTextureRelease(WGPUTexture texture);
        export fn wgpuTextureRelease(texture: gpu.Texture) void {
            Impl.textureRelease(texture);
        }

        // WGPU_EXPORT void wgpuTextureViewSetLabel(WGPUTextureView textureView, char const * label);
        export fn wgpuTextureViewSetLabel(texture_view: gpu.TextureView, label: [*:0]const u8) void {
            Impl.textureViewSetLabel(texture_view, label);
        }

        // WGPU_EXPORT void wgpuTextureViewReference(WGPUTextureView textureView);
        export fn wgpuTextureViewReference(texture_view: gpu.TextureView) void {
            Impl.textureViewReference(texture_view);
        }

        // WGPU_EXPORT void wgpuTextureViewRelease(WGPUTextureView textureView);
        export fn wgpuTextureViewRelease(texture_view: gpu.TextureView) void {
            Impl.textureViewRelease(texture_view);
        }
    };
}

/// A stub gpu.Interface in which every function is implemented by `unreachable;`
pub const StubInterface = Interface(struct {
    pub inline fn createInstance(descriptor: *const InstanceDescriptor) ?Instance {
        _ = descriptor;
        unreachable;
    }

    pub inline fn getProcAddress(device: gpu.Device, proc_name: [*:0]const u8) ?gpu.Proc {
        _ = device;
        _ = proc_name;
        unreachable;
    }

    pub inline fn adapterCreateDevice(adapter: gpu.Adapter, descriptor: ?*const gpu.DeviceDescriptor) ?gpu.Device {
        _ = adapter;
        _ = descriptor;
        unreachable;
    }

    pub inline fn adapterEnumerateFeatures(adapter: gpu.Adapter, features: ?[*]gpu.FeatureName) usize {
        _ = adapter;
        _ = features;
        unreachable;
    }

    pub inline fn adapterGetLimits(adapter: gpu.Adapter, limits: *gpu.SupportedLimits) bool {
        _ = adapter;
        _ = limits;
        unreachable;
    }

    pub inline fn adapterGetProperties(adapter: gpu.Adapter, properties: *gpu.AdapterProperties) void {
        _ = adapter;
        _ = properties;
        unreachable;
    }

    pub inline fn adapterHasFeature(adapter: gpu.Adapter, feature: gpu.FeatureName) bool {
        _ = adapter;
        _ = feature;
        unreachable;
    }

    pub inline fn adapterRequestDevice(adapter: gpu.Adapter, descriptor: ?*const gpu.DeviceDescriptor, callback: gpu.RequestDeviceCallback, userdata: *anyopaque) void {
        _ = adapter;
        _ = descriptor;
        _ = callback;
        _ = userdata;
        unreachable;
    }

    pub inline fn adapterReference(adapter: gpu.Adapter) void {
        _ = adapter;
        unreachable;
    }

    pub inline fn adapterRelease(adapter: gpu.Adapter) void {
        _ = adapter;
        unreachable;
    }

    pub inline fn bindGroupSetLabel(bind_group: gpu.BindGroup, label: [*:0]const u8) void {
        _ = bind_group;
        _ = label;
        unreachable;
    }

    pub inline fn bindGroupReference(bind_group: gpu.BindGroup) void {
        _ = bind_group;
        unreachable;
    }

    pub inline fn bindGroupRelease(bind_group: gpu.BindGroup) void {
        _ = bind_group;
        unreachable;
    }

    pub inline fn bindGroupLayoutSetLabel(bind_group_layout: gpu.BindGroupLayout, label: [*:0]const u8) void {
        _ = bind_group_layout;
        _ = label;
        unreachable;
    }

    pub inline fn bindGroupLayoutReference(bind_group_layout: gpu.BindGroupLayout) void {
        _ = bind_group_layout;
        unreachable;
    }

    pub inline fn bindGroupLayoutRelease(bind_group_layout: gpu.BindGroupLayout) void {
        _ = bind_group_layout;
        unreachable;
    }

    pub inline fn bufferDestroy(buffer: gpu.Buffer) void {
        _ = buffer;
        unreachable;
    }

    // TODO: should return nullable; bug in Dawn docstrings!
    pub inline fn bufferGetConstMappedRange(buffer: gpu.Buffer, offset: usize, size: usize) *const anyopaque {
        _ = buffer;
        _ = offset;
        _ = size;
        unreachable;
    }

    // TODO: should return nullable; bug in Dawn docstrings!
    pub inline fn bufferGetMappedRange(buffer: gpu.Buffer, offset: usize, size: usize) *anyopaque {
        _ = buffer;
        _ = offset;
        _ = size;
        unreachable;
    }

    pub inline fn bufferGetSize(buffer: gpu.Buffer) u64 {
        _ = buffer;
        unreachable;
    }

    pub inline fn bufferGetUsage(buffer: gpu.Buffer) gpu.BufferUsage {
        _ = buffer;
        unreachable;
    }

    // TODO: should return void, I typo'd it
    pub inline fn bufferMapAsync(buffer: gpu.Buffer, mode: gpu.MapMode, offset: usize, size: usize, callback: gpu.BufferMapCallback, userdata: *anyopaque) u64 {
        _ = buffer;
        _ = mode;
        _ = offset;
        _ = size;
        _ = callback;
        _ = userdata;
        unreachable;
    }

    pub inline fn bufferSetLabel(buffer: gpu.Buffer, label: [*:0]const u8) void {
        _ = buffer;
        _ = label;
        unreachable;
    }

    pub inline fn bufferUnmap(buffer: gpu.Buffer) void {
        _ = buffer;
        unreachable;
    }

    pub inline fn bufferReference(buffer: gpu.Buffer) void {
        _ = buffer;
        unreachable;
    }

    pub inline fn bufferRelease(buffer: gpu.Buffer) void {
        _ = buffer;
        unreachable;
    }

    pub inline fn commandBufferSetLabel(command_buffer: gpu.CommandBuffer, label: [*:0]const u8) void {
        _ = command_buffer;
        _ = label;
        unreachable;
    }

    pub inline fn commandBufferReference(command_buffer: gpu.CommandBuffer) void {
        _ = command_buffer;
        unreachable;
    }

    pub inline fn commandBufferRelease(command_buffer: gpu.CommandBuffer) void {
        _ = command_buffer;
        unreachable;
    }

    pub inline fn commandEncoderBeginComputePass(command_encoder: gpu.CommandEncoder, descriptor: ?*const gpu.ComputePassDescriptor) gpu.ComputePassEncoder {
        _ = command_encoder;
        _ = descriptor;
        unreachable;
    }

    pub inline fn commandEncoderBeginRenderPass(command_encoder: gpu.CommandEncoder, descriptor: *const gpu.RenderPassDescriptor) gpu.RenderPassEncoder {
        _ = command_encoder;
        _ = descriptor;
        unreachable;
    }

    pub inline fn commandEncoderClearBuffer(command_encoder: gpu.CommandEncoder, buffer: gpu.Buffer, offset: u64, size: u64) void {
        _ = command_encoder;
        _ = buffer;
        _ = offset;
        _ = size;
        unreachable;
    }

    pub inline fn commandEncoderCopyBufferToBuffer(command_encoder: gpu.CommandEncoder, source: gpu.Buffer, source_offset: u64, destination: gpu.Buffer, destination_offset: u64, size: u64) void {
        _ = command_encoder;
        _ = source;
        _ = source_offset;
        _ = destination;
        _ = destination_offset;
        _ = size;
        unreachable;
    }

    pub inline fn commandEncoderCopyBufferToTexture(command_encoder: gpu.CommandEncoder, source: *const gpu.ImageCopyBuffer, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) void {
        _ = command_encoder;
        _ = source;
        _ = destination;
        _ = copy_size;
        unreachable;
    }

    pub inline fn commandEncoderCopyTextureToBuffer(command_encoder: gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyBuffer, copy_size: *const gpu.Extent3D) void {
        _ = command_encoder;
        _ = source;
        _ = destination;
        _ = copy_size;
        unreachable;
    }

    pub inline fn commandEncoderCopyTextureToTexture(command_encoder: gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) void {
        _ = command_encoder;
        _ = source;
        _ = destination;
        _ = copy_size;
        unreachable;
    }

    pub inline fn commandEncoderCopyTextureToTextureInternal(command_encoder: gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) void {
        _ = command_encoder;
        _ = source;
        _ = destination;
        _ = copy_size;
        unreachable;
    }

    pub inline fn commandEncoderFinish(command_encoder: gpu.CommandEncoder, descriptor: ?*const gpu.CommandBufferDescriptor) gpu.CommandBuffer {
        _ = command_encoder;
        _ = descriptor;
        unreachable;
    }

    pub inline fn commandEncoderInjectValidationError(command_encoder: gpu.CommandEncoder, message: [*:0]const u8) void {
        _ = command_encoder;
        _ = message;
        unreachable;
    }

    pub inline fn commandEncoderInsertDebugMarker(command_encoder: gpu.CommandEncoder, marker_label: [*:0]const u8) void {
        _ = command_encoder;
        _ = marker_label;
        unreachable;
    }

    pub inline fn commandEncoderPopDebugGroup(command_encoder: gpu.CommandEncoder) void {
        _ = command_encoder;
        unreachable;
    }

    pub inline fn commandEncoderPushDebugGroup(command_encoder: gpu.CommandEncoder, group_label: [*:0]const u8) void {
        _ = command_encoder;
        _ = group_label;
        unreachable;
    }

    pub inline fn commandEncoderResolveQuerySet(command_encoder: gpu.CommandEncoder, query_set: gpu.QuerySet, first_query: u32, query_count: u32, destination: gpu.Buffer, destination_offset: u64) void {
        _ = command_encoder;
        _ = query_set;
        _ = first_query;
        _ = query_count;
        _ = destination;
        _ = destination_offset;
        unreachable;
    }

    pub inline fn commandEncoderSetLabel(command_encoder: gpu.CommandEncoder, label: [*:0]const u8) void {
        _ = command_encoder;
        _ = label;
        unreachable;
    }

    pub inline fn commandEncoderWriteBuffer(command_encoder: gpu.CommandEncoder, buffer: gpu.Buffer, buffer_offset: u64, data: [*]const u8, size: u64) void {
        _ = command_encoder;
        _ = buffer;
        _ = buffer_offset;
        _ = data;
        _ = size;
        unreachable;
    }

    pub inline fn commandEncoderWriteTimestamp(command_encoder: gpu.CommandEncoder, query_set: gpu.QuerySet, query_index: u32) void {
        _ = command_encoder;
        _ = query_set;
        _ = query_index;
        unreachable;
    }

    pub inline fn commandEncoderReference(command_encoder: gpu.CommandEncoder) void {
        _ = command_encoder;
        unreachable;
    }

    pub inline fn commandEncoderRelease(command_encoder: gpu.CommandEncoder) void {
        _ = command_encoder;
        unreachable;
    }

    pub inline fn computePassEncoderDispatch(compute_pass_encoder: gpu.ComputePassEncoder, workgroup_count_x: u32, workgroup_count_y: u32, workgroup_count_z: u32) void {
        _ = compute_pass_encoder;
        _ = workgroup_count_x;
        _ = workgroup_count_y;
        _ = workgroup_count_z;
        unreachable;
    }

    pub inline fn computePassEncoderDispatchIndirect(compute_pass_encoder: gpu.ComputePassEncoder, indirect_buffer: gpu.Buffer, indirect_offset: u64) void {
        _ = compute_pass_encoder;
        _ = indirect_buffer;
        _ = indirect_offset;
        unreachable;
    }

    pub inline fn computePassEncoderDispatchWorkgroups(compute_pass_encoder: gpu.ComputePassEncoder, workgroup_count_x: u32, workgroup_count_y: u32, workgroup_count_z: u32) void {
        _ = compute_pass_encoder;
        _ = workgroup_count_x;
        _ = workgroup_count_y;
        _ = workgroup_count_z;
        unreachable;
    }

    pub inline fn computePassEncoderDispatchWorkgroupsIndirect(compute_pass_encoder: gpu.ComputePassEncoder, indirect_buffer: gpu.Buffer, indirect_offset: u64) void {
        _ = compute_pass_encoder;
        _ = indirect_buffer;
        _ = indirect_offset;
        unreachable;
    }

    pub inline fn computePassEncoderEnd(compute_pass_encoder: gpu.ComputePassEncoder) void {
        _ = compute_pass_encoder;
        unreachable;
    }

    pub inline fn computePassEncoderEndPass(compute_pass_encoder: gpu.ComputePassEncoder) void {
        _ = compute_pass_encoder;
        unreachable;
    }

    pub inline fn computePassEncoderInsertDebugMarker(compute_pass_encoder: gpu.ComputePassEncoder, marker_label: [*:0]const u8) void {
        _ = compute_pass_encoder;
        _ = marker_label;
        unreachable;
    }

    pub inline fn computePassEncoderPopDebugGroup(compute_pass_encoder: gpu.ComputePassEncoder) void {
        _ = compute_pass_encoder;
        unreachable;
    }

    pub inline fn computePassEncoderPushDebugGroup(compute_pass_encoder: gpu.ComputePassEncoder, group_label: [*:0]const u8) void {
        _ = compute_pass_encoder;
        _ = group_label;
        unreachable;
    }

    pub inline fn computePassEncoderSetBindGroup(compute_pass_encoder: gpu.ComputePassEncoder, group_index: u32, group: gpu.BindGroup, dynamic_offset_count: u32, dynamic_offsets: [*]const u32) void {
        _ = compute_pass_encoder;
        _ = group_index;
        _ = group;
        _ = dynamic_offset_count;
        _ = dynamic_offsets;
        unreachable;
    }

    pub inline fn computePassEncoderSetLabel(compute_pass_encoder: gpu.ComputePassEncoder, label: [*:0]const u8) void {
        _ = compute_pass_encoder;
        _ = label;
        unreachable;
    }

    pub inline fn computePassEncoderSetPipeline(compute_pass_encoder: gpu.ComputePassEncoder, pipeline: gpu.ComputePipeline) void {
        _ = compute_pass_encoder;
        _ = pipeline;
        unreachable;
    }

    pub inline fn computePassEncoderWriteTimestamp(compute_pass_encoder: gpu.ComputePassEncoder, pipeline: gpu.ComputePipeline) void {
        _ = compute_pass_encoder;
        _ = pipeline;
        unreachable;
    }

    pub inline fn computePassEncoderReference(compute_pass_encoder: gpu.ComputePassEncoder) void {
        _ = compute_pass_encoder;
        unreachable;
    }

    pub inline fn computePassEncoderRelease(compute_pass_encoder: gpu.ComputePassEncoder) void {
        _ = compute_pass_encoder;
        unreachable;
    }

    pub inline fn computePipelineGetBindGroupLayout(compute_pipeline: gpu.ComputePipeline, group_index: u32) gpu.BindGroupLayout {
        _ = compute_pipeline;
        _ = group_index;
        unreachable;
    }

    pub inline fn computePipelineSetLabel(compute_pipeline: gpu.ComputePipeline, label: [*:0]const u8) void {
        _ = compute_pipeline;
        _ = label;
        unreachable;
    }

    pub inline fn computePipelineReference(compute_pipeline: gpu.ComputePipeline) void {
        _ = compute_pipeline;
        unreachable;
    }

    pub inline fn computePipelineRelease(compute_pipeline: gpu.ComputePipeline) void {
        _ = compute_pipeline;
        unreachable;
    }

    pub inline fn deviceCreateBindGroup(device: gpu.Device, descriptor: *const gpu.BindGroupDescriptor) gpu.BindGroup {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceCreateBindGroupLayout(device: gpu.Device, descriptor: *const gpu.BindGroupLayoutDescriptor) gpu.BindGroupLayout {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    // TODO: should be deviceCreateBuffer elsewhere
    pub inline fn deviceCreateBuffer(device: gpu.Device, descriptor: *const gpu.BufferDescriptor) gpu.Buffer {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceCreateCommandEncoder(device: gpu.Device, descriptor: ?*const gpu.CommandEncoderDescriptor) gpu.CommandEncoder {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceCreateComputePipeline(device: gpu.Device, descriptor: *const gpu.ComputePipelineDescriptor) gpu.ComputePipeline {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceCreateComputePipelineAsync(device: gpu.Device, descriptor: *const gpu.ComputePipelineDescriptor, callback: gpu.CreateComputePipelineAsyncCallback, userdata: *anyopaque) void {
        _ = device;
        _ = descriptor;
        _ = callback;
        _ = userdata;
        unreachable;
    }

    pub inline fn deviceCreateErrorBuffer(device: gpu.Device) gpu.Buffer {
        _ = device;
        unreachable;
    }

    pub inline fn deviceCreateErrorExternalTexture(device: gpu.Device) gpu.ExternalTexture {
        _ = device;
        unreachable;
    }

    pub inline fn deviceCreateExternalTexture(device: gpu.Device, external_texture_descriptor: *const gpu.ExternalTextureDescriptor) gpu.ExternalTexture {
        _ = device;
        _ = external_texture_descriptor;
        unreachable;
    }

    pub inline fn deviceCreatePipelineLayout(device: gpu.Device, pipeline_layout_descriptor: *const gpu.PipelineLayoutDescriptor) gpu.PipelineLayout {
        _ = device;
        _ = pipeline_layout_descriptor;
        unreachable;
    }

    pub inline fn deviceCreateQuerySet(device: gpu.Device, descriptor: *const gpu.QuerySetDescriptor) gpu.QuerySet {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceCreateRenderBundleEncoder(device: gpu.Device, descriptor: *const gpu.RenderBundleEncoderDescriptor) gpu.RenderBundleEncoder {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceCreateRenderPipeline(device: gpu.Device, descriptor: *const gpu.RenderPipelineDescriptor) gpu.RenderPipeline {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceCreateRenderPipelineAsync(device: gpu.Device, descriptor: *const gpu.RenderPipelineDescriptor, callback: gpu.CreateRenderPipelineAsyncCallback, userdata: *anyopaque) void {
        _ = device;
        _ = descriptor;
        _ = callback;
        _ = userdata;
        unreachable;
    }

    pub inline fn deviceCreateSampler(device: gpu.Device, descriptor: ?*const gpu.SamplerDescriptor) gpu.Sampler {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceCreateShaderModule(device: gpu.Device, descriptor: *const gpu.ShaderModuleDescriptor) gpu.ShaderModule {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceCreateSwapChain(device: gpu.Device, surface: ?gpu.Surface, descriptor: *const gpu.SwapChainDescriptor) gpu.SwapChain {
        _ = device;
        _ = surface;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceCreateTexture(device: gpu.Device, descriptor: *const gpu.TextureDescriptor) gpu.Texture {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceDestroy(device: gpu.Device) void {
        _ = device;
        unreachable;
    }

    pub inline fn deviceEnumerateFeatures(device: gpu.Device, features: [*]gpu.FeatureName) usize {
        _ = device;
        _ = features;
        unreachable;
    }

    pub inline fn deviceGetLimits(device: gpu.Device, limits: *gpu.SupportedLimits) bool {
        _ = device;
        _ = limits;
        unreachable;
    }

    pub inline fn deviceGetQueue(device: gpu.Device) gpu.Queue {
        _ = device;
        unreachable;
    }

    pub inline fn deviceHasFeature(device: gpu.Device, feature: gpu.FeatureName) bool {
        _ = device;
        _ = feature;
        unreachable;
    }

    pub inline fn deviceInjectError(device: gpu.Device, typ: gpu.ErrorType, message: [*:0]const u8) void {
        _ = device;
        _ = typ;
        _ = message;
        unreachable;
    }

    pub inline fn deviceLoseForTesting(device: gpu.Device) void {
        _ = device;
        unreachable;
    }

    pub inline fn devicePopErrorScope(device: gpu.Device, callback: gpu.ErrorCallback, userdata: *anyopaque) bool {
        _ = device;
        _ = callback;
        _ = userdata;
        unreachable;
    }

    pub inline fn devicePushErrorScope(device: gpu.Device, filter: gpu.ErrorFilter) void {
        _ = device;
        _ = filter;
        unreachable;
    }

    pub inline fn deviceSetDeviceLostCallback(device: gpu.Device, callback: gpu.DeviceLostCallback, userdata: *anyopaque) void {
        _ = device;
        _ = callback;
        _ = userdata;
        unreachable;
    }

    pub inline fn deviceSetLabel(device: gpu.Device, label: [*:0]const u8) void {
        _ = device;
        _ = label;
        unreachable;
    }

    pub inline fn deviceSetLoggingCallback(device: gpu.Device, callback: gpu.LoggingCallback, userdata: *anyopaque) void {
        _ = device;
        _ = callback;
        _ = userdata;
        unreachable;
    }

    pub inline fn deviceSetUncapturedErrorCallback(device: gpu.Device, callback: gpu.ErrorCallback, userdata: *anyopaque) void {
        _ = device;
        _ = callback;
        _ = userdata;
        unreachable;
    }

    pub inline fn deviceTick(device: gpu.Device) void {
        _ = device;
        unreachable;
    }

    pub inline fn deviceReference(device: gpu.Device) void {
        _ = device;
        unreachable;
    }

    pub inline fn deviceRelease(device: gpu.Device) void {
        _ = device;
        unreachable;
    }

    pub inline fn externalTextureDestroy(external_texture: gpu.ExternalTexture) void {
        _ = external_texture;
        unreachable;
    }

    pub inline fn externalTextureSetLabel(external_texture: gpu.ExternalTexture, label: [*:0]const u8) void {
        _ = external_texture;
        _ = label;
        unreachable;
    }

    pub inline fn externalTextureReference(external_texture: gpu.ExternalTexture) void {
        _ = external_texture;
        unreachable;
    }

    pub inline fn externalTextureRelease(external_texture: gpu.ExternalTexture) void {
        _ = external_texture;
        unreachable;
    }

    pub inline fn instanceCreateSurface(instance: gpu.Instance, descriptor: *const gpu.SurfaceDescriptor) gpu.Surface {
        _ = instance;
        _ = descriptor;
        unreachable;
    }

    pub inline fn instanceRequestAdapter(instance: gpu.Instance, options: *const gpu.RequestAdapterOptions, callback: gpu.RequestAdapterCallback, userdata: *anyopaque) void {
        _ = instance;
        _ = options;
        _ = callback;
        _ = userdata;
        unreachable;
    }

    pub inline fn instanceReference(instance: gpu.Instance) void {
        _ = instance;
        unreachable;
    }

    pub inline fn instanceRelease(instance: gpu.Instance) void {
        _ = instance;
        unreachable;
    }

    pub inline fn pipelineLayoutSetLabel(pipeline_layout: gpu.PipelineLayout, label: [*:0]const u8) void {
        _ = pipeline_layout;
        _ = label;
        unreachable;
    }

    pub inline fn pipelineLayoutReference(pipeline_layout: gpu.PipelineLayout) void {
        _ = pipeline_layout;
        unreachable;
    }

    pub inline fn pipelineLayoutRelease(pipeline_layout: gpu.PipelineLayout) void {
        _ = pipeline_layout;
        unreachable;
    }

    pub inline fn querySetDestroy(query_set: gpu.QuerySet) void {
        _ = query_set;
        unreachable;
    }

    pub inline fn querySetGetCount(query_set: gpu.QuerySet) u32 {
        _ = query_set;
        unreachable;
    }

    pub inline fn querySetGetType(query_set: gpu.QuerySet) gpu.QueryType {
        _ = query_set;
        unreachable;
    }

    pub inline fn querySetSetLabel(query_set: gpu.QuerySet, label: [*:0]const u8) void {
        _ = query_set;
        _ = label;
        unreachable;
    }

    pub inline fn querySetReference(query_set: gpu.QuerySet) void {
        _ = query_set;
        unreachable;
    }

    pub inline fn querySetRelease(query_set: gpu.QuerySet) void {
        _ = query_set;
        unreachable;
    }

    pub inline fn queueCopyTextureForBrowser(queue: gpu.Queue, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D, options: *const gpu.CopyTextureForBrowserOptions) void {
        _ = queue;
        _ = source;
        _ = destination;
        _ = copy_size;
        _ = options;
        unreachable;
    }

    pub inline fn queueOnSubmittedWorkDone(queue: gpu.Queue, signal_value: u64, callback: gpu.QueueWorkDoneCallback, userdata: *anyopaque) void {
        _ = queue;
        _ = signal_value;
        _ = callback;
        _ = userdata;
        unreachable;
    }

    pub inline fn queueSetLabel(queue: gpu.Queue, label: [*:0]const u8) void {
        _ = queue;
        _ = label;
        unreachable;
    }

    pub inline fn queueSubmit(queue: gpu.Queue, command_count: u32, commands: [*]gpu.CommandBuffer) void {
        _ = queue;
        _ = command_count;
        _ = commands;
        unreachable;
    }

    pub inline fn queueWriteBuffer(queue: gpu.Queue, buffer: gpu.Buffer, buffer_offset: u64, data: *anyopaque, size: usize) void {
        _ = queue;
        _ = buffer;
        _ = buffer_offset;
        _ = data;
        _ = size;
        unreachable;
    }

    pub inline fn queueWriteTexture(queue: gpu.Queue, data: *anyopaque, data_size: usize, data_layout: *const gpu.TextureDataLayout, write_size: *const gpu.Extent3D) void {
        _ = queue;
        _ = data;
        _ = data_size;
        _ = data_layout;
        _ = write_size;
        unreachable;
    }

    pub inline fn queueReference(queue: gpu.Queue) void {
        _ = queue;
        unreachable;
    }

    pub inline fn queueRelease(queue: gpu.Queue) void {
        _ = queue;
        unreachable;
    }

    pub inline fn renderBundleReference(render_bundle: gpu.RenderBundle) void {
        _ = render_bundle;
        unreachable;
    }

    pub inline fn renderBundleRelease(render_bundle: gpu.RenderBundle) void {
        _ = render_bundle;
        unreachable;
    }

    pub inline fn renderBundleEncoderDraw(render_bundle_encoder: gpu.RenderBundleEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {
        _ = render_bundle_encoder;
        _ = vertex_count;
        _ = instance_count;
        _ = first_vertex;
        _ = first_instance;
        unreachable;
    }

    pub inline fn renderBundleEncoderDrawIndexed(render_bundle_encoder: gpu.RenderBundleEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: u32, first_instance: u32) void {
        _ = render_bundle_encoder;
        _ = index_count;
        _ = instance_count;
        _ = first_index;
        _ = base_vertex;
        _ = first_instance;
        unreachable;
    }

    pub inline fn renderBundleEncoderDrawIndexedIndirect(render_bundle_encoder: gpu.RenderBundleEncoder, indirect_buffer: gpu.Buffer, indirect_offset: u64) void {
        _ = render_bundle_encoder;
        _ = indirect_buffer;
        _ = indirect_offset;
        unreachable;
    }

    pub inline fn renderBundleEncoderDrawIndirect(render_bundle_encoder: gpu.RenderBundleEncoder, indirect_buffer: gpu.Buffer, indirect_offset: u64) void {
        _ = render_bundle_encoder;
        _ = indirect_buffer;
        _ = indirect_offset;
        unreachable;
    }

    pub inline fn renderBundleEncoderFinish(render_bundle_encoder: gpu.RenderBundleEncoder, descriptor: ?*const gpu.RenderBundleDescriptor) void {
        _ = render_bundle_encoder;
        _ = descriptor;
        unreachable;
    }

    pub inline fn renderBundleEncoderInsertDebugMarker(render_bundle_encoder: gpu.RenderBundleEncoder, marker_label: [*:0]const u8) void {
        _ = render_bundle_encoder;
        _ = marker_label;
        unreachable;
    }

    pub inline fn renderBundleEncoderPopDebugGroup(render_bundle_encoder: gpu.RenderBundleEncoder) void {
        _ = render_bundle_encoder;
        unreachable;
    }

    pub inline fn renderBundleEncoderPushDebugGroup(render_bundle_encoder: gpu.RenderBundleEncoder, group_label: [*:0]const u8) void {
        _ = render_bundle_encoder;
        _ = group_label;
        unreachable;
    }

    pub inline fn renderBundleEncoderSetBindGroup(render_bundle_encoder: gpu.RenderBundleEncoder, group_index: u32, group: gpu.BindGroup, dynamic_offset_count: u32, dynamic_offsets: [*]const u32) void {
        _ = render_bundle_encoder;
        _ = group_index;
        _ = group;
        _ = dynamic_offset_count;
        _ = dynamic_offsets;
        unreachable;
    }

    pub inline fn renderBundleEncoderSetIndexBuffer(render_bundle_encoder: gpu.RenderBundleEncoder, buffer: gpu.Buffer, format: gpu.IndexFormat, offset: u64, size: u64) void {
        _ = render_bundle_encoder;
        _ = buffer;
        _ = format;
        _ = offset;
        _ = size;
        unreachable;
    }

    pub inline fn renderBundleEncoderSetLabel(render_bundle_encoder: gpu.RenderBundleEncoder, label: [*:0]const u8) void {
        _ = render_bundle_encoder;
        _ = label;
        unreachable;
    }

    pub inline fn renderBundleEncoderSetPipeline(render_bundle_encoder: gpu.RenderBundleEncoder, pipeline: gpu.RenderPipeline) void {
        _ = render_bundle_encoder;
        _ = pipeline;
        unreachable;
    }

    pub inline fn renderBundleEncoderSetVertexBuffer(render_bundle_encoder: gpu.RenderBundleEncoder, slot: u32, buffer: gpu.Buffer, offset: u64, size: u64) void {
        _ = render_bundle_encoder;
        _ = slot;
        _ = buffer;
        _ = offset;
        _ = size;
        unreachable;
    }

    pub inline fn renderBundleEncoderReference(render_bundle_encoder: gpu.RenderBundleEncoder) void {
        _ = render_bundle_encoder;
        unreachable;
    }

    pub inline fn renderBundleEncoderRelease(render_bundle_encoder: gpu.RenderBundleEncoder) void {
        _ = render_bundle_encoder;
        unreachable;
    }

    pub inline fn renderPassEncoderBeginOcclusionQuery(render_pass_encoder: gpu.RenderPassEncoder, query_index: u32) void {
        _ = render_pass_encoder;
        _ = query_index;
        unreachable;
    }

    pub inline fn renderPassEncoderDraw(render_pass_encoder: gpu.RenderPassEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {
        _ = render_pass_encoder;
        _ = vertex_count;
        _ = instance_count;
        _ = first_vertex;
        _ = first_instance;
        unreachable;
    }

    pub inline fn renderPassEncoderDrawIndexed(render_pass_encoder: gpu.RenderPassEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: u32, first_instance: u32) void {
        _ = render_pass_encoder;
        _ = index_count;
        _ = instance_count;
        _ = first_index;
        _ = base_vertex;
        _ = first_instance;
        unreachable;
    }

    pub inline fn renderPassEncoderDrawIndexedIndirect(render_pass_encoder: gpu.RenderPassEncoder, indirect_buffer: gpu.Buffer, indirect_offset: u64) void {
        _ = render_pass_encoder;
        _ = indirect_buffer;
        _ = indirect_offset;
        unreachable;
    }

    pub inline fn renderPassEncoderDrawIndirect(render_pass_encoder: gpu.RenderPassEncoder, indirect_buffer: gpu.Buffer, indirect_offset: u64) void {
        _ = render_pass_encoder;
        _ = indirect_buffer;
        _ = indirect_offset;
        unreachable;
    }

    pub inline fn renderPassEncoderEnd(render_pass_encoder: gpu.RenderPassEncoder) void {
        _ = render_pass_encoder;
        unreachable;
    }

    pub inline fn renderPassEncoderEndOcclusionQuery(render_pass_encoder: gpu.RenderPassEncoder) void {
        _ = render_pass_encoder;
        unreachable;
    }

    pub inline fn renderPassEncoderEndPass(render_pass_encoder: gpu.RenderPassEncoder) void {
        _ = render_pass_encoder;
        unreachable;
    }

    pub inline fn renderPassEncoderExecuteBundles(render_pass_encoder: gpu.RenderPassEncoder, bundles_count: u32, bundles: [*]const gpu.RenderBundle) void {
        _ = render_pass_encoder;
        _ = bundles_count;
        _ = bundles;
        unreachable;
    }

    pub inline fn renderPassEncoderInsertDebugMarker(render_pass_encoder: gpu.RenderPassEncoder, marker_label: [*:0]const u8) void {
        _ = render_pass_encoder;
        _ = marker_label;
        unreachable;
    }

    pub inline fn renderPassEncoderPopDebugGroup(render_pass_encoder: gpu.RenderPassEncoder) void {
        _ = render_pass_encoder;
        unreachable;
    }

    pub inline fn renderPassEncoderPushDebugGroup(render_pass_encoder: gpu.RenderPassEncoder, group_label: [*:0]const u8) void {
        _ = render_pass_encoder;
        _ = group_label;
        unreachable;
    }

    pub inline fn renderPassEncoderSetBindGroup(render_pass_encoder: gpu.RenderPassEncoder, group_index: u32, group: gpu.BindGroup, dynamic_offset_count: u32, dynamic_offsets: [*]const u32) void {
        _ = render_pass_encoder;
        _ = group_index;
        _ = group;
        _ = dynamic_offset_count;
        _ = dynamic_offsets;
        unreachable;
    }

    pub inline fn renderPassEncoderSetBlendConstant(render_pass_encoder: gpu.RenderPassEncoder, color: *const gpu.Color) void {
        _ = render_pass_encoder;
        _ = color;
        unreachable;
    }

    pub inline fn renderPassEncoderSetIndexBuffer(render_pass_encoder: gpu.RenderPassEncoder, buffer: gpu.Buffer, format: gpu.IndexFormat, offset: u64, size: u64) void {
        _ = render_pass_encoder;
        _ = buffer;
        _ = format;
        _ = offset;
        _ = size;
        unreachable;
    }

    pub inline fn renderPassEncoderSetLabel(render_pass_encoder: gpu.RenderPassEncoder, label: [*:0]const u8) void {
        _ = render_pass_encoder;
        _ = label;
        unreachable;
    }

    pub inline fn renderPassEncoderSetPipeline(render_pass_encoder: gpu.RenderPassEncoder, pipeline: gpu.RenderPipeline) void {
        _ = render_pass_encoder;
        _ = pipeline;
        unreachable;
    }

    pub inline fn renderPassEncoderSetScissorRect(render_pass_encoder: gpu.RenderPassEncoder, x: u32, y: u32, width: u32, height: u32) void {
        _ = render_pass_encoder;
        _ = x;
        _ = y;
        _ = width;
        _ = height;
        unreachable;
    }

    pub inline fn renderPassEncoderSetStencilReference(render_pass_encoder: gpu.RenderPassEncoder, reference: u32) void {
        _ = render_pass_encoder;
        _ = reference;
        unreachable;
    }

    pub inline fn renderPassEncoderSetVertexBuffer(render_pass_encoder: gpu.RenderPassEncoder, slot: u32, buffer: gpu.Buffer, offset: u64, size: u64) void {
        _ = render_pass_encoder;
        _ = slot;
        _ = buffer;
        _ = offset;
        _ = size;
        unreachable;
    }

    pub inline fn renderPassEncoderSetViewport(render_pass_encoder: gpu.RenderPassEncoder, x: f32, y: f32, width: f32, height: f32, min_depth: f32, max_depth: f32) void {
        _ = render_pass_encoder;
        _ = x;
        _ = y;
        _ = width;
        _ = height;
        _ = min_depth;
        _ = max_depth;
        unreachable;
    }

    pub inline fn renderPassEncoderWriteTimestamp(render_pass_encoder: gpu.RenderPassEncoder, query_set: gpu.QuerySet, query_index: u32) void {
        _ = render_pass_encoder;
        _ = query_set;
        _ = query_index;
        unreachable;
    }

    pub inline fn renderPassEncoderReference(render_pass_encoder: gpu.RenderPassEncoder) void {
        _ = render_pass_encoder;
        unreachable;
    }

    pub inline fn renderPassEncoderRelease(render_pass_encoder: gpu.RenderPassEncoder) void {
        _ = render_pass_encoder;
        unreachable;
    }

    pub inline fn renderPipelineGetBindGroupLayout(render_pipeline: gpu.RenderPipeline, group_index: u32) gpu.BindGroupLayout {
        _ = render_pipeline;
        _ = group_index;
        unreachable;
    }

    pub inline fn renderPipelineSetLabel(render_pipeline: gpu.RenderPipeline, label: [*:0]const u8) void {
        _ = render_pipeline;
        _ = label;
        unreachable;
    }

    pub inline fn renderPipelineReference(render_pipeline: gpu.RenderPipeline) void {
        _ = render_pipeline;
        unreachable;
    }

    pub inline fn renderPipelineRelease(render_pipeline: gpu.RenderPipeline) void {
        _ = render_pipeline;
        unreachable;
    }

    pub inline fn samplerSetLabel(sampler: gpu.Sampler, label: [*:0]const u8) void {
        _ = sampler;
        _ = label;
        unreachable;
    }

    pub inline fn samplerReference(sampler: gpu.Sampler) void {
        _ = sampler;
        unreachable;
    }

    pub inline fn samplerRelease(sampler: gpu.Sampler) void {
        _ = sampler;
        unreachable;
    }

    pub inline fn shaderModuleGetCompilationInfo(shader_module: gpu.ShaderModule, callback: gpu.CompilationInfoCallback, userdata: *anyopaque) void {
        _ = shader_module;
        _ = callback;
        _ = userdata;
        unreachable;
    }

    pub inline fn shaderModuleSetLabel(shader_module: gpu.ShaderModule, label: [*:0]const u8) void {
        _ = shader_module;
        _ = label;
        unreachable;
    }

    pub inline fn shaderModuleReference(shader_module: gpu.ShaderModule) void {
        _ = shader_module;
        unreachable;
    }

    pub inline fn shaderModuleRelease(shader_module: gpu.ShaderModule) void {
        _ = shader_module;
        unreachable;
    }

    pub inline fn surfaceReference(surface: gpu.Surface) void {
        _ = surface;
        unreachable;
    }

    pub inline fn surfaceRelease(surface: gpu.Surface) void {
        _ = surface;
        unreachable;
    }

    pub inline fn swapChainConfigure(swap_chain: gpu.SwapChain, format: gpu.TextureFormat, allowed_usage: gpu.TextureUsageFlags, width: u32, height: u32) void {
        _ = swap_chain;
        _ = format;
        _ = allowed_usage;
        _ = width;
        _ = height;
        unreachable;
    }

    pub inline fn swapChainGetCurrentTextureView(swap_chain: gpu.SwapChain) gpu.TextureView {
        _ = swap_chain;
        unreachable;
    }

    pub inline fn swapChainPresent(swap_chain: gpu.SwapChain) void {
        _ = swap_chain;
        unreachable;
    }

    pub inline fn swapChainReference(swap_chain: gpu.SwapChain) void {
        _ = swap_chain;
        unreachable;
    }

    pub inline fn swapChainRelease(swap_chain: gpu.SwapChain) void {
        _ = swap_chain;
        unreachable;
    }

    pub inline fn textureCreateView(texture: gpu.Texture, descriptor: ?*const gpu.TextureViewDescriptor) gpu.TextureView {
        _ = texture;
        _ = descriptor;
        unreachable;
    }

    pub inline fn textureDestroy(texture: gpu.Texture) void {
        _ = texture;
        unreachable;
    }

    pub inline fn textureGetDepthOrArrayLayers(texture: gpu.Texture) u32 {
        _ = texture;
        unreachable;
    }

    pub inline fn textureGetDimension(texture: gpu.Texture) gpu.TextureDimension {
        _ = texture;
        unreachable;
    }

    pub inline fn textureGetFormat(texture: gpu.Texture) gpu.TextureFormat {
        _ = texture;
        unreachable;
    }

    pub inline fn textureGetHeight(texture: gpu.Texture) u32 {
        _ = texture;
        unreachable;
    }

    pub inline fn textureGetMipLevelCount(texture: gpu.Texture) u32 {
        _ = texture;
        unreachable;
    }

    pub inline fn textureGetSampleCount(texture: gpu.Texture) u32 {
        _ = texture;
        unreachable;
    }

    pub inline fn textureGetUsage(texture: gpu.Texture) gpu.TextureUsageFlags {
        _ = texture;
        unreachable;
    }

    pub inline fn textureGetWidth(texture: gpu.Texture) u32 {
        _ = texture;
        unreachable;
    }

    pub inline fn textureSetLabel(texture: gpu.Texture, label: [*:0]const u8) void {
        _ = texture;
        _ = label;
        unreachable;
    }

    pub inline fn textureReference(texture: gpu.Texture) void {
        _ = texture;
        unreachable;
    }

    pub inline fn textureRelease(texture: gpu.Texture) void {
        _ = texture;
        unreachable;
    }

    pub inline fn textureViewSetLabel(texture_view: gpu.TextureView, label: [*:0]const u8) void {
        _ = texture_view;
        _ = label;
        unreachable;
    }

    pub inline fn textureViewReference(texture_view: gpu.TextureView) void {
        _ = texture_view;
        unreachable;
    }

    pub inline fn textureViewRelease(texture_view: gpu.TextureView) void {
        _ = texture_view;
        unreachable;
    }
});

test "stub" {
    _ = Export(StubInterface);
}
