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
    setLabel: fn (ptr: *anyopaque, label: [:0]const u8) void,
};

pub inline fn reference(qset: QuerySet) void {
    qset.vtable.reference(qset.ptr);
}

pub inline fn release(qset: QuerySet) void {
    qset.vtable.release(qset.ptr);
}

pub inline fn setLabel(qset: QuerySet, label: [:0]const u8) void {
    qset.vtable.setLabel(qset.ptr, label);
}

test "syntax" {
    _ = VTable;
    _ = reference;
    _ = release;
}
