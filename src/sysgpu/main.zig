const std = @import("std");
const builtin = @import("builtin");
const build_options = @import("build-options");
pub const sysgpu = @import("sysgpu/main.zig");
pub const shader = @import("shader.zig");
const utils = @import("utils.zig");

const backend_type: sysgpu.BackendType =
    if (build_options.sysgpu_backend != .default) build_options.sysgpu_backend else switch (builtin.target.os.tag) {
    .linux => .vulkan,
    .macos, .ios => .metal,
    .windows => .d3d12,
    else => @compileError("unsupported platform"),
};
const impl = switch (backend_type) {
    .d3d12 => @import("d3d12.zig"),
    .metal => @import("metal.zig"),
    .opengl => @import("opengl.zig"),
    .vulkan => @import("vulkan.zig"),
    else => @compileError("unsupported backend"),
};

var inited = false;
var allocator: std.mem.Allocator = undefined;

pub const Impl = sysgpu.Interface(struct {
    pub fn init(alloc: std.mem.Allocator, options: impl.InitOptions) !void {
        inited = true;
        allocator = alloc;
        try impl.init(alloc, options);
    }

    pub inline fn createInstance(descriptor: ?*const sysgpu.Instance.Descriptor) ?*sysgpu.Instance {
        if (builtin.mode == .Debug and !inited) {
            std.log.err("sysgpu not initialized; did you forget to call sysgpu.Impl.init()?", .{});
        }

        const instance = impl.Instance.init(descriptor orelse &sysgpu.Instance.Descriptor{}) catch @panic("api error");
        return @as(*sysgpu.Instance, @ptrCast(instance));
    }

    pub inline fn getProcAddress(device: *sysgpu.Device, proc_name: [*:0]const u8) ?sysgpu.Proc {
        _ = device;
        _ = proc_name;
        @panic("unimplemented");
    }

    pub inline fn adapterCreateDevice(adapter_raw: *sysgpu.Adapter, descriptor: ?*const sysgpu.Device.Descriptor) ?*sysgpu.Device {
        const adapter: *impl.Adapter = @ptrCast(@alignCast(adapter_raw));
        const device = adapter.createDevice(descriptor) catch return null;
        if (descriptor) |desc| {
            device.lost_cb = desc.device_lost_callback;
            device.lost_cb_userdata = desc.device_lost_userdata;
        }
        return @as(*sysgpu.Device, @ptrCast(device));
    }

    pub inline fn adapterEnumerateFeatures(adapter: *sysgpu.Adapter, features: ?[*]sysgpu.FeatureName) usize {
        _ = adapter;
        _ = features;
        @panic("unimplemented");
    }

    pub inline fn adapterGetLimits(adapter: *sysgpu.Adapter, limits: *sysgpu.SupportedLimits) u32 {
        _ = adapter;
        _ = limits;
        @panic("unimplemented");
    }

    pub inline fn adapterGetInstance(adapter: *sysgpu.Adapter) *sysgpu.Instance {
        _ = adapter;
        @panic("unimplemented");
    }

    pub inline fn adapterGetProperties(adapter_raw: *sysgpu.Adapter, properties: *sysgpu.Adapter.Properties) void {
        const adapter: *impl.Adapter = @ptrCast(@alignCast(adapter_raw));
        properties.* = adapter.getProperties();
    }

    pub inline fn adapterHasFeature(adapter: *sysgpu.Adapter, feature: sysgpu.FeatureName) u32 {
        _ = adapter;
        _ = feature;
        @panic("unimplemented");
    }

    pub inline fn adapterPropertiesFreeMembers(value: sysgpu.Adapter.Properties) void {
        _ = value;
        @panic("unimplemented");
    }

    pub inline fn adapterRequestDevice(adapter: *sysgpu.Adapter, descriptor: ?*const sysgpu.Device.Descriptor, callback: sysgpu.RequestDeviceCallback, userdata: ?*anyopaque) void {
        _ = adapter;
        _ = descriptor;
        _ = callback;
        _ = userdata;
        @panic("unimplemented");
    }

    pub inline fn adapterReference(adapter_raw: *sysgpu.Adapter) void {
        const adapter: *impl.Adapter = @ptrCast(@alignCast(adapter_raw));
        adapter.manager.reference();
    }

    pub inline fn adapterRelease(adapter_raw: *sysgpu.Adapter) void {
        const adapter: *impl.Adapter = @ptrCast(@alignCast(adapter_raw));
        adapter.manager.release();
    }

    pub inline fn bindGroupSetLabel(bind_group: *sysgpu.BindGroup, label: [*:0]const u8) void {
        _ = bind_group;
        _ = label;
        @panic("unimplemented");
    }

    pub inline fn bindGroupReference(bind_group_raw: *sysgpu.BindGroup) void {
        const bind_group: *impl.BindGroup = @ptrCast(@alignCast(bind_group_raw));
        bind_group.manager.reference();
    }

    pub inline fn bindGroupRelease(bind_group_raw: *sysgpu.BindGroup) void {
        const bind_group: *impl.BindGroup = @ptrCast(@alignCast(bind_group_raw));
        bind_group.manager.release();
    }

    pub inline fn bindGroupLayoutSetLabel(bind_group_layout: *sysgpu.BindGroupLayout, label: [*:0]const u8) void {
        _ = bind_group_layout;
        _ = label;
        @panic("unimplemented");
    }

    pub inline fn bindGroupLayoutReference(bind_group_layout_raw: *sysgpu.BindGroupLayout) void {
        const bind_group_layout: *impl.BindGroupLayout = @ptrCast(@alignCast(bind_group_layout_raw));
        bind_group_layout.manager.reference();
    }

    pub inline fn bindGroupLayoutRelease(bind_group_layout_raw: *sysgpu.BindGroupLayout) void {
        const bind_group_layout: *impl.BindGroupLayout = @ptrCast(@alignCast(bind_group_layout_raw));
        bind_group_layout.manager.release();
    }

    pub inline fn bufferDestroy(buffer: *sysgpu.Buffer) void {
        _ = buffer;
        @panic("unimplemented");
    }

    pub inline fn bufferGetConstMappedRange(buffer_raw: *sysgpu.Buffer, offset: usize, size: usize) ?*const anyopaque {
        const buffer: *impl.Buffer = @ptrCast(@alignCast(buffer_raw));
        return buffer.getMappedRange(offset, size) catch @panic("api error");
    }

    pub inline fn bufferGetMappedRange(buffer_raw: *sysgpu.Buffer, offset: usize, size: usize) ?*anyopaque {
        const buffer: *impl.Buffer = @ptrCast(@alignCast(buffer_raw));
        return buffer.getMappedRange(offset, size) catch @panic("api error");
    }

    pub inline fn bufferGetSize(buffer_raw: *sysgpu.Buffer) u64 {
        const buffer: *impl.Buffer = @ptrCast(@alignCast(buffer_raw));
        return buffer.getSize();
    }

    pub inline fn bufferGetUsage(buffer_raw: *sysgpu.Buffer) sysgpu.Buffer.UsageFlags {
        const buffer: *impl.Buffer = @ptrCast(@alignCast(buffer_raw));
        return buffer.getUsage();
    }

    pub inline fn bufferMapAsync(buffer_raw: *sysgpu.Buffer, mode: sysgpu.MapModeFlags, offset: usize, size: usize, callback: sysgpu.Buffer.MapCallback, userdata: ?*anyopaque) void {
        const buffer: *impl.Buffer = @ptrCast(@alignCast(buffer_raw));
        buffer.mapAsync(mode, offset, size, callback, userdata) catch @panic("api error");
    }

    pub inline fn bufferSetLabel(buffer_raw: *sysgpu.Buffer, label: [*:0]const u8) void {
        const buffer: *impl.Buffer = @ptrCast(@alignCast(buffer_raw));
        buffer.setLabel(label);
    }

    pub inline fn bufferUnmap(buffer_raw: *sysgpu.Buffer) void {
        const buffer: *impl.Buffer = @ptrCast(@alignCast(buffer_raw));
        buffer.unmap() catch @panic("api error");
    }

    pub inline fn bufferReference(buffer_raw: *sysgpu.Buffer) void {
        const buffer: *impl.Buffer = @ptrCast(@alignCast(buffer_raw));
        buffer.manager.reference();
    }

    pub inline fn bufferRelease(buffer_raw: *sysgpu.Buffer) void {
        const buffer: *impl.Buffer = @ptrCast(@alignCast(buffer_raw));
        buffer.manager.release();
    }

    pub inline fn commandBufferSetLabel(command_buffer: *sysgpu.CommandBuffer, label: [*:0]const u8) void {
        _ = command_buffer;
        _ = label;
        @panic("unimplemented");
    }

    pub inline fn commandBufferReference(command_buffer_raw: *sysgpu.CommandBuffer) void {
        const command_buffer: *impl.CommandBuffer = @ptrCast(@alignCast(command_buffer_raw));
        command_buffer.manager.reference();
    }

    pub inline fn commandBufferRelease(command_buffer_raw: *sysgpu.CommandBuffer) void {
        const command_buffer: *impl.CommandBuffer = @ptrCast(@alignCast(command_buffer_raw));
        command_buffer.manager.release();
    }

    pub inline fn commandEncoderBeginComputePass(command_encoder_raw: *sysgpu.CommandEncoder, descriptor: ?*const sysgpu.ComputePassDescriptor) *sysgpu.ComputePassEncoder {
        const command_encoder: *impl.CommandEncoder = @ptrCast(@alignCast(command_encoder_raw));
        const compute_pass = command_encoder.beginComputePass(descriptor orelse &.{}) catch @panic("api error");
        return @ptrCast(compute_pass);
    }

    pub inline fn commandEncoderBeginRenderPass(command_encoder_raw: *sysgpu.CommandEncoder, descriptor: *const sysgpu.RenderPassDescriptor) *sysgpu.RenderPassEncoder {
        const command_encoder: *impl.CommandEncoder = @ptrCast(@alignCast(command_encoder_raw));
        const render_pass = command_encoder.beginRenderPass(descriptor) catch @panic("api error");
        return @ptrCast(render_pass);
    }

    pub inline fn commandEncoderClearBuffer(command_encoder: *sysgpu.CommandEncoder, buffer: *sysgpu.Buffer, offset: u64, size: u64) void {
        _ = command_encoder;
        _ = buffer;
        _ = offset;
        _ = size;
        @panic("unimplemented");
    }

    pub inline fn commandEncoderCopyBufferToBuffer(command_encoder_raw: *sysgpu.CommandEncoder, source_raw: *sysgpu.Buffer, source_offset: u64, destination_raw: *sysgpu.Buffer, destination_offset: u64, size: u64) void {
        const command_encoder: *impl.CommandEncoder = @ptrCast(@alignCast(command_encoder_raw));
        const source: *impl.Buffer = @ptrCast(@alignCast(source_raw));
        const destination: *impl.Buffer = @ptrCast(@alignCast(destination_raw));

        command_encoder.copyBufferToBuffer(source, source_offset, destination, destination_offset, size) catch @panic("api error");
    }

    pub inline fn commandEncoderCopyBufferToTexture(command_encoder_raw: *sysgpu.CommandEncoder, source: *const sysgpu.ImageCopyBuffer, destination: *const sysgpu.ImageCopyTexture, copy_size: *const sysgpu.Extent3D) void {
        const command_encoder: *impl.CommandEncoder = @ptrCast(@alignCast(command_encoder_raw));
        command_encoder.copyBufferToTexture(source, destination, copy_size) catch @panic("api error");
    }

    pub inline fn commandEncoderCopyTextureToBuffer(command_encoder: *sysgpu.CommandEncoder, source: *const sysgpu.ImageCopyTexture, destination: *const sysgpu.ImageCopyBuffer, copy_size: *const sysgpu.Extent3D) void {
        _ = command_encoder;
        _ = source;
        _ = destination;
        _ = copy_size;
        @panic("unimplemented");
    }

    pub inline fn commandEncoderCopyTextureToTexture(command_encoder_raw: *sysgpu.CommandEncoder, source: *const sysgpu.ImageCopyTexture, destination: *const sysgpu.ImageCopyTexture, copy_size: *const sysgpu.Extent3D) void {
        const command_encoder: *impl.CommandEncoder = @ptrCast(@alignCast(command_encoder_raw));
        command_encoder.copyTextureToTexture(source, destination, copy_size) catch @panic("api error");
    }

    pub inline fn commandEncoderCopyTextureToTextureInternal(command_encoder: *sysgpu.CommandEncoder, source: *const sysgpu.ImageCopyTexture, destination: *const sysgpu.ImageCopyTexture, copy_size: *const sysgpu.Extent3D) void {
        _ = command_encoder;
        _ = source;
        _ = destination;
        _ = copy_size;
        @panic("unimplemented");
    }

    pub inline fn commandEncoderFinish(command_encoder_raw: *sysgpu.CommandEncoder, descriptor: ?*const sysgpu.CommandBuffer.Descriptor) *sysgpu.CommandBuffer {
        const command_encoder: *impl.CommandEncoder = @ptrCast(@alignCast(command_encoder_raw));
        const command_buffer = command_encoder.finish(descriptor orelse &.{}) catch @panic("api error");
        command_buffer.manager.reference();
        return @ptrCast(command_buffer);
    }

    pub inline fn commandEncoderInjectValidationError(command_encoder: *sysgpu.CommandEncoder, message: [*:0]const u8) void {
        _ = command_encoder;
        _ = message;
        @panic("unimplemented");
    }

    pub inline fn commandEncoderInsertDebugMarker(command_encoder: *sysgpu.CommandEncoder, marker_label: [*:0]const u8) void {
        _ = command_encoder;
        _ = marker_label;
        @panic("unimplemented");
    }

    pub inline fn commandEncoderPopDebugGroup(command_encoder: *sysgpu.CommandEncoder) void {
        _ = command_encoder;
        @panic("unimplemented");
    }

    pub inline fn commandEncoderPushDebugGroup(command_encoder: *sysgpu.CommandEncoder, group_label: [*:0]const u8) void {
        _ = command_encoder;
        _ = group_label;
        @panic("unimplemented");
    }

    pub inline fn commandEncoderResolveQuerySet(command_encoder: *sysgpu.CommandEncoder, query_set: *sysgpu.QuerySet, first_query: u32, query_count: u32, destination: *sysgpu.Buffer, destination_offset: u64) void {
        _ = command_encoder;
        _ = query_set;
        _ = first_query;
        _ = query_count;
        _ = destination;
        _ = destination_offset;
        @panic("unimplemented");
    }

    pub inline fn commandEncoderSetLabel(command_encoder: *sysgpu.CommandEncoder, label: [*:0]const u8) void {
        _ = command_encoder;
        _ = label;
        @panic("unimplemented");
    }

    pub inline fn commandEncoderWriteBuffer(command_encoder_raw: *sysgpu.CommandEncoder, buffer_raw: *sysgpu.Buffer, buffer_offset: u64, data: [*]const u8, size: u64) void {
        const command_encoder: *impl.CommandEncoder = @ptrCast(@alignCast(command_encoder_raw));
        const buffer: *impl.Buffer = @ptrCast(@alignCast(buffer_raw));
        command_encoder.writeBuffer(buffer, buffer_offset, @ptrCast(data), size) catch @panic("api error");
    }

    pub inline fn commandEncoderWriteTimestamp(command_encoder: *sysgpu.CommandEncoder, query_set: *sysgpu.QuerySet, query_index: u32) void {
        _ = command_encoder;
        _ = query_set;
        _ = query_index;
        @panic("unimplemented");
    }

    pub inline fn commandEncoderReference(command_encoder_raw: *sysgpu.CommandEncoder) void {
        const command_encoder: *impl.CommandEncoder = @ptrCast(@alignCast(command_encoder_raw));
        command_encoder.manager.reference();
    }

    pub inline fn commandEncoderRelease(command_encoder_raw: *sysgpu.CommandEncoder) void {
        const command_encoder: *impl.CommandEncoder = @ptrCast(@alignCast(command_encoder_raw));
        command_encoder.manager.release();
    }

    pub inline fn computePassEncoderDispatchWorkgroups(compute_pass_encoder_raw: *sysgpu.ComputePassEncoder, workgroup_count_x: u32, workgroup_count_y: u32, workgroup_count_z: u32) void {
        const compute_pass_encoder: *impl.ComputePassEncoder = @ptrCast(@alignCast(compute_pass_encoder_raw));
        compute_pass_encoder.dispatchWorkgroups(workgroup_count_x, workgroup_count_y, workgroup_count_z) catch @panic("api error");
    }

    pub inline fn computePassEncoderDispatchWorkgroupsIndirect(compute_pass_encoder: *sysgpu.ComputePassEncoder, indirect_buffer: *sysgpu.Buffer, indirect_offset: u64) void {
        _ = compute_pass_encoder;
        _ = indirect_buffer;
        _ = indirect_offset;
        @panic("unimplemented");
    }

    pub inline fn computePassEncoderEnd(compute_pass_encoder_raw: *sysgpu.ComputePassEncoder) void {
        const compute_pass_encoder: *impl.ComputePassEncoder = @ptrCast(@alignCast(compute_pass_encoder_raw));
        compute_pass_encoder.end();
    }

    pub inline fn computePassEncoderInsertDebugMarker(compute_pass_encoder: *sysgpu.ComputePassEncoder, marker_label: [*:0]const u8) void {
        _ = compute_pass_encoder;
        _ = marker_label;
        @panic("unimplemented");
    }

    pub inline fn computePassEncoderPopDebugGroup(compute_pass_encoder: *sysgpu.ComputePassEncoder) void {
        _ = compute_pass_encoder;
        @panic("unimplemented");
    }

    pub inline fn computePassEncoderPushDebugGroup(compute_pass_encoder: *sysgpu.ComputePassEncoder, group_label: [*:0]const u8) void {
        _ = compute_pass_encoder;
        _ = group_label;
        @panic("unimplemented");
    }

    pub inline fn computePassEncoderSetBindGroup(compute_pass_encoder_raw: *sysgpu.ComputePassEncoder, group_index: u32, group_raw: *sysgpu.BindGroup, dynamic_offset_count: usize, dynamic_offsets: ?[*]const u32) void {
        const compute_pass_encoder: *impl.ComputePassEncoder = @ptrCast(@alignCast(compute_pass_encoder_raw));
        const group: *impl.BindGroup = @ptrCast(@alignCast(group_raw));
        compute_pass_encoder.setBindGroup(group_index, group, dynamic_offset_count, dynamic_offsets) catch @panic("api error");
    }

    pub inline fn computePassEncoderSetLabel(compute_pass_encoder: *sysgpu.ComputePassEncoder, label: [*:0]const u8) void {
        _ = compute_pass_encoder;
        _ = label;
        @panic("unimplemented");
    }

    pub inline fn computePassEncoderSetPipeline(compute_pass_encoder_raw: *sysgpu.ComputePassEncoder, pipeline_raw: *sysgpu.ComputePipeline) void {
        const compute_pass_encoder: *impl.ComputePassEncoder = @ptrCast(@alignCast(compute_pass_encoder_raw));
        const pipeline: *impl.ComputePipeline = @ptrCast(@alignCast(pipeline_raw));
        compute_pass_encoder.setPipeline(pipeline) catch @panic("api error");
    }

    pub inline fn computePassEncoderWriteTimestamp(compute_pass_encoder: *sysgpu.ComputePassEncoder, query_set: *sysgpu.QuerySet, query_index: u32) void {
        _ = compute_pass_encoder;
        _ = query_set;
        _ = query_index;
        @panic("unimplemented");
    }

    pub inline fn computePassEncoderReference(compute_pass_encoder_raw: *sysgpu.ComputePassEncoder) void {
        const compute_pass_encoder: *impl.ComputePassEncoder = @ptrCast(@alignCast(compute_pass_encoder_raw));
        compute_pass_encoder.manager.reference();
    }

    pub inline fn computePassEncoderRelease(compute_pass_encoder_raw: *sysgpu.ComputePassEncoder) void {
        const compute_pass_encoder: *impl.ComputePassEncoder = @ptrCast(@alignCast(compute_pass_encoder_raw));
        compute_pass_encoder.manager.release();
    }

    pub inline fn computePipelineGetBindGroupLayout(compute_pipeline_raw: *sysgpu.ComputePipeline, group_index: u32) *sysgpu.BindGroupLayout {
        const compute_pipeline: *impl.ComputePipeline = @ptrCast(@alignCast(compute_pipeline_raw));
        const layout = compute_pipeline.getBindGroupLayout(group_index);
        layout.manager.reference();
        return @ptrCast(layout);
    }

    pub inline fn computePipelineSetLabel(compute_pipeline: *sysgpu.ComputePipeline, label: [*:0]const u8) void {
        _ = compute_pipeline;
        _ = label;
        @panic("unimplemented");
    }

    pub inline fn computePipelineReference(compute_pipeline_raw: *sysgpu.ComputePipeline) void {
        const compute_pipeline: *impl.ComputePipeline = @ptrCast(@alignCast(compute_pipeline_raw));
        compute_pipeline.manager.reference();
    }

    pub inline fn computePipelineRelease(compute_pipeline_raw: *sysgpu.ComputePipeline) void {
        const compute_pipeline: *impl.ComputePipeline = @ptrCast(@alignCast(compute_pipeline_raw));
        compute_pipeline.manager.release();
    }

    pub inline fn deviceCreateBindGroup(device_raw: *sysgpu.Device, descriptor: *const sysgpu.BindGroup.Descriptor) *sysgpu.BindGroup {
        const device: *impl.Device = @ptrCast(@alignCast(device_raw));
        const group = device.createBindGroup(descriptor) catch @panic("api error");
        return @ptrCast(group);
    }

    pub inline fn deviceCreateBindGroupLayout(device_raw: *sysgpu.Device, descriptor: *const sysgpu.BindGroupLayout.Descriptor) *sysgpu.BindGroupLayout {
        const device: *impl.Device = @ptrCast(@alignCast(device_raw));
        const layout = device.createBindGroupLayout(descriptor) catch @panic("api error");
        return @ptrCast(layout);
    }

    pub inline fn deviceCreateBuffer(device_raw: *sysgpu.Device, descriptor: *const sysgpu.Buffer.Descriptor) *sysgpu.Buffer {
        const device: *impl.Device = @ptrCast(@alignCast(device_raw));
        const buffer = device.createBuffer(descriptor) catch @panic("api error");
        return @ptrCast(buffer);
    }

    pub inline fn deviceCreateCommandEncoder(device_raw: *sysgpu.Device, descriptor: ?*const sysgpu.CommandEncoder.Descriptor) *sysgpu.CommandEncoder {
        const device: *impl.Device = @ptrCast(@alignCast(device_raw));
        const command_encoder = device.createCommandEncoder(descriptor orelse &.{}) catch @panic("api error");
        return @ptrCast(command_encoder);
    }

    pub inline fn deviceCreateComputePipeline(device_raw: *sysgpu.Device, descriptor: *const sysgpu.ComputePipeline.Descriptor) *sysgpu.ComputePipeline {
        const device: *impl.Device = @ptrCast(@alignCast(device_raw));
        const pipeline = device.createComputePipeline(descriptor) catch @panic("api error");
        return @ptrCast(pipeline);
    }

    pub inline fn deviceCreateComputePipelineAsync(device: *sysgpu.Device, descriptor: *const sysgpu.ComputePipeline.Descriptor, callback: sysgpu.CreateComputePipelineAsyncCallback, userdata: ?*anyopaque) void {
        _ = device;
        _ = descriptor;
        _ = callback;
        _ = userdata;
        @panic("unimplemented");
    }

    pub inline fn deviceCreateErrorBuffer(device: *sysgpu.Device, descriptor: *const sysgpu.Buffer.Descriptor) *sysgpu.Buffer {
        _ = device;
        _ = descriptor;
        @panic("unimplemented");
    }

    pub inline fn deviceCreateErrorExternalTexture(device: *sysgpu.Device) *sysgpu.ExternalTexture {
        _ = device;
        @panic("unimplemented");
    }

    pub inline fn deviceCreateErrorTexture(device: *sysgpu.Device, descriptor: *const sysgpu.Texture.Descriptor) *sysgpu.Texture {
        _ = device;
        _ = descriptor;
        @panic("unimplemented");
    }

    pub inline fn deviceCreateExternalTexture(device: *sysgpu.Device, external_texture_descriptor: *const sysgpu.ExternalTexture.Descriptor) *sysgpu.ExternalTexture {
        _ = device;
        _ = external_texture_descriptor;
        @panic("unimplemented");
    }

    pub inline fn deviceCreatePipelineLayout(device_raw: *sysgpu.Device, pipeline_layout_descriptor: *const sysgpu.PipelineLayout.Descriptor) *sysgpu.PipelineLayout {
        const device: *impl.Device = @ptrCast(@alignCast(device_raw));
        const layout = device.createPipelineLayout(pipeline_layout_descriptor) catch @panic("api error");
        return @ptrCast(layout);
    }

    pub inline fn deviceCreateQuerySet(device: *sysgpu.Device, descriptor: *const sysgpu.QuerySet.Descriptor) *sysgpu.QuerySet {
        _ = device;
        _ = descriptor;
        @panic("unimplemented");
    }

    pub inline fn deviceCreateRenderBundleEncoder(device: *sysgpu.Device, descriptor: *const sysgpu.RenderBundleEncoder.Descriptor) *sysgpu.RenderBundleEncoder {
        _ = device;
        _ = descriptor;
        @panic("unimplemented");
    }

    pub inline fn deviceCreateRenderPipeline(device_raw: *sysgpu.Device, descriptor: *const sysgpu.RenderPipeline.Descriptor) *sysgpu.RenderPipeline {
        const device: *impl.Device = @ptrCast(@alignCast(device_raw));
        const render_pipeline = device.createRenderPipeline(descriptor) catch @panic("api error");
        return @ptrCast(render_pipeline);
    }

    pub inline fn deviceCreateRenderPipelineAsync(device: *sysgpu.Device, descriptor: *const sysgpu.RenderPipeline.Descriptor, callback: sysgpu.CreateRenderPipelineAsyncCallback, userdata: ?*anyopaque) void {
        _ = device;
        _ = descriptor;
        _ = callback;
        _ = userdata;
        @panic("unimplemented");
    }

    pub inline fn deviceCreateSampler(device_raw: *sysgpu.Device, descriptor: ?*const sysgpu.Sampler.Descriptor) *sysgpu.Sampler {
        const device: *impl.Device = @ptrCast(@alignCast(device_raw));
        const sampler = device.createSampler(descriptor orelse &sysgpu.Sampler.Descriptor{}) catch @panic("api error");
        return @ptrCast(sampler);
    }

    pub inline fn deviceCreateShaderModule(device_raw: *sysgpu.Device, descriptor: *const sysgpu.ShaderModule.Descriptor) *sysgpu.ShaderModule {
        const device: *impl.Device = @ptrCast(@alignCast(device_raw));

        var errors = try shader.ErrorList.init(allocator);
        defer errors.deinit();
        if (utils.findChained(sysgpu.ShaderModule.WGSLDescriptor, descriptor.next_in_chain.generic)) |wgsl_descriptor| {
            const source = std.mem.span(wgsl_descriptor.code);

            var ast = shader.Ast.parse(allocator, &errors, source) catch |err| switch (err) {
                error.Parsing => {
                    errors.print(source, null) catch @panic("api error");
                    std.process.exit(1);
                },
                else => @panic("api error"),
            };
            defer ast.deinit(allocator);

            const air = allocator.create(shader.Air) catch @panic("api error");
            air.* = shader.Air.generate(allocator, &ast, &errors, null) catch |err| switch (err) {
                error.AnalysisFail => {
                    errors.print(source, null) catch @panic("api error");
                    std.process.exit(1);
                },
                else => @panic("api error"),
            };

            const shader_module = device.createShaderModuleAir(air, descriptor.label orelse "<ShaderModule label not specified>") catch @panic("api error");
            return @ptrCast(shader_module);
        } else if (utils.findChained(sysgpu.ShaderModule.SPIRVDescriptor, descriptor.next_in_chain.generic)) |spirv_descriptor| {
            const shader_module = device.createShaderModuleSpirv(spirv_descriptor.code, spirv_descriptor.code_size) catch @panic("api error");
            return @ptrCast(shader_module);
        } else if (utils.findChained(sysgpu.ShaderModule.HLSLDescriptor, descriptor.next_in_chain.generic)) |hlsl_descriptor| {
            const shader_module = device.createShaderModuleHLSL(hlsl_descriptor.code[0..hlsl_descriptor.code_size]) catch @panic("api error");
            return @ptrCast(shader_module);
        } else if (utils.findChained(sysgpu.ShaderModule.MSLDescriptor, descriptor.next_in_chain.generic)) |msl_descriptor| {
            const shader_module = device.createShaderModuleMSL(
                descriptor.label orelse "<ShaderModule label not specified>",
                msl_descriptor.code[0..msl_descriptor.code_size],
                msl_descriptor.workgroup_size,
            ) catch @panic("api error");
            return @ptrCast(shader_module);
        }

        @panic("unimplemented");
    }

    pub inline fn deviceCreateSwapChain(device_raw: *sysgpu.Device, surface_raw: ?*sysgpu.Surface, descriptor: *const sysgpu.SwapChain.Descriptor) *sysgpu.SwapChain {
        const device: *impl.Device = @ptrCast(@alignCast(device_raw));
        const surface: *impl.Surface = @ptrCast(@alignCast(surface_raw.?));
        const swapchain = device.createSwapChain(surface, descriptor) catch @panic("api error");
        return @ptrCast(swapchain);
    }

    pub inline fn deviceCreateTexture(device_raw: *sysgpu.Device, descriptor: *const sysgpu.Texture.Descriptor) *sysgpu.Texture {
        const device: *impl.Device = @ptrCast(@alignCast(device_raw));
        const texture = device.createTexture(descriptor) catch @panic("api error");
        return @ptrCast(texture);
    }

    pub inline fn deviceDestroy(device: *sysgpu.Device) void {
        _ = device;
        @panic("unimplemented");
    }

    pub inline fn deviceEnumerateFeatures(device: *sysgpu.Device, features: ?[*]sysgpu.FeatureName) usize {
        _ = device;
        _ = features;
        @panic("unimplemented");
    }

    pub inline fn deviceGetLimits(device: *sysgpu.Device, limits: *sysgpu.SupportedLimits) u32 {
        _ = device;
        _ = limits;
        @panic("unimplemented");
    }

    pub inline fn deviceGetQueue(device_raw: *sysgpu.Device) *sysgpu.Queue {
        const device: *impl.Device = @ptrCast(@alignCast(device_raw));
        const queue = device.getQueue() catch @panic("api error");
        queue.manager.reference();
        return @ptrCast(queue);
    }

    pub inline fn deviceHasFeature(device: *sysgpu.Device, feature: sysgpu.FeatureName) u32 {
        _ = device;
        _ = feature;
        @panic("unimplemented");
    }

    pub inline fn deviceImportSharedFence(device: *sysgpu.Device, descriptor: *const sysgpu.SharedFence.Descriptor) *sysgpu.SharedFence {
        _ = device;
        _ = descriptor;
        @panic("unimplemented");
    }

    pub inline fn deviceImportSharedTextureMemory(device: *sysgpu.Device, descriptor: *const sysgpu.SharedTextureMemory.Descriptor) *sysgpu.SharedTextureMemory {
        _ = device;
        _ = descriptor;
        @panic("unimplemented");
    }

    pub inline fn deviceInjectError(device: *sysgpu.Device, typ: sysgpu.ErrorType, message: [*:0]const u8) void {
        _ = device;
        _ = typ;
        _ = message;
        @panic("unimplemented");
    }

    pub inline fn deviceLoseForTesting(device: *sysgpu.Device) void {
        _ = device;
        @panic("unimplemented");
    }

    pub inline fn devicePopErrorScope(device: *sysgpu.Device, callback: sysgpu.ErrorCallback, userdata: ?*anyopaque) void {
        _ = device;
        _ = callback;
        _ = userdata;
        @panic("unimplemented");
    }

    pub inline fn devicePushErrorScope(device: *sysgpu.Device, filter: sysgpu.ErrorFilter) void {
        _ = device;
        _ = filter;
        @panic("unimplemented");
    }

    pub inline fn deviceSetDeviceLostCallback(device_raw: *sysgpu.Device, callback: ?sysgpu.Device.LostCallback, userdata: ?*anyopaque) void {
        const device: *impl.Device = @ptrCast(@alignCast(device_raw));
        device.lost_cb = callback;
        device.lost_cb_userdata = userdata;
    }

    pub inline fn deviceSetLabel(device: *sysgpu.Device, label: [*:0]const u8) void {
        _ = device;
        _ = label;
        @panic("unimplemented");
    }

    pub inline fn deviceSetLoggingCallback(device_raw: *sysgpu.Device, callback: ?sysgpu.LoggingCallback, userdata: ?*anyopaque) void {
        const device: *impl.Device = @ptrCast(@alignCast(device_raw));
        device.log_cb = callback;
        device.log_cb_userdata = userdata;
    }

    pub inline fn deviceSetUncapturedErrorCallback(device_raw: *sysgpu.Device, callback: ?sysgpu.ErrorCallback, userdata: ?*anyopaque) void {
        const device: *impl.Device = @ptrCast(@alignCast(device_raw));
        device.err_cb = callback;
        device.err_cb_userdata = userdata;
    }

    pub inline fn deviceTick(device_raw: *sysgpu.Device) void {
        const device: *impl.Device = @ptrCast(@alignCast(device_raw));
        device.tick() catch @panic("api error");
    }

    pub inline fn machDeviceWaitForCommandsToBeScheduled(device: *sysgpu.Device) void {
        _ = device;
    }

    pub inline fn deviceReference(device_raw: *sysgpu.Device) void {
        const device: *impl.Device = @ptrCast(@alignCast(device_raw));
        device.manager.reference();
    }

    pub inline fn deviceRelease(device_raw: *sysgpu.Device) void {
        const device: *impl.Device = @ptrCast(@alignCast(device_raw));
        device.manager.release();
    }

    pub inline fn externalTextureDestroy(external_texture: *sysgpu.ExternalTexture) void {
        _ = external_texture;
        @panic("unimplemented");
    }

    pub inline fn externalTextureSetLabel(external_texture: *sysgpu.ExternalTexture, label: [*:0]const u8) void {
        _ = external_texture;
        _ = label;
        @panic("unimplemented");
    }

    pub inline fn externalTextureReference(external_texture: *sysgpu.ExternalTexture) void {
        _ = external_texture;
        @panic("unimplemented");
    }

    pub inline fn externalTextureRelease(external_texture: *sysgpu.ExternalTexture) void {
        _ = external_texture;
        @panic("unimplemented");
    }

    pub inline fn instanceCreateSurface(instance_raw: *sysgpu.Instance, descriptor: *const sysgpu.Surface.Descriptor) *sysgpu.Surface {
        const instance: *impl.Instance = @ptrCast(@alignCast(instance_raw));
        const surface = instance.createSurface(descriptor) catch @panic("api error");
        return @ptrCast(surface);
    }

    pub inline fn instanceProcessEvents(instance: *sysgpu.Instance) void {
        _ = instance;
        @panic("unimplemented");
    }

    pub inline fn instanceRequestAdapter(
        instance_raw: *sysgpu.Instance,
        options: ?*const sysgpu.RequestAdapterOptions,
        callback: sysgpu.RequestAdapterCallback,
        userdata: ?*anyopaque,
    ) void {
        const instance: *impl.Instance = @ptrCast(@alignCast(instance_raw));
        const adapter = impl.Adapter.init(instance, options orelse &sysgpu.RequestAdapterOptions{}) catch |err| {
            return callback(.err, undefined, @errorName(err), userdata);
        };
        callback(.success, @as(*sysgpu.Adapter, @ptrCast(adapter)), null, userdata);
    }

    pub inline fn instanceReference(instance_raw: *sysgpu.Instance) void {
        const instance: *impl.Instance = @ptrCast(@alignCast(instance_raw));
        instance.manager.reference();
    }

    pub inline fn instanceRelease(instance_raw: *sysgpu.Instance) void {
        const instance: *impl.Instance = @ptrCast(@alignCast(instance_raw));
        instance.manager.release();
    }

    pub inline fn pipelineLayoutSetLabel(pipeline_layout: *sysgpu.PipelineLayout, label: [*:0]const u8) void {
        _ = pipeline_layout;
        _ = label;
        @panic("unimplemented");
    }

    pub inline fn pipelineLayoutReference(pipeline_layout_raw: *sysgpu.PipelineLayout) void {
        const pipeline_layout: *impl.PipelineLayout = @ptrCast(@alignCast(pipeline_layout_raw));
        pipeline_layout.manager.reference();
    }

    pub inline fn pipelineLayoutRelease(pipeline_layout_raw: *sysgpu.PipelineLayout) void {
        const pipeline_layout: *impl.PipelineLayout = @ptrCast(@alignCast(pipeline_layout_raw));
        pipeline_layout.manager.release();
    }

    pub inline fn querySetDestroy(query_set: *sysgpu.QuerySet) void {
        _ = query_set;
        @panic("unimplemented");
    }

    pub inline fn querySetGetCount(query_set: *sysgpu.QuerySet) u32 {
        _ = query_set;
        @panic("unimplemented");
    }

    pub inline fn querySetGetType(query_set: *sysgpu.QuerySet) sysgpu.QueryType {
        _ = query_set;
        @panic("unimplemented");
    }

    pub inline fn querySetSetLabel(query_set: *sysgpu.QuerySet, label: [*:0]const u8) void {
        _ = query_set;
        _ = label;
        @panic("unimplemented");
    }

    pub inline fn querySetReference(query_set: *sysgpu.QuerySet) void {
        _ = query_set;
        @panic("unimplemented");
    }

    pub inline fn querySetRelease(query_set: *sysgpu.QuerySet) void {
        _ = query_set;
        @panic("unimplemented");
    }

    pub inline fn queueCopyTextureForBrowser(queue: *sysgpu.Queue, source: *const sysgpu.ImageCopyTexture, destination: *const sysgpu.ImageCopyTexture, copy_size: *const sysgpu.Extent3D, options: *const sysgpu.CopyTextureForBrowserOptions) void {
        _ = queue;
        _ = source;
        _ = destination;
        _ = copy_size;
        _ = options;
        @panic("unimplemented");
    }

    pub inline fn queueOnSubmittedWorkDone(queue: *sysgpu.Queue, signal_value: u64, callback: sysgpu.Queue.WorkDoneCallback, userdata: ?*anyopaque) void {
        _ = queue;
        _ = signal_value;
        _ = callback;
        _ = userdata;
        @panic("unimplemented");
    }

    pub inline fn queueSetLabel(queue: *sysgpu.Queue, label: [*:0]const u8) void {
        _ = queue;
        _ = label;
        @panic("unimplemented");
    }

    pub inline fn queueSubmit(queue_raw: *sysgpu.Queue, command_count: usize, commands_raw: [*]const *const sysgpu.CommandBuffer) void {
        const queue: *impl.Queue = @ptrCast(@alignCast(queue_raw));
        const commands: []const *impl.CommandBuffer = @ptrCast(commands_raw[0..command_count]);
        queue.submit(commands) catch @panic("api error");
    }

    pub inline fn queueWriteBuffer(queue_raw: *sysgpu.Queue, buffer_raw: *sysgpu.Buffer, buffer_offset: u64, data: *const anyopaque, size: usize) void {
        const queue: *impl.Queue = @ptrCast(@alignCast(queue_raw));
        const buffer: *impl.Buffer = @ptrCast(@alignCast(buffer_raw));
        queue.writeBuffer(buffer, buffer_offset, @ptrCast(data), size) catch @panic("api error");
    }

    pub inline fn queueWriteTexture(queue_raw: *sysgpu.Queue, destination: *const sysgpu.ImageCopyTexture, data: *const anyopaque, data_size: usize, data_layout: *const sysgpu.Texture.DataLayout, write_size: *const sysgpu.Extent3D) void {
        const queue: *impl.Queue = @ptrCast(@alignCast(queue_raw));
        queue.writeTexture(destination, @ptrCast(data), data_size, data_layout, write_size) catch @panic("api error");
    }

    pub inline fn queueReference(queue_raw: *sysgpu.Queue) void {
        const queue: *impl.Queue = @ptrCast(@alignCast(queue_raw));
        queue.manager.reference();
    }

    pub inline fn queueRelease(queue_raw: *sysgpu.Queue) void {
        const queue: *impl.Queue = @ptrCast(@alignCast(queue_raw));
        queue.manager.release();
    }

    pub inline fn renderBundleReference(render_bundle: *sysgpu.RenderBundle) void {
        _ = render_bundle;
        @panic("unimplemented");
    }

    pub inline fn renderBundleRelease(render_bundle: *sysgpu.RenderBundle) void {
        _ = render_bundle;
        @panic("unimplemented");
    }

    pub inline fn renderBundleSetLabel(render_bundle: *sysgpu.RenderBundle, name: [*:0]const u8) void {
        _ = name;
        _ = render_bundle;
        @panic("unimplemented");
    }

    pub inline fn renderBundleEncoderDraw(render_bundle_encoder: *sysgpu.RenderBundleEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {
        _ = render_bundle_encoder;
        _ = vertex_count;
        _ = instance_count;
        _ = first_vertex;
        _ = first_instance;
        @panic("unimplemented");
    }

    pub inline fn renderBundleEncoderDrawIndexed(render_bundle_encoder: *sysgpu.RenderBundleEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: i32, first_instance: u32) void {
        _ = render_bundle_encoder;
        _ = index_count;
        _ = instance_count;
        _ = first_index;
        _ = base_vertex;
        _ = first_instance;
        @panic("unimplemented");
    }

    pub inline fn renderBundleEncoderDrawIndexedIndirect(render_bundle_encoder: *sysgpu.RenderBundleEncoder, indirect_buffer: *sysgpu.Buffer, indirect_offset: u64) void {
        _ = render_bundle_encoder;
        _ = indirect_buffer;
        _ = indirect_offset;
        @panic("unimplemented");
    }

    pub inline fn renderBundleEncoderDrawIndirect(render_bundle_encoder: *sysgpu.RenderBundleEncoder, indirect_buffer: *sysgpu.Buffer, indirect_offset: u64) void {
        _ = render_bundle_encoder;
        _ = indirect_buffer;
        _ = indirect_offset;
        @panic("unimplemented");
    }

    pub inline fn renderBundleEncoderFinish(render_bundle_encoder: *sysgpu.RenderBundleEncoder, descriptor: ?*const sysgpu.RenderBundle.Descriptor) *sysgpu.RenderBundle {
        _ = render_bundle_encoder;
        _ = descriptor;
        @panic("unimplemented");
    }

    pub inline fn renderBundleEncoderInsertDebugMarker(render_bundle_encoder: *sysgpu.RenderBundleEncoder, marker_label: [*:0]const u8) void {
        _ = render_bundle_encoder;
        _ = marker_label;
        @panic("unimplemented");
    }

    pub inline fn renderBundleEncoderPopDebugGroup(render_bundle_encoder: *sysgpu.RenderBundleEncoder) void {
        _ = render_bundle_encoder;
        @panic("unimplemented");
    }

    pub inline fn renderBundleEncoderPushDebugGroup(render_bundle_encoder: *sysgpu.RenderBundleEncoder, group_label: [*:0]const u8) void {
        _ = render_bundle_encoder;
        _ = group_label;
        @panic("unimplemented");
    }

    pub inline fn renderBundleEncoderSetBindGroup(render_bundle_encoder: *sysgpu.RenderBundleEncoder, group_index: u32, group: *sysgpu.BindGroup, dynamic_offset_count: usize, dynamic_offsets: ?[*]const u32) void {
        _ = render_bundle_encoder;
        _ = group_index;
        _ = group;
        _ = dynamic_offset_count;
        _ = dynamic_offsets;
        @panic("unimplemented");
    }

    pub inline fn renderBundleEncoderSetIndexBuffer(render_bundle_encoder: *sysgpu.RenderBundleEncoder, buffer: *sysgpu.Buffer, format: sysgpu.IndexFormat, offset: u64, size: u64) void {
        _ = render_bundle_encoder;
        _ = buffer;
        _ = format;
        _ = offset;
        _ = size;
        @panic("unimplemented");
    }

    pub inline fn renderBundleEncoderSetLabel(render_bundle_encoder: *sysgpu.RenderBundleEncoder, label: [*:0]const u8) void {
        _ = render_bundle_encoder;
        _ = label;
        @panic("unimplemented");
    }

    pub inline fn renderBundleEncoderSetPipeline(render_bundle_encoder: *sysgpu.RenderBundleEncoder, pipeline: *sysgpu.RenderPipeline) void {
        _ = render_bundle_encoder;
        _ = pipeline;
        @panic("unimplemented");
    }

    pub inline fn renderBundleEncoderSetVertexBuffer(render_bundle_encoder: *sysgpu.RenderBundleEncoder, slot: u32, buffer: *sysgpu.Buffer, offset: u64, size: u64) void {
        _ = render_bundle_encoder;
        _ = slot;
        _ = buffer;
        _ = offset;
        _ = size;
        @panic("unimplemented");
    }

    pub inline fn renderBundleEncoderReference(render_bundle_encoder: *sysgpu.RenderBundleEncoder) void {
        _ = render_bundle_encoder;
        @panic("unimplemented");
    }

    pub inline fn renderBundleEncoderRelease(render_bundle_encoder: *sysgpu.RenderBundleEncoder) void {
        _ = render_bundle_encoder;
        @panic("unimplemented");
    }

    pub inline fn renderPassEncoderBeginOcclusionQuery(render_pass_encoder: *sysgpu.RenderPassEncoder, query_index: u32) void {
        _ = render_pass_encoder;
        _ = query_index;
        @panic("unimplemented");
    }

    pub inline fn renderPassEncoderDraw(render_pass_encoder_raw: *sysgpu.RenderPassEncoder, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {
        const render_pass_encoder: *impl.RenderPassEncoder = @ptrCast(@alignCast(render_pass_encoder_raw));
        render_pass_encoder.draw(vertex_count, instance_count, first_vertex, first_instance) catch @panic("api error");
    }

    pub inline fn renderPassEncoderDrawIndexed(render_pass_encoder_raw: *sysgpu.RenderPassEncoder, index_count: u32, instance_count: u32, first_index: u32, base_vertex: i32, first_instance: u32) void {
        const render_pass_encoder: *impl.RenderPassEncoder = @ptrCast(@alignCast(render_pass_encoder_raw));
        render_pass_encoder.drawIndexed(index_count, instance_count, first_index, base_vertex, first_instance) catch @panic("api error");
    }

    pub inline fn renderPassEncoderDrawIndexedIndirect(render_pass_encoder: *sysgpu.RenderPassEncoder, indirect_buffer: *sysgpu.Buffer, indirect_offset: u64) void {
        _ = render_pass_encoder;
        _ = indirect_buffer;
        _ = indirect_offset;
        @panic("unimplemented");
    }

    pub inline fn renderPassEncoderDrawIndirect(render_pass_encoder: *sysgpu.RenderPassEncoder, indirect_buffer: *sysgpu.Buffer, indirect_offset: u64) void {
        _ = render_pass_encoder;
        _ = indirect_buffer;
        _ = indirect_offset;
        @panic("unimplemented");
    }

    pub inline fn renderPassEncoderEnd(render_pass_encoder_raw: *sysgpu.RenderPassEncoder) void {
        const render_pass_encoder: *impl.RenderPassEncoder = @ptrCast(@alignCast(render_pass_encoder_raw));
        render_pass_encoder.end() catch @panic("api error");
    }

    pub inline fn renderPassEncoderEndOcclusionQuery(render_pass_encoder: *sysgpu.RenderPassEncoder) void {
        _ = render_pass_encoder;
        @panic("unimplemented");
    }

    pub inline fn renderPassEncoderExecuteBundles(render_pass_encoder: *sysgpu.RenderPassEncoder, bundles_count: usize, bundles: [*]const *const sysgpu.RenderBundle) void {
        _ = render_pass_encoder;
        _ = bundles_count;
        _ = bundles;
        @panic("unimplemented");
    }

    pub inline fn renderPassEncoderInsertDebugMarker(render_pass_encoder: *sysgpu.RenderPassEncoder, marker_label: [*:0]const u8) void {
        _ = render_pass_encoder;
        _ = marker_label;
        @panic("unimplemented");
    }

    pub inline fn renderPassEncoderPopDebugGroup(render_pass_encoder: *sysgpu.RenderPassEncoder) void {
        _ = render_pass_encoder;
        @panic("unimplemented");
    }

    pub inline fn renderPassEncoderPushDebugGroup(render_pass_encoder: *sysgpu.RenderPassEncoder, group_label: [*:0]const u8) void {
        _ = render_pass_encoder;
        _ = group_label;
        @panic("unimplemented");
    }

    pub inline fn renderPassEncoderSetBindGroup(
        render_pass_encoder_raw: *sysgpu.RenderPassEncoder,
        group_index: u32,
        group_raw: *sysgpu.BindGroup,
        dynamic_offset_count: usize,
        dynamic_offsets: ?[*]const u32,
    ) void {
        const render_pass_encoder: *impl.RenderPassEncoder = @ptrCast(@alignCast(render_pass_encoder_raw));
        const group: *impl.BindGroup = @ptrCast(@alignCast(group_raw));
        render_pass_encoder.setBindGroup(group_index, group, dynamic_offset_count, dynamic_offsets) catch @panic("api error");
    }

    pub inline fn renderPassEncoderSetBlendConstant(render_pass_encoder: *sysgpu.RenderPassEncoder, color: *const sysgpu.Color) void {
        _ = render_pass_encoder;
        _ = color;
        @panic("unimplemented");
    }

    pub inline fn renderPassEncoderSetIndexBuffer(render_pass_encoder_raw: *sysgpu.RenderPassEncoder, buffer_raw: *sysgpu.Buffer, format: sysgpu.IndexFormat, offset: u64, size: u64) void {
        const render_pass_encoder: *impl.RenderPassEncoder = @ptrCast(@alignCast(render_pass_encoder_raw));
        const buffer: *impl.Buffer = @ptrCast(@alignCast(buffer_raw));
        render_pass_encoder.setIndexBuffer(buffer, format, offset, size) catch @panic("api error");
    }

    pub inline fn renderPassEncoderSetLabel(render_pass_encoder: *sysgpu.RenderPassEncoder, label: [*:0]const u8) void {
        _ = render_pass_encoder;
        _ = label;
        @panic("unimplemented");
    }

    pub inline fn renderPassEncoderSetPipeline(render_pass_encoder_raw: *sysgpu.RenderPassEncoder, pipeline_raw: *sysgpu.RenderPipeline) void {
        const render_pass_encoder: *impl.RenderPassEncoder = @ptrCast(@alignCast(render_pass_encoder_raw));
        const pipeline: *impl.RenderPipeline = @ptrCast(@alignCast(pipeline_raw));
        render_pass_encoder.setPipeline(pipeline) catch @panic("api error");
    }

    pub inline fn renderPassEncoderSetScissorRect(render_pass_encoder_raw: *sysgpu.RenderPassEncoder, x: u32, y: u32, width: u32, height: u32) void {
        const render_pass_encoder: *impl.RenderPassEncoder = @ptrCast(@alignCast(render_pass_encoder_raw));
        render_pass_encoder.setScissorRect(x, y, width, height) catch @panic("api error");
    }

    pub inline fn renderPassEncoderSetStencilReference(render_pass_encoder: *sysgpu.RenderPassEncoder, reference: u32) void {
        _ = render_pass_encoder;
        _ = reference;
        @panic("unimplemented");
    }

    pub inline fn renderPassEncoderSetVertexBuffer(render_pass_encoder_raw: *sysgpu.RenderPassEncoder, slot: u32, buffer_raw: *sysgpu.Buffer, offset: u64, size: u64) void {
        const render_pass_encoder: *impl.RenderPassEncoder = @ptrCast(@alignCast(render_pass_encoder_raw));
        const buffer: *impl.Buffer = @ptrCast(@alignCast(buffer_raw));
        render_pass_encoder.setVertexBuffer(slot, buffer, offset, size) catch @panic("api error");
    }

    pub inline fn renderPassEncoderSetViewport(render_pass_encoder_raw: *sysgpu.RenderPassEncoder, x: f32, y: f32, width: f32, height: f32, min_depth: f32, max_depth: f32) void {
        const render_pass_encoder: *impl.RenderPassEncoder = @ptrCast(@alignCast(render_pass_encoder_raw));
        render_pass_encoder.setViewport(x, y, width, height, min_depth, max_depth) catch @panic("api error");
    }

    pub inline fn renderPassEncoderWriteTimestamp(render_pass_encoder: *sysgpu.RenderPassEncoder, query_set: *sysgpu.QuerySet, query_index: u32) void {
        _ = render_pass_encoder;
        _ = query_set;
        _ = query_index;
        @panic("unimplemented");
    }

    pub inline fn renderPassEncoderReference(render_pass_encoder_raw: *sysgpu.RenderPassEncoder) void {
        const render_pass_encoder: *impl.RenderPassEncoder = @ptrCast(@alignCast(render_pass_encoder_raw));
        render_pass_encoder.manager.reference();
    }

    pub inline fn renderPassEncoderRelease(render_pass_encoder_raw: *sysgpu.RenderPassEncoder) void {
        const render_pass_encoder: *impl.RenderPassEncoder = @ptrCast(@alignCast(render_pass_encoder_raw));
        render_pass_encoder.manager.release();
    }

    pub inline fn renderPipelineGetBindGroupLayout(render_pipeline_raw: *sysgpu.RenderPipeline, group_index: u32) *sysgpu.BindGroupLayout {
        const render_pipeline: *impl.RenderPipeline = @ptrCast(@alignCast(render_pipeline_raw));
        const layout: *impl.BindGroupLayout = render_pipeline.getBindGroupLayout(group_index);
        layout.manager.reference();
        return @ptrCast(layout);
    }

    pub inline fn renderPipelineSetLabel(render_pipeline: *sysgpu.RenderPipeline, label: [*:0]const u8) void {
        _ = render_pipeline;
        _ = label;
        @panic("unimplemented");
    }

    pub inline fn renderPipelineReference(render_pipeline_raw: *sysgpu.RenderPipeline) void {
        const render_pipeline: *impl.RenderPipeline = @ptrCast(@alignCast(render_pipeline_raw));
        render_pipeline.manager.reference();
    }

    pub inline fn renderPipelineRelease(render_pipeline_raw: *sysgpu.RenderPipeline) void {
        const render_pipeline: *impl.RenderPipeline = @ptrCast(@alignCast(render_pipeline_raw));
        render_pipeline.manager.release();
    }

    pub inline fn samplerSetLabel(sampler: *sysgpu.Sampler, label: [*:0]const u8) void {
        _ = sampler;
        _ = label;
        @panic("unimplemented");
    }

    pub inline fn samplerReference(sampler_raw: *sysgpu.Sampler) void {
        const sampler: *impl.Sampler = @ptrCast(@alignCast(sampler_raw));
        sampler.manager.reference();
    }

    pub inline fn samplerRelease(sampler_raw: *sysgpu.Sampler) void {
        const sampler: *impl.Sampler = @ptrCast(@alignCast(sampler_raw));
        sampler.manager.release();
    }

    pub inline fn shaderModuleGetCompilationInfo(shader_module: *sysgpu.ShaderModule, callback: sysgpu.CompilationInfoCallback, userdata: ?*anyopaque) void {
        _ = shader_module;
        _ = callback;
        _ = userdata;
        @panic("unimplemented");
    }

    pub inline fn shaderModuleSetLabel(shader_module: *sysgpu.ShaderModule, label: [*:0]const u8) void {
        _ = shader_module;
        _ = label;
        @panic("unimplemented");
    }

    pub inline fn shaderModuleReference(shader_module_raw: *sysgpu.ShaderModule) void {
        const shader_module: *impl.ShaderModule = @ptrCast(@alignCast(shader_module_raw));
        shader_module.manager.reference();
    }

    pub inline fn shaderModuleRelease(shader_module_raw: *sysgpu.ShaderModule) void {
        const shader_module: *impl.ShaderModule = @ptrCast(@alignCast(shader_module_raw));
        shader_module.manager.release();
    }

    pub inline fn sharedFenceExportInfo(shared_fence: *sysgpu.SharedFence, info: *sysgpu.SharedFence.ExportInfo) void {
        _ = shared_fence;
        _ = info;
        @panic("unimplemented");
    }

    pub inline fn sharedFenceReference(shared_fence: *sysgpu.SharedFence) void {
        _ = shared_fence;
        @panic("unimplemented");
    }

    pub inline fn sharedFenceRelease(shared_fence: *sysgpu.SharedFence) void {
        _ = shared_fence;
        @panic("unimplemented");
    }

    pub inline fn sharedTextureMemoryBeginAccess(shared_texture_memory: *sysgpu.SharedTextureMemory, texture: *sysgpu.Texture, descriptor: *const sysgpu.SharedTextureMemory.BeginAccessDescriptor) void {
        _ = shared_texture_memory;
        _ = texture;
        _ = descriptor;
        @panic("unimplemented");
    }

    pub inline fn sharedTextureMemoryCreateTexture(shared_texture_memory: *sysgpu.SharedTextureMemory, descriptor: *const sysgpu.Texture.Descriptor) *sysgpu.Texture {
        _ = shared_texture_memory;
        _ = descriptor;
        @panic("unimplemented");
    }

    pub inline fn sharedTextureMemoryEndAccess(shared_texture_memory: *sysgpu.SharedTextureMemory, texture: *sysgpu.Texture, descriptor: *sysgpu.SharedTextureMemory.EndAccessState) void {
        _ = shared_texture_memory;
        _ = texture;
        _ = descriptor;
        @panic("unimplemented");
    }

    pub inline fn sharedTextureMemoryEndAccessStateFreeMembers(value: sysgpu.SharedTextureMemory.EndAccessState) void {
        _ = value;
        @panic("unimplemented");
    }

    pub inline fn sharedTextureMemoryGetProperties(shared_texture_memory: *sysgpu.SharedTextureMemory, properties: *sysgpu.SharedTextureMemory.Properties) void {
        _ = shared_texture_memory;
        _ = properties;
        @panic("unimplemented");
    }

    pub inline fn sharedTextureMemorySetLabel(shared_texture_memory: *sysgpu.SharedTextureMemory, label: [*:0]const u8) void {
        _ = shared_texture_memory;
        _ = label;
        @panic("unimplemented");
    }

    pub inline fn sharedTextureMemoryReference(shared_texture_memory: *sysgpu.SharedTextureMemory) void {
        _ = shared_texture_memory;
        @panic("unimplemented");
    }

    pub inline fn sharedTextureMemoryRelease(shared_texture_memory: *sysgpu.SharedTextureMemory) void {
        _ = shared_texture_memory;
        @panic("unimplemented");
    }

    pub inline fn surfaceReference(surface_raw: *sysgpu.Surface) void {
        const surface: *impl.Surface = @ptrCast(@alignCast(surface_raw));
        surface.manager.reference();
    }

    pub inline fn surfaceRelease(surface_raw: *sysgpu.Surface) void {
        const surface: *impl.Surface = @ptrCast(@alignCast(surface_raw));
        surface.manager.release();
    }

    pub inline fn swapChainConfigure(swap_chain: *sysgpu.SwapChain, format: sysgpu.Texture.Format, allowed_usage: sysgpu.Texture.UsageFlags, width: u32, height: u32) void {
        _ = swap_chain;
        _ = format;
        _ = allowed_usage;
        _ = width;
        _ = height;
        @panic("unimplemented");
    }

    pub inline fn swapChainGetCurrentTexture(swap_chain: *sysgpu.SwapChain) ?*sysgpu.Texture {
        _ = swap_chain;
        @panic("unimplemented");
    }

    pub inline fn swapChainGetCurrentTextureView(swap_chain_raw: *sysgpu.SwapChain) ?*sysgpu.TextureView {
        const swap_chain: *impl.SwapChain = @ptrCast(@alignCast(swap_chain_raw));
        const texture_view = swap_chain.getCurrentTextureView() catch @panic("api error");
        return @ptrCast(texture_view);
    }

    pub inline fn swapChainPresent(swap_chain_raw: *sysgpu.SwapChain) void {
        const swap_chain: *impl.SwapChain = @ptrCast(@alignCast(swap_chain_raw));
        swap_chain.present() catch @panic("api error");
    }

    pub inline fn swapChainReference(swap_chain_raw: *sysgpu.SwapChain) void {
        const swap_chain: *impl.SwapChain = @ptrCast(@alignCast(swap_chain_raw));
        swap_chain.manager.reference();
    }

    pub inline fn swapChainRelease(swap_chain_raw: *sysgpu.SwapChain) void {
        const swap_chain: *impl.SwapChain = @ptrCast(@alignCast(swap_chain_raw));
        swap_chain.manager.release();
    }

    pub inline fn textureCreateView(texture_raw: *sysgpu.Texture, descriptor: ?*const sysgpu.TextureView.Descriptor) *sysgpu.TextureView {
        const texture: *impl.Texture = @ptrCast(@alignCast(texture_raw));
        const texture_view = texture.createView(descriptor orelse &sysgpu.TextureView.Descriptor{}) catch @panic("api error");
        return @ptrCast(texture_view);
    }

    pub inline fn textureDestroy(texture: *sysgpu.Texture) void {
        _ = texture;
        @panic("unimplemented");
    }

    pub inline fn textureGetDepthOrArrayLayers(texture: *sysgpu.Texture) u32 {
        _ = texture;
        @panic("unimplemented");
    }

    pub inline fn textureGetDimension(texture: *sysgpu.Texture) sysgpu.Texture.Dimension {
        _ = texture;
        @panic("unimplemented");
    }

    pub inline fn textureGetFormat(texture: *sysgpu.Texture) sysgpu.Texture.Format {
        _ = texture;
        @panic("unimplemented");
    }

    pub inline fn textureGetHeight(texture: *sysgpu.Texture) u32 {
        _ = texture;
        @panic("unimplemented");
    }

    pub inline fn textureGetMipLevelCount(texture: *sysgpu.Texture) u32 {
        _ = texture;
        @panic("unimplemented");
    }

    pub inline fn textureGetSampleCount(texture: *sysgpu.Texture) u32 {
        _ = texture;
        @panic("unimplemented");
    }

    pub inline fn textureGetUsage(texture: *sysgpu.Texture) sysgpu.Texture.UsageFlags {
        _ = texture;
        @panic("unimplemented");
    }

    pub inline fn textureGetWidth(texture: *sysgpu.Texture) u32 {
        _ = texture;
        @panic("unimplemented");
    }

    pub inline fn textureSetLabel(texture: *sysgpu.Texture, label: [*:0]const u8) void {
        _ = texture;
        _ = label;
        @panic("unimplemented");
    }

    pub inline fn textureReference(texture_raw: *sysgpu.Texture) void {
        const texture: *impl.Texture = @ptrCast(@alignCast(texture_raw));
        texture.manager.reference();
    }

    pub inline fn textureRelease(texture_raw: *sysgpu.Texture) void {
        const texture: *impl.Texture = @ptrCast(@alignCast(texture_raw));
        texture.manager.release();
    }

    pub inline fn textureViewSetLabel(texture_view: *sysgpu.TextureView, label: [*:0]const u8) void {
        _ = texture_view;
        _ = label;
        @panic("unimplemented");
    }

    pub inline fn textureViewReference(texture_view_raw: *sysgpu.TextureView) void {
        const texture_view: *impl.TextureView = @ptrCast(@alignCast(texture_view_raw));
        texture_view.manager.reference();
    }

    pub inline fn textureViewRelease(texture_view_raw: *sysgpu.TextureView) void {
        const texture_view: *impl.TextureView = @ptrCast(@alignCast(texture_view_raw));
        texture_view.manager.release();
    }
});

test "refAllDeclsRecursive" {
    // std.testing.refAllDeclsRecursive(@This());
    _ = @import("shader/test.zig");

    // // Force inline functions to be analyzed for semantic errors
    // // see e.g. https://github.com/ziglang/zig/issues/17390
    // _ = &struct {
    //     fn f() void {
    //         foo1();
    //         foo2();
    //         foo3();
    //     }
    // }.f;
}

test "export" {
    _ = sysgpu.Export(Impl);
}
