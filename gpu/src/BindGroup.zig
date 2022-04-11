const Buffer = @import("Buffer.zig");
const Sampler = @import("Sampler.zig");
const TextureView = @import("TextureView.zig");
const BindGroupLayout = @import("BindGroupLayout.zig");

const BindGroup = @This();

/// The type erased pointer to the BindGroup implementation
/// Equal to c.WGPUBindGroup for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    setLabel: fn (ptr: *anyopaque, label: [:0]const u8) void,
};

pub inline fn reference(group: BindGroup) void {
    group.vtable.reference(group.ptr);
}

pub inline fn release(group: BindGroup) void {
    group.vtable.release(group.ptr);
}

pub inline fn setLabel(group: BindGroup, label: [:0]const u8) void {
    group.vtable.setLabel(group.ptr, label);
}

pub const Entry = struct {
    binding: u32,
    buffer: ?Buffer = null,
    offset: u64 = 0,
    size: u64,
    sampler: ?Sampler = null,
    texture_view: ?TextureView = null,

    /// Helper to create a buffer BindGroup.Entry.
    pub fn buffer(binding: u32, buf: Buffer, offset: u64, size: u64) Entry {
        return .{
            .binding = binding,
            .buffer = buf,
            .offset = offset,
            .size = size,
        };
    }

    /// Helper to create a sampler BindGroup.Entry.
    pub fn sampler(binding: u32, sam: Sampler) Entry {
        return .{
            .binding = binding,
            .sampler = sam,
            .size = 0,
        };
    }

    /// Helper to create a texture view BindGroup.Entry.
    pub fn textureView(binding: u32, texview: TextureView) Entry {
        return .{
            .binding = binding,
            .texture_view = texview,
            .size = 0,
        };
    }
};

pub const Descriptor = struct {
    label: ?[*:0]const u8 = null,
    layout: BindGroupLayout,
    entries: []const Entry,
};

test {
    _ = VTable;
    _ = reference;
    _ = release;
    _ = setLabel;
    _ = Entry;
    _ = Descriptor;
}
