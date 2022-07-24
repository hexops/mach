const ChainedStruct = @import("types.zig").ChainedStruct;
const ShaderStageFlags = @import("types.zig").ShaderStageFlags;
const Buffer = @import("buffer.zig").Buffer;
const Sampler = @import("sampler.zig").Sampler;
const Texture = @import("texture.zig").Texture;
const StorageTextureBindingLayout = @import("types.zig").StorageTextureBindingLayout;

pub const BindGroupLayout = *opaque {};

pub const BindGroupLayoutEntry = extern struct {
    next_in_chain: *const ChainedStruct,
    binding: u32,
    visibility: ShaderStageFlags,
    buffer: Buffer.BindingLayout,
    sampler: Sampler.BindingLayout,
    texture: Texture.BindingLayout,
    storage_texture: StorageTextureBindingLayout,
};

pub const BindGroupLayoutDescriptor = extern struct {
    next_in_chain: *const ChainedStruct,
    label: ?[*:0]const u8 = null,
    entry_count: u32,
    entries: [*]const BindGroupLayoutEntry,
};
