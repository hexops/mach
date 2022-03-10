const BindGroup = @This();

/// The type erased pointer to the BindGroup implementation
/// Equal to c.WGPUBindGroup for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    // TODO:
    // WGPU_EXPORT void wgpuBindGroupSetLabel(WGPUBindGroup bindGroup, char const * label);
};

pub inline fn reference(group: BindGroup) void {
    group.vtable.reference(group.ptr);
}

pub inline fn release(group: BindGroup) void {
    group.vtable.release(group.ptr);
}

test "syntax" {
    _ = VTable;
    _ = reference;
    _ = release;
}