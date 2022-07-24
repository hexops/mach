const ChainedStruct = @import("types.zig").ChainedStruct;
const PresentMode = @import("types.zig").PresentMode;
const Texture = @import("texture.zig").Texture;
const TextureUsageFlags = @import("texture.zig").TextureUsageFlags;
const TextureFormat = @import("texture.zig").TextureFormat;

pub const SwapChain = *opaque {};

pub const SwapChainDescriptor = extern struct {
    next_in_chain: *const ChainedStruct,
    label: ?[*:0]const u8 = null,
    usage: TextureUsageFlags,
    format: TextureFormat,
    width: u32,
    height: u32,
    present_mode: PresentMode,
    implementation: u64,
};
