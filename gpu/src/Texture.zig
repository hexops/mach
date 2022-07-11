ptr: *anyopaque,

pub const Aspect = enum(u32) {
    all = 0x00000000,
    stencil_only = 0x00000001,
    depth_only = 0x00000002,
    plane0_only = 0x00000003,
    plane1_only = 0x00000004,
};

pub const ComponentType = enum(u32) {
    float = 0x00000000,
    sint = 0x00000001,
    uint = 0x00000002,
    depth_comparison = 0x00000003,
};

pub const Dimension = enum(u32) {
    dimension_1d = 0x00000000,
    dimension_2d = 0x00000001,
    dimension_3d = 0x00000002,
};
