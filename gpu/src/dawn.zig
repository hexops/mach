const ChainedStruct = @import("types.zig").ChainedStruct;
const Texture = @import("texture.zig").Texture;

pub const CacheDeviceDescriptor = struct {
    // TODO: file an issue on Dawn: why not named nextInChain?
    chain: ChainedStruct,
    isolation_key: [*:0]const u8,
};

pub const EncoderInternalUsageDescriptor = struct {
    // TODO: file an issue on Dawn: why not named nextInChain?
    chain: ChainedStruct,
    use_internal_usages: bool,
};

pub const InstanceDescriptor = extern struct {
    // TODO: file an issue on Dawn: why not named nextInChain?
    chain: ChainedStruct,
    additional_runtime_search_paths_count: u32,
    additional_runtime_search_paths: [*]const u8,
};

pub const TextureInternalUsageDescriptor = extern struct {
    // TODO: file an issue on Dawn: why not named nextInChain?
    chain: ChainedStruct,
    internal_usage: Texture.UsageFlags,
};
