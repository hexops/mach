const RenderBundle = @This();

/// The type erased pointer to the RenderBundle implementation
/// Equal to c.WGPURenderBundle for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    // TODO:
};

pub inline fn reference(bundle: RenderBundle) void {
    bundle.vtable.reference(bundle.ptr);
}

pub inline fn release(bundle: RenderBundle) void {
    bundle.vtable.release(bundle.ptr);
}

test "syntax" {
    _ = VTable;
    _ = reference;
    _ = release;
}
