const ChainedStruct = @import("types.zig").ChainedStruct;
const ShaderStageFlags = @import("types.zig").ShaderStageFlags;
const Buffer = @import("buffer.zig").Buffer;
const Sampler = @import("sampler.zig").Sampler;
const Texture = @import("texture.zig").Texture;
const StorageTextureBindingLayout = @import("types.zig").StorageTextureBindingLayout;

pub const BindGroupLayout = enum(usize) {
    _,

    // TODO: verify there is a use case for nullable value of this type.
    pub const none: BindGroupLayout = @intToEnum(BindGroupLayout, 0);

    pub const Entry = extern struct {
        next_in_chain: *const ChainedStruct,
        binding: u32,
        visibility: ShaderStageFlags,
        buffer: Buffer.BindingLayout,
        sampler: Sampler.BindingLayout,
        texture: Texture.BindingLayout,
        storage_texture: StorageTextureBindingLayout,
    };
};
