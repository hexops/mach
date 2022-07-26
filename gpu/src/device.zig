const ChainedStruct = @import("types.zig").ChainedStruct;
const FeatureName = @import("types.zig").FeatureName;
const RequiredLimits = @import("types.zig").RequiredLimits;
const Queue = @import("queue.zig").Queue;
const QueueDescriptor = @import("queue.zig").QueueDescriptor;

pub const Device = *opaque {
    // TODO
    // pub inline fn deviceCreateBindGroup(device: gpu.Device, descriptor: *const gpu.BindGroupDescriptor) gpu.BindGroup {

    // TODO
    // pub inline fn deviceCreateBindGroupLayout(device: gpu.Device, descriptor: *const gpu.BindGroupLayoutDescriptor) gpu.BindGroupLayout {

    // TODO
    // pub inline fn deviceCreateBindGroup(device: gpu.Device, descriptor: *const gpu.BufferDescriptor) gpu.Buffer {

    // TODO
    // pub inline fn deviceCreateCommandEncoder(device: gpu.Device, descriptor: ?*const gpu.CommandEncoderDescriptor) gpu.CommandEncoder {

    // TODO
    // pub inline fn deviceCreateComputePipeline(device: gpu.Device, descriptor: *const gpu.ComputePipelineDescriptor) gpu.ComputePipeline {

    // TODO
    // pub inline fn deviceCreateComputePipelineAsync(device: gpu.Device, descriptor: *const gpu.ComputePipelineDescriptor, callback: gpu.CreateComputePipelineAsyncCallback, userdata: *anyopaque) void {

    // TODO
    // pub inline fn deviceCreateErrorBuffer(device: gpu.Device) gpu.Buffer {

    // TODO
    // pub inline fn deviceCreateErrorExternalTexture(device: gpu.Device) gpu.ExternalTexture {

    // TODO
    // pub inline fn deviceCreateExternalTexture(device: gpu.Device, external_texture_descriptor: *const gpu.ExternalTextureDescriptor) gpu.ExternalTexture {

    // TODO
    // pub inline fn deviceCreatePipelineLayout(device: gpu.Device, pipeline_layout_descriptor: *const gpu.PipelineLayoutDescriptor) gpu.PipelineLayout {

    // TODO
    // pub inline fn deviceCreateQuerySet(device: gpu.Device, descriptor: *const gpu.QuerySetDescriptor) gpu.QuerySet {

    // TODO
    // pub inline fn deviceCreateRenderBundleEncoder(device: gpu.Device, descriptor: *const gpu.RenderBundleEncoderDescriptor) gpu.RenderBundleEncoder {

    // TODO
    // pub inline fn deviceCreateRenderPipeline(device: gpu.Device, descriptor: *const gpu.RenderPipelineDescriptor) gpu.RenderPipeline {

    // TODO
    // pub inline fn deviceCreateRenderPipelineAsync(device: gpu.Device, descriptor: *const gpu.RenderPipelineDescriptor, callback: gpu.CreateRenderPipelineAsyncCallback, userdata: *anyopaque) void {

    // TODO
    // pub inline fn deviceCreateRenderPipeline(device: gpu.Device, descriptor: ?*const gpu.SamplerDescriptor) gpu.Sampler {

    // TODO
    // pub inline fn deviceCreateShaderModule(device: gpu.Device, descriptor: *const gpu.ShaderModuleDescriptor) gpu.ShaderModule {

    // TODO
    // pub inline fn deviceCreateShaderModule(device: gpu.Device, surface: ?Surface, descriptor: *const gpu.SwapChainDescriptor) gpu.SwapChain {

    // TODO
    // pub inline fn deviceCreateTexture(device: gpu.Device, descriptor: *const gpu.TextureDescriptor) gpu.Texture {

    // TODO
    // pub inline fn deviceDestroy(device: gpu.Device) void {

    // TODO
    // pub inline fn deviceEnumerateFeatures(device: gpu.Device, features: [*]gpu.FeatureName) usize {

    // TODO
    // pub inline fn deviceGetLimits(device: gpu.Device, limits: *gpu.SupportedLimits) bool {

    // TODO
    // pub inline fn deviceGetQueue(device: gpu.Device) gpu.Queue {

    // TODO
    // pub inline fn deviceHasFeature(device: gpu.Device, feature: gpu.FeatureName) bool {

    // TODO
    // pub inline fn deviceInjectError(device: gpu.Device, typ: gpu.ErrorType, message: [*:0]const u8) void {

    // TODO
    // pub inline fn deviceLoseForTesting(device: gpu.Device) void {

    // TODO
    // pub inline fn devicePopErrorScope(device: gpu.Device, callback: gpu.ErrorCallback, userdata: *anyopaque) bool {

    // TODO
    // pub inline fn devicePushErrorScope(device: gpu.Device, filter: gpu.ErrorFilter) void {

    // TODO
    // pub inline fn deviceSetDeviceLostCallback(device: gpu.Device, callback: gpu.DeviceLostCallback, userdata: *anyopaque) void {

    // TODO
    // pub inline fn deviceSetLabel(device: gpu.Device, label: [*:0]const u8) void {

    // TODO
    // pub inline fn deviceSetLoggingCallback(device: gpu.Device, callback: gpu.LoggingCallback, userdata: *anyopaque) void {

    // TODO
    // pub inline fn deviceSetUncapturedErrorCallback(device: gpu.Device, callback: gpu.ErrorCallback, userdata: *anyopaque) void {

    // TODO
    // pub inline fn deviceTick(device: gpu.Device) void {

    // TODO
    // pub inline fn deviceReference(device: gpu.Device) void {

    // TODO
    // pub inline fn deviceRelease(device: gpu.Device) void {
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
