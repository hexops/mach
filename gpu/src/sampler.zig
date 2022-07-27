const ChainedStruct = @import("types.zig").ChainedStruct;
const FilterMode = @import("types.zig").FilterMode;
const CompareFunction = @import("types.zig").CompareFunction;
const Impl = @import("interface.zig").Impl;

pub const Sampler = *opaque {
    pub inline fn setLabel(sampler: Sampler, label: [*:0]const u8) void {
        Impl.samplerSetLabel(sampler, label);
    }

    pub inline fn reference(sampler: Sampler) void {
        Impl.samplerReference(sampler);
    }

    pub inline fn release(sampler: Sampler) void {
        Impl.samplerRelease(sampler);
    }
};

pub const SamplerAddressMode = enum(u32) {
    repeat = 0x00000000,
    mirror_repeat = 0x00000001,
    clamp_to_edge = 0x00000002,
};

pub const SamplerBindingType = enum(u32) {
    undef = 0x00000000,
    filtering = 0x00000001,
    non_filtering = 0x00000002,
    comparison = 0x00000003,
};

pub const SamplerBindingLayout = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    type: SamplerBindingType = .undef,
};

pub const SamplerDescriptor = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    label: ?[*:0]const u8 = null,
    address_mode_u: SamplerAddressMode = .clamp_to_edge,
    address_mode_v: SamplerAddressMode = .clamp_to_edge,
    address_mode_w: SamplerAddressMode = .clamp_to_edge,
    mag_filter: FilterMode = .nearest,
    min_filter: FilterMode = .nearest,
    mipmap_filter: FilterMode = .nearest,
    lod_min_clamp: f32 = 0.0,
    lod_max_clamp: f32 = 1000.0,
    compare: CompareFunction = .undef,
    max_anisotropy: u16 = 1,
};
