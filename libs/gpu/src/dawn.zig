const ChainedStruct = @import("main.zig").ChainedStruct;
const ChainedStructOut = @import("main.zig").ChainedStructOut;
const PowerPreference = @import("main.zig").PowerPreference;
const Texture = @import("texture.zig").Texture;
pub const Interface = @import("dawn_impl.zig").Interface;

pub const CacheDeviceDescriptor = extern struct {
    chain: ChainedStruct = .{ .next = null, .s_type = .dawn_cache_device_descriptor },
    isolation_key: [*:0]const u8 = "",
};

pub const EncoderInternalUsageDescriptor = extern struct {
    chain: ChainedStruct = .{ .next = null, .s_type = .dawn_encoder_internal_usage_descriptor },
    use_internal_usages: bool = false,
};

pub const InstanceDescriptor = extern struct {
    chain: ChainedStruct = .{ .next = null, .s_type = .dawn_instance_descriptor },
    additional_runtime_search_paths_count: u32 = 0,
    additional_runtime_search_paths: ?[*]const [*:0]const u8 = null,

    /// Provides a slightly friendlier Zig API to initialize this structure.
    pub inline fn init(v: struct {
        chain: ChainedStruct = .{ .next = null, .s_type = .dawn_instance_descriptor },
        additional_runtime_search_paths: ?[]const [*:0]const u8 = null,
    }) InstanceDescriptor {
        return .{
            .chain = v.chain,
            .additional_runtime_search_paths_count = if (v.additional_runtime_search_paths) |e| @intCast(u32, e.len) else 0,
            .additional_runtime_search_paths = if (v.additional_runtime_search_paths) |e| e.ptr else null,
        };
    }
};

pub const TextureInternalUsageDescriptor = extern struct {
    chain: ChainedStruct = .{ .next = null, .s_type = .dawn_texture_internal_usage_descriptor },
    internal_usage: Texture.UsageFlags = Texture.UsageFlags.none,
};

pub const TogglesDeviceDescriptor = extern struct {
    chain: ChainedStruct = .{ .next = null, .s_type = .dawn_toggles_device_descriptor },
    force_enabled_toggles_count: u32 = 0,
    force_enabled_toggles: ?[*]const [*:0]const u8 = null,
    force_disabled_toggles_count: u32 = 0,
    force_disabled_toggles: ?[*]const [*:0]const u8 = null,

    /// Provides a slightly friendlier Zig API to initialize this structure.
    pub inline fn init(v: struct {
        chain: ChainedStruct = .{ .next = null, .s_type = .dawn_toggles_device_descriptor },
        force_enabled_toggles: ?[]const [*:0]const u8 = null,
        force_disabled_toggles: ?[]const [*:0]const u8 = null,
    }) TogglesDeviceDescriptor {
        return .{
            .chain = v.chain,
            .force_enabled_toggles_count = if (v.force_enabled_toggles) |e| @intCast(u32, e.len) else 0,
            .force_enabled_toggles = if (v.force_enabled_toggles) |e| e.ptr else null,
            .force_disabled_toggles_count = if (v.force_disabled_toggles) |e| @intCast(u32, e.len) else 0,
            .force_disabled_toggles = if (v.force_disabled_toggles) |e| e.ptr else null,
        };
    }
};

pub const AdapterPropertiesPowerPreference = extern struct {
    chain: ChainedStructOut = .{
        .next = null,
        .s_type = .dawn_adapter_properties_power_preference,
    },
    power_preference: PowerPreference = .undefined,
};

pub const BufferDescriptorErrorInfoFromWireClient = extern struct {
    chain: ChainedStruct = .{
        .next = null,
        .s_type = .dawn_buffer_descriptor_error_info_from_wire_client,
    },
    out_of_memory: bool = false,
};
