const std = @import("std");

const mach = @import("../main.zig");
const testing = mach.testing;
const math = mach.math;
const vec = @import("vec.zig");

pub fn Mat(
    comptime n_cols: usize,
    comptime n_rows: usize,
    comptime Vector: type,
) type {
    return extern struct {
        v: [cols]Vec,

        /// The number of columns, e.g. Mat3x4.cols == 3
        pub const cols = n_cols;

        /// The number of rows, e.g. Mat3x4.rows == 4
        pub const rows = n_rows;

        /// The scalar type of this matrix, e.g. Mat3x3.T == f32
        pub const T = Vector.T;

        /// The underlying Vec type, e.g. Mat3x3.Vec == Vec4
        pub const Vec = Vector;

        /// The Vec type corresponding to the number of rows, e.g. Mat3x3.RowVec == Vec3
        pub const RowVec = vec.Vec(rows, T);

        const Matrix = @This();

        /// Identity matrix
        pub const ident = switch (Matrix) {
            inline math.Mat3x3, math.Mat3x3h, math.Mat3x3d => Matrix.init(
                RowVec.init(1, 0, 0),
                RowVec.init(0, 1, 0),
                RowVec.init(0, 0, 1),
            ),
            inline math.Mat4x4, math.Mat4x4h, math.Mat4x4d => Matrix.init(
                Vec.init(1, 0, 0, 0),
                Vec.init(0, 1, 0, 0),
                Vec.init(0, 0, 1, 0),
                Vec.init(0, 0, 0, 1),
            ),
            else => @compileError("Expected Mat3x3, Mat4x4 found '" ++ @typeName(Matrix) ++ "'"),
        };

        pub usingnamespace switch (Matrix) {
            inline math.Mat3x3, math.Mat3x3h, math.Mat3x3d => struct {
                pub inline fn init(
                    col0: RowVec,
                    col1: RowVec,
                    col2: RowVec,
                ) Matrix {
                    return .{ .v = [_]Vec{
                        Vec.init(col0.x(), col0.y(), col0.z(), 1),
                        Vec.init(col1.x(), col1.y(), col1.z(), 1),
                        Vec.init(col2.x(), col2.y(), col2.z(), 1),
                    } };
                }

                /// Constructs a 3D matrix which scales each dimension by the given vector.
                // TODO: needs tests
                pub inline fn scale(v: Vec) Matrix {
                    return init(
                        Vec.init(v.x(), 0, 0, 0),
                        Vec.init(0, v.y(), 0, 0),
                        Vec.init(0, 0, v.z(), 0),
                        Vec.init(0, 0, 0, 1),
                    );
                }

                /// Constructs a 3D matrix which scales each dimension by the given scalar.
                // TODO: needs tests
                pub inline fn scaleScalar(scalar: Vec.T) Matrix {
                    return scale(Vec.splat(scalar));
                }
            },
            inline math.Mat4x4, math.Mat4x4h, math.Mat4x4d => struct {
                pub inline fn init(col0: Vec, col1: Vec, col2: Vec, col3: Vec) Matrix {
                    return .{ .v = [_]Vec{
                        col0,
                        col1,
                        col2,
                        col3,
                    } };
                }

                /// Constructs a 2D matrix which scales each dimension by the given vector.
                // TODO: needs tests
                pub inline fn scale(v: Vec) Matrix {
                    return init(
                        Vec.init(v.x(), 0, 0, 1),
                        Vec.init(0, v.y(), 0, 1),
                        Vec.init(0, 0, 1, 1),
                    );
                }

                /// Constructs a 2D matrix which scales each dimension by the given scalar.
                // TODO: needs tests
                pub inline fn scaleScalar(scalar: Vec.T) Matrix {
                    return scale(Vec.splat(scalar));
                }
            },
            else => @compileError("Expected Mat3x3, Mat4x4 found '" ++ @typeName(Matrix) ++ "'"),
        };

        // TODO: the below code was correct in our old implementation, it just needs to be updated
        // to work with this new Mat approach, swapping f32 for the generic T float type, moving 3x3
        // and 4x4 specific functions into the mixin above, writing new tests, etc.

        // /// Constructs an orthographic projection matrix; an orthogonal transformation matrix which
        // /// transforms from the given left, right, bottom, and top dimensions into -1 +1 in x and y,
        // /// and 0 to +1 in z.
        // ///
        // /// The near/far parameters denotes the depth (z coordinate) of the near/far clipping plane.
        // ///
        // /// Returns an orthographic projection matrix.
        // pub inline fn ortho(
        //     /// The sides of the near clipping plane viewport
        //     left: f32,
        //     right: f32,
        //     bottom: f32,
        //     top: f32,
        //     /// The depth (z coordinate) of the near/far clipping plane.
        //     near: f32,
        //     far: f32,
        // ) Mat4x4 {
        //     const xx = 2 / (right - left);
        //     const yy = 2 / (top - bottom);
        //     const zz = 1 / (near - far);
        //     const tx = (right + left) / (left - right);
        //     const ty = (top + bottom) / (bottom - top);
        //     const tz = near / (near - far);
        //     return init(Mat4x4, .{
        //         xx, 0,  0,  0,
        //         0,  yy, 0,  0,
        //         0,  0,  zz, 0,
        //         tx, ty, tz, 1,
        //     });
        // }

        // /// Constructs a 2D matrix which translates coordinates by v.
        // pub inline fn translate2d(v: Vec2) Mat3x3 {
        //     return init(Mat3x3, .{
        //         1,    0,    0, 0,
        //         0,    1,    0, 0,
        //         v[0], v[1], 1, 0,
        //     });
        // }

        // /// Constructs a 3D matrix which translates coordinates by v.
        // pub inline fn translate3d(v: Vec3) Mat4x4 {
        //     return init(Mat4x4, .{
        //         1,    0,    0,    0,
        //         0,    1,    0,    0,
        //         0,    0,    1,    0,
        //         v[0], v[1], v[2], 1,
        //     });
        // }

        // /// Returns the translation component of the 2D matrix.
        // pub inline fn translation2d(v: Mat3x3) Vec2 {
        //     return .{ mat.index(v, 8), mat.index(v, 9) };
        // }

        // /// Returns the translation component of the 3D matrix.
        // pub inline fn translation3d(v: Mat4x4) Vec3 {
        //     return .{ mat.index(v, 12), mat.index(v, 13), mat.index(v, 14) };
        // }

        // // Multiplies matrices a * b
        // pub inline fn mul(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
        //     return if (@TypeOf(a) == Mat3x3) {
        //         const a00 = a[0][0];
        //         const a01 = a[0][1];
        //         const a02 = a[0][2];
        //         const a10 = a[1][0];
        //         const a11 = a[1][1];
        //         const a12 = a[1][2];
        //         const a20 = a[2][0];
        //         const a21 = a[2][1];
        //         const a22 = a[2][2];
        //         const b00 = b[0][0];
        //         const b01 = b[0][1];
        //         const b02 = b[0][2];
        //         const b10 = b[1][0];
        //         const b11 = b[1][1];
        //         const b12 = b[1][2];
        //         const b20 = b[2][0];
        //         const b21 = b[2][1];
        //         const b22 = b[2][2];
        //         return init(Mat3x3, .{
        //             a00 * b00 + a10 * b01 + a20 * b02,
        //             a01 * b00 + a11 * b01 + a21 * b02,
        //             a02 * b00 + a12 * b01 + a22 * b02,
        //             a00 * b10 + a10 * b11 + a20 * b12,
        //             a01 * b10 + a11 * b11 + a21 * b12,
        //             a02 * b10 + a12 * b11 + a22 * b12,
        //             a00 * b20 + a10 * b21 + a20 * b22,
        //             a01 * b20 + a11 * b21 + a21 * b22,
        //             a02 * b20 + a12 * b21 + a22 * b22,
        //         });
        //     } else if (@TypeOf(a) == Mat4x4) {
        //         const a00 = a[0][0];
        //         const a01 = a[0][1];
        //         const a02 = a[0][2];
        //         const a03 = a[0][3];
        //         const a10 = a[1][0];
        //         const a11 = a[1][1];
        //         const a12 = a[1][2];
        //         const a13 = a[1][3];
        //         const a20 = a[2][0];
        //         const a21 = a[2][1];
        //         const a22 = a[2][2];
        //         const a23 = a[2][3];
        //         const a30 = a[3][0];
        //         const a31 = a[3][1];
        //         const a32 = a[3][2];
        //         const a33 = a[3][3];
        //         const b00 = b[0][0];
        //         const b01 = b[0][1];
        //         const b02 = b[0][2];
        //         const b03 = b[0][3];
        //         const b10 = b[1][0];
        //         const b11 = b[1][1];
        //         const b12 = b[1][2];
        //         const b13 = b[1][3];
        //         const b20 = b[2][0];
        //         const b21 = b[2][1];
        //         const b22 = b[2][2];
        //         const b23 = b[2][3];
        //         const b30 = b[3][0];
        //         const b31 = b[3][1];
        //         const b32 = b[3][2];
        //         const b33 = b[3][3];
        //         return init(Mat4x4, .{
        //             a00 * b00 + a10 * b01 + a20 * b02 + a30 * b03,
        //             a01 * b00 + a11 * b01 + a21 * b02 + a31 * b03,
        //             a02 * b00 + a12 * b01 + a22 * b02 + a32 * b03,
        //             a03 * b00 + a13 * b01 + a23 * b02 + a33 * b03,
        //             a00 * b10 + a10 * b11 + a20 * b12 + a30 * b13,
        //             a01 * b10 + a11 * b11 + a21 * b12 + a31 * b13,
        //             a02 * b10 + a12 * b11 + a22 * b12 + a32 * b13,
        //             a03 * b10 + a13 * b11 + a23 * b12 + a33 * b13,
        //             a00 * b20 + a10 * b21 + a20 * b22 + a30 * b23,
        //             a01 * b20 + a11 * b21 + a21 * b22 + a31 * b23,
        //             a02 * b20 + a12 * b21 + a22 * b22 + a32 * b23,
        //             a03 * b20 + a13 * b21 + a23 * b22 + a33 * b23,
        //             a00 * b30 + a10 * b31 + a20 * b32 + a30 * b33,
        //             a01 * b30 + a11 * b31 + a21 * b32 + a31 * b33,
        //             a02 * b30 + a12 * b31 + a22 * b32 + a32 * b33,
        //             a03 * b30 + a13 * b31 + a23 * b32 + a33 * b33,
        //         });
        //     } else @compileError("Expected matrix, found '" ++ @typeName(@TypeOf(a)) ++ "'");
        // }

        // /// Check if two matrices are approximate equal. Returns true if the absolute difference between
        // /// each element in matrix them is less or equal than the specified tolerance.
        // pub inline fn equals(a: anytype, b: @TypeOf(a), tolerance: f32) bool {
        //     // TODO: leverage a vec.equals function
        //     return if (@TypeOf(a) == Mat3x3) {
        //         return float.equals(f32, a[0][0], b[0][0], tolerance) and
        //             float.equals(f32, a[0][1], b[0][1], tolerance) and
        //             float.equals(f32, a[0][2], b[0][2], tolerance) and
        //             float.equals(f32, a[0][3], b[0][3], tolerance) and
        //             float.equals(f32, a[1][0], b[1][0], tolerance) and
        //             float.equals(f32, a[1][1], b[1][1], tolerance) and
        //             float.equals(f32, a[1][2], b[1][2], tolerance) and
        //             float.equals(f32, a[1][3], b[1][3], tolerance) and
        //             float.equals(f32, a[2][0], b[2][0], tolerance) and
        //             float.equals(f32, a[2][1], b[2][1], tolerance) and
        //             float.equals(f32, a[2][2], b[2][2], tolerance) and
        //             float.equals(f32, a[2][3], b[2][3], tolerance);
        //     } else if (@TypeOf(a) == Mat4x4) {
        //         return float.equals(f32, a[0][0], b[0][0], tolerance) and
        //             float.equals(f32, a[0][1], b[0][1], tolerance) and
        //             float.equals(f32, a[0][2], b[0][2], tolerance) and
        //             float.equals(f32, a[0][3], b[0][3], tolerance) and
        //             float.equals(f32, a[1][0], b[1][0], tolerance) and
        //             float.equals(f32, a[1][1], b[1][1], tolerance) and
        //             float.equals(f32, a[1][2], b[1][2], tolerance) and
        //             float.equals(f32, a[1][3], b[1][3], tolerance) and
        //             float.equals(f32, a[2][0], b[2][0], tolerance) and
        //             float.equals(f32, a[2][1], b[2][1], tolerance) and
        //             float.equals(f32, a[2][2], b[2][2], tolerance) and
        //             float.equals(f32, a[2][3], b[2][3], tolerance) and
        //             float.equals(f32, a[3][0], b[3][0], tolerance) and
        //             float.equals(f32, a[3][1], b[3][1], tolerance) and
        //             float.equals(f32, a[3][2], b[3][2], tolerance) and
        //             float.equals(f32, a[3][3], b[3][3], tolerance);
        //     } else @compileError("Expected matrix, found '" ++ @typeName(@TypeOf(a)) ++ "'");
        // }

        // /// Constructs a 3D matrix which rotates around the X axis by `angle_radians`.
        // pub inline fn rotateX(angle_radians: f32) Mat4x4 {
        //     const c = std.math.cos(angle_radians);
        //     const s = std.math.sin(angle_radians);

        //     return init(Mat4x4, .{
        //         1, 0,  0, 0,
        //         0, c,  s, 0,
        //         0, -s, c, 0,
        //         0, 0,  0, 1,
        //     });
        // }

        // /// Constructs a 3D matrix which rotates around the X axis by `angle_radians`.
        // pub inline fn rotateY(angle_radians: f32) Mat4x4 {
        //     const c = std.math.cos(angle_radians);
        //     const s = std.math.sin(angle_radians);

        //     return init(Mat4x4, .{
        //         c, 0, -s, 0,
        //         0, 1, 0,  0,
        //         s, 0, c,  0,
        //         0, 0, 0,  1,
        //     });
        // }

        // /// Constructs a 3D matrix which rotates around the Z axis by `angle_radians`.
        // pub inline fn rotateZ(angle_radians: f32) Mat4x4 {
        //     const c = std.math.cos(angle_radians);
        //     const s = std.math.sin(angle_radians);

        //     return init(Mat4x4, .{
        //         c,  s, 0, 0,
        //         -s, c, 0, 0,
        //         0,  0, 1, 0,
        //         0,  0, 0, 1,
        //     });
        // }
    };
}

