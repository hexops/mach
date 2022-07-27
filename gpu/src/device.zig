const Queue = @import("queue.zig").Queue;
const QueueDescriptor = @import("queue.zig").QueueDescriptor;
const BindGroup = @import("bind_group.zig").BindGroup;
const BindGroupDescriptor = @import("bind_group.zig").BindGroupDescriptor;
const BindGroupLayout = @import("bind_group_layout.zig").BindGroupLayout;
const BindGroupLayoutDescriptor = @import("bind_group_layout.zig").BindGroupLayoutDescriptor;
const Buffer = @import("buffer.zig").Buffer;
const BufferDescriptor = @import("buffer.zig").BufferDescriptor;
const CommandEncoder = @import("command_encoder.zig").CommandEncoder;
const CommandEncoderDescriptor = @import("command_encoder.zig").CommandEncoderDescriptor;
const ComputePipeline = @import("compute_pipeline.zig").ComputePipeline;
const ComputePipelineDescriptor = @import("compute_pipeline.zig").ComputePipelineDescriptor;
const ExternalTexture = @import("external_texture.zig").ExternalTexture;
const ExternalTextureDescriptor = @import("external_texture.zig").ExternalTextureDescriptor;
const PipelineLayout = @import("pipeline_layout.zig").PipelineLayout;
const PipelineLayoutDescriptor = @import("pipeline_layout.zig").PipelineLayoutDescriptor;
const QuerySet = @import("query_set.zig").QuerySet;
const QuerySetDescriptor = @import("query_set.zig").QuerySetDescriptor;
const RenderBundleEncoder = @import("render_bundle_encoder.zig").RenderBundleEncoder;
const RenderBundleEncoderDescriptor = @import("render_bundle_encoder.zig").RenderBundleEncoderDescriptor;
const RenderPipeline = @import("render_pipeline.zig").RenderPipeline;
const RenderPipelineDescriptor = @import("render_pipeline.zig").RenderPipelineDescriptor;
const Sampler = @import("sampler.zig").Sampler;
const SamplerDescriptor = @import("sampler.zig").SamplerDescriptor;
const ShaderModule = @import("shader_module.zig").ShaderModule;
const ShaderModuleDescriptor = @import("shader_module.zig").ShaderModuleDescriptor;
const Surface = @import("surface.zig").Surface;
const SwapChain = @import("swap_chain.zig").SwapChain;
const SwapChainDescriptor = @import("swap_chain.zig").SwapChainDescriptor;
const Texture = @import("texture.zig").Texture;
const TextureDescriptor = @import("texture.zig").TextureDescriptor;
const ChainedStruct = @import("types.zig").ChainedStruct;
const FeatureName = @import("types.zig").FeatureName;
const RequiredLimits = @import("types.zig").RequiredLimits;
const SupportedLimits = @import("types.zig").SupportedLimits;
const ErrorType = @import("types.zig").ErrorType;
const ErrorFilter = @import("types.zig").ErrorFilter;
const ErrorCallback = @import("types.zig").ErrorCallback;
const LoggingCallback = @import("types.zig").LoggingCallback;
const CreateComputePipelineAsyncCallback = @import("types.zig").CreateComputePipelineAsyncCallback;
const CreateRenderPipelineAsyncCallback = @import("types.zig").CreateRenderPipelineAsyncCallback;
const impl = @import("interface.zig").impl;

