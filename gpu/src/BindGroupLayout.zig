const BindGroupLayout = @This();

/// The type erased pointer to the BindGroupLayout implementation
/// Equal to c.WGPUBindGroupLayout for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    // TODO:
    // WGPU_EXPORT void wgpuBindGroupLayoutSetLabel(WGPUBindGroupLayout bindGroupLayout, char const * label);
};

pub inline fn reference(layout: BindGroupLayout) void {
    layout.vtable.reference(layout.ptr);
}

pub inline fn release(layout: BindGroupLayout) void {
    layout.vtable.release(layout.ptr);
}

test "syntax" {
    _ = VTable;
    _ = reference;
    _ = release;
}
