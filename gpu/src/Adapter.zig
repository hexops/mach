//! A GPUAdapter which identifies an implementation of WebGPU on the system.
//!
//! An adapter is both an instance of compute/rendering functionality on the platform, and an
//! instance of the WebGPU implementation on top of that functionality.
//!
//! Adapters do not uniquely represent underlying implementations: calling `requestAdapter()`
//! multiple times returns a different adapter object each time.
//!
//! An adapter object may become invalid at any time. This happens inside "lose the device" and
//! "mark adapters stale". An invalid adapter is unable to vend new devices.
//!
//! Note: This mechanism ensures that various adapter-creation scenarios look similar to
//! applications, so they can easily be robust to more scenarios with less testing: first
//! initialization, reinitialization due to an unplugged adapter, reinitialization due to a test
//! GPUDevice.destroy() call, etc. It also ensures applications use the latest system state to make
//! decisions about which adapter to use.
//!
//! https://gpuweb.github.io/gpuweb/#adapters
//! https://gpuweb.github.io/gpuweb/#gpuadapter

const FeatureName = @import("feature_name.zig").FeatureName;
const SupportedLimits = @import("supported_limits.zig").SupportedLimits;

const Adapter = @This();

/// The features which can be used to create devices on this adapter.
features: []FeatureName,

/// The best limits which can be used to create devices on this adapter.
///
/// Each adapter limit will be the same or better than its default value in supported limits.
limits: SupportedLimits,

/// If set to true indicates that the adapter is a fallback adapter.
///
/// An adapter may be considered a fallback adapter if it has significant performance caveats in
/// exchange for some combination of wider compatibility, more predictable behavior, or improved
/// privacy. It is not guaranteed that a fallback adapter is available on every system.
fallback: bool,

// The type erased pointer to the Adapter implementation
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    // TODO:
    // WGPU_EXPORT void wgpuAdapterRequestDevice(WGPUAdapter adapter, WGPUDeviceDescriptor const * descriptor, WGPURequestDeviceCallback callback, void * userdata);
    // WGPU_EXPORT WGPUDevice wgpuAdapterCreateDevice(WGPUAdapter adapter, WGPUDeviceDescriptor const * descriptor);
    // WGPU_EXPORT void wgpuAdapterReference(WGPUAdapter adapter);
    // WGPU_EXPORT void wgpuAdapterRelease(WGPUAdapter adapter);
};

/// Tests of the given feature can be used to create devices on this adapter.
pub fn hasFeature(adapter: Adapter, feature: FeatureName) bool {
    for (adapter.features) |f| {
        if (f == feature) return true;
    }
    return false;
}

// TODO:
// typedef struct WGPUAdapterProperties {
//     WGPUChainedStructOut * nextInChain;
//     uint32_t vendorID;
//     uint32_t deviceID;
//     char const * name;
//     char const * driverDescription;
//     WGPUAdapterType adapterType;
//     WGPUBackendType backendType;
// } WGPUAdapterProperties;

// TODO:
// typedef enum WGPUAdapterType {
//     WGPUAdapterType_DiscreteGPU = 0x00000000,
//     WGPUAdapterType_IntegratedGPU = 0x00000001,
//     WGPUAdapterType_CPU = 0x00000002,
//     WGPUAdapterType_Unknown = 0x00000003,
//     WGPUAdapterType_Force32 = 0x7FFFFFFF
// } WGPUAdapterType;