pub const Device = *opaque {
    pub inline fn createBindGroup(device: Device, descriptor: *const BindGroupDescriptor) BindGroup {
        return impl.deviceCreateBindGroup(device, descriptor);
    }

    pub inline fn createBindGroupLayout(device: Device, descriptor: *const BindGroupLayoutDescriptor) BindGroupLayout {
        return impl.deviceCreateBindGroupLayout(device, descriptor);
    }

    pub inline fn createBuffer(device: Device, descriptor: *const BufferDescriptor) Buffer {
        return impl.deviceCreateBuffer(device, descriptor);
    }

    pub inline fn createCommandEncoder(device: Device, descriptor: ?*const CommandEncoderDescriptor) CommandEncoder {
        return impl.deviceCreateCommandEncoder(device, descriptor);
    }

    pub inline fn createComputePipeline(device: Device, descriptor: *const ComputePipelineDescriptor) ComputePipeline {
        return impl.deviceCreateComputePipeline(device, descriptor);
    }

    pub inline fn createComputePipelineAsync(device: Device, descriptor: *const ComputePipelineDescriptor, callback: CreateComputePipelineAsyncCallback, userdata: *anyopaque) void {
        impl.deviceCreateComputePipelineAsync(device, descriptor, callback, userdata);
    }

    pub inline fn createErrorBuffer(device: Device) Buffer {
        return impl.deviceCreateErrorBuffer(device);
    }

    pub inline fn createErrorExternalTexture(device: Device) ExternalTexture {
        return impl.deviceCreateErrorExternalTexture(device);
    }

    pub inline fn createExternalTexture(device: Device, external_texture_descriptor: *const ExternalTextureDescriptor) ExternalTexture {
        return impl.deviceCreateExternalTexture(device, external_texture_descriptor);
    }

    pub inline fn createPipelineLayout(device: Device, pipeline_layout_descriptor: *const PipelineLayoutDescriptor) PipelineLayout {
        return impl.deviceCreatePipelineLayout(device, pipeline_layout_descriptor);
    }

    pub inline fn createQuerySet(device: Device, descriptor: *const QuerySetDescriptor) QuerySet {
        return impl.deviceCreateQuerySet(device, descriptor);
    }

    pub inline fn createRenderBundleEncoder(device: Device, descriptor: *const RenderBundleEncoderDescriptor) RenderBundleEncoder {
        return impl.deviceCreateRenderBundleEncoder(device, descriptor);
    }

    pub inline fn createRenderPipeline(device: Device, descriptor: *const RenderPipelineDescriptor) RenderPipeline {
        return impl.deviceCreateRenderPipeline(device, descriptor);
    }

    pub inline fn createRenderPipelineAsync(device: Device, descriptor: *const RenderPipelineDescriptor, callback: CreateRenderPipelineAsyncCallback, userdata: *anyopaque) void {
        impl.deviceCreateRenderPipelineAsync(device, descriptor, callback, userdata);
    }

    pub inline fn createSampler(device: Device, descriptor: ?*const SamplerDescriptor) Sampler {
        return impl.deviceCreateSampler(device, descriptor);
    }

    pub inline fn createShaderModule(device: Device, descriptor: *const ShaderModuleDescriptor) ShaderModule {
        return impl.deviceCreateShaderModule(device, descriptor);
    }

    pub inline fn createSwapChain(device: Device, surface: ?Surface, descriptor: *const SwapChainDescriptor) SwapChain {
        return impl.deviceCreateSwapChain(device, surface, descriptor);
    }

    pub inline fn createTexture(device: Device, descriptor: *const TextureDescriptor) Texture {
        return impl.deviceCreateTexture(device, descriptor);
    }

    pub inline fn destroy(device: Device) void {
        impl.deviceDestroy(device);
    }

    pub inline fn enumerateFeatures(device: Device, features: [*]FeatureName) usize {
        return impl.deviceEnumerateFeatures(device, features);
    }

    pub inline fn getLimits(device: Device, limits: *SupportedLimits) bool {
        return impl.deviceGetLimits(device, limits);
    }

    pub inline fn getQueue(device: Device) Queue {
        return impl.deviceGetQueue(device);
    }

    pub inline fn hasFeature(device: Device, feature: FeatureName) bool {
        return impl.deviceHasFeature(device, feature);
    }

    pub inline fn injectError(device: Device, typ: ErrorType, message: [*:0]const u8) void {
        impl.deviceInjectError(device, typ, message);
    }

    pub inline fn loseForTesting(device: Device) void {
        impl.deviceLoseForTesting(device);
    }

    pub inline fn popErrorScope(device: Device, callback: ErrorCallback, userdata: *anyopaque) bool {
        return impl.devicePopErrorScope(device, callback, userdata);
    }

    pub inline fn pushErrorScope(device: Device, filter: ErrorFilter) void {
        impl.devicePushErrorScope(device, filter);
    }

    pub inline fn setDeviceLostCallback(device: Device, callback: DeviceLostCallback, userdata: *anyopaque) void {
        impl.deviceSetDeviceLostCallback(device, callback, userdata);
    }

    pub inline fn setLabel(device: Device, label: [*:0]const u8) void {
        impl.deviceSetLabel(device, label);
    }

    pub inline fn setLoggingCallback(device: Device, callback: LoggingCallback, userdata: *anyopaque) void {
        impl.deviceSetLoggingCallback(device, callback, userdata);
    }

    pub inline fn setUncapturedErrorCallback(device: Device, callback: ErrorCallback, userdata: *anyopaque) void {
        impl.deviceSetUncapturedErrorCallback(device, callback, userdata);
    }

    pub inline fn tick(device: Device) void {
        impl.deviceTick(device);
    }

    pub inline fn reference(device: Device) void {
        impl.deviceReference(device);
    }

    pub inline fn release(device: Device) void {
        impl.deviceRelease(device);
    }
};

pub const DeviceLostCallback = fn (
    reason: DeviceLostReason,
    message: [*:0]const u8,
    userdata: *anyopaque,
) callconv(.C) void;

pub const DeviceLostReason = enum(u32) {
    undef = 0x00000000,
    destroyed = 0x00000001,
};

pub const DeviceDescriptor = extern struct {
    next_in_chain: *const ChainedStruct,
    label: ?[*:0]const u8 = null,
    required_features_count: u32,
    required_features: [*]const FeatureName,
    required_limits: ?*const RequiredLimits = null, // nullable
    default_queue: QueueDescriptor,
};
