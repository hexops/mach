const ExternalTexture = @This();

/// The type erased pointer to the ExternalTexture implementation
/// Equal to c.WGPUExternalTexture for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    // TODO:
    // WGPU_EXPORT void wgpuExternalTextureDestroy(WGPUExternalTexture externalTexture);
    // WGPU_EXPORT void wgpuExternalTextureSetLabel(WGPUExternalTexture externalTexture, char const * label);
};

pub inline fn reference(texture: ExternalTexture) void {
    texture.vtable.reference(texture.ptr);
}

pub inline fn release(texture: ExternalTexture) void {
    texture.vtable.release(texture.ptr);
}

test "syntax" {
    _ = VTable;
    _ = reference;
    _ = release;
}
