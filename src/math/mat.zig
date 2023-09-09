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
        /// The column vectors of the matrix.
        ///
        /// Mach matrices use [column-major storage and column-vectors](https://machengine.org/engine/math/matrix-storage/).
        /// The translation vector is stored in contiguous memory elements 12, 13, 14:
        ///
        /// ```
        /// [4]Vec4{
        ///     vec4( 1,  0,  0,  0),
        ///     vec4( 0,  1,  0,  0),
        ///     vec4( 0,  0,  1,  0),
        ///     vec4(tx, ty, tz, tw),
        /// }
        /// ```
        ///
        /// Use the init() constructor to write code which visually matches the same layout as you'd
        /// see used in scientific / maths communities.
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
                /// Constructs a 3x3 matrix with the given rows. For example to write a translation
                /// matrix like in the left part of this equation:
                ///
                /// ```
                /// |1 0 tx| |x  |   |x+z*tx|
                /// |0 1 ty| |y  | = |y+z*ty|
                /// |0 0 tz| |z=1|   |tz    |
                /// ```
                ///
                /// You would write it with the same visual layout:
                ///
                /// ```
                /// const m = Mat3x3.init(
                ///     vec4(1, 0, tx),
                ///     vec4(0, 1, ty),
                ///     vec4(0, 0, tz),
                /// );
                /// ```
                ///
                /// Note that Mach matrices use [column-major storage and column-vectors](https://machengine.org/engine/math/matrix-storage/).
                pub inline fn init(r0: RowVec, r1: RowVec, r2: RowVec) Matrix {
                    return .{ .v = [_]Vec{
                        Vec.init(r0.x(), r1.x(), r2.x(), 1),
                        Vec.init(r0.y(), r1.y(), r2.y(), 1),
                        Vec.init(r0.z(), r1.z(), r2.z(), 1),
                    } };
                }

                /// Returns the row `i` of the matrix.
                pub inline fn row(m: Matrix, i: usize) RowVec {
                    return RowVec.init(m.v[0].v[i], m.v[1].v[i], m.v[2].v[i]);
                }

                /// Returns the column `i` of the matrix.
                pub inline fn col(m: Matrix, i: usize) RowVec {
                    return RowVec.init(m.v[i].v[0], m.v[i].v[1], m.v[i].v[2]);
                }

                /// Constructs a 2D matrix which scales each dimension by the given vector.
                // TODO: needs tests
                pub inline fn scale(s: math.Vec2) Matrix {
                    return init(
                        RowVec.init(s.x(), 0, 0),
                        RowVec.init(0, s.y(), 0),
                        RowVec.init(0, 0, 1),
                    );
                }

                /// Constructs a 2D matrix which scales each dimension by the given scalar.
                // TODO: needs tests
                pub inline fn scaleScalar(t: Vec.T) Matrix {
                    return scale(Vec.splat(t));
                }

                /// Constructs a 2D matrix which translates coordinates by the given vector.
                // TODO: needs tests
                pub inline fn translate(t: math.Vec2) Matrix {
                    return init(
                        RowVec.init(1, 0, t.x()),
                        RowVec.init(0, 1, t.y()),
                        RowVec.init(0, 0, 1),
                    );
                }

                /// Constructs a 2D matrix which translates coordinates by the given scalar.
                // TODO: needs tests
                pub inline fn translateScalar(t: Vec.T) Matrix {
                    return translate(Vec.splat(t));
                }

                /// Returns the translation component of the matrix.
                // TODO: needs tests
                pub inline fn translation(t: Matrix) math.Vec2 {
                    return math.Vec2.init(t.v[2].x(), t.v[2].y());
                }
            },
            inline math.Mat4x4, math.Mat4x4h, math.Mat4x4d => struct {
                /// Constructs a 4x4 matrix with the given rows. For example to write a translation
                /// matrix like in the left part of this equation:
                ///
                /// ```
                /// |1 0 0 tx| |x  |   |x+w*tx|
                /// |0 1 0 ty| |y  | = |y+w*ty|
                /// |0 0 1 tz| |z  |   |z+w*tz|
                /// |0 0 0 tw| |w=1|   |tw    |
                /// ```
                ///
                /// You would write it with the same visual layout:
                ///
                /// ```
                /// const m = Mat4x4.init(
                ///     vec4(1, 0, 0, tx),
                ///     vec4(0, 1, 0, ty),
                ///     vec4(0, 0, 1, tz),
                ///     vec4(0, 0, 0, tw),
                /// );
                /// ```
                ///
                /// Note that Mach matrices use [column-major storage and column-vectors](https://machengine.org/engine/math/matrix-storage/).
                pub inline fn init(r0: Vec, r1: RowVec, r2: RowVec, r3: RowVec) Matrix {
                    return .{ .v = [_]Vec{
                        Vec.init(r0.x(), r1.x(), r2.x(), r3.x()),
                        Vec.init(r0.y(), r1.y(), r2.y(), r3.y()),
                        Vec.init(r0.z(), r1.z(), r2.z(), r3.z()),
                        Vec.init(r0.w(), r1.w(), r2.w(), r3.w()),
                    } };
                }

                /// Returns the row `i` of the matrix.
                pub inline fn row(m: Matrix, i: usize) RowVec {
                    return RowVec.init(m.v[0].v[i], m.v[1].v[i], m.v[2].v[i], m.v[3].v[i]);
                }

                /// Returns the column `i` of the matrix.
                pub inline fn col(m: Matrix, i: usize) RowVec {
                    return RowVec.init(m.v[i].v[0], m.v[i].v[1], m.v[i].v[2], m.v[i].v[3]);
                }

                /// Constructs a 3D matrix which scales each dimension by the given vector.
                // TODO: needs tests
                pub inline fn scale(s: math.Vec3) Matrix {
                    return init(
                        Vec.init(s.x(), 0, 0, 0),
                        Vec.init(0, s.y(), 0, 0),
                        Vec.init(0, 0, s.z(), 0),
                        Vec.init(0, 0, 0, 1),
                    );
                }

                /// Constructs a 3D matrix which scales each dimension by the given scalar.
                // TODO: needs tests
                pub inline fn scaleScalar(s: Vec.T) Matrix {
                    return scale(Vec.splat(s));
                }

                /// Constructs a 3D matrix which translates coordinates by the given vector.
                // TODO: needs tests
                pub inline fn translate(t: math.Vec3) Matrix {
                    return init(
                        RowVec.init(1, 0, 0, t.x()),
                        RowVec.init(0, 1, 0, t.y()),
                        RowVec.init(0, 0, 1, t.z()),
                        RowVec.init(0, 0, 0, 1),
                    );
                }

                /// Constructs a 3D matrix which translates coordinates by the given scalar.
                // TODO: needs tests
                pub inline fn translateScalar(t: Vec.T) Matrix {
                    return translate(Vec.splat(t));
                }

                /// Returns the translation component of the matrix.
                // TODO: needs tests
                pub inline fn translation(t: Matrix) math.Vec3 {
                    return math.Vec3.init(t.v[3].x(), t.v[3].y(), t.v[3].z());
                }

                /// Constructs an orthographic projection matrix; an orthogonal transformation matrix
                /// which transforms from the given left, right, bottom, and top dimensions into
                /// `(-1, +1)` in `(x, y)`, and `(0, +1)` in `z`.
                ///
                /// The near/far parameters denotes the depth (z coordinate) of the near/far clipping
                /// plane.
                ///
                /// Returns an orthographic projection matrix.
                // TODO: needs tests
                pub inline fn ortho(
                    /// The sides of the near clipping plane viewport
                    left: f32,
                    right: f32,
                    bottom: f32,
                    top: f32,
                    /// The depth (z coordinate) of the near/far clipping plane.
                    near: f32,
                    far: f32,
                ) Matrix {
                    const xx = 2 / (right - left);
                    const yy = 2 / (top - bottom);
                    const zz = 1 / (near - far);
                    const tx = (right + left) / (left - right);
                    const ty = (top + bottom) / (bottom - top);
                    const tz = near / (near - far);
                    return init(
                        RowVec.init(xx, 0, 0, tx),
                        RowVec.init(0, yy, 0, ty),
                        RowVec.init(0, 0, zz, tz),
                        RowVec.init(0, 0, 0, 1),
                    );
                }
            },
            else => @compileError("Expected Mat3x3, Mat4x4 found '" ++ @typeName(Matrix) ++ "'"),
        };

        // TODO: the below code was correct in our old implementation, it just needs to be updated
        // to work with this new Mat approach, swapping f32 for the generic T float type, moving 3x3
        // and 4x4 specific functions into the mixin above, writing new tests, etc.

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
        math.vec3(1, 0, 1337),
        math.vec3(0, 1, 7331),
        math.vec3(0, 0, 1),
    )).eql(math.Mat3x3{
        .v = [_]math.Vec4{
            math.Vec4.init(1, 0, 0, 1),
            math.Vec4.init(0, 1, 0, 1),
            math.Vec4.init(1337, 7331, 1, 1),
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

test "Mat3x3_row" {
    const m = math.Mat3x3.init(
        math.vec3(0, 1, 2),
        math.vec3(3, 4, 5),
        math.vec3(6, 7, 8),
    );
    try testing.expect(math.Vec3, math.vec3(0, 1, 2)).eql(m.row(0));
    try testing.expect(math.Vec3, math.vec3(3, 4, 5)).eql(m.row(1));
    try testing.expect(math.Vec3, math.vec3(6, 7, 8)).eql(m.row(@TypeOf(m).rows - 1));
}

test "Mat3x3_col" {
    const m = math.Mat3x3.init(
        math.vec3(0, 1, 2),
        math.vec3(3, 4, 5),
        math.vec3(6, 7, 8),
    );
    try testing.expect(math.Vec3, math.vec3(0, 3, 6)).eql(m.col(0));
    try testing.expect(math.Vec3, math.vec3(1, 4, 7)).eql(m.col(1));
    try testing.expect(math.Vec3, math.vec3(2, 5, 8)).eql(m.col(@TypeOf(m).cols - 1));
}

test "Mat4x4_row" {
    const m = math.Mat4x4.init(
        math.vec4(0, 1, 2, 3),
        math.vec4(4, 5, 6, 7),
        math.vec4(8, 9, 10, 11),
        math.vec4(12, 13, 14, 15),
    );
    try testing.expect(math.Vec4, math.vec4(0, 1, 2, 3)).eql(m.row(0));
    try testing.expect(math.Vec4, math.vec4(4, 5, 6, 7)).eql(m.row(1));
    try testing.expect(math.Vec4, math.vec4(8, 9, 10, 11)).eql(m.row(2));
    try testing.expect(math.Vec4, math.vec4(12, 13, 14, 15)).eql(m.row(@TypeOf(m).rows - 1));
}

test "Mat4x4_col" {
    const m = math.Mat4x4.init(
        math.vec4(0, 1, 2, 3),
        math.vec4(4, 5, 6, 7),
        math.vec4(8, 9, 10, 11),
        math.vec4(12, 13, 14, 15),
    );
    try testing.expect(math.Vec4, math.vec4(0, 4, 8, 12)).eql(m.col(0));
    try testing.expect(math.Vec4, math.vec4(1, 5, 9, 13)).eql(m.col(1));
    try testing.expect(math.Vec4, math.vec4(2, 6, 10, 14)).eql(m.col(2));
    try testing.expect(math.Vec4, math.vec4(3, 7, 11, 15)).eql(m.col(@TypeOf(m).cols - 1));
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
