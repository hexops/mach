const std = @import("std");

const mach = @import("../main.zig");
const testing = mach.testing;
const math = mach.math;

pub fn Vec(comptime n_value: usize, comptime Scalar: type) type {
    return extern struct {
        v: Vector,

        /// The vector dimension size, e.g. Vec3.n == 3
        pub const n = n_value;

        /// The scalar type of this vector, e.g. Vec3.T == f32
        pub const T = Scalar;

        // The underlying @Vector type
        pub const Vector = @Vector(n_value, Scalar);

        const VecN = @This();

        pub usingnamespace switch (VecN.n) {
            inline 2 => struct {
                pub inline fn init(xs: Scalar, ys: Scalar) VecN {
                    return .{ .v = .{ xs, ys } };
                }
                pub inline fn x(v: *const VecN) Scalar {
                    return v.v[0];
                }
                pub inline fn y(v: *const VecN) Scalar {
                    return v.v[1];
                }
            },
            inline 3 => struct {
                pub inline fn init(xs: Scalar, ys: Scalar, zs: Scalar) VecN {
                    return .{ .v = .{ xs, ys, zs } };
                }
                pub inline fn x(v: *const VecN) Scalar {
                    return v.v[0];
                }
                pub inline fn y(v: *const VecN) Scalar {
                    return v.v[1];
                }
                pub inline fn z(v: *const VecN) Scalar {
                    return v.v[2];
                }

                // TODO(math): come up with a better strategy for swizzling?
                pub inline fn yzw(v: *const VecN) VecN {
                    return VecN.init(v.y(), v.z(), v.w());
                }
                pub inline fn zxy(v: *const VecN) VecN {
                    return VecN.init(v.z(), v.x(), v.y());
                }

                /// Calculates the cross product between vector a and b. This can be done only in 3D
                /// and required inputs are Vec3.
                pub inline fn cross(a: *const VecN, b: *const VecN) VecN {
                    // https://gamemath.com/book/vectors.html#cross_product
                    const s1 = a.yzx().mul(b.zxy());
                    const s2 = a.zxy().mul(b.yzx());
                    return s1.sub(s2);
                }
            },
            inline 4 => struct {
                pub inline fn init(xs: Scalar, ys: Scalar, zs: Scalar, ws: Scalar) VecN {
                    return .{ .v = .{ xs, ys, zs, ws } };
                }
                pub inline fn x(v: *const VecN) Scalar {
                    return v.v[0];
                }
                pub inline fn y(v: *const VecN) Scalar {
                    return v.v[1];
                }
                pub inline fn z(v: *const VecN) Scalar {
                    return v.v[2];
                }
                pub inline fn w(v: *const VecN) Scalar {
                    return v.v[3];
                }
            },
            else => @compileError("Expected Vec2, Vec3, Vec4, found '" ++ @typeName(VecN) ++ "'"),
        };

        /// Element-wise addition
        pub inline fn add(a: *const VecN, b: *const VecN) VecN {
            return .{ .v = a.v + b.v };
        }

        /// Element-wise subtraction
        pub inline fn sub(a: *const VecN, b: *const VecN) VecN {
            return .{ .v = a.v - b.v };
        }

        /// Element-wise division
        pub inline fn div(a: *const VecN, b: *const VecN) VecN {
            return .{ .v = a.v / b.v };
        }

        /// Element-wise multiplication.
        ///
        /// See also .cross()
        pub inline fn mul(a: *const VecN, b: *const VecN) VecN {
            return .{ .v = a.v * b.v };
        }

        /// Scalar addition
        pub inline fn addScalar(a: *const VecN, s: Scalar) VecN {
            return .{ .v = a.v + VecN.splat(s).v };
        }

        /// Scalar subtraction
        pub inline fn subScalar(a: *const VecN, s: Scalar) VecN {
            return .{ .v = a.v - VecN.splat(s).v };
        }

        /// Scalar division
        pub inline fn divScalar(a: *const VecN, s: Scalar) VecN {
            return .{ .v = a.v / VecN.splat(s).v };
        }

        /// Scalar multiplication.
        ///
        /// See .dot() for the dot product
        pub inline fn mulScalar(a: *const VecN, s: Scalar) VecN {
            return .{ .v = a.v * VecN.splat(s).v };
        }

        /// Element-wise a < b
        pub inline fn less(a: *const VecN, b: Scalar) bool {
            return a.v < b.v;
        }

        /// Element-wise a <= b
        pub inline fn lessEq(a: *const VecN, b: Scalar) bool {
            return a.v <= b.v;
        }

        /// Element-wise a > b
        pub inline fn greater(a: *const VecN, b: Scalar) bool {
            return a.v > b.v;
        }

        /// Element-wise a >= b
        pub inline fn greaterEq(a: *const VecN, b: Scalar) bool {
            return a.v >= b.v;
        }

        /// Returns a vector with all components set to the `scalar` value:
        ///
        /// ```
        /// var v = Vec3.splat(1337.0).v;
        /// // v.x == 1337, v.y == 1337, v.z == 1337
        /// ```
        pub inline fn splat(scalar: Scalar) VecN {
            return .{ .v = @splat(scalar) };
        }

        /// Computes the squared length of the vector. Faster than `len()`
        pub inline fn len2(v: *const VecN) Scalar {
            return switch (VecN.n) {
                inline 2 => (v.x() * v.x()) + (v.y() * v.y()),
                inline 3 => (v.x() * v.x()) + (v.y() * v.y()) + (v.z() * v.z()),
                inline 4 => (v.x() * v.x()) + (v.y() * v.y()) + (v.z() * v.z()) + (v.w() * v.w()),
                else => @compileError("Expected Vec2, Vec3, Vec4, found '" ++ @typeName(VecN) ++ "'"),
            };
        }

        /// Computes the length of the vector.
        pub inline fn len(v: *const VecN) Scalar {
            return math.sqrt(len2(v));
        }

        /// Normalizes a vector, such that all components end up in the range [0.0, 1.0].
        ///
        /// d0 is added to the divisor, which means that e.g. if you provide a near-zero value, then in
        /// situations where you would otherwise get NaN back you will instead get a near-zero vector.
        ///
        /// ```
        /// math.vec3(1.0, 2.0, 3.0).normalize(v, 0.00000001);
        /// ```
        pub inline fn normalize(v: *const VecN, d0: Scalar) VecN {
            return v.div(&VecN.splat(v.len() + d0));
        }

        /// Returns the normalized direction vector from points a and b.
        ///
        /// d0 is added to the divisor, which means that e.g. if you provide a near-zero value, then in
        /// situations where you would otherwise get NaN back you will instead get a near-zero vector.
        ///
        /// ```
        /// var v = a_point.dir(b_point, 0.0000001);
        /// ```
        pub inline fn dir(a: *const VecN, b: *const VecN, d0: Scalar) VecN {
            return b.sub(a).normalize(d0);
        }

        /// Calculates the squared distance between points a and b. Faster than `dist()`.
        pub inline fn dist2(a: *const VecN, b: *const VecN) Scalar {
            return b.sub(a).len2();
        }

        /// Calculates the distance between points a and b.
        pub inline fn dist(a: *const VecN, b: *const VecN) Scalar {
            return math.sqrt(a.dist2(b));
        }

        /// Performs linear interpolation between a and b by some amount.
        ///
        /// ```
        /// a.lerp(b, 0.0) == a
        /// a.lerp(b, 1.0) == b
        /// ```
        pub inline fn lerp(a: *const VecN, b: *const VecN, amount: Scalar) VecN {
            return a.mulScalar(1.0 - amount).add(&b.mulScalar(amount));
        }

        /// Calculates the dot product between vector a and b and returns scalar.
        pub inline fn dot(a: *const VecN, b: *const VecN) Scalar {
            return .{ .v = @reduce(.Add, a.v * b.v) };
        }
    };
}

