ptr: *anyopaque,

pub const Aspect = enum(u32) {
    all = 0x00000000,
    stencil_only = 0x00000001,
    depth_only = 0x00000002,
    plane0_only = 0x00000003,
    plane1_only = 0x00000004,
};
