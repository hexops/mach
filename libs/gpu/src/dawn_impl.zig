const gpu = @import("main.zig");
const builtin = @import("builtin");

const c = @cImport({
    @cInclude("dawn/webgpu.h");
    @cInclude("mach_dawn.h");
});

var didInit = false;
var procs: c.DawnProcTable = undefined;

/// A Dawn implementation of the gpu.Interface, which merely directs calls to the Dawn proc table.
///
/// Before use, it must be `.init()`ialized in order to set the global proc table.
pub const Interface = struct {
    pub fn init() void {
        didInit = true;
        procs = c.machDawnGetProcTable();
    }

    pub inline fn createInstance(descriptor: ?*const gpu.Instance.Descriptor) ?*gpu.Instance {
        if (builtin.mode == .Debug and !didInit) @panic("dawn: not initialized; did you forget to call gpu.Impl.init()?");
        return @ptrCast(?*gpu.Instance, procs.createInstance.?(
            @ptrCast(?*const c.WGPUInstanceDescriptor, descriptor),
        ));
    }

    pub inline fn getProcAddress(device: *gpu.Device, proc_name: [*:0]const u8) ?gpu.Proc {
        return procs.getProcAddress.?(
            @ptrCast(c.WGPUDevice, device),
            proc_name,
        );
    }

    pub inline fn adapterCreateDevice(adapter: *gpu.Adapter, descriptor: ?*const gpu.Device.Descriptor) ?*gpu.Device {
        return @ptrCast(?*gpu.Device, procs.adapterCreateDevice.?(
            @ptrCast(c.WGPUAdapter, adapter),
            @ptrCast(?*const c.WGPUDeviceDescriptor, descriptor),
        ));
    }

    pub inline fn adapterEnumerateFeatures(adapter: *gpu.Adapter, features: ?[*]gpu.FeatureName) usize {
        return procs.adapterEnumerateFeatures.?(
            @ptrCast(c.WGPUAdapter, adapter),
            @ptrCast(?[*]c.WGPUFeatureName, features),
        );
    }

    pub inline fn adapterGetLimits(adapter: *gpu.Adapter, limits: *gpu.SupportedLimits) bool {
        return procs.adapterGetLimits.?(
            @ptrCast(c.WGPUAdapter, adapter),
            @ptrCast(*c.WGPUSupportedLimits, limits),
        );
    }

    pub inline fn adapterGetProperties(adapter: *gpu.Adapter, properties: *gpu.Adapter.Properties) void {
        return procs.adapterGetProperties.?(
            @ptrCast(c.WGPUAdapter, adapter),
            @ptrCast(*c.WGPUAdapterProperties, properties),
        );
    }

    pub inline fn adapterHasFeature(adapter: *gpu.Adapter, feature: gpu.FeatureName) bool {
        return procs.adapterHasFeature.?(
            @ptrCast(c.WGPUAdapter, adapter),
            @enumToInt(feature),
        );
    }

    pub inline fn adapterRequestDevice(adapter: *gpu.Adapter, descriptor: ?*const gpu.Device.Descriptor, callback: gpu.RequestDeviceCallback, userdata: ?*anyopaque) void {
        return procs.adapterRequestDevice.?(
            @ptrCast(c.WGPUAdapter, adapter),
            @ptrCast(?*const c.WGPUDeviceDescriptor, descriptor),
            @ptrCast(c.WGPURequestDeviceCallback, callback),
            userdata,
        );
    }

    pub inline fn adapterReference(adapter: *gpu.Adapter) void {
        procs.adapterReference.?(@ptrCast(c.WGPUAdapter, adapter));
    }

    pub inline fn adapterRelease(adapter: *gpu.Adapter) void {
        procs.adapterRelease.?(@ptrCast(c.WGPUAdapter, adapter));
    }

    pub inline fn bindGroupSetLabel(bind_group: *gpu.BindGroup, label: [*:0]const u8) void {
        procs.bindGroupSetLabel.?(@ptrCast(c.WGPUBindGroup, bind_group), label);
    }

    pub inline fn bindGroupReference(bind_group: *gpu.BindGroup) void {
        procs.bindGroupReference.?(@ptrCast(c.WGPUBindGroup, bind_group));
    }

    pub inline fn bindGroupRelease(bind_group: *gpu.BindGroup) void {
        procs.bindGroupRelease.?(@ptrCast(c.WGPUBindGroup, bind_group));
    }

    pub inline fn bindGroupLayoutSetLabel(bind_group_layout: *gpu.BindGroupLayout, label: [*:0]const u8) void {
        procs.bindGroupLayoutSetLabel.?(@ptrCast(c.WGPUBindGroupLayout, bind_group_layout), label);
    }

    pub inline fn bindGroupLayoutReference(bind_group_layout: *gpu.BindGroupLayout) void {
        procs.bindGroupLayoutReference.?(@ptrCast(c.WGPUBindGroupLayout, bind_group_layout));
    }

    pub inline fn bindGroupLayoutRelease(bind_group_layout: *gpu.BindGroupLayout) void {
        procs.bindGroupLayoutRelease.?(@ptrCast(c.WGPUBindGroupLayout, bind_group_layout));
    }

    pub inline fn bufferDestroy(buffer: *gpu.Buffer) void {
        procs.bufferDestroy.?(@ptrCast(c.WGPUBuffer, buffer));
    }

    pub inline fn bufferGetMapState(buffer: *gpu.Buffer) gpu.Buffer.MapState {
        return procs.bufferGetMapState.?(@ptrCast(c.WGPUBuffer, buffer));
    }

    // TODO: dawn: return value not marked as nullable in dawn.json but in fact is.
    pub inline fn bufferGetConstMappedRange(buffer: *gpu.Buffer, offset: usize, size: usize) ?*const anyopaque {
        return procs.bufferGetConstMappedRange.?(
            @ptrCast(c.WGPUBuffer, buffer),
            offset,
            size,
        );
    }

    // TODO: dawn: return value not marked as nullable in dawn.json but in fact is.
    pub inline fn bufferGetMappedRange(buffer: *gpu.Buffer, offset: usize, size: usize) ?*anyopaque {
        return procs.bufferGetMappedRange.?(
            @ptrCast(c.WGPUBuffer, buffer),
            offset,
            size,
        );
    }

    pub inline fn bufferGetSize(buffer: *gpu.Buffer) u64 {
        return procs.bufferGetSize.?(@ptrCast(c.WGPUBuffer, buffer));
    }

    pub inline fn bufferGetUsage(buffer: *gpu.Buffer) gpu.Buffer.UsageFlags {
        return @bitCast(gpu.Buffer.UsageFlags, procs.bufferGetUsage.?(@ptrCast(c.WGPUBuffer, buffer)));
    }

    pub inline fn bufferMapAsync(buffer: *gpu.Buffer, mode: gpu.MapModeFlags, offset: usize, size: usize, callback: gpu.Buffer.MapCallback, userdata: ?*anyopaque) void {
        procs.bufferMapAsync.?(
            @ptrCast(c.WGPUBuffer, buffer),
            @bitCast(c.WGPUMapModeFlags, mode),
            offset,
            size,
            @ptrCast(c.WGPUBufferMapCallback, callback),
            userdata,
        );
    }

    pub inline fn bufferSetLabel(buffer: *gpu.Buffer, label: [*:0]const u8) void {
        procs.bufferSetLabel.?(@ptrCast(c.WGPUBuffer, buffer), label);
    }

    pub inline fn bufferUnmap(buffer: *gpu.Buffer) void {
        procs.bufferUnmap.?(@ptrCast(c.WGPUBuffer, buffer));
    }

    pub inline fn bufferReference(buffer: *gpu.Buffer) void {
        procs.bufferReference.?(@ptrCast(c.WGPUBuffer, buffer));
    }

    pub inline fn bufferRelease(buffer: *gpu.Buffer) void {
        procs.bufferRelease.?(@ptrCast(c.WGPUBuffer, buffer));
    }

    pub inline fn commandBufferSetLabel(command_buffer: *gpu.CommandBuffer, label: [*:0]const u8) void {
        procs.commandBufferSetLabel.?(@ptrCast(c.WGPUCommandBuffer, command_buffer), label);
    }

    pub inline fn commandBufferReference(command_buffer: *gpu.CommandBuffer) void {
        procs.commandBufferReference.?(@ptrCast(c.WGPUCommandBuffer, command_buffer));
    }

    pub inline fn commandBufferRelease(command_buffer: *gpu.CommandBuffer) void {
        procs.commandBufferRelease.?(@ptrCast(c.WGPUCommandBuffer, command_buffer));
    }

    pub inline fn commandEncoderBeginComputePass(command_encoder: *gpu.CommandEncoder, descriptor: ?*const gpu.ComputePassDescriptor) *gpu.ComputePassEncoder {
        return @ptrCast(*gpu.ComputePassEncoder, procs.commandEncoderBeginComputePass.?(
            @ptrCast(c.WGPUCommandEncoder, command_encoder),
            @ptrCast(?*const c.WGPUComputePassDescriptor, descriptor),
        ));
    }

    pub inline fn commandEncoderBeginRenderPass(command_encoder: *gpu.CommandEncoder, descriptor: *const gpu.RenderPassDescriptor) *gpu.RenderPassEncoder {
        return @ptrCast(*gpu.RenderPassEncoder, procs.commandEncoderBeginRenderPass.?(
            @ptrCast(c.WGPUCommandEncoder, command_encoder),
            @ptrCast(?*const c.WGPURenderPassDescriptor, descriptor),
        ));
    }

    pub inline fn commandEncoderClearBuffer(command_encoder: *gpu.CommandEncoder, buffer: *gpu.Buffer, offset: u64, size: u64) void {
        procs.commandEncoderClearBuffer.?(
            @ptrCast(c.WGPUCommandEncoder, command_encoder),
            @ptrCast(c.WGPUBuffer, buffer),
            offset,
            size,
        );
    }

    pub inline fn commandEncoderCopyBufferToBuffer(command_encoder: *gpu.CommandEncoder, source: *gpu.Buffer, source_offset: u64, destination: *gpu.Buffer, destination_offset: u64, size: u64) void {
        procs.commandEncoderCopyBufferToBuffer.?(
            @ptrCast(c.WGPUCommandEncoder, command_encoder),
            @ptrCast(c.WGPUBuffer, source),
            source_offset,
            @ptrCast(c.WGPUBuffer, destination),
            destination_offset,
            size,
        );
    }

    pub inline fn commandEncoderCopyBufferToTexture(command_encoder: *gpu.CommandEncoder, source: *const gpu.ImageCopyBuffer, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) void {
        procs.commandEncoderCopyBufferToTexture.?(
            @ptrCast(c.WGPUCommandEncoder, command_encoder),
            @ptrCast(*const c.WGPUImageCopyBuffer, source),
            @ptrCast(*const c.WGPUImageCopyTexture, destination),
            @ptrCast(*const c.WGPUExtent3D, copy_size),
        );
    }

    pub inline fn commandEncoderCopyTextureToBuffer(command_encoder: *gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyBuffer, copy_size: *const gpu.Extent3D) void {
        procs.commandEncoderCopyTextureToBuffer.?(
            @ptrCast(c.WGPUCommandEncoder, command_encoder),
            @ptrCast(*const c.WGPUImageCopyTexture, source),
            @ptrCast(*const c.WGPUImageCopyBuffer, destination),
            @ptrCast(*const c.WGPUExtent3D, copy_size),
        );
    }

    pub inline fn commandEncoderCopyTextureToTexture(command_encoder: *gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) void {
        procs.commandEncoderCopyTextureToTexture.?(
            @ptrCast(c.WGPUCommandEncoder, command_encoder),
            @ptrCast(*const c.WGPUImageCopyTexture, source),
            @ptrCast(*const c.WGPUImageCopyTexture, destination),
            @ptrCast(*const c.WGPUExtent3D, copy_size),
        );
    }

    pub inline fn commandEncoderCopyTextureToTextureInternal(command_encoder: *gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) void {
        procs.commandEncoderCopyTextureToTextureInternal.?(
            @ptrCast(c.WGPUCommandEncoder, command_encoder),
            @ptrCast(*const c.WGPUImageCopyTexture, source),
            @ptrCast(*const c.WGPUImageCopyTexture, destination),
            @ptrCast(*const c.WGPUExtent3D, copy_size),
        );
    }

    pub inline fn commandEncoderFinish(command_encoder: *gpu.CommandEncoder, descriptor: ?*const gpu.CommandBuffer.Descriptor) *gpu.CommandBuffer {
        return @ptrCast(*gpu.CommandBuffer, procs.commandEncoderFinish.?(
            @ptrCast(c.WGPUCommandEncoder, command_encoder),
            @ptrCast(?*const c.WGPUCommandBufferDescriptor, descriptor),
        ));
    }

    pub inline fn commandEncoderInjectValidationError(command_encoder: *gpu.CommandEncoder, message: [*:0]const u8) void {
        procs.commandEncoderInjectValidationError.?(
            @ptrCast(c.WGPUCommandEncoder, command_encoder),
            message,
        );
    }

    pub inline fn commandEncoderInsertDebugMarker(command_encoder: *gpu.CommandEncoder, marker_label: [*:0]const u8) void {
        procs.commandEncoderInsertDebugMarker.?(
            @ptrCast(c.WGPUCommandEncoder, command_encoder),
            marker_label,
        );
    }

    pub inline fn commandEncoderPopDebugGroup(command_encoder: *gpu.CommandEncoder) void {
        procs.commandEncoderPopDebugGroup.?(@ptrCast(c.WGPUCommandEncoder, command_encoder));
    }

    pub inline fn commandEncoderPushDebugGroup(command_encoder: *gpu.CommandEncoder, group_label: [*:0]const u8) void {
        procs.commandEncoderPushDebugGroup.?(
            @ptrCast(c.WGPUCommandEncoder, command_encoder),
            group_label,
        );
    }

    pub inline fn commandEncoderResolveQuerySet(command_encoder: *gpu.CommandEncoder, query_set: *gpu.QuerySet, first_query: u32, query_count: u32, destination: *gpu.Buffer, destination_offset: u64) void {
        procs.commandEncoderResolveQuerySet.?(
            @ptrCast(c.WGPUCommandEncoder, command_encoder),
            @ptrCast(c.WGPUQuerySet, query_set),
            first_query,
            query_count,
            @ptrCast(c.WGPUBuffer, destination),
            destination_offset,
        );
    }

    pub inline fn commandEncoderSetLabel(command_encoder: *gpu.CommandEncoder, label: [*:0]const u8) void {
        procs.commandEncoderSetLabel.?(@ptrCast(c.WGPUCommandEncoder, command_encoder), label);
    }

    pub inline fn commandEncoderWriteBuffer(command_encoder: *gpu.CommandEncoder, buffer: *gpu.Buffer, buffer_offset: u64, data: [*]const u8, size: u64) void {
        procs.commandEncoderWriteBuffer.?(
            @ptrCast(c.WGPUCommandEncoder, command_encoder),
            @ptrCast(c.WGPUBuffer, buffer),
            buffer_offset,
            data,
            size,
        );
    }

    pub inline fn commandEncoderWriteTimestamp(command_encoder: *gpu.CommandEncoder, query_set: *gpu.QuerySet, query_index: u32) void {
        procs.commandEncoderWriteTimestamp.?(
            @ptrCast(c.WGPUCommandEncoder, command_encoder),
            @ptrCast(c.WGPUQuerySet, query_set),
            query_index,
        );
    }

    pub inline fn commandEncoderReference(command_encoder: *gpu.CommandEncoder) void {
        procs.commandEncoderReference.?(@ptrCast(c.WGPUCommandEncoder, command_encoder));
    }

    pub inline fn commandEncoderRelease(command_encoder: *gpu.CommandEncoder) void {
        procs.commandEncoderRelease.?(@ptrCast(c.WGPUCommandEncoder, command_encoder));
    }

    pub inline fn computePassEncoderDispatchWorkgroups(compute_pass_encoder: *gpu.ComputePassEncoder, workgroup_count_x: u32, workgroup_count_y: u32, workgroup_count_z: u32) void {
        procs.computePassEncoderDispatchWorkgroups.?(
            @ptrCast(c.WGPUComputePassEncoder, compute_pass_encoder),
            workgroup_count_x,
            workgroup_count_y,
            workgroup_count_z,
        );
    }

    pub inline fn computePassEncoderDispatchWorkgroupsIndirect(compute_pass_encoder: *gpu.ComputePassEncoder, indirect_buffer: *gpu.Buffer, indirect_offset: u64) void {
        procs.computePassEncoderDispatchWorkgroupsIndirect.?(
            @ptrCast(c.WGPUComputePassEncoder, compute_pass_encoder),
            @ptrCast(c.WGPUBuffer, indirect_buffer),
            indirect_offset,
        );
    }

    pub inline fn computePassEncoderEnd(compute_pass_encoder: *gpu.ComputePassEncoder) void {
        procs.computePassEncoderEnd.?(@ptrCast(c.WGPUComputePassEncoder, compute_pass_encoder));
    }

    pub inline fn computePassEncoderInsertDebugMarker(compute_pass_encoder: *gpu.ComputePassEncoder, marker_label: [*:0]const u8) void {
        procs.computePassEncoderInsertDebugMarker.?(
            @ptrCast(c.WGPUComputePassEncoder, compute_pass_encoder),
            marker_label,
        );
    }

    pub inline fn computePassEncoderPopDebugGroup(compute_pass_encoder: *gpu.ComputePassEncoder) void {
        procs.computePassEncoderPopDebugGroup.?(@ptrCast(c.WGPUComputePassEncoder, compute_pass_encoder));
    }

    pub inline fn computePassEncoderPushDebugGroup(compute_pass_encoder: *gpu.ComputePassEncoder, group_label: [*:0]const u8) void {
        procs.computePassEncoderPushDebugGroup.?(
            @ptrCast(c.WGPUComputePassEncoder, compute_pass_encoder),
            group_label,
        );
    }

    pub inline fn computePassEncoderSetBindGroup(compute_pass_encoder: *gpu.ComputePassEncoder, group_index: u32, group: *gpu.BindGroup, dynamic_offset_count: u32, dynamic_offsets: ?[*]const u32) void {
        procs.computePassEncoderSetBindGroup.?(
            @ptrCast(c.WGPUComputePassEncoder, compute_pass_encoder),
            group_index,
            @ptrCast(c.WGPUBindGroup, group),
            dynamic_offset_count,
            dynamic_offsets,
        );
    }

    pub inline fn computePassEncoderSetLabel(compute_pass_encoder: *gpu.ComputePassEncoder, label: [*:0]const u8) void {
        procs.computePassEncoderSetLabel.?(@ptrCast(c.WGPUComputePassEncoder, compute_pass_encoder), label);
    }

    pub inline fn computePassEncoderSetPipeline(compute_pass_encoder: *gpu.ComputePassEncoder, pipeline: *gpu.ComputePipeline) void {
        procs.computePassEncoderSetPipeline.?(
            @ptrCast(c.WGPUComputePassEncoder, compute_pass_encoder),
            @ptrCast(c.WGPUComputePipeline, pipeline),
        );
    }

    pub inline fn computePassEncoderWriteTimestamp(compute_pass_encoder: *gpu.ComputePassEncoder, query_set: *gpu.QuerySet, query_index: u32) void {
        procs.computePassEncoderWriteTimestamp.?(
            @ptrCast(c.WGPUComputePassEncoder, compute_pass_encoder),
            @ptrCast(c.WGPUQuerySet, query_set),
            query_index,
        );
    }

    pub inline fn computePassEncoderReference(compute_pass_encoder: *gpu.ComputePassEncoder) void {
        procs.computePassEncoderReference.?(@ptrCast(c.WGPUComputePassEncoder, compute_pass_encoder));
    }

    pub inline fn computePassEncoderRelease(compute_pass_encoder: *gpu.ComputePassEncoder) void {
        procs.computePassEncoderRelease.?(@ptrCast(c.WGPUComputePassEncoder, compute_pass_encoder));
    }

    pub inline fn computePipelineGetBindGroupLayout(compute_pipeline: *gpu.ComputePipeline, group_index: u32) *gpu.BindGroupLayout {
        return @ptrCast(*gpu.BindGroupLayout, procs.computePipelineGetBindGroupLayout.?(
            @ptrCast(c.WGPUComputePipeline, compute_pipeline),
            group_index,
        ));
    }

    pub inline fn computePipelineSetLabel(compute_pipeline: *gpu.ComputePipeline, label: [*:0]const u8) void {
        procs.computePipelineSetLabel.?(@ptrCast(c.WGPUComputePipeline, compute_pipeline), label);
    }

    pub inline fn computePipelineReference(compute_pipeline: *gpu.ComputePipeline) void {
        procs.computePipelineReference.?(@ptrCast(c.WGPUComputePipeline, compute_pipeline));
    }

    pub inline fn computePipelineRelease(compute_pipeline: *gpu.ComputePipeline) void {
        procs.computePipelineRelease.?(@ptrCast(c.WGPUComputePipeline, compute_pipeline));
    }

    pub inline fn deviceCreateBindGroup(device: *gpu.Device, descriptor: *const gpu.BindGroup.Descriptor) *gpu.BindGroup {
        return @ptrCast(*gpu.BindGroup, procs.deviceCreateBindGroup.?(
            @ptrCast(c.WGPUDevice, device),
            @ptrCast(*const c.WGPUBindGroupDescriptor, descriptor),
        ));
    }

    pub inline fn deviceCreateBindGroupLayout(device: *gpu.Device, descriptor: *const gpu.BindGroupLayout.Descriptor) *gpu.BindGroupLayout {
        return @ptrCast(*gpu.BindGroupLayout, procs.deviceCreateBindGroupLayout.?(
            @ptrCast(c.WGPUDevice, device),
            @ptrCast(*const c.WGPUBindGroupLayoutDescriptor, descriptor),
        ));
    }

    pub inline fn deviceCreateBuffer(device: *gpu.Device, descriptor: *const gpu.Buffer.Descriptor) *gpu.Buffer {
        return @ptrCast(*gpu.Buffer, procs.deviceCreateBuffer.?(
            @ptrCast(c.WGPUDevice, device),
            @ptrCast(*const c.WGPUBufferDescriptor, descriptor),
        ));
    }

    pub inline fn deviceCreateCommandEncoder(device: *gpu.Device, descriptor: ?*const gpu.CommandEncoder.Descriptor) *gpu.CommandEncoder {
        return @ptrCast(*gpu.CommandEncoder, procs.deviceCreateCommandEncoder.?(
            @ptrCast(c.WGPUDevice, device),
            @ptrCast(?*const c.WGPUCommandEncoderDescriptor, descriptor),
        ));
    }

    pub inline fn deviceCreateComputePipeline(device: *gpu.Device, descriptor: *const gpu.ComputePipeline.Descriptor) *gpu.ComputePipeline {
        return @ptrCast(*gpu.ComputePipeline, procs.deviceCreateComputePipeline.?(
            @ptrCast(c.WGPUDevice, device),
            @ptrCast(*const c.WGPUComputePipelineDescriptor, descriptor),
        ));
    }

    pub inline fn deviceCreateComputePipelineAsync(device: *gpu.Device, descriptor: *const gpu.ComputePipeline.Descriptor, callback: gpu.CreateComputePipelineAsyncCallback, userdata: ?*anyopaque) void {
        procs.deviceCreateComputePipelineAsync.?(
            @ptrCast(c.WGPUDevice, device),
            @ptrCast(*const c.WGPUComputePipelineDescriptor, descriptor),
            @ptrCast(c.WGPUCreateComputePipelineAsyncCallback, callback),
            userdata,
        );
    }

    pub inline fn deviceCreateErrorBuffer(device: *gpu.Device, descriptor: *const gpu.Buffer.Descriptor) *gpu.Buffer {
        return @ptrCast(*gpu.Buffer, procs.deviceCreateErrorBuffer.?(
            @ptrCast(c.WGPUDevice, device),
            @ptrCast(*const c.WGPUBufferDescriptor, descriptor),
        ));
    }

    pub inline fn deviceCreateErrorExternalTexture(device: *gpu.Device) *gpu.ExternalTexture {
        return @ptrCast(*gpu.ExternalTexture, procs.deviceCreateErrorExternalTexture.?(@ptrCast(c.WGPUDevice, device)));
    }

    pub inline fn deviceCreateErrorTexture(device: *gpu.Device, descriptor: *const gpu.Texture.Descriptor) *gpu.Texture {
        return @ptrCast(*gpu.Texture, procs.deviceCreateErrorTexture.?(
            @ptrCast(c.WGPUDevice, device),
            @ptrCast(*const c.WGPUTextureDescriptor, descriptor),
        ));
    }

    pub inline fn deviceCreateExternalTexture(device: *gpu.Device, external_texture_descriptor: *const gpu.ExternalTexture.Descriptor) *gpu.ExternalTexture {
        return @ptrCast(*gpu.ExternalTexture, procs.deviceCreateExternalTexture.?(
            @ptrCast(c.WGPUDevice, device),
            @ptrCast(*const c.WGPUExternalTextureDescriptor, external_texture_descriptor),
        ));
    }

    pub inline fn deviceCreatePipelineLayout(device: *gpu.Device, pipeline_layout_descriptor: *const gpu.PipelineLayout.Descriptor) *gpu.PipelineLayout {
        return @ptrCast(*gpu.PipelineLayout, procs.deviceCreatePipelineLayout.?(
            @ptrCast(c.WGPUDevice, device),
            @ptrCast(*const c.WGPUPipelineLayoutDescriptor, pipeline_layout_descriptor),
        ));
    }

    pub inline fn deviceCreateQuerySet(device: *gpu.Device, descriptor: *const gpu.QuerySet.Descriptor) *gpu.QuerySet {
        return @ptrCast(*gpu.QuerySet, procs.deviceCreateQuerySet.?(
            @ptrCast(c.WGPUDevice, device),
            @ptrCast(*const c.WGPUQuerySetDescriptor, descriptor),
        ));
    }

    pub inline fn deviceCreateRenderBundleEncoder(device: *gpu.Device, descriptor: *const gpu.RenderBundleEncoder.Descriptor) *gpu.RenderBundleEncoder {
        return @ptrCast(*gpu.RenderBundleEncoder, procs.deviceCreateRenderBundleEncoder.?(
            @ptrCast(c.WGPUDevice, device),
            @ptrCast(*const c.WGPURenderBundleEncoderDescriptor, descriptor),
        ));
    }

    pub inline fn deviceCreateRenderPipeline(device: *gpu.Device, descriptor: *const gpu.RenderPipeline.Descriptor) *gpu.RenderPipeline {
        return @ptrCast(*gpu.RenderPipeline, procs.deviceCreateRenderPipeline.?(
            @ptrCast(c.WGPUDevice, device),
            @ptrCast(*const c.WGPURenderPipelineDescriptor, descriptor),
        ));
    }

    pub inline fn deviceCreateRenderPipelineAsync(device: *gpu.Device, descriptor: *const gpu.RenderPipeline.Descriptor, callback: gpu.CreateRenderPipelineAsyncCallback, userdata: ?*anyopaque) void {
        procs.deviceCreateRenderPipelineAsync.?(
            @ptrCast(c.WGPUDevice, device),
            @ptrCast(*const c.WGPURenderPipelineDescriptor, descriptor),
            @ptrCast(c.WGPUCreateRenderPipelineAsyncCallback, callback),
            userdata,
        );
    }

    // TODO(self-hosted): this cannot be marked as inline for some reason.
    // https://github.com/ziglang/zig/issues/12545
    pub fn deviceCreateSampler(device: *gpu.Device, descriptor: ?*const gpu.Sampler.Descriptor) *gpu.Sampler {
        return @ptrCast(*gpu.Sampler, procs.deviceCreateSampler.?(
            @ptrCast(c.WGPUDevice, device),
            @ptrCast(?*const c.WGPUSamplerDescriptor, descriptor),
        ));
    }

    pub inline fn deviceCreateShaderModule(device: *gpu.Device, descriptor: *const gpu.ShaderModule.Descriptor) *gpu.ShaderModule {
        return @ptrCast(*gpu.ShaderModule, procs.deviceCreateShaderModule.?(
            @ptrCast(c.WGPUDevice, device),
            @ptrCast(*const c.WGPUShaderModuleDescriptor, descriptor),
        ));
    }

    pub inline fn deviceCreateSwapChain(device: *gpu.Device, surface: ?*gpu.Surface, descriptor: *const gpu.SwapChain.Descriptor) *gpu.SwapChain {
        return @ptrCast(*gpu.SwapChain, procs.deviceCreateSwapChain.?(
            @ptrCast(c.WGPUDevice, device),
            @ptrCast(c.WGPUSurface, surface),
            @ptrCast(*const c.WGPUSwapChainDescriptor, descriptor),
        ));
    }

    pub inline fn deviceCreateTexture(device: *gpu.Device, descriptor: *const gpu.Texture.Descriptor) *gpu.Texture {
        return @ptrCast(*gpu.Texture, procs.deviceCreateTexture.?(
            @ptrCast(c.WGPUDevice, device),
            @ptrCast(*const c.WGPUTextureDescriptor, descriptor),
        ));
    }

    pub inline fn deviceDestroy(device: *gpu.Device) void {
        procs.deviceDestroy.?(@ptrCast(c.WGPUDevice, device));
    }

    pub inline fn deviceEnumerateFeatures(device: *gpu.Device, features: ?[*]gpu.FeatureName) usize {
        return procs.deviceEnumerateFeatures.?(
            @ptrCast(c.WGPUDevice, device),
            @ptrCast(?[*]c.WGPUFeatureName, features),
        );
    }

    pub inline fn forceLoss(device: *gpu.Device, reason: gpu.Device.LostReason, message: [*:0]const u8) void {
        return procs.deviceForceLoss.?(
            @ptrCast(c.WGPUDevice, device),
            reason,
            message,
        );
    }

    pub inline fn deviceGetAdapter(device: *gpu.Device) *gpu.Adapter {
        return procs.deviceGetAdapter.?(@ptrCast(c.WGPUDevice, device));
    }

    pub inline fn deviceGetLimits(device: *gpu.Device, limits: *gpu.SupportedLimits) bool {
        return procs.deviceGetLimits.?(
            @ptrCast(c.WGPUDevice, device),
            @ptrCast(*c.WGPUSupportedLimits, limits),
        );
    }

    pub inline fn deviceGetQueue(device: *gpu.Device) *gpu.Queue {
        return @ptrCast(*gpu.Queue, procs.deviceGetQueue.?(@ptrCast(c.WGPUDevice, device)));
    }

    pub inline fn deviceHasFeature(device: *gpu.Device, feature: gpu.FeatureName) bool {
        return procs.deviceHasFeature.?(
            @ptrCast(c.WGPUDevice, device),
            @enumToInt(feature),
        );
    }

    pub inline fn deviceInjectError(device: *gpu.Device, typ: gpu.ErrorType, message: [*:0]const u8) void {
        procs.deviceInjectError.?(
            @ptrCast(c.WGPUDevice, device),
            @enumToInt(typ),
            message,
        );
    }

    pub inline fn devicePopErrorScope(device: *gpu.Device, callback: gpu.ErrorCallback, userdata: ?*anyopaque) bool {
        return procs.devicePopErrorScope.?(
            @ptrCast(c.WGPUDevice, device),
            @ptrCast(c.WGPUErrorCallback, callback),
            userdata,
        );
    }

    pub inline fn devicePushErrorScope(device: *gpu.Device, filter: gpu.ErrorFilter) void {
        procs.devicePushErrorScope.?(
            @ptrCast(c.WGPUDevice, device),
            @enumToInt(filter),
        );
    }

    pub inline fn deviceSetDeviceLostCallback(device: *gpu.Device, callback: ?gpu.Device.LostCallback, userdata: ?*anyopaque) void {
        procs.deviceSetDeviceLostCallback.?(
            @ptrCast(c.WGPUDevice, device),
            @ptrCast(c.WGPUDeviceLostCallback, callback),
            userdata,
        );
    }

    pub inline fn deviceSetLabel(device: *gpu.Device, label: [*:0]const u8) void {
        procs.deviceSetLabel.?(@ptrCast(c.WGPUDevice, device), label);
    }

    pub inline fn deviceSetLoggingCallback(device: *gpu.Device, callback: ?gpu.LoggingCallback, userdata: ?*anyopaque) void {
        procs.deviceSetLoggingCallback.?(
            @ptrCast(c.WGPUDevice, device),
            @ptrCast(c.WGPULoggingCallback, callback),
            userdata,
        );
    }

    pub inline fn deviceSetUncapturedErrorCallback(device: *gpu.Device, callback: ?gpu.ErrorCallback, userdata: ?*anyopaque) void {
        procs.deviceSetUncapturedErrorCallback.?(
            @ptrCast(c.WGPUDevice, device),
            @ptrCast(c.WGPUErrorCallback, callback),
            userdata,
        );
    }

    pub inline fn deviceTick(device: *gpu.Device) void {
        procs.deviceTick.?(@ptrCast(c.WGPUDevice, device));
    }

    pub inline fn deviceValidateTextureDescriptor(device: *gpu.Device, descriptor: *const gpu.Texture.Descriptor) void {
        procs.deviceValidateTextureDescriptor(device, descriptor);
    }

    pub inline fn deviceReference(device: *gpu.Device) void {
        procs.deviceReference.?(@ptrCast(c.WGPUDevice, device));
    }

    pub inline fn deviceRelease(device: *gpu.Device) void {
        procs.deviceRelease.?(@ptrCast(c.WGPUDevice, device));
    }

    pub inline fn externalTextureDestroy(external_texture: *gpu.ExternalTexture) void {
        procs.externalTextureDestroy.?(@ptrCast(c.WGPUExternalTexture, external_texture));
    }

    pub inline fn externalTextureSetLabel(external_texture: *gpu.ExternalTexture, label: [*:0]const u8) void {
        procs.externalTextureSetLabel.?(@ptrCast(c.WGPUExternalTexture, external_texture), label);
    }

    pub inline fn externalTextureReference(external_texture: *gpu.ExternalTexture) void {
        procs.externalTextureReference.?(@ptrCast(c.WGPUExternalTexture, external_texture));
    }

    pub inline fn externalTextureRelease(external_texture: *gpu.ExternalTexture) void {
        procs.externalTextureRelease.?(@ptrCast(c.WGPUExternalTexture, external_texture));
    }

    pub inline fn instanceCreateSurface(instance: *gpu.Instance, descriptor: *const gpu.Surface.Descriptor) *gpu.Surface {
        return @ptrCast(*gpu.Surface, procs.instanceCreateSurface.?(
            @ptrCast(c.WGPUInstance, instance),
            @ptrCast(*const c.WGPUSurfaceDescriptor, descriptor),
        ));
    }

    pub inline fn instanceRequestAdapter(instance: *gpu.Instance, options: ?*const gpu.RequestAdapterOptions, callback: gpu.RequestAdapterCallback, userdata: ?*anyopaque) void {
        procs.instanceRequestAdapter.?(
            @ptrCast(c.WGPUInstance, instance),
            @ptrCast(?*const c.WGPURequestAdapterOptions, options),
            @ptrCast(c.WGPURequestAdapterCallback, callback),
            userdata,
        );
    }

    pub inline fn instanceReference(instance: *gpu.Instance) void {
        procs.instanceReference.?(@ptrCast(c.WGPUInstance, instance));
    }

    pub inline fn instanceRelease(instance: *gpu.Instance) void {
        procs.instanceRelease.?(@ptrCast(c.WGPUInstance, instance));
    }

    pub inline fn pipelineLayoutSetLabel(pipeline_layout: *gpu.PipelineLayout, label: [*:0]const u8) void {
        procs.pipelineLayoutSetLabel.?(@ptrCast(c.WGPUPipelineLayout, pipeline_layout), label);
    }

    pub inline fn pipelineLayoutReference(pipeline_layout: *gpu.PipelineLayout) void {
        procs.pipelineLayoutReference.?(@ptrCast(c.WGPUPipelineLayout, pipeline_layout));
    }

    pub inline fn pipelineLayoutRelease(pipeline_layout: *gpu.PipelineLayout) void {
        procs.pipelineLayoutRelease.?(@ptrCast(c.WGPUPipelineLayout, pipeline_layout));
    }

    pub inline fn querySetDestroy(query_set: *gpu.QuerySet) void {
        procs.querySetDestroy.?(@ptrCast(c.WGPUQuerySet, query_set));
    }

    pub inline fn querySetGetCount(query_set: *gpu.QuerySet) u32 {
        return procs.querySetGetCount.?(@ptrCast(c.WGPUQuerySet, query_set));
    }

    pub inline fn querySetGetType(query_set: *gpu.QuerySet) gpu.QueryType {
        return @intToEnum(gpu.QueryType, procs.querySetGetType.?(@ptrCast(c.WGPUQuerySet, query_set)));
    }

    pub inline fn querySetSetLabel(query_set: *gpu.QuerySet, label: [*:0]const u8) void {
        procs.querySetSetLabel.?(@ptrCast(c.WGPUQuerySet, query_set), label);
    }

    pub inline fn querySetReference(query_set: *gpu.QuerySet) void {
        procs.querySetReference.?(@ptrCast(c.WGPUQuerySet, query_set));
    }

    pub inline fn querySetRelease(query_set: *gpu.QuerySet) void {
        procs.querySetRelease.?(@ptrCast(c.WGPUQuerySet, query_set));
    }

    pub inline fn queueCopyExternalTextureForBrowser(queue: *gpu.Queue, source: *const gpu.ImageCopyExternalTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D, options: *const gpu.CopyTextureForBrowserOptions) void {
        procs.queueCopyExternalTextureForBrowser.?(
            @ptrCast(c.WGPUQueue, queue),
            @ptrCast(*const c.ImageCopyExternalTexture, source),
            @ptrCast(*const c.WGPUImageCopyTexture, destination),
            @ptrCast(*const c.WGPUExtent3D, copy_size),
            @ptrCast(*const c.WGPUCopyTextureForBrowserOptions, options),
        );
    }

    pub inline fn queueCopyTextureForBrowser(queue: *gpu.Queue, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D, options: *const gpu.CopyTextureForBrowserOptions) void {
        procs.queueCopyTextureForBrowser.?(
            @ptrCast(c.WGPUQueue, queue),
            @ptrCast(*const c.WGPUImageCopyTexture, source),
            @ptrCast(*const c.WGPUImageCopyTexture, destination),
            @ptrCast(*const c.WGPUExtent3D, copy_size),
            @ptrCast(*const c.WGPUCopyTextureForBrowserOptions, options),
        );
    }

    pub inline fn queueOnSubmittedWorkDone(queue: *gpu.Queue, signal_value: u64, callback: gpu.Queue.WorkDoneCallback, userdata: ?*anyopaque) void {
        procs.queueOnSubmittedWorkDone.?(
            @ptrCast(c.WGPUQueue, queue),
            signal_value,
            @ptrCast(c.WGPUQueueWorkDoneCallback, callback),
            userdata,
        );
    }

    pub inline fn queueSetLabel(queue: *gpu.Queue, label: [*:0]const u8) void {
        procs.queueSetLabel.?(@ptrCast(c.WGPUQueue, queue), label);
    }

    pub inline fn queueSubmit(queue: *gpu.Queue, command_count: u32, commands: [*]const *const gpu.CommandBuffer) void {
        procs.queueSubmit.?(
            @ptrCast(c.WGPUQueue, queue),
            command_count,
            @ptrCast([*]const c.WGPUCommandBuffer, commands),
        );
    }

    pub inline fn queueWriteBuffer(queue: *gpu.Queue, buffer: *gpu.Buffer, buffer_offset: u64, data: *const anyopaque, size: usize) void {
        procs.queueWriteBuffer.?(
            @ptrCast(c.WGPUQueue, queue),
            @ptrCast(c.WGPUBuffer, buffer),
            buffer_offset,
            data,
            size,
        );
    }

    pub inline fn queueWriteTexture(queue: *gpu.Queue, destination: *const gpu.ImageCopyTexture, data: *const anyopaque, data_size: usize, data_layout: *const gpu.Texture.DataLayout, write_size: *const gpu.Extent3D) void {
        procs.queueWriteTexture.?(
            @ptrCast(c.WGPUQueue, queue),
            @ptrCast(*const c.WGPUImageCopyTexture, destination),
            data,
            data_size,
            @ptrCast(*const c.WGPUTextureDataLayout, data_layout),
            @ptrCast(*const c.WGPUExtent3D, write_size),
        );
    }

    pub inline fn queueReference(queue: *gpu.Queue) void {
        procs.queueReference.?(@ptrCast(c.WGPUQueue, queue));
    }

    pub inline fn queueRelease(queue: *gpu.Queue) void {
        procs.queueRelease.?(@ptrCast(c.WGPUQueue, queue));
    }

    pub inline fn renderBundleReference(render_bundle: *gpu.RenderBundle) void {
        procs.renderBundleReference.?(@ptrCast(c.WGPURenderBundle, render_bundle));
    }

    pub inline fn renderBundleRelease(render_bundle: *gpu.RenderBundle) void {
        procs.renderBundleRelease.?(@ptrCast(c.WGPURenderBundle, render_bundle));
    }

    pub inline fn renderBundleEncoderDraw(render_bundle_encoder: *gpu.RenderBundleEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {
        procs.renderBundleEncoderDraw.?(@ptrCast(c.WGPURenderBundleEncoder, render_bundle_encoder), vertex_count, instance_count, first_vertex, first_instance);
    }

    pub inline fn renderBundleEncoderDrawIndexed(render_bundle_encoder: *gpu.RenderBundleEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: i32, first_instance: u32) void {
        procs.renderBundleEncoderDrawIndexed.?(
            @ptrCast(c.WGPURenderBundleEncoder, render_bundle_encoder),
            index_count,
            instance_count,
            first_index,
            base_vertex,
            first_instance,
        );
    }

    pub inline fn renderBundleEncoderDrawIndexedIndirect(render_bundle_encoder: *gpu.RenderBundleEncoder, indirect_buffer: *gpu.Buffer, indirect_offset: u64) void {
        procs.renderBundleEncoderDrawIndexedIndirect.?(
            @ptrCast(c.WGPURenderBundleEncoder, render_bundle_encoder),
            @ptrCast(c.WGPUBuffer, indirect_buffer),
            indirect_offset,
        );
    }

    pub inline fn renderBundleEncoderDrawIndirect(render_bundle_encoder: *gpu.RenderBundleEncoder, indirect_buffer: *gpu.Buffer, indirect_offset: u64) void {
        procs.renderBundleEncoderDrawIndirect.?(
            @ptrCast(c.WGPURenderBundleEncoder, render_bundle_encoder),
            @ptrCast(c.WGPUBuffer, indirect_buffer),
            indirect_offset,
        );
    }

    pub inline fn renderBundleEncoderFinish(render_bundle_encoder: *gpu.RenderBundleEncoder, descriptor: ?*const gpu.RenderBundle.Descriptor) *gpu.RenderBundle {
        return @ptrCast(*gpu.RenderBundle, procs.renderBundleEncoderFinish.?(
            @ptrCast(c.WGPURenderBundleEncoder, render_bundle_encoder),
            @ptrCast(?*const c.WGPURenderBundleDescriptor, descriptor),
        ));
    }

    pub inline fn renderBundleEncoderInsertDebugMarker(render_bundle_encoder: *gpu.RenderBundleEncoder, marker_label: [*:0]const u8) void {
        procs.renderBundleEncoderInsertDebugMarker.?(
            @ptrCast(c.WGPURenderBundleEncoder, render_bundle_encoder),
            marker_label,
        );
    }

    pub inline fn renderBundleEncoderPopDebugGroup(render_bundle_encoder: *gpu.RenderBundleEncoder) void {
        procs.renderBundleEncoderPopDebugGroup.?(@ptrCast(c.WGPURenderBundleEncoder, render_bundle_encoder));
    }

    pub inline fn renderBundleEncoderPushDebugGroup(render_bundle_encoder: *gpu.RenderBundleEncoder, group_label: [*:0]const u8) void {
        procs.renderBundleEncoderPushDebugGroup.?(@ptrCast(c.WGPURenderBundleEncoder, render_bundle_encoder), group_label);
    }

    pub inline fn renderBundleEncoderSetBindGroup(render_bundle_encoder: *gpu.RenderBundleEncoder, group_index: u32, group: *gpu.BindGroup, dynamic_offset_count: u32, dynamic_offsets: ?[*]const u32) void {
        procs.renderBundleEncoderSetBindGroup.?(
            @ptrCast(c.WGPURenderBundleEncoder, render_bundle_encoder),
            group_index,
            @ptrCast(c.WGPUBindGroup, group),
            dynamic_offset_count,
            dynamic_offsets,
        );
    }

    pub inline fn renderBundleEncoderSetIndexBuffer(render_bundle_encoder: *gpu.RenderBundleEncoder, buffer: *gpu.Buffer, format: gpu.IndexFormat, offset: u64, size: u64) void {
        procs.renderBundleEncoderSetIndexBuffer.?(
            @ptrCast(c.WGPURenderBundleEncoder, render_bundle_encoder),
            @ptrCast(c.WGPUBuffer, buffer),
            @enumToInt(format),
            offset,
            size,
        );
    }

    pub inline fn renderBundleEncoderSetLabel(render_bundle_encoder: *gpu.RenderBundleEncoder, label: [*:0]const u8) void {
        procs.renderBundleEncoderSetLabel.?(@ptrCast(c.WGPURenderBundleEncoder, render_bundle_encoder), label);
    }

    pub inline fn renderBundleEncoderSetPipeline(render_bundle_encoder: *gpu.RenderBundleEncoder, pipeline: *gpu.RenderPipeline) void {
        procs.renderBundleEncoderSetPipeline.?(
            @ptrCast(c.WGPURenderBundleEncoder, render_bundle_encoder),
            @ptrCast(c.WGPURenderPipeline, pipeline),
        );
    }

    pub inline fn renderBundleEncoderSetVertexBuffer(render_bundle_encoder: *gpu.RenderBundleEncoder, slot: u32, buffer: *gpu.Buffer, offset: u64, size: u64) void {
        procs.renderBundleEncoderSetVertexBuffer.?(
            @ptrCast(c.WGPURenderBundleEncoder, render_bundle_encoder),
            slot,
            @ptrCast(c.WGPUBuffer, buffer),
            offset,
            size,
        );
    }

    pub inline fn renderBundleEncoderReference(render_bundle_encoder: *gpu.RenderBundleEncoder) void {
        procs.renderBundleEncoderReference.?(@ptrCast(c.WGPURenderBundleEncoder, render_bundle_encoder));
    }

    pub inline fn renderBundleEncoderRelease(render_bundle_encoder: *gpu.RenderBundleEncoder) void {
        procs.renderBundleEncoderRelease.?(@ptrCast(c.WGPURenderBundleEncoder, render_bundle_encoder));
    }

    pub inline fn renderPassEncoderBeginOcclusionQuery(render_pass_encoder: *gpu.RenderPassEncoder, query_index: u32) void {
        procs.renderPassEncoderBeginOcclusionQuery.?(
            @ptrCast(c.WGPURenderPassEncoder, render_pass_encoder),
            query_index,
        );
    }

    pub inline fn renderPassEncoderDraw(render_pass_encoder: *gpu.RenderPassEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {
        procs.renderPassEncoderDraw.?(
            @ptrCast(c.WGPURenderPassEncoder, render_pass_encoder),
            vertex_count,
            instance_count,
            first_vertex,
            first_instance,
        );
    }

    pub inline fn renderPassEncoderDrawIndexed(render_pass_encoder: *gpu.RenderPassEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: i32, first_instance: u32) void {
        procs.renderPassEncoderDrawIndexed.?(
            @ptrCast(c.WGPURenderPassEncoder, render_pass_encoder),
            index_count,
            instance_count,
            first_index,
            base_vertex,
            first_instance,
        );
    }

    pub inline fn renderPassEncoderDrawIndexedIndirect(render_pass_encoder: *gpu.RenderPassEncoder, indirect_buffer: *gpu.Buffer, indirect_offset: u64) void {
        procs.renderPassEncoderDrawIndexedIndirect.?(
            @ptrCast(c.WGPURenderPassEncoder, render_pass_encoder),
            @ptrCast(c.WGPUBuffer, indirect_buffer),
            indirect_offset,
        );
    }

    pub inline fn renderPassEncoderDrawIndirect(render_pass_encoder: *gpu.RenderPassEncoder, indirect_buffer: *gpu.Buffer, indirect_offset: u64) void {
        procs.renderPassEncoderDrawIndirect.?(
            @ptrCast(c.WGPURenderPassEncoder, render_pass_encoder),
            @ptrCast(c.WGPUBuffer, indirect_buffer),
            indirect_offset,
        );
    }

    pub inline fn renderPassEncoderEnd(render_pass_encoder: *gpu.RenderPassEncoder) void {
        procs.renderPassEncoderEnd.?(@ptrCast(c.WGPURenderPassEncoder, render_pass_encoder));
    }

    pub inline fn renderPassEncoderEndOcclusionQuery(render_pass_encoder: *gpu.RenderPassEncoder) void {
        procs.renderPassEncoderEndOcclusionQuery.?(@ptrCast(c.WGPURenderPassEncoder, render_pass_encoder));
    }

    pub inline fn renderPassEncoderExecuteBundles(render_pass_encoder: *gpu.RenderPassEncoder, bundles_count: u32, bundles: [*]const *const gpu.RenderBundle) void {
        procs.renderPassEncoderExecuteBundles.?(
            @ptrCast(c.WGPURenderPassEncoder, render_pass_encoder),
            bundles_count,
            @ptrCast([*]const c.WGPURenderBundle, bundles),
        );
    }

    pub inline fn renderPassEncoderInsertDebugMarker(render_pass_encoder: *gpu.RenderPassEncoder, marker_label: [*:0]const u8) void {
        procs.renderPassEncoderInsertDebugMarker.?(@ptrCast(c.WGPURenderPassEncoder, render_pass_encoder), marker_label);
    }

    pub inline fn renderPassEncoderPopDebugGroup(render_pass_encoder: *gpu.RenderPassEncoder) void {
        procs.renderPassEncoderPopDebugGroup.?(@ptrCast(c.WGPURenderPassEncoder, render_pass_encoder));
    }

    pub inline fn renderPassEncoderPushDebugGroup(render_pass_encoder: *gpu.RenderPassEncoder, group_label: [*:0]const u8) void {
        procs.renderPassEncoderPushDebugGroup.?(
            @ptrCast(c.WGPURenderPassEncoder, render_pass_encoder),
            group_label,
        );
    }

    pub inline fn renderPassEncoderSetBindGroup(render_pass_encoder: *gpu.RenderPassEncoder, group_index: u32, group: *gpu.BindGroup, dynamic_offset_count: u32, dynamic_offsets: ?[*]const u32) void {
        procs.renderPassEncoderSetBindGroup.?(
            @ptrCast(c.WGPURenderPassEncoder, render_pass_encoder),
            group_index,
            @ptrCast(c.WGPUBindGroup, group),
            dynamic_offset_count,
            dynamic_offsets,
        );
    }

    pub inline fn renderPassEncoderSetBlendConstant(render_pass_encoder: *gpu.RenderPassEncoder, color: *const gpu.Color) void {
        procs.renderPassEncoderSetBlendConstant.?(
            @ptrCast(c.WGPURenderPassEncoder, render_pass_encoder),
            @ptrCast(*const c.WGPUColor, color),
        );
    }

    pub inline fn renderPassEncoderSetIndexBuffer(render_pass_encoder: *gpu.RenderPassEncoder, buffer: *gpu.Buffer, format: gpu.IndexFormat, offset: u64, size: u64) void {
        procs.renderPassEncoderSetIndexBuffer.?(
            @ptrCast(c.WGPURenderPassEncoder, render_pass_encoder),
            @ptrCast(c.WGPUBuffer, buffer),
            @enumToInt(format),
            offset,
            size,
        );
    }

    pub inline fn renderPassEncoderSetLabel(render_pass_encoder: *gpu.RenderPassEncoder, label: [*:0]const u8) void {
        procs.renderPassEncoderSetLabel.?(@ptrCast(c.WGPURenderPassEncoder, render_pass_encoder), label);
    }

    pub inline fn renderPassEncoderSetPipeline(render_pass_encoder: *gpu.RenderPassEncoder, pipeline: *gpu.RenderPipeline) void {
        procs.renderPassEncoderSetPipeline.?(
            @ptrCast(c.WGPURenderPassEncoder, render_pass_encoder),
            @ptrCast(c.WGPURenderPipeline, pipeline),
        );
    }

    pub inline fn renderPassEncoderSetScissorRect(render_pass_encoder: *gpu.RenderPassEncoder, x: u32, y: u32, width: u32, height: u32) void {
        procs.renderPassEncoderSetScissorRect.?(
            @ptrCast(c.WGPURenderPassEncoder, render_pass_encoder),
            x,
            y,
            width,
            height,
        );
    }

    pub inline fn renderPassEncoderSetStencilReference(render_pass_encoder: *gpu.RenderPassEncoder, reference: u32) void {
        procs.renderPassEncoderSetStencilReference.?(
            @ptrCast(c.WGPURenderPassEncoder, render_pass_encoder),
            reference,
        );
    }

    pub inline fn renderPassEncoderSetVertexBuffer(render_pass_encoder: *gpu.RenderPassEncoder, slot: u32, buffer: *gpu.Buffer, offset: u64, size: u64) void {
        procs.renderPassEncoderSetVertexBuffer.?(
            @ptrCast(c.WGPURenderPassEncoder, render_pass_encoder),
            slot,
            @ptrCast(c.WGPUBuffer, buffer),
            offset,
            size,
        );
    }

    pub inline fn renderPassEncoderSetViewport(render_pass_encoder: *gpu.RenderPassEncoder, x: f32, y: f32, width: f32, height: f32, min_depth: f32, max_depth: f32) void {
        procs.renderPassEncoderSetViewport.?(
            @ptrCast(c.WGPURenderPassEncoder, render_pass_encoder),
            x,
            y,
            width,
            height,
            min_depth,
            max_depth,
        );
    }

    pub inline fn renderPassEncoderWriteTimestamp(render_pass_encoder: *gpu.RenderPassEncoder, query_set: *gpu.QuerySet, query_index: u32) void {
        procs.renderPassEncoderWriteTimestamp.?(
            @ptrCast(c.WGPURenderPassEncoder, render_pass_encoder),
            @ptrCast(c.WGPUQuerySet, query_set),
            query_index,
        );
    }

    pub inline fn renderPassEncoderReference(render_pass_encoder: *gpu.RenderPassEncoder) void {
        procs.renderPassEncoderReference.?(@ptrCast(c.WGPURenderPassEncoder, render_pass_encoder));
    }

    pub inline fn renderPassEncoderRelease(render_pass_encoder: *gpu.RenderPassEncoder) void {
        procs.renderPassEncoderRelease.?(@ptrCast(c.WGPURenderPassEncoder, render_pass_encoder));
    }

    pub inline fn renderPipelineGetBindGroupLayout(render_pipeline: *gpu.RenderPipeline, group_index: u32) *gpu.BindGroupLayout {
        return @ptrCast(*gpu.BindGroupLayout, procs.renderPipelineGetBindGroupLayout.?(
            @ptrCast(c.WGPURenderPipeline, render_pipeline),
            group_index,
        ));
    }

    pub inline fn renderPipelineSetLabel(render_pipeline: *gpu.RenderPipeline, label: [*:0]const u8) void {
        procs.renderPipelineSetLabel.?(@ptrCast(c.WGPURenderPipeline, render_pipeline), label);
    }

    pub inline fn renderPipelineReference(render_pipeline: *gpu.RenderPipeline) void {
        procs.renderPipelineReference.?(@ptrCast(c.WGPURenderPipeline, render_pipeline));
    }

    pub inline fn renderPipelineRelease(render_pipeline: *gpu.RenderPipeline) void {
        procs.renderPipelineRelease.?(@ptrCast(c.WGPURenderPipeline, render_pipeline));
    }

    pub inline fn samplerSetLabel(sampler: *gpu.Sampler, label: [*:0]const u8) void {
        procs.samplerSetLabel.?(@ptrCast(c.WGPUSampler, sampler), label);
    }

    pub inline fn samplerReference(sampler: *gpu.Sampler) void {
        procs.samplerReference.?(@ptrCast(c.WGPUSampler, sampler));
    }

    pub inline fn samplerRelease(sampler: *gpu.Sampler) void {
        procs.samplerRelease.?(@ptrCast(c.WGPUSampler, sampler));
    }

    pub inline fn shaderModuleGetCompilationInfo(shader_module: *gpu.ShaderModule, callback: gpu.CompilationInfoCallback, userdata: ?*anyopaque) void {
        procs.shaderModuleGetCompilationInfo.?(
            @ptrCast(c.WGPUShaderModule, shader_module),
            @ptrCast(c.WGPUCompilationInfoCallback, callback),
            userdata,
        );
    }

    pub inline fn shaderModuleSetLabel(shader_module: *gpu.ShaderModule, label: [*:0]const u8) void {
        procs.shaderModuleSetLabel.?(@ptrCast(c.WGPUShaderModule, shader_module), label);
    }

    pub inline fn shaderModuleReference(shader_module: *gpu.ShaderModule) void {
        procs.shaderModuleReference.?(@ptrCast(c.WGPUShaderModule, shader_module));
    }

    pub inline fn shaderModuleRelease(shader_module: *gpu.ShaderModule) void {
        procs.shaderModuleRelease.?(@ptrCast(c.WGPUShaderModule, shader_module));
    }

    pub inline fn surfaceReference(surface: *gpu.Surface) void {
        procs.surfaceReference.?(@ptrCast(c.WGPUSurface, surface));
    }

    pub inline fn surfaceRelease(surface: *gpu.Surface) void {
        procs.surfaceRelease.?(@ptrCast(c.WGPUSurface, surface));
    }

    pub inline fn swapChainConfigure(swap_chain: *gpu.SwapChain, format: gpu.Texture.Format, allowed_usage: gpu.Texture.UsageFlags, width: u32, height: u32) void {
        procs.swapChainConfigure.?(
            @ptrCast(c.WGPUSwapChain, swap_chain),
            @enumToInt(format),
            @bitCast(c.WGPUTextureUsageFlags, allowed_usage),
            width,
            height,
        );
    }

    pub inline fn swapChainGetCurrentTextureView(swap_chain: *gpu.SwapChain) *gpu.TextureView {
        return @ptrCast(*gpu.TextureView, procs.swapChainGetCurrentTextureView.?(@ptrCast(c.WGPUSwapChain, swap_chain)));
    }

    pub inline fn swapChainPresent(swap_chain: *gpu.SwapChain) void {
        procs.swapChainPresent.?(@ptrCast(c.WGPUSwapChain, swap_chain));
    }

    pub inline fn swapChainReference(swap_chain: *gpu.SwapChain) void {
        procs.swapChainReference.?(@ptrCast(c.WGPUSwapChain, swap_chain));
    }

    pub inline fn swapChainRelease(swap_chain: *gpu.SwapChain) void {
        procs.swapChainRelease.?(@ptrCast(c.WGPUSwapChain, swap_chain));
    }

    pub inline fn textureCreateView(texture: *gpu.Texture, descriptor: ?*const gpu.TextureView.Descriptor) *gpu.TextureView {
        return @ptrCast(*gpu.TextureView, procs.textureCreateView.?(
            @ptrCast(c.WGPUTexture, texture),
            @ptrCast(?*const c.WGPUTextureViewDescriptor, descriptor),
        ));
    }

    pub inline fn textureDestroy(texture: *gpu.Texture) void {
        procs.textureDestroy.?(@ptrCast(c.WGPUTexture, texture));
    }

    pub inline fn textureGetDepthOrArrayLayers(texture: *gpu.Texture) u32 {
        return procs.textureGetDepthOrArrayLayers.?(@ptrCast(c.WGPUTexture, texture));
    }

    pub inline fn textureGetDimension(texture: *gpu.Texture) gpu.Texture.Dimension {
        return @intToEnum(gpu.Texture.Dimension, procs.textureGetDimension.?(@ptrCast(c.WGPUTexture, texture)));
    }

    pub inline fn textureGetFormat(texture: *gpu.Texture) gpu.Texture.Format {
        return @intToEnum(gpu.Texture.Format, procs.textureGetFormat.?(@ptrCast(c.WGPUTexture, texture)));
    }

    pub inline fn textureGetHeight(texture: *gpu.Texture) u32 {
        return procs.textureGetHeight.?(@ptrCast(c.WGPUTexture, texture));
    }

    pub inline fn textureGetMipLevelCount(texture: *gpu.Texture) u32 {
        return procs.textureGetMipLevelCount.?(@ptrCast(c.WGPUTexture, texture));
    }

    pub inline fn textureGetSampleCount(texture: *gpu.Texture) u32 {
        return procs.textureGetSampleCount.?(@ptrCast(c.WGPUTexture, texture));
    }

    pub inline fn textureGetUsage(texture: *gpu.Texture) gpu.Texture.UsageFlags {
        return @bitCast(gpu.Texture.UsageFlags, procs.textureGetUsage.?(
            @ptrCast(c.WGPUTexture, texture),
        ));
    }

    pub inline fn textureGetWidth(texture: *gpu.Texture) u32 {
        return procs.textureGetWidth.?(@ptrCast(c.WGPUTexture, texture));
    }

    pub inline fn textureSetLabel(texture: *gpu.Texture, label: [*:0]const u8) void {
        procs.textureSetLabel.?(@ptrCast(c.WGPUTexture, texture), label);
    }

    pub inline fn textureReference(texture: *gpu.Texture) void {
        procs.textureReference.?(@ptrCast(c.WGPUTexture, texture));
    }

    pub inline fn textureRelease(texture: *gpu.Texture) void {
        procs.textureRelease.?(@ptrCast(c.WGPUTexture, texture));
    }

    pub inline fn textureViewSetLabel(texture_view: *gpu.TextureView, label: [*:0]const u8) void {
        procs.textureViewSetLabel.?(@ptrCast(c.WGPUTextureView, texture_view), label);
    }

    pub inline fn textureViewReference(texture_view: *gpu.TextureView) void {
        procs.textureViewReference.?(@ptrCast(c.WGPUTextureView, texture_view));
    }

    pub inline fn textureViewRelease(texture_view: *gpu.TextureView) void {
        procs.textureViewRelease.?(@ptrCast(c.WGPUTextureView, texture_view));
    }
};

test "dawn_impl" {
    _ = gpu.Export(Interface);
}
