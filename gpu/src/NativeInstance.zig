//! A native webgpu.h implementation of the gpu.Interface
const c = @import("c.zig").c;
const Interface = @import("Interface.zig");
const Surface = @import("Surface.zig");

const NativeInstance = @This();

/// The WGPUInstance that is wrapped by this native instance.
instance: c.WGPUInstance,

vtable: Interface.VTable,

/// Wraps a native WGPUInstance to provide an implementation of the gpu.Interface.
pub fn wrap(instance: c.WGPUInstance) NativeInstance {
    return .{ .instance = instance };
}

/// Returns the gpu.Interface for interacting with this native instance.
pub fn interface(native: *const NativeInstance) Interface {
    return .{
        .ptr = native,
        .vtable = native.vtable,
    };
    // TODO: implement Interface
    // WGPU_EXPORT void wgpuInstanceReference(WGPUInstance instance);
    // WGPU_EXPORT void wgpuInstanceRelease(WGPUInstance instance);

    // TODO: implement Device interface

    // TODO: implement Adapter interface:
    // typedef struct WGPUAdapterImpl* WGPUAdapter;
    // // Methods of Adapter
    // WGPU_EXPORT size_t wgpuAdapterEnumerateFeatures(WGPUAdapter adapter, WGPUFeatureName * features);
    // WGPU_EXPORT bool wgpuAdapterHasFeature(WGPUAdapter adapter, WGPUFeatureName feature);
    // WGPU_EXPORT bool wgpuAdapterGetLimits(WGPUAdapter adapter, WGPUSupportedLimits * limits);
    // WGPU_EXPORT void wgpuAdapterGetProperties(WGPUAdapter adapter, WGPUAdapterProperties * properties);
}

pub fn createSurface(native: *const NativeInstance, descriptor: *const Surface.Descriptor) Surface {
    _ = native;
    _ = descriptor;
    // TODO:
    // WGPU_EXPORT WGPUSurface wgpuInstanceCreateSurface(WGPUInstance instance, WGPUSurfaceDescriptor const * descriptor);
}
