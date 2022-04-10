const Buffer = @import("Buffer.zig");
const Sampler = @import("Sampler.zig");
const Texture = @import("Texture.zig");
const TextureView = @import("TextureView.zig");
const StorageTextureBindingLayout = @import("structs.zig").StorageTextureBindingLayout;
const StorageTextureAccess = @import("enums.zig").StorageTextureAccess;
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

pub const Entry = extern struct {
    reserved: ?*anyopaque = null,
    binding: u32,
    visibility: ShaderStage,
    buffer: Buffer.BindingLayout = .{ .type = .none },
    sampler: Sampler.BindingLayout = .{ .type = .none },
    texture: Texture.BindingLayout = .{ .sample_type = .none },
    storage_texture: StorageTextureBindingLayout = .{ .access = .none, .format = .none },

    /// Helper to create a buffer BindGroupLayout.Entry.
    pub fn buffer(
        binding: u32,
        visibility: ShaderStage,
        binding_type: Buffer.BindingType,
        has_dynamic_offset: bool,
        min_binding_size: u64,
    ) Entry {
        return .{
            .binding = binding,
            .visibility = visibility,
            .buffer = .{
                .type = binding_type,
                .has_dynamic_offset = has_dynamic_offset,
                .min_binding_size = min_binding_size,
            },
        };
    }

    /// Helper to create a sampler BindGroupLayout.Entry.
    pub fn sampler(binding: u32, visibility: ShaderStage, binding_type: Sampler.BindingType) Entry {
        return .{
            .binding = binding,
            .visibility = visibility,
            .sampler = .{ .type = binding_type },
        };
    }

    /// Helper to create a texture BindGroupLayout.Entry.
    pub fn texture(
        binding: u32,
        visibility: ShaderStage,
        sample_type: Texture.SampleType,
        view_dimension: TextureView.Dimension,
        multisampled: bool,
    ) Entry {
        return .{
            .binding = binding,
            .visibility = visibility,
            .texture = .{
                .sample_type = sample_type,
                .view_dimension = view_dimension,
                .multisampled = multisampled,
            },
        };
    }

    /// Helper to create a storage texture BindGroupLayout.Entry.
    pub fn storageTexture(
        binding: u32,
        visibility: ShaderStage,
        access: StorageTextureAccess,
        format: Texture.Format,
        view_dimension: TextureView.Dimension,
    ) Entry {
        return .{
            .binding = binding,
            .visibility = visibility,
            .storage_texture = .{
                .access = access,
                .format = format,
                .view_dimension = view_dimension,
            },
        };
    }
};

test {
    _ = VTable;
    _ = reference;
    _ = release;
    _ = setLabel;
    _ = Descriptor;
    _ = Entry;

    const desc = BindGroupLayout.Descriptor{
        .entries = &.{
            BindGroupLayout.Entry.buffer(0, .{ .vertex = true }, .uniform, true, 0),
            BindGroupLayout.Entry.sampler(1, .{ .vertex = true }, .filtering),
            BindGroupLayout.Entry.texture(2, .{ .fragment = true }, .float, .dimension_2d, false),
            BindGroupLayout.Entry.storageTexture(3, .{ .fragment = true }, .none, .rgba32_float, .dimension_2d),
        },
    };
    _ = desc;
}
