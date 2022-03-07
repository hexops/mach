//! A standard interface to a WebGPU implementation.
//!
//! Like std.mem.Allocator, but representing a WebGPU implementation.

const Interface = @This();

/// The type erased pointer to the Interface implementation
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
};

pub inline fn reference(interface: Interface) void {
    interface.vtable.reference(interface.ptr);
}

pub inline fn release(interface: Interface) void {
    interface.vtable.release(interface.ptr);
}

// TODO:
// WGPU_EXPORT void wgpuInstanceRequestAdapter(WGPUInstance instance, WGPURequestAdapterOptions const * options, WGPURequestAdapterCallback callback, void * userdata);
