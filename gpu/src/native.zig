//! A native webgpu.h based implementation of the Device interface.
const Device = @import("Device.zig");

/// Returns a native WebGPU implementation of the Device interface.
pub fn native() Device {
    // TODO: implement Device interface
    @panic("not implemented");

    // TODO: implement Adapter interface:
    // typedef struct WGPUAdapterImpl* WGPUAdapter;
    // // Methods of Adapter
    // WGPU_EXPORT size_t wgpuAdapterEnumerateFeatures(WGPUAdapter adapter, WGPUFeatureName * features);
    // WGPU_EXPORT bool wgpuAdapterHasFeature(WGPUAdapter adapter, WGPUFeatureName feature);
    // WGPU_EXPORT bool wgpuAdapterGetLimits(WGPUAdapter adapter, WGPUSupportedLimits * limits);
    // WGPU_EXPORT void wgpuAdapterGetProperties(WGPUAdapter adapter, WGPUAdapterProperties * properties);
}
