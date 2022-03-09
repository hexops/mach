const Sampler = @This();

/// The type erased pointer to the Sampler implementation
/// Equal to c.WGPUSampler for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    // TODO:
    // WGPU_EXPORT void wgpuSamplerSetLabel(WGPUSampler sampler, char const * label);
};

pub inline fn reference(sampler: Sampler) void {
    sampler.vtable.reference(sampler.ptr);
}

pub inline fn release(sampler: Sampler) void {
    sampler.vtable.release(sampler.ptr);
}

test "syntax" {
    _ = VTable;
    _ = reference;
    _ = release;
}
