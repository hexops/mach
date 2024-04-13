const gpu = @import("main.zig");
const builtin = @import("builtin");
const std = @import("std");

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
    pub fn init(allocator: std.mem.Allocator, _: struct {}) error{}!void {
        _ = allocator;
        didInit = true;
        procs = c.machDawnGetProcTable();
    }

    pub inline fn createInstance(descriptor: ?*const gpu.Instance.Descriptor) ?*gpu.Instance {
        if (builtin.mode == .Debug and !didInit) @panic("dawn: not initialized; did you forget to call gpu.Impl.init()?");
        return @ptrCast(procs.createInstance.?(@ptrCast(descriptor)));
    }

    pub inline fn getProcAddress(device: *gpu.Device, proc_name: [*:0]const u8) ?gpu.Proc {
        return procs.getProcAddress.?(@ptrCast(device), proc_name);
    }

    pub inline fn adapterCreateDevice(adapter: *gpu.Adapter, descriptor: ?*const gpu.Device.Descriptor) ?*gpu.Device {
        return @ptrCast(procs.adapterCreateDevice.?(@ptrCast(adapter), @ptrCast(descriptor)));
    }

    pub inline fn adapterEnumerateFeatures(adapter: *gpu.Adapter, features: ?[*]gpu.FeatureName) usize {
        return procs.adapterEnumerateFeatures.?(@ptrCast(adapter), @ptrCast(features));
    }

    pub inline fn adapterGetInstance(adapter: *gpu.Adapter) *gpu.Instance {
        return @ptrCast(procs.adapterGetInstance.?(@ptrCast(adapter)));
    }

    pub inline fn adapterGetLimits(adapter: *gpu.Adapter, limits: *gpu.SupportedLimits) u32 {
        return procs.adapterGetLimits.?(@ptrCast(adapter), @ptrCast(limits));
    }

    pub inline fn adapterGetProperties(adapter: *gpu.Adapter, properties: *gpu.Adapter.Properties) void {
        return procs.adapterGetProperties.?(@ptrCast(adapter), @ptrCast(properties));
    }

    pub inline fn adapterHasFeature(adapter: *gpu.Adapter, feature: gpu.FeatureName) u32 {
        return procs.adapterHasFeature.?(@ptrCast(adapter), @intFromEnum(feature));
    }

    pub inline fn adapterPropertiesFreeMembers(value: gpu.Adapter.Properties) void {
        procs.adapterPropertiesFreeMembers.?(@bitCast(value));
    }

    pub inline fn adapterRequestDevice(adapter: *gpu.Adapter, descriptor: ?*const gpu.Device.Descriptor, callback: gpu.RequestDeviceCallback, userdata: ?*anyopaque) void {
        return procs.adapterRequestDevice.?(
            @ptrCast(adapter),
            @ptrCast(descriptor),
            @ptrCast(callback),
            userdata,
        );
    }

    pub inline fn adapterReference(adapter: *gpu.Adapter) void {
        procs.adapterReference.?(@ptrCast(adapter));
    }

    pub inline fn adapterRelease(adapter: *gpu.Adapter) void {
        procs.adapterRelease.?(@ptrCast(adapter));
    }

    pub inline fn bindGroupSetLabel(bind_group: *gpu.BindGroup, label: [*:0]const u8) void {
        procs.bindGroupSetLabel.?(@ptrCast(bind_group), label);
    }

    pub inline fn bindGroupReference(bind_group: *gpu.BindGroup) void {
        procs.bindGroupReference.?(@ptrCast(bind_group));
    }

    pub inline fn bindGroupRelease(bind_group: *gpu.BindGroup) void {
        procs.bindGroupRelease.?(@ptrCast(bind_group));
    }

    pub inline fn bindGroupLayoutSetLabel(bind_group_layout: *gpu.BindGroupLayout, label: [*:0]const u8) void {
        procs.bindGroupLayoutSetLabel.?(@ptrCast(bind_group_layout), label);
    }

    pub inline fn bindGroupLayoutReference(bind_group_layout: *gpu.BindGroupLayout) void {
        procs.bindGroupLayoutReference.?(@ptrCast(bind_group_layout));
    }

    pub inline fn bindGroupLayoutRelease(bind_group_layout: *gpu.BindGroupLayout) void {
        procs.bindGroupLayoutRelease.?(@ptrCast(bind_group_layout));
    }

    pub inline fn bufferDestroy(buffer: *gpu.Buffer) void {
        procs.bufferDestroy.?(@ptrCast(buffer));
    }

    pub inline fn bufferGetMapState(buffer: *gpu.Buffer) gpu.Buffer.MapState {
        return @enumFromInt(procs.bufferGetMapState.?(@ptrCast(buffer)));
    }

    // TODO: dawn: return value not marked as nullable in dawn.json but in fact is.
    pub inline fn bufferGetConstMappedRange(buffer: *gpu.Buffer, offset: usize, size: usize) ?*const anyopaque {
        return procs.bufferGetConstMappedRange.?(@ptrCast(buffer), offset, size);
    }

    // TODO: dawn: return value not marked as nullable in dawn.json but in fact is.
    pub inline fn bufferGetMappedRange(buffer: *gpu.Buffer, offset: usize, size: usize) ?*anyopaque {
        return procs.bufferGetMappedRange.?(@ptrCast(buffer), offset, size);
    }

    pub inline fn bufferGetSize(buffer: *gpu.Buffer) u64 {
        return procs.bufferGetSize.?(@ptrCast(buffer));
    }

    pub inline fn bufferGetUsage(buffer: *gpu.Buffer) gpu.Buffer.UsageFlags {
        return @bitCast(procs.bufferGetUsage.?(@ptrCast(buffer)));
    }

    pub inline fn bufferMapAsync(buffer: *gpu.Buffer, mode: gpu.MapModeFlags, offset: usize, size: usize, callback: gpu.Buffer.MapCallback, userdata: ?*anyopaque) void {
        procs.bufferMapAsync.?(
            @ptrCast(buffer),
            @bitCast(mode),
            offset,
            size,
            @ptrCast(callback),
            userdata,
        );
    }

    pub inline fn bufferSetLabel(buffer: *gpu.Buffer, label: [*:0]const u8) void {
        procs.bufferSetLabel.?(@ptrCast(buffer), label);
    }

    pub inline fn bufferUnmap(buffer: *gpu.Buffer) void {
        procs.bufferUnmap.?(@ptrCast(buffer));
    }

    pub inline fn bufferReference(buffer: *gpu.Buffer) void {
        procs.bufferReference.?(@ptrCast(buffer));
    }

    pub inline fn bufferRelease(buffer: *gpu.Buffer) void {
        procs.bufferRelease.?(@ptrCast(buffer));
    }

    pub inline fn commandBufferSetLabel(command_buffer: *gpu.CommandBuffer, label: [*:0]const u8) void {
        procs.commandBufferSetLabel.?(@ptrCast(command_buffer), label);
    }

    pub inline fn commandBufferReference(command_buffer: *gpu.CommandBuffer) void {
        procs.commandBufferReference.?(@ptrCast(command_buffer));
    }

    pub inline fn commandBufferRelease(command_buffer: *gpu.CommandBuffer) void {
        procs.commandBufferRelease.?(@ptrCast(command_buffer));
    }

    pub inline fn commandEncoderBeginComputePass(command_encoder: *gpu.CommandEncoder, descriptor: ?*const gpu.ComputePassDescriptor) *gpu.ComputePassEncoder {
        return @ptrCast(procs.commandEncoderBeginComputePass.?(@ptrCast(command_encoder), @ptrCast(descriptor)));
    }

    pub inline fn commandEncoderBeginRenderPass(command_encoder: *gpu.CommandEncoder, descriptor: *const gpu.RenderPassDescriptor) *gpu.RenderPassEncoder {
        return @ptrCast(procs.commandEncoderBeginRenderPass.?(@ptrCast(command_encoder), @ptrCast(descriptor)));
    }

    pub inline fn commandEncoderClearBuffer(command_encoder: *gpu.CommandEncoder, buffer: *gpu.Buffer, offset: u64, size: u64) void {
        procs.commandEncoderClearBuffer.?(
            @ptrCast(command_encoder),
            @ptrCast(buffer),
            offset,
            size,
        );
    }

    pub inline fn commandEncoderCopyBufferToBuffer(command_encoder: *gpu.CommandEncoder, source: *gpu.Buffer, source_offset: u64, destination: *gpu.Buffer, destination_offset: u64, size: u64) void {
        procs.commandEncoderCopyBufferToBuffer.?(
            @ptrCast(command_encoder),
            @ptrCast(source),
            source_offset,
            @ptrCast(destination),
            destination_offset,
            size,
        );
    }

    pub inline fn commandEncoderCopyBufferToTexture(command_encoder: *gpu.CommandEncoder, source: *const gpu.ImageCopyBuffer, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) void {
        procs.commandEncoderCopyBufferToTexture.?(
            @ptrCast(command_encoder),
            @ptrCast(source),
            @ptrCast(destination),
            @ptrCast(copy_size),
        );
    }

    pub inline fn commandEncoderCopyTextureToBuffer(command_encoder: *gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyBuffer, copy_size: *const gpu.Extent3D) void {
        procs.commandEncoderCopyTextureToBuffer.?(
            @ptrCast(command_encoder),
            @ptrCast(source),
            @ptrCast(destination),
            @ptrCast(copy_size),
        );
    }

    pub inline fn commandEncoderCopyTextureToTexture(command_encoder: *gpu.CommandEncoder, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D) void {
        procs.commandEncoderCopyTextureToTexture.?(
            @ptrCast(command_encoder),
            @ptrCast(source),
            @ptrCast(destination),
            @ptrCast(copy_size),
        );
    }

    pub inline fn commandEncoderFinish(command_encoder: *gpu.CommandEncoder, descriptor: ?*const gpu.CommandBuffer.Descriptor) *gpu.CommandBuffer {
        return @ptrCast(procs.commandEncoderFinish.?(
            @ptrCast(command_encoder),
            @ptrCast(descriptor),
        ));
    }

    pub inline fn commandEncoderInjectValidationError(command_encoder: *gpu.CommandEncoder, message: [*:0]const u8) void {
        procs.commandEncoderInjectValidationError.?(
            @ptrCast(command_encoder),
            message,
        );
    }

    pub inline fn commandEncoderInsertDebugMarker(command_encoder: *gpu.CommandEncoder, marker_label: [*:0]const u8) void {
        procs.commandEncoderInsertDebugMarker.?(
            @ptrCast(command_encoder),
            marker_label,
        );
    }

    pub inline fn commandEncoderPopDebugGroup(command_encoder: *gpu.CommandEncoder) void {
        procs.commandEncoderPopDebugGroup.?(@ptrCast(command_encoder));
    }

    pub inline fn commandEncoderPushDebugGroup(command_encoder: *gpu.CommandEncoder, group_label: [*:0]const u8) void {
        procs.commandEncoderPushDebugGroup.?(
            @ptrCast(command_encoder),
            group_label,
        );
    }

    pub inline fn commandEncoderResolveQuerySet(command_encoder: *gpu.CommandEncoder, query_set: *gpu.QuerySet, first_query: u32, query_count: u32, destination: *gpu.Buffer, destination_offset: u64) void {
        procs.commandEncoderResolveQuerySet.?(
            @ptrCast(command_encoder),
            @ptrCast(query_set),
            first_query,
            query_count,
            @ptrCast(destination),
            destination_offset,
        );
    }

    pub inline fn commandEncoderSetLabel(command_encoder: *gpu.CommandEncoder, label: [*:0]const u8) void {
        procs.commandEncoderSetLabel.?(@ptrCast(command_encoder), label);
    }

    pub inline fn commandEncoderWriteBuffer(command_encoder: *gpu.CommandEncoder, buffer: *gpu.Buffer, buffer_offset: u64, data: [*]const u8, size: u64) void {
        procs.commandEncoderWriteBuffer.?(
            @ptrCast(command_encoder),
            @ptrCast(buffer),
            buffer_offset,
            data,
            size,
        );
    }

    pub inline fn commandEncoderWriteTimestamp(command_encoder: *gpu.CommandEncoder, query_set: *gpu.QuerySet, query_index: u32) void {
        procs.commandEncoderWriteTimestamp.?(
            @ptrCast(command_encoder),
            @ptrCast(query_set),
            query_index,
        );
    }

    pub inline fn commandEncoderReference(command_encoder: *gpu.CommandEncoder) void {
        procs.commandEncoderReference.?(@ptrCast(command_encoder));
    }

    pub inline fn commandEncoderRelease(command_encoder: *gpu.CommandEncoder) void {
        procs.commandEncoderRelease.?(@ptrCast(command_encoder));
    }

    pub inline fn computePassEncoderDispatchWorkgroups(compute_pass_encoder: *gpu.ComputePassEncoder, workgroup_count_x: u32, workgroup_count_y: u32, workgroup_count_z: u32) void {
        procs.computePassEncoderDispatchWorkgroups.?(
            @ptrCast(compute_pass_encoder),
            workgroup_count_x,
            workgroup_count_y,
            workgroup_count_z,
        );
    }

    pub inline fn computePassEncoderDispatchWorkgroupsIndirect(compute_pass_encoder: *gpu.ComputePassEncoder, indirect_buffer: *gpu.Buffer, indirect_offset: u64) void {
        procs.computePassEncoderDispatchWorkgroupsIndirect.?(
            @ptrCast(compute_pass_encoder),
            @ptrCast(indirect_buffer),
            indirect_offset,
        );
    }

    pub inline fn computePassEncoderEnd(compute_pass_encoder: *gpu.ComputePassEncoder) void {
        procs.computePassEncoderEnd.?(@ptrCast(compute_pass_encoder));
    }

    pub inline fn computePassEncoderInsertDebugMarker(compute_pass_encoder: *gpu.ComputePassEncoder, marker_label: [*:0]const u8) void {
        procs.computePassEncoderInsertDebugMarker.?(
            @ptrCast(compute_pass_encoder),
            marker_label,
        );
    }

    pub inline fn computePassEncoderPopDebugGroup(compute_pass_encoder: *gpu.ComputePassEncoder) void {
        procs.computePassEncoderPopDebugGroup.?(@ptrCast(compute_pass_encoder));
    }

    pub inline fn computePassEncoderPushDebugGroup(compute_pass_encoder: *gpu.ComputePassEncoder, group_label: [*:0]const u8) void {
        procs.computePassEncoderPushDebugGroup.?(
            @ptrCast(compute_pass_encoder),
            group_label,
        );
    }

    pub inline fn computePassEncoderSetBindGroup(compute_pass_encoder: *gpu.ComputePassEncoder, group_index: u32, group: *gpu.BindGroup, dynamic_offset_count: usize, dynamic_offsets: ?[*]const u32) void {
        procs.computePassEncoderSetBindGroup.?(
            @ptrCast(compute_pass_encoder),
            group_index,
            @ptrCast(group),
            dynamic_offset_count,
            dynamic_offsets,
        );
    }

    pub inline fn computePassEncoderSetLabel(compute_pass_encoder: *gpu.ComputePassEncoder, label: [*:0]const u8) void {
        procs.computePassEncoderSetLabel.?(@ptrCast(compute_pass_encoder), label);
    }

    pub inline fn computePassEncoderSetPipeline(compute_pass_encoder: *gpu.ComputePassEncoder, pipeline: *gpu.ComputePipeline) void {
        procs.computePassEncoderSetPipeline.?(
            @ptrCast(compute_pass_encoder),
            @ptrCast(pipeline),
        );
    }

    pub inline fn computePassEncoderWriteTimestamp(compute_pass_encoder: *gpu.ComputePassEncoder, query_set: *gpu.QuerySet, query_index: u32) void {
        procs.computePassEncoderWriteTimestamp.?(
            @ptrCast(compute_pass_encoder),
            @ptrCast(query_set),
            query_index,
        );
    }

    pub inline fn computePassEncoderReference(compute_pass_encoder: *gpu.ComputePassEncoder) void {
        procs.computePassEncoderReference.?(@ptrCast(compute_pass_encoder));
    }

    pub inline fn computePassEncoderRelease(compute_pass_encoder: *gpu.ComputePassEncoder) void {
        procs.computePassEncoderRelease.?(@ptrCast(compute_pass_encoder));
    }

    pub inline fn computePipelineGetBindGroupLayout(compute_pipeline: *gpu.ComputePipeline, group_index: u32) *gpu.BindGroupLayout {
        return @ptrCast(procs.computePipelineGetBindGroupLayout.?(
            @ptrCast(compute_pipeline),
            group_index,
        ));
    }

    pub inline fn computePipelineSetLabel(compute_pipeline: *gpu.ComputePipeline, label: [*:0]const u8) void {
        procs.computePipelineSetLabel.?(@ptrCast(compute_pipeline), label);
    }

    pub inline fn computePipelineReference(compute_pipeline: *gpu.ComputePipeline) void {
        procs.computePipelineReference.?(@ptrCast(compute_pipeline));
    }

    pub inline fn computePipelineRelease(compute_pipeline: *gpu.ComputePipeline) void {
        procs.computePipelineRelease.?(@ptrCast(compute_pipeline));
    }

    pub inline fn deviceCreateBindGroup(device: *gpu.Device, descriptor: *const gpu.BindGroup.Descriptor) *gpu.BindGroup {
        return @ptrCast(procs.deviceCreateBindGroup.?(
            @ptrCast(device),
            @ptrCast(descriptor),
        ));
    }

    pub inline fn deviceCreateBindGroupLayout(device: *gpu.Device, descriptor: *const gpu.BindGroupLayout.Descriptor) *gpu.BindGroupLayout {
        return @ptrCast(procs.deviceCreateBindGroupLayout.?(
            @ptrCast(device),
            @ptrCast(descriptor),
        ));
    }

    pub inline fn deviceCreateBuffer(device: *gpu.Device, descriptor: *const gpu.Buffer.Descriptor) *gpu.Buffer {
        return @ptrCast(procs.deviceCreateBuffer.?(
            @ptrCast(device),
            @ptrCast(descriptor),
        ));
    }

    pub inline fn deviceCreateCommandEncoder(device: *gpu.Device, descriptor: ?*const gpu.CommandEncoder.Descriptor) *gpu.CommandEncoder {
        return @ptrCast(procs.deviceCreateCommandEncoder.?(
            @ptrCast(device),
            @ptrCast(descriptor),
        ));
    }

    pub inline fn deviceCreateComputePipeline(device: *gpu.Device, descriptor: *const gpu.ComputePipeline.Descriptor) *gpu.ComputePipeline {
        return @ptrCast(procs.deviceCreateComputePipeline.?(
            @ptrCast(device),
            @ptrCast(descriptor),
        ));
    }

    pub inline fn deviceCreateComputePipelineAsync(device: *gpu.Device, descriptor: *const gpu.ComputePipeline.Descriptor, callback: gpu.CreateComputePipelineAsyncCallback, userdata: ?*anyopaque) void {
        procs.deviceCreateComputePipelineAsync.?(
            @ptrCast(device),
            @ptrCast(descriptor),
            @ptrCast(callback),
            userdata,
        );
    }

    pub inline fn deviceCreateErrorBuffer(device: *gpu.Device, descriptor: *const gpu.Buffer.Descriptor) *gpu.Buffer {
        return @ptrCast(procs.deviceCreateErrorBuffer.?(
            @ptrCast(device),
            @ptrCast(descriptor),
        ));
    }

    pub inline fn deviceCreateErrorExternalTexture(device: *gpu.Device) *gpu.ExternalTexture {
        return @ptrCast(procs.deviceCreateErrorExternalTexture.?(@ptrCast(device)));
    }

    pub inline fn deviceCreateErrorTexture(device: *gpu.Device, descriptor: *const gpu.Texture.Descriptor) *gpu.Texture {
        return @ptrCast(procs.deviceCreateErrorTexture.?(
            @ptrCast(device),
            @ptrCast(descriptor),
        ));
    }

    pub inline fn deviceCreateExternalTexture(device: *gpu.Device, external_texture_descriptor: *const gpu.ExternalTexture.Descriptor) *gpu.ExternalTexture {
        return @ptrCast(procs.deviceCreateExternalTexture.?(
            @ptrCast(device),
            @ptrCast(external_texture_descriptor),
        ));
    }

    pub inline fn deviceCreatePipelineLayout(device: *gpu.Device, pipeline_layout_descriptor: *const gpu.PipelineLayout.Descriptor) *gpu.PipelineLayout {
        return @ptrCast(procs.deviceCreatePipelineLayout.?(
            @ptrCast(device),
            @ptrCast(pipeline_layout_descriptor),
        ));
    }

    pub inline fn deviceCreateQuerySet(device: *gpu.Device, descriptor: *const gpu.QuerySet.Descriptor) *gpu.QuerySet {
        return @ptrCast(procs.deviceCreateQuerySet.?(
            @ptrCast(device),
            @ptrCast(descriptor),
        ));
    }

    pub inline fn deviceCreateRenderBundleEncoder(device: *gpu.Device, descriptor: *const gpu.RenderBundleEncoder.Descriptor) *gpu.RenderBundleEncoder {
        return @ptrCast(procs.deviceCreateRenderBundleEncoder.?(
            @ptrCast(device),
            @ptrCast(descriptor),
        ));
    }

    pub inline fn deviceCreateRenderPipeline(device: *gpu.Device, descriptor: *const gpu.RenderPipeline.Descriptor) *gpu.RenderPipeline {
        return @ptrCast(procs.deviceCreateRenderPipeline.?(
            @ptrCast(device),
            @ptrCast(descriptor),
        ));
    }

    pub inline fn deviceCreateRenderPipelineAsync(device: *gpu.Device, descriptor: *const gpu.RenderPipeline.Descriptor, callback: gpu.CreateRenderPipelineAsyncCallback, userdata: ?*anyopaque) void {
        procs.deviceCreateRenderPipelineAsync.?(
            @ptrCast(device),
            @ptrCast(descriptor),
            @ptrCast(callback),
            userdata,
        );
    }

    // TODO(self-hosted): this cannot be marked as inline for some reason.
    // https://github.com/ziglang/zig/issues/12545
    pub fn deviceCreateSampler(device: *gpu.Device, descriptor: ?*const gpu.Sampler.Descriptor) *gpu.Sampler {
        return @ptrCast(procs.deviceCreateSampler.?(
            @ptrCast(device),
            @ptrCast(descriptor),
        ));
    }

    pub inline fn deviceCreateShaderModule(device: *gpu.Device, descriptor: *const gpu.ShaderModule.Descriptor) *gpu.ShaderModule {
        return @ptrCast(procs.deviceCreateShaderModule.?(
            @ptrCast(device),
            @ptrCast(descriptor),
        ));
    }

    pub inline fn deviceCreateSwapChain(device: *gpu.Device, surface: ?*gpu.Surface, descriptor: *const gpu.SwapChain.Descriptor) *gpu.SwapChain {
        return @ptrCast(procs.deviceCreateSwapChain.?(
            @ptrCast(device),
            @ptrCast(surface),
            @ptrCast(descriptor),
        ));
    }

    pub inline fn deviceCreateTexture(device: *gpu.Device, descriptor: *const gpu.Texture.Descriptor) *gpu.Texture {
        return @ptrCast(procs.deviceCreateTexture.?(
            @ptrCast(device),
            @ptrCast(descriptor),
        ));
    }

    pub inline fn deviceDestroy(device: *gpu.Device) void {
        procs.deviceDestroy.?(@ptrCast(device));
    }

    pub inline fn deviceEnumerateFeatures(device: *gpu.Device, features: ?[*]gpu.FeatureName) usize {
        return procs.deviceEnumerateFeatures.?(@ptrCast(device), @ptrCast(features));
    }

    pub inline fn forceLoss(device: *gpu.Device, reason: gpu.Device.LostReason, message: [*:0]const u8) void {
        return procs.deviceForceLoss.?(
            @ptrCast(device),
            reason,
            message,
        );
    }

    pub inline fn deviceGetAdapter(device: *gpu.Device) *gpu.Adapter {
        return procs.deviceGetAdapter.?(@ptrCast(device));
    }

    pub inline fn deviceGetLimits(device: *gpu.Device, limits: *gpu.SupportedLimits) u32 {
        return procs.deviceGetLimits.?(
            @ptrCast(device),
            @ptrCast(limits),
        );
    }

    pub inline fn deviceGetQueue(device: *gpu.Device) *gpu.Queue {
        return @ptrCast(procs.deviceGetQueue.?(@ptrCast(device)));
    }

    pub inline fn deviceHasFeature(device: *gpu.Device, feature: gpu.FeatureName) u32 {
        return procs.deviceHasFeature.?(
            @ptrCast(device),
            @intFromEnum(feature),
        );
    }

    pub inline fn deviceImportSharedFence(device: *gpu.Device, descriptor: *const gpu.SharedFence.Descriptor) *gpu.SharedFence {
        return @ptrCast(procs.deviceImportSharedFence.?(@ptrCast(device), @ptrCast(descriptor)));
    }

    pub inline fn deviceImportSharedTextureMemory(device: *gpu.Device, descriptor: *const gpu.SharedTextureMemory.Descriptor) *gpu.SharedTextureMemory {
        return @ptrCast(procs.deviceImportSharedTextureMemory.?(@ptrCast(device), @ptrCast(descriptor)));
    }

    pub inline fn deviceInjectError(device: *gpu.Device, typ: gpu.ErrorType, message: [*:0]const u8) void {
        procs.deviceInjectError.?(
            @ptrCast(device),
            @intFromEnum(typ),
            message,
        );
    }

    pub inline fn devicePopErrorScope(device: *gpu.Device, callback: gpu.ErrorCallback, userdata: ?*anyopaque) void {
        procs.devicePopErrorScope.?(
            @ptrCast(device),
            @ptrCast(callback),
            userdata,
        );
    }

    pub inline fn devicePushErrorScope(device: *gpu.Device, filter: gpu.ErrorFilter) void {
        procs.devicePushErrorScope.?(
            @ptrCast(device),
            @intFromEnum(filter),
        );
    }

    pub inline fn deviceSetDeviceLostCallback(device: *gpu.Device, callback: ?gpu.Device.LostCallback, userdata: ?*anyopaque) void {
        procs.deviceSetDeviceLostCallback.?(
            @ptrCast(device),
            @ptrCast(callback),
            userdata,
        );
    }

    pub inline fn deviceSetLabel(device: *gpu.Device, label: [*:0]const u8) void {
        procs.deviceSetLabel.?(@ptrCast(device), label);
    }

    pub inline fn deviceSetLoggingCallback(device: *gpu.Device, callback: ?gpu.LoggingCallback, userdata: ?*anyopaque) void {
        procs.deviceSetLoggingCallback.?(
            @ptrCast(device),
            @ptrCast(callback),
            userdata,
        );
    }

    pub inline fn deviceSetUncapturedErrorCallback(device: *gpu.Device, callback: ?gpu.ErrorCallback, userdata: ?*anyopaque) void {
        procs.deviceSetUncapturedErrorCallback.?(
            @ptrCast(device),
            @ptrCast(callback),
            userdata,
        );
    }

    pub inline fn deviceTick(device: *gpu.Device) void {
        procs.deviceTick.?(@ptrCast(device));
    }

    pub inline fn machDeviceWaitForCommandsToBeScheduled(device: *gpu.Device) void {
        c.machDawnDeviceWaitForCommandsToBeScheduled(@ptrCast(device));
    }

    pub inline fn deviceValidateTextureDescriptor(device: *gpu.Device, descriptor: *const gpu.Texture.Descriptor) void {
        procs.deviceValidateTextureDescriptor(device, descriptor);
    }

    pub inline fn deviceReference(device: *gpu.Device) void {
        procs.deviceReference.?(@ptrCast(device));
    }

    pub inline fn deviceRelease(device: *gpu.Device) void {
        procs.deviceRelease.?(@ptrCast(device));
    }

    pub inline fn externalTextureDestroy(external_texture: *gpu.ExternalTexture) void {
        procs.externalTextureDestroy.?(@ptrCast(external_texture));
    }

    pub inline fn externalTextureSetLabel(external_texture: *gpu.ExternalTexture, label: [*:0]const u8) void {
        procs.externalTextureSetLabel.?(@ptrCast(external_texture), label);
    }

    pub inline fn externalTextureReference(external_texture: *gpu.ExternalTexture) void {
        procs.externalTextureReference.?(@ptrCast(external_texture));
    }

    pub inline fn externalTextureRelease(external_texture: *gpu.ExternalTexture) void {
        procs.externalTextureRelease.?(@ptrCast(external_texture));
    }

    pub inline fn instanceCreateSurface(instance: *gpu.Instance, descriptor: *const gpu.Surface.Descriptor) *gpu.Surface {
        return @ptrCast(procs.instanceCreateSurface.?(
            @ptrCast(instance),
            @ptrCast(descriptor),
        ));
    }

    pub inline fn instanceProcessEvents(instance: *gpu.Instance) void {
        procs.instanceProcessEvents.?(
            @ptrCast(instance),
        );
    }

    pub inline fn instanceRequestAdapter(instance: *gpu.Instance, options: ?*const gpu.RequestAdapterOptions, callback: gpu.RequestAdapterCallback, userdata: ?*anyopaque) void {
        procs.instanceRequestAdapter.?(
            @ptrCast(instance),
            @ptrCast(options),
            @ptrCast(callback),
            userdata,
        );
    }

    pub inline fn instanceReference(instance: *gpu.Instance) void {
        procs.instanceReference.?(@ptrCast(instance));
    }

    pub inline fn instanceRelease(instance: *gpu.Instance) void {
        procs.instanceRelease.?(@ptrCast(instance));
    }

    pub inline fn pipelineLayoutSetLabel(pipeline_layout: *gpu.PipelineLayout, label: [*:0]const u8) void {
        procs.pipelineLayoutSetLabel.?(@ptrCast(pipeline_layout), label);
    }

    pub inline fn pipelineLayoutReference(pipeline_layout: *gpu.PipelineLayout) void {
        procs.pipelineLayoutReference.?(@ptrCast(pipeline_layout));
    }

    pub inline fn pipelineLayoutRelease(pipeline_layout: *gpu.PipelineLayout) void {
        procs.pipelineLayoutRelease.?(@ptrCast(pipeline_layout));
    }

    pub inline fn querySetDestroy(query_set: *gpu.QuerySet) void {
        procs.querySetDestroy.?(@ptrCast(query_set));
    }

    pub inline fn querySetGetCount(query_set: *gpu.QuerySet) u32 {
        return procs.querySetGetCount.?(@ptrCast(query_set));
    }

    pub inline fn querySetGetType(query_set: *gpu.QuerySet) gpu.QueryType {
        return @enumFromInt(procs.querySetGetType.?(@ptrCast(query_set)));
    }

    pub inline fn querySetSetLabel(query_set: *gpu.QuerySet, label: [*:0]const u8) void {
        procs.querySetSetLabel.?(@ptrCast(query_set), label);
    }

    pub inline fn querySetReference(query_set: *gpu.QuerySet) void {
        procs.querySetReference.?(@ptrCast(query_set));
    }

    pub inline fn querySetRelease(query_set: *gpu.QuerySet) void {
        procs.querySetRelease.?(@ptrCast(query_set));
    }

    pub inline fn queueCopyExternalTextureForBrowser(queue: *gpu.Queue, source: *const gpu.ImageCopyExternalTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D, options: *const gpu.CopyTextureForBrowserOptions) void {
        procs.queueCopyExternalTextureForBrowser.?(
            @ptrCast(queue),
            @ptrCast(source),
            @ptrCast(destination),
            @ptrCast(copy_size),
            @ptrCast(options),
        );
    }

    pub inline fn queueCopyTextureForBrowser(queue: *gpu.Queue, source: *const gpu.ImageCopyTexture, destination: *const gpu.ImageCopyTexture, copy_size: *const gpu.Extent3D, options: *const gpu.CopyTextureForBrowserOptions) void {
        procs.queueCopyTextureForBrowser.?(
            @ptrCast(queue),
            @ptrCast(source),
            @ptrCast(destination),
            @ptrCast(copy_size),
            @ptrCast(options),
        );
    }

    pub inline fn queueOnSubmittedWorkDone(queue: *gpu.Queue, signal_value: u64, callback: gpu.Queue.WorkDoneCallback, userdata: ?*anyopaque) void {
        procs.queueOnSubmittedWorkDone.?(
            @ptrCast(queue),
            signal_value,
            @ptrCast(callback),
            userdata,
        );
    }

    pub inline fn queueSetLabel(queue: *gpu.Queue, label: [*:0]const u8) void {
        procs.queueSetLabel.?(@ptrCast(queue), label);
    }

    pub inline fn queueSubmit(queue: *gpu.Queue, command_count: usize, commands: [*]const *const gpu.CommandBuffer) void {
        procs.queueSubmit.?(
            @ptrCast(queue),
            command_count,
            @ptrCast(commands),
        );
    }

    pub inline fn queueWriteBuffer(queue: *gpu.Queue, buffer: *gpu.Buffer, buffer_offset: u64, data: *const anyopaque, size: usize) void {
        procs.queueWriteBuffer.?(
            @ptrCast(queue),
            @ptrCast(buffer),
            buffer_offset,
            data,
            size,
        );
    }

    pub inline fn queueWriteTexture(queue: *gpu.Queue, destination: *const gpu.ImageCopyTexture, data: *const anyopaque, data_size: usize, data_layout: *const gpu.Texture.DataLayout, write_size: *const gpu.Extent3D) void {
        procs.queueWriteTexture.?(
            @ptrCast(queue),
            @ptrCast(destination),
            data,
            data_size,
            @ptrCast(data_layout),
            @ptrCast(write_size),
        );
    }

    pub inline fn queueReference(queue: *gpu.Queue) void {
        procs.queueReference.?(@ptrCast(queue));
    }

    pub inline fn queueRelease(queue: *gpu.Queue) void {
        procs.queueRelease.?(@ptrCast(queue));
    }

    pub inline fn renderBundleSetLabel(render_bundle: *gpu.RenderBundle, label: [*:0]const u8) void {
        procs.renderBundleSetLabel.?(@ptrCast(render_bundle), label);
    }

    pub inline fn renderBundleReference(render_bundle: *gpu.RenderBundle) void {
        procs.renderBundleReference.?(@ptrCast(render_bundle));
    }

    pub inline fn renderBundleRelease(render_bundle: *gpu.RenderBundle) void {
        procs.renderBundleRelease.?(@ptrCast(render_bundle));
    }

    pub inline fn renderBundleEncoderDraw(render_bundle_encoder: *gpu.RenderBundleEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {
        procs.renderBundleEncoderDraw.?(@ptrCast(render_bundle_encoder), vertex_count, instance_count, first_vertex, first_instance);
    }

    pub inline fn renderBundleEncoderDrawIndexed(render_bundle_encoder: *gpu.RenderBundleEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: i32, first_instance: u32) void {
        procs.renderBundleEncoderDrawIndexed.?(
            @ptrCast(render_bundle_encoder),
            index_count,
            instance_count,
            first_index,
            base_vertex,
            first_instance,
        );
    }

    pub inline fn renderBundleEncoderDrawIndexedIndirect(render_bundle_encoder: *gpu.RenderBundleEncoder, indirect_buffer: *gpu.Buffer, indirect_offset: u64) void {
        procs.renderBundleEncoderDrawIndexedIndirect.?(
            @ptrCast(render_bundle_encoder),
            @ptrCast(indirect_buffer),
            indirect_offset,
        );
    }

    pub inline fn renderBundleEncoderDrawIndirect(render_bundle_encoder: *gpu.RenderBundleEncoder, indirect_buffer: *gpu.Buffer, indirect_offset: u64) void {
        procs.renderBundleEncoderDrawIndirect.?(
            @ptrCast(render_bundle_encoder),
            @ptrCast(indirect_buffer),
            indirect_offset,
        );
    }

    pub inline fn renderBundleEncoderFinish(render_bundle_encoder: *gpu.RenderBundleEncoder, descriptor: ?*const gpu.RenderBundle.Descriptor) *gpu.RenderBundle {
        return @ptrCast(procs.renderBundleEncoderFinish.?(
            @ptrCast(render_bundle_encoder),
            @ptrCast(descriptor),
        ));
    }

    pub inline fn renderBundleEncoderInsertDebugMarker(render_bundle_encoder: *gpu.RenderBundleEncoder, marker_label: [*:0]const u8) void {
        procs.renderBundleEncoderInsertDebugMarker.?(
            @ptrCast(render_bundle_encoder),
            marker_label,
        );
    }

    pub inline fn renderBundleEncoderPopDebugGroup(render_bundle_encoder: *gpu.RenderBundleEncoder) void {
        procs.renderBundleEncoderPopDebugGroup.?(@ptrCast(render_bundle_encoder));
    }

    pub inline fn renderBundleEncoderPushDebugGroup(render_bundle_encoder: *gpu.RenderBundleEncoder, group_label: [*:0]const u8) void {
        procs.renderBundleEncoderPushDebugGroup.?(@ptrCast(render_bundle_encoder), group_label);
    }

    pub inline fn renderBundleEncoderSetBindGroup(render_bundle_encoder: *gpu.RenderBundleEncoder, group_index: u32, group: *gpu.BindGroup, dynamic_offset_count: usize, dynamic_offsets: ?[*]const u32) void {
        procs.renderBundleEncoderSetBindGroup.?(
            @ptrCast(render_bundle_encoder),
            group_index,
            @ptrCast(group),
            dynamic_offset_count,
            dynamic_offsets,
        );
    }

    pub inline fn renderBundleEncoderSetIndexBuffer(render_bundle_encoder: *gpu.RenderBundleEncoder, buffer: *gpu.Buffer, format: gpu.IndexFormat, offset: u64, size: u64) void {
        procs.renderBundleEncoderSetIndexBuffer.?(
            @ptrCast(render_bundle_encoder),
            @ptrCast(buffer),
            @intFromEnum(format),
            offset,
            size,
        );
    }

    pub inline fn renderBundleEncoderSetLabel(render_bundle_encoder: *gpu.RenderBundleEncoder, label: [*:0]const u8) void {
        procs.renderBundleEncoderSetLabel.?(@ptrCast(render_bundle_encoder), label);
    }

    pub inline fn renderBundleEncoderSetPipeline(render_bundle_encoder: *gpu.RenderBundleEncoder, pipeline: *gpu.RenderPipeline) void {
        procs.renderBundleEncoderSetPipeline.?(
            @ptrCast(render_bundle_encoder),
            @ptrCast(pipeline),
        );
    }

    pub inline fn renderBundleEncoderSetVertexBuffer(render_bundle_encoder: *gpu.RenderBundleEncoder, slot: u32, buffer: *gpu.Buffer, offset: u64, size: u64) void {
        procs.renderBundleEncoderSetVertexBuffer.?(
            @ptrCast(render_bundle_encoder),
            slot,
            @ptrCast(buffer),
            offset,
            size,
        );
    }

    pub inline fn renderBundleEncoderReference(render_bundle_encoder: *gpu.RenderBundleEncoder) void {
        procs.renderBundleEncoderReference.?(@ptrCast(render_bundle_encoder));
    }

    pub inline fn renderBundleEncoderRelease(render_bundle_encoder: *gpu.RenderBundleEncoder) void {
        procs.renderBundleEncoderRelease.?(@ptrCast(render_bundle_encoder));
    }

    pub inline fn renderPassEncoderBeginOcclusionQuery(render_pass_encoder: *gpu.RenderPassEncoder, query_index: u32) void {
        procs.renderPassEncoderBeginOcclusionQuery.?(
            @ptrCast(render_pass_encoder),
            query_index,
        );
    }

    pub inline fn renderPassEncoderDraw(render_pass_encoder: *gpu.RenderPassEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {
        procs.renderPassEncoderDraw.?(
            @ptrCast(render_pass_encoder),
            vertex_count,
            instance_count,
            first_vertex,
            first_instance,
        );
    }

    pub inline fn renderPassEncoderDrawIndexed(render_pass_encoder: *gpu.RenderPassEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: i32, first_instance: u32) void {
        procs.renderPassEncoderDrawIndexed.?(
            @ptrCast(render_pass_encoder),
            index_count,
            instance_count,
            first_index,
            base_vertex,
            first_instance,
        );
    }

    pub inline fn renderPassEncoderDrawIndexedIndirect(render_pass_encoder: *gpu.RenderPassEncoder, indirect_buffer: *gpu.Buffer, indirect_offset: u64) void {
        procs.renderPassEncoderDrawIndexedIndirect.?(
            @ptrCast(render_pass_encoder),
            @ptrCast(indirect_buffer),
            indirect_offset,
        );
    }

    pub inline fn renderPassEncoderDrawIndirect(render_pass_encoder: *gpu.RenderPassEncoder, indirect_buffer: *gpu.Buffer, indirect_offset: u64) void {
        procs.renderPassEncoderDrawIndirect.?(
            @ptrCast(render_pass_encoder),
            @ptrCast(indirect_buffer),
            indirect_offset,
        );
    }

    pub inline fn renderPassEncoderEnd(render_pass_encoder: *gpu.RenderPassEncoder) void {
        procs.renderPassEncoderEnd.?(@ptrCast(render_pass_encoder));
    }

    pub inline fn renderPassEncoderEndOcclusionQuery(render_pass_encoder: *gpu.RenderPassEncoder) void {
        procs.renderPassEncoderEndOcclusionQuery.?(@ptrCast(render_pass_encoder));
    }

    pub inline fn renderPassEncoderExecuteBundles(render_pass_encoder: *gpu.RenderPassEncoder, bundles_count: usize, bundles: [*]const *const gpu.RenderBundle) void {
        procs.renderPassEncoderExecuteBundles.?(
            @ptrCast(render_pass_encoder),
            bundles_count,
            @ptrCast(bundles),
        );
    }

    pub inline fn renderPassEncoderInsertDebugMarker(render_pass_encoder: *gpu.RenderPassEncoder, marker_label: [*:0]const u8) void {
        procs.renderPassEncoderInsertDebugMarker.?(@ptrCast(render_pass_encoder), marker_label);
    }

    pub inline fn renderPassEncoderPopDebugGroup(render_pass_encoder: *gpu.RenderPassEncoder) void {
        procs.renderPassEncoderPopDebugGroup.?(@ptrCast(render_pass_encoder));
    }

    pub inline fn renderPassEncoderPushDebugGroup(render_pass_encoder: *gpu.RenderPassEncoder, group_label: [*:0]const u8) void {
        procs.renderPassEncoderPushDebugGroup.?(
            @ptrCast(render_pass_encoder),
            group_label,
        );
    }

    pub inline fn renderPassEncoderSetBindGroup(render_pass_encoder: *gpu.RenderPassEncoder, group_index: u32, group: *gpu.BindGroup, dynamic_offset_count: usize, dynamic_offsets: ?[*]const u32) void {
        procs.renderPassEncoderSetBindGroup.?(
            @ptrCast(render_pass_encoder),
            group_index,
            @ptrCast(group),
            dynamic_offset_count,
            dynamic_offsets,
        );
    }

    pub inline fn renderPassEncoderSetBlendConstant(render_pass_encoder: *gpu.RenderPassEncoder, color: *const gpu.Color) void {
        procs.renderPassEncoderSetBlendConstant.?(
            @ptrCast(render_pass_encoder),
            @ptrCast(color),
        );
    }

    pub inline fn renderPassEncoderSetIndexBuffer(render_pass_encoder: *gpu.RenderPassEncoder, buffer: *gpu.Buffer, format: gpu.IndexFormat, offset: u64, size: u64) void {
        procs.renderPassEncoderSetIndexBuffer.?(
            @ptrCast(render_pass_encoder),
            @ptrCast(buffer),
            @intFromEnum(format),
            offset,
            size,
        );
    }

    pub inline fn renderPassEncoderSetLabel(render_pass_encoder: *gpu.RenderPassEncoder, label: [*:0]const u8) void {
        procs.renderPassEncoderSetLabel.?(@ptrCast(render_pass_encoder), label);
    }

    pub inline fn renderPassEncoderSetPipeline(render_pass_encoder: *gpu.RenderPassEncoder, pipeline: *gpu.RenderPipeline) void {
        procs.renderPassEncoderSetPipeline.?(
            @ptrCast(render_pass_encoder),
            @ptrCast(pipeline),
        );
    }

    pub inline fn renderPassEncoderSetScissorRect(render_pass_encoder: *gpu.RenderPassEncoder, x: u32, y: u32, width: u32, height: u32) void {
        procs.renderPassEncoderSetScissorRect.?(
            @ptrCast(render_pass_encoder),
            x,
            y,
            width,
            height,
        );
    }

    pub inline fn renderPassEncoderSetStencilReference(render_pass_encoder: *gpu.RenderPassEncoder, reference: u32) void {
        procs.renderPassEncoderSetStencilReference.?(
            @ptrCast(render_pass_encoder),
            reference,
        );
    }

    pub inline fn renderPassEncoderSetVertexBuffer(render_pass_encoder: *gpu.RenderPassEncoder, slot: u32, buffer: *gpu.Buffer, offset: u64, size: u64) void {
        procs.renderPassEncoderSetVertexBuffer.?(
            @ptrCast(render_pass_encoder),
            slot,
            @ptrCast(buffer),
            offset,
            size,
        );
    }

    pub inline fn renderPassEncoderSetViewport(render_pass_encoder: *gpu.RenderPassEncoder, x: f32, y: f32, width: f32, height: f32, min_depth: f32, max_depth: f32) void {
        procs.renderPassEncoderSetViewport.?(
            @ptrCast(render_pass_encoder),
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
            @ptrCast(render_pass_encoder),
            @ptrCast(query_set),
            query_index,
        );
    }

    pub inline fn renderPassEncoderReference(render_pass_encoder: *gpu.RenderPassEncoder) void {
        procs.renderPassEncoderReference.?(@ptrCast(render_pass_encoder));
    }

    pub inline fn renderPassEncoderRelease(render_pass_encoder: *gpu.RenderPassEncoder) void {
        procs.renderPassEncoderRelease.?(@ptrCast(render_pass_encoder));
    }

    pub inline fn renderPipelineGetBindGroupLayout(render_pipeline: *gpu.RenderPipeline, group_index: u32) *gpu.BindGroupLayout {
        return @ptrCast(procs.renderPipelineGetBindGroupLayout.?(
            @ptrCast(render_pipeline),
            group_index,
        ));
    }

    pub inline fn renderPipelineSetLabel(render_pipeline: *gpu.RenderPipeline, label: [*:0]const u8) void {
        procs.renderPipelineSetLabel.?(@ptrCast(render_pipeline), label);
    }

    pub inline fn renderPipelineReference(render_pipeline: *gpu.RenderPipeline) void {
        procs.renderPipelineReference.?(@ptrCast(render_pipeline));
    }

    pub inline fn renderPipelineRelease(render_pipeline: *gpu.RenderPipeline) void {
        procs.renderPipelineRelease.?(@ptrCast(render_pipeline));
    }

    pub inline fn samplerSetLabel(sampler: *gpu.Sampler, label: [*:0]const u8) void {
        procs.samplerSetLabel.?(@ptrCast(sampler), label);
    }

    pub inline fn samplerReference(sampler: *gpu.Sampler) void {
        procs.samplerReference.?(@ptrCast(sampler));
    }

    pub inline fn samplerRelease(sampler: *gpu.Sampler) void {
        procs.samplerRelease.?(@ptrCast(sampler));
    }

    pub inline fn shaderModuleGetCompilationInfo(shader_module: *gpu.ShaderModule, callback: gpu.CompilationInfoCallback, userdata: ?*anyopaque) void {
        procs.shaderModuleGetCompilationInfo.?(
            @ptrCast(shader_module),
            @ptrCast(callback),
            userdata,
        );
    }

    pub inline fn shaderModuleSetLabel(shader_module: *gpu.ShaderModule, label: [*:0]const u8) void {
        procs.shaderModuleSetLabel.?(@ptrCast(shader_module), label);
    }

    pub inline fn shaderModuleReference(shader_module: *gpu.ShaderModule) void {
        procs.shaderModuleReference.?(@ptrCast(shader_module));
    }

    pub inline fn shaderModuleRelease(shader_module: *gpu.ShaderModule) void {
        procs.shaderModuleRelease.?(@ptrCast(shader_module));
    }

    pub inline fn sharedFenceExportInfo(shared_fence: *gpu.SharedFence, info: *gpu.SharedFence.ExportInfo) void {
        procs.sharedFenceExportInfo.?(@ptrCast(shared_fence), @ptrCast(info));
    }

    pub inline fn sharedFenceReference(shared_fence: *gpu.SharedFence) void {
        procs.sharedFenceReference.?(@ptrCast(shared_fence));
    }

    pub inline fn sharedFenceRelease(shared_fence: *gpu.SharedFence) void {
        procs.sharedFenceRelease.?(@ptrCast(shared_fence));
    }

    pub inline fn sharedTextureMemoryBeginAccess(shared_texture_memory: *gpu.SharedTextureMemory, texture: *gpu.Texture, descriptor: *const gpu.SharedTextureMemory.BeginAccessDescriptor) void {
        procs.sharedTextureMemoryBeginAccess.?(@ptrCast(shared_texture_memory), @ptrCast(texture), @ptrCast(descriptor));
    }

    pub inline fn sharedTextureMemoryCreateTexture(shared_texture_memory: *gpu.SharedTextureMemory, descriptor: *const gpu.Texture.Descriptor) *gpu.Texture {
        return @ptrCast(procs.sharedTextureMemoryCreateTexture.?(@ptrCast(shared_texture_memory), @ptrCast(descriptor)));
    }

    pub inline fn sharedTextureMemoryEndAccess(shared_texture_memory: *gpu.SharedTextureMemory, texture: *gpu.Texture, descriptor: *gpu.SharedTextureMemory.EndAccessState) void {
        procs.sharedTextureMemoryEndAccess.?(@ptrCast(shared_texture_memory), @ptrCast(texture), @ptrCast(descriptor));
    }

    pub inline fn sharedTextureMemoryEndAccessStateFreeMembers(value: gpu.SharedTextureMemory.EndAccessState) void {
        procs.sharedTextureMemoryEndAccessStateFreeMembers.?(@bitCast(value));
    }

    pub inline fn sharedTextureMemoryGetProperties(shared_texture_memory: *gpu.SharedTextureMemory, properties: *gpu.SharedTextureMemory.Properties) void {
        procs.sharedTextureMemoryGetProperties.?(@ptrCast(shared_texture_memory), @ptrCast(properties));
    }

    pub inline fn sharedTextureMemorySetLabel(shared_texture_memory: *gpu.SharedTextureMemory, label: [*:0]const u8) void {
        procs.sharedTextureMemorySetLabel.?(@ptrCast(shared_texture_memory), label);
    }

    pub inline fn sharedTextureMemoryReference(shared_texture_memory: *gpu.SharedTextureMemory) void {
        procs.sharedTextureMemoryReference.?(@ptrCast(shared_texture_memory));
    }

    pub inline fn sharedTextureMemoryRelease(shared_texture_memory: *gpu.SharedTextureMemory) void {
        procs.sharedTextureMemoryRelease.?(@ptrCast(shared_texture_memory));
    }

    pub inline fn surfaceReference(surface: *gpu.Surface) void {
        procs.surfaceReference.?(@ptrCast(surface));
    }

    pub inline fn surfaceRelease(surface: *gpu.Surface) void {
        procs.surfaceRelease.?(@ptrCast(surface));
    }

    pub inline fn swapChainGetCurrentTexture(swap_chain: *gpu.SwapChain) ?*gpu.Texture {
        return @ptrCast(procs.swapChainGetCurrentTexture.?(@ptrCast(swap_chain)));
    }

    pub inline fn swapChainGetCurrentTextureView(swap_chain: *gpu.SwapChain) ?*gpu.TextureView {
        return @ptrCast(procs.swapChainGetCurrentTextureView.?(@ptrCast(swap_chain)));
    }

    pub inline fn swapChainPresent(swap_chain: *gpu.SwapChain) void {
        procs.swapChainPresent.?(@ptrCast(swap_chain));
    }

    pub inline fn swapChainReference(swap_chain: *gpu.SwapChain) void {
        procs.swapChainReference.?(@ptrCast(swap_chain));
    }

    pub inline fn swapChainRelease(swap_chain: *gpu.SwapChain) void {
        procs.swapChainRelease.?(@ptrCast(swap_chain));
    }

    pub inline fn textureCreateView(texture: *gpu.Texture, descriptor: ?*const gpu.TextureView.Descriptor) *gpu.TextureView {
        return @ptrCast(procs.textureCreateView.?(
            @ptrCast(texture),
            @ptrCast(descriptor),
        ));
    }

    pub inline fn textureDestroy(texture: *gpu.Texture) void {
        procs.textureDestroy.?(@ptrCast(texture));
    }

    pub inline fn textureGetDepthOrArrayLayers(texture: *gpu.Texture) u32 {
        return procs.textureGetDepthOrArrayLayers.?(@ptrCast(texture));
    }

    pub inline fn textureGetDimension(texture: *gpu.Texture) gpu.Texture.Dimension {
        return @enumFromInt(procs.textureGetDimension.?(@ptrCast(texture)));
    }

    pub inline fn textureGetFormat(texture: *gpu.Texture) gpu.Texture.Format {
        return @enumFromInt(procs.textureGetFormat.?(@ptrCast(texture)));
    }

    pub inline fn textureGetHeight(texture: *gpu.Texture) u32 {
        return procs.textureGetHeight.?(@ptrCast(texture));
    }

    pub inline fn textureGetMipLevelCount(texture: *gpu.Texture) u32 {
        return procs.textureGetMipLevelCount.?(@ptrCast(texture));
    }

    pub inline fn textureGetSampleCount(texture: *gpu.Texture) u32 {
        return procs.textureGetSampleCount.?(@ptrCast(texture));
    }

    pub inline fn textureGetUsage(texture: *gpu.Texture) gpu.Texture.UsageFlags {
        return @bitCast(procs.textureGetUsage.?(@ptrCast(texture)));
    }

    pub inline fn textureGetWidth(texture: *gpu.Texture) u32 {
        return procs.textureGetWidth.?(@ptrCast(texture));
    }

    pub inline fn textureSetLabel(texture: *gpu.Texture, label: [*:0]const u8) void {
        procs.textureSetLabel.?(@ptrCast(texture), label);
    }

    pub inline fn textureReference(texture: *gpu.Texture) void {
        procs.textureReference.?(@ptrCast(texture));
    }

    pub inline fn textureRelease(texture: *gpu.Texture) void {
        procs.textureRelease.?(@ptrCast(texture));
    }

    pub inline fn textureViewSetLabel(texture_view: *gpu.TextureView, label: [*:0]const u8) void {
        procs.textureViewSetLabel.?(@ptrCast(texture_view), label);
    }

    pub inline fn textureViewReference(texture_view: *gpu.TextureView) void {
        procs.textureViewReference.?(@ptrCast(texture_view));
    }

    pub inline fn textureViewRelease(texture_view: *gpu.TextureView) void {
        procs.textureViewRelease.?(@ptrCast(texture_view));
    }
};

test "dawn_impl" {
    _ = gpu.Export(Interface);
}
