const Instance = @import("instance.zig").Instance;
const InstanceDescriptor = @import("instance.zig").InstanceDescriptor;
const gpu = @import("main.zig");

/// The gpu.Interface implementation that is used by the entire program. Only one may exist, since
/// it is resolved fully at comptime with no vtable indirection, etc.
pub const impl = blk: {
    if (@import("builtin").is_test) {
        break :blk NullInterface{};
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
    // assertDecl(Impl, "adapterRequestDevice", fn (adapter: gpu.Adapter, descriptor: ?*const gpu.DeviceDescriptor, callback: gpu.RequestDeviceCallback, userdata: *anyopaque) callconv(.Inline) void);
    // assertDecl(Impl, "adapterReference", fn (adapter: gpu.Adapter) callconv(.Inline) void);
    // assertDecl(Impl, "adapterRelease", fn (adapter: gpu.Adapter) callconv(.Inline) void);
    // assertDecl(Impl, "bindGroupSetLabel", fn (bind_group: gpu.BindGroup, label: [*:0]const u8) callconv(.Inline) void);
    // assertDecl(Impl, "bindGroupReference", fn (bind_group: gpu.BindGroup) callconv(.Inline) void);
    // assertDecl(Impl, "bindGroupRelease", fn (bind_group: gpu.BindGroup) callconv(.Inline) void);
    // assertDecl(Impl, "bindGroupLayoutSetLabel", fn (bind_group_layout: gpu.BindGroupLayout, label: [*:0]const u8) callconv(.Inline) void);
    // assertDecl(Impl, "bindGroupLayoutReference", fn (bind_group_layout: gpu.BindGroupLayout) callconv(.Inline) void);
    // assertDecl(Impl, "bindGroupLayoutRelease", fn (bind_group_layout: gpu.BindGroupLayout) callconv(.Inline) void);
    // assertDecl(Impl, "bufferDestroy", fn (buffer: gpu.Buffer) callconv(.Inline) void);
    // assertDecl(Impl, "bufferGetConstMappedRange", fn (buffer: gpu.Buffer, offset: usize, size: usize) callconv(.Inline) *const anyopaque);
    // assertDecl(Impl, "bufferGetMappedRange", fn (buffer: gpu.Buffer, offset: usize, size: usize) callconv(.Inline) *anyopaque);
    // assertDecl(Impl, "bufferGetSize", fn (buffer: gpu.Buffer) callconv(.Inline) u64);
    // assertDecl(Impl, "bufferGetUsage", fn (buffer: gpu.Buffer) callconv(.Inline) gpu.BufferUsage);
    // assertDecl(Impl, "bufferMapAsync", fn (buffer: gpu.Buffer, mode: gpu.MapModeFlags, offset: usize, size: usize, callback: BufferMapCallback, userdata: *anyopaque) callconv(.Inline) u64);
    // assertDecl(Impl, "bufferSetLabel", fn (buffer: gpu.Buffer, label: [*:0]const u8) callconv(.Inline) void);
    // assertDecl(Impl, "bufferUnmap", fn (buffer: gpu.Buffer) callconv(.Inline) void);
    // assertDecl(Impl, "bufferReference", fn (buffer: gpu.Buffer) callconv(.Inline) void);
    // assertDecl(Impl, "bufferRelease", fn (buffer: gpu.Buffer) callconv(.Inline) void);
    // assertDecl(Impl, "commandBufferSetLabel", fn (command_buffer: gpu.CommandBuffer, label: [*:0]const u8) callconv(.Inline) void);
    // assertDecl(Impl, "commandBufferReference", fn (command_buffer: gpu.CommandBuffer) callconv(.Inline) void);
    // assertDecl(Impl, "commandBufferRelease", fn (command_buffer: gpu.CommandBuffer) callconv(.Inline) void);
    // assertDecl(Impl, "commandEncoderBeginComputePass", fn (command_encoder: gpu.CommandEncoder, descriptor: ?*const gpu.ComputePassDescriptor) callconv(.Inline) gpu.ComputePassEncoder);
    // assertDecl(Impl, "commandEncoderBeginRenderPass", fn (command_encoder: gpu.CommandEncoder, descriptor: *const gpu.RenderPassDescriptor) callconv(.Inline) gpu.RenderPassEncoder);
    // assertDecl(Impl, "commandEncoderClearBuffer", fn (command_encoder: gpu.CommandEncoder, buffer: gpu.Buffer, offset: u64, size: u64) callconv(.Inline) void);
    // assertDecl(Impl, "commandEncoderCopyBufferToBuffer", fn (command_encoder: gpu.CommandEncoder, source: gpu.Buffer, source_offset: u64, destination: gpu.Buffer, destination_offset: u64, size: u64) callconv(.Inline) void);
    // assertDecl(Impl, "commandEncoderCopyBufferToTexture", fn (command_encoder: gpu.CommandEncoder, source: *const gpu.ImageCopyBuffer, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) callconv(.Inline) void);
    // assertDecl(Impl, "commandEncoderCopyTextureToBuffer", fn (command_encoder: gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyBuffer, copy_size: *const gpu.Extent3D) callconv(.Inline) void);
    // assertDecl(Impl, "commandEncoderCopyTextureToTexture", fn (command_encoder: gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) callconv(.Inline) void);
    // assertDecl(Impl, "commandEncoderCopyTextureToTextureInternal", fn (command_encoder: gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) callconv(.Inline) void);
    // assertDecl(Impl, "commandEncoderFinish", fn (command_encoder: gpu.CommandEncoder, descriptor: ?*const gpu.CommandBufferDescriptor) callconv(.Inline) gpu.CommandBuffer);
    // assertDecl(Impl, "commandEncoderInjectValidationError", fn (command_encoder: gpu.CommandEncoder, message: [*:0]const u8) void);
    // assertDecl(Impl, "commandEncoderInsertDebugMarker", fn (command_encoder: gpu.CommandEncoder, marker_label: [*:0]const u8) void);
    // assertDecl(Impl, "commandEncoderPopDebugGroup", fn (command_encoder: gpu.CommandEncoder) void);
    // assertDecl(Impl, "commandEncoderPushDebugGroup", fn (command_encoder: gpu.CommandEncoder, group_label: [*:0]const u8) void);
    // assertDecl(Impl, "commandEncoderResolveQuerySet", fn (command_encoder: gpu.CommandEncoder, query_set: gpu.QuerySet, first_query: u32, query_count: u32, destination: gpu.Buffer, destination_offset: u64) void);
    // assertDecl(Impl, "commandEncoderSetLabel", fn (command_encoder: gpu.CommandEncoder, label: [*:0]const u8) callconv(.Inline) void);
    // assertDecl(Impl, "commandEncoderWriteBuffer", fn (command_encoder: gpu.CommandEncoder, buffer: gpu.Buffer, buffer_offset: u64, data: [*]const u8, size: u64) void);
    // assertDecl(Impl, "commandEncoderWriteTimestamp", fn (command_encoder: gpu.CommandEncoder, query_set: gpu.QuerySet, query_index: u32) void);
    // assertDecl(Impl, "commandEncoderReference", fn (command_encoder: gpu.CommandEncoder) callconv(.Inline) void);
    // assertDecl(Impl, "commandEncoderRelease", fn (command_encoder: gpu.CommandEncoder) callconv(.Inline) void);
    // assertDecl(Impl, "computePassEncoderDispatch", fn (compute_pass_encoder: gpu.ComputePassEncoder, workgroup_count_x: u32, workgroup_count_y: u32, workgroup_count_z: u32) callconv(.Inline) void);
    // assertDecl(Impl, "computePassEncoderDispatchIndirect", fn (compute_pass_encoder: gpu.ComputePassEncoder, indirect_buffer: gpu.Buffer, indirect_offset: u64) callconv(.Inline) void);
    // assertDecl(Impl, "computePassEncoderDispatchWorkgroups", fn (compute_pass_encoder: gpu.ComputePassEncoder, workgroup_count_x: u32, workgroup_count_y: u32, workgroup_count_z: u32) callconv(.Inline) void);
    // assertDecl(Impl, "wgpuComputePassEncoderDispatchWorkgroupsIndirect", fn (compute_pass_encoder: gpu.ComputePassEncoder, indirect_buffer: gpu.Buffer, indirect_offset: u64) callconv(.Inline) void);
    // assertDecl(Impl, "computePassEncoderEnd", fn (compute_pass_encoder: gpu.ComputePassEncoder) callconv(.Inline) void);
    // assertDecl(Impl, "computePassEncoderEndPass", fn (compute_pass_encoder: gpu.ComputePassEncoder) callconv(.Inline) void);
    // assertDecl(Impl, "computePassEncoderInsertDebugMarker", fn (compute_pass_encoder: gpu.ComputePassEncoder, marker_label: [*:0]const u8) callconv(.Inline) void);
    // assertDecl(Impl, "computePassEncoderPopDebugGroup", fn (compute_pass_encoder: gpu.ComputePassEncoder) callconv(.Inline) void);
    // assertDecl(Impl, "computePassEncoderPushDebugGroup", fn (compute_pass_encoder: gpu.ComputePassEncoder, group_label: [*:0]const u8) callconv(.Inline) void);
    // assertDecl(Impl, "computePassEncoderSetBindGroup", fn (compute_pass_encoder: gpu.ComputePassEncoder, group_index: u32, group: gpu.BindGroup, dynamic_offset_count: u32, dynamic_offsets: [*]const u32) callconv(.Inline) void);
    // assertDecl(Impl, "computePassEncoderSetLabel", fn (compute_pass_encoder: gpu.ComputePassEncoder, label: [*:0]const u8) callconv(.Inline) void);
    // assertDecl(Impl, "computePassEncoderSetPipeline", fn (compute_pass_encoder: gpu.ComputePassEncoder, pipeline: gpu.ComputePipeline) callconv(.Inline) void);
    // assertDecl(Impl, "computePassEncoderWriteTimestamp", fn (compute_pass_encoder: gpu.ComputePassEncoder, pipeline: gpu.ComputePipeline) callconv(.Inline) void);
    // assertDecl(Impl, "computePassEncoderReference", fn (compute_pass_encoder: gpu.ComputePassEncoder) callconv(.Inline) void);
    // assertDecl(Impl, "computePassEncoderRelease", fn (compute_pass_encoder: gpu.ComputePassEncoder) callconv(.Inline) void);
    // assertDecl(Impl, "computePipelineGetBindGroupLayout", fn (compute_pipeline: gpu.ComputePipeline, group_index: u32) callconv(.Inline) gpu.BindGroupLayout);
    // assertDecl(Impl, "computePipelineSetLabel", fn (compute_pipeline: gpu.ComputePipeline, label: [*:0]const u8) callconv(.Inline) void);
    // assertDecl(Impl, "computePipelineReference", fn (compute_pipeline: gpu.ComputePipeline) callconv(.Inline) void);
    // assertDecl(Impl, "computePipelineRelease", fn (compute_pipeline: gpu.ComputePipeline) callconv(.Inline) void);
    // assertDecl(Impl, "deviceCreateBindGroup", fn (device: gpu.Device, descriptor: *const gpu.BindGroupDescriptor) callconv(.Inline) gpu.BindGroup);
    // assertDecl(Impl, "deviceCreateBindGroupLayout", fn (device: gpu.Device, descriptor: *const gpu.BindGroupLayoutDescriptor) callconv(.Inline) gpu.BindGroupLayout);
    // assertDecl(Impl, "deviceCreateBindGroup", fn (device: gpu.Device, descriptor: *const gpu.BufferDescriptor) callconv(.Inline) gpu.Buffer);
    // assertDecl(Impl, "deviceCreateCommandEncoder", fn (device: gpu.Device, descriptor: ?*const gpu.CommandEncoderDescriptor) callconv(.Inline) gpu.CommandEncoder);
    // assertDecl(Impl, "deviceCreateComputePipeline", fn (device: gpu.Device, descriptor: *const gpu.ComputePipelineDescriptor) callconv(.Inline) gpu.ComputePipeline);
    // assertDecl(Impl, "deviceCreateComputePipelineAsync", fn (device: gpu.Device, descriptor: *const gpu.ComputePipelineDescriptor, callback: gpu.CreateComputePipelineAsyncCallback, userdata: *anyopaque) callconv(.Inline) void);
    // assertDecl(Impl, "deviceCreateErrorBuffer", fn (device: gpu.Device) callconv(.Inline) gpu.Buffer);
    // assertDecl(Impl, "deviceCreateErrorExternalTexture", fn (device: gpu.Device) callconv(.Inline) gpu.ExternalTexture);
    // assertDecl(Impl, "deviceCreateExternalTexture", fn (device: gpu.Device, external_texture_descriptor: *const gpu.ExternalTextureDescriptor) callconv(.Inline) gpu.ExternalTexture);
    // assertDecl(Impl, "deviceCreatePipelineLayout", fn (device: gpu.Device, pipeline_layout_descriptor: *const gpu.PipelineLayoutDescriptor) callconv(.Inline) gpu.PipelineLayout);
    // assertDecl(Impl, "deviceCreateQuerySet", fn (device: gpu.Device, descriptor: *const gpu.QuerySetDescriptor) callconv(.Inline) gpu.QuerySet);
    // assertDecl(Impl, "deviceCreateRenderBundleEncoder", fn (device: gpu.Device, descriptor: *const gpu.RenderBundleEncoderDescriptor) callconv(.Inline) gpu.RenderBundleEncoder);
    // assertDecl(Impl, "deviceCreateRenderPipeline", fn (device: gpu.Device, descriptor: *const gpu.RenderPipelineDescriptor) callconv(.Inline) gpu.RenderPipeline);
    // assertDecl(Impl, "deviceCreateRenderPipelineAsync", fn (device: gpu.Device, descriptor: *const gpu.RenderPipelineDescriptor, callback: gpu.CreateRenderPipelineAsyncCallback, userdata: *anyopaque) callconv(.Inline) void);
    // assertDecl(Impl, "deviceCreateRenderPipeline", fn (device: gpu.Device, descriptor: ?*const gpu.SamplerDescriptor) callconv(.Inline) gpu.Sampler);
    // assertDecl(Impl, "deviceCreateShaderModule", fn (device: gpu.Device, descriptor: *const gpu.ShaderModuleDescriptor) callconv(.Inline) gpu.ShaderModule);
    // assertDecl(Impl, "deviceCreateShaderModule", fn (device: gpu.Device, surface: ?Surface, descriptor: *const gpu.SwapChainDescriptor) callconv(.Inline) gpu.SwapChain);
    // assertDecl(Impl, "deviceCreateTexture", fn (device: gpu.Device, descriptor: *const gpu.TextureDescriptor) callconv(.Inline) gpu.Texture);
    // assertDecl(Impl, "deviceDestroy", fn (device: gpu.Device) callconv(.Inline) void);
    // assertDecl(Impl, "deviceEnumerateFeatures", fn (device: gpu.Device, features: [*]gpu.FeatureName) callconv(.Inline) usize);
    // assertDecl(Impl, "deviceGetLimits", fn (device: gpu.Device, limits: *gpu.SupportedLimits) callconv(.Inline) bool);
    // assertDecl(Impl, "deviceGetQueue", fn (device: gpu.Device) callconv(.Inline) gpu.Queue);
    // assertDecl(Impl, "deviceHasFeature", fn (device: gpu.Device, feature: gpu.FeatureName) callconv(.Inline) bool);
    // assertDecl(Impl, "deviceInjectError", fn (device: gpu.Device, typ: gpu.ErrorType, message: [*:0]const u8) callconv(.Inline) void);
    // assertDecl(Impl, "deviceLoseForTesting", fn (device: gpu.Device) callconv(.Inline) void);
    // assertDecl(Impl, "devicePopErrorScope", fn (device: gpu.Device, callback: gpu.ErrorCallback, userdata: *anyopaque) callconv(.Inline) bool);
    // assertDecl(Impl, "devicePushErrorScope", fn (device: gpu.Device, filter: gpu.ErrorFilter) callconv(.Inline) void);
    // assertDecl(Impl, "deviceSetDeviceLostCallback", fn (device: gpu.Device, callback: gpu.DeviceLostCallback, userdata: *anyopaque) callconv(.Inline) void);
    // assertDecl(Impl, "deviceSetLabel", fn (device: gpu.Device, label: [*:0]const u8) callconv(.Inline) void);
    // assertDecl(Impl, "deviceSetLoggingCallback", fn (device: gpu.Device, callback: gpu.LoggingCallback, userdata: *anyopaque) callconv(.Inline) void);
    // assertDecl(Impl, "deviceSetUncapturedErrorCallback", fn (device: gpu.Device, callback: gpu.ErrorCallback, userdata: *anyopaque) callconv(.Inline) void);
    // assertDecl(Impl, "deviceTick", fn (device: gpu.Device) callconv(.Inline) void);
    // assertDecl(Impl, "deviceReference", fn (device: gpu.Device) callconv(.Inline) void);
    // assertDecl(Impl, "deviceRelease", fn (device: gpu.Device) callconv(.Inline) void);
    // assertDecl(Impl, "externalTextureDestroy", fn (external_texture: gpu.ExternalTexture) callconv(.Inline) void);
    // assertDecl(Impl, "externalTextureSetLabel", fn (external_texture: gpu.ExternalTexture, label: [*:0]const u8) callconv(.Inline) void);
    // assertDecl(Impl, "externalTextureReference", fn (external_texture: gpu.ExternalTexture) callconv(.Inline) void);
    // assertDecl(Impl, "externalTextureRelease", fn (external_texture: gpu.ExternalTexture) callconv(.Inline) void);
    // assertDecl(Impl, "instanceCreateSurface", fn (instance: gpu.Instance, descriptor: *const gpu.SurfaceDescriptor) callconv(.Inline) gpu.Surface);
    // assertDecl(Impl, "instanceRequestAdapter", fn (instance: gpu.Instance, options: *const gpu.RequestAdapterOptions, callback: gpu.RequestAdapterCallback, userdata: *anyopaque) callconv(.Inline) void);
    // assertDecl(Impl, "instanceReference", fn (instance: gpu.Instance) callconv(.Inline) void);
    // assertDecl(Impl, "instanceRelease", fn (instance: gpu.Instance) callconv(.Inline) void);
    // assertDecl(Impl, "pipelineLayoutSetLabel", fn (pipeline_layout: gpu.PipelineLayout, label: [*:0]const u8) callconv(.Inline) void);
    // assertDecl(Impl, "pipelineLayoutReference", fn (pipeline_layout: gpu.PipelineLayout) callconv(.Inline) void);
    // assertDecl(Impl, "pipelineLayoutRelease", fn (pipeline_layout: gpu.PipelineLayout) callconv(.Inline) void);
    // assertDecl(Impl, "querySetDestroy", fn (query_set: gpu.QuerySet) callconv(.Inline) void);
    // assertDecl(Impl, "querySetGetCount", fn (query_set: gpu.QuerySet) callconv(.Inline) u32);
    // assertDecl(Impl, "querySetGetType", fn (query_set: gpu.QuerySet) callconv(.Inline) gpu.QueryType);
    // assertDecl(Impl, "querySetSetLabel", fn (query_set: gpu.QuerySet, label: [*:0]const u8) callconv(.Inline) void);
    // assertDecl(Impl, "querySetReference", fn (query_set: gpu.QuerySet) callconv(.Inline) void);
    // assertDecl(Impl, "querySetRelease", fn (query_set: gpu.QuerySet) callconv(.Inline) void);
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
    // assertDecl(Impl, "textureGetUsage", fn (texture: gpu.Texture) callconv(.Inline) gpu.TextureUsage);
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
    };
}