test "gpu_compatibility" {
    // https://www.w3.org/TR/WGSL/#alignment-and-size
    try testing.expect(usize, 48).eql(@sizeOf(math.Mat3x3));
    try testing.expect(usize, 64).eql(@sizeOf(math.Mat4x4));

    try testing.expect(usize, 24).eql(@sizeOf(math.Mat3x3h));
    try testing.expect(usize, 32).eql(@sizeOf(math.Mat4x4h));

    try testing.expect(usize, 48 * 2).eql(@sizeOf(math.Mat3x3d)); // speculative
    try testing.expect(usize, 64 * 2).eql(@sizeOf(math.Mat4x4d)); // speculative
}

test "zero_struct_overhead" {
    // Proof that using e.g. [3]Vec4 is equal to [3]@Vector(4, f32)
    try testing.expect(usize, @alignOf([3]@Vector(4, f32))).eql(@alignOf(math.Mat3x3));
    try testing.expect(usize, @alignOf([4]@Vector(4, f32))).eql(@alignOf(math.Mat4x4));
    try testing.expect(usize, @sizeOf([3]@Vector(4, f32))).eql(@sizeOf(math.Mat3x3));
    try testing.expect(usize, @sizeOf([4]@Vector(4, f32))).eql(@sizeOf(math.Mat4x4));
}

