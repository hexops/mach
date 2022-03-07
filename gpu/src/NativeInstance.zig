//! A native webgpu.h implementation of the gpu.Interface
const c = @import("c.zig").c;
const Interface = @import("Interface.zig");

const NativeInstance = @This();

/// The WGPUInstance that is wrapped by this native instance.
instance: c.WGPUInstance,

/// Returns the gpu.Interface for interacting with this native instance.
pub fn interface(native: NativeInstance) Interface {
    _ = native;
    @panic("not implemented");

    // TODO: implement Interface

    // TODO: implement Device interface

    // TODO: implement Adapter interface:
    // typedef struct WGPUAdapterImpl* WGPUAdapter;
    // // Methods of Adapter
    // WGPU_EXPORT size_t wgpuAdapterEnumerateFeatures(WGPUAdapter adapter, WGPUFeatureName * features);
    // WGPU_EXPORT bool wgpuAdapterHasFeature(WGPUAdapter adapter, WGPUFeatureName feature);
    // WGPU_EXPORT bool wgpuAdapterGetLimits(WGPUAdapter adapter, WGPUSupportedLimits * limits);
    // WGPU_EXPORT void wgpuAdapterGetProperties(WGPUAdapter adapter, WGPUAdapterProperties * properties);
}

/// Wraps a native WGPUInstance to provide an implementation of the gpu.Interface.
pub fn wrap(instance: c.WGPUInstance) NativeInstance {
    return .{ .instance = instance };
}
