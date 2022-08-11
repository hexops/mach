const ChainedStruct = @import("types.zig").ChainedStruct;
const ShaderStageFlags = @import("types.zig").ShaderStageFlags;
const Buffer = @import("buffer.zig").Buffer;
const Sampler = @import("sampler.zig").Sampler;
const Texture = @import("texture.zig").Texture;
const StorageTextureBindingLayout = @import("types.zig").StorageTextureBindingLayout;
const Impl = @import("interface.zig").Impl;

pub const BindGroupLayout = opaque {
    pub const Entry = extern struct {
        next_in_chain: ?*const ChainedStruct = null,
        binding: u32,
        visibility: ShaderStageFlags,
        buffer: Buffer.BindingLayout,
        sampler: Sampler.BindingLayout,
        texture: Texture.BindingLayout,
        storage_texture: StorageTextureBindingLayout,
    };

    pub const Descriptor = extern struct {
        next_in_chain: ?*const ChainedStruct = null,
        label: ?[*:0]const u8 = null,
        entry_count: u32 = 0,
        entries: ?[*]const Entry = null,
    };

    pub inline fn setLabel(bind_group_layout: *BindGroupLayout, label: [*:0]const u8) void {
        Impl.bindGroupLayoutSetLabel(bind_group_layout, label);
    }

    pub inline fn reference(bind_group_layout: *BindGroupLayout) void {
        Impl.bindGroupLayoutReference(bind_group_layout);
    }

    pub inline fn release(bind_group_layout: *BindGroupLayout) void {
        Impl.bindGroupLayoutRelease(bind_group_layout);
    }
};
