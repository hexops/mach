const TextureView = @This();

/// The type erased pointer to the TextureView implementation
/// Equal to c.WGPUTextureView for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    // TODO:
    // WGPU_EXPORT void wgpuTextureViewSetLabel(WGPUTextureView textureView, char const * label);
};

pub inline fn reference(texture_view: TextureView) void {
    texture_view.vtable.reference(texture_view.ptr);
}

pub inline fn release(texture_view: TextureView) void {
    texture_view.vtable.release(texture_view.ptr);
}

test "syntax" {
    _ = VTable;
    _ = reference;
    _ = release;
}