test "n" {
    try testing.expect(usize, 3).eql(math.Mat3x3.cols);
    try testing.expect(usize, 3).eql(math.Mat3x3.rows);
    try testing.expect(type, math.Vec4).eql(math.Mat3x3.Vec);
    try testing.expect(usize, 4).eql(math.Mat3x3.Vec.n);
}

test "init" {
    try testing.expect(math.Mat3x3, math.mat3x3(
        math.vec3(1, 2, 3),
        math.vec3(4, 5, 6),
        math.vec3(7, 8, 9),
    )).eql(math.Mat3x3{
        .v = [_]math.Vec4{
            math.Vec4.init(1, 2, 3, 1),
            math.Vec4.init(4, 5, 6, 1),
            math.Vec4.init(7, 8, 9, 1),
        },
    });
}

test "mat3x3_ident" {
    try testing.expect(math.Mat3x3, math.Mat3x3.ident).eql(math.Mat3x3{
        .v = [_]math.Vec4{
            math.Vec4.init(1, 0, 0, 1),
            math.Vec4.init(0, 1, 0, 1),
            math.Vec4.init(0, 0, 1, 1),
        },
    });
}

test "mat4x4_ident" {
    try testing.expect(math.Mat4x4, math.Mat4x4.ident).eql(math.Mat4x4{
        .v = [_]math.Vec4{
            math.Vec4.init(1, 0, 0, 0),
            math.Vec4.init(0, 1, 0, 0),
            math.Vec4.init(0, 0, 1, 0),
            math.Vec4.init(0, 0, 0, 1),
        },
    });
}

