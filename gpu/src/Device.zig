//! A GPUDevice / logical instantiation of an adapter.
//!
//! A device is the exclusive owner of all internal objects created from it: when the device is
//! lost or destroyed, it and all objects created on it (directly, e.g. createTexture(), or
//! indirectly, e.g. createView()) become implicitly unusable.
//!
//! https://gpuweb.github.io/gpuweb/#devices
//! https://gpuweb.github.io/gpuweb/#gpuadapter
const Feature = @import("enums.zig").Feature;
const ErrorType = @import("enums.zig").ErrorType;
const Limits = @import("data.zig").Limits;
const Queue = @import("Queue.zig");
const ShaderModule = @import("ShaderModule.zig");
const Surface = @import("Surface.zig");
const SwapChain = @import("SwapChain.zig");
const RenderPipeline = @import("RenderPipeline.zig");
const CommandEncoder = @import("CommandEncoder.zig");
const ComputePipeline = @import("ComputePipeline.zig");
const BindGroup = @import("BindGroup.zig");
const BindGroupLayout = @import("BindGroupLayout.zig");
const Buffer = @import("Buffer.zig");
const ExternalTexture = @import("ExternalTexture.zig");
const PipelineLayout = @import("PipelineLayout.zig");
const QuerySet = @import("QuerySet.zig");

const Device = @This();

/// The type erased pointer to the Device implementation
/// Equal to c.WGPUDevice for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    createBindGroup: fn (ptr: *anyopaque, descriptor: *const BindGroup.Descriptor) BindGroup,
    createBindGroupLayout: fn (ptr: *anyopaque, descriptor: *const BindGroupLayout.Descriptor) BindGroupLayout,
    createBuffer: fn (ptr: *anyopaque, descriptor: *const Buffer.Descriptor) Buffer,
    createCommandEncoder: fn (ptr: *anyopaque, descriptor: ?*const CommandEncoder.Descriptor) CommandEncoder,
    createComputePipeline: fn (ptr: *anyopaque, descriptor: *const ComputePipeline.Descriptor) ComputePipeline,
    createComputePipelineAsync: fn (
        ptr: *anyopaque,
        descriptor: *const ComputePipeline.Descriptor,
        callback: *ComputePipeline.CreateCallback,
    ) void,
    createErrorBuffer: fn (ptr: *anyopaque) Buffer,
    createExternalTexture: fn (ptr: *anyopaque, descriptor: *const ExternalTexture.Descriptor) ExternalTexture,
    createPipelineLayout: fn (ptr: *anyopaque, descriptor: *const PipelineLayout.Descriptor) PipelineLayout,
    createQuerySet: fn (ptr: *anyopaque, descriptor: *const QuerySet.Descriptor) QuerySet,
    // createRenderBundleEncoder: fn (ptr: *anyopaque, descriptor: *const RenderBundleEncoder.Descriptor) RenderBundleEncoder,
    createRenderPipeline: fn (ptr: *anyopaque, descriptor: *const RenderPipeline.Descriptor) RenderPipeline,
    createRenderPipelineAsync: fn (
        ptr: *anyopaque,
        descriptor: *const RenderPipeline.Descriptor,
        callback: *RenderPipeline.CreateCallback,
    ) void,
    // createSampler: fn (ptr: *anyopaque, descriptor: *const Sampler.Descriptor) Sampler,
    // WGPU_EXPORT WGPUSampler wgpuDeviceCreateSampler(WGPUDevice device, WGPUSamplerDescriptor const * descriptor);
    createShaderModule: fn (ptr: *anyopaque, descriptor: *const ShaderModule.Descriptor) ShaderModule,
    nativeCreateSwapChain: fn (ptr: *anyopaque, surface: ?Surface, descriptor: *const SwapChain.Descriptor) SwapChain,
    // createTexture: fn (ptr: *anyopaque, descriptor: *const Texture.Descriptor) Texture,
    // WGPU_EXPORT WGPUTexture wgpuDeviceCreateTexture(WGPUDevice device, WGPUTextureDescriptor const * descriptor);
    destroy: fn (ptr: *anyopaque) void,
    // TODO: should features be exposed as static slice?
    // WGPU_EXPORT size_t wgpuDeviceEnumerateFeatures(WGPUDevice device, WGPUFeature * features);
    // TODO: should limits be exposed as static slice?
    // WGPU_EXPORT bool wgpuDeviceGetLimits(WGPUDevice device, WGPUSupportedLimits * limits);
    getQueue: fn (ptr: *anyopaque) Queue,
    // TODO: should hasFeature be a helper method?
    // WGPU_EXPORT bool wgpuDeviceHasFeature(WGPUDevice device, WGPUFeature feature);
    injectError: fn (ptr: *anyopaque, type: ErrorType, message: [*:0]const u8) void,
    // loseForTesting: fn (ptr: *anyopaque) void,
    // WGPU_EXPORT void wgpuDeviceLoseForTesting(WGPUDevice device);
    // TODO: callback
    // popErrorScope: fn (ptr: *anyopaque, callback: ErrorCallback) bool,
    // WGPU_EXPORT bool wgpuDevicePopErrorScope(WGPUDevice device, WGPUErrorCallback callback, void * userdata);
    // pushErrorScope: fn (ptr: *anyopaque, filter: ErrorFilter) void,
    // WGPU_EXPORT void wgpuDevicePushErrorScope(WGPUDevice device, WGPUErrorFilter filter);
    // TODO: callback
    // setDeviceLostCallback: fn (ptr: *anyopaque, callback: DeviceLostCallback) void,
    // WGPU_EXPORT void wgpuDeviceSetDeviceLostCallback(WGPUDevice device, WGPUDeviceLostCallback callback, void * userdata);
    // TODO: callback
    // setLoggingCallback: fn (ptr: *anyopaque, callback: LoggingCallback) void,
    // WGPU_EXPORT void wgpuDeviceSetLoggingCallback(WGPUDevice device, WGPULoggingCallback callback, void * userdata);
    // TODO: callback
    // setUncapturedErrorCallback: fn (ptr: *anyopaque, callback: UncapturedErrorCallback) void,
    // WGPU_EXPORT void wgpuDeviceSetUncapturedErrorCallback(WGPUDevice device, WGPUErrorCallback callback, void * userdata);
    tick: fn (ptr: *anyopaque) void,
};

