//! A standard interface to a WebGPU implementation.
//!
//! Like std.mem.Allocator, but representing a WebGPU implementation.

// The type erased pointer to the Device implementation
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    // TODO(gpu): make these *const fn once stage2 is released.
    deinit: fn (ptr: *anyopaque) void,
};

// TODO:
// WGPU_EXPORT void wgpuInstanceRequestAdapter(WGPUInstance instance, WGPURequestAdapterOptions const * options, WGPURequestAdapterCallback callback, void * userdata);
// WGPU_EXPORT void wgpuInstanceReference(WGPUInstance instance);
// WGPU_EXPORT void wgpuInstanceRelease(WGPUInstance instance);
