const PipelineLayout = @This();

/// The type erased pointer to the PipelineLayout implementation
/// Equal to c.WGPUPipelineLayout for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    // TODO:
    // WGPU_EXPORT void wgpuPipelineLayoutSetLabel(WGPUPipelineLayout pipelineLayout, char const * label);
};

pub inline fn reference(qset: PipelineLayout) void {
    qset.vtable.reference(qset.ptr);
}

pub inline fn release(qset: PipelineLayout) void {
    qset.vtable.release(qset.ptr);
}

test "syntax" {
    _ = VTable;
    _ = reference;
    _ = release;
}
