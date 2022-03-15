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
    setLabel: fn (ptr: *anyopaque, label: [:0]const u8) void,
    mapAsync: fn (
        ptr: *anyopaque,
        mode: MapMode,
        offset: usize,
        size: usize,
        callback: *MapCallback,
    ) void,
    unmap: fn (ptr: *anyopaque) void,
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

pub inline fn mapAsync(
    buf: Buffer,
    mode: MapMode,
    offset: usize,
    size: usize,
    callback: *MapCallback,
) void {
    buf.vtable.mapAsync(buf.ptr, mode, offset, size, callback);
}

pub const MapCallback = struct {
    type_erased_ctx: *anyopaque,
    type_erased_callback: fn (ctx: *anyopaque, status: MapAsyncStatus) callconv(.Inline) void,

    pub fn init(
        comptime Context: type,
        ctx: *Context,
        comptime callback: fn (ctx: *Context, status: MapAsyncStatus) void,
    ) MapCallback {
        const erased = (struct {
            pub inline fn erased(type_erased_ctx: *anyopaque, status: MapAsyncStatus) void {
                callback(@ptrCast(*Context, @alignCast(@alignOf(*Context), type_erased_ctx)), status);
            }
        }).erased;

        return .{
            .type_erased_ctx = ctx,
            .type_erased_callback = erased,
        };
    }
};

pub inline fn unmap(buf: Buffer) void {
    buf.vtable.unmap(buf.ptr);
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

pub const MapMode = enum(u32) {
    none = 0x00000000,
    read = 0x00000001,
    write = 0x00000002,
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
    _ = MapMode;
}