test "gpu_compatibility" {
    // https://www.w3.org/TR/WGSL/#alignment-and-size
    try testing.expect(usize, 8).eql(@sizeOf(math.Vec2)); // WGSL AlignOf 8, SizeOf 8
    try testing.expect(usize, 16).eql(@sizeOf(math.Vec3)); // WGSL AlignOf 16, SizeOf 12
    try testing.expect(usize, 16).eql(@sizeOf(math.Vec4)); // WGSL AlignOf 16, SizeOf 16

    try testing.expect(usize, 4).eql(@sizeOf(math.Vec2h)); // WGSL AlignOf 4, SizeOf 4
    try testing.expect(usize, 8).eql(@sizeOf(math.Vec3h)); // WGSL AlignOf 8, SizeOf 6
    try testing.expect(usize, 8).eql(@sizeOf(math.Vec4h)); // WGSL AlignOf 8, SizeOf 8

    try testing.expect(usize, 8 * 2).eql(@sizeOf(math.Vec2d)); // speculative
    try testing.expect(usize, 16 * 2).eql(@sizeOf(math.Vec3d)); // speculative
    try testing.expect(usize, 16 * 2).eql(@sizeOf(math.Vec4d)); // speculative
}

test "zero_struct_overhead" {
    // Proof that using Vec4 is equal to @Vector(4, f32)
    try testing.expect(usize, @alignOf(@Vector(4, f32))).eql(@alignOf(math.Vec4));
    try testing.expect(usize, @sizeOf(@Vector(4, f32))).eql(@sizeOf(math.Vec4));
}

