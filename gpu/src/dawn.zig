const ChainedStruct = @import("types.zig").ChainedStruct;
const Texture = @import("texture.zig").Texture;
pub const Interface = @import("dawn_impl.zig").Interface;

/// TODO: Can be chained in gpu.Device.Descriptor
pub const CacheDeviceDescriptor = extern struct {
    chain: ChainedStruct,
    isolation_key: [*:0]const u8 = "",
};

/// TODO: Can be chained in gpu.CommandEncoder.Descriptor
pub const EncoderInternalUsageDescriptor = extern struct {
    chain: ChainedStruct,
    use_internal_usages: bool = false,
};

/// TODO: Can be chained in gpu.Instance.Descriptor
pub const InstanceDescriptor = extern struct {
    chain: ChainedStruct,
    // TODO: slice helper
    additional_runtime_search_paths_count: u32 = 0,
    additional_runtime_search_paths: ?[*]const u8 = null,
};

/// TODO: Can be chained in gpu.Texture.Descriptor
pub const TextureInternalUsageDescriptor = extern struct {
    chain: ChainedStruct,
    internal_usage: Texture.UsageFlags = Texture.UsageFlags.none,
};

/// TODO: Can be chained in gpu.Device.Descriptor
pub const TogglesDeviceDescriptor = extern struct {
    chain: ChainedStruct,
    // TODO: slice helper
    force_enabled_toggles_count: u32 = 0,
    force_enabled_toggles: ?[*]const u8 = null,
    // TODO: slice helper
    force_disabled_toggles_count: u32 = 0,
    force_disabled_toggles: ?[*]const u8 = null,
};