// TODO(math): the tests below violate our styleguide (https://machengine.org/about/style/) we
// should write new tests loosely based on them:

// test "mat.ortho" {
//     const ortho_mat = mat.ortho(-2, 2, -2, 3, 10, 110);

//     // Computed Values
//     try expectEqual(ortho_mat[0][0], 0.5);
//     try expectEqual(ortho_mat[1][1], 0.4);
//     try expectEqual(ortho_mat[2][2], -0.01);
//     try expectEqual(ortho_mat[3][0], 0);
//     try expectEqual(ortho_mat[3][1], -0.2);
//     try expectEqual(ortho_mat[3][2], -0.1);

//     // Constant values, which should not change but we still check for completeness
//     const zero_value_indexes = [_]u8{
//         1,     2,         3,
//         4,     4 + 2,     4 + 3,
//         4 * 2, 4 * 2 + 1, 4 * 2 + 3,
//     };
//     for (zero_value_indexes) |index| {
//         try expectEqual(mat.index(ortho_mat, index), 0);
//     }
//     try expectEqual(ortho_mat[3][3], 1);
// }

// test "mat.translate2d" {
//     const v = Vec2{ 1.0, -2.5 };
//     const translation_mat = mat.translate2d(v);

//     // Computed Values
//     try expectEqual(translation_mat[2][0], v[0]);
//     try expectEqual(translation_mat[2][1], v[1]);