test "dimensions" {
    try testing.expect(usize, 3).eql(math.Vec3.n);
}

test "type" {
    try testing.expect(type, f16).eql(math.Vec3h.T);
}

test "init" {
    try testing.expect(math.Vec3h, math.vec3h(1, 2, 3)).eql(math.vec3h(1, 2, 3));
}

test "splat" {
    try testing.expect(math.Vec3h, math.vec3h(1337, 1337, 1337)).eql(math.Vec3h.splat(1337));
}

test "swizzle_singular" {
    try testing.expect(f32, 1).eql(math.vec3(1, 2, 3).x());
    try testing.expect(f32, 2).eql(math.vec3(1, 2, 3).y());
    try testing.expect(f32, 3).eql(math.vec3(1, 2, 3).z());
}

test "len2" {
    try testing.expect(f32, 2).eql(math.vec2(1, 1).len2());
    try testing.expect(f32, 29).eql(math.vec3(2, 3, -4).len2());
    try testing.expect(f32, 38.115).eqlApprox(math.vec4(1.5, 2.25, 3.33, 4.44).len2(), 0.0001);
    try testing.expect(f32, 0).eql(math.vec4(0, 0, 0, 0).len2());
}

test "len" {
    try testing.expect(f32, 5).eql(math.vec2(3, 4).len());
    try testing.expect(f32, 6).eql(math.vec3(4, 4, 2).len());
    try testing.expect(f32, 6.17373468817700328621).eql(math.vec4(1.5, 2.25, 3.33, 4.44).len());
    try testing.expect(f32, 0).eql(math.vec4(0, 0, 0, 0).len());
}

test "normalize_example" {
    const normalized = math.vec4(10, 0.5, -3, -0.2).normalize(math.eps_f32);
    try testing.expect(math.Vec4, math.vec4(0.95, 0.05, -0.3, -0.02)).eqlApprox(normalized, 0.1);
}

test "normalize_accuracy" {
    const normalized = math.vec2(1, 1).normalize(0);
    const norm_val = std.math.sqrt1_2; // 1 / sqrt(2)
    try testing.expect(math.Vec2, math.Vec2.splat(norm_val)).eql(normalized);
}

test "normalize_nan" {
    const near_zero = 0.0;
    const normalized = math.vec2(0, 0).normalize(near_zero);
    try testing.expect(bool, true).eql(math.isNan(normalized.x()));
}

test "normalize_no_nan" {
    const near_zero = math.eps_f32;
    const normalized = math.vec2(0, 0).normalize(near_zero);
    try testing.expect(math.Vec2, math.vec2(0, 0)).eqlBinary(normalized);
}

