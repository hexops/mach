const ChainedStruct = @import("types.zig").ChainedStruct;
const FilterMode = @import("types.zig").FilterMode;
const CompareFunction = @import("types.zig").CompareFunction;

pub const Sampler = enum(usize) {
    _,

    pub const none: Sampler = @intToEnum(Sampler, 0);

    pub const AddressMode = enum(u32) {
        repeat = 0x00000000,
        mirror_repeat = 0x00000001,
        clamp_to_edge = 0x00000002,
    };

    pub const BindingType = enum(u32) {
        undef = 0x00000000,
        filtering = 0x00000001,
        non_filtering = 0x00000002,
        comparison = 0x00000003,
    };

    pub const BindingLayout = extern struct {
        next_in_chain: *const ChainedStruct,
        type: BindingType,
    };

    pub const Descriptor = extern struct {
        next_in_chain: *const ChainedStruct,
        label: ?[*:0]const u8 = null,
        address_mode_u: AddressMode,
        address_mode_v: AddressMode,
        address_mode_w: AddressMode,
        mag_filter: FilterMode,
        min_filter: FilterMode,
        mipmap_filter: FilterMode,
        lod_min_clamp: f32,
        lod_max_clamp: f32,
        compare: CompareFunction,
        max_anisotropy: u16,
    };
};