//     // Constant values, which should not change but we still check for completeness
//     const zero_value_indexes = [_]u8{
//         1,         2,     3,
//         4,         4 + 2, 4 + 3,
//         4 * 2 + 3,
//     };
//     for (zero_value_indexes) |index| {
//         try expectEqual(mat.index(translation_mat, index), 0);
//     }
//     try expectEqual(translation_mat[0][0], 1);
//     try expectEqual(translation_mat[1][1], 1);
//     try expectEqual(translation_mat[2][2], 1);
// }

// test "mat.translate3d" {
//     const v = Vec3{ 1.0, -2.5, 0.001 };
//     const translation_mat = mat.translate3d(v);

//     // Computed Values
//     try expectEqual(translation_mat[3][0], v[0]);
//     try expectEqual(translation_mat[3][1], v[1]);
//     try expectEqual(translation_mat[3][2], v[2]);

//     // Constant values, which should not change but we still check for completeness
//     const zero_value_indexes = [_]u8{
//         1,     2,         3,
//         4,     4 + 2,     4 + 3,
//         4 * 2, 4 * 2 + 1, 4 * 2 + 3,
//     };
//     for (zero_value_indexes) |index| {
//         try expectEqual(mat.index(translation_mat, index), 0);
//     }
//     try expectEqual(translation_mat[3][3], 1);
// }