// TODO(math): add basic tests for these:
//
// pub inline fn add(a: *const VecN, b: *const VecN) VecN {
// pub inline fn sub(a: *const VecN, b: *const VecN) VecN {
// pub inline fn div(a: *const VecN, b: *const VecN) VecN {
// pub inline fn mul(a: *const VecN, b: *const VecN) VecN {
// pub inline fn addScalar(a: *const VecN, s: Scalar) VecN {
// pub inline fn subScalar(a: *const VecN, s: Scalar) VecN {
// pub inline fn divScalar(a: *const VecN, s: Scalar) VecN {
// pub inline fn mulScalar(a: *const VecN, s: Scalar) VecN {

// TODO(math): the tests below violate our styleguide (https://machengine.org/about/style/) we
// should write new tests loosely based on them:

// test "vec.dir" {
//     const near_zero_value = 1e-8;

//     {
//         const a = Vec2{ 0, 0 };
//         const b = Vec2{ 0, 0 };
//         const d = vec.dir(a, b, near_zero_value);
//         try expect(d[0] == 0 and d[1] == 0);
//     }

//     {
//         const a = Vec2{ 1, 2 };
//         const b = Vec2{ 1, 2 };
//         const d = vec.dir(a, b, near_zero_value);
//         try expect(d[0] == 0 and d[1] == 0);
//     }

//     {
//         const a = Vec2{ 1, 2 };
//         const b = Vec2{ 3, 4 };
//         const d = vec.dir(a, b, 0);
//         const result = std.math.sqrt1_2; // 1 / sqrt(2)
//         try expect(d[0] == result and d[1] == result);
//     }

//     {
//         const a = Vec2{ 1, 2 };
//         const b = Vec2{ -1, -2 };
//         const d = vec.dir(a, b, 0);
//         const result = -0.44721359549995793928; // 1 / sqrt(5)
//         try expectApproxEqAbs(d[0], result, near_zero_value);
//         try expectApproxEqAbs(d[1], 2 * result, near_zero_value);
//     }

//     {
//         const a = Vec3{ 1, -1, 0 };
//         const b = Vec3{ 0, 1, 1 };
//         const d = vec.dir(a, b, 0);

//         const result_3 = 0.40824829046386301637; // 1 / sqrt(6)
//         const result_1 = -result_3; // -1 / sqrt(6)
//         const result_2 = 0.81649658092772603273; // sqrt(2/3)
//         try expectApproxEqAbs(d[0], result_1, 1e-7);
//         try expectApproxEqAbs(d[1], result_2, 1e-7);
//         try expectApproxEqAbs(d[2], result_3, 1e-7);
//     }
// }

// test "vec.dist2" {
//     {
//         const a = Vec4{ 0, 0, 0, 0 };
//         const b = Vec4{ 0, 0, 0, 0 };
//         try expect(vec.dist2(a, b) == 0);
//     }

//     {
//         const a = Vec2{ 1, 1 };
//         try expect(vec.dist2(a, a) == 0);
//     }

//     {
//         const a = Vec2{ 1, 2 };
//         const b = Vec2{ 3, 4 };
//         try expect(vec.dist2(a, b) == 8);
//     }

//     {
//         const a = Vec3{ -1, -2, -3 };
//         const b = Vec3{ 3, 2, 1 };
//         try expect(vec.dist2(a, b) == 48);
//     }

//     {
//         const a = Vec4{ 1.5, 2.25, 3.33, 4.44 };
//         const b = Vec4{ 1.44, -9.33, 7.25, -0.5 };
//         try expectApproxEqAbs(vec.dist2(a, b), 173.87, 1e-8);
//     }
// }

// test "vec.dist" {
//     {
//         const a = Vec4{ 0, 0, 0, 0 };
//         const b = Vec4{ 0, 0, 0, 0 };
//         try expect(vec.dist(a, b) == 0);
//     }

//     {
//         const a = Vec2{ 1, 1 };
//         try expect(vec.dist(a, a) == 0);
//     }

//     {
//         const a = Vec2{ 1, 2 };
//         const b = Vec2{ 4, 6 };
//         try expectEqual(vec.dist(a, b), 5);
//     }

