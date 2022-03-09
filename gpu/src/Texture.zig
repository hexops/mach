const Texture = @This();

/// The type erased pointer to the Texture implementation
/// Equal to c.WGPUTexture for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    // TODO:
    // WGPU_EXPORT WGPUTextureView wgpuTextureCreateView(WGPUTexture texture, WGPUTextureViewDescriptor const * descriptor);
    // WGPU_EXPORT void wgpuTextureDestroy(WGPUTexture texture);
    // WGPU_EXPORT void wgpuTextureSetLabel(WGPUTexture texture, char const * label);
};

pub inline fn reference(texture: Texture) void {
    texture.vtable.reference(texture.ptr);
}

pub inline fn release(texture: Texture) void {
    texture.vtable.release(texture.ptr);
}

test "syntax" {
    _ = VTable;
    _ = reference;
    _ = release;
}
