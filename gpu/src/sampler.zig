const ChainedStruct = @import("types.zig").ChainedStruct;

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
};