//     {
//         const a = Vec3{ -1, -2, -3 };
//         const b = Vec3{ 3, 2, -1 };
//         try expect(vec.dist(a, b) == 6);
//     }

//     {
//         const a = Vec4{ 1.5, 2.25, 3.33, 4.44 };
//         const b = Vec4{ 1.44, -9.33, 7.25, -0.5 };
//         try expectApproxEqAbs(vec.dist(a, b), 13.18597740025364975978, 1e-8);
//     }
// }

// test "vec.lerp" {
//     {
//         const a = Vec4{ 1, 1, 1, 1 };
//         const b = Vec4{ 0, 0, 0, 0 };
//         const lerp_to_a = vec.lerp(a, b, 0.0);
//         try expectEqual(lerp_to_a[0], a[0]);
//         try expectEqual(lerp_to_a[1], a[1]);
//         try expectEqual(lerp_to_a[2], a[2]);
//         try expectEqual(lerp_to_a[3], a[3]);

//         const lerp_to_b = vec.lerp(a, b, 1.0);
//         try expectEqual(lerp_to_b[0], b[0]);
//         try expectEqual(lerp_to_b[1], b[1]);
//         try expectEqual(lerp_to_b[2], b[2]);
//         try expectEqual(lerp_to_b[3], b[3]);

//         const lerp_to_mid = vec.lerp(a, b, 0.5);
//         try expectEqual(lerp_to_mid[0], 0.5);
//         try expectEqual(lerp_to_mid[1], 0.5);
//         try expectEqual(lerp_to_mid[2], 0.5);
//         try expectEqual(lerp_to_mid[3], 0.5);
//     }
// }

// test "vec.cross" {
//     {
//         const a = Vec3{ 1, 3, 4 };
//         const b = Vec3{ 2, -5, 8 };
//         const cross = vec.cross(a, b);
//         try expectEqual(cross[0], 44);
//         try expectEqual(cross[1], 0);
//         try expectEqual(cross[2], -11);
//     }
//     {
//         const a = Vec3{ 1.0, 0.0, 0.0 };
//         const b = Vec3{ 0.0, 1.0, 0.0 };
//         const cross = vec.cross(a, b);
//         try expectEqual(cross[0], 0.0);
//         try expectEqual(cross[1], 0.0);
//         try expectEqual(cross[2], 1.0);
//     }
//     {
//         const a = Vec3{ 1.0, 0.0, 0.0 };
//         const b = Vec3{ 0.0, -1.0, 0.0 };
//         const cross = vec.cross(a, b);
//         try expectEqual(cross[0], 0.0);
//         try expectEqual(cross[1], 0.0);
//         try expectEqual(cross[2], -1.0);
//     }
//     {
//         const a = Vec3{ -3.0, 0.0, -2.0 };
//         const b = Vec3{ 5.0, -1.0, 2.0 };
//         const cross = vec.cross(a, b);
//         try expectEqual(cross[0], -2.0);
//         try expectEqual(cross[1], -4.0);
//         try expectEqual(cross[2], 3.0);
//     }
// }

// test "vec.dot" {
//     {
//         const a = Vec2{ -1, 2 };
//         const b = Vec2{ 4, 5 };
//         const dot = vec.dot(a, b);
//         try expectEqual(dot, 6);
//     }
//     {
//         const a = Vec3{ -1.0, 2.0, 3.0 };
//         const b = Vec3{ 4.0, 5.0, 6.0 };
//         const dot = vec.dot(a, b);
//         try expectEqual(dot, 24.0);
//     }
//     {
//         const a = Vec4{ -1.0, 2.0, 3.0, -2.0 };
//         const b = Vec4{ 4.0, 5.0, 6.0, 2.0 };
//         const dot = vec.dot(a, b);
//         try expectEqual(dot, 20.0);
//     }

//     {
//         const a = Vec4{ 0, 0, 0, 0 };
//         const b = Vec4{ 0, 0, 0, 0 };
//         const dot = vec.dot(a, b);
//         try expectEqual(dot, 0.0);
//     }
// }
