const Buffer = @import("Buffer.zig");
const Sampler = @import("Sampler.zig");
const Texture = @import("Texture.zig");
const StorageTextureBindingLayout = @import("structs.zig").StorageTextureBindingLayout;
const ShaderStage = @import("enums.zig").ShaderStage;

const BindGroupLayout = @This();

/// The type erased pointer to the BindGroupLayout implementation
/// Equal to c.WGPUBindGroupLayout for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    setLabel: fn (ptr: *anyopaque, label: [:0]const u8) void,
};

pub inline fn reference(layout: BindGroupLayout) void {
    layout.vtable.reference(layout.ptr);
}

pub inline fn release(layout: BindGroupLayout) void {
    layout.vtable.release(layout.ptr);
}

pub inline fn setLabel(group: BindGroupLayout, label: [:0]const u8) void {
    group.vtable.setLabel(group.ptr, label);
}

pub const Descriptor = struct {
    label: ?[*:0]const u8 = null,
    entries: []const Entry,
};

// TODO: can this be extern struct / ABI compatible?
pub const Entry = struct {
    binding: u32,
    visibility: ShaderStage,
    buffer: Buffer.BindingLayout,
    sampler: Sampler.BindingLayout,
    texture: Texture.BindingLayout,
    storage_texture: StorageTextureBindingLayout,
};

test "syntax" {
    _ = VTable;
    _ = reference;
    _ = release;
    _ = setLabel;
    _ = Descriptor;
    _ = Entry;
}
