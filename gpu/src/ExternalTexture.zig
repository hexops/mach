const Texture = @import("Texture.zig");
const PredefinedColorSpace = @import("enums.zig").PredefinedColorSpace;

const ExternalTexture = @This();

/// The type erased pointer to the ExternalTexture implementation
/// Equal to c.WGPUExternalTexture for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    destroy: fn (ptr: *anyopaque) void,
    setLabel: fn (ptr: *anyopaque, label: [:0]const u8) void,
};

pub inline fn reference(texture: ExternalTexture) void {
    texture.vtable.reference(texture.ptr);
}

pub inline fn release(texture: ExternalTexture) void {
    texture.vtable.release(texture.ptr);
}

pub inline fn setLabel(texture: ExternalTexture, label: [:0]const u8) void {
    texture.vtable.setLabel(texture.ptr, label);
}

pub inline fn destroy(texture: ExternalTexture) void {
    texture.vtable.destroy(texture.ptr);
}

pub const Descriptor = struct {
    label: ?[*:0]const u8 = null,
    plane0: Texture.View,
    plane1: Texture.View,
    color_space: PredefinedColorSpace,
};

test "syntax" {
    _ = VTable;
    _ = reference;
    _ = release;
    _ = destroy;
    _ = Descriptor;
}