// test "mat.translation" {
//     {
//         const v = Vec2{ 1.0, -2.5 };
//         const translation_mat = mat.translate2d(v);
//         const result = mat.translation2d(translation_mat);
//         try expectEqual(result[0], v[0]);
//         try expectEqual(result[1], v[1]);
//     }

//     {
//         const v = Vec3{ 1.0, -2.5, 0.001 };
//         const translation_mat = mat.translate3d(v);
//         const result = mat.translation3d(translation_mat);
//         try expectEqual(result[0], v[0]);
//         try expectEqual(result[1], v[1]);
//         try expectEqual(result[2], v[2]);
//     }
// }

// const degreesToRadians = std.math.degreesToRadians;

// // TODO: Maybe reconsider based on feedback to join all test for rotation into one test as only
// //       location of values change. And create some kind of struct that will hold this indexes and
// //       coresponding values
// test "mat.rotateX" {
//     const zero_value_indexes = [_]u8{
//         1,         2,     3,
//         4,         4 + 3, 4 * 2,
//         4 * 2 + 3, 4 * 3, 4 * 3 + 1,
//         4 * 3 + 2,
//     };

//     const one_value_indexes = [_]u8{
//         0, 4 * 3 + 3,
//     };

//     const tolerance = 1e-7;

//     {
//         const r = 90;
//         const R_x = mat.rotateX(degreesToRadians(f32, r));
//         try expectApproxEqAbs(R_x[1][1], 0, tolerance);
//         try expectApproxEqAbs(R_x[2][2], 0, tolerance);
//         try expectApproxEqAbs(R_x[1][2], 1, tolerance);
//         try expectApproxEqAbs(R_x[2][1], -1, tolerance);

//         for (zero_value_indexes) |index| {
//             try expectEqual(mat.index(R_x, index), 0);
//         }

//         for (one_value_indexes) |index| {
//             try expectEqual(mat.index(R_x, index), 1);
//         }
//     }

//     {
//         const r = 0;
//         const R_x = mat.rotateX(degreesToRadians(f32, r));
//         try expectApproxEqAbs(R_x[1][1], 1, tolerance);
//         try expectApproxEqAbs(R_x[2][2], 1, tolerance);
//         try expectApproxEqAbs(R_x[1][2], 0, tolerance);
//         try expectApproxEqAbs(R_x[2][1], 0, tolerance);

//         for (zero_value_indexes) |index| {
//             try expectEqual(mat.index(R_x, index), 0);
//         }

//         for (one_value_indexes) |index| {
//             try expectEqual(mat.index(R_x, index), 1);
//         }
//     }

//     {
//         const r = 45;
//         const result: f32 = std.math.sqrt(2.0) / 2.0; // sqrt(2) / 2
//         const R_x = mat.rotateX(degreesToRadians(f32, r));
//         try expectApproxEqAbs(R_x[1][1], result, tolerance);
//         try expectApproxEqAbs(R_x[2][2], result, tolerance);
//         try expectApproxEqAbs(R_x[1][2], result, tolerance);
//         try expectApproxEqAbs(R_x[2][1], -result, tolerance);

//         for (zero_value_indexes) |index| {
//             try expectEqual(mat.index(R_x, index), 0);
//         }

