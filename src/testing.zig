const std = @import("std");
const testing = std.testing;

const mach = @import("main.zig");
const math = mach.math;

fn ExpectFloat(comptime T: type) type {
    return struct {
        expected: T,

        /// Approximate (absolute epsilon tolerence) equality
        pub fn equal(e: *const @This(), actual: T) !void {
            try e.equalApprox(actual, math.eps(T));
        }

        /// Approximate (tolerence) equality
        pub fn equalApprox(e: *const @This(), actual: T, tolerance: T) !void {
            try testing.expectApproxEqAbs(e.expected, actual, tolerance);
        }

        /// Bitwise equality
        pub fn equalBinary(e: *const @This(), actual: T) !void {
            try testing.expectEqual(e.expected, actual);
        }
    };
}

fn ExpectVector(comptime T: type) type {
    const Elem = std.meta.Elem(T);
    const len = @typeInfo(T).Vector.len;
    return struct {
        expected: T,

        /// Approximate (absolute epsilon tolerence) equality
        pub fn equal(e: *const @This(), actual: T) !void {
            try e.equalApprox(actual, math.eps(Elem));
        }

        /// Approximate (tolerence) equality
        pub fn equalApprox(e: *const @This(), actual: T, tolerance: Elem) !void {
            var i: usize = 0;
            while (i < len) : (i += 1) {
                if (!math.equals(Elem, e.expected[i], actual[i], tolerance)) {
                    std.debug.print("vector[{}] actual {}, not within absolute tolerance {} of expected {}\n", .{ i, actual[i], tolerance, e.expected[i] });
                    return error.TestExpectEqualEps;
                }
            }
        }

        /// Bitwise equality
        pub fn equalBinary(e: *const @This(), actual: T) !void {
            try testing.expectEqual(e.expected, actual);
        }
    };
}

fn ExpectVecMat(comptime T: type) type {
    return struct {
        expected: T,

        /// Approximate (absolute epsilon tolerence) equality
        pub fn equal(e: *const @This(), actual: T) !void {
            try e.equalApprox(actual, math.eps(T.T));
        }

        /// Approximate (tolerence) equality
        pub fn equalApprox(e: *const @This(), actual: T, tolerance: T.T) !void {
            var i: usize = 0;
            while (i < T.n) : (i += 1) {
                if (!math.equals(T.T, e.expected.v[i], actual.v[i], tolerance)) {
                    std.debug.print("vector[{}] actual {}, not within absolute tolerance {} of expected {}\n", .{ i, actual.v[i], tolerance, e.expected.v[i] });
                    return error.TestExpectEqualEps;
                }
            }
        }

        /// Bitwise equality
        pub fn equalBinary(e: *const @This(), actual: T) !void {
            try testing.expectEqual(e.expected.v, actual.v);
        }
    };
}

fn ExpectComptime(comptime T: type) type {
    return struct {
        expected: T,
        pub fn equal(comptime e: *const @This(), comptime actual: T) !void {
            try testing.expectEqual(e.expected, actual);
        }
    };
}

fn ExpectBytes(comptime T: type) type {
    return struct {
        expected: T,

        pub fn equal(comptime e: *const @This(), comptime actual: T) !void {
            try testing.expectEqualStrings(e.expected, actual);
        }

        pub fn equalBinary(comptime e: *const @This(), comptime actual: T) !void {
            try testing.expectEqual(e.expected, actual);
        }
    };
}

fn Expect(comptime T: type) type {
    if (T == type) return ExpectComptime(T);
    if (T == f16 or T == f32 or T == f64) return ExpectFloat(T);
    if (T == []const u8) return ExpectBytes(T);
    if (@typeInfo(T) == .Vector) return ExpectVector(T);

    // Vector and matrix equality
    const is_vec2 = T == math.Vec2 or T == math.Vec2h or T == math.Vec2d;
    const is_vec3 = T == math.Vec3 or T == math.Vec3h or T == math.Vec3d;
    const is_vec4 = T == math.Vec4 or T == math.Vec4h or T == math.Vec4d;
    if (is_vec2 or is_vec3 or is_vec4) return ExpectVecMat(T);

    // Generic equality
    return struct {
        expected: T,
        pub fn equal(e: *const @This(), actual: T) !void {
            try testing.expectEqual(e.expected, actual);
        }
    };
}

/// Alternative to std.testing equality methods with:
///
/// * Less ambiguity about order of parameters
/// * Approximate absolute float equality by default
/// * Handling of vector and matrix types
///
/// Floats, mach.math.Vec, and mach.math.Mat types support:
///
/// * `.equal(v)` (epsilon equality)
/// * `.equalApprox(v, tolerence)` (specific tolerence equality)
/// * `.equalBinary(v)` binary equality
///
/// All other types support only `.equal(v)` binary equality.
///
/// Comparisons with std.testing:
///
/// ```diff
/// -std.testing.expectEqual(@as(u32, 1337), actual())
/// +mach.testing.expect(u32, 1337).equal(actual())
/// ```
///
/// ```diff
/// -std.testing.expectApproxEqAbs(@as(f32, 1.0), actual(), std.math.floatEps(f32))
/// +mach.testing.expect(f32, 1.0).equal(actual())
/// ```
///
/// ```diff
/// -std.testing.expectApproxEqAbs(@as(f32, 1.0), actual(), 0.1)
/// +mach.testing.expect(f32, 1.0).equalApprox(actual(), 0.1)
/// ```
///
/// ```diff
/// -std.testing.expectEqual(@as(f32, 1.0), actual())
/// +mach.testing.expect(f32, 1.0).equalBinary(actual())
/// ```
///
/// ```diff
/// -std.testing.expectEqual(@as([]const u8, byte_array), actual())
/// +mach.testing.expect([]const u8, byte_array).equalBinary(actual())
/// ```
///
/// ```diff
/// -std.testing.expectEqualStrings("foo", actual())
/// +mach.testing.expect([]const u8, "foo").equal(actual())
/// ```
///
/// Note that std.testing cannot handle @Vector approximate equality at all, while mach.testing uses
/// approx equality of mach.Vec and mach.Mat by default.
pub fn expect(comptime T: type, expected: T) Expect(T) {
    return Expect(T){ .expected = expected };
}

test {
    testing.refAllDeclsRecursive(Expect(u32));
    testing.refAllDeclsRecursive(Expect(f32));
    testing.refAllDeclsRecursive(Expect([]const u8));
    testing.refAllDeclsRecursive(Expect(@Vector(3, f32)));
    testing.refAllDeclsRecursive(Expect(mach.math.Vec2h));
    testing.refAllDeclsRecursive(Expect(mach.math.Vec3));
    testing.refAllDeclsRecursive(Expect(mach.math.Vec4d));
    // testing.refAllDeclsRecursive(Expect(mach.math.Mat4h));
    // testing.refAllDeclsRecursive(Expect(mach.math.Mat4));
    // testing.refAllDeclsRecursive(Expect(mach.math.Mat4d));
}
