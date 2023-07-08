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
        return @as(?*gpu.Instance, @ptrCast(procs.createInstance.?(
            @as(?*const c.WGPUInstanceDescriptor, @ptrCast(descriptor)),
        )));
    }

    pub inline fn getProcAddress(device: *gpu.Device, proc_name: [*:0]const u8) ?gpu.Proc {
        return procs.getProcAddress.?(
            @as(c.WGPUDevice, @ptrCast(device)),
            proc_name,
        );
    }

    pub inline fn adapterCreateDevice(adapter: *gpu.Adapter, descriptor: ?*const gpu.Device.Descriptor) ?*gpu.Device {
        return @as(?*gpu.Device, @ptrCast(procs.adapterCreateDevice.?(
            @as(c.WGPUAdapter, @ptrCast(adapter)),
            @as(?*const c.WGPUDeviceDescriptor, @ptrCast(descriptor)),
        )));
    }

    pub inline fn adapterEnumerateFeatures(adapter: *gpu.Adapter, features: ?[*]gpu.FeatureName) usize {
        return procs.adapterEnumerateFeatures.?(
            @as(c.WGPUAdapter, @ptrCast(adapter)),
            @as(?[*]c.WGPUFeatureName, @ptrCast(features)),
        );
    }

    pub inline fn adapterGetInstance(adapter: *gpu.Adapter) *gpu.Instance {
        return @as(*gpu.Instance, @ptrCast(procs.adapterGetInstance.?(
            @as(c.WGPUAdapter, @ptrCast(adapter)),
        )));
    }

    pub inline fn adapterGetLimits(adapter: *gpu.Adapter, limits: *gpu.SupportedLimits) bool {
        return procs.adapterGetLimits.?(
            @as(c.WGPUAdapter, @ptrCast(adapter)),
            @as(*c.WGPUSupportedLimits, @ptrCast(limits)),
        );
    }

    pub inline fn adapterGetProperties(adapter: *gpu.Adapter, properties: *gpu.Adapter.Properties) void {
        return procs.adapterGetProperties.?(
            @as(c.WGPUAdapter, @ptrCast(adapter)),
            @as(*c.WGPUAdapterProperties, @ptrCast(properties)),
        );
    }

    pub inline fn adapterHasFeature(adapter: *gpu.Adapter, feature: gpu.FeatureName) bool {
        return procs.adapterHasFeature.?(
            @as(c.WGPUAdapter, @ptrCast(adapter)),
            @intFromEnum(feature),
        );
    }

    pub inline fn adapterRequestDevice(adapter: *gpu.Adapter, descriptor: ?*const gpu.Device.Descriptor, callback: gpu.RequestDeviceCallback, userdata: ?*anyopaque) void {
        return procs.adapterRequestDevice.?(
            @as(c.WGPUAdapter, @ptrCast(adapter)),
            @as(?*const c.WGPUDeviceDescriptor, @ptrCast(descriptor)),
            @as(c.WGPURequestDeviceCallback, @ptrCast(callback)),
            userdata,
        );
    }

    pub inline fn adapterReference(adapter: *gpu.Adapter) void {
        procs.adapterReference.?(@as(c.WGPUAdapter, @ptrCast(adapter)));
    }

    pub inline fn adapterRelease(adapter: *gpu.Adapter) void {
        procs.adapterRelease.?(@as(c.WGPUAdapter, @ptrCast(adapter)));
    }

    pub inline fn bindGroupSetLabel(bind_group: *gpu.BindGroup, label: [*:0]const u8) void {
        procs.bindGroupSetLabel.?(@as(c.WGPUBindGroup, @ptrCast(bind_group)), label);
    }

    pub inline fn bindGroupReference(bind_group: *gpu.BindGroup) void {
        procs.bindGroupReference.?(@as(c.WGPUBindGroup, @ptrCast(bind_group)));
    }

    pub inline fn bindGroupRelease(bind_group: *gpu.BindGroup) void {
        procs.bindGroupRelease.?(@as(c.WGPUBindGroup, @ptrCast(bind_group)));
    }

    pub inline fn bindGroupLayoutSetLabel(bind_group_layout: *gpu.BindGroupLayout, label: [*:0]const u8) void {
        procs.bindGroupLayoutSetLabel.?(@as(c.WGPUBindGroupLayout, @ptrCast(bind_group_layout)), label);
    }

    pub inline fn bindGroupLayoutReference(bind_group_layout: *gpu.BindGroupLayout) void {
        procs.bindGroupLayoutReference.?(@as(c.WGPUBindGroupLayout, @ptrCast(bind_group_layout)));
    }

    pub inline fn bindGroupLayoutRelease(bind_group_layout: *gpu.BindGroupLayout) void {
        procs.bindGroupLayoutRelease.?(@as(c.WGPUBindGroupLayout, @ptrCast(bind_group_layout)));
    }

    pub inline fn bufferDestroy(buffer: *gpu.Buffer) void {
        procs.bufferDestroy.?(@as(c.WGPUBuffer, @ptrCast(buffer)));
    }

    pub inline fn bufferGetMapState(buffer: *gpu.Buffer) gpu.Buffer.MapState {
        return @enumFromInt(procs.bufferGetMapState.?(@as(c.WGPUBuffer, @ptrCast(buffer))));
    }

    // TODO: dawn: return value not marked as nullable in dawn.json but in fact is.
    pub inline fn bufferGetConstMappedRange(buffer: *gpu.Buffer, offset: usize, size: usize) ?*const anyopaque {
        return procs.bufferGetConstMappedRange.?(
            @as(c.WGPUBuffer, @ptrCast(buffer)),
            offset,
            size,
        );
    }

    // TODO: dawn: return value not marked as nullable in dawn.json but in fact is.
    pub inline fn bufferGetMappedRange(buffer: *gpu.Buffer, offset: usize, size: usize) ?*anyopaque {
        return procs.bufferGetMappedRange.?(
            @as(c.WGPUBuffer, @ptrCast(buffer)),
            offset,
            size,
        );
    }

    pub inline fn bufferGetSize(buffer: *gpu.Buffer) u64 {
        return procs.bufferGetSize.?(@as(c.WGPUBuffer, @ptrCast(buffer)));
    }

    pub inline fn bufferGetUsage(buffer: *gpu.Buffer) gpu.Buffer.UsageFlags {
        return @as(gpu.Buffer.UsageFlags, @bitCast(procs.bufferGetUsage.?(@as(c.WGPUBuffer, @ptrCast(buffer)))));
    }

    pub inline fn bufferMapAsync(buffer: *gpu.Buffer, mode: gpu.MapModeFlags, offset: usize, size: usize, callback: gpu.Buffer.MapCallback, userdata: ?*anyopaque) void {
        procs.bufferMapAsync.?(
            @as(c.WGPUBuffer, @ptrCast(buffer)),
            @as(c.WGPUMapModeFlags, @bitCast(mode)),
            offset,
            size,
            @as(c.WGPUBufferMapCallback, @ptrCast(callback)),
            userdata,
        );
    }

    pub inline fn bufferSetLabel(buffer: *gpu.Buffer, label: [*:0]const u8) void {
        procs.bufferSetLabel.?(@as(c.WGPUBuffer, @ptrCast(buffer)), label);
    }

    pub inline fn bufferUnmap(buffer: *gpu.Buffer) void {
        procs.bufferUnmap.?(@as(c.WGPUBuffer, @ptrCast(buffer)));
    }

    pub inline fn bufferReference(buffer: *gpu.Buffer) void {
        procs.bufferReference.?(@as(c.WGPUBuffer, @ptrCast(buffer)));
    }

    pub inline fn bufferRelease(buffer: *gpu.Buffer) void {
        procs.bufferRelease.?(@as(c.WGPUBuffer, @ptrCast(buffer)));
    }

    pub inline fn commandBufferSetLabel(command_buffer: *gpu.CommandBuffer, label: [*:0]const u8) void {
        procs.commandBufferSetLabel.?(@as(c.WGPUCommandBuffer, @ptrCast(command_buffer)), label);
    }

    pub inline fn commandBufferReference(command_buffer: *gpu.CommandBuffer) void {
        procs.commandBufferReference.?(@as(c.WGPUCommandBuffer, @ptrCast(command_buffer)));
    }

    pub inline fn commandBufferRelease(command_buffer: *gpu.CommandBuffer) void {
        procs.commandBufferRelease.?(@as(c.WGPUCommandBuffer, @ptrCast(command_buffer)));
    }

    pub inline fn commandEncoderBeginComputePass(command_encoder: *gpu.CommandEncoder, descriptor: ?*const gpu.ComputePassDescriptor) *gpu.ComputePassEncoder {
        return @as(*gpu.ComputePassEncoder, @ptrCast(procs.commandEncoderBeginComputePass.?(
            @as(c.WGPUCommandEncoder, @ptrCast(command_encoder)),
            @as(?*const c.WGPUComputePassDescriptor, @ptrCast(descriptor)),
        )));
    }

    pub inline fn commandEncoderBeginRenderPass(command_encoder: *gpu.CommandEncoder, descriptor: *const gpu.RenderPassDescriptor) *gpu.RenderPassEncoder {
        return @as(*gpu.RenderPassEncoder, @ptrCast(procs.commandEncoderBeginRenderPass.?(
            @as(c.WGPUCommandEncoder, @ptrCast(command_encoder)),
            @as(?*const c.WGPURenderPassDescriptor, @ptrCast(descriptor)),
        )));
    }

    pub inline fn commandEncoderClearBuffer(command_encoder: *gpu.CommandEncoder, buffer: *gpu.Buffer, offset: u64, size: u64) void {
        procs.commandEncoderClearBuffer.?(
            @as(c.WGPUCommandEncoder, @ptrCast(command_encoder)),
            @as(c.WGPUBuffer, @ptrCast(buffer)),
            offset,
            size,
        );
    }

    pub inline fn commandEncoderCopyBufferToBuffer(command_encoder: *gpu.CommandEncoder, source: *gpu.Buffer, source_offset: u64, destination: *gpu.Buffer, destination_offset: u64, size: u64) void {
        procs.commandEncoderCopyBufferToBuffer.?(
            @as(c.WGPUCommandEncoder, @ptrCast(command_encoder)),
            @as(c.WGPUBuffer, @ptrCast(source)),
            source_offset,
            @as(c.WGPUBuffer, @ptrCast(destination)),
            destination_offset,
            size,
        );
    }

    pub inline fn commandEncoderCopyBufferToTexture(command_encoder: *gpu.CommandEncoder, source: *const gpu.ImageCopyBuffer, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) void {
        procs.commandEncoderCopyBufferToTexture.?(
            @as(c.WGPUCommandEncoder, @ptrCast(command_encoder)),
            @as(*const c.WGPUImageCopyBuffer, @ptrCast(source)),
            @as(*const c.WGPUImageCopyTexture, @ptrCast(destination)),
            @as(*const c.WGPUExtent3D, @ptrCast(copy_size)),
        );
    }

    pub inline fn commandEncoderCopyTextureToBuffer(command_encoder: *gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyBuffer, copy_size: *const gpu.Extent3D) void {
        procs.commandEncoderCopyTextureToBuffer.?(
            @as(c.WGPUCommandEncoder, @ptrCast(command_encoder)),
            @as(*const c.WGPUImageCopyTexture, @ptrCast(source)),
            @as(*const c.WGPUImageCopyBuffer, @ptrCast(destination)),
            @as(*const c.WGPUExtent3D, @ptrCast(copy_size)),
        );
    }

    pub inline fn commandEncoderCopyTextureToTexture(command_encoder: *gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) void {
        procs.commandEncoderCopyTextureToTexture.?(
            @as(c.WGPUCommandEncoder, @ptrCast(command_encoder)),
            @as(*const c.WGPUImageCopyTexture, @ptrCast(source)),
            @as(*const c.WGPUImageCopyTexture, @ptrCast(destination)),
            @as(*const c.WGPUExtent3D, @ptrCast(copy_size)),
        );
    }

    pub inline fn commandEncoderCopyTextureToTextureInternal(command_encoder: *gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) void {
        procs.commandEncoderCopyTextureToTextureInternal.?(
            @as(c.WGPUCommandEncoder, @ptrCast(command_encoder)),
            @as(*const c.WGPUImageCopyTexture, @ptrCast(source)),
            @as(*const c.WGPUImageCopyTexture, @ptrCast(destination)),
            @as(*const c.WGPUExtent3D, @ptrCast(copy_size)),
        );
    }

    pub inline fn commandEncoderFinish(command_encoder: *gpu.CommandEncoder, descriptor: ?*const gpu.CommandBuffer.Descriptor) *gpu.CommandBuffer {
        return @as(*gpu.CommandBuffer, @ptrCast(procs.commandEncoderFinish.?(
            @as(c.WGPUCommandEncoder, @ptrCast(command_encoder)),
            @as(?*const c.WGPUCommandBufferDescriptor, @ptrCast(descriptor)),
        )));
    }

    pub inline fn commandEncoderInjectValidationError(command_encoder: *gpu.CommandEncoder, message: [*:0]const u8) void {
        procs.commandEncoderInjectValidationError.?(
            @as(c.WGPUCommandEncoder, @ptrCast(command_encoder)),
            message,
        );
    }

    pub inline fn commandEncoderInsertDebugMarker(command_encoder: *gpu.CommandEncoder, marker_label: [*:0]const u8) void {
        procs.commandEncoderInsertDebugMarker.?(
            @as(c.WGPUCommandEncoder, @ptrCast(command_encoder)),
            marker_label,
        );
    }

    pub inline fn commandEncoderPopDebugGroup(command_encoder: *gpu.CommandEncoder) void {
        procs.commandEncoderPopDebugGroup.?(@as(c.WGPUCommandEncoder, @ptrCast(command_encoder)));
    }

    pub inline fn commandEncoderPushDebugGroup(command_encoder: *gpu.CommandEncoder, group_label: [*:0]const u8) void {
        procs.commandEncoderPushDebugGroup.?(
            @as(c.WGPUCommandEncoder, @ptrCast(command_encoder)),
            group_label,
        );
    }

    pub inline fn commandEncoderResolveQuerySet(command_encoder: *gpu.CommandEncoder, query_set: *gpu.QuerySet, first_query: u32, query_count: u32, destination: *gpu.Buffer, destination_offset: u64) void {
        procs.commandEncoderResolveQuerySet.?(
            @as(c.WGPUCommandEncoder, @ptrCast(command_encoder)),
            @as(c.WGPUQuerySet, @ptrCast(query_set)),
            first_query,
            query_count,
            @as(c.WGPUBuffer, @ptrCast(destination)),
            destination_offset,
        );
    }

    pub inline fn commandEncoderSetLabel(command_encoder: *gpu.CommandEncoder, label: [*:0]const u8) void {
        procs.commandEncoderSetLabel.?(@as(c.WGPUCommandEncoder, @ptrCast(command_encoder)), label);
    }

    pub inline fn commandEncoderWriteBuffer(command_encoder: *gpu.CommandEncoder, buffer: *gpu.Buffer, buffer_offset: u64, data: [*]const u8, size: u64) void {
        procs.commandEncoderWriteBuffer.?(
            @as(c.WGPUCommandEncoder, @ptrCast(command_encoder)),
            @as(c.WGPUBuffer, @ptrCast(buffer)),
            buffer_offset,
            data,
            size,
        );
    }

    pub inline fn commandEncoderWriteTimestamp(command_encoder: *gpu.CommandEncoder, query_set: *gpu.QuerySet, query_index: u32) void {
        procs.commandEncoderWriteTimestamp.?(
            @as(c.WGPUCommandEncoder, @ptrCast(command_encoder)),
            @as(c.WGPUQuerySet, @ptrCast(query_set)),
            query_index,
        );
    }

    pub inline fn commandEncoderReference(command_encoder: *gpu.CommandEncoder) void {
        procs.commandEncoderReference.?(@as(c.WGPUCommandEncoder, @ptrCast(command_encoder)));
    }

    pub inline fn commandEncoderRelease(command_encoder: *gpu.CommandEncoder) void {
        procs.commandEncoderRelease.?(@as(c.WGPUCommandEncoder, @ptrCast(command_encoder)));
    }

    pub inline fn computePassEncoderDispatchWorkgroups(compute_pass_encoder: *gpu.ComputePassEncoder, workgroup_count_x: u32, workgroup_count_y: u32, workgroup_count_z: u32) void {
        procs.computePassEncoderDispatchWorkgroups.?(
            @as(c.WGPUComputePassEncoder, @ptrCast(compute_pass_encoder)),
            workgroup_count_x,
            workgroup_count_y,
            workgroup_count_z,
        );
    }

    pub inline fn computePassEncoderDispatchWorkgroupsIndirect(compute_pass_encoder: *gpu.ComputePassEncoder, indirect_buffer: *gpu.Buffer, indirect_offset: u64) void {
        procs.computePassEncoderDispatchWorkgroupsIndirect.?(
            @as(c.WGPUComputePassEncoder, @ptrCast(compute_pass_encoder)),
            @as(c.WGPUBuffer, @ptrCast(indirect_buffer)),
            indirect_offset,
        );
    }

    pub inline fn computePassEncoderEnd(compute_pass_encoder: *gpu.ComputePassEncoder) void {
        procs.computePassEncoderEnd.?(@as(c.WGPUComputePassEncoder, @ptrCast(compute_pass_encoder)));
    }

    pub inline fn computePassEncoderInsertDebugMarker(compute_pass_encoder: *gpu.ComputePassEncoder, marker_label: [*:0]const u8) void {
        procs.computePassEncoderInsertDebugMarker.?(
            @as(c.WGPUComputePassEncoder, @ptrCast(compute_pass_encoder)),
            marker_label,
        );
    }

    pub inline fn computePassEncoderPopDebugGroup(compute_pass_encoder: *gpu.ComputePassEncoder) void {
        procs.computePassEncoderPopDebugGroup.?(@as(c.WGPUComputePassEncoder, @ptrCast(compute_pass_encoder)));
    }

    pub inline fn computePassEncoderPushDebugGroup(compute_pass_encoder: *gpu.ComputePassEncoder, group_label: [*:0]const u8) void {
        procs.computePassEncoderPushDebugGroup.?(
            @as(c.WGPUComputePassEncoder, @ptrCast(compute_pass_encoder)),
            group_label,
        );
    }

    pub inline fn computePassEncoderSetBindGroup(compute_pass_encoder: *gpu.ComputePassEncoder, group_index: u32, group: *gpu.BindGroup, dynamic_offset_count: usize, dynamic_offsets: ?[*]const u32) void {
        procs.computePassEncoderSetBindGroup.?(
            @as(c.WGPUComputePassEncoder, @ptrCast(compute_pass_encoder)),
            group_index,
            @as(c.WGPUBindGroup, @ptrCast(group)),
            dynamic_offset_count,
            dynamic_offsets,
        );
    }

    pub inline fn computePassEncoderSetLabel(compute_pass_encoder: *gpu.ComputePassEncoder, label: [*:0]const u8) void {
        procs.computePassEncoderSetLabel.?(@as(c.WGPUComputePassEncoder, @ptrCast(compute_pass_encoder)), label);
    }

    pub inline fn computePassEncoderSetPipeline(compute_pass_encoder: *gpu.ComputePassEncoder, pipeline: *gpu.ComputePipeline) void {
        procs.computePassEncoderSetPipeline.?(
            @as(c.WGPUComputePassEncoder, @ptrCast(compute_pass_encoder)),
            @as(c.WGPUComputePipeline, @ptrCast(pipeline)),
        );
    }

    pub inline fn computePassEncoderWriteTimestamp(compute_pass_encoder: *gpu.ComputePassEncoder, query_set: *gpu.QuerySet, query_index: u32) void {
        procs.computePassEncoderWriteTimestamp.?(
            @as(c.WGPUComputePassEncoder, @ptrCast(compute_pass_encoder)),
            @as(c.WGPUQuerySet, @ptrCast(query_set)),
            query_index,
        );
    }

    pub inline fn computePassEncoderReference(compute_pass_encoder: *gpu.ComputePassEncoder) void {
        procs.computePassEncoderReference.?(@as(c.WGPUComputePassEncoder, @ptrCast(compute_pass_encoder)));
    }

    pub inline fn computePassEncoderRelease(compute_pass_encoder: *gpu.ComputePassEncoder) void {
        procs.computePassEncoderRelease.?(@as(c.WGPUComputePassEncoder, @ptrCast(compute_pass_encoder)));
    }

    pub inline fn computePipelineGetBindGroupLayout(compute_pipeline: *gpu.ComputePipeline, group_index: u32) *gpu.BindGroupLayout {
        return @as(*gpu.BindGroupLayout, @ptrCast(procs.computePipelineGetBindGroupLayout.?(
            @as(c.WGPUComputePipeline, @ptrCast(compute_pipeline)),
            group_index,
        )));
    }

    pub inline fn computePipelineSetLabel(compute_pipeline: *gpu.ComputePipeline, label: [*:0]const u8) void {
        procs.computePipelineSetLabel.?(@as(c.WGPUComputePipeline, @ptrCast(compute_pipeline)), label);
    }

    pub inline fn computePipelineReference(compute_pipeline: *gpu.ComputePipeline) void {
        procs.computePipelineReference.?(@as(c.WGPUComputePipeline, @ptrCast(compute_pipeline)));
    }

    pub inline fn computePipelineRelease(compute_pipeline: *gpu.ComputePipeline) void {
        procs.computePipelineRelease.?(@as(c.WGPUComputePipeline, @ptrCast(compute_pipeline)));
    }

    pub inline fn deviceCreateBindGroup(device: *gpu.Device, descriptor: *const gpu.BindGroup.Descriptor) *gpu.BindGroup {
        return @as(*gpu.BindGroup, @ptrCast(procs.deviceCreateBindGroup.?(
            @as(c.WGPUDevice, @ptrCast(device)),
            @as(*const c.WGPUBindGroupDescriptor, @ptrCast(descriptor)),
        )));
    }

    pub inline fn deviceCreateBindGroupLayout(device: *gpu.Device, descriptor: *const gpu.BindGroupLayout.Descriptor) *gpu.BindGroupLayout {
        return @as(*gpu.BindGroupLayout, @ptrCast(procs.deviceCreateBindGroupLayout.?(
            @as(c.WGPUDevice, @ptrCast(device)),
            @as(*const c.WGPUBindGroupLayoutDescriptor, @ptrCast(descriptor)),
        )));
    }

    pub inline fn deviceCreateBuffer(device: *gpu.Device, descriptor: *const gpu.Buffer.Descriptor) *gpu.Buffer {
        return @as(*gpu.Buffer, @ptrCast(procs.deviceCreateBuffer.?(
            @as(c.WGPUDevice, @ptrCast(device)),
            @as(*const c.WGPUBufferDescriptor, @ptrCast(descriptor)),
        )));
    }

    pub inline fn deviceCreateCommandEncoder(device: *gpu.Device, descriptor: ?*const gpu.CommandEncoder.Descriptor) *gpu.CommandEncoder {
        return @as(*gpu.CommandEncoder, @ptrCast(procs.deviceCreateCommandEncoder.?(
            @as(c.WGPUDevice, @ptrCast(device)),
            @as(?*const c.WGPUCommandEncoderDescriptor, @ptrCast(descriptor)),
        )));
    }

    pub inline fn deviceCreateComputePipeline(device: *gpu.Device, descriptor: *const gpu.ComputePipeline.Descriptor) *gpu.ComputePipeline {
        return @as(*gpu.ComputePipeline, @ptrCast(procs.deviceCreateComputePipeline.?(
            @as(c.WGPUDevice, @ptrCast(device)),
            @as(*const c.WGPUComputePipelineDescriptor, @ptrCast(descriptor)),
        )));
    }

    pub inline fn deviceCreateComputePipelineAsync(device: *gpu.Device, descriptor: *const gpu.ComputePipeline.Descriptor, callback: gpu.CreateComputePipelineAsyncCallback, userdata: ?*anyopaque) void {
        procs.deviceCreateComputePipelineAsync.?(
            @as(c.WGPUDevice, @ptrCast(device)),
            @as(*const c.WGPUComputePipelineDescriptor, @ptrCast(descriptor)),
            @as(c.WGPUCreateComputePipelineAsyncCallback, @ptrCast(callback)),
            userdata,
        );
    }

    pub inline fn deviceCreateErrorBuffer(device: *gpu.Device, descriptor: *const gpu.Buffer.Descriptor) *gpu.Buffer {
        return @as(*gpu.Buffer, @ptrCast(procs.deviceCreateErrorBuffer.?(
            @as(c.WGPUDevice, @ptrCast(device)),
            @as(*const c.WGPUBufferDescriptor, @ptrCast(descriptor)),
        )));
    }

    pub inline fn deviceCreateErrorExternalTexture(device: *gpu.Device) *gpu.ExternalTexture {
        return @as(*gpu.ExternalTexture, @ptrCast(procs.deviceCreateErrorExternalTexture.?(@as(c.WGPUDevice, @ptrCast(device)))));
    }

    pub inline fn deviceCreateErrorTexture(device: *gpu.Device, descriptor: *const gpu.Texture.Descriptor) *gpu.Texture {
        return @as(*gpu.Texture, @ptrCast(procs.deviceCreateErrorTexture.?(
            @as(c.WGPUDevice, @ptrCast(device)),
            @as(*const c.WGPUTextureDescriptor, @ptrCast(descriptor)),
        )));
    }

    pub inline fn deviceCreateExternalTexture(device: *gpu.Device, external_texture_descriptor: *const gpu.ExternalTexture.Descriptor) *gpu.ExternalTexture {
        return @as(*gpu.ExternalTexture, @ptrCast(procs.deviceCreateExternalTexture.?(
            @as(c.WGPUDevice, @ptrCast(device)),
            @as(*const c.WGPUExternalTextureDescriptor, @ptrCast(external_texture_descriptor)),
        )));
    }

    pub inline fn deviceCreatePipelineLayout(device: *gpu.Device, pipeline_layout_descriptor: *const gpu.PipelineLayout.Descriptor) *gpu.PipelineLayout {
        return @as(*gpu.PipelineLayout, @ptrCast(procs.deviceCreatePipelineLayout.?(
            @as(c.WGPUDevice, @ptrCast(device)),
            @as(*const c.WGPUPipelineLayoutDescriptor, @ptrCast(pipeline_layout_descriptor)),
        )));
    }

    pub inline fn deviceCreateQuerySet(device: *gpu.Device, descriptor: *const gpu.QuerySet.Descriptor) *gpu.QuerySet {
        return @as(*gpu.QuerySet, @ptrCast(procs.deviceCreateQuerySet.?(
            @as(c.WGPUDevice, @ptrCast(device)),
            @as(*const c.WGPUQuerySetDescriptor, @ptrCast(descriptor)),
        )));
    }

    pub inline fn deviceCreateRenderBundleEncoder(device: *gpu.Device, descriptor: *const gpu.RenderBundleEncoder.Descriptor) *gpu.RenderBundleEncoder {
        return @as(*gpu.RenderBundleEncoder, @ptrCast(procs.deviceCreateRenderBundleEncoder.?(
            @as(c.WGPUDevice, @ptrCast(device)),
            @as(*const c.WGPURenderBundleEncoderDescriptor, @ptrCast(descriptor)),
        )));
    }

    pub inline fn deviceCreateRenderPipeline(device: *gpu.Device, descriptor: *const gpu.RenderPipeline.Descriptor) *gpu.RenderPipeline {
        return @as(*gpu.RenderPipeline, @ptrCast(procs.deviceCreateRenderPipeline.?(
            @as(c.WGPUDevice, @ptrCast(device)),
            @as(*const c.WGPURenderPipelineDescriptor, @ptrCast(descriptor)),
        )));
    }

    pub inline fn deviceCreateRenderPipelineAsync(device: *gpu.Device, descriptor: *const gpu.RenderPipeline.Descriptor, callback: gpu.CreateRenderPipelineAsyncCallback, userdata: ?*anyopaque) void {
        procs.deviceCreateRenderPipelineAsync.?(
            @as(c.WGPUDevice, @ptrCast(device)),
            @as(*const c.WGPURenderPipelineDescriptor, @ptrCast(descriptor)),
            @as(c.WGPUCreateRenderPipelineAsyncCallback, @ptrCast(callback)),
            userdata,
        );
    }

    // TODO(self-hosted): this cannot be marked as inline for some reason.
    // https://github.com/ziglang/zig/issues/12545
    pub fn deviceCreateSampler(device: *gpu.Device, descriptor: ?*const gpu.Sampler.Descriptor) *gpu.Sampler {
        return @as(*gpu.Sampler, @ptrCast(procs.deviceCreateSampler.?(
            @as(c.WGPUDevice, @ptrCast(device)),
            @as(?*const c.WGPUSamplerDescriptor, @ptrCast(descriptor)),
        )));
    }

    pub inline fn deviceCreateShaderModule(device: *gpu.Device, descriptor: *const gpu.ShaderModule.Descriptor) *gpu.ShaderModule {
        return @as(*gpu.ShaderModule, @ptrCast(procs.deviceCreateShaderModule.?(
            @as(c.WGPUDevice, @ptrCast(device)),
            @as(*const c.WGPUShaderModuleDescriptor, @ptrCast(descriptor)),
        )));
    }

    pub inline fn deviceCreateSwapChain(device: *gpu.Device, surface: ?*gpu.Surface, descriptor: *const gpu.SwapChain.Descriptor) *gpu.SwapChain {
        return @as(*gpu.SwapChain, @ptrCast(procs.deviceCreateSwapChain.?(
            @as(c.WGPUDevice, @ptrCast(device)),
            @as(c.WGPUSurface, @ptrCast(surface)),
            @as(*const c.WGPUSwapChainDescriptor, @ptrCast(descriptor)),
        )));
    }

    pub inline fn deviceCreateTexture(device: *gpu.Device, descriptor: *const gpu.Texture.Descriptor) *gpu.Texture {
        return @as(*gpu.Texture, @ptrCast(procs.deviceCreateTexture.?(
            @as(c.WGPUDevice, @ptrCast(device)),
            @as(*const c.WGPUTextureDescriptor, @ptrCast(descriptor)),
        )));
    }

    pub inline fn deviceDestroy(device: *gpu.Device) void {
        procs.deviceDestroy.?(@as(c.WGPUDevice, @ptrCast(device)));
    }

    pub inline fn deviceEnumerateFeatures(device: *gpu.Device, features: ?[*]gpu.FeatureName) usize {
        return procs.deviceEnumerateFeatures.?(
            @as(c.WGPUDevice, @ptrCast(device)),
            @as(?[*]c.WGPUFeatureName, @ptrCast(features)),
        );
    }

    pub inline fn forceLoss(device: *gpu.Device, reason: gpu.Device.LostReason, message: [*:0]const u8) void {
        return procs.deviceForceLoss.?(
            @as(c.WGPUDevice, @ptrCast(device)),
            reason,
            message,
        );
    }

    pub inline fn deviceGetAdapter(device: *gpu.Device) *gpu.Adapter {
        return procs.deviceGetAdapter.?(@as(c.WGPUDevice, @ptrCast(device)));
    }

    pub inline fn deviceGetLimits(device: *gpu.Device, limits: *gpu.SupportedLimits) bool {
        return procs.deviceGetLimits.?(
            @as(c.WGPUDevice, @ptrCast(device)),
            @as(*c.WGPUSupportedLimits, @ptrCast(limits)),
        );
    }

    pub inline fn deviceGetQueue(device: *gpu.Device) *gpu.Queue {
        return @as(*gpu.Queue, @ptrCast(procs.deviceGetQueue.?(@as(c.WGPUDevice, @ptrCast(device)))));
    }

    pub inline fn deviceHasFeature(device: *gpu.Device, feature: gpu.FeatureName) bool {
        return procs.deviceHasFeature.?(
            @as(c.WGPUDevice, @ptrCast(device)),
            @intFromEnum(feature),
        );
    }

    pub inline fn deviceInjectError(device: *gpu.Device, typ: gpu.ErrorType, message: [*:0]const u8) void {
        procs.deviceInjectError.?(
            @as(c.WGPUDevice, @ptrCast(device)),
            @intFromEnum(typ),
            message,
        );
    }

    pub inline fn devicePopErrorScope(device: *gpu.Device, callback: gpu.ErrorCallback, userdata: ?*anyopaque) void {
        procs.devicePopErrorScope.?(
            @as(c.WGPUDevice, @ptrCast(device)),
            @as(c.WGPUErrorCallback, @ptrCast(callback)),
            userdata,
        );
    }

    pub inline fn devicePushErrorScope(device: *gpu.Device, filter: gpu.ErrorFilter) void {
        procs.devicePushErrorScope.?(
            @as(c.WGPUDevice, @ptrCast(device)),
            @intFromEnum(filter),
        );
    }

    pub inline fn deviceSetDeviceLostCallback(device: *gpu.Device, callback: ?gpu.Device.LostCallback, userdata: ?*anyopaque) void {
        procs.deviceSetDeviceLostCallback.?(
            @as(c.WGPUDevice, @ptrCast(device)),
            @as(c.WGPUDeviceLostCallback, @ptrCast(callback)),
            userdata,
        );
    }

    pub inline fn deviceSetLabel(device: *gpu.Device, label: [*:0]const u8) void {
        procs.deviceSetLabel.?(@as(c.WGPUDevice, @ptrCast(device)), label);
    }

    pub inline fn deviceSetLoggingCallback(device: *gpu.Device, callback: ?gpu.LoggingCallback, userdata: ?*anyopaque) void {
        procs.deviceSetLoggingCallback.?(
            @as(c.WGPUDevice, @ptrCast(device)),
            @as(c.WGPULoggingCallback, @ptrCast(callback)),
            userdata,
        );
    }

    pub inline fn deviceSetUncapturedErrorCallback(device: *gpu.Device, callback: ?gpu.ErrorCallback, userdata: ?*anyopaque) void {
        procs.deviceSetUncapturedErrorCallback.?(
            @as(c.WGPUDevice, @ptrCast(device)),
            @as(c.WGPUErrorCallback, @ptrCast(callback)),
            userdata,
        );
    }

    pub inline fn deviceTick(device: *gpu.Device) void {
        procs.deviceTick.?(@as(c.WGPUDevice, @ptrCast(device)));
    }

    pub inline fn deviceValidateTextureDescriptor(device: *gpu.Device, descriptor: *const gpu.Texture.Descriptor) void {
        procs.deviceValidateTextureDescriptor(device, descriptor);
    }

    pub inline fn deviceReference(device: *gpu.Device) void {
        procs.deviceReference.?(@as(c.WGPUDevice, @ptrCast(device)));
    }

    pub inline fn deviceRelease(device: *gpu.Device) void {
        procs.deviceRelease.?(@as(c.WGPUDevice, @ptrCast(device)));
    }

    pub inline fn externalTextureDestroy(external_texture: *gpu.ExternalTexture) void {
        procs.externalTextureDestroy.?(@as(c.WGPUExternalTexture, @ptrCast(external_texture)));
    }

    pub inline fn externalTextureSetLabel(external_texture: *gpu.ExternalTexture, label: [*:0]const u8) void {
        procs.externalTextureSetLabel.?(@as(c.WGPUExternalTexture, @ptrCast(external_texture)), label);
    }

    pub inline fn externalTextureReference(external_texture: *gpu.ExternalTexture) void {
        procs.externalTextureReference.?(@as(c.WGPUExternalTexture, @ptrCast(external_texture)));
    }

    pub inline fn externalTextureRelease(external_texture: *gpu.ExternalTexture) void {
        procs.externalTextureRelease.?(@as(c.WGPUExternalTexture, @ptrCast(external_texture)));
    }

    pub inline fn instanceCreateSurface(instance: *gpu.Instance, descriptor: *const gpu.Surface.Descriptor) *gpu.Surface {
        return @as(*gpu.Surface, @ptrCast(procs.instanceCreateSurface.?(
            @as(c.WGPUInstance, @ptrCast(instance)),
            @as(*const c.WGPUSurfaceDescriptor, @ptrCast(descriptor)),
        )));
    }

    pub inline fn instanceProcessEvents(instance: *gpu.Instance) void {
        procs.instanceProcessEvents.?(
            @as(c.WGPUInstance, @ptrCast(instance)),
        );
    }

    pub inline fn instanceRequestAdapter(instance: *gpu.Instance, options: ?*const gpu.RequestAdapterOptions, callback: gpu.RequestAdapterCallback, userdata: ?*anyopaque) void {
        procs.instanceRequestAdapter.?(
            @as(c.WGPUInstance, @ptrCast(instance)),
            @as(?*const c.WGPURequestAdapterOptions, @ptrCast(options)),
            @as(c.WGPURequestAdapterCallback, @ptrCast(callback)),
            userdata,
        );
    }

    pub inline fn instanceReference(instance: *gpu.Instance) void {
        procs.instanceReference.?(@as(c.WGPUInstance, @ptrCast(instance)));
    }

    pub inline fn instanceRelease(instance: *gpu.Instance) void {
        procs.instanceRelease.?(@as(c.WGPUInstance, @ptrCast(instance)));
    }

    pub inline fn pipelineLayoutSetLabel(pipeline_layout: *gpu.PipelineLayout, label: [*:0]const u8) void {
        procs.pipelineLayoutSetLabel.?(@as(c.WGPUPipelineLayout, @ptrCast(pipeline_layout)), label);
    }

    pub inline fn pipelineLayoutReference(pipeline_layout: *gpu.PipelineLayout) void {
        procs.pipelineLayoutReference.?(@as(c.WGPUPipelineLayout, @ptrCast(pipeline_layout)));
    }

    pub inline fn pipelineLayoutRelease(pipeline_layout: *gpu.PipelineLayout) void {
        procs.pipelineLayoutRelease.?(@as(c.WGPUPipelineLayout, @ptrCast(pipeline_layout)));
    }

    pub inline fn querySetDestroy(query_set: *gpu.QuerySet) void {
        procs.querySetDestroy.?(@as(c.WGPUQuerySet, @ptrCast(query_set)));
    }

    pub inline fn querySetGetCount(query_set: *gpu.QuerySet) u32 {
        return procs.querySetGetCount.?(@as(c.WGPUQuerySet, @ptrCast(query_set)));
    }

    pub inline fn querySetGetType(query_set: *gpu.QuerySet) gpu.QueryType {
        return @as(gpu.QueryType, @enumFromInt(procs.querySetGetType.?(@as(c.WGPUQuerySet, @ptrCast(query_set)))));
    }

    pub inline fn querySetSetLabel(query_set: *gpu.QuerySet, label: [*:0]const u8) void {
        procs.querySetSetLabel.?(@as(c.WGPUQuerySet, @ptrCast(query_set)), label);
    }

    pub inline fn querySetReference(query_set: *gpu.QuerySet) void {
        procs.querySetReference.?(@as(c.WGPUQuerySet, @ptrCast(query_set)));
    }

    pub inline fn querySetRelease(query_set: *gpu.QuerySet) void {
        procs.querySetRelease.?(@as(c.WGPUQuerySet, @ptrCast(query_set)));
    }

    pub inline fn queueCopyExternalTextureForBrowser(queue: *gpu.Queue, source: *const gpu.ImageCopyExternalTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D, options: *const gpu.CopyTextureForBrowserOptions) void {
        procs.queueCopyExternalTextureForBrowser.?(
            @as(c.WGPUQueue, @ptrCast(queue)),
            @as(*const c.ImageCopyExternalTexture, @ptrCast(source)),
            @as(*const c.WGPUImageCopyTexture, @ptrCast(destination)),
            @as(*const c.WGPUExtent3D, @ptrCast(copy_size)),
            @as(*const c.WGPUCopyTextureForBrowserOptions, @ptrCast(options)),
        );
    }

    pub inline fn queueCopyTextureForBrowser(queue: *gpu.Queue, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D, options: *const gpu.CopyTextureForBrowserOptions) void {
        procs.queueCopyTextureForBrowser.?(
            @as(c.WGPUQueue, @ptrCast(queue)),
            @as(*const c.WGPUImageCopyTexture, @ptrCast(source)),
            @as(*const c.WGPUImageCopyTexture, @ptrCast(destination)),
            @as(*const c.WGPUExtent3D, @ptrCast(copy_size)),
            @as(*const c.WGPUCopyTextureForBrowserOptions, @ptrCast(options)),
        );
    }

    pub inline fn queueOnSubmittedWorkDone(queue: *gpu.Queue, signal_value: u64, callback: gpu.Queue.WorkDoneCallback, userdata: ?*anyopaque) void {
        procs.queueOnSubmittedWorkDone.?(
            @as(c.WGPUQueue, @ptrCast(queue)),
            signal_value,
            @as(c.WGPUQueueWorkDoneCallback, @ptrCast(callback)),
            userdata,
        );
    }

    pub inline fn queueSetLabel(queue: *gpu.Queue, label: [*:0]const u8) void {
        procs.queueSetLabel.?(@as(c.WGPUQueue, @ptrCast(queue)), label);
    }

    pub inline fn queueSubmit(queue: *gpu.Queue, command_count: usize, commands: [*]const *const gpu.CommandBuffer) void {
        procs.queueSubmit.?(
            @as(c.WGPUQueue, @ptrCast(queue)),
            command_count,
            @as([*]const c.WGPUCommandBuffer, @ptrCast(commands)),
        );
    }

    pub inline fn queueWriteBuffer(queue: *gpu.Queue, buffer: *gpu.Buffer, buffer_offset: u64, data: *const anyopaque, size: usize) void {
        procs.queueWriteBuffer.?(
            @as(c.WGPUQueue, @ptrCast(queue)),
            @as(c.WGPUBuffer, @ptrCast(buffer)),
            buffer_offset,
            data,
            size,
        );
    }

    pub inline fn queueWriteTexture(queue: *gpu.Queue, destination: *const gpu.ImageCopyTexture, data: *const anyopaque, data_size: usize, data_layout: *const gpu.Texture.DataLayout, write_size: *const gpu.Extent3D) void {
        procs.queueWriteTexture.?(
            @as(c.WGPUQueue, @ptrCast(queue)),
            @as(*const c.WGPUImageCopyTexture, @ptrCast(destination)),
            data,
            data_size,
            @as(*const c.WGPUTextureDataLayout, @ptrCast(data_layout)),
            @as(*const c.WGPUExtent3D, @ptrCast(write_size)),
        );
    }

    pub inline fn queueReference(queue: *gpu.Queue) void {
        procs.queueReference.?(@as(c.WGPUQueue, @ptrCast(queue)));
    }

    pub inline fn queueRelease(queue: *gpu.Queue) void {
        procs.queueRelease.?(@as(c.WGPUQueue, @ptrCast(queue)));
    }

    pub inline fn renderBundleSetLabel(render_bundle: *gpu.RenderBundle, label: [*:0]const u8) void {
        procs.renderBundleSetLabel.?(@as(c.WGPURenderBundle, @ptrCast(render_bundle)), label);
    }

    pub inline fn renderBundleReference(render_bundle: *gpu.RenderBundle) void {
        procs.renderBundleReference.?(@as(c.WGPURenderBundle, @ptrCast(render_bundle)));
    }

    pub inline fn renderBundleRelease(render_bundle: *gpu.RenderBundle) void {
        procs.renderBundleRelease.?(@as(c.WGPURenderBundle, @ptrCast(render_bundle)));
    }

    pub inline fn renderBundleEncoderDraw(render_bundle_encoder: *gpu.RenderBundleEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {
        procs.renderBundleEncoderDraw.?(@as(c.WGPURenderBundleEncoder, @ptrCast(render_bundle_encoder)), vertex_count, instance_count, first_vertex, first_instance);
    }

    pub inline fn renderBundleEncoderDrawIndexed(render_bundle_encoder: *gpu.RenderBundleEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: i32, first_instance: u32) void {
        procs.renderBundleEncoderDrawIndexed.?(
            @as(c.WGPURenderBundleEncoder, @ptrCast(render_bundle_encoder)),
            index_count,
            instance_count,
            first_index,
            base_vertex,
            first_instance,
        );
    }

    pub inline fn renderBundleEncoderDrawIndexedIndirect(render_bundle_encoder: *gpu.RenderBundleEncoder, indirect_buffer: *gpu.Buffer, indirect_offset: u64) void {
        procs.renderBundleEncoderDrawIndexedIndirect.?(
            @as(c.WGPURenderBundleEncoder, @ptrCast(render_bundle_encoder)),
            @as(c.WGPUBuffer, @ptrCast(indirect_buffer)),
            indirect_offset,
        );
    }

    pub inline fn renderBundleEncoderDrawIndirect(render_bundle_encoder: *gpu.RenderBundleEncoder, indirect_buffer: *gpu.Buffer, indirect_offset: u64) void {
        procs.renderBundleEncoderDrawIndirect.?(
            @as(c.WGPURenderBundleEncoder, @ptrCast(render_bundle_encoder)),
            @as(c.WGPUBuffer, @ptrCast(indirect_buffer)),
            indirect_offset,
        );
    }

    pub inline fn renderBundleEncoderFinish(render_bundle_encoder: *gpu.RenderBundleEncoder, descriptor: ?*const gpu.RenderBundle.Descriptor) *gpu.RenderBundle {
        return @as(*gpu.RenderBundle, @ptrCast(procs.renderBundleEncoderFinish.?(
            @as(c.WGPURenderBundleEncoder, @ptrCast(render_bundle_encoder)),
            @as(?*const c.WGPURenderBundleDescriptor, @ptrCast(descriptor)),
        )));
    }

    pub inline fn renderBundleEncoderInsertDebugMarker(render_bundle_encoder: *gpu.RenderBundleEncoder, marker_label: [*:0]const u8) void {
        procs.renderBundleEncoderInsertDebugMarker.?(
            @as(c.WGPURenderBundleEncoder, @ptrCast(render_bundle_encoder)),
            marker_label,
        );
    }

    pub inline fn renderBundleEncoderPopDebugGroup(render_bundle_encoder: *gpu.RenderBundleEncoder) void {
        procs.renderBundleEncoderPopDebugGroup.?(@as(c.WGPURenderBundleEncoder, @ptrCast(render_bundle_encoder)));
    }

    pub inline fn renderBundleEncoderPushDebugGroup(render_bundle_encoder: *gpu.RenderBundleEncoder, group_label: [*:0]const u8) void {
        procs.renderBundleEncoderPushDebugGroup.?(@as(c.WGPURenderBundleEncoder, @ptrCast(render_bundle_encoder)), group_label);
    }

    pub inline fn renderBundleEncoderSetBindGroup(render_bundle_encoder: *gpu.RenderBundleEncoder, group_index: u32, group: *gpu.BindGroup, dynamic_offset_count: usize, dynamic_offsets: ?[*]const u32) void {
        procs.renderBundleEncoderSetBindGroup.?(
            @as(c.WGPURenderBundleEncoder, @ptrCast(render_bundle_encoder)),
            group_index,
            @as(c.WGPUBindGroup, @ptrCast(group)),
            dynamic_offset_count,
            dynamic_offsets,
        );
    }

    pub inline fn renderBundleEncoderSetIndexBuffer(render_bundle_encoder: *gpu.RenderBundleEncoder, buffer: *gpu.Buffer, format: gpu.IndexFormat, offset: u64, size: u64) void {
        procs.renderBundleEncoderSetIndexBuffer.?(
            @as(c.WGPURenderBundleEncoder, @ptrCast(render_bundle_encoder)),
            @as(c.WGPUBuffer, @ptrCast(buffer)),
            @intFromEnum(format),
            offset,
            size,
        );
    }

    pub inline fn renderBundleEncoderSetLabel(render_bundle_encoder: *gpu.RenderBundleEncoder, label: [*:0]const u8) void {
        procs.renderBundleEncoderSetLabel.?(@as(c.WGPURenderBundleEncoder, @ptrCast(render_bundle_encoder)), label);
    }

    pub inline fn renderBundleEncoderSetPipeline(render_bundle_encoder: *gpu.RenderBundleEncoder, pipeline: *gpu.RenderPipeline) void {
        procs.renderBundleEncoderSetPipeline.?(
            @as(c.WGPURenderBundleEncoder, @ptrCast(render_bundle_encoder)),
            @as(c.WGPURenderPipeline, @ptrCast(pipeline)),
        );
    }

    pub inline fn renderBundleEncoderSetVertexBuffer(render_bundle_encoder: *gpu.RenderBundleEncoder, slot: u32, buffer: *gpu.Buffer, offset: u64, size: u64) void {
        procs.renderBundleEncoderSetVertexBuffer.?(
            @as(c.WGPURenderBundleEncoder, @ptrCast(render_bundle_encoder)),
            slot,
            @as(c.WGPUBuffer, @ptrCast(buffer)),
            offset,
            size,
        );
    }

    pub inline fn renderBundleEncoderReference(render_bundle_encoder: *gpu.RenderBundleEncoder) void {
        procs.renderBundleEncoderReference.?(@as(c.WGPURenderBundleEncoder, @ptrCast(render_bundle_encoder)));
    }

    pub inline fn renderBundleEncoderRelease(render_bundle_encoder: *gpu.RenderBundleEncoder) void {
        procs.renderBundleEncoderRelease.?(@as(c.WGPURenderBundleEncoder, @ptrCast(render_bundle_encoder)));
    }

    pub inline fn renderPassEncoderBeginOcclusionQuery(render_pass_encoder: *gpu.RenderPassEncoder, query_index: u32) void {
        procs.renderPassEncoderBeginOcclusionQuery.?(
            @as(c.WGPURenderPassEncoder, @ptrCast(render_pass_encoder)),
            query_index,
        );
    }

    pub inline fn renderPassEncoderDraw(render_pass_encoder: *gpu.RenderPassEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {
        procs.renderPassEncoderDraw.?(
            @as(c.WGPURenderPassEncoder, @ptrCast(render_pass_encoder)),
            vertex_count,
            instance_count,
            first_vertex,
            first_instance,
        );
    }

    pub inline fn renderPassEncoderDrawIndexed(render_pass_encoder: *gpu.RenderPassEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: i32, first_instance: u32) void {
        procs.renderPassEncoderDrawIndexed.?(
            @as(c.WGPURenderPassEncoder, @ptrCast(render_pass_encoder)),
            index_count,
            instance_count,
            first_index,
            base_vertex,
            first_instance,
        );
    }

    pub inline fn renderPassEncoderDrawIndexedIndirect(render_pass_encoder: *gpu.RenderPassEncoder, indirect_buffer: *gpu.Buffer, indirect_offset: u64) void {
        procs.renderPassEncoderDrawIndexedIndirect.?(
            @as(c.WGPURenderPassEncoder, @ptrCast(render_pass_encoder)),
            @as(c.WGPUBuffer, @ptrCast(indirect_buffer)),
            indirect_offset,
        );
    }

    pub inline fn renderPassEncoderDrawIndirect(render_pass_encoder: *gpu.RenderPassEncoder, indirect_buffer: *gpu.Buffer, indirect_offset: u64) void {
        procs.renderPassEncoderDrawIndirect.?(
            @as(c.WGPURenderPassEncoder, @ptrCast(render_pass_encoder)),
            @as(c.WGPUBuffer, @ptrCast(indirect_buffer)),
            indirect_offset,
        );
    }

    pub inline fn renderPassEncoderEnd(render_pass_encoder: *gpu.RenderPassEncoder) void {
        procs.renderPassEncoderEnd.?(@as(c.WGPURenderPassEncoder, @ptrCast(render_pass_encoder)));
    }

    pub inline fn renderPassEncoderEndOcclusionQuery(render_pass_encoder: *gpu.RenderPassEncoder) void {
        procs.renderPassEncoderEndOcclusionQuery.?(@as(c.WGPURenderPassEncoder, @ptrCast(render_pass_encoder)));
    }

    pub inline fn renderPassEncoderExecuteBundles(render_pass_encoder: *gpu.RenderPassEncoder, bundles_count: usize, bundles: [*]const *const gpu.RenderBundle) void {
        procs.renderPassEncoderExecuteBundles.?(
            @as(c.WGPURenderPassEncoder, @ptrCast(render_pass_encoder)),
            bundles_count,
            @as([*]const c.WGPURenderBundle, @ptrCast(bundles)),
        );
    }

    pub inline fn renderPassEncoderInsertDebugMarker(render_pass_encoder: *gpu.RenderPassEncoder, marker_label: [*:0]const u8) void {
        procs.renderPassEncoderInsertDebugMarker.?(@as(c.WGPURenderPassEncoder, @ptrCast(render_pass_encoder)), marker_label);
    }

    pub inline fn renderPassEncoderPopDebugGroup(render_pass_encoder: *gpu.RenderPassEncoder) void {
        procs.renderPassEncoderPopDebugGroup.?(@as(c.WGPURenderPassEncoder, @ptrCast(render_pass_encoder)));
    }

    pub inline fn renderPassEncoderPushDebugGroup(render_pass_encoder: *gpu.RenderPassEncoder, group_label: [*:0]const u8) void {
        procs.renderPassEncoderPushDebugGroup.?(
            @as(c.WGPURenderPassEncoder, @ptrCast(render_pass_encoder)),
            group_label,
        );
    }

    pub inline fn renderPassEncoderSetBindGroup(render_pass_encoder: *gpu.RenderPassEncoder, group_index: u32, group: *gpu.BindGroup, dynamic_offset_count: usize, dynamic_offsets: ?[*]const u32) void {
        procs.renderPassEncoderSetBindGroup.?(
            @as(c.WGPURenderPassEncoder, @ptrCast(render_pass_encoder)),
            group_index,
            @as(c.WGPUBindGroup, @ptrCast(group)),
            dynamic_offset_count,
            dynamic_offsets,
        );
    }

    pub inline fn renderPassEncoderSetBlendConstant(render_pass_encoder: *gpu.RenderPassEncoder, color: *const gpu.Color) void {
        procs.renderPassEncoderSetBlendConstant.?(
            @as(c.WGPURenderPassEncoder, @ptrCast(render_pass_encoder)),
            @as(*const c.WGPUColor, @ptrCast(color)),
        );
    }

    pub inline fn renderPassEncoderSetIndexBuffer(render_pass_encoder: *gpu.RenderPassEncoder, buffer: *gpu.Buffer, format: gpu.IndexFormat, offset: u64, size: u64) void {
        procs.renderPassEncoderSetIndexBuffer.?(
            @as(c.WGPURenderPassEncoder, @ptrCast(render_pass_encoder)),
            @as(c.WGPUBuffer, @ptrCast(buffer)),
            @intFromEnum(format),
            offset,
            size,
        );
    }

    pub inline fn renderPassEncoderSetLabel(render_pass_encoder: *gpu.RenderPassEncoder, label: [*:0]const u8) void {
        procs.renderPassEncoderSetLabel.?(@as(c.WGPURenderPassEncoder, @ptrCast(render_pass_encoder)), label);
    }

    pub inline fn renderPassEncoderSetPipeline(render_pass_encoder: *gpu.RenderPassEncoder, pipeline: *gpu.RenderPipeline) void {
        procs.renderPassEncoderSetPipeline.?(
            @as(c.WGPURenderPassEncoder, @ptrCast(render_pass_encoder)),
            @as(c.WGPURenderPipeline, @ptrCast(pipeline)),
        );
    }

    pub inline fn renderPassEncoderSetScissorRect(render_pass_encoder: *gpu.RenderPassEncoder, x: u32, y: u32, width: u32, height: u32) void {
        procs.renderPassEncoderSetScissorRect.?(
            @as(c.WGPURenderPassEncoder, @ptrCast(render_pass_encoder)),
            x,
            y,
            width,
            height,
        );
    }

    pub inline fn renderPassEncoderSetStencilReference(render_pass_encoder: *gpu.RenderPassEncoder, reference: u32) void {
        procs.renderPassEncoderSetStencilReference.?(
            @as(c.WGPURenderPassEncoder, @ptrCast(render_pass_encoder)),
            reference,
        );
    }

    pub inline fn renderPassEncoderSetVertexBuffer(render_pass_encoder: *gpu.RenderPassEncoder, slot: u32, buffer: *gpu.Buffer, offset: u64, size: u64) void {
        procs.renderPassEncoderSetVertexBuffer.?(
            @as(c.WGPURenderPassEncoder, @ptrCast(render_pass_encoder)),
            slot,
            @as(c.WGPUBuffer, @ptrCast(buffer)),
            offset,
            size,
        );
    }

    pub inline fn renderPassEncoderSetViewport(render_pass_encoder: *gpu.RenderPassEncoder, x: f32, y: f32, width: f32, height: f32, min_depth: f32, max_depth: f32) void {
        procs.renderPassEncoderSetViewport.?(
            @as(c.WGPURenderPassEncoder, @ptrCast(render_pass_encoder)),
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
            @as(c.WGPURenderPassEncoder, @ptrCast(render_pass_encoder)),
            @as(c.WGPUQuerySet, @ptrCast(query_set)),
            query_index,
        );
    }

    pub inline fn renderPassEncoderReference(render_pass_encoder: *gpu.RenderPassEncoder) void {
        procs.renderPassEncoderReference.?(@as(c.WGPURenderPassEncoder, @ptrCast(render_pass_encoder)));
    }

    pub inline fn renderPassEncoderRelease(render_pass_encoder: *gpu.RenderPassEncoder) void {
        procs.renderPassEncoderRelease.?(@as(c.WGPURenderPassEncoder, @ptrCast(render_pass_encoder)));
    }

    pub inline fn renderPipelineGetBindGroupLayout(render_pipeline: *gpu.RenderPipeline, group_index: u32) *gpu.BindGroupLayout {
        return @as(*gpu.BindGroupLayout, @ptrCast(procs.renderPipelineGetBindGroupLayout.?(
            @as(c.WGPURenderPipeline, @ptrCast(render_pipeline)),
            group_index,
        )));
    }

    pub inline fn renderPipelineSetLabel(render_pipeline: *gpu.RenderPipeline, label: [*:0]const u8) void {
        procs.renderPipelineSetLabel.?(@as(c.WGPURenderPipeline, @ptrCast(render_pipeline)), label);
    }

    pub inline fn renderPipelineReference(render_pipeline: *gpu.RenderPipeline) void {
        procs.renderPipelineReference.?(@as(c.WGPURenderPipeline, @ptrCast(render_pipeline)));
    }

    pub inline fn renderPipelineRelease(render_pipeline: *gpu.RenderPipeline) void {
        procs.renderPipelineRelease.?(@as(c.WGPURenderPipeline, @ptrCast(render_pipeline)));
    }

    pub inline fn samplerSetLabel(sampler: *gpu.Sampler, label: [*:0]const u8) void {
        procs.samplerSetLabel.?(@as(c.WGPUSampler, @ptrCast(sampler)), label);
    }

    pub inline fn samplerReference(sampler: *gpu.Sampler) void {
        procs.samplerReference.?(@as(c.WGPUSampler, @ptrCast(sampler)));
    }

    pub inline fn samplerRelease(sampler: *gpu.Sampler) void {
        procs.samplerRelease.?(@as(c.WGPUSampler, @ptrCast(sampler)));
    }

    pub inline fn shaderModuleGetCompilationInfo(shader_module: *gpu.ShaderModule, callback: gpu.CompilationInfoCallback, userdata: ?*anyopaque) void {
        procs.shaderModuleGetCompilationInfo.?(
            @as(c.WGPUShaderModule, @ptrCast(shader_module)),
            @as(c.WGPUCompilationInfoCallback, @ptrCast(callback)),
            userdata,
        );
    }

    pub inline fn shaderModuleSetLabel(shader_module: *gpu.ShaderModule, label: [*:0]const u8) void {
        procs.shaderModuleSetLabel.?(@as(c.WGPUShaderModule, @ptrCast(shader_module)), label);
    }

    pub inline fn shaderModuleReference(shader_module: *gpu.ShaderModule) void {
        procs.shaderModuleReference.?(@as(c.WGPUShaderModule, @ptrCast(shader_module)));
    }

    pub inline fn shaderModuleRelease(shader_module: *gpu.ShaderModule) void {
        procs.shaderModuleRelease.?(@as(c.WGPUShaderModule, @ptrCast(shader_module)));
    }

    pub inline fn surfaceReference(surface: *gpu.Surface) void {
        procs.surfaceReference.?(@as(c.WGPUSurface, @ptrCast(surface)));
    }

    pub inline fn surfaceRelease(surface: *gpu.Surface) void {
        procs.surfaceRelease.?(@as(c.WGPUSurface, @ptrCast(surface)));
    }

    pub inline fn swapChainGetCurrentTexture(swap_chain: *gpu.SwapChain) ?*gpu.Texture {
        return @as(?*gpu.Texture, @ptrCast(procs.swapChainGetCurrentTexture.?(@as(c.WGPUSwapChain, @ptrCast(swap_chain)))));
    }

    pub inline fn swapChainGetCurrentTextureView(swap_chain: *gpu.SwapChain) ?*gpu.TextureView {
        return @as(?*gpu.TextureView, @ptrCast(procs.swapChainGetCurrentTextureView.?(@as(c.WGPUSwapChain, @ptrCast(swap_chain)))));
    }

    pub inline fn swapChainPresent(swap_chain: *gpu.SwapChain) void {
        procs.swapChainPresent.?(@as(c.WGPUSwapChain, @ptrCast(swap_chain)));
    }

    pub inline fn swapChainReference(swap_chain: *gpu.SwapChain) void {
        procs.swapChainReference.?(@as(c.WGPUSwapChain, @ptrCast(swap_chain)));
    }

    pub inline fn swapChainRelease(swap_chain: *gpu.SwapChain) void {
        procs.swapChainRelease.?(@as(c.WGPUSwapChain, @ptrCast(swap_chain)));
    }

    pub inline fn textureCreateView(texture: *gpu.Texture, descriptor: ?*const gpu.TextureView.Descriptor) *gpu.TextureView {
        return @as(*gpu.TextureView, @ptrCast(procs.textureCreateView.?(
            @as(c.WGPUTexture, @ptrCast(texture)),
            @as(?*const c.WGPUTextureViewDescriptor, @ptrCast(descriptor)),
        )));
    }

    pub inline fn textureDestroy(texture: *gpu.Texture) void {
        procs.textureDestroy.?(@as(c.WGPUTexture, @ptrCast(texture)));
    }

    pub inline fn textureGetDepthOrArrayLayers(texture: *gpu.Texture) u32 {
        return procs.textureGetDepthOrArrayLayers.?(@as(c.WGPUTexture, @ptrCast(texture)));
    }

    pub inline fn textureGetDimension(texture: *gpu.Texture) gpu.Texture.Dimension {
        return @as(gpu.Texture.Dimension, @enumFromInt(procs.textureGetDimension.?(@as(c.WGPUTexture, @ptrCast(texture)))));
    }

    pub inline fn textureGetFormat(texture: *gpu.Texture) gpu.Texture.Format {
        return @as(gpu.Texture.Format, @enumFromInt(procs.textureGetFormat.?(@as(c.WGPUTexture, @ptrCast(texture)))));
    }

    pub inline fn textureGetHeight(texture: *gpu.Texture) u32 {
        return procs.textureGetHeight.?(@as(c.WGPUTexture, @ptrCast(texture)));
    }

    pub inline fn textureGetMipLevelCount(texture: *gpu.Texture) u32 {
        return procs.textureGetMipLevelCount.?(@as(c.WGPUTexture, @ptrCast(texture)));
    }

    pub inline fn textureGetSampleCount(texture: *gpu.Texture) u32 {
        return procs.textureGetSampleCount.?(@as(c.WGPUTexture, @ptrCast(texture)));
    }

    pub inline fn textureGetUsage(texture: *gpu.Texture) gpu.Texture.UsageFlags {
        return @as(gpu.Texture.UsageFlags, @bitCast(procs.textureGetUsage.?(
            @as(c.WGPUTexture, @ptrCast(texture)),
        )));
    }

    pub inline fn textureGetWidth(texture: *gpu.Texture) u32 {
        return procs.textureGetWidth.?(@as(c.WGPUTexture, @ptrCast(texture)));
    }

    pub inline fn textureSetLabel(texture: *gpu.Texture, label: [*:0]const u8) void {
        procs.textureSetLabel.?(@as(c.WGPUTexture, @ptrCast(texture)), label);
    }

    pub inline fn textureReference(texture: *gpu.Texture) void {
        procs.textureReference.?(@as(c.WGPUTexture, @ptrCast(texture)));
    }

    pub inline fn textureRelease(texture: *gpu.Texture) void {
        procs.textureRelease.?(@as(c.WGPUTexture, @ptrCast(texture)));
    }

    pub inline fn textureViewSetLabel(texture_view: *gpu.TextureView, label: [*:0]const u8) void {
        procs.textureViewSetLabel.?(@as(c.WGPUTextureView, @ptrCast(texture_view)), label);
    }

    pub inline fn textureViewReference(texture_view: *gpu.TextureView) void {
        procs.textureViewReference.?(@as(c.WGPUTextureView, @ptrCast(texture_view)));
    }

    pub inline fn textureViewRelease(texture_view: *gpu.TextureView) void {
        procs.textureViewRelease.?(@as(c.WGPUTextureView, @ptrCast(texture_view)));
    }
};

test "dawn_impl" {
    _ = gpu.Export(Interface);
}