//         for (one_value_indexes) |index| {
//             try expectEqual(mat.index(R_x, index), 1);
//         }
//     }
// }

// test "mat.rotateY" {
//     const zero_value_indexes = [_]u8{
//         1,         3,
//         4,         4 + 2,
//         4 + 3,     4 * 2 + 1,
//         4 * 2 + 3, 4 * 3,
//         4 * 3 + 1, 4 * 3 + 2,
//     };

//     const one_value_indexes = [_]u8{
//         4 + 1, 4 * 3 + 3,
//     };

//     const tolerance = 1e-7;

//     {
//         const r = 90;
//         const R_y = mat.rotateY(degreesToRadians(f32, r));
//         try expectApproxEqAbs(R_y[0][0], 0, tolerance);
//         try expectApproxEqAbs(R_y[2][2], 0, tolerance);
//         try expectApproxEqAbs(R_y[0][2], -1, tolerance);
//         try expectApproxEqAbs(R_y[2][0], 1, tolerance);

//         for (zero_value_indexes) |index| {
//             try expectEqual(mat.index(R_y, index), 0);
//         }

//         for (one_value_indexes) |index| {
//             try expectEqual(mat.index(R_y, index), 1);
//         }
//     }

//     {
//         const r = 0;
//         const R_y = mat.rotateY(degreesToRadians(f32, r));
//         try expectApproxEqAbs(R_y[0][0], 1, tolerance);
//         try expectApproxEqAbs(R_y[2][2], 1, tolerance);
//         try expectApproxEqAbs(R_y[0][2], 0, tolerance);
//         try expectApproxEqAbs(R_y[3][0], 0, tolerance); // TODO: [2][0] ?

//         for (zero_value_indexes) |index| {
//             try expectEqual(mat.index(R_y, index), 0);
//         }

//         for (one_value_indexes) |index| {
//             try expectEqual(mat.index(R_y, index), 1);
//         }
//     }

//     {
//         const r = 45;
//         const result: f32 = std.math.sqrt(2.0) / 2.0; // sqrt(2) / 2
//         const R_y = mat.rotateY(degreesToRadians(f32, r));
//         try expectApproxEqAbs(R_y[0][0], result, tolerance);
//         try expectApproxEqAbs(R_y[2][2], result, tolerance);
//         try expectApproxEqAbs(R_y[0][2], -result, tolerance);
//         try expectApproxEqAbs(R_y[2][0], result, tolerance);

//         for (zero_value_indexes) |index| {
//             try expectEqual(mat.index(R_y, index), 0);
//         }

//         for (one_value_indexes) |index| {
//             try expectEqual(mat.index(R_y, index), 1);
//         }
//     }
// }

// test "mat.rotateZ" {
//     const zero_value_indexes = [_]u8{
//         2,         3,
//         4 + 2,     4 + 3,
//         4 * 2,     4 * 2 + 1,
//         4 * 2 + 3, 4 * 3,
//         4 * 3 + 1, 4 * 3 + 2,
//     };

//     const one_value_indexes = [_]u8{
//         4 * 2 + 2, 4 * 3 + 3,
//     };

//     const tolerance = 1e-7;

//     {
//         const r = 90;
//         const R_z = mat.rotateZ(degreesToRadians(f32, r));
//         try expectApproxEqAbs(R_z[0][0], 0, tolerance);
//         try expectApproxEqAbs(R_z[1][1], 0, tolerance);
//         try expectApproxEqAbs(R_z[0][1], 1, tolerance);
//         try expectApproxEqAbs(R_z[1][0], -1, tolerance);

//         for (zero_value_indexes) |index| {
//             try expectEqual(mat.index(R_z, index), 0);
//         }

//         for (one_value_indexes) |index| {
//             try expectEqual(mat.index(R_z, index), 1);
//         }
//     }

//     {
//         const r = 0;
//         const R_z = mat.rotateZ(degreesToRadians(f32, r));
//         try expectApproxEqAbs(R_z[0][0], 1, tolerance);
//         try expectApproxEqAbs(R_z[1][1], 1, tolerance);
//         try expectApproxEqAbs(R_z[0][1], 0, tolerance);
//         try expectApproxEqAbs(R_z[1][0], 0, tolerance);

