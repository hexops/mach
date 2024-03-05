const sysgpu = @import("main.zig");

/// The sysgpu.Interface implementation that is used by the entire program. Only one may exist, since
/// it is resolved fully at comptime with no vtable indirection, etc.
///
/// Depending on the implementation, it may need to be `.init()`ialized before use.
pub const Impl = blk: {
    if (@import("builtin").is_test) {
        break :blk StubInterface;
    } else {
        const root = @import("root");
        if (!@hasDecl(root, "SYSGPUInterface")) @compileError("expected to find `pub const SYSGPUInterface = T;` in root file");
        _ = sysgpu.Interface(root.SYSGPUInterface); // verify the type
        break :blk root.SYSGPUInterface;
    }
};

/// Verifies that a sysgpu.Interface implementation exposes the expected function declarations.
pub fn Interface(comptime T: type) type {
    // sysgpu.Device
    assertDecl(T, "deviceCreateRenderPipeline", fn (device: *sysgpu.Device, descriptor: *const sysgpu.RenderPipeline.Descriptor) callconv(.Inline) *sysgpu.RenderPipeline);
    assertDecl(T, "deviceCreateRenderPipelineAsync", fn (device: *sysgpu.Device, descriptor: *const sysgpu.RenderPipeline.Descriptor, callback: sysgpu.CreateRenderPipelineAsyncCallback, userdata: ?*anyopaque) callconv(.Inline) void);
    assertDecl(T, "deviceCreatePipelineLayout", fn (device: *sysgpu.Device, pipeline_layout_descriptor: *const sysgpu.PipelineLayout.Descriptor) callconv(.Inline) *sysgpu.PipelineLayout);

    // sysgpu.PipelineLayout
    assertDecl(T, "pipelineLayoutSetLabel", fn (pipeline_layout: *sysgpu.PipelineLayout, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "pipelineLayoutReference", fn (pipeline_layout: *sysgpu.PipelineLayout) callconv(.Inline) void);
    assertDecl(T, "pipelineLayoutRelease", fn (pipeline_layout: *sysgpu.PipelineLayout) callconv(.Inline) void);

    // sysgpu.RenderBundleEncoder
    assertDecl(T, "renderBundleEncoderSetPipeline", fn (render_bundle_encoder: *sysgpu.RenderBundleEncoder, pipeline: *sysgpu.RenderPipeline) callconv(.Inline) void);
    assertDecl(T, "renderBundleEncoderSetBindGroup", fn (render_bundle_encoder: *sysgpu.RenderBundleEncoder, group_index: u32, group: *sysgpu.BindGroup, dynamic_offset_count: usize, dynamic_offsets: ?[*]const u32) callconv(.Inline) void);

    // sysgpu.RenderPassEncoder
    assertDecl(T, "renderPassEncoderSetPipeline", fn (render_pass_encoder: *sysgpu.RenderPassEncoder, pipeline: *sysgpu.RenderPipeline) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderSetBindGroup", fn (render_pass_encoder: *sysgpu.RenderPassEncoder, group_index: u32, group: *sysgpu.BindGroup, dynamic_offset_count: usize, dynamic_offsets: ?[*]const u32) callconv(.Inline) void);

    // sysgpu.BindGroup
    assertDecl(T, "bindGroupSetLabel", fn (bind_group: *sysgpu.BindGroup, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "bindGroupReference", fn (bind_group: *sysgpu.BindGroup) callconv(.Inline) void);
    assertDecl(T, "bindGroupRelease", fn (bind_group: *sysgpu.BindGroup) callconv(.Inline) void);

    // sysgpu.BindGroupLayout
    assertDecl(T, "bindGroupLayoutSetLabel", fn (bind_group_layout: *sysgpu.BindGroupLayout, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "bindGroupLayoutReference", fn (bind_group_layout: *sysgpu.BindGroupLayout) callconv(.Inline) void);
    assertDecl(T, "bindGroupLayoutRelease", fn (bind_group_layout: *sysgpu.BindGroupLayout) callconv(.Inline) void);

    // sysgpu.RenderPipeline
    assertDecl(T, "renderPipelineGetBindGroupLayout", fn (render_pipeline: *sysgpu.RenderPipeline, group_index: u32) callconv(.Inline) *sysgpu.BindGroupLayout);
    assertDecl(T, "renderPipelineSetLabel", fn (render_pipeline: *sysgpu.RenderPipeline, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "renderPipelineReference", fn (render_pipeline: *sysgpu.RenderPipeline) callconv(.Inline) void);
    assertDecl(T, "renderPipelineRelease", fn (render_pipeline: *sysgpu.RenderPipeline) callconv(.Inline) void);

    // sysgpu.Instance
    assertDecl(T, "createInstance", fn (descriptor: ?*const sysgpu.Instance.Descriptor) callconv(.Inline) ?*sysgpu.Instance);

    // sysgpu.Adapter
    assertDecl(T, "adapterCreateDevice", fn (adapter: *sysgpu.Adapter, descriptor: ?*const sysgpu.Device.Descriptor) callconv(.Inline) ?*sysgpu.Device);
    assertDecl(T, "adapterEnumerateFeatures", fn (adapter: *sysgpu.Adapter, features: ?[*]sysgpu.FeatureName) callconv(.Inline) usize);
    assertDecl(T, "adapterGetInstance", fn (adapter: *sysgpu.Adapter) callconv(.Inline) *sysgpu.Instance);
    assertDecl(T, "adapterGetLimits", fn (adapter: *sysgpu.Adapter, limits: *sysgpu.SupportedLimits) callconv(.Inline) u32);
    assertDecl(T, "adapterGetProperties", fn (adapter: *sysgpu.Adapter, properties: *sysgpu.Adapter.Properties) callconv(.Inline) void);
    assertDecl(T, "adapterHasFeature", fn (adapter: *sysgpu.Adapter, feature: sysgpu.FeatureName) callconv(.Inline) u32);
    assertDecl(T, "adapterPropertiesFreeMembers", fn (value: sysgpu.Adapter.Properties) callconv(.Inline) void);
    assertDecl(T, "adapterRequestDevice", fn (adapter: *sysgpu.Adapter, descriptor: ?*const sysgpu.Device.Descriptor, callback: sysgpu.RequestDeviceCallback, userdata: ?*anyopaque) callconv(.Inline) void);
    assertDecl(T, "adapterReference", fn (adapter: *sysgpu.Adapter) callconv(.Inline) void);
    assertDecl(T, "adapterRelease", fn (adapter: *sysgpu.Adapter) callconv(.Inline) void);

    // sysgpu.Buffer
    assertDecl(T, "bufferDestroy", fn (buffer: *sysgpu.Buffer) callconv(.Inline) void);
    assertDecl(T, "bufferGetConstMappedRange", fn (buffer: *sysgpu.Buffer, offset: usize, size: usize) callconv(.Inline) ?*const anyopaque);
    assertDecl(T, "bufferGetMappedRange", fn (buffer: *sysgpu.Buffer, offset: usize, size: usize) callconv(.Inline) ?*anyopaque);
    assertDecl(T, "bufferGetSize", fn (buffer: *sysgpu.Buffer) callconv(.Inline) u64);
    assertDecl(T, "bufferGetUsage", fn (buffer: *sysgpu.Buffer) callconv(.Inline) sysgpu.Buffer.UsageFlags);
    assertDecl(T, "bufferMapAsync", fn (buffer: *sysgpu.Buffer, mode: sysgpu.MapModeFlags, offset: usize, size: usize, callback: sysgpu.Buffer.MapCallback, userdata: ?*anyopaque) callconv(.Inline) void);
    assertDecl(T, "bufferSetLabel", fn (buffer: *sysgpu.Buffer, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "bufferUnmap", fn (buffer: *sysgpu.Buffer) callconv(.Inline) void);
    assertDecl(T, "bufferReference", fn (buffer: *sysgpu.Buffer) callconv(.Inline) void);
    assertDecl(T, "bufferRelease", fn (buffer: *sysgpu.Buffer) callconv(.Inline) void);

    // sysgpu.CommandBuffer
    assertDecl(T, "commandBufferSetLabel", fn (command_buffer: *sysgpu.CommandBuffer, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "commandBufferReference", fn (command_buffer: *sysgpu.CommandBuffer) callconv(.Inline) void);
    assertDecl(T, "commandBufferRelease", fn (command_buffer: *sysgpu.CommandBuffer) callconv(.Inline) void);

    // sysgpu.CommandEncoder
    assertDecl(T, "commandEncoderBeginComputePass", fn (command_encoder: *sysgpu.CommandEncoder, descriptor: ?*const sysgpu.ComputePassDescriptor) callconv(.Inline) *sysgpu.ComputePassEncoder);
    assertDecl(T, "commandEncoderBeginRenderPass", fn (command_encoder: *sysgpu.CommandEncoder, descriptor: *const sysgpu.RenderPassDescriptor) callconv(.Inline) *sysgpu.RenderPassEncoder);
    assertDecl(T, "commandEncoderClearBuffer", fn (command_encoder: *sysgpu.CommandEncoder, buffer: *sysgpu.Buffer, offset: u64, size: u64) callconv(.Inline) void);
    assertDecl(T, "commandEncoderCopyBufferToBuffer", fn (command_encoder: *sysgpu.CommandEncoder, source: *sysgpu.Buffer, source_offset: u64, destination: *sysgpu.Buffer, destination_offset: u64, size: u64) callconv(.Inline) void);
    assertDecl(T, "commandEncoderCopyBufferToTexture", fn (command_encoder: *sysgpu.CommandEncoder, source: *const sysgpu.ImageCopyBuffer, destination: *const sysgpu.ImageCopyTexture, copy_size: *const sysgpu.Extent3D) callconv(.Inline) void);
    assertDecl(T, "commandEncoderCopyTextureToBuffer", fn (command_encoder: *sysgpu.CommandEncoder, source: *const sysgpu.ImageCopyTexture, destination: *const sysgpu.ImageCopyBuffer, copy_size: *const sysgpu.Extent3D) callconv(.Inline) void);
    assertDecl(T, "commandEncoderCopyTextureToTexture", fn (command_encoder: *sysgpu.CommandEncoder, source: *const sysgpu.ImageCopyTexture, destination: *const sysgpu.ImageCopyTexture, copy_size: *const sysgpu.Extent3D) callconv(.Inline) void);
    assertDecl(T, "commandEncoderFinish", fn (command_encoder: *sysgpu.CommandEncoder, descriptor: ?*const sysgpu.CommandBuffer.Descriptor) callconv(.Inline) *sysgpu.CommandBuffer);
    assertDecl(T, "commandEncoderInjectValidationError", fn (command_encoder: *sysgpu.CommandEncoder, message: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "commandEncoderInsertDebugMarker", fn (command_encoder: *sysgpu.CommandEncoder, marker_label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "commandEncoderPopDebugGroup", fn (command_encoder: *sysgpu.CommandEncoder) callconv(.Inline) void);
    assertDecl(T, "commandEncoderPushDebugGroup", fn (command_encoder: *sysgpu.CommandEncoder, group_label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "commandEncoderResolveQuerySet", fn (command_encoder: *sysgpu.CommandEncoder, query_set: *sysgpu.QuerySet, first_query: u32, query_count: u32, destination: *sysgpu.Buffer, destination_offset: u64) callconv(.Inline) void);
    assertDecl(T, "commandEncoderSetLabel", fn (command_encoder: *sysgpu.CommandEncoder, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "commandEncoderWriteBuffer", fn (command_encoder: *sysgpu.CommandEncoder, buffer: *sysgpu.Buffer, buffer_offset: u64, data: [*]const u8, size: u64) callconv(.Inline) void);
    assertDecl(T, "commandEncoderWriteTimestamp", fn (command_encoder: *sysgpu.CommandEncoder, query_set: *sysgpu.QuerySet, query_index: u32) callconv(.Inline) void);
    assertDecl(T, "commandEncoderReference", fn (command_encoder: *sysgpu.CommandEncoder) callconv(.Inline) void);
    assertDecl(T, "commandEncoderRelease", fn (command_encoder: *sysgpu.CommandEncoder) callconv(.Inline) void);

    // sysgpu.ComputePassEncoder
    assertDecl(T, "computePassEncoderDispatchWorkgroups", fn (compute_pass_encoder: *sysgpu.ComputePassEncoder, workgroup_count_x: u32, workgroup_count_y: u32, workgroup_count_z: u32) callconv(.Inline) void);
    assertDecl(T, "computePassEncoderDispatchWorkgroupsIndirect", fn (compute_pass_encoder: *sysgpu.ComputePassEncoder, indirect_buffer: *sysgpu.Buffer, indirect_offset: u64) callconv(.Inline) void);
    assertDecl(T, "computePassEncoderEnd", fn (compute_pass_encoder: *sysgpu.ComputePassEncoder) callconv(.Inline) void);
    assertDecl(T, "computePassEncoderInsertDebugMarker", fn (compute_pass_encoder: *sysgpu.ComputePassEncoder, marker_label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "computePassEncoderPopDebugGroup", fn (compute_pass_encoder: *sysgpu.ComputePassEncoder) callconv(.Inline) void);
    assertDecl(T, "computePassEncoderPushDebugGroup", fn (compute_pass_encoder: *sysgpu.ComputePassEncoder, group_label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "computePassEncoderSetBindGroup", fn (compute_pass_encoder: *sysgpu.ComputePassEncoder, group_index: u32, group: *sysgpu.BindGroup, dynamic_offset_count: usize, dynamic_offsets: ?[*]const u32) callconv(.Inline) void);
    assertDecl(T, "computePassEncoderSetLabel", fn (compute_pass_encoder: *sysgpu.ComputePassEncoder, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "computePassEncoderSetPipeline", fn (compute_pass_encoder: *sysgpu.ComputePassEncoder, pipeline: *sysgpu.ComputePipeline) callconv(.Inline) void);
    assertDecl(T, "computePassEncoderWriteTimestamp", fn (compute_pass_encoder: *sysgpu.ComputePassEncoder, query_set: *sysgpu.QuerySet, query_index: u32) callconv(.Inline) void);
    assertDecl(T, "computePassEncoderReference", fn (compute_pass_encoder: *sysgpu.ComputePassEncoder) callconv(.Inline) void);
    assertDecl(T, "computePassEncoderRelease", fn (compute_pass_encoder: *sysgpu.ComputePassEncoder) callconv(.Inline) void);

    // sysgpu.ComputePipeline
    assertDecl(T, "computePipelineGetBindGroupLayout", fn (compute_pipeline: *sysgpu.ComputePipeline, group_index: u32) callconv(.Inline) *sysgpu.BindGroupLayout);
    assertDecl(T, "computePipelineSetLabel", fn (compute_pipeline: *sysgpu.ComputePipeline, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "computePipelineReference", fn (compute_pipeline: *sysgpu.ComputePipeline) callconv(.Inline) void);
    assertDecl(T, "computePipelineRelease", fn (compute_pipeline: *sysgpu.ComputePipeline) callconv(.Inline) void);

    // sysgpu.Device
    assertDecl(T, "getProcAddress", fn (device: *sysgpu.Device, proc_name: [*:0]const u8) callconv(.Inline) ?sysgpu.Proc);
    assertDecl(T, "deviceCreateBindGroup", fn (device: *sysgpu.Device, descriptor: *const sysgpu.BindGroup.Descriptor) callconv(.Inline) *sysgpu.BindGroup);
    assertDecl(T, "deviceCreateBindGroupLayout", fn (device: *sysgpu.Device, descriptor: *const sysgpu.BindGroupLayout.Descriptor) callconv(.Inline) *sysgpu.BindGroupLayout);
    assertDecl(T, "deviceCreateBuffer", fn (device: *sysgpu.Device, descriptor: *const sysgpu.Buffer.Descriptor) callconv(.Inline) *sysgpu.Buffer);
    assertDecl(T, "deviceCreateCommandEncoder", fn (device: *sysgpu.Device, descriptor: ?*const sysgpu.CommandEncoder.Descriptor) callconv(.Inline) *sysgpu.CommandEncoder);
    assertDecl(T, "deviceCreateComputePipeline", fn (device: *sysgpu.Device, descriptor: *const sysgpu.ComputePipeline.Descriptor) callconv(.Inline) *sysgpu.ComputePipeline);
    assertDecl(T, "deviceCreateComputePipelineAsync", fn (device: *sysgpu.Device, descriptor: *const sysgpu.ComputePipeline.Descriptor, callback: sysgpu.CreateComputePipelineAsyncCallback, userdata: ?*anyopaque) callconv(.Inline) void);
    assertDecl(T, "deviceCreateErrorBuffer", fn (device: *sysgpu.Device, descriptor: *const sysgpu.Buffer.Descriptor) callconv(.Inline) *sysgpu.Buffer);
    assertDecl(T, "deviceCreateErrorExternalTexture", fn (device: *sysgpu.Device) callconv(.Inline) *sysgpu.ExternalTexture);
    assertDecl(T, "deviceCreateErrorTexture", fn (device: *sysgpu.Device, descriptor: *const sysgpu.Texture.Descriptor) callconv(.Inline) *sysgpu.Texture);
    assertDecl(T, "deviceCreateExternalTexture", fn (device: *sysgpu.Device, external_texture_descriptor: *const sysgpu.ExternalTexture.Descriptor) callconv(.Inline) *sysgpu.ExternalTexture);
    assertDecl(T, "deviceCreateQuerySet", fn (device: *sysgpu.Device, descriptor: *const sysgpu.QuerySet.Descriptor) callconv(.Inline) *sysgpu.QuerySet);
    assertDecl(T, "deviceCreateRenderBundleEncoder", fn (device: *sysgpu.Device, descriptor: *const sysgpu.RenderBundleEncoder.Descriptor) callconv(.Inline) *sysgpu.RenderBundleEncoder);
    // TODO(self-hosted): this cannot be marked as inline for some reason:
    // https://github.com/ziglang/zig/issues/12545
    assertDecl(T, "deviceCreateSampler", fn (device: *sysgpu.Device, descriptor: ?*const sysgpu.Sampler.Descriptor) callconv(.Inline) *sysgpu.Sampler);
    assertDecl(T, "deviceCreateShaderModule", fn (device: *sysgpu.Device, descriptor: *const sysgpu.ShaderModule.Descriptor) callconv(.Inline) *sysgpu.ShaderModule);
    assertDecl(T, "deviceCreateSwapChain", fn (device: *sysgpu.Device, surface: ?*sysgpu.Surface, descriptor: *const sysgpu.SwapChain.Descriptor) callconv(.Inline) *sysgpu.SwapChain);
    assertDecl(T, "deviceCreateTexture", fn (device: *sysgpu.Device, descriptor: *const sysgpu.Texture.Descriptor) callconv(.Inline) *sysgpu.Texture);
    assertDecl(T, "deviceDestroy", fn (device: *sysgpu.Device) callconv(.Inline) void);
    assertDecl(T, "deviceEnumerateFeatures", fn (device: *sysgpu.Device, features: ?[*]sysgpu.FeatureName) callconv(.Inline) usize);
    assertDecl(T, "deviceGetLimits", fn (device: *sysgpu.Device, limits: *sysgpu.SupportedLimits) callconv(.Inline) u32);
    assertDecl(T, "deviceGetQueue", fn (device: *sysgpu.Device) callconv(.Inline) *sysgpu.Queue);
    assertDecl(T, "deviceHasFeature", fn (device: *sysgpu.Device, feature: sysgpu.FeatureName) callconv(.Inline) u32);
    assertDecl(T, "deviceImportSharedFence", fn (device: *sysgpu.Device, descriptor: *const sysgpu.SharedFence.Descriptor) callconv(.Inline) *sysgpu.SharedFence);
    assertDecl(T, "deviceImportSharedTextureMemory", fn (device: *sysgpu.Device, descriptor: *const sysgpu.SharedTextureMemory.Descriptor) callconv(.Inline) *sysgpu.SharedTextureMemory);
    assertDecl(T, "deviceInjectError", fn (device: *sysgpu.Device, typ: sysgpu.ErrorType, message: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "devicePopErrorScope", fn (device: *sysgpu.Device, callback: sysgpu.ErrorCallback, userdata: ?*anyopaque) callconv(.Inline) void);
    assertDecl(T, "devicePushErrorScope", fn (device: *sysgpu.Device, filter: sysgpu.ErrorFilter) callconv(.Inline) void);
    assertDecl(T, "deviceSetDeviceLostCallback", fn (device: *sysgpu.Device, callback: ?sysgpu.Device.LostCallback, userdata: ?*anyopaque) callconv(.Inline) void);
    assertDecl(T, "deviceSetLabel", fn (device: *sysgpu.Device, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "deviceSetLoggingCallback", fn (device: *sysgpu.Device, callback: ?sysgpu.LoggingCallback, userdata: ?*anyopaque) callconv(.Inline) void);
    assertDecl(T, "deviceSetUncapturedErrorCallback", fn (device: *sysgpu.Device, callback: ?sysgpu.ErrorCallback, userdata: ?*anyopaque) callconv(.Inline) void);
    assertDecl(T, "deviceTick", fn (device: *sysgpu.Device) callconv(.Inline) void);
    assertDecl(T, "machDeviceWaitForCommandsToBeScheduled", fn (device: *sysgpu.Device) callconv(.Inline) void);
    assertDecl(T, "deviceReference", fn (device: *sysgpu.Device) callconv(.Inline) void);
    assertDecl(T, "deviceRelease", fn (device: *sysgpu.Device) callconv(.Inline) void);

    // sysgpu.ExternalTexture
    assertDecl(T, "externalTextureDestroy", fn (external_texture: *sysgpu.ExternalTexture) callconv(.Inline) void);
    assertDecl(T, "externalTextureSetLabel", fn (external_texture: *sysgpu.ExternalTexture, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "externalTextureReference", fn (external_texture: *sysgpu.ExternalTexture) callconv(.Inline) void);
    assertDecl(T, "externalTextureRelease", fn (external_texture: *sysgpu.ExternalTexture) callconv(.Inline) void);

    // sysgpu.Instance
    assertDecl(T, "instanceCreateSurface", fn (instance: *sysgpu.Instance, descriptor: *const sysgpu.Surface.Descriptor) callconv(.Inline) *sysgpu.Surface);
    assertDecl(T, "instanceProcessEvents", fn (instance: *sysgpu.Instance) callconv(.Inline) void);
    assertDecl(T, "instanceRequestAdapter", fn (instance: *sysgpu.Instance, options: ?*const sysgpu.RequestAdapterOptions, callback: sysgpu.RequestAdapterCallback, userdata: ?*anyopaque) callconv(.Inline) void);
    assertDecl(T, "instanceReference", fn (instance: *sysgpu.Instance) callconv(.Inline) void);
    assertDecl(T, "instanceRelease", fn (instance: *sysgpu.Instance) callconv(.Inline) void);

    // sysgpu.QuerySet
    assertDecl(T, "querySetDestroy", fn (query_set: *sysgpu.QuerySet) callconv(.Inline) void);
    assertDecl(T, "querySetGetCount", fn (query_set: *sysgpu.QuerySet) callconv(.Inline) u32);
    assertDecl(T, "querySetGetType", fn (query_set: *sysgpu.QuerySet) callconv(.Inline) sysgpu.QueryType);
    assertDecl(T, "querySetSetLabel", fn (query_set: *sysgpu.QuerySet, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "querySetReference", fn (query_set: *sysgpu.QuerySet) callconv(.Inline) void);
    assertDecl(T, "querySetRelease", fn (query_set: *sysgpu.QuerySet) callconv(.Inline) void);

    // sysgpu.Queue
    assertDecl(T, "queueCopyTextureForBrowser", fn (queue: *sysgpu.Queue, source: *const sysgpu.ImageCopyTexture, destination: *const sysgpu.ImageCopyTexture, copy_size: *const sysgpu.Extent3D, options: *const sysgpu.CopyTextureForBrowserOptions) callconv(.Inline) void);
    assertDecl(T, "queueOnSubmittedWorkDone", fn (queue: *sysgpu.Queue, signal_value: u64, callback: sysgpu.Queue.WorkDoneCallback, userdata: ?*anyopaque) callconv(.Inline) void);
    assertDecl(T, "queueSetLabel", fn (queue: *sysgpu.Queue, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "queueSubmit", fn (queue: *sysgpu.Queue, command_count: usize, commands: [*]const *const sysgpu.CommandBuffer) callconv(.Inline) void);
    assertDecl(T, "queueWriteBuffer", fn (queue: *sysgpu.Queue, buffer: *sysgpu.Buffer, buffer_offset: u64, data: *const anyopaque, size: usize) callconv(.Inline) void);
    assertDecl(T, "queueWriteTexture", fn (queue: *sysgpu.Queue, destination: *const sysgpu.ImageCopyTexture, data: *const anyopaque, data_size: usize, data_layout: *const sysgpu.Texture.DataLayout, write_size: *const sysgpu.Extent3D) callconv(.Inline) void);
    assertDecl(T, "queueReference", fn (queue: *sysgpu.Queue) callconv(.Inline) void);
    assertDecl(T, "queueRelease", fn (queue: *sysgpu.Queue) callconv(.Inline) void);

    // sysgpu.RenderBundle
    assertDecl(T, "renderBundleSetLabel", fn (render_bundle: *sysgpu.RenderBundle, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "renderBundleReference", fn (render_bundle: *sysgpu.RenderBundle) callconv(.Inline) void);
    assertDecl(T, "renderBundleRelease", fn (render_bundle: *sysgpu.RenderBundle) callconv(.Inline) void);

    // sysgpu.RenderBundleEncoder
    assertDecl(T, "renderBundleEncoderDraw", fn (render_bundle_encoder: *sysgpu.RenderBundleEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) callconv(.Inline) void);
    assertDecl(T, "renderBundleEncoderDrawIndexed", fn (render_bundle_encoder: *sysgpu.RenderBundleEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: i32, first_instance: u32) callconv(.Inline) void);
    assertDecl(T, "renderBundleEncoderDrawIndexedIndirect", fn (render_bundle_encoder: *sysgpu.RenderBundleEncoder, indirect_buffer: *sysgpu.Buffer, indirect_offset: u64) callconv(.Inline) void);
    assertDecl(T, "renderBundleEncoderDrawIndirect", fn (render_bundle_encoder: *sysgpu.RenderBundleEncoder, indirect_buffer: *sysgpu.Buffer, indirect_offset: u64) callconv(.Inline) void);
    assertDecl(T, "renderBundleEncoderFinish", fn (render_bundle_encoder: *sysgpu.RenderBundleEncoder, descriptor: ?*const sysgpu.RenderBundle.Descriptor) callconv(.Inline) *sysgpu.RenderBundle);
    assertDecl(T, "renderBundleEncoderInsertDebugMarker", fn (render_bundle_encoder: *sysgpu.RenderBundleEncoder, marker_label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "renderBundleEncoderPopDebugGroup", fn (render_bundle_encoder: *sysgpu.RenderBundleEncoder) callconv(.Inline) void);
    assertDecl(T, "renderBundleEncoderPushDebugGroup", fn (render_bundle_encoder: *sysgpu.RenderBundleEncoder, group_label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "renderBundleEncoderSetIndexBuffer", fn (render_bundle_encoder: *sysgpu.RenderBundleEncoder, buffer: *sysgpu.Buffer, format: sysgpu.IndexFormat, offset: u64, size: u64) callconv(.Inline) void);
    assertDecl(T, "renderBundleEncoderSetLabel", fn (render_bundle_encoder: *sysgpu.RenderBundleEncoder, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "renderBundleEncoderSetVertexBuffer", fn (render_bundle_encoder: *sysgpu.RenderBundleEncoder, slot: u32, buffer: *sysgpu.Buffer, offset: u64, size: u64) callconv(.Inline) void);
    assertDecl(T, "renderBundleEncoderReference", fn (render_bundle_encoder: *sysgpu.RenderBundleEncoder) callconv(.Inline) void);
    assertDecl(T, "renderBundleEncoderRelease", fn (render_bundle_encoder: *sysgpu.RenderBundleEncoder) callconv(.Inline) void);

    // sysgpu.RenderPassEncoder
    assertDecl(T, "renderPassEncoderBeginOcclusionQuery", fn (render_pass_encoder: *sysgpu.RenderPassEncoder, query_index: u32) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderDraw", fn (render_pass_encoder: *sysgpu.RenderPassEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderDrawIndexed", fn (render_pass_encoder: *sysgpu.RenderPassEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: i32, first_instance: u32) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderDrawIndexedIndirect", fn (render_pass_encoder: *sysgpu.RenderPassEncoder, indirect_buffer: *sysgpu.Buffer, indirect_offset: u64) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderDrawIndirect", fn (render_pass_encoder: *sysgpu.RenderPassEncoder, indirect_buffer: *sysgpu.Buffer, indirect_offset: u64) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderEnd", fn (render_pass_encoder: *sysgpu.RenderPassEncoder) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderEndOcclusionQuery", fn (render_pass_encoder: *sysgpu.RenderPassEncoder) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderExecuteBundles", fn (render_pass_encoder: *sysgpu.RenderPassEncoder, bundles_count: usize, bundles: [*]const *const sysgpu.RenderBundle) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderInsertDebugMarker", fn (render_pass_encoder: *sysgpu.RenderPassEncoder, marker_label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderPopDebugGroup", fn (render_pass_encoder: *sysgpu.RenderPassEncoder) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderPushDebugGroup", fn (render_pass_encoder: *sysgpu.RenderPassEncoder, group_label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderSetBlendConstant", fn (render_pass_encoder: *sysgpu.RenderPassEncoder, color: *const sysgpu.Color) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderSetIndexBuffer", fn (render_pass_encoder: *sysgpu.RenderPassEncoder, buffer: *sysgpu.Buffer, format: sysgpu.IndexFormat, offset: u64, size: u64) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderSetLabel", fn (render_pass_encoder: *sysgpu.RenderPassEncoder, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderSetScissorRect", fn (render_pass_encoder: *sysgpu.RenderPassEncoder, x: u32, y: u32, width: u32, height: u32) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderSetStencilReference", fn (render_pass_encoder: *sysgpu.RenderPassEncoder, reference: u32) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderSetVertexBuffer", fn (render_pass_encoder: *sysgpu.RenderPassEncoder, slot: u32, buffer: *sysgpu.Buffer, offset: u64, size: u64) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderSetViewport", fn (render_pass_encoder: *sysgpu.RenderPassEncoder, x: f32, y: f32, width: f32, height: f32, min_depth: f32, max_depth: f32) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderWriteTimestamp", fn (render_pass_encoder: *sysgpu.RenderPassEncoder, query_set: *sysgpu.QuerySet, query_index: u32) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderReference", fn (render_pass_encoder: *sysgpu.RenderPassEncoder) callconv(.Inline) void);
    assertDecl(T, "renderPassEncoderRelease", fn (render_pass_encoder: *sysgpu.RenderPassEncoder) callconv(.Inline) void);

    // sysgpu.Sampler
    assertDecl(T, "samplerSetLabel", fn (sampler: *sysgpu.Sampler, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "samplerReference", fn (sampler: *sysgpu.Sampler) callconv(.Inline) void);
    assertDecl(T, "samplerRelease", fn (sampler: *sysgpu.Sampler) callconv(.Inline) void);

    // sysgpu.ShaderModule
    assertDecl(T, "shaderModuleGetCompilationInfo", fn (shader_module: *sysgpu.ShaderModule, callback: sysgpu.CompilationInfoCallback, userdata: ?*anyopaque) callconv(.Inline) void);
    assertDecl(T, "shaderModuleSetLabel", fn (shader_module: *sysgpu.ShaderModule, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "shaderModuleReference", fn (shader_module: *sysgpu.ShaderModule) callconv(.Inline) void);
    assertDecl(T, "shaderModuleRelease", fn (shader_module: *sysgpu.ShaderModule) callconv(.Inline) void);

    // sysgpu.SharedFence
    assertDecl(T, "sharedFenceExportInfo", fn (shared_fence: *sysgpu.SharedFence, info: *sysgpu.SharedFence.ExportInfo) callconv(.Inline) void);
    assertDecl(T, "sharedFenceReference", fn (shared_fence: *sysgpu.SharedFence) callconv(.Inline) void);
    assertDecl(T, "sharedFenceRelease", fn (shared_fence: *sysgpu.SharedFence) callconv(.Inline) void);

    // sysgpu.SharedTextureMemory
    assertDecl(T, "sharedTextureMemoryBeginAccess", fn (shared_texture_memory: *sysgpu.SharedTextureMemory, texture: *sysgpu.Texture, descriptor: *const sysgpu.SharedTextureMemory.BeginAccessDescriptor) callconv(.Inline) void);
    assertDecl(T, "sharedTextureMemoryCreateTexture", fn (shared_texture_memory: *sysgpu.SharedTextureMemory, descriptor: *const sysgpu.Texture.Descriptor) callconv(.Inline) *sysgpu.Texture);
    assertDecl(T, "sharedTextureMemoryEndAccess", fn (shared_texture_memory: *sysgpu.SharedTextureMemory, texture: *sysgpu.Texture, descriptor: *sysgpu.SharedTextureMemory.EndAccessState) callconv(.Inline) void);
    assertDecl(T, "sharedTextureMemoryEndAccessStateFreeMembers", fn (value: sysgpu.SharedTextureMemory.EndAccessState) callconv(.Inline) void);
    assertDecl(T, "sharedTextureMemoryGetProperties", fn (shared_texture_memory: *sysgpu.SharedTextureMemory, properties: *sysgpu.SharedTextureMemory.Properties) callconv(.Inline) void);
    assertDecl(T, "sharedTextureMemorySetLabel", fn (shared_texture_memory: *sysgpu.SharedTextureMemory, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "sharedTextureMemoryReference", fn (shared_texture_memory: *sysgpu.SharedTextureMemory) callconv(.Inline) void);
    assertDecl(T, "sharedTextureMemoryRelease", fn (shared_texture_memory: *sysgpu.SharedTextureMemory) callconv(.Inline) void);

    // sysgpu.Surface
    assertDecl(T, "surfaceReference", fn (surface: *sysgpu.Surface) callconv(.Inline) void);
    assertDecl(T, "surfaceRelease", fn (surface: *sysgpu.Surface) callconv(.Inline) void);

    // sysgpu.SwapChain
    assertDecl(T, "swapChainGetCurrentTexture", fn (swap_chain: *sysgpu.SwapChain) callconv(.Inline) ?*sysgpu.Texture);
    assertDecl(T, "swapChainGetCurrentTextureView", fn (swap_chain: *sysgpu.SwapChain) callconv(.Inline) ?*sysgpu.TextureView);
    assertDecl(T, "swapChainPresent", fn (swap_chain: *sysgpu.SwapChain) callconv(.Inline) void);
    assertDecl(T, "swapChainReference", fn (swap_chain: *sysgpu.SwapChain) callconv(.Inline) void);
    assertDecl(T, "swapChainRelease", fn (swap_chain: *sysgpu.SwapChain) callconv(.Inline) void);

    // sysgpu.Texture
    assertDecl(T, "textureCreateView", fn (texture: *sysgpu.Texture, descriptor: ?*const sysgpu.TextureView.Descriptor) callconv(.Inline) *sysgpu.TextureView);
    assertDecl(T, "textureDestroy", fn (texture: *sysgpu.Texture) callconv(.Inline) void);
    assertDecl(T, "textureGetDepthOrArrayLayers", fn (texture: *sysgpu.Texture) callconv(.Inline) u32);
    assertDecl(T, "textureGetDimension", fn (texture: *sysgpu.Texture) callconv(.Inline) sysgpu.Texture.Dimension);
    assertDecl(T, "textureGetFormat", fn (texture: *sysgpu.Texture) callconv(.Inline) sysgpu.Texture.Format);
    assertDecl(T, "textureGetHeight", fn (texture: *sysgpu.Texture) callconv(.Inline) u32);
    assertDecl(T, "textureGetMipLevelCount", fn (texture: *sysgpu.Texture) callconv(.Inline) u32);
    assertDecl(T, "textureGetSampleCount", fn (texture: *sysgpu.Texture) callconv(.Inline) u32);
    assertDecl(T, "textureGetUsage", fn (texture: *sysgpu.Texture) callconv(.Inline) sysgpu.Texture.UsageFlags);
    assertDecl(T, "textureGetWidth", fn (texture: *sysgpu.Texture) callconv(.Inline) u32);
    assertDecl(T, "textureSetLabel", fn (texture: *sysgpu.Texture, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "textureReference", fn (texture: *sysgpu.Texture) callconv(.Inline) void);
    assertDecl(T, "textureRelease", fn (texture: *sysgpu.Texture) callconv(.Inline) void);
    assertDecl(T, "textureViewSetLabel", fn (texture_view: *sysgpu.TextureView, label: [*:0]const u8) callconv(.Inline) void);
    assertDecl(T, "textureViewReference", fn (texture_view: *sysgpu.TextureView) callconv(.Inline) void);
    assertDecl(T, "textureViewRelease", fn (texture_view: *sysgpu.TextureView) callconv(.Inline) void);
    return T;
}

fn assertDecl(comptime T: anytype, comptime name: []const u8, comptime Decl: type) void {
    if (!@hasDecl(T, name)) @compileError("sysgpu.Interface missing declaration: " ++ @typeName(Decl));
    const FoundDecl = @TypeOf(@field(T, name));
    if (FoundDecl != Decl) @compileError("sysgpu.Interface field '" ++ name ++ "'\n\texpected type: " ++ @typeName(Decl) ++ "\n\t   found type: " ++ @typeName(FoundDecl));
}

/// Exports C ABI function declarations for the given sysgpu.Interface implementation.
pub fn Export(comptime T: type) type {
    _ = Interface(T); // verify implementation is a valid interface
    return struct {
        // SYSGPU_EXPORT WGPUInstance sysgpuCreateInstance(WGPUInstanceDescriptor const * descriptor);
        export fn sysgpuCreateInstance(descriptor: ?*const sysgpu.Instance.Descriptor) ?*sysgpu.Instance {
            return T.createInstance(descriptor);
        }

        // SYSGPU_EXPORT WGPUProc sysgpuGetProcAddress(WGPUDevice device, char const * procName);
        export fn sysgpuGetProcAddress(device: *sysgpu.Device, proc_name: [*:0]const u8) ?sysgpu.Proc {
            return T.getProcAddress(device, proc_name);
        }

        // SYSGPU_EXPORT WGPUDevice sysgpuAdapterCreateDevice(WGPUAdapter adapter, WGPUDeviceDescriptor const * descriptor /* nullable */);
        export fn sysgpuAdapterCreateDevice(adapter: *sysgpu.Adapter, descriptor: ?*const sysgpu.Device.Descriptor) ?*sysgpu.Device {
            return T.adapterCreateDevice(adapter, descriptor);
        }

        // SYSGPU_EXPORT size_t sysgpuAdapterEnumerateFeatures(WGPUAdapter adapter, WGPUFeatureName * features);
        export fn sysgpuAdapterEnumerateFeatures(adapter: *sysgpu.Adapter, features: ?[*]sysgpu.FeatureName) usize {
            return T.adapterEnumerateFeatures(adapter, features);
        }

        // SYSGPU_EXPORT WGPUInstance sysgpuAdapterGetInstance(WGPUAdapter adapter);
        export fn sysgpuAdapterGetInstance(adapter: *sysgpu.Adapter) *sysgpu.Instance {
            return T.adapterGetInstance(adapter);
        }

        // SYSGPU_EXPORT WGPUBool sysgpuAdapterGetLimits(WGPUAdapter adapter, WGPUSupportedLimits * limits);
        export fn sysgpuAdapterGetLimits(adapter: *sysgpu.Adapter, limits: *sysgpu.SupportedLimits) u32 {
            return T.adapterGetLimits(adapter, limits);
        }

        // SYSGPU_EXPORT void sysgpuAdapterGetProperties(WGPUAdapter adapter, WGPUAdapterProperties * properties);
        export fn sysgpuAdapterGetProperties(adapter: *sysgpu.Adapter, properties: *sysgpu.Adapter.Properties) void {
            return T.adapterGetProperties(adapter, properties);
        }

        // SYSGPU_EXPORT WGPUBool sysgpuAdapterHasFeature(WGPUAdapter adapter, WGPUFeatureName feature);
        export fn sysgpuAdapterHasFeature(adapter: *sysgpu.Adapter, feature: sysgpu.FeatureName) u32 {
            return T.adapterHasFeature(adapter, feature);
        }

        // SYSGPU_EXPORT void sysgpuAdapterPropertiesFreeMembers(WGPUAdapterProperties value);
        export fn sysgpuAdapterPropertiesFreeMembers(value: sysgpu.Adapter.Properties) void {
            T.adapterPropertiesFreeMembers(value);
        }

        // SYSGPU_EXPORT void sysgpuAdapterRequestDevice(WGPUAdapter adapter, WGPUDeviceDescriptor const * descriptor /* nullable */, WGPURequestDeviceCallback callback, void * userdata);
        export fn sysgpuAdapterRequestDevice(adapter: *sysgpu.Adapter, descriptor: ?*const sysgpu.Device.Descriptor, callback: sysgpu.RequestDeviceCallback, userdata: ?*anyopaque) void {
            T.adapterRequestDevice(adapter, descriptor, callback, userdata);
        }

        // SYSGPU_EXPORT void sysgpuAdapterReference(WGPUAdapter adapter);
        export fn sysgpuAdapterReference(adapter: *sysgpu.Adapter) void {
            T.adapterReference(adapter);
        }

        // SYSGPU_EXPORT void sysgpuAdapterRelease(WGPUAdapter adapter);
        export fn sysgpuAdapterRelease(adapter: *sysgpu.Adapter) void {
            T.adapterRelease(adapter);
        }

        // SYSGPU_EXPORT void sysgpuBindGroupSetLabel(WGPUBindGroup bindGroup, char const * label);
        export fn sysgpuBindGroupSetLabel(bind_group: *sysgpu.BindGroup, label: [*:0]const u8) void {
            T.bindGroupSetLabel(bind_group, label);
        }

        // SYSGPU_EXPORT void sysgpuBindGroupReference(WGPUBindGroup bindGroup);
        export fn sysgpuBindGroupReference(bind_group: *sysgpu.BindGroup) void {
            T.bindGroupReference(bind_group);
        }

        // SYSGPU_EXPORT void sysgpuBindGroupRelease(WGPUBindGroup bindGroup);
        export fn sysgpuBindGroupRelease(bind_group: *sysgpu.BindGroup) void {
            T.bindGroupRelease(bind_group);
        }

        // SYSGPU_EXPORT void sysgpuBindGroupLayoutSetLabel(WGPUBindGroupLayout bindGroupLayout, char const * label);
        export fn sysgpuBindGroupLayoutSetLabel(bind_group_layout: *sysgpu.BindGroupLayout, label: [*:0]const u8) void {
            T.bindGroupLayoutSetLabel(bind_group_layout, label);
        }

        // SYSGPU_EXPORT void sysgpuBindGroupLayoutReference(WGPUBindGroupLayout bindGroupLayout);
        export fn sysgpuBindGroupLayoutReference(bind_group_layout: *sysgpu.BindGroupLayout) void {
            T.bindGroupLayoutReference(bind_group_layout);
        }

        // SYSGPU_EXPORT void sysgpuBindGroupLayoutRelease(WGPUBindGroupLayout bindGroupLayout);
        export fn sysgpuBindGroupLayoutRelease(bind_group_layout: *sysgpu.BindGroupLayout) void {
            T.bindGroupLayoutRelease(bind_group_layout);
        }

        // SYSGPU_EXPORT void sysgpuBufferDestroy(WGPUBuffer buffer);
        export fn sysgpuBufferDestroy(buffer: *sysgpu.Buffer) void {
            T.bufferDestroy(buffer);
        }

        // SYSGPU_EXPORT void const * sysgpuBufferGetConstMappedRange(WGPUBuffer buffer, size_t offset, size_t size);
        export fn sysgpuBufferGetConstMappedRange(buffer: *sysgpu.Buffer, offset: usize, size: usize) ?*const anyopaque {
            return T.bufferGetConstMappedRange(buffer, offset, size);
        }

        // SYSGPU_EXPORT void * sysgpuBufferGetMappedRange(WGPUBuffer buffer, size_t offset, size_t size);
        export fn sysgpuBufferGetMappedRange(buffer: *sysgpu.Buffer, offset: usize, size: usize) ?*anyopaque {
            return T.bufferGetMappedRange(buffer, offset, size);
        }

        // SYSGPU_EXPORT uint64_t sysgpuBufferGetSize(WGPUBuffer buffer);
        export fn sysgpuBufferGetSize(buffer: *sysgpu.Buffer) u64 {
            return T.bufferGetSize(buffer);
        }

        // SYSGPU_EXPORT WGPUBufferUsage sysgpuBufferGetUsage(WGPUBuffer buffer);
        export fn sysgpuBufferGetUsage(buffer: *sysgpu.Buffer) sysgpu.Buffer.UsageFlags {
            return T.bufferGetUsage(buffer);
        }

        // SYSGPU_EXPORT void sysgpuBufferMapAsync(WGPUBuffer buffer, WGPUMapModeFlags mode, size_t offset, size_t size, WGPUBufferMapCallback callback, void * userdata);
        export fn sysgpuBufferMapAsync(buffer: *sysgpu.Buffer, mode: u32, offset: usize, size: usize, callback: sysgpu.Buffer.MapCallback, userdata: ?*anyopaque) void {
            T.bufferMapAsync(buffer, @as(sysgpu.MapModeFlags, @bitCast(mode)), offset, size, callback, userdata);
        }

        // SYSGPU_EXPORT void sysgpuBufferSetLabel(WGPUBuffer buffer, char const * label);
        export fn sysgpuBufferSetLabel(buffer: *sysgpu.Buffer, label: [*:0]const u8) void {
            T.bufferSetLabel(buffer, label);
        }

        // SYSGPU_EXPORT void sysgpuBufferUnmap(WGPUBuffer buffer);
        export fn sysgpuBufferUnmap(buffer: *sysgpu.Buffer) void {
            T.bufferUnmap(buffer);
        }

        // SYSGPU_EXPORT void sysgpuBufferReference(WGPUBuffer buffer);
        export fn sysgpuBufferReference(buffer: *sysgpu.Buffer) void {
            T.bufferReference(buffer);
        }

        // SYSGPU_EXPORT void sysgpuBufferRelease(WGPUBuffer buffer);
        export fn sysgpuBufferRelease(buffer: *sysgpu.Buffer) void {
            T.bufferRelease(buffer);
        }

        // SYSGPU_EXPORT void sysgpuCommandBufferSetLabel(WGPUCommandBuffer commandBuffer, char const * label);
        export fn sysgpuCommandBufferSetLabel(command_buffer: *sysgpu.CommandBuffer, label: [*:0]const u8) void {
            T.commandBufferSetLabel(command_buffer, label);
        }

        // SYSGPU_EXPORT void sysgpuCommandBufferReference(WGPUCommandBuffer commandBuffer);
        export fn sysgpuCommandBufferReference(command_buffer: *sysgpu.CommandBuffer) void {
            T.commandBufferReference(command_buffer);
        }

        // SYSGPU_EXPORT void sysgpuCommandBufferRelease(WGPUCommandBuffer commandBuffer);
        export fn sysgpuCommandBufferRelease(command_buffer: *sysgpu.CommandBuffer) void {
            T.commandBufferRelease(command_buffer);
        }

        // SYSGPU_EXPORT WGPUComputePassEncoder sysgpuCommandEncoderBeginComputePass(WGPUCommandEncoder commandEncoder, WGPUComputePassDescriptor const * descriptor /* nullable */);
        export fn sysgpuCommandEncoderBeginComputePass(command_encoder: *sysgpu.CommandEncoder, descriptor: ?*const sysgpu.ComputePassDescriptor) *sysgpu.ComputePassEncoder {
            return T.commandEncoderBeginComputePass(command_encoder, descriptor);
        }

        // SYSGPU_EXPORT WGPURenderPassEncoder sysgpuCommandEncoderBeginRenderPass(WGPUCommandEncoder commandEncoder, WGPURenderPassDescriptor const * descriptor);
        export fn sysgpuCommandEncoderBeginRenderPass(command_encoder: *sysgpu.CommandEncoder, descriptor: *const sysgpu.RenderPassDescriptor) *sysgpu.RenderPassEncoder {
            return T.commandEncoderBeginRenderPass(command_encoder, descriptor);
        }

        // SYSGPU_EXPORT void sysgpuCommandEncoderClearBuffer(WGPUCommandEncoder commandEncoder, WGPUBuffer buffer, uint64_t offset, uint64_t size);
        export fn sysgpuCommandEncoderClearBuffer(command_encoder: *sysgpu.CommandEncoder, buffer: *sysgpu.Buffer, offset: u64, size: u64) void {
            T.commandEncoderClearBuffer(command_encoder, buffer, offset, size);
        }

        // SYSGPU_EXPORT void sysgpuCommandEncoderCopyBufferToBuffer(WGPUCommandEncoder commandEncoder, WGPUBuffer source, uint64_t sourceOffset, WGPUBuffer destination, uint64_t destinationOffset, uint64_t size);
        export fn sysgpuCommandEncoderCopyBufferToBuffer(command_encoder: *sysgpu.CommandEncoder, source: *sysgpu.Buffer, source_offset: u64, destination: *sysgpu.Buffer, destination_offset: u64, size: u64) void {
            T.commandEncoderCopyBufferToBuffer(command_encoder, source, source_offset, destination, destination_offset, size);
        }

        // SYSGPU_EXPORT void sysgpuCommandEncoderCopyBufferToTexture(WGPUCommandEncoder commandEncoder, WGPUImageCopyBuffer const * source, WGPUImageCopyTexture const * destination, WGPUExtent3D const * copySize);
        export fn sysgpuCommandEncoderCopyBufferToTexture(command_encoder: *sysgpu.CommandEncoder, source: *const sysgpu.ImageCopyBuffer, destination: *const sysgpu.ImageCopyTexture, copy_size: *const sysgpu.Extent3D) void {
            T.commandEncoderCopyBufferToTexture(command_encoder, source, destination, copy_size);
        }

        // SYSGPU_EXPORT void sysgpuCommandEncoderCopyTextureToBuffer(WGPUCommandEncoder commandEncoder, WGPUImageCopyTexture const * source, WGPUImageCopyBuffer const * destination, WGPUExtent3D const * copySize);
        export fn sysgpuCommandEncoderCopyTextureToBuffer(command_encoder: *sysgpu.CommandEncoder, source: *const sysgpu.ImageCopyTexture, destination: *const sysgpu.ImageCopyBuffer, copy_size: *const sysgpu.Extent3D) void {
            T.commandEncoderCopyTextureToBuffer(command_encoder, source, destination, copy_size);
        }

        // SYSGPU_EXPORT void sysgpuCommandEncoderCopyTextureToTexture(WGPUCommandEncoder commandEncoder, WGPUImageCopyTexture const * source, WGPUImageCopyTexture const * destination, WGPUExtent3D const * copySize);
        export fn sysgpuCommandEncoderCopyTextureToTexture(command_encoder: *sysgpu.CommandEncoder, source: *const sysgpu.ImageCopyTexture, destination: *const sysgpu.ImageCopyTexture, copy_size: *const sysgpu.Extent3D) void {
            T.commandEncoderCopyTextureToTexture(command_encoder, source, destination, copy_size);
        }

        // SYSGPU_EXPORT WGPUCommandBuffer sysgpuCommandEncoderFinish(WGPUCommandEncoder commandEncoder, WGPUCommandBufferDescriptor const * descriptor /* nullable */);
        export fn sysgpuCommandEncoderFinish(command_encoder: *sysgpu.CommandEncoder, descriptor: ?*const sysgpu.CommandBuffer.Descriptor) *sysgpu.CommandBuffer {
            return T.commandEncoderFinish(command_encoder, descriptor);
        }

        // SYSGPU_EXPORT void sysgpuCommandEncoderInjectValidationError(WGPUCommandEncoder commandEncoder, char const * message);
        export fn sysgpuCommandEncoderInjectValidationError(command_encoder: *sysgpu.CommandEncoder, message: [*:0]const u8) void {
            T.commandEncoderInjectValidationError(command_encoder, message);
        }

        // SYSGPU_EXPORT void sysgpuCommandEncoderInsertDebugMarker(WGPUCommandEncoder commandEncoder, char const * markerLabel);
        export fn sysgpuCommandEncoderInsertDebugMarker(command_encoder: *sysgpu.CommandEncoder, marker_label: [*:0]const u8) void {
            T.commandEncoderInsertDebugMarker(command_encoder, marker_label);
        }

        // SYSGPU_EXPORT void sysgpuCommandEncoderPopDebugGroup(WGPUCommandEncoder commandEncoder);
        export fn sysgpuCommandEncoderPopDebugGroup(command_encoder: *sysgpu.CommandEncoder) void {
            T.commandEncoderPopDebugGroup(command_encoder);
        }

        // SYSGPU_EXPORT void sysgpuCommandEncoderPushDebugGroup(WGPUCommandEncoder commandEncoder, char const * groupLabel);
        export fn sysgpuCommandEncoderPushDebugGroup(command_encoder: *sysgpu.CommandEncoder, group_label: [*:0]const u8) void {
            T.commandEncoderPushDebugGroup(command_encoder, group_label);
        }

        // SYSGPU_EXPORT void sysgpuCommandEncoderResolveQuerySet(WGPUCommandEncoder commandEncoder, WGPUQuerySet querySet, uint32_t firstQuery, uint32_t queryCount, WGPUBuffer destination, uint64_t destinationOffset);
        export fn sysgpuCommandEncoderResolveQuerySet(command_encoder: *sysgpu.CommandEncoder, query_set: *sysgpu.QuerySet, first_query: u32, query_count: u32, destination: *sysgpu.Buffer, destination_offset: u64) void {
            T.commandEncoderResolveQuerySet(command_encoder, query_set, first_query, query_count, destination, destination_offset);
        }

        // SYSGPU_EXPORT void sysgpuCommandEncoderSetLabel(WGPUCommandEncoder commandEncoder, char const * label);
        export fn sysgpuCommandEncoderSetLabel(command_encoder: *sysgpu.CommandEncoder, label: [*:0]const u8) void {
            T.commandEncoderSetLabel(command_encoder, label);
        }

        // SYSGPU_EXPORT void sysgpuCommandEncoderWriteBuffer(WGPUCommandEncoder commandEncoder, WGPUBuffer buffer, uint64_t bufferOffset, uint8_t const * data, uint64_t size);
        export fn sysgpuCommandEncoderWriteBuffer(command_encoder: *sysgpu.CommandEncoder, buffer: *sysgpu.Buffer, buffer_offset: u64, data: [*]const u8, size: u64) void {
            T.commandEncoderWriteBuffer(command_encoder, buffer, buffer_offset, data, size);
        }

        // SYSGPU_EXPORT void sysgpuCommandEncoderWriteTimestamp(WGPUCommandEncoder commandEncoder, WGPUQuerySet querySet, uint32_t queryIndex);
        export fn sysgpuCommandEncoderWriteTimestamp(command_encoder: *sysgpu.CommandEncoder, query_set: *sysgpu.QuerySet, query_index: u32) void {
            T.commandEncoderWriteTimestamp(command_encoder, query_set, query_index);
        }

        // SYSGPU_EXPORT void sysgpuCommandEncoderReference(WGPUCommandEncoder commandEncoder);
        export fn sysgpuCommandEncoderReference(command_encoder: *sysgpu.CommandEncoder) void {
            T.commandEncoderReference(command_encoder);
        }

        // SYSGPU_EXPORT void sysgpuCommandEncoderRelease(WGPUCommandEncoder commandEncoder);
        export fn sysgpuCommandEncoderRelease(command_encoder: *sysgpu.CommandEncoder) void {
            T.commandEncoderRelease(command_encoder);
        }

        // SYSGPU_EXPORT void sysgpuComputePassEncoderDispatchWorkgroups(WGPUComputePassEncoder computePassEncoder, uint32_t workgroupCountX, uint32_t workgroupCountY, uint32_t workgroupCountZ);
        export fn sysgpuComputePassEncoderDispatchWorkgroups(compute_pass_encoder: *sysgpu.ComputePassEncoder, workgroup_count_x: u32, workgroup_count_y: u32, workgroup_count_z: u32) void {
            T.computePassEncoderDispatchWorkgroups(compute_pass_encoder, workgroup_count_x, workgroup_count_y, workgroup_count_z);
        }

        // SYSGPU_EXPORT void sysgpuComputePassEncoderDispatchWorkgroupsIndirect(WGPUComputePassEncoder computePassEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
        export fn sysgpuComputePassEncoderDispatchWorkgroupsIndirect(compute_pass_encoder: *sysgpu.ComputePassEncoder, indirect_buffer: *sysgpu.Buffer, indirect_offset: u64) void {
            T.computePassEncoderDispatchWorkgroupsIndirect(compute_pass_encoder, indirect_buffer, indirect_offset);
        }

        // SYSGPU_EXPORT void sysgpuComputePassEncoderEnd(WGPUComputePassEncoder computePassEncoder);
        export fn sysgpuComputePassEncoderEnd(compute_pass_encoder: *sysgpu.ComputePassEncoder) void {
            T.computePassEncoderEnd(compute_pass_encoder);
        }

        // SYSGPU_EXPORT void sysgpuComputePassEncoderInsertDebugMarker(WGPUComputePassEncoder computePassEncoder, char const * markerLabel);
        export fn sysgpuComputePassEncoderInsertDebugMarker(compute_pass_encoder: *sysgpu.ComputePassEncoder, marker_label: [*:0]const u8) void {
            T.computePassEncoderInsertDebugMarker(compute_pass_encoder, marker_label);
        }

        // SYSGPU_EXPORT void sysgpuComputePassEncoderPopDebugGroup(WGPUComputePassEncoder computePassEncoder);
        export fn sysgpuComputePassEncoderPopDebugGroup(compute_pass_encoder: *sysgpu.ComputePassEncoder) void {
            T.computePassEncoderPopDebugGroup(compute_pass_encoder);
        }

        // SYSGPU_EXPORT void sysgpuComputePassEncoderPushDebugGroup(WGPUComputePassEncoder computePassEncoder, char const * groupLabel);
        export fn sysgpuComputePassEncoderPushDebugGroup(compute_pass_encoder: *sysgpu.ComputePassEncoder, group_label: [*:0]const u8) void {
            T.computePassEncoderPushDebugGroup(compute_pass_encoder, group_label);
        }

        // SYSGPU_EXPORT void sysgpuComputePassEncoderSetBindGroup(WGPUComputePassEncoder computePassEncoder, uint32_t groupIndex, WGPUBindGroup group, size_t dynamicOffsetCount, uint32_t const * dynamicOffsets);
        export fn sysgpuComputePassEncoderSetBindGroup(compute_pass_encoder: *sysgpu.ComputePassEncoder, group_index: u32, group: *sysgpu.BindGroup, dynamic_offset_count: usize, dynamic_offsets: ?[*]const u32) void {
            T.computePassEncoderSetBindGroup(compute_pass_encoder, group_index, group, dynamic_offset_count, dynamic_offsets);
        }

        // SYSGPU_EXPORT void sysgpuComputePassEncoderSetLabel(WGPUComputePassEncoder computePassEncoder, char const * label);
        export fn sysgpuComputePassEncoderSetLabel(compute_pass_encoder: *sysgpu.ComputePassEncoder, label: [*:0]const u8) void {
            T.computePassEncoderSetLabel(compute_pass_encoder, label);
        }

        // SYSGPU_EXPORT void sysgpuComputePassEncoderSetPipeline(WGPUComputePassEncoder computePassEncoder, WGPUComputePipeline pipeline);
        export fn sysgpuComputePassEncoderSetPipeline(compute_pass_encoder: *sysgpu.ComputePassEncoder, pipeline: *sysgpu.ComputePipeline) void {
            T.computePassEncoderSetPipeline(compute_pass_encoder, pipeline);
        }

        // SYSGPU_EXPORT void sysgpuComputePassEncoderWriteTimestamp(WGPUComputePassEncoder computePassEncoder, WGPUQuerySet querySet, uint32_t queryIndex);
        export fn sysgpuComputePassEncoderWriteTimestamp(compute_pass_encoder: *sysgpu.ComputePassEncoder, query_set: *sysgpu.QuerySet, query_index: u32) void {
            T.computePassEncoderWriteTimestamp(compute_pass_encoder, query_set, query_index);
        }

        // SYSGPU_EXPORT void sysgpuComputePassEncoderReference(WGPUComputePassEncoder computePassEncoder);
        export fn sysgpuComputePassEncoderReference(compute_pass_encoder: *sysgpu.ComputePassEncoder) void {
            T.computePassEncoderReference(compute_pass_encoder);
        }

        // SYSGPU_EXPORT void sysgpuComputePassEncoderRelease(WGPUComputePassEncoder computePassEncoder);
        export fn sysgpuComputePassEncoderRelease(compute_pass_encoder: *sysgpu.ComputePassEncoder) void {
            T.computePassEncoderRelease(compute_pass_encoder);
        }

        // SYSGPU_EXPORT WGPUBindGroupLayout sysgpuComputePipelineGetBindGroupLayout(WGPUComputePipeline computePipeline, uint32_t groupIndex);
        export fn sysgpuComputePipelineGetBindGroupLayout(compute_pipeline: *sysgpu.ComputePipeline, group_index: u32) *sysgpu.BindGroupLayout {
            return T.computePipelineGetBindGroupLayout(compute_pipeline, group_index);
        }

        // SYSGPU_EXPORT void sysgpuComputePipelineSetLabel(WGPUComputePipeline computePipeline, char const * label);
        export fn sysgpuComputePipelineSetLabel(compute_pipeline: *sysgpu.ComputePipeline, label: [*:0]const u8) void {
            T.computePipelineSetLabel(compute_pipeline, label);
        }

        // SYSGPU_EXPORT void sysgpuComputePipelineReference(WGPUComputePipeline computePipeline);
        export fn sysgpuComputePipelineReference(compute_pipeline: *sysgpu.ComputePipeline) void {
            T.computePipelineReference(compute_pipeline);
        }

        // SYSGPU_EXPORT void sysgpuComputePipelineRelease(WGPUComputePipeline computePipeline);
        export fn sysgpuComputePipelineRelease(compute_pipeline: *sysgpu.ComputePipeline) void {
            T.computePipelineRelease(compute_pipeline);
        }

        // SYSGPU_EXPORT WGPUBindGroup sysgpuDeviceCreateBindGroup(WGPUDevice device, WGPUBindGroupDescriptor const * descriptor);
        export fn sysgpuDeviceCreateBindGroup(device: *sysgpu.Device, descriptor: *const sysgpu.BindGroup.Descriptor) *sysgpu.BindGroup {
            return T.deviceCreateBindGroup(device, descriptor);
        }

        // SYSGPU_EXPORT WGPUBindGroupLayout sysgpuDeviceCreateBindGroupLayout(WGPUDevice device, WGPUBindGroupLayout.Descriptor const * descriptor);
        export fn sysgpuDeviceCreateBindGroupLayout(device: *sysgpu.Device, descriptor: *const sysgpu.BindGroupLayout.Descriptor) *sysgpu.BindGroupLayout {
            return T.deviceCreateBindGroupLayout(device, descriptor);
        }

        // SYSGPU_EXPORT WGPUBuffer sysgpuDeviceCreateBuffer(WGPUDevice device, WGPUBuffer.Descriptor const * descriptor);
        export fn sysgpuDeviceCreateBuffer(device: *sysgpu.Device, descriptor: *const sysgpu.Buffer.Descriptor) *sysgpu.Buffer {
            return T.deviceCreateBuffer(device, descriptor);
        }

        // SYSGPU_EXPORT WGPUCommandEncoder sysgpuDeviceCreateCommandEncoder(WGPUDevice device, WGPUCommandEncoderDescriptor const * descriptor /* nullable */);
        export fn sysgpuDeviceCreateCommandEncoder(device: *sysgpu.Device, descriptor: ?*const sysgpu.CommandEncoder.Descriptor) *sysgpu.CommandEncoder {
            return T.deviceCreateCommandEncoder(device, descriptor);
        }

        // SYSGPU_EXPORT WGPUComputePipeline sysgpuDeviceCreateComputePipeline(WGPUDevice device, WGPUComputePipelineDescriptor const * descriptor);
        export fn sysgpuDeviceCreateComputePipeline(device: *sysgpu.Device, descriptor: *const sysgpu.ComputePipeline.Descriptor) *sysgpu.ComputePipeline {
            return T.deviceCreateComputePipeline(device, descriptor);
        }

        // SYSGPU_EXPORT void sysgpuDeviceCreateComputePipelineAsync(WGPUDevice device, WGPUComputePipelineDescriptor const * descriptor, WGPUCreateComputePipelineAsyncCallback callback, void * userdata);
        export fn sysgpuDeviceCreateComputePipelineAsync(device: *sysgpu.Device, descriptor: *const sysgpu.ComputePipeline.Descriptor, callback: sysgpu.CreateComputePipelineAsyncCallback, userdata: ?*anyopaque) void {
            T.deviceCreateComputePipelineAsync(device, descriptor, callback, userdata);
        }

        // SYSGPU_EXPORT WGPUBuffer sysgpuDeviceCreateErrorBuffer(WGPUDevice device, WGPUBufferDescriptor const * descriptor);
        export fn sysgpuDeviceCreateErrorBuffer(device: *sysgpu.Device, descriptor: *const sysgpu.Buffer.Descriptor) *sysgpu.Buffer {
            return T.deviceCreateErrorBuffer(device, descriptor);
        }

        // SYSGPU_EXPORT WGPUExternalTexture sysgpuDeviceCreateErrorExternalTexture(WGPUDevice device);
        export fn sysgpuDeviceCreateErrorExternalTexture(device: *sysgpu.Device) *sysgpu.ExternalTexture {
            return T.deviceCreateErrorExternalTexture(device);
        }

        // SYSGPU_EXPORT WGPUTexture sysgpuDeviceCreateErrorTexture(WGPUDevice device, WGPUTextureDescriptor const * descriptor);
        export fn sysgpuDeviceCreateErrorTexture(device: *sysgpu.Device, descriptor: *const sysgpu.Texture.Descriptor) *sysgpu.Texture {
            return T.deviceCreateErrorTexture(device, descriptor);
        }

        // SYSGPU_EXPORT WGPUExternalTexture sysgpuDeviceCreateExternalTexture(WGPUDevice device, WGPUExternalTextureDescriptor const * externalTextureDescriptor);
        export fn sysgpuDeviceCreateExternalTexture(device: *sysgpu.Device, external_texture_descriptor: *const sysgpu.ExternalTexture.Descriptor) *sysgpu.ExternalTexture {
            return T.deviceCreateExternalTexture(device, external_texture_descriptor);
        }

        // SYSGPU_EXPORT WGPUPipelineLayout sysgpuDeviceCreatePipelineLayout(WGPUDevice device, WGPUPipelineLayoutDescriptor const * descriptor);
        export fn sysgpuDeviceCreatePipelineLayout(device: *sysgpu.Device, pipeline_layout_descriptor: *const sysgpu.PipelineLayout.Descriptor) *sysgpu.PipelineLayout {
            return T.deviceCreatePipelineLayout(device, pipeline_layout_descriptor);
        }

        // SYSGPU_EXPORT WGPUQuerySet sysgpuDeviceCreateQuerySet(WGPUDevice device, WGPUQuerySetDescriptor const * descriptor);
        export fn sysgpuDeviceCreateQuerySet(device: *sysgpu.Device, descriptor: *const sysgpu.QuerySet.Descriptor) *sysgpu.QuerySet {
            return T.deviceCreateQuerySet(device, descriptor);
        }

        // SYSGPU_EXPORT WGPURenderBundleEncoder sysgpuDeviceCreateRenderBundleEncoder(WGPUDevice device, WGPURenderBundleEncoderDescriptor const * descriptor);
        export fn sysgpuDeviceCreateRenderBundleEncoder(device: *sysgpu.Device, descriptor: *const sysgpu.RenderBundleEncoder.Descriptor) *sysgpu.RenderBundleEncoder {
            return T.deviceCreateRenderBundleEncoder(device, descriptor);
        }

        // SYSGPU_EXPORT WGPURenderPipeline sysgpuDeviceCreateRenderPipeline(WGPUDevice device, WGPURenderPipelineDescriptor const * descriptor);
        export fn sysgpuDeviceCreateRenderPipeline(device: *sysgpu.Device, descriptor: *const sysgpu.RenderPipeline.Descriptor) *sysgpu.RenderPipeline {
            return T.deviceCreateRenderPipeline(device, descriptor);
        }

        // SYSGPU_EXPORT void sysgpuDeviceCreateRenderPipelineAsync(WGPUDevice device, WGPURenderPipelineDescriptor const * descriptor, WGPUCreateRenderPipelineAsyncCallback callback, void * userdata);
        export fn sysgpuDeviceCreateRenderPipelineAsync(device: *sysgpu.Device, descriptor: *const sysgpu.RenderPipeline.Descriptor, callback: sysgpu.CreateRenderPipelineAsyncCallback, userdata: ?*anyopaque) void {
            T.deviceCreateRenderPipelineAsync(device, descriptor, callback, userdata);
        }

        // SYSGPU_EXPORT WGPUSampler sysgpuDeviceCreateSampler(WGPUDevice device, WGPUSamplerDescriptor const * descriptor /* nullable */);
        export fn sysgpuDeviceCreateSampler(device: *sysgpu.Device, descriptor: ?*const sysgpu.Sampler.Descriptor) *sysgpu.Sampler {
            return T.deviceCreateSampler(device, descriptor);
        }

        // SYSGPU_EXPORT WGPUShaderModule sysgpuDeviceCreateShaderModule(WGPUDevice device, WGPUShaderModuleDescriptor const * descriptor);
        export fn sysgpuDeviceCreateShaderModule(device: *sysgpu.Device, descriptor: *const sysgpu.ShaderModule.Descriptor) *sysgpu.ShaderModule {
            return T.deviceCreateShaderModule(device, descriptor);
        }

        // SYSGPU_EXPORT WGPUSwapChain sysgpuDeviceCreateSwapChain(WGPUDevice device, WGPUSurface surface /* nullable */, WGPUSwapChainDescriptor const * descriptor);
        export fn sysgpuDeviceCreateSwapChain(device: *sysgpu.Device, surface: ?*sysgpu.Surface, descriptor: *const sysgpu.SwapChain.Descriptor) *sysgpu.SwapChain {
            return T.deviceCreateSwapChain(device, surface, descriptor);
        }

        // SYSGPU_EXPORT WGPUTexture sysgpuDeviceCreateTexture(WGPUDevice device, WGPUTextureDescriptor const * descriptor);
        export fn sysgpuDeviceCreateTexture(device: *sysgpu.Device, descriptor: *const sysgpu.Texture.Descriptor) *sysgpu.Texture {
            return T.deviceCreateTexture(device, descriptor);
        }

        // SYSGPU_EXPORT void sysgpuDeviceDestroy(WGPUDevice device);
        export fn sysgpuDeviceDestroy(device: *sysgpu.Device) void {
            T.deviceDestroy(device);
        }

        // SYSGPU_EXPORT size_t sysgpuDeviceEnumerateFeatures(WGPUDevice device, WGPUFeatureName * features);
        export fn sysgpuDeviceEnumerateFeatures(device: *sysgpu.Device, features: ?[*]sysgpu.FeatureName) usize {
            return T.deviceEnumerateFeatures(device, features);
        }

        // SYSGPU_EXPORT WGPUBool sysgpuDeviceGetLimits(WGPUDevice device, WGPUSupportedLimits * limits);
        export fn sysgpuDeviceGetLimits(device: *sysgpu.Device, limits: *sysgpu.SupportedLimits) u32 {
            return T.deviceGetLimits(device, limits);
        }

        // SYSGPU_EXPORT WGPUSharedFence sysgpuDeviceImportSharedFence(WGPUDevice device, WGPUSharedFenceDescriptor const * descriptor);
        export fn sysgpuDeviceImportSharedFence(device: *sysgpu.Device, descriptor: *const sysgpu.SharedFence.Descriptor) *sysgpu.SharedFence {
            return T.deviceImportSharedFence(device, descriptor);
        }

        // SYSGPU_EXPORT WGPUSharedTextureMemory sysgpuDeviceImportSharedTextureMemory(WGPUDevice device, WGPUSharedTextureMemoryDescriptor const * descriptor);
        export fn sysgpuDeviceImportSharedTextureMemory(device: *sysgpu.Device, descriptor: *const sysgpu.SharedTextureMemory.Descriptor) *sysgpu.SharedTextureMemory {
            return T.deviceImportSharedTextureMemory(device, descriptor);
        }

        // SYSGPU_EXPORT WGPUQueue sysgpuDeviceGetQueue(WGPUDevice device);
        export fn sysgpuDeviceGetQueue(device: *sysgpu.Device) *sysgpu.Queue {
            return T.deviceGetQueue(device);
        }

        // SYSGPU_EXPORT bool sysgpuDeviceHasFeature(WGPUDevice device, WGPUFeatureName feature);
        export fn sysgpuDeviceHasFeature(device: *sysgpu.Device, feature: sysgpu.FeatureName) u32 {
            return T.deviceHasFeature(device, feature);
        }

        // SYSGPU_EXPORT void sysgpuDeviceInjectError(WGPUDevice device, WGPUErrorType type, char const * message);
        export fn sysgpuDeviceInjectError(device: *sysgpu.Device, typ: sysgpu.ErrorType, message: [*:0]const u8) void {
            T.deviceInjectError(device, typ, message);
        }

        // SYSGPU_EXPORT void sysgpuDevicePopErrorScope(WGPUDevice device, WGPUErrorCallback callback, void * userdata);
        export fn sysgpuDevicePopErrorScope(device: *sysgpu.Device, callback: sysgpu.ErrorCallback, userdata: ?*anyopaque) void {
            T.devicePopErrorScope(device, callback, userdata);
        }

        // SYSGPU_EXPORT void sysgpuDevicePushErrorScope(WGPUDevice device, WGPUErrorFilter filter);
        export fn sysgpuDevicePushErrorScope(device: *sysgpu.Device, filter: sysgpu.ErrorFilter) void {
            T.devicePushErrorScope(device, filter);
        }

        // TODO: dawn: callback not marked as nullable in dawn.json but in fact is.
        // SYSGPU_EXPORT void sysgpuDeviceSetDeviceLostCallback(WGPUDevice device, WGPUDeviceLostCallback callback, void * userdata);
        export fn sysgpuDeviceSetDeviceLostCallback(device: *sysgpu.Device, callback: ?sysgpu.Device.LostCallback, userdata: ?*anyopaque) void {
            T.deviceSetDeviceLostCallback(device, callback, userdata);
        }

        // SYSGPU_EXPORT void sysgpuDeviceSetLabel(WGPUDevice device, char const * label);
        export fn sysgpuDeviceSetLabel(device: *sysgpu.Device, label: [*:0]const u8) void {
            T.deviceSetLabel(device, label);
        }

        // TODO: dawn: callback not marked as nullable in dawn.json but in fact is.
        // SYSGPU_EXPORT void sysgpuDeviceSetLoggingCallback(WGPUDevice device, WGPULoggingCallback callback, void * userdata);
        export fn sysgpuDeviceSetLoggingCallback(device: *sysgpu.Device, callback: ?sysgpu.LoggingCallback, userdata: ?*anyopaque) void {
            T.deviceSetLoggingCallback(device, callback, userdata);
        }

        // TODO: dawn: callback not marked as nullable in dawn.json but in fact is.
        // SYSGPU_EXPORT void sysgpuDeviceSetUncapturedErrorCallback(WGPUDevice device, WGPUErrorCallback callback, void * userdata);
        export fn sysgpuDeviceSetUncapturedErrorCallback(device: *sysgpu.Device, callback: ?sysgpu.ErrorCallback, userdata: ?*anyopaque) void {
            T.deviceSetUncapturedErrorCallback(device, callback, userdata);
        }

        // SYSGPU_EXPORT void sysgpuDeviceTick(WGPUDevice device);
        export fn sysgpuDeviceTick(device: *sysgpu.Device) void {
            T.deviceTick(device);
        }

        // SYSGPU_EXPORT void sysgpuMachDeviceWaitForCommandsToBeScheduled(WGPUDevice device);
        export fn sysgpuMachDeviceWaitForCommandsToBeScheduled(device: *sysgpu.Device) void {
            T.machDeviceWaitForCommandsToBeScheduled(device);
        }

        // SYSGPU_EXPORT void sysgpuDeviceReference(WGPUDevice device);
        export fn sysgpuDeviceReference(device: *sysgpu.Device) void {
            T.deviceReference(device);
        }

        // SYSGPU_EXPORT void sysgpuDeviceRelease(WGPUDevice device);
        export fn sysgpuDeviceRelease(device: *sysgpu.Device) void {
            T.deviceRelease(device);
        }

        // SYSGPU_EXPORT void sysgpuExternalTextureDestroy(WGPUExternalTexture externalTexture);
        export fn sysgpuExternalTextureDestroy(external_texture: *sysgpu.ExternalTexture) void {
            T.externalTextureDestroy(external_texture);
        }

        // SYSGPU_EXPORT void sysgpuExternalTextureSetLabel(WGPUExternalTexture externalTexture, char const * label);
        export fn sysgpuExternalTextureSetLabel(external_texture: *sysgpu.ExternalTexture, label: [*:0]const u8) void {
            T.externalTextureSetLabel(external_texture, label);
        }

        // SYSGPU_EXPORT void sysgpuExternalTextureReference(WGPUExternalTexture externalTexture);
        export fn sysgpuExternalTextureReference(external_texture: *sysgpu.ExternalTexture) void {
            T.externalTextureReference(external_texture);
        }

        // SYSGPU_EXPORT void sysgpuExternalTextureRelease(WGPUExternalTexture externalTexture);
        export fn sysgpuExternalTextureRelease(external_texture: *sysgpu.ExternalTexture) void {
            T.externalTextureRelease(external_texture);
        }

        // SYSGPU_EXPORT WGPUSurface sysgpuInstanceCreateSurface(WGPUInstance instance, WGPUSurfaceDescriptor const * descriptor);
        export fn sysgpuInstanceCreateSurface(instance: *sysgpu.Instance, descriptor: *const sysgpu.Surface.Descriptor) *sysgpu.Surface {
            return T.instanceCreateSurface(instance, descriptor);
        }

        // SYSGPU_EXPORT void instanceProcessEvents(WGPUInstance instance);
        export fn sysgpuInstanceProcessEvents(instance: *sysgpu.Instance) void {
            T.instanceProcessEvents(instance);
        }

        // SYSGPU_EXPORT void sysgpuInstanceRequestAdapter(WGPUInstance instance, WGPURequestAdapterOptions const * options /* nullable */, WGPURequestAdapterCallback callback, void * userdata);
        export fn sysgpuInstanceRequestAdapter(instance: *sysgpu.Instance, options: ?*const sysgpu.RequestAdapterOptions, callback: sysgpu.RequestAdapterCallback, userdata: ?*anyopaque) void {
            T.instanceRequestAdapter(instance, options, callback, userdata);
        }

        // SYSGPU_EXPORT void sysgpuInstanceReference(WGPUInstance instance);
        export fn sysgpuInstanceReference(instance: *sysgpu.Instance) void {
            T.instanceReference(instance);
        }

        // SYSGPU_EXPORT void sysgpuInstanceRelease(WGPUInstance instance);
        export fn sysgpuInstanceRelease(instance: *sysgpu.Instance) void {
            T.instanceRelease(instance);
        }

        // SYSGPU_EXPORT void sysgpuPipelineLayoutSetLabel(WGPUPipelineLayout pipelineLayout, char const * label);
        export fn sysgpuPipelineLayoutSetLabel(pipeline_layout: *sysgpu.PipelineLayout, label: [*:0]const u8) void {
            T.pipelineLayoutSetLabel(pipeline_layout, label);
        }

        // SYSGPU_EXPORT void sysgpuPipelineLayoutReference(WGPUPipelineLayout pipelineLayout);
        export fn sysgpuPipelineLayoutReference(pipeline_layout: *sysgpu.PipelineLayout) void {
            T.pipelineLayoutReference(pipeline_layout);
        }

        // SYSGPU_EXPORT void sysgpuPipelineLayoutRelease(WGPUPipelineLayout pipelineLayout);
        export fn sysgpuPipelineLayoutRelease(pipeline_layout: *sysgpu.PipelineLayout) void {
            T.pipelineLayoutRelease(pipeline_layout);
        }

        // SYSGPU_EXPORT void sysgpuQuerySetDestroy(WGPUQuerySet querySet);
        export fn sysgpuQuerySetDestroy(query_set: *sysgpu.QuerySet) void {
            T.querySetDestroy(query_set);
        }

        // SYSGPU_EXPORT uint32_t sysgpuQuerySetGetCount(WGPUQuerySet querySet);
        export fn sysgpuQuerySetGetCount(query_set: *sysgpu.QuerySet) u32 {
            return T.querySetGetCount(query_set);
        }

        // SYSGPU_EXPORT WGPUQueryType sysgpuQuerySetGetType(WGPUQuerySet querySet);
        export fn sysgpuQuerySetGetType(query_set: *sysgpu.QuerySet) sysgpu.QueryType {
            return T.querySetGetType(query_set);
        }

        // SYSGPU_EXPORT void sysgpuQuerySetSetLabel(WGPUQuerySet querySet, char const * label);
        export fn sysgpuQuerySetSetLabel(query_set: *sysgpu.QuerySet, label: [*:0]const u8) void {
            T.querySetSetLabel(query_set, label);
        }

        // SYSGPU_EXPORT void sysgpuQuerySetReference(WGPUQuerySet querySet);
        export fn sysgpuQuerySetReference(query_set: *sysgpu.QuerySet) void {
            T.querySetReference(query_set);
        }

        // SYSGPU_EXPORT void sysgpuQuerySetRelease(WGPUQuerySet querySet);
        export fn sysgpuQuerySetRelease(query_set: *sysgpu.QuerySet) void {
            T.querySetRelease(query_set);
        }

        // SYSGPU_EXPORT void sysgpuQueueCopyTextureForBrowser(WGPUQueue queue, WGPUImageCopyTexture const * source, WGPUImageCopyTexture const * destination, WGPUExtent3D const * copySize, WGPUCopyTextureForBrowserOptions const * options);
        export fn sysgpuQueueCopyTextureForBrowser(queue: *sysgpu.Queue, source: *const sysgpu.ImageCopyTexture, destination: *const sysgpu.ImageCopyTexture, copy_size: *const sysgpu.Extent3D, options: *const sysgpu.CopyTextureForBrowserOptions) void {
            T.queueCopyTextureForBrowser(queue, source, destination, copy_size, options);
        }

        // SYSGPU_EXPORT void sysgpuQueueOnSubmittedWorkDone(WGPUQueue queue, uint64_t signalValue, WGPUQueueWorkDoneCallback callback, void * userdata);
        export fn sysgpuQueueOnSubmittedWorkDone(queue: *sysgpu.Queue, signal_value: u64, callback: sysgpu.Queue.WorkDoneCallback, userdata: ?*anyopaque) void {
            T.queueOnSubmittedWorkDone(queue, signal_value, callback, userdata);
        }

        // SYSGPU_EXPORT void sysgpuQueueSetLabel(WGPUQueue queue, char const * label);
        export fn sysgpuQueueSetLabel(queue: *sysgpu.Queue, label: [*:0]const u8) void {
            T.queueSetLabel(queue, label);
        }

        // SYSGPU_EXPORT void sysgpuQueueSubmit(WGPUQueue queue, size_t commandCount, WGPUCommandBuffer const * commands);
        export fn sysgpuQueueSubmit(queue: *sysgpu.Queue, command_count: usize, commands: [*]const *const sysgpu.CommandBuffer) void {
            T.queueSubmit(queue, command_count, commands);
        }

        // SYSGPU_EXPORT void sysgpuQueueWriteBuffer(WGPUQueue queue, WGPUBuffer buffer, uint64_t bufferOffset, void const * data, size_t size);
        export fn sysgpuQueueWriteBuffer(queue: *sysgpu.Queue, buffer: *sysgpu.Buffer, buffer_offset: u64, data: *const anyopaque, size: usize) void {
            T.queueWriteBuffer(queue, buffer, buffer_offset, data, size);
        }

        // SYSGPU_EXPORT void sysgpuQueueWriteTexture(WGPUQueue queue, WGPUImageCopyTexture const * destination, void const * data, size_t dataSize, WGPUTextureDataLayout const * dataLayout, WGPUExtent3D const * writeSize);
        export fn sysgpuQueueWriteTexture(queue: *sysgpu.Queue, destination: *const sysgpu.ImageCopyTexture, data: *const anyopaque, data_size: usize, data_layout: *const sysgpu.Texture.DataLayout, write_size: *const sysgpu.Extent3D) void {
            T.queueWriteTexture(queue, destination, data, data_size, data_layout, write_size);
        }

        // SYSGPU_EXPORT void sysgpuQueueReference(WGPUQueue queue);
        export fn sysgpuQueueReference(queue: *sysgpu.Queue) void {
            T.queueReference(queue);
        }

        // SYSGPU_EXPORT void sysgpuQueueRelease(WGPUQueue queue);
        export fn sysgpuQueueRelease(queue: *sysgpu.Queue) void {
            T.queueRelease(queue);
        }

        // SYSGPU_EXPORT void sysgpuRenderBundleSetLabel(WGPURenderBundle renderBundle, char const * label);
        export fn sysgpuRenderBundleSetLabel(render_bundle: *sysgpu.RenderBundle, label: [*:0]const u8) void {
            T.renderBundleSetLabel(render_bundle, label);
        }

        // SYSGPU_EXPORT void sysgpuRenderBundleReference(WGPURenderBundle renderBundle);
        export fn sysgpuRenderBundleReference(render_bundle: *sysgpu.RenderBundle) void {
            T.renderBundleReference(render_bundle);
        }

        // SYSGPU_EXPORT void sysgpuRenderBundleRelease(WGPURenderBundle renderBundle);
        export fn sysgpuRenderBundleRelease(render_bundle: *sysgpu.RenderBundle) void {
            T.renderBundleRelease(render_bundle);
        }

        // SYSGPU_EXPORT void sysgpuRenderBundleEncoderDraw(WGPURenderBundleEncoder renderBundleEncoder, uint32_t vertexCount, uint32_t instanceCount, uint32_t firstVertex, uint32_t firstInstance);
        export fn sysgpuRenderBundleEncoderDraw(render_bundle_encoder: *sysgpu.RenderBundleEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {
            T.renderBundleEncoderDraw(render_bundle_encoder, vertex_count, instance_count, first_vertex, first_instance);
        }

        // SYSGPU_EXPORT void sysgpuRenderBundleEncoderDrawIndexed(WGPURenderBundleEncoder renderBundleEncoder, uint32_t indexCount, uint32_t instanceCount, uint32_t firstIndex, int32_t baseVertex, uint32_t firstInstance);
        export fn sysgpuRenderBundleEncoderDrawIndexed(render_bundle_encoder: *sysgpu.RenderBundleEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: i32, first_instance: u32) void {
            T.renderBundleEncoderDrawIndexed(render_bundle_encoder, index_count, instance_count, first_index, base_vertex, first_instance);
        }

        // SYSGPU_EXPORT void sysgpuRenderBundleEncoderDrawIndexedIndirect(WGPURenderBundleEncoder renderBundleEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
        export fn sysgpuRenderBundleEncoderDrawIndexedIndirect(render_bundle_encoder: *sysgpu.RenderBundleEncoder, indirect_buffer: *sysgpu.Buffer, indirect_offset: u64) void {
            T.renderBundleEncoderDrawIndexedIndirect(render_bundle_encoder, indirect_buffer, indirect_offset);
        }

        // SYSGPU_EXPORT void sysgpuRenderBundleEncoderDrawIndirect(WGPURenderBundleEncoder renderBundleEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
        export fn sysgpuRenderBundleEncoderDrawIndirect(render_bundle_encoder: *sysgpu.RenderBundleEncoder, indirect_buffer: *sysgpu.Buffer, indirect_offset: u64) void {
            T.renderBundleEncoderDrawIndirect(render_bundle_encoder, indirect_buffer, indirect_offset);
        }

        // SYSGPU_EXPORT WGPURenderBundle sysgpuRenderBundleEncoderFinish(WGPURenderBundleEncoder renderBundleEncoder, WGPURenderBundleDescriptor const * descriptor /* nullable */);
        export fn sysgpuRenderBundleEncoderFinish(render_bundle_encoder: *sysgpu.RenderBundleEncoder, descriptor: ?*const sysgpu.RenderBundle.Descriptor) *sysgpu.RenderBundle {
            return T.renderBundleEncoderFinish(render_bundle_encoder, descriptor);
        }

        // SYSGPU_EXPORT void sysgpuRenderBundleEncoderInsertDebugMarker(WGPURenderBundleEncoder renderBundleEncoder, char const * markerLabel);
        export fn sysgpuRenderBundleEncoderInsertDebugMarker(render_bundle_encoder: *sysgpu.RenderBundleEncoder, marker_label: [*:0]const u8) void {
            T.renderBundleEncoderInsertDebugMarker(render_bundle_encoder, marker_label);
        }

        // SYSGPU_EXPORT void sysgpuRenderBundleEncoderPopDebugGroup(WGPURenderBundleEncoder renderBundleEncoder);
        export fn sysgpuRenderBundleEncoderPopDebugGroup(render_bundle_encoder: *sysgpu.RenderBundleEncoder) void {
            T.renderBundleEncoderPopDebugGroup(render_bundle_encoder);
        }

        // SYSGPU_EXPORT void sysgpuRenderBundleEncoderPushDebugGroup(WGPURenderBundleEncoder renderBundleEncoder, char const * groupLabel);
        export fn sysgpuRenderBundleEncoderPushDebugGroup(render_bundle_encoder: *sysgpu.RenderBundleEncoder, group_label: [*:0]const u8) void {
            T.renderBundleEncoderPushDebugGroup(render_bundle_encoder, group_label);
        }

        // SYSGPU_EXPORT void sysgpuRenderBundleEncoderSetBindGroup(WGPURenderBundleEncoder renderBundleEncoder, uint32_t groupIndex, WGPUBindGroup group, size_t dynamicOffsetCount, uint32_t const * dynamicOffsets);
        export fn sysgpuRenderBundleEncoderSetBindGroup(render_bundle_encoder: *sysgpu.RenderBundleEncoder, group_index: u32, group: *sysgpu.BindGroup, dynamic_offset_count: usize, dynamic_offsets: ?[*]const u32) void {
            T.renderBundleEncoderSetBindGroup(render_bundle_encoder, group_index, group, dynamic_offset_count, dynamic_offsets);
        }

        // SYSGPU_EXPORT void sysgpuRenderBundleEncoderSetIndexBuffer(WGPURenderBundleEncoder renderBundleEncoder, WGPUBuffer buffer, WGPUIndexFormat format, uint64_t offset, uint64_t size);
        export fn sysgpuRenderBundleEncoderSetIndexBuffer(render_bundle_encoder: *sysgpu.RenderBundleEncoder, buffer: *sysgpu.Buffer, format: sysgpu.IndexFormat, offset: u64, size: u64) void {
            T.renderBundleEncoderSetIndexBuffer(render_bundle_encoder, buffer, format, offset, size);
        }

        // SYSGPU_EXPORT void sysgpuRenderBundleEncoderSetLabel(WGPURenderBundleEncoder renderBundleEncoder, char const * label);
        export fn sysgpuRenderBundleEncoderSetLabel(render_bundle_encoder: *sysgpu.RenderBundleEncoder, label: [*:0]const u8) void {
            T.renderBundleEncoderSetLabel(render_bundle_encoder, label);
        }

        // SYSGPU_EXPORT void sysgpuRenderBundleEncoderSetPipeline(WGPURenderBundleEncoder renderBundleEncoder, WGPURenderPipeline pipeline);
        export fn sysgpuRenderBundleEncoderSetPipeline(render_bundle_encoder: *sysgpu.RenderBundleEncoder, pipeline: *sysgpu.RenderPipeline) void {
            T.renderBundleEncoderSetPipeline(render_bundle_encoder, pipeline);
        }

        // SYSGPU_EXPORT void sysgpuRenderBundleEncoderSetVertexBuffer(WGPURenderBundleEncoder renderBundleEncoder, uint32_t slot, WGPUBuffer buffer, uint64_t offset, uint64_t size);
        export fn sysgpuRenderBundleEncoderSetVertexBuffer(render_bundle_encoder: *sysgpu.RenderBundleEncoder, slot: u32, buffer: *sysgpu.Buffer, offset: u64, size: u64) void {
            T.renderBundleEncoderSetVertexBuffer(render_bundle_encoder, slot, buffer, offset, size);
        }

        // SYSGPU_EXPORT void sysgpuRenderBundleEncoderReference(WGPURenderBundleEncoder renderBundleEncoder);
        export fn sysgpuRenderBundleEncoderReference(render_bundle_encoder: *sysgpu.RenderBundleEncoder) void {
            T.renderBundleEncoderReference(render_bundle_encoder);
        }

        // SYSGPU_EXPORT void sysgpuRenderBundleEncoderRelease(WGPURenderBundleEncoder renderBundleEncoder);
        export fn sysgpuRenderBundleEncoderRelease(render_bundle_encoder: *sysgpu.RenderBundleEncoder) void {
            T.renderBundleEncoderRelease(render_bundle_encoder);
        }

        // SYSGPU_EXPORT void sysgpuRenderPassEncoderBeginOcclusionQuery(WGPURenderPassEncoder renderPassEncoder, uint32_t queryIndex);
        export fn sysgpuRenderPassEncoderBeginOcclusionQuery(render_pass_encoder: *sysgpu.RenderPassEncoder, query_index: u32) void {
            T.renderPassEncoderBeginOcclusionQuery(render_pass_encoder, query_index);
        }

        // SYSGPU_EXPORT void sysgpuRenderPassEncoderDraw(WGPURenderPassEncoder renderPassEncoder, uint32_t vertexCount, uint32_t instanceCount, uint32_t firstVertex, uint32_t firstInstance);
        export fn sysgpuRenderPassEncoderDraw(render_pass_encoder: *sysgpu.RenderPassEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {
            T.renderPassEncoderDraw(render_pass_encoder, vertex_count, instance_count, first_vertex, first_instance);
        }

        // SYSGPU_EXPORT void sysgpuRenderPassEncoderDrawIndexed(WGPURenderPassEncoder renderPassEncoder, uint32_t indexCount, uint32_t instanceCount, uint32_t firstIndex, int32_t baseVertex, uint32_t firstInstance);
        export fn sysgpuRenderPassEncoderDrawIndexed(render_pass_encoder: *sysgpu.RenderPassEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: i32, first_instance: u32) void {
            T.renderPassEncoderDrawIndexed(render_pass_encoder, index_count, instance_count, first_index, base_vertex, first_instance);
        }

        // SYSGPU_EXPORT void sysgpuRenderPassEncoderDrawIndexedIndirect(WGPURenderPassEncoder renderPassEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
        export fn sysgpuRenderPassEncoderDrawIndexedIndirect(render_pass_encoder: *sysgpu.RenderPassEncoder, indirect_buffer: *sysgpu.Buffer, indirect_offset: u64) void {
            T.renderPassEncoderDrawIndexedIndirect(render_pass_encoder, indirect_buffer, indirect_offset);
        }

        // SYSGPU_EXPORT void sysgpuRenderPassEncoderDrawIndirect(WGPURenderPassEncoder renderPassEncoder, WGPUBuffer indirectBuffer, uint64_t indirectOffset);
        export fn sysgpuRenderPassEncoderDrawIndirect(render_pass_encoder: *sysgpu.RenderPassEncoder, indirect_buffer: *sysgpu.Buffer, indirect_offset: u64) void {
            T.renderPassEncoderDrawIndirect(render_pass_encoder, indirect_buffer, indirect_offset);
        }

        // SYSGPU_EXPORT void sysgpuRenderPassEncoderEnd(WGPURenderPassEncoder renderPassEncoder);
        export fn sysgpuRenderPassEncoderEnd(render_pass_encoder: *sysgpu.RenderPassEncoder) void {
            T.renderPassEncoderEnd(render_pass_encoder);
        }

        // SYSGPU_EXPORT void sysgpuRenderPassEncoderEndOcclusionQuery(WGPURenderPassEncoder renderPassEncoder);
        export fn sysgpuRenderPassEncoderEndOcclusionQuery(render_pass_encoder: *sysgpu.RenderPassEncoder) void {
            T.renderPassEncoderEndOcclusionQuery(render_pass_encoder);
        }

        // SYSGPU_EXPORT void sysgpuRenderPassEncoderExecuteBundles(WGPURenderPassEncoder renderPassEncoder, size_t bundleCount, WGPURenderBundle const * bundles);
        export fn sysgpuRenderPassEncoderExecuteBundles(render_pass_encoder: *sysgpu.RenderPassEncoder, bundles_count: usize, bundles: [*]const *const sysgpu.RenderBundle) void {
            T.renderPassEncoderExecuteBundles(render_pass_encoder, bundles_count, bundles);
        }

        // SYSGPU_EXPORT void sysgpuRenderPassEncoderInsertDebugMarker(WGPURenderPassEncoder renderPassEncoder, char const * markerLabel);
        export fn sysgpuRenderPassEncoderInsertDebugMarker(render_pass_encoder: *sysgpu.RenderPassEncoder, marker_label: [*:0]const u8) void {
            T.renderPassEncoderInsertDebugMarker(render_pass_encoder, marker_label);
        }

        // SYSGPU_EXPORT void sysgpuRenderPassEncoderPopDebugGroup(WGPURenderPassEncoder renderPassEncoder);
        export fn sysgpuRenderPassEncoderPopDebugGroup(render_pass_encoder: *sysgpu.RenderPassEncoder) void {
            T.renderPassEncoderPopDebugGroup(render_pass_encoder);
        }

        // SYSGPU_EXPORT void sysgpuRenderPassEncoderPushDebugGroup(WGPURenderPassEncoder renderPassEncoder, char const * groupLabel);
        export fn sysgpuRenderPassEncoderPushDebugGroup(render_pass_encoder: *sysgpu.RenderPassEncoder, group_label: [*:0]const u8) void {
            T.renderPassEncoderPushDebugGroup(render_pass_encoder, group_label);
        }

        // SYSGPU_EXPORT void sysgpuRenderPassEncoderSetBindGroup(WGPURenderPassEncoder renderPassEncoder, uint32_t groupIndex, WGPUBindGroup group, size_t dynamicOffsetCount, uint32_t const * dynamicOffsets);
        export fn sysgpuRenderPassEncoderSetBindGroup(render_pass_encoder: *sysgpu.RenderPassEncoder, group_index: u32, group: *sysgpu.BindGroup, dynamic_offset_count: usize, dynamic_offsets: ?[*]const u32) void {
            T.renderPassEncoderSetBindGroup(render_pass_encoder, group_index, group, dynamic_offset_count, dynamic_offsets);
        }

        // SYSGPU_EXPORT void sysgpuRenderPassEncoderSetBlendConstant(WGPURenderPassEncoder renderPassEncoder, WGPUColor const * color);
        export fn sysgpuRenderPassEncoderSetBlendConstant(render_pass_encoder: *sysgpu.RenderPassEncoder, color: *const sysgpu.Color) void {
            T.renderPassEncoderSetBlendConstant(render_pass_encoder, color);
        }

        // SYSGPU_EXPORT void sysgpuRenderPassEncoderSetIndexBuffer(WGPURenderPassEncoder renderPassEncoder, WGPUBuffer buffer, WGPUIndexFormat format, uint64_t offset, uint64_t size);
        export fn sysgpuRenderPassEncoderSetIndexBuffer(render_pass_encoder: *sysgpu.RenderPassEncoder, buffer: *sysgpu.Buffer, format: sysgpu.IndexFormat, offset: u64, size: u64) void {
            T.renderPassEncoderSetIndexBuffer(render_pass_encoder, buffer, format, offset, size);
        }

        // SYSGPU_EXPORT void sysgpuRenderPassEncoderSetLabel(WGPURenderPassEncoder renderPassEncoder, char const * label);
        export fn sysgpuRenderPassEncoderSetLabel(render_pass_encoder: *sysgpu.RenderPassEncoder, label: [*:0]const u8) void {
            T.renderPassEncoderSetLabel(render_pass_encoder, label);
        }

        // SYSGPU_EXPORT void sysgpuRenderPassEncoderSetPipeline(WGPURenderPassEncoder renderPassEncoder, WGPURenderPipeline pipeline);
        export fn sysgpuRenderPassEncoderSetPipeline(render_pass_encoder: *sysgpu.RenderPassEncoder, pipeline: *sysgpu.RenderPipeline) void {
            T.renderPassEncoderSetPipeline(render_pass_encoder, pipeline);
        }

        // SYSGPU_EXPORT void sysgpuRenderPassEncoderSetScissorRect(WGPURenderPassEncoder renderPassEncoder, uint32_t x, uint32_t y, uint32_t width, uint32_t height);
        export fn sysgpuRenderPassEncoderSetScissorRect(render_pass_encoder: *sysgpu.RenderPassEncoder, x: u32, y: u32, width: u32, height: u32) void {
            T.renderPassEncoderSetScissorRect(render_pass_encoder, x, y, width, height);
        }

        // SYSGPU_EXPORT void sysgpuRenderPassEncoderSetStencilReference(WGPURenderPassEncoder renderPassEncoder, uint32_t reference);
        export fn sysgpuRenderPassEncoderSetStencilReference(render_pass_encoder: *sysgpu.RenderPassEncoder, reference: u32) void {
            T.renderPassEncoderSetStencilReference(render_pass_encoder, reference);
        }

        // SYSGPU_EXPORT void sysgpuRenderPassEncoderSetVertexBuffer(WGPURenderPassEncoder renderPassEncoder, uint32_t slot, WGPUBuffer buffer, uint64_t offset, uint64_t size);
        export fn sysgpuRenderPassEncoderSetVertexBuffer(render_pass_encoder: *sysgpu.RenderPassEncoder, slot: u32, buffer: *sysgpu.Buffer, offset: u64, size: u64) void {
            T.renderPassEncoderSetVertexBuffer(render_pass_encoder, slot, buffer, offset, size);
        }

        // SYSGPU_EXPORT void sysgpuRenderPassEncoderSetViewport(WGPURenderPassEncoder renderPassEncoder, float x, float y, float width, float height, float minDepth, float maxDepth);
        export fn sysgpuRenderPassEncoderSetViewport(render_pass_encoder: *sysgpu.RenderPassEncoder, x: f32, y: f32, width: f32, height: f32, min_depth: f32, max_depth: f32) void {
            T.renderPassEncoderSetViewport(render_pass_encoder, x, y, width, height, min_depth, max_depth);
        }

        // SYSGPU_EXPORT void sysgpuRenderPassEncoderWriteTimestamp(WGPURenderPassEncoder renderPassEncoder, WGPUQuerySet querySet, uint32_t queryIndex);
        export fn sysgpuRenderPassEncoderWriteTimestamp(render_pass_encoder: *sysgpu.RenderPassEncoder, query_set: *sysgpu.QuerySet, query_index: u32) void {
            T.renderPassEncoderWriteTimestamp(render_pass_encoder, query_set, query_index);
        }

        // SYSGPU_EXPORT void sysgpuRenderPassEncoderReference(WGPURenderPassEncoder renderPassEncoder);
        export fn sysgpuRenderPassEncoderReference(render_pass_encoder: *sysgpu.RenderPassEncoder) void {
            T.renderPassEncoderReference(render_pass_encoder);
        }

        // SYSGPU_EXPORT void sysgpuRenderPassEncoderRelease(WGPURenderPassEncoder renderPassEncoder);
        export fn sysgpuRenderPassEncoderRelease(render_pass_encoder: *sysgpu.RenderPassEncoder) void {
            T.renderPassEncoderRelease(render_pass_encoder);
        }

        // SYSGPU_EXPORT WGPUBindGroupLayout sysgpuRenderPipelineGetBindGroupLayout(WGPURenderPipeline renderPipeline, uint32_t groupIndex);
        export fn sysgpuRenderPipelineGetBindGroupLayout(render_pipeline: *sysgpu.RenderPipeline, group_index: u32) *sysgpu.BindGroupLayout {
            return T.renderPipelineGetBindGroupLayout(render_pipeline, group_index);
        }

        // SYSGPU_EXPORT void sysgpuRenderPipelineSetLabel(WGPURenderPipeline renderPipeline, char const * label);
        export fn sysgpuRenderPipelineSetLabel(render_pipeline: *sysgpu.RenderPipeline, label: [*:0]const u8) void {
            T.renderPipelineSetLabel(render_pipeline, label);
        }

        // SYSGPU_EXPORT void sysgpuRenderPipelineReference(WGPURenderPipeline renderPipeline);
        export fn sysgpuRenderPipelineReference(render_pipeline: *sysgpu.RenderPipeline) void {
            T.renderPipelineReference(render_pipeline);
        }

        // SYSGPU_EXPORT void sysgpuRenderPipelineRelease(WGPURenderPipeline renderPipeline);
        export fn sysgpuRenderPipelineRelease(render_pipeline: *sysgpu.RenderPipeline) void {
            T.renderPipelineRelease(render_pipeline);
        }

        // SYSGPU_EXPORT void sysgpuSamplerSetLabel(WGPUSampler sampler, char const * label);
        export fn sysgpuSamplerSetLabel(sampler: *sysgpu.Sampler, label: [*:0]const u8) void {
            T.samplerSetLabel(sampler, label);
        }

        // SYSGPU_EXPORT void sysgpuSamplerReference(WGPUSampler sampler);
        export fn sysgpuSamplerReference(sampler: *sysgpu.Sampler) void {
            T.samplerReference(sampler);
        }

        // SYSGPU_EXPORT void sysgpuSamplerRelease(WGPUSampler sampler);
        export fn sysgpuSamplerRelease(sampler: *sysgpu.Sampler) void {
            T.samplerRelease(sampler);
        }

        // SYSGPU_EXPORT void sysgpuShaderModuleGetCompilationInfo(WGPUShaderModule shaderModule, WGPUCompilationInfoCallback callback, void * userdata);
        export fn sysgpuShaderModuleGetCompilationInfo(shader_module: *sysgpu.ShaderModule, callback: sysgpu.CompilationInfoCallback, userdata: ?*anyopaque) void {
            T.shaderModuleGetCompilationInfo(shader_module, callback, userdata);
        }

        // SYSGPU_EXPORT void sysgpuShaderModuleSetLabel(WGPUShaderModule shaderModule, char const * label);
        export fn sysgpuShaderModuleSetLabel(shader_module: *sysgpu.ShaderModule, label: [*:0]const u8) void {
            T.shaderModuleSetLabel(shader_module, label);
        }

        // SYSGPU_EXPORT void sysgpuShaderModuleReference(WGPUShaderModule shaderModule);
        export fn sysgpuShaderModuleReference(shader_module: *sysgpu.ShaderModule) void {
            T.shaderModuleReference(shader_module);
        }

        // SYSGPU_EXPORT void sysgpuShaderModuleRelease(WGPUShaderModule shaderModule);
        export fn sysgpuShaderModuleRelease(shader_module: *sysgpu.ShaderModule) void {
            T.shaderModuleRelease(shader_module);
        }

        // SYSGPU_EXPORT void sysgpuSharedFenceExportInfo(WGPUSharedFence sharedFence, WGPUSharedFenceExportInfo * info);
        export fn sysgpuSharedFenceExportInfo(shared_fence: *sysgpu.SharedFence, info: *sysgpu.SharedFence.ExportInfo) void {
            T.sharedFenceExportInfo(shared_fence, info);
        }

        // SYSGPU_EXPORT void sysgpuSharedFenceReference(WGPUSharedFence sharedFence);
        export fn sysgpuSharedFenceReference(shared_fence: *sysgpu.SharedFence) void {
            T.sharedFenceReference(shared_fence);
        }

        // SYSGPU_EXPORT void sysgpuSharedFenceRelease(WGPUSharedFence sharedFence);
        export fn sysgpuSharedFenceRelease(shared_fence: *sysgpu.SharedFence) void {
            T.sharedFenceRelease(shared_fence);
        }

        // SYSGPU_EXPORT void sysgpuSharedTextureMemoryBeginAccess(WGPUSharedTextureMemory sharedTextureMemory, WGPUTexture texture, WGPUSharedTextureMemoryBeginAccessDescriptor const * descriptor);
        export fn sysgpuSharedTextureMemoryBeginAccess(shared_texture_memory: *sysgpu.SharedTextureMemory, texture: *sysgpu.Texture, descriptor: *const sysgpu.SharedTextureMemory.BeginAccessDescriptor) void {
            T.sharedTextureMemoryBeginAccess(shared_texture_memory, texture, descriptor);
        }

        // SYSGPU_EXPORT WGPUTexture sysgpuSharedTextureMemoryCreateTexture(WGPUSharedTextureMemory sharedTextureMemory, WGPUTextureDescriptor const * descriptor);
        export fn sysgpuSharedTextureMemoryCreateTexture(shared_texture_memory: *sysgpu.SharedTextureMemory, descriptor: *const sysgpu.Texture.Descriptor) *sysgpu.Texture {
            return T.sharedTextureMemoryCreateTexture(shared_texture_memory, descriptor);
        }

        // SYSGPU_EXPORT void sysgpuSharedTextureMemoryEndAccess(WGPUSharedTextureMemory sharedTextureMemory, WGPUTexture texture, WGPUSharedTextureMemoryEndAccessState * descriptor);
        export fn sysgpuSharedTextureMemoryEndAccess(shared_texture_memory: *sysgpu.SharedTextureMemory, texture: *sysgpu.Texture, descriptor: *sysgpu.SharedTextureMemory.EndAccessState) void {
            T.sharedTextureMemoryEndAccess(shared_texture_memory, texture, descriptor);
        }

        // SYSGPU_EXPORT void sysgpuSharedTextureMemoryEndAccessStateFreeMembers(WGPUSharedTextureMemoryEndAccessState value);
        export fn sysgpuSharedTextureMemoryEndAccessStateFreeMembers(value: sysgpu.SharedTextureMemory.EndAccessState) void {
            T.sharedTextureMemoryEndAccessStateFreeMembers(value);
        }

        // SYSGPU_EXPORT void sysgpuSharedTextureMemoryGetProperties(WGPUSharedTextureMemory sharedTextureMemory, WGPUSharedTextureMemoryProperties * properties);
        export fn sysgpuSharedTextureMemoryGetProperties(shared_texture_memory: *sysgpu.SharedTextureMemory, properties: *sysgpu.SharedTextureMemory.Properties) void {
            T.sharedTextureMemoryGetProperties(shared_texture_memory, properties);
        }

        // SYSGPU_EXPORT void sysgpuSharedTextureMemorySetLabel(WGPUSharedTextureMemory sharedTextureMemory, char const * label);
        export fn sysgpuSharedTextureMemorySetLabel(shared_texture_memory: *sysgpu.SharedTextureMemory, label: [*:0]const u8) void {
            T.sharedTextureMemorySetLabel(shared_texture_memory, label);
        }

        // SYSGPU_EXPORT void sysgpuSharedTextureMemoryReference(WGPUSharedTextureMemory sharedTextureMemory);
        export fn sysgpuSharedTextureMemoryReference(shared_texture_memory: *sysgpu.SharedTextureMemory) void {
            T.sharedTextureMemoryReference(shared_texture_memory);
        }

        // SYSGPU_EXPORT void sysgpuSharedTextureMemoryRelease(WGPUSharedTextureMemory sharedTextureMemory);
        export fn sysgpuSharedTextureMemoryRelease(shared_texture_memory: *sysgpu.SharedTextureMemory) void {
            T.sharedTextureMemoryRelease(shared_texture_memory);
        }

        // SYSGPU_EXPORT void sysgpuSurfaceReference(WGPUSurface surface);
        export fn sysgpuSurfaceReference(surface: *sysgpu.Surface) void {
            T.surfaceReference(surface);
        }

        // SYSGPU_EXPORT void sysgpuSurfaceRelease(WGPUSurface surface);
        export fn sysgpuSurfaceRelease(surface: *sysgpu.Surface) void {
            T.surfaceRelease(surface);
        }

        // SYSGPU_EXPORT WGPUTexture sysgpuSwapChainGetCurrentTexture(WGPUSwapChain swapChain);
        export fn sysgpuSwapChainGetCurrentTexture(swap_chain: *sysgpu.SwapChain) ?*sysgpu.Texture {
            return T.swapChainGetCurrentTexture(swap_chain);
        }

        // SYSGPU_EXPORT WGPUTextureView sysgpuSwapChainGetCurrentTextureView(WGPUSwapChain swapChain);
        export fn sysgpuSwapChainGetCurrentTextureView(swap_chain: *sysgpu.SwapChain) ?*sysgpu.TextureView {
            return T.swapChainGetCurrentTextureView(swap_chain);
        }

        // SYSGPU_EXPORT void sysgpuSwapChainPresent(WGPUSwapChain swapChain);
        export fn sysgpuSwapChainPresent(swap_chain: *sysgpu.SwapChain) void {
            T.swapChainPresent(swap_chain);
        }

        // SYSGPU_EXPORT void sysgpuSwapChainReference(WGPUSwapChain swapChain);
        export fn sysgpuSwapChainReference(swap_chain: *sysgpu.SwapChain) void {
            T.swapChainReference(swap_chain);
        }

        // SYSGPU_EXPORT void sysgpuSwapChainRelease(WGPUSwapChain swapChain);
        export fn sysgpuSwapChainRelease(swap_chain: *sysgpu.SwapChain) void {
            T.swapChainRelease(swap_chain);
        }

        // SYSGPU_EXPORT WGPUTextureView sysgpuTextureCreateView(WGPUTexture texture, WGPUTextureViewDescriptor const * descriptor /* nullable */);
        export fn sysgpuTextureCreateView(texture: *sysgpu.Texture, descriptor: ?*const sysgpu.TextureView.Descriptor) *sysgpu.TextureView {
            return T.textureCreateView(texture, descriptor);
        }

        // SYSGPU_EXPORT void sysgpuTextureDestroy(WGPUTexture texture);
        export fn sysgpuTextureDestroy(texture: *sysgpu.Texture) void {
            T.textureDestroy(texture);
        }

        // SYSGPU_EXPORT uint32_t sysgpuTextureGetDepthOrArrayLayers(WGPUTexture texture);
        export fn sysgpuTextureGetDepthOrArrayLayers(texture: *sysgpu.Texture) u32 {
            return T.textureGetDepthOrArrayLayers(texture);
        }

        // SYSGPU_EXPORT WGPUTextureDimension sysgpuTextureGetDimension(WGPUTexture texture);
        export fn sysgpuTextureGetDimension(texture: *sysgpu.Texture) sysgpu.Texture.Dimension {
            return T.textureGetDimension(texture);
        }

        // SYSGPU_EXPORT WGPUTextureFormat sysgpuTextureGetFormat(WGPUTexture texture);
        export fn sysgpuTextureGetFormat(texture: *sysgpu.Texture) sysgpu.Texture.Format {
            return T.textureGetFormat(texture);
        }

        // SYSGPU_EXPORT uint32_t sysgpuTextureGetHeight(WGPUTexture texture);
        export fn sysgpuTextureGetHeight(texture: *sysgpu.Texture) u32 {
            return T.textureGetHeight(texture);
        }

        // SYSGPU_EXPORT uint32_t sysgpuTextureGetMipLevelCount(WGPUTexture texture);
        export fn sysgpuTextureGetMipLevelCount(texture: *sysgpu.Texture) u32 {
            return T.textureGetMipLevelCount(texture);
        }

        // SYSGPU_EXPORT uint32_t sysgpuTextureGetSampleCount(WGPUTexture texture);
        export fn sysgpuTextureGetSampleCount(texture: *sysgpu.Texture) u32 {
            return T.textureGetSampleCount(texture);
        }

        // SYSGPU_EXPORT WGPUTextureUsage sysgpuTextureGetUsage(WGPUTexture texture);
        export fn sysgpuTextureGetUsage(texture: *sysgpu.Texture) sysgpu.Texture.UsageFlags {
            return T.textureGetUsage(texture);
        }

        // SYSGPU_EXPORT uint32_t sysgpuTextureGetWidth(WGPUTexture texture);
        export fn sysgpuTextureGetWidth(texture: *sysgpu.Texture) u32 {
            return T.textureGetWidth(texture);
        }

        // SYSGPU_EXPORT void sysgpuTextureSetLabel(WGPUTexture texture, char const * label);
        export fn sysgpuTextureSetLabel(texture: *sysgpu.Texture, label: [*:0]const u8) void {
            T.textureSetLabel(texture, label);
        }

        // SYSGPU_EXPORT void sysgpuTextureReference(WGPUTexture texture);
        export fn sysgpuTextureReference(texture: *sysgpu.Texture) void {
            T.textureReference(texture);
        }

        // SYSGPU_EXPORT void sysgpuTextureRelease(WGPUTexture texture);
        export fn sysgpuTextureRelease(texture: *sysgpu.Texture) void {
            T.textureRelease(texture);
        }

        // SYSGPU_EXPORT void sysgpuTextureViewSetLabel(WGPUTextureView textureView, char const * label);
        export fn sysgpuTextureViewSetLabel(texture_view: *sysgpu.TextureView, label: [*:0]const u8) void {
            T.textureViewSetLabel(texture_view, label);
        }

        // SYSGPU_EXPORT void sysgpuTextureViewReference(WGPUTextureView textureView);
        export fn sysgpuTextureViewReference(texture_view: *sysgpu.TextureView) void {
            T.textureViewReference(texture_view);
        }

        // SYSGPU_EXPORT void sysgpuTextureViewRelease(WGPUTextureView textureView);
        export fn sysgpuTextureViewRelease(texture_view: *sysgpu.TextureView) void {
            T.textureViewRelease(texture_view);
        }
    };
}

/// A stub sysgpu.Interface in which every function is implemented by `unreachable;`
pub const StubInterface = Interface(struct {
    pub inline fn createInstance(descriptor: ?*const sysgpu.Instance.Descriptor) ?*sysgpu.Instance {
        _ = descriptor;
        unreachable;
    }

    pub inline fn getProcAddress(device: *sysgpu.Device, proc_name: [*:0]const u8) ?sysgpu.Proc {
        _ = device;
        _ = proc_name;
        unreachable;
    }

    pub inline fn adapterCreateDevice(adapter: *sysgpu.Adapter, descriptor: ?*const sysgpu.Device.Descriptor) ?*sysgpu.Device {
        _ = adapter;
        _ = descriptor;
        unreachable;
    }

    pub inline fn adapterEnumerateFeatures(adapter: *sysgpu.Adapter, features: ?[*]sysgpu.FeatureName) usize {
        _ = adapter;
        _ = features;
        unreachable;
    }

    pub inline fn adapterGetInstance(adapter: *sysgpu.Adapter) *sysgpu.Instance {
        _ = adapter;
        unreachable;
    }

    pub inline fn adapterGetLimits(adapter: *sysgpu.Adapter, limits: *sysgpu.SupportedLimits) u32 {
        _ = adapter;
        _ = limits;
        unreachable;
    }

    pub inline fn adapterGetProperties(adapter: *sysgpu.Adapter, properties: *sysgpu.Adapter.Properties) void {
        _ = adapter;
        _ = properties;
        unreachable;
    }

    pub inline fn adapterHasFeature(adapter: *sysgpu.Adapter, feature: sysgpu.FeatureName) u32 {
        _ = adapter;
        _ = feature;
        unreachable;
    }

    pub inline fn adapterPropertiesFreeMembers(value: sysgpu.Adapter.Properties) void {
        _ = value;
        unreachable;
    }

    pub inline fn adapterRequestDevice(adapter: *sysgpu.Adapter, descriptor: ?*const sysgpu.Device.Descriptor, callback: sysgpu.RequestDeviceCallback, userdata: ?*anyopaque) void {
        _ = adapter;
        _ = descriptor;
        _ = callback;
        _ = userdata;
        unreachable;
    }

    pub inline fn adapterReference(adapter: *sysgpu.Adapter) void {
        _ = adapter;
        unreachable;
    }

    pub inline fn adapterRelease(adapter: *sysgpu.Adapter) void {
        _ = adapter;
        unreachable;
    }

    pub inline fn bindGroupSetLabel(bind_group: *sysgpu.BindGroup, label: [*:0]const u8) void {
        _ = bind_group;
        _ = label;
        unreachable;
    }

    pub inline fn bindGroupReference(bind_group: *sysgpu.BindGroup) void {
        _ = bind_group;
        unreachable;
    }

    pub inline fn bindGroupRelease(bind_group: *sysgpu.BindGroup) void {
        _ = bind_group;
        unreachable;
    }

    pub inline fn bindGroupLayoutSetLabel(bind_group_layout: *sysgpu.BindGroupLayout, label: [*:0]const u8) void {
        _ = bind_group_layout;
        _ = label;
        unreachable;
    }

    pub inline fn bindGroupLayoutReference(bind_group_layout: *sysgpu.BindGroupLayout) void {
        _ = bind_group_layout;
        unreachable;
    }

    pub inline fn bindGroupLayoutRelease(bind_group_layout: *sysgpu.BindGroupLayout) void {
        _ = bind_group_layout;
        unreachable;
    }

    pub inline fn bufferDestroy(buffer: *sysgpu.Buffer) void {
        _ = buffer;
        unreachable;
    }

    // TODO: dawn: return value not marked as nullable in dawn.json but in fact is.
    pub inline fn bufferGetConstMappedRange(buffer: *sysgpu.Buffer, offset: usize, size: usize) ?*const anyopaque {
        _ = buffer;
        _ = offset;
        _ = size;
        unreachable;
    }

    // TODO: dawn: return value not marked as nullable in dawn.json but in fact is.
    pub inline fn bufferGetMappedRange(buffer: *sysgpu.Buffer, offset: usize, size: usize) ?*anyopaque {
        _ = buffer;
        _ = offset;
        _ = size;
        unreachable;
    }

    pub inline fn bufferGetSize(buffer: *sysgpu.Buffer) u64 {
        _ = buffer;
        unreachable;
    }

    pub inline fn bufferGetUsage(buffer: *sysgpu.Buffer) sysgpu.Buffer.UsageFlags {
        _ = buffer;
        unreachable;
    }

    pub inline fn bufferMapAsync(buffer: *sysgpu.Buffer, mode: sysgpu.MapModeFlags, offset: usize, size: usize, callback: sysgpu.Buffer.MapCallback, userdata: ?*anyopaque) void {
        _ = buffer;
        _ = mode;
        _ = offset;
        _ = size;
        _ = callback;
        _ = userdata;
        unreachable;
    }

    pub inline fn bufferSetLabel(buffer: *sysgpu.Buffer, label: [*:0]const u8) void {
        _ = buffer;
        _ = label;
        unreachable;
    }

    pub inline fn bufferUnmap(buffer: *sysgpu.Buffer) void {
        _ = buffer;
        unreachable;
    }

    pub inline fn bufferReference(buffer: *sysgpu.Buffer) void {
        _ = buffer;
        unreachable;
    }

    pub inline fn bufferRelease(buffer: *sysgpu.Buffer) void {
        _ = buffer;
        unreachable;
    }

    pub inline fn commandBufferSetLabel(command_buffer: *sysgpu.CommandBuffer, label: [*:0]const u8) void {
        _ = command_buffer;
        _ = label;
        unreachable;
    }

    pub inline fn commandBufferReference(command_buffer: *sysgpu.CommandBuffer) void {
        _ = command_buffer;
        unreachable;
    }

    pub inline fn commandBufferRelease(command_buffer: *sysgpu.CommandBuffer) void {
        _ = command_buffer;
        unreachable;
    }

    pub inline fn commandEncoderBeginComputePass(command_encoder: *sysgpu.CommandEncoder, descriptor: ?*const sysgpu.ComputePassDescriptor) *sysgpu.ComputePassEncoder {
        _ = command_encoder;
        _ = descriptor;
        unreachable;
    }

    pub inline fn commandEncoderBeginRenderPass(command_encoder: *sysgpu.CommandEncoder, descriptor: *const sysgpu.RenderPassDescriptor) *sysgpu.RenderPassEncoder {
        _ = command_encoder;
        _ = descriptor;
        unreachable;
    }

    pub inline fn commandEncoderClearBuffer(command_encoder: *sysgpu.CommandEncoder, buffer: *sysgpu.Buffer, offset: u64, size: u64) void {
        _ = command_encoder;
        _ = buffer;
        _ = offset;
        _ = size;
        unreachable;
    }

    pub inline fn commandEncoderCopyBufferToBuffer(command_encoder: *sysgpu.CommandEncoder, source: *sysgpu.Buffer, source_offset: u64, destination: *sysgpu.Buffer, destination_offset: u64, size: u64) void {
        _ = command_encoder;
        _ = source;
        _ = source_offset;
        _ = destination;
        _ = destination_offset;
        _ = size;
        unreachable;
    }

    pub inline fn commandEncoderCopyBufferToTexture(command_encoder: *sysgpu.CommandEncoder, source: *const sysgpu.ImageCopyBuffer, destination: *const sysgpu.ImageCopyTexture, copy_size: *const sysgpu.Extent3D) void {
        _ = command_encoder;
        _ = source;
        _ = destination;
        _ = copy_size;
        unreachable;
    }

    pub inline fn commandEncoderCopyTextureToBuffer(command_encoder: *sysgpu.CommandEncoder, source: *const sysgpu.ImageCopyTexture, destination: *const sysgpu.ImageCopyBuffer, copy_size: *const sysgpu.Extent3D) void {
        _ = command_encoder;
        _ = source;
        _ = destination;
        _ = copy_size;
        unreachable;
    }

    pub inline fn commandEncoderCopyTextureToTexture(command_encoder: *sysgpu.CommandEncoder, source: *const sysgpu.ImageCopyTexture, destination: *const sysgpu.ImageCopyTexture, copy_size: *const sysgpu.Extent3D) void {
        _ = command_encoder;
        _ = source;
        _ = destination;
        _ = copy_size;
        unreachable;
    }

    pub inline fn commandEncoderFinish(command_encoder: *sysgpu.CommandEncoder, descriptor: ?*const sysgpu.CommandBuffer.Descriptor) *sysgpu.CommandBuffer {
        _ = command_encoder;
        _ = descriptor;
        unreachable;
    }

    pub inline fn commandEncoderInjectValidationError(command_encoder: *sysgpu.CommandEncoder, message: [*:0]const u8) void {
        _ = command_encoder;
        _ = message;
        unreachable;
    }

    pub inline fn commandEncoderInsertDebugMarker(command_encoder: *sysgpu.CommandEncoder, marker_label: [*:0]const u8) void {
        _ = command_encoder;
        _ = marker_label;
        unreachable;
    }

    pub inline fn commandEncoderPopDebugGroup(command_encoder: *sysgpu.CommandEncoder) void {
        _ = command_encoder;
        unreachable;
    }

    pub inline fn commandEncoderPushDebugGroup(command_encoder: *sysgpu.CommandEncoder, group_label: [*:0]const u8) void {
        _ = command_encoder;
        _ = group_label;
        unreachable;
    }

    pub inline fn commandEncoderResolveQuerySet(command_encoder: *sysgpu.CommandEncoder, query_set: *sysgpu.QuerySet, first_query: u32, query_count: u32, destination: *sysgpu.Buffer, destination_offset: u64) void {
        _ = command_encoder;
        _ = query_set;
        _ = first_query;
        _ = query_count;
        _ = destination;
        _ = destination_offset;
        unreachable;
    }

    pub inline fn commandEncoderSetLabel(command_encoder: *sysgpu.CommandEncoder, label: [*:0]const u8) void {
        _ = command_encoder;
        _ = label;
        unreachable;
    }

    pub inline fn commandEncoderWriteBuffer(command_encoder: *sysgpu.CommandEncoder, buffer: *sysgpu.Buffer, buffer_offset: u64, data: [*]const u8, size: u64) void {
        _ = command_encoder;
        _ = buffer;
        _ = buffer_offset;
        _ = data;
        _ = size;
        unreachable;
    }

    pub inline fn commandEncoderWriteTimestamp(command_encoder: *sysgpu.CommandEncoder, query_set: *sysgpu.QuerySet, query_index: u32) void {
        _ = command_encoder;
        _ = query_set;
        _ = query_index;
        unreachable;
    }

    pub inline fn commandEncoderReference(command_encoder: *sysgpu.CommandEncoder) void {
        _ = command_encoder;
        unreachable;
    }

    pub inline fn commandEncoderRelease(command_encoder: *sysgpu.CommandEncoder) void {
        _ = command_encoder;
        unreachable;
    }

    pub inline fn computePassEncoderDispatchWorkgroups(compute_pass_encoder: *sysgpu.ComputePassEncoder, workgroup_count_x: u32, workgroup_count_y: u32, workgroup_count_z: u32) void {
        _ = compute_pass_encoder;
        _ = workgroup_count_x;
        _ = workgroup_count_y;
        _ = workgroup_count_z;
        unreachable;
    }

    pub inline fn computePassEncoderDispatchWorkgroupsIndirect(compute_pass_encoder: *sysgpu.ComputePassEncoder, indirect_buffer: *sysgpu.Buffer, indirect_offset: u64) void {
        _ = compute_pass_encoder;
        _ = indirect_buffer;
        _ = indirect_offset;
        unreachable;
    }

    pub inline fn computePassEncoderEnd(compute_pass_encoder: *sysgpu.ComputePassEncoder) void {
        _ = compute_pass_encoder;
        unreachable;
    }

    pub inline fn computePassEncoderInsertDebugMarker(compute_pass_encoder: *sysgpu.ComputePassEncoder, marker_label: [*:0]const u8) void {
        _ = compute_pass_encoder;
        _ = marker_label;
        unreachable;
    }

    pub inline fn computePassEncoderPopDebugGroup(compute_pass_encoder: *sysgpu.ComputePassEncoder) void {
        _ = compute_pass_encoder;
        unreachable;
    }

    pub inline fn computePassEncoderPushDebugGroup(compute_pass_encoder: *sysgpu.ComputePassEncoder, group_label: [*:0]const u8) void {
        _ = compute_pass_encoder;
        _ = group_label;
        unreachable;
    }

    pub inline fn computePassEncoderSetBindGroup(compute_pass_encoder: *sysgpu.ComputePassEncoder, group_index: u32, group: *sysgpu.BindGroup, dynamic_offset_count: usize, dynamic_offsets: ?[*]const u32) void {
        _ = compute_pass_encoder;
        _ = group_index;
        _ = group;
        _ = dynamic_offset_count;
        _ = dynamic_offsets;
        unreachable;
    }

    pub inline fn computePassEncoderSetLabel(compute_pass_encoder: *sysgpu.ComputePassEncoder, label: [*:0]const u8) void {
        _ = compute_pass_encoder;
        _ = label;
        unreachable;
    }

    pub inline fn computePassEncoderSetPipeline(compute_pass_encoder: *sysgpu.ComputePassEncoder, pipeline: *sysgpu.ComputePipeline) void {
        _ = compute_pass_encoder;
        _ = pipeline;
        unreachable;
    }

    pub inline fn computePassEncoderWriteTimestamp(compute_pass_encoder: *sysgpu.ComputePassEncoder, query_set: *sysgpu.QuerySet, query_index: u32) void {
        _ = compute_pass_encoder;
        _ = query_set;
        _ = query_index;
        unreachable;
    }

    pub inline fn computePassEncoderReference(compute_pass_encoder: *sysgpu.ComputePassEncoder) void {
        _ = compute_pass_encoder;
        unreachable;
    }

    pub inline fn computePassEncoderRelease(compute_pass_encoder: *sysgpu.ComputePassEncoder) void {
        _ = compute_pass_encoder;
        unreachable;
    }

    pub inline fn computePipelineGetBindGroupLayout(compute_pipeline: *sysgpu.ComputePipeline, group_index: u32) *sysgpu.BindGroupLayout {
        _ = compute_pipeline;
        _ = group_index;
        unreachable;
    }

    pub inline fn computePipelineSetLabel(compute_pipeline: *sysgpu.ComputePipeline, label: [*:0]const u8) void {
        _ = compute_pipeline;
        _ = label;
        unreachable;
    }

    pub inline fn computePipelineReference(compute_pipeline: *sysgpu.ComputePipeline) void {
        _ = compute_pipeline;
        unreachable;
    }

    pub inline fn computePipelineRelease(compute_pipeline: *sysgpu.ComputePipeline) void {
        _ = compute_pipeline;
        unreachable;
    }

    pub inline fn deviceCreateBindGroup(device: *sysgpu.Device, descriptor: *const sysgpu.BindGroup.Descriptor) *sysgpu.BindGroup {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceCreateBindGroupLayout(device: *sysgpu.Device, descriptor: *const sysgpu.BindGroupLayout.Descriptor) *sysgpu.BindGroupLayout {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceCreateBuffer(device: *sysgpu.Device, descriptor: *const sysgpu.Buffer.Descriptor) *sysgpu.Buffer {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceCreateCommandEncoder(device: *sysgpu.Device, descriptor: ?*const sysgpu.CommandEncoder.Descriptor) *sysgpu.CommandEncoder {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceCreateComputePipeline(device: *sysgpu.Device, descriptor: *const sysgpu.ComputePipeline.Descriptor) *sysgpu.ComputePipeline {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceCreateComputePipelineAsync(device: *sysgpu.Device, descriptor: *const sysgpu.ComputePipeline.Descriptor, callback: sysgpu.CreateComputePipelineAsyncCallback, userdata: ?*anyopaque) void {
        _ = device;
        _ = descriptor;
        _ = callback;
        _ = userdata;
        unreachable;
    }

    pub inline fn deviceCreateErrorBuffer(device: *sysgpu.Device, descriptor: *const sysgpu.Buffer.Descriptor) *sysgpu.Buffer {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceCreateErrorExternalTexture(device: *sysgpu.Device) *sysgpu.ExternalTexture {
        _ = device;
        unreachable;
    }

    pub inline fn deviceCreateErrorTexture(device: *sysgpu.Device, descriptor: *const sysgpu.Texture.Descriptor) *sysgpu.Texture {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceCreateExternalTexture(device: *sysgpu.Device, external_texture_descriptor: *const sysgpu.ExternalTexture.Descriptor) *sysgpu.ExternalTexture {
        _ = device;
        _ = external_texture_descriptor;
        unreachable;
    }

    pub inline fn deviceCreatePipelineLayout(device: *sysgpu.Device, pipeline_layout_descriptor: *const sysgpu.PipelineLayout.Descriptor) *sysgpu.PipelineLayout {
        _ = device;
        _ = pipeline_layout_descriptor;
        unreachable;
    }

    pub inline fn deviceCreateQuerySet(device: *sysgpu.Device, descriptor: *const sysgpu.QuerySet.Descriptor) *sysgpu.QuerySet {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceCreateRenderBundleEncoder(device: *sysgpu.Device, descriptor: *const sysgpu.RenderBundleEncoder.Descriptor) *sysgpu.RenderBundleEncoder {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceCreateRenderPipeline(device: *sysgpu.Device, descriptor: *const sysgpu.RenderPipeline.Descriptor) *sysgpu.RenderPipeline {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceCreateRenderPipelineAsync(device: *sysgpu.Device, descriptor: *const sysgpu.RenderPipeline.Descriptor, callback: sysgpu.CreateRenderPipelineAsyncCallback, userdata: ?*anyopaque) void {
        _ = device;
        _ = descriptor;
        _ = callback;
        _ = userdata;
        unreachable;
    }

    pub inline fn deviceCreateSampler(device: *sysgpu.Device, descriptor: ?*const sysgpu.Sampler.Descriptor) *sysgpu.Sampler {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceCreateShaderModule(device: *sysgpu.Device, descriptor: *const sysgpu.ShaderModule.Descriptor) *sysgpu.ShaderModule {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceCreateSwapChain(device: *sysgpu.Device, surface: ?*sysgpu.Surface, descriptor: *const sysgpu.SwapChain.Descriptor) *sysgpu.SwapChain {
        _ = device;
        _ = surface;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceCreateTexture(device: *sysgpu.Device, descriptor: *const sysgpu.Texture.Descriptor) *sysgpu.Texture {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceDestroy(device: *sysgpu.Device) void {
        _ = device;
        unreachable;
    }

    pub inline fn deviceEnumerateFeatures(device: *sysgpu.Device, features: ?[*]sysgpu.FeatureName) usize {
        _ = device;
        _ = features;
        unreachable;
    }

    pub inline fn deviceGetLimits(device: *sysgpu.Device, limits: *sysgpu.SupportedLimits) u32 {
        _ = device;
        _ = limits;
        unreachable;
    }

    pub inline fn deviceGetQueue(device: *sysgpu.Device) *sysgpu.Queue {
        _ = device;
        unreachable;
    }

    pub inline fn deviceHasFeature(device: *sysgpu.Device, feature: sysgpu.FeatureName) u32 {
        _ = device;
        _ = feature;
        unreachable;
    }

    pub inline fn deviceImportSharedFence(device: *sysgpu.Device, descriptor: *const sysgpu.SharedFence.Descriptor) *sysgpu.SharedFence {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceImportSharedTextureMemory(device: *sysgpu.Device, descriptor: *const sysgpu.SharedTextureMemory.Descriptor) *sysgpu.SharedTextureMemory {
        _ = device;
        _ = descriptor;
        unreachable;
    }

    pub inline fn deviceInjectError(device: *sysgpu.Device, typ: sysgpu.ErrorType, message: [*:0]const u8) void {
        _ = device;
        _ = typ;
        _ = message;
        unreachable;
    }

    pub inline fn deviceLoseForTesting(device: *sysgpu.Device) void {
        _ = device;
        unreachable;
    }

    pub inline fn devicePopErrorScope(device: *sysgpu.Device, callback: sysgpu.ErrorCallback, userdata: ?*anyopaque) void {
        _ = device;
        _ = callback;
        _ = userdata;
        unreachable;
    }

    pub inline fn devicePushErrorScope(device: *sysgpu.Device, filter: sysgpu.ErrorFilter) void {
        _ = device;
        _ = filter;
        unreachable;
    }

    pub inline fn deviceSetDeviceLostCallback(device: *sysgpu.Device, callback: ?sysgpu.Device.LostCallback, userdata: ?*anyopaque) void {
        _ = device;
        _ = callback;
        _ = userdata;
        unreachable;
    }

    pub inline fn deviceSetLabel(device: *sysgpu.Device, label: [*:0]const u8) void {
        _ = device;
        _ = label;
        unreachable;
    }

    pub inline fn deviceSetLoggingCallback(device: *sysgpu.Device, callback: ?sysgpu.LoggingCallback, userdata: ?*anyopaque) void {
        _ = device;
        _ = callback;
        _ = userdata;
        unreachable;
    }

    pub inline fn deviceSetUncapturedErrorCallback(device: *sysgpu.Device, callback: ?sysgpu.ErrorCallback, userdata: ?*anyopaque) void {
        _ = device;
        _ = callback;
        _ = userdata;
        unreachable;
    }

    pub inline fn deviceTick(device: *sysgpu.Device) void {
        _ = device;
        unreachable;
    }

    pub inline fn machDeviceWaitForCommandsToBeScheduled(device: *sysgpu.Device) void {
        _ = device;
        unreachable;
    }

    pub inline fn deviceReference(device: *sysgpu.Device) void {
        _ = device;
        unreachable;
    }

    pub inline fn deviceRelease(device: *sysgpu.Device) void {
        _ = device;
        unreachable;
    }

    pub inline fn externalTextureDestroy(external_texture: *sysgpu.ExternalTexture) void {
        _ = external_texture;
        unreachable;
    }

    pub inline fn externalTextureSetLabel(external_texture: *sysgpu.ExternalTexture, label: [*:0]const u8) void {
        _ = external_texture;
        _ = label;
        unreachable;
    }

    pub inline fn externalTextureReference(external_texture: *sysgpu.ExternalTexture) void {
        _ = external_texture;
        unreachable;
    }

    pub inline fn externalTextureRelease(external_texture: *sysgpu.ExternalTexture) void {
        _ = external_texture;
        unreachable;
    }

    pub inline fn instanceCreateSurface(instance: *sysgpu.Instance, descriptor: *const sysgpu.Surface.Descriptor) *sysgpu.Surface {
        _ = instance;
        _ = descriptor;
        unreachable;
    }

    pub inline fn instanceProcessEvents(instance: *sysgpu.Instance) void {
        _ = instance;
        unreachable;
    }

    pub inline fn instanceRequestAdapter(instance: *sysgpu.Instance, options: ?*const sysgpu.RequestAdapterOptions, callback: sysgpu.RequestAdapterCallback, userdata: ?*anyopaque) void {
        _ = instance;
        _ = options;
        _ = callback;
        _ = userdata;
        unreachable;
    }

    pub inline fn instanceReference(instance: *sysgpu.Instance) void {
        _ = instance;
        unreachable;
    }

    pub inline fn instanceRelease(instance: *sysgpu.Instance) void {
        _ = instance;
        unreachable;
    }

    pub inline fn pipelineLayoutSetLabel(pipeline_layout: *sysgpu.PipelineLayout, label: [*:0]const u8) void {
        _ = pipeline_layout;
        _ = label;
        unreachable;
    }

    pub inline fn pipelineLayoutReference(pipeline_layout: *sysgpu.PipelineLayout) void {
        _ = pipeline_layout;
        unreachable;
    }

    pub inline fn pipelineLayoutRelease(pipeline_layout: *sysgpu.PipelineLayout) void {
        _ = pipeline_layout;
        unreachable;
    }

    pub inline fn querySetDestroy(query_set: *sysgpu.QuerySet) void {
        _ = query_set;
        unreachable;
    }

    pub inline fn querySetGetCount(query_set: *sysgpu.QuerySet) u32 {
        _ = query_set;
        unreachable;
    }

    pub inline fn querySetGetType(query_set: *sysgpu.QuerySet) sysgpu.QueryType {
        _ = query_set;
        unreachable;
    }

    pub inline fn querySetSetLabel(query_set: *sysgpu.QuerySet, label: [*:0]const u8) void {
        _ = query_set;
        _ = label;
        unreachable;
    }

    pub inline fn querySetReference(query_set: *sysgpu.QuerySet) void {
        _ = query_set;
        unreachable;
    }

    pub inline fn querySetRelease(query_set: *sysgpu.QuerySet) void {
        _ = query_set;
        unreachable;
    }

    pub inline fn queueCopyTextureForBrowser(queue: *sysgpu.Queue, source: *const sysgpu.ImageCopyTexture, destination: *const sysgpu.ImageCopyTexture, copy_size: *const sysgpu.Extent3D, options: *const sysgpu.CopyTextureForBrowserOptions) void {
        _ = queue;
        _ = source;
        _ = destination;
        _ = copy_size;
        _ = options;
        unreachable;
    }

    pub inline fn queueOnSubmittedWorkDone(queue: *sysgpu.Queue, signal_value: u64, callback: sysgpu.Queue.WorkDoneCallback, userdata: ?*anyopaque) void {
        _ = queue;
        _ = signal_value;
        _ = callback;
        _ = userdata;
        unreachable;
    }

    pub inline fn queueSetLabel(queue: *sysgpu.Queue, label: [*:0]const u8) void {
        _ = queue;
        _ = label;
        unreachable;
    }

    pub inline fn queueSubmit(queue: *sysgpu.Queue, command_count: usize, commands: [*]const *const sysgpu.CommandBuffer) void {
        _ = queue;
        _ = command_count;
        _ = commands;
        unreachable;
    }

    pub inline fn queueWriteBuffer(queue: *sysgpu.Queue, buffer: *sysgpu.Buffer, buffer_offset: u64, data: *const anyopaque, size: usize) void {
        _ = queue;
        _ = buffer;
        _ = buffer_offset;
        _ = data;
        _ = size;
        unreachable;
    }

    pub inline fn queueWriteTexture(queue: *sysgpu.Queue, destination: *const sysgpu.ImageCopyTexture, data: *const anyopaque, data_size: usize, data_layout: *const sysgpu.Texture.DataLayout, write_size: *const sysgpu.Extent3D) void {
        _ = queue;
        _ = destination;
        _ = data;
        _ = data_size;
        _ = data_layout;
        _ = write_size;
        unreachable;
    }

    pub inline fn queueReference(queue: *sysgpu.Queue) void {
        _ = queue;
        unreachable;
    }

    pub inline fn queueRelease(queue: *sysgpu.Queue) void {
        _ = queue;
        unreachable;
    }

    pub inline fn renderBundleSetLabel(render_bundle: *sysgpu.RenderBundle, label: [*:0]const u8) void {
        _ = render_bundle;
        _ = label;
        unreachable;
    }

    pub inline fn renderBundleReference(render_bundle: *sysgpu.RenderBundle) void {
        _ = render_bundle;
        unreachable;
    }

    pub inline fn renderBundleRelease(render_bundle: *sysgpu.RenderBundle) void {
        _ = render_bundle;
        unreachable;
    }

    pub inline fn renderBundleEncoderDraw(render_bundle_encoder: *sysgpu.RenderBundleEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {
        _ = render_bundle_encoder;
        _ = vertex_count;
        _ = instance_count;
        _ = first_vertex;
        _ = first_instance;
        unreachable;
    }

    pub inline fn renderBundleEncoderDrawIndexed(render_bundle_encoder: *sysgpu.RenderBundleEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: i32, first_instance: u32) void {
        _ = render_bundle_encoder;
        _ = index_count;
        _ = instance_count;
        _ = first_index;
        _ = base_vertex;
        _ = first_instance;
        unreachable;
    }

    pub inline fn renderBundleEncoderDrawIndexedIndirect(render_bundle_encoder: *sysgpu.RenderBundleEncoder, indirect_buffer: *sysgpu.Buffer, indirect_offset: u64) void {
        _ = render_bundle_encoder;
        _ = indirect_buffer;
        _ = indirect_offset;
        unreachable;
    }

    pub inline fn renderBundleEncoderDrawIndirect(render_bundle_encoder: *sysgpu.RenderBundleEncoder, indirect_buffer: *sysgpu.Buffer, indirect_offset: u64) void {
        _ = render_bundle_encoder;
        _ = indirect_buffer;
        _ = indirect_offset;
        unreachable;
    }

    pub inline fn renderBundleEncoderFinish(render_bundle_encoder: *sysgpu.RenderBundleEncoder, descriptor: ?*const sysgpu.RenderBundle.Descriptor) *sysgpu.RenderBundle {
        _ = render_bundle_encoder;
        _ = descriptor;
        unreachable;
    }

    pub inline fn renderBundleEncoderInsertDebugMarker(render_bundle_encoder: *sysgpu.RenderBundleEncoder, marker_label: [*:0]const u8) void {
        _ = render_bundle_encoder;
        _ = marker_label;
        unreachable;
    }

    pub inline fn renderBundleEncoderPopDebugGroup(render_bundle_encoder: *sysgpu.RenderBundleEncoder) void {
        _ = render_bundle_encoder;
        unreachable;
    }

    pub inline fn renderBundleEncoderPushDebugGroup(render_bundle_encoder: *sysgpu.RenderBundleEncoder, group_label: [*:0]const u8) void {
        _ = render_bundle_encoder;
        _ = group_label;
        unreachable;
    }

    pub inline fn renderBundleEncoderSetBindGroup(render_bundle_encoder: *sysgpu.RenderBundleEncoder, group_index: u32, group: *sysgpu.BindGroup, dynamic_offset_count: usize, dynamic_offsets: ?[*]const u32) void {
        _ = render_bundle_encoder;
        _ = group_index;
        _ = group;
        _ = dynamic_offset_count;
        _ = dynamic_offsets;
        unreachable;
    }

    pub inline fn renderBundleEncoderSetIndexBuffer(render_bundle_encoder: *sysgpu.RenderBundleEncoder, buffer: *sysgpu.Buffer, format: sysgpu.IndexFormat, offset: u64, size: u64) void {
        _ = render_bundle_encoder;
        _ = buffer;
        _ = format;
        _ = offset;
        _ = size;
        unreachable;
    }

    pub inline fn renderBundleEncoderSetLabel(render_bundle_encoder: *sysgpu.RenderBundleEncoder, label: [*:0]const u8) void {
        _ = render_bundle_encoder;
        _ = label;
        unreachable;
    }

    pub inline fn renderBundleEncoderSetPipeline(render_bundle_encoder: *sysgpu.RenderBundleEncoder, pipeline: *sysgpu.RenderPipeline) void {
        _ = render_bundle_encoder;
        _ = pipeline;
        unreachable;
    }

    pub inline fn renderBundleEncoderSetVertexBuffer(render_bundle_encoder: *sysgpu.RenderBundleEncoder, slot: u32, buffer: *sysgpu.Buffer, offset: u64, size: u64) void {
        _ = render_bundle_encoder;
        _ = slot;
        _ = buffer;
        _ = offset;
        _ = size;
        unreachable;
    }

    pub inline fn renderBundleEncoderReference(render_bundle_encoder: *sysgpu.RenderBundleEncoder) void {
        _ = render_bundle_encoder;
        unreachable;
    }

    pub inline fn renderBundleEncoderRelease(render_bundle_encoder: *sysgpu.RenderBundleEncoder) void {
        _ = render_bundle_encoder;
        unreachable;
    }

    pub inline fn renderPassEncoderBeginOcclusionQuery(render_pass_encoder: *sysgpu.RenderPassEncoder, query_index: u32) void {
        _ = render_pass_encoder;
        _ = query_index;
        unreachable;
    }

    pub inline fn renderPassEncoderDraw(render_pass_encoder: *sysgpu.RenderPassEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {
        _ = render_pass_encoder;
        _ = vertex_count;
        _ = instance_count;
        _ = first_vertex;
        _ = first_instance;
        unreachable;
    }

    pub inline fn renderPassEncoderDrawIndexed(render_pass_encoder: *sysgpu.RenderPassEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: i32, first_instance: u32) void {
        _ = render_pass_encoder;
        _ = index_count;
        _ = instance_count;
        _ = first_index;
        _ = base_vertex;
        _ = first_instance;
        unreachable;
    }

    pub inline fn renderPassEncoderDrawIndexedIndirect(render_pass_encoder: *sysgpu.RenderPassEncoder, indirect_buffer: *sysgpu.Buffer, indirect_offset: u64) void {
        _ = render_pass_encoder;
        _ = indirect_buffer;
        _ = indirect_offset;
        unreachable;
    }

    pub inline fn renderPassEncoderDrawIndirect(render_pass_encoder: *sysgpu.RenderPassEncoder, indirect_buffer: *sysgpu.Buffer, indirect_offset: u64) void {
        _ = render_pass_encoder;
        _ = indirect_buffer;
        _ = indirect_offset;
        unreachable;
    }

    pub inline fn renderPassEncoderEnd(render_pass_encoder: *sysgpu.RenderPassEncoder) void {
        _ = render_pass_encoder;
        unreachable;
    }

    pub inline fn renderPassEncoderEndOcclusionQuery(render_pass_encoder: *sysgpu.RenderPassEncoder) void {
        _ = render_pass_encoder;
        unreachable;
    }

    pub inline fn renderPassEncoderExecuteBundles(render_pass_encoder: *sysgpu.RenderPassEncoder, bundles_count: usize, bundles: [*]const *const sysgpu.RenderBundle) void {
        _ = render_pass_encoder;
        _ = bundles_count;
        _ = bundles;
        unreachable;
    }

    pub inline fn renderPassEncoderInsertDebugMarker(render_pass_encoder: *sysgpu.RenderPassEncoder, marker_label: [*:0]const u8) void {
        _ = render_pass_encoder;
        _ = marker_label;
        unreachable;
    }

    pub inline fn renderPassEncoderPopDebugGroup(render_pass_encoder: *sysgpu.RenderPassEncoder) void {
        _ = render_pass_encoder;
        unreachable;
    }

    pub inline fn renderPassEncoderPushDebugGroup(render_pass_encoder: *sysgpu.RenderPassEncoder, group_label: [*:0]const u8) void {
        _ = render_pass_encoder;
        _ = group_label;
        unreachable;
    }

    pub inline fn renderPassEncoderSetBindGroup(render_pass_encoder: *sysgpu.RenderPassEncoder, group_index: u32, group: *sysgpu.BindGroup, dynamic_offset_count: usize, dynamic_offsets: ?[*]const u32) void {
        _ = render_pass_encoder;
        _ = group_index;
        _ = group;
        _ = dynamic_offset_count;
        _ = dynamic_offsets;
        unreachable;
    }

    pub inline fn renderPassEncoderSetBlendConstant(render_pass_encoder: *sysgpu.RenderPassEncoder, color: *const sysgpu.Color) void {
        _ = render_pass_encoder;
        _ = color;
        unreachable;
    }

    pub inline fn renderPassEncoderSetIndexBuffer(render_pass_encoder: *sysgpu.RenderPassEncoder, buffer: *sysgpu.Buffer, format: sysgpu.IndexFormat, offset: u64, size: u64) void {
        _ = render_pass_encoder;
        _ = buffer;
        _ = format;
        _ = offset;
        _ = size;
        unreachable;
    }

    pub inline fn renderPassEncoderSetLabel(render_pass_encoder: *sysgpu.RenderPassEncoder, label: [*:0]const u8) void {
        _ = render_pass_encoder;
        _ = label;
        unreachable;
    }

    pub inline fn renderPassEncoderSetPipeline(render_pass_encoder: *sysgpu.RenderPassEncoder, pipeline: *sysgpu.RenderPipeline) void {
        _ = render_pass_encoder;
        _ = pipeline;
        unreachable;
    }

    pub inline fn renderPassEncoderSetScissorRect(render_pass_encoder: *sysgpu.RenderPassEncoder, x: u32, y: u32, width: u32, height: u32) void {
        _ = render_pass_encoder;
        _ = x;
        _ = y;
        _ = width;
        _ = height;
        unreachable;
    }

    pub inline fn renderPassEncoderSetStencilReference(render_pass_encoder: *sysgpu.RenderPassEncoder, reference: u32) void {
        _ = render_pass_encoder;
        _ = reference;
        unreachable;
    }

    pub inline fn renderPassEncoderSetVertexBuffer(render_pass_encoder: *sysgpu.RenderPassEncoder, slot: u32, buffer: *sysgpu.Buffer, offset: u64, size: u64) void {
        _ = render_pass_encoder;
        _ = slot;
        _ = buffer;
        _ = offset;
        _ = size;
        unreachable;
    }

    pub inline fn renderPassEncoderSetViewport(render_pass_encoder: *sysgpu.RenderPassEncoder, x: f32, y: f32, width: f32, height: f32, min_depth: f32, max_depth: f32) void {
        _ = render_pass_encoder;
        _ = x;
        _ = y;
        _ = width;
        _ = height;
        _ = min_depth;
        _ = max_depth;
        unreachable;
    }

    pub inline fn renderPassEncoderWriteTimestamp(render_pass_encoder: *sysgpu.RenderPassEncoder, query_set: *sysgpu.QuerySet, query_index: u32) void {
        _ = render_pass_encoder;
        _ = query_set;
        _ = query_index;
        unreachable;
    }

    pub inline fn renderPassEncoderReference(render_pass_encoder: *sysgpu.RenderPassEncoder) void {
        _ = render_pass_encoder;
        unreachable;
    }

    pub inline fn renderPassEncoderRelease(render_pass_encoder: *sysgpu.RenderPassEncoder) void {
        _ = render_pass_encoder;
        unreachable;
    }

    pub inline fn renderPipelineGetBindGroupLayout(render_pipeline: *sysgpu.RenderPipeline, group_index: u32) *sysgpu.BindGroupLayout {
        _ = render_pipeline;
        _ = group_index;
        unreachable;
    }

    pub inline fn renderPipelineSetLabel(render_pipeline: *sysgpu.RenderPipeline, label: [*:0]const u8) void {
        _ = render_pipeline;
        _ = label;
        unreachable;
    }

    pub inline fn renderPipelineReference(render_pipeline: *sysgpu.RenderPipeline) void {
        _ = render_pipeline;
        unreachable;
    }

    pub inline fn renderPipelineRelease(render_pipeline: *sysgpu.RenderPipeline) void {
        _ = render_pipeline;
        unreachable;
    }

    pub inline fn samplerSetLabel(sampler: *sysgpu.Sampler, label: [*:0]const u8) void {
        _ = sampler;
        _ = label;
        unreachable;
    }

    pub inline fn samplerReference(sampler: *sysgpu.Sampler) void {
        _ = sampler;
        unreachable;
    }

    pub inline fn samplerRelease(sampler: *sysgpu.Sampler) void {
        _ = sampler;
        unreachable;
    }

    pub inline fn shaderModuleGetCompilationInfo(shader_module: *sysgpu.ShaderModule, callback: sysgpu.CompilationInfoCallback, userdata: ?*anyopaque) void {
        _ = shader_module;
        _ = callback;
        _ = userdata;
        unreachable;
    }

    pub inline fn shaderModuleSetLabel(shader_module: *sysgpu.ShaderModule, label: [*:0]const u8) void {
        _ = shader_module;
        _ = label;
        unreachable;
    }

    pub inline fn shaderModuleReference(shader_module: *sysgpu.ShaderModule) void {
        _ = shader_module;
        unreachable;
    }

    pub inline fn shaderModuleRelease(shader_module: *sysgpu.ShaderModule) void {
        _ = shader_module;
        unreachable;
    }

    pub inline fn sharedFenceExportInfo(shared_fence: *sysgpu.SharedFence, info: *sysgpu.SharedFence.ExportInfo) void {
        _ = shared_fence;
        _ = info;
        unreachable;
    }

    pub inline fn sharedFenceReference(shared_fence: *sysgpu.SharedFence) void {
        _ = shared_fence;
        unreachable;
    }

    pub inline fn sharedFenceRelease(shared_fence: *sysgpu.SharedFence) void {
        _ = shared_fence;
        unreachable;
    }

    pub inline fn sharedTextureMemoryBeginAccess(shared_texture_memory: *sysgpu.SharedTextureMemory, texture: *sysgpu.Texture, descriptor: *const sysgpu.SharedTextureMemory.BeginAccessDescriptor) void {
        _ = shared_texture_memory;
        _ = texture;
        _ = descriptor;
        unreachable;
    }

    pub inline fn sharedTextureMemoryCreateTexture(shared_texture_memory: *sysgpu.SharedTextureMemory, descriptor: *const sysgpu.Texture.Descriptor) *sysgpu.Texture {
        _ = shared_texture_memory;
        _ = descriptor;
        unreachable;
    }

    pub inline fn sharedTextureMemoryEndAccess(shared_texture_memory: *sysgpu.SharedTextureMemory, texture: *sysgpu.Texture, descriptor: *sysgpu.SharedTextureMemory.EndAccessState) void {
        _ = shared_texture_memory;
        _ = texture;
        _ = descriptor;
        unreachable;
    }

    pub inline fn sharedTextureMemoryEndAccessStateFreeMembers(value: sysgpu.SharedTextureMemory.EndAccessState) void {
        _ = value;
        unreachable;
    }

    pub inline fn sharedTextureMemoryGetProperties(shared_texture_memory: *sysgpu.SharedTextureMemory, properties: *sysgpu.SharedTextureMemory.Properties) void {
        _ = shared_texture_memory;
        _ = properties;
        unreachable;
    }

    pub inline fn sharedTextureMemorySetLabel(shared_texture_memory: *sysgpu.SharedTextureMemory, label: [*:0]const u8) void {
        _ = shared_texture_memory;
        _ = label;
        unreachable;
    }

    pub inline fn sharedTextureMemoryReference(shared_texture_memory: *sysgpu.SharedTextureMemory) void {
        _ = shared_texture_memory;
        unreachable;
    }

    pub inline fn sharedTextureMemoryRelease(shared_texture_memory: *sysgpu.SharedTextureMemory) void {
        _ = shared_texture_memory;
        unreachable;
    }

    pub inline fn surfaceReference(surface: *sysgpu.Surface) void {
        _ = surface;
        unreachable;
    }

    pub inline fn surfaceRelease(surface: *sysgpu.Surface) void {
        _ = surface;
        unreachable;
    }

    pub inline fn swapChainGetCurrentTexture(swap_chain: *sysgpu.SwapChain) ?*sysgpu.Texture {
        _ = swap_chain;
        unreachable;
    }

    pub inline fn swapChainGetCurrentTextureView(swap_chain: *sysgpu.SwapChain) ?*sysgpu.TextureView {
        _ = swap_chain;
        unreachable;
    }

    pub inline fn swapChainPresent(swap_chain: *sysgpu.SwapChain) void {
        _ = swap_chain;
        unreachable;
    }

    pub inline fn swapChainReference(swap_chain: *sysgpu.SwapChain) void {
        _ = swap_chain;
        unreachable;
    }

    pub inline fn swapChainRelease(swap_chain: *sysgpu.SwapChain) void {
        _ = swap_chain;
        unreachable;
    }

    pub inline fn textureCreateView(texture: *sysgpu.Texture, descriptor: ?*const sysgpu.TextureView.Descriptor) *sysgpu.TextureView {
        _ = texture;
        _ = descriptor;
        unreachable;
    }

    pub inline fn textureDestroy(texture: *sysgpu.Texture) void {
        _ = texture;
        unreachable;
    }

    pub inline fn textureGetDepthOrArrayLayers(texture: *sysgpu.Texture) u32 {
        _ = texture;
        unreachable;
    }

    pub inline fn textureGetDimension(texture: *sysgpu.Texture) sysgpu.Texture.Dimension {
        _ = texture;
        unreachable;
    }

    pub inline fn textureGetFormat(texture: *sysgpu.Texture) sysgpu.Texture.Format {
        _ = texture;
        unreachable;
    }

    pub inline fn textureGetHeight(texture: *sysgpu.Texture) u32 {
        _ = texture;
        unreachable;
    }

    pub inline fn textureGetMipLevelCount(texture: *sysgpu.Texture) u32 {
        _ = texture;
        unreachable;
    }

    pub inline fn textureGetSampleCount(texture: *sysgpu.Texture) u32 {
        _ = texture;
        unreachable;
    }

    pub inline fn textureGetUsage(texture: *sysgpu.Texture) sysgpu.Texture.UsageFlags {
        _ = texture;
        unreachable;
    }

    pub inline fn textureGetWidth(texture: *sysgpu.Texture) u32 {
        _ = texture;
        unreachable;
    }

    pub inline fn textureSetLabel(texture: *sysgpu.Texture, label: [*:0]const u8) void {
        _ = texture;
        _ = label;
        unreachable;
    }

    pub inline fn textureReference(texture: *sysgpu.Texture) void {
        _ = texture;
        unreachable;
    }

    pub inline fn textureRelease(texture: *sysgpu.Texture) void {
        _ = texture;
        unreachable;
    }

    pub inline fn textureViewSetLabel(texture_view: *sysgpu.TextureView, label: [*:0]const u8) void {
        _ = texture_view;
        _ = label;
        unreachable;
    }

    pub inline fn textureViewReference(texture_view: *sysgpu.TextureView) void {
        _ = texture_view;
        unreachable;
    }

    pub inline fn textureViewRelease(texture_view: *sysgpu.TextureView) void {
        _ = texture_view;
        unreachable;
    }
});

test "stub" {
    _ = StubInterface;
}
