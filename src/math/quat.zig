const std = @import("std");

const mach = @import("../main.zig");
const testing = mach.testing;
const math = mach.math;
const vec = @import("vec.zig");

pub fn Quat(comptime Scalar: type) type {
    return extern struct {
        v: vec.Vec(4, Scalar),

        /// The scalar type of this matrix, e.g. Mat3x3.T == f32
        pub const T = Vec.T;

        /// The underlying Vec type, e.g. math.Vec4, math.Vec4h, math.Vec4d
        pub const Vec = vec.Vec(4, Scalar);

        pub inline fn init(x: T, y: T, z: T, w: T) Quat(Scalar) {
            return .{ .v = math.vec4(x, y, z, w) };
        }
    };
}

test "zero_struct_overhead" {
    // Proof that using Quat is equal to @Vector(4, f32)
    try testing.expect(usize, @alignOf(@Vector(4, f32))).eql(@alignOf(math.Quat));
    try testing.expect(usize, @sizeOf(@Vector(4, f32))).eql(@sizeOf(math.Quat));
}

test "init" {
    try testing.expect(math.Quat, math.quat(1, 2, 3, 4)).eql(math.Quat{
        .v = math.vec4(1, 2, 3, 4),
    });
}