//         for (zero_value_indexes) |index| {
//             try expectEqual(mat.index(R_z, index), 0);
//         }

//         for (one_value_indexes) |index| {
//             try expectEqual(mat.index(R_z, index), 1);
//         }
//     }

//     {
//         const r = 45;
//         const result: f32 = std.math.sqrt(2.0) / 2.0; // sqrt(2) / 2
//         const R_z = mat.rotateZ(degreesToRadians(f32, r));
//         try expectApproxEqAbs(R_z[0][0], result, tolerance);
//         try expectApproxEqAbs(R_z[1][1], result, tolerance);
//         try expectApproxEqAbs(R_z[0][1], result, tolerance);
//         try expectApproxEqAbs(R_z[1][0], -result, tolerance);

//         for (zero_value_indexes) |index| {
//             try expectEqual(mat.index(R_z, index), 0);
//         }

//         for (one_value_indexes) |index| {
//             try expectEqual(mat.index(R_z, index), 1);
//         }
//     }
// }

// test "mat.mul" {
//     {
//         const tolerance = 1e-6;
//         const t = Vec3{ 1, 2, -3 };
//         const T = mat.translate3d(t);
//         const s = Vec3{ 3, 1, -5 };
//         const S = mat.scale3d(s);
//         const r = Vec3{ 30, -40, 235 };
//         const R_x = mat.rotateX(degreesToRadians(f32, r[0]));
//         const R_y = mat.rotateY(degreesToRadians(f32, r[1]));
//         const R_z = mat.rotateZ(degreesToRadians(f32, r[2]));

//         const R_yz = mat.mul(R_y, R_z);
//         // This values are calculated by hand with help of matrix calculator: https://matrix.reshish.com/multCalculation.php
//         const expected_R_yz = mat.init(Mat4x4, .{
//             -0.43938504177070496278, -0.8191520442889918, -0.36868782649461236545, 0,
//             0.62750687159713312638,  -0.573576436351046,  0.52654078451836329713,  0,
//             -0.6427876096865394,     0,                   0.766044443118978,       0,
//             0,                       0,                   0,                       1,
//         });
//         try expect(mat.equals(R_yz, expected_R_yz, tolerance));

//         const R_xyz = mat.mul(R_x, R_yz);
//         const expected_R_xyz = mat.init(Mat4x4, .{
//             -0.439385041770705,  -0.52506256666891627986, -0.72886904595489960019, 0,
//             0.6275068715971331,  -0.76000215715133560834, 0.16920947734596765363,  0,
//             -0.6427876096865394, -0.383022221559489,      0.66341394816893832989,  0,
//             0,                   0,                       0,                       1,
//         });
//         try expect(mat.equals(R_xyz, expected_R_xyz, tolerance));

//         const SR = mat.mul(S, R_xyz);
//         const expected_SR = mat.init(Mat4x4, .{
//             -1.318155125312115,  -0.5250625666689163, 3.6443452297744985,  0,
//             1.8825206147913993,  -0.7600021571513356, -0.8460473867298382, 0,
//             -1.9283628290596182, -0.383022221559489,  -3.3170697408446915, 0,
//             0,                   0,                   0,                   1,
//         });
//         try expect(mat.equals(SR, expected_SR, tolerance));

//         const TSR = mat.mul(T, SR);
//         const expected_TSR = mat.init(Mat4x4, .{
//             -1.318155125312115,  -0.5250625666689163, 3.6443452297744985,  0,
//             1.8825206147913993,  -0.7600021571513356, -0.8460473867298382, 0,
//             -1.9283628290596182, -0.383022221559489,  -3.3170697408446914, 0,
//             1,                   2,                   -3,                  1,
//         });

//         try expect(mat.equals(TSR, expected_TSR, tolerance));
//     }
// }