pub inline fn reference(device: Device) void {
    device.vtable.reference(device.ptr);
}

pub inline fn release(device: Device) void {
    device.vtable.release(device.ptr);
}

pub inline fn getQueue(device: Device) Queue {
    return device.vtable.getQueue(device.ptr);
}

pub inline fn injectError(device: Device, typ: ErrorType, message: [*:0]const u8) void {
    device.vtable.injectError(device.ptr, typ, message);
}

pub inline fn createBindGroup(device: Device, descriptor: *const BindGroup.Descriptor) BindGroup {
    return device.vtable.createBindGroup(device.ptr, descriptor);
}

pub inline fn createBindGroupLayout(device: Device, descriptor: *const BindGroupLayout.Descriptor) BindGroupLayout {
    return device.vtable.createBindGroupLayout(device.ptr, descriptor);
}

pub inline fn createShaderModule(device: Device, descriptor: *const ShaderModule.Descriptor) ShaderModule {
    return device.vtable.createShaderModule(device.ptr, descriptor);
}

pub inline fn nativeCreateSwapChain(device: Device, surface: ?Surface, descriptor: *const SwapChain.Descriptor) SwapChain {
    return device.vtable.nativeCreateSwapChain(device.ptr, surface, descriptor);
}

pub inline fn destroy(device: Device) void {
    device.vtable.destroy(device.ptr);
}

pub inline fn createBuffer(device: Device, descriptor: *const Buffer.Descriptor) Buffer {
    return device.vtable.createBuffer(device.ptr, descriptor);
}

pub inline fn createCommandEncoder(device: Device, descriptor: ?*const CommandEncoder.Descriptor) CommandEncoder {
    return device.vtable.createCommandEncoder(device.ptr, descriptor);
}

pub inline fn createComputePipeline(
    device: Device,
    descriptor: *const ComputePipeline.Descriptor,
) ComputePipeline {
    return device.vtable.createComputePipeline(device.ptr, descriptor);
}

pub inline fn createComputePipelineAsync(
    device: Device,
    descriptor: *const ComputePipeline.Descriptor,
    callback: *ComputePipeline.CreateCallback,
) void {
    device.vtable.createComputePipelineAsync(device.ptr, descriptor, callback);
}

pub inline fn createErrorBuffer(device: Device) Buffer {
    return device.vtable.createErrorBuffer(device.ptr);
}

pub inline fn createExternalTexture(device: Device, descriptor: *const ExternalTexture.Descriptor) ExternalTexture {
    return device.vtable.createExternalTexture(device.ptr, descriptor);
}

pub inline fn createPipelineLayout(device: Device, descriptor: *const PipelineLayout.Descriptor) PipelineLayout {
    return device.vtable.createPipelineLayout(device.ptr, descriptor);
}

pub inline fn createQuerySet(device: Device, descriptor: *const QuerySet.Descriptor) QuerySet {
    return device.vtable.createQuerySet(device.ptr, descriptor);
}

// pub inline fn createRenderBundleEncoder(device: Device, descriptor: *const RenderBundleEncoder.Descriptor) RenderBundleEncoder {
//     return device.vtable.createRenderBundleEncoder(device.ptr, descriptor);
// }
// createRenderBundleEncoder: fn (ptr: *anyopaque, descriptor: *const RenderBundleEncoder.Descriptor) RenderBundleEncoder,
// WGPU_EXPORT WGPURenderBundleEncoder wgpuDeviceCreateRenderBundleEncoder(WGPUDevice device, WGPURenderBundleEncoderDescriptor const * descriptor);

pub inline fn createRenderPipeline(device: Device, descriptor: *const RenderPipeline.Descriptor) RenderPipeline {
    return device.vtable.createRenderPipeline(device.ptr, descriptor);
}

pub inline fn createRenderPipelineAsync(
    device: Device,
    descriptor: *const RenderPipeline.Descriptor,
    callback: *RenderPipeline.CreateCallback,
) void {
    device.vtable.createRenderPipelineAsync(device.ptr, descriptor, callback);
}

pub inline fn tick(device: Device) void {
    device.vtable.tick(device.ptr);
}

pub const Descriptor = struct {
    label: ?[*:0]const u8 = null,
    required_features: ?[]Feature = null,
    required_limits: ?Limits = null,
};

pub const LostReason = enum(u32) {
    none = 0x00000000,
    destroyed = 0x00000001,
};

test {
    _ = VTable;
    _ = reference;
    _ = release;
    _ = getQueue;
    _ = injectError;
    _ = createBindGroup;
    _ = createBindGroupLayout;
    _ = createShaderModule;
    _ = nativeCreateSwapChain;
    _ = destroy;
    _ = createBuffer;
    _ = createCommandEncoder;
    _ = createComputePipeline;
    _ = createComputePipelineAsync;
    _ = createErrorBuffer;
    _ = createExternalTexture;
    _ = createPipelineLayout;
    _ = createQuerySet;
    // _ = createRenderBundleEncoder;
    _ = createRenderPipeline;
    _ = createRenderPipelineAsync;
    _ = tick;
    _ = Descriptor;
    _ = LostReason;
}
