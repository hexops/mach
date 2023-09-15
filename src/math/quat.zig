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

        /// The Vec type used to represent axes, e.g. math.Vec3
        pub const Axis = vec.Vec(3, Scalar);

        pub inline fn init(x: T, y: T, z: T, w: T) Quat(Scalar) {
            return .{ .v = math.vec4(x, y, z, w) };
        }

        /// Creates a Quaternion based on the given `axis` and `angle`, and returns it.
        pub inline fn fromAxisAngle(axis: Axis, angle: T) Quat(Scalar) {
            const halfAngle = angle * 0.5;
            const s = std.math.sin(halfAngle);

            return init(s * axis[0], s * axis[1], s * axis[2], std.math.cos(halfAngle));
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

test "fromAxisAngle" {
    const expected = math.Quat.init(0.383, 0.0, 0.0, 0.924); // Expected values for a 45-degree rotation around the x-axis
    const actual = math.Quat.fromAxisAngle(math.Axis{ .x = 1.0 }, 0.785398); // 45 degrees in radians (π/4) around the x-axis

    try testing.expect(math.Quat, actual).eql(expected);
}
