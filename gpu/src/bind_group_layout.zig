const ChainedStruct = @import("types.zig").ChainedStruct;
const ShaderStageFlags = @import("types.zig").ShaderStageFlags;
const Buffer = @import("buffer.zig").Buffer;
const BufferBindingLayout = @import("buffer.zig").BufferBindingLayout;
const Sampler = @import("sampler.zig").Sampler;
const SamplerBindingLayout = @import("sampler.zig").SamplerBindingLayout;
const Texture = @import("texture.zig").Texture;
const TextureBindingLayout = @import("texture.zig").TextureBindingLayout;
const StorageTextureBindingLayout = @import("types.zig").StorageTextureBindingLayout;

pub const BindGroupLayout = *opaque {};

pub const BindGroupLayoutEntry = extern struct {
    next_in_chain: *const ChainedStruct,
    binding: u32,
    visibility: ShaderStageFlags,
    buffer: BufferBindingLayout,
    sampler: SamplerBindingLayout,
    texture: TextureBindingLayout,
    storage_texture: StorageTextureBindingLayout,
};

pub const BindGroupLayoutDescriptor = extern struct {
    next_in_chain: *const ChainedStruct,
    label: ?[*:0]const u8 = null,
    entry_count: u32,
    entries: [*]const BindGroupLayoutEntry,
};
