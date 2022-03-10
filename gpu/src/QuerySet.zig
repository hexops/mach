const QuerySet = @This();

/// The type erased pointer to the QuerySet implementation
/// Equal to c.WGPUQuerySet for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    // TODO:
    // WGPU_EXPORT void wgpuQuerySetDestroy(WGPUQuerySet querySet);
    // WGPU_EXPORT void wgpuQuerySetSetLabel(WGPUQuerySet querySet, char const * label);
};

pub inline fn reference(qset: QuerySet) void {
    qset.vtable.reference(qset.ptr);
}

pub inline fn release(qset: QuerySet) void {
    qset.vtable.release(qset.ptr);
}

test "syntax" {
    _ = VTable;
    _ = reference;
    _ = release;
}
