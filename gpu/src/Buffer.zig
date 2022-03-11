const BufferUsage = @import("enums.zig").BufferUsage;

const Buffer = @This();

/// The type erased pointer to the Buffer implementation
/// Equal to c.WGPUBuffer for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    destroy: fn (ptr: *anyopaque) void,
    // TODO:
    // WGPU_EXPORT void const * wgpuBufferGetConstMappedRange(WGPUBuffer buffer, size_t offset, size_t size);
    // WGPU_EXPORT void * wgpuBufferGetMappedRange(WGPUBuffer buffer, size_t offset, size_t size);
    // WGPU_EXPORT void wgpuBufferMapAsync(WGPUBuffer buffer, WGPUMapModeFlags mode, size_t offset, size_t size, WGPUBufferMapCallback callback, void * userdata);
    setLabel: fn (ptr: *anyopaque, label: [:0]const u8) void,
    // WGPU_EXPORT void wgpuBufferUnmap(WGPUBuffer buffer);
};

pub inline fn reference(buf: Buffer) void {
    buf.vtable.reference(buf.ptr);
}

pub inline fn release(buf: Buffer) void {
    buf.vtable.release(buf.ptr);
}

pub inline fn destroy(buf: Buffer) void {
    buf.vtable.destroy(buf.ptr);
}

pub inline fn setLabel(buf: Buffer, label: [:0]const u8) void {
    buf.vtable.setLabel(buf.ptr, label);
}

pub const Descriptor = struct {
    label: ?[*:0]const u8 = null,
    usage: BufferUsage,
    size: usize,
    mapped_at_creation: bool,
};

pub const BindingType = enum(u32) {
    none = 0x00000000,
    uniform = 0x00000001,
    storage = 0x00000002,
    read_only_storage = 0x00000003,
};

pub const BindingLayout = struct {
    type: BindingType,
    has_dynamic_offset: bool,
    min_binding_size: u64,
};

pub const MapAsyncStatus = enum(u32) {
    success = 0x00000000,
    err = 0x00000001,
    unknown = 0x00000002,
    device_lost = 0x00000003,
    destroyed_before_callback = 0x00000004,
    unmapped_before_callback = 0x00000005,
};

test "syntax" {
    _ = VTable;
    _ = reference;
    _ = release;
    _ = destroy;
    _ = setLabel;
    _ = Descriptor;
    _ = BindingType;
    _ = BindingLayout;
    _ = MapAsyncStatus;
}