/// A no-operation gpu.Interface implementation.
pub const NullInterface = Interface(struct {
    pub inline fn createInstance(descriptor: *const InstanceDescriptor) ?Instance {
        _ = descriptor;
        return null;
    }

    pub inline fn getProcAddress(device: gpu.Device, proc_name: [*:0]const u8) ?gpu.Proc {
        _ = device;
        _ = proc_name;
        return null;
    }

    pub inline fn adapterCreateDevice(adapter: gpu.Adapter, descriptor: ?*const gpu.DeviceDescriptor) ?gpu.Device {
        _ = adapter;
        _ = descriptor;
        return null;
    }

    pub inline fn adapterEnumerateFeatures(adapter: gpu.Adapter, features: ?[*]gpu.FeatureName) usize {
        _ = adapter;
        _ = features;
        return 0;
    }

    pub inline fn adapterGetLimits(adapter: gpu.Adapter, limits: *gpu.SupportedLimits) bool {
        _ = adapter;
        _ = limits;
        return false;
    }

    pub inline fn adapterGetProperties(adapter: gpu.Adapter, properties: *gpu.AdapterProperties) void {
        _ = adapter;
        _ = properties;
    }

    pub inline fn adapterHasFeature(adapter: gpu.Adapter, feature: gpu.FeatureName) bool {
        _ = adapter;
        _ = feature;
        return false;
    }
});

test "null" {
    _ = Export(NullInterface);
}
