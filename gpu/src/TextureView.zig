const Texture = @import("Texture.zig");

const TextureView = @This();

/// The type erased pointer to the TextureView implementation
/// Equal to c.WGPUTextureView for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    setLabel: fn (ptr: *anyopaque, label: [:0]const u8) void,
};

pub inline fn reference(texture_view: TextureView) void {
    texture_view.vtable.reference(texture_view.ptr);
}

pub inline fn release(texture_view: TextureView) void {
    texture_view.vtable.release(texture_view.ptr);
}

pub inline fn setLabel(texture_view: TextureView, label: [:0]const u8) void {
    texture_view.vtable.setLabel(texture_view.ptr, label);
}

pub const Descriptor = struct {
    label: ?[*:0]const u8 = null,
    format: Texture.Format,
    dimension: TextureView.Dimension,
    base_mip_level: u32 = 0,
    mip_level_count: u32,
    base_array_layer: u32 = 0,
    array_layer_count: u32,
    aspect: Texture.Aspect = .all,
};

pub const Dimension = enum(u32) {
    dimension_none = 0x00000000,
    dimension_1d = 0x00000001,
    dimension_2d = 0x00000002,
    dimension_2d_array = 0x00000003,
    dimension_cube = 0x00000004,
    dimension_cube_array = 0x00000005,
    dimension_3d = 0x00000006,
};

test {
    _ = VTable;
    _ = reference;
    _ = release;
    _ = Descriptor;
    _ = Dimension;
}
