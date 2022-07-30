const ChainedStruct = @import("types.zig").ChainedStruct;
const ShaderStageFlags = @import("types.zig").ShaderStageFlags;
const Buffer = @import("buffer.zig").Buffer;
const BufferBindingLayout = @import("buffer.zig").BufferBindingLayout;
const Sampler = @import("sampler.zig").Sampler;
const SamplerBindingLayout = @import("sampler.zig").SamplerBindingLayout;
const Texture = @import("texture.zig").Texture;
const TextureBindingLayout = @import("texture.zig").TextureBindingLayout;
const StorageTextureBindingLayout = @import("types.zig").StorageTextureBindingLayout;
const Impl = @import("interface.zig").Impl;

pub const BindGroupLayout = opaque {
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

pub const BindGroupLayoutEntry = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    binding: u32,
    visibility: ShaderStageFlags,
    buffer: BufferBindingLayout,
    sampler: SamplerBindingLayout,
    texture: TextureBindingLayout,
    storage_texture: StorageTextureBindingLayout,
};

pub const BindGroupLayoutDescriptor = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    label: ?[*:0]const u8 = null,
    entry_count: u32,
    // TODO: file a bug on Dawn, this is not marked as nullable but in fact is.
    entries: ?[*]const BindGroupLayoutEntry,
};
