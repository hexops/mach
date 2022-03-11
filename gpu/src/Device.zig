//! A GPUDevice / logical instantiation of an adapter.
//!
//! A device is the exclusive owner of all internal objects created from it: when the device is
//! lost or destroyed, it and all objects created on it (directly, e.g. createTexture(), or
//! indirectly, e.g. createView()) become implicitly unusable.
//!
//! https://gpuweb.github.io/gpuweb/#devices
//! https://gpuweb.github.io/gpuweb/#gpuadapter
const Feature = @import("enums.zig").Feature;
const Limits = @import("data.zig").Limits;
const Queue = @import("Queue.zig");
const ShaderModule = @import("ShaderModule.zig");
const Surface = @import("Surface.zig");
const SwapChain = @import("SwapChain.zig");

const Device = @This();

/// The type erased pointer to the Device implementation
/// Equal to c.WGPUDevice for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    // TODO:
    // WGPU_EXPORT WGPUBindGroup wgpuDeviceCreateBindGroup(WGPUDevice device, WGPUBindGroupDescriptor const * descriptor);
    // WGPU_EXPORT WGPUBindGroupLayout wgpuDeviceCreateBindGroupLayout(WGPUDevice device, WGPUBindGroupLayoutDescriptor const * descriptor);
    // WGPU_EXPORT WGPUBuffer wgpuDeviceCreateBuffer(WGPUDevice device, WGPUBufferDescriptor const * descriptor);
    // WGPU_EXPORT WGPUCommandEncoder wgpuDeviceCreateCommandEncoder(WGPUDevice device, WGPUCommandEncoderDescriptor const * descriptor);
    // WGPU_EXPORT WGPUComputePipeline wgpuDeviceCreateComputePipeline(WGPUDevice device, WGPUComputePipelineDescriptor const * descriptor);
    // WGPU_EXPORT void wgpuDeviceCreateComputePipelineAsync(WGPUDevice device, WGPUComputePipelineDescriptor const * descriptor, WGPUCreateComputePipelineAsyncCallback callback, void * userdata);
    // WGPU_EXPORT WGPUBuffer wgpuDeviceCreateErrorBuffer(WGPUDevice device);
    // WGPU_EXPORT WGPUExternalTexture wgpuDeviceCreateExternalTexture(WGPUDevice device, WGPUExternalTextureDescriptor const * externalTextureDescriptor);
    // WGPU_EXPORT WGPUPipelineLayout wgpuDeviceCreatePipelineLayout(WGPUDevice device, WGPUPipelineLayoutDescriptor const * descriptor);
    // WGPU_EXPORT WGPUQuerySet wgpuDeviceCreateQuerySet(WGPUDevice device, WGPUQuerySetDescriptor const * descriptor);
    // WGPU_EXPORT WGPURenderBundleEncoder wgpuDeviceCreateRenderBundleEncoder(WGPUDevice device, WGPURenderBundleEncoderDescriptor const * descriptor);
    // WGPU_EXPORT WGPURenderPipeline wgpuDeviceCreateRenderPipeline(WGPUDevice device, WGPURenderPipelineDescriptor const * descriptor);
    // WGPU_EXPORT void wgpuDeviceCreateRenderPipelineAsync(WGPUDevice device, WGPURenderPipelineDescriptor const * descriptor, WGPUCreateRenderPipelineAsyncCallback callback, void * userdata);
    // WGPU_EXPORT WGPUSampler wgpuDeviceCreateSampler(WGPUDevice device, WGPUSamplerDescriptor const * descriptor);
    createShaderModule: fn (ptr: *anyopaque, descriptor: *const ShaderModule.Descriptor) ShaderModule,
    nativeCreateSwapChain: fn (ptr: *anyopaque, surface: ?Surface, descriptor: *const SwapChain.Descriptor) SwapChain,
    // WGPU_EXPORT WGPUTexture wgpuDeviceCreateTexture(WGPUDevice device, WGPUTextureDescriptor const * descriptor);
    destroy: fn (ptr: *anyopaque) void,
    // WGPU_EXPORT size_t wgpuDeviceEnumerateFeatures(WGPUDevice device, WGPUFeature * features);
    // WGPU_EXPORT bool wgpuDeviceGetLimits(WGPUDevice device, WGPUSupportedLimits * limits);
    getQueue: fn (ptr: *anyopaque) Queue,
    // WGPU_EXPORT bool wgpuDeviceHasFeature(WGPUDevice device, WGPUFeature feature);
    // WGPU_EXPORT void wgpuDeviceInjectError(WGPUDevice device, WGPUErrorType type, char const * message);
    // WGPU_EXPORT void wgpuDeviceLoseForTesting(WGPUDevice device);
    // WGPU_EXPORT bool wgpuDevicePopErrorScope(WGPUDevice device, WGPUErrorCallback callback, void * userdata);
    // WGPU_EXPORT void wgpuDevicePushErrorScope(WGPUDevice device, WGPUErrorFilter filter);
    // WGPU_EXPORT void wgpuDeviceSetDeviceLostCallback(WGPUDevice device, WGPUDeviceLostCallback callback, void * userdata);
    // WGPU_EXPORT void wgpuDeviceSetLoggingCallback(WGPUDevice device, WGPULoggingCallback callback, void * userdata);
    // WGPU_EXPORT void wgpuDeviceSetUncapturedErrorCallback(WGPUDevice device, WGPUErrorCallback callback, void * userdata);
    // WGPU_EXPORT void wgpuDeviceTick(WGPUDevice device);

    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
};

pub inline fn getQueue(device: Device) Queue {
    return device.vtable.getQueue(device.ptr);
}

pub inline fn reference(device: Device) void {
    device.vtable.reference(device.ptr);
}

pub inline fn release(device: Device) void {
    device.vtable.release(device.ptr);
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

// TODO: docs
pub const Descriptor = struct {
    label: ?[*:0]const u8 = null,
    required_features: ?[]Feature = null,
    required_limits: ?Limits = null,
};

test "syntax" {
    _ = VTable;
    _ = getQueue;
    _ = reference;
    _ = release;
    _ = createShaderModule;
    _ = nativeCreateSwapChain;
    _ = destroy;
    _ = Descriptor;
}
