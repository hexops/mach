const Bool32 = @import("main.zig").Bool32;
const ChainedStruct = @import("main.zig").ChainedStruct;
const ChainedStructOut = @import("main.zig").ChainedStructOut;
const PowerPreference = @import("main.zig").PowerPreference;
const Texture = @import("texture.zig").Texture;

pub const CacheDeviceDescriptor = extern struct {
    chain: ChainedStruct = .{ .next = null, .s_type = .dawn_cache_device_descriptor },
    isolation_key: [*:0]const u8 = "",
};

pub const EncoderInternalUsageDescriptor = extern struct {
    chain: ChainedStruct = .{ .next = null, .s_type = .dawn_encoder_internal_usage_descriptor },
    use_internal_usages: Bool32 = .false,
};

pub const MultisampleStateRenderToSingleSampled = extern struct {
    chain: ChainedStruct = .{ .next = null, .s_type = .dawn_multisample_state_render_to_single_sampled },
    enabled: Bool32 = .false,
};

pub const RenderPassColorAttachmentRenderToSingleSampled = extern struct {
    chain: ChainedStruct = .{ .next = null, .s_type = .dawn_render_pass_color_attachment_render_to_single_sampled },
    implicit_sample_count: u32 = 1,
};

pub const TextureInternalUsageDescriptor = extern struct {
    chain: ChainedStruct = .{ .next = null, .s_type = .dawn_texture_internal_usage_descriptor },
    internal_usage: Texture.UsageFlags = Texture.UsageFlags.none,
};

pub const TogglesDescriptor = extern struct {
    chain: ChainedStruct = .{ .next = null, .s_type = .dawn_toggles_descriptor },
    enabled_toggles_count: usize = 0,
    enabled_toggles: ?[*]const [*:0]const u8 = null,
    disabled_toggles_count: usize = 0,
    disabled_toggles: ?[*]const [*:0]const u8 = null,

    /// Provides a slightly friendlier Zig API to initialize this structure.
    pub inline fn init(v: struct {
        chain: ChainedStruct = .{ .next = null, .s_type = .dawn_toggles_descriptor },
        enabled_toggles: ?[]const [*:0]const u8 = null,
        disabled_toggles: ?[]const [*:0]const u8 = null,
    }) TogglesDescriptor {
        return .{
            .chain = v.chain,
            .enabled_toggles_count = if (v.enabled_toggles) |e| e.len else 0,
            .enabled_toggles = if (v.enabled_toggles) |e| e.ptr else null,
            .disabled_toggles_count = if (v.disabled_toggles) |e| e.len else 0,
            .disabled_toggles = if (v.disabled_toggles) |e| e.ptr else null,
        };
    }
};

pub const ShaderModuleSPIRVOptionsDescriptor = extern struct {
    chain: ChainedStruct = .{ .next = null, .s_type = .dawn_shader_module_spirv_options_descriptor },
    allow_non_uniform_derivatives: Bool32 = .false,
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
    out_of_memory: Bool32 = .false,
};
