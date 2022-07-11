ptr: *anyopaque,

pub const Dimension = enum(u32) {
    dimension_undef = 0x00000000,
    dimension_1d = 0x00000001,
    dimension_2d = 0x00000002,
    dimension_2d_array = 0x00000003,
    dimension_cube = 0x00000004,
    dimension_cube_array = 0x00000005,
    dimension_3d = 0x00000006,
};
