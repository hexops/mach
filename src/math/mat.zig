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

        /// The Vec type corresponding to the numebr of cols, e.g. Mat3x4.ColVec = Vec4
        pub const ColVec = vec.Vec(cols, T);

        const Matrix = @This();

        /// Identity matrix
        pub const ident = switch (Matrix) {
            inline math.Mat3x3, math.Mat3x3h, math.Mat3x3d => Matrix.init(
                &RowVec.init(1, 0, 0),
                &RowVec.init(0, 1, 0),
                &RowVec.init(0, 0, 1),
            ),
            inline math.Mat4x4, math.Mat4x4h, math.Mat4x4d => Matrix.init(
                &Vec.init(1, 0, 0, 0),
                &Vec.init(0, 1, 0, 0),
                &Vec.init(0, 0, 1, 0),
                &Vec.init(0, 0, 0, 1),
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
                pub inline fn init(r0: *const RowVec, r1: *const RowVec, r2: *const RowVec) Matrix {
                    return .{ .v = [_]Vec{
                        Vec.init(r0.x(), r1.x(), r2.x(), 1),
                        Vec.init(r0.y(), r1.y(), r2.y(), 1),
                        Vec.init(r0.z(), r1.z(), r2.z(), 1),
                    } };
                }

                /// Returns the row `i` of the matrix.
                pub inline fn row(m: *const Matrix, i: usize) RowVec {
                    // Note: we inline RowVec.init manually here as it is faster in debug builds.
                    // return RowVec.init(m.v[0].v[i], m.v[1].v[i], m.v[2].v[i]);
                    return .{ .v = .{ m.v[0].v[i], m.v[1].v[i], m.v[2].v[i] } };
                }

                /// Returns the column `i` of the matrix.
                pub inline fn col(m: *const Matrix, i: usize) RowVec {
                    // Note: we inline RowVec.init manually here as it is faster in debug builds.
                    // return RowVec.init(m.v[i].v[0], m.v[i].v[1], m.v[i].v[2]);
                    return .{ .v = .{ m.v[i].v[0], m.v[i].v[1], m.v[i].v[2] } };
                }

                /// Transposes the matrix.
                pub inline fn transpose(m: *const Matrix) Matrix {
                    return .{ .v = [_]Vec{
                        Vec.init(m.v[0].v[0], m.v[1].v[0], m.v[2].v[0], 1),
                        Vec.init(m.v[0].v[1], m.v[1].v[1], m.v[2].v[1], 1),
                        Vec.init(m.v[0].v[2], m.v[1].v[2], m.v[2].v[2], 1),
                    } };
                }

                /// Constructs a 2D matrix which scales each dimension by the given vector.
                pub inline fn scale(s: math.Vec2) Matrix {
                    return init(
                        &RowVec.init(s.x(), 0, 0),
                        &RowVec.init(0, s.y(), 0),
                        &RowVec.init(0, 0, 1),
                    );
                }

                /// Constructs a 2D matrix which scales each dimension by the given scalar.
                pub inline fn scaleScalar(t: Vec.T) Matrix {
                    return scale(math.Vec2.splat(t));
                }

                /// Constructs a 2D matrix which translates coordinates by the given vector.
                pub inline fn translate(t: math.Vec2) Matrix {
                    return init(
                        &RowVec.init(1, 0, t.x()),
                        &RowVec.init(0, 1, t.y()),
                        &RowVec.init(0, 0, 1),
                    );
                }

                /// Constructs a 2D matrix which translates coordinates by the given scalar.
                pub inline fn translateScalar(t: Vec.T) Matrix {
                    return translate(math.Vec2.splat(t));
                }

                /// Returns the translation component of the matrix.
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
                ///     &vec4(1, 0, 0, tx),
                ///     &vec4(0, 1, 0, ty),
                ///     &vec4(0, 0, 1, tz),
                ///     &vec4(0, 0, 0, tw),
                /// );
                /// ```
                ///
                /// Note that Mach matrices use [column-major storage and column-vectors](https://machengine.org/engine/math/matrix-storage/).
                pub inline fn init(r0: *const RowVec, r1: *const RowVec, r2: *const RowVec, r3: *const RowVec) Matrix {
                    return .{ .v = [_]Vec{
                        Vec.init(r0.x(), r1.x(), r2.x(), r3.x()),
                        Vec.init(r0.y(), r1.y(), r2.y(), r3.y()),
                        Vec.init(r0.z(), r1.z(), r2.z(), r3.z()),
                        Vec.init(r0.w(), r1.w(), r2.w(), r3.w()),
                    } };
                }

                /// Returns the row `i` of the matrix.
                pub inline fn row(m: *const Matrix, i: usize) RowVec {
                    return RowVec{ .v = RowVec.Vector{ m.v[0].v[i], m.v[1].v[i], m.v[2].v[i], m.v[3].v[i] } };
                }

                /// Returns the column `i` of the matrix.
                pub inline fn col(m: *const Matrix, i: usize) RowVec {
                    return RowVec{ .v = RowVec.Vector{ m.v[i].v[0], m.v[i].v[1], m.v[i].v[2], m.v[i].v[3] } };
                }

                /// Transposes the matrix.
                pub inline fn transpose(m: *const Matrix) Matrix {
                    return .{ .v = [_]Vec{
                        Vec.init(m.v[0].v[0], m.v[1].v[0], m.v[2].v[0], m.v[3].v[0]),
                        Vec.init(m.v[0].v[1], m.v[1].v[1], m.v[2].v[1], m.v[3].v[1]),
                        Vec.init(m.v[0].v[2], m.v[1].v[2], m.v[2].v[2], m.v[3].v[2]),
                        Vec.init(m.v[0].v[3], m.v[1].v[3], m.v[2].v[3], m.v[3].v[3]),
                    } };
                }

                /// Constructs a 3D matrix which scales each dimension by the given vector.
                pub inline fn scale(s: math.Vec3) Matrix {
                    return init(
                        &RowVec.init(s.x(), 0, 0, 0),
                        &RowVec.init(0, s.y(), 0, 0),
                        &RowVec.init(0, 0, s.z(), 0),
                        &RowVec.init(0, 0, 0, 1),
                    );
                }

                /// Constructs a 3D matrix which scales each dimension by the given scalar.
                pub inline fn scaleScalar(s: Vec.T) Matrix {
                    return scale(math.Vec3.splat(s));
                }

                /// Constructs a 3D matrix which translates coordinates by the given vector.
                pub inline fn translate(t: math.Vec3) Matrix {
                    return init(
                        &RowVec.init(1, 0, 0, t.x()),
                        &RowVec.init(0, 1, 0, t.y()),
                        &RowVec.init(0, 0, 1, t.z()),
                        &RowVec.init(0, 0, 0, 1),
                    );
                }

                /// Constructs a 3D matrix which translates coordinates by the given scalar.
                pub inline fn translateScalar(t: Vec.T) Matrix {
                    return translate(math.Vec3.splat(t));
                }

                /// Returns the translation component of the matrix.
                pub inline fn translation(t: *const Matrix) math.Vec3 {
                    return math.Vec3.init(t.v[3].x(), t.v[3].y(), t.v[3].z());
                }

                /// Constructs a 3D matrix which rotates around the X axis by `angle_radians`.
                pub inline fn rotateX(angle_radians: f32) Matrix {
                    const c = std.math.cos(angle_radians);
                    const s = std.math.sin(angle_radians);
                    return Matrix.init(
                        &RowVec.init(1, 0, 0, 0),
                        &RowVec.init(0, c, -s, 0),
                        &RowVec.init(0, s, c, 0),
                        &RowVec.init(0, 0, 0, 1),
                    );
                }

                /// Constructs a 3D matrix which rotates around the X axis by `angle_radians`.
                pub inline fn rotateY(angle_radians: f32) Matrix {
                    const c = std.math.cos(angle_radians);
                    const s = std.math.sin(angle_radians);
                    return Matrix.init(
                        &RowVec.init(c, 0, s, 0),
                        &RowVec.init(0, 1, 0, 0),
                        &RowVec.init(-s, 0, c, 0),
                        &RowVec.init(0, 0, 0, 1),
                    );
                }

                /// Constructs a 3D matrix which rotates around the Z axis by `angle_radians`.
                pub inline fn rotateZ(angle_radians: f32) Matrix {
                    const c = std.math.cos(angle_radians);
                    const s = std.math.sin(angle_radians);
                    return Matrix.init(
                        &RowVec.init(c, -s, 0, 0),
                        &RowVec.init(s, c, 0, 0),
                        &RowVec.init(0, 0, 1, 0),
                        &RowVec.init(0, 0, 0, 1),
                    );
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
                        &RowVec.init(xx, 0, 0, tx),
                        &RowVec.init(0, yy, 0, ty),
                        &RowVec.init(0, 0, zz, tz),
                        &RowVec.init(0, 0, 0, 1),
                    );
                }

                /// Constructs a perspective projection matrix; a perspective transformation matrix
                /// which transforms from eye space to clip space.
                ///
                /// The field of view angle `fovy` is the vertical angle in radians.
                /// The `aspect` ratio is the ratio of the width to the height of the viewport.
                /// The `near` and `far` parameters denote the depth (z coordinate) of the near and far clipping planes.
                ///
                /// Returns a perspective projection matrix.
                pub inline fn perspective(
                    /// The field of view angle in the y direction, in radians.
                    fovy: f32,
                    /// The aspect ratio of the viewport's width to its height.
                    aspect: f32,
                    /// The depth (z coordinate) of the near clipping plane.
                    near: f32,
                    /// The depth (z coordinate) of the far clipping plane.
                    far: f32,
                ) Matrix {
                    const f = 1.0 / std.math.tan(fovy / 2.0);
                    const zz = (near + far) / (near - far);
                    const zw = (2.0 * near * far) / (near - far);
                    return init(
                        &RowVec.init(f / aspect, 0, 0, 0),
                        &RowVec.init(0, f, 0, 0),
                        &RowVec.init(0, 0, zz, -1),
                        &RowVec.init(0, 0, zw, 0),
                    );
                }
            },
            else => @compileError("Expected Mat3x3, Mat4x4 found '" ++ @typeName(Matrix) ++ "'"),
        };

        /// Matrix multiplication a*b
        // TODO: needs tests
        pub inline fn mul(a: *const Matrix, b: *const Matrix) Matrix {
            @setEvalBranchQuota(10000);
            var result: Matrix = undefined;
            inline for (0..Matrix.rows) |row| {
                inline for (0..Matrix.cols) |col| {
                    var sum: RowVec.T = 0.0;
                    inline for (0..RowVec.n) |i| {
                        // Note: we directly access rows/columns below as it is much faster **in
                        // debug builds**, instead of using these helpers:
                        //
                        // sum += a.row(row).mul(&b.col(col)).v[i];
                        sum += a.v[i].v[row] * b.v[col].v[i];
                    }
                    result.v[col].v[row] = sum;
                }
            }
            return result;
        }

        /// Matrix * Vector multiplication
        pub inline fn mulVec(a: *const Matrix, b: *const ColVec) ColVec {
            var result = [_]ColVec.T{0}**ColVec.n;
            inline for (0..Matrix.rows) |row| {
                inline for (0..ColVec.n) |i| {
                    result[i] += a.v[row].v[i] * b.v[row];
                }
            }
            return vec.Vec(ColVec.n, ColVec.T){
                .v = result
            };
        }

        // TODO: the below code was correct in our old implementation, it just needs to be updated
        // to work with this new Mat approach, swapping f32 for the generic T float type, moving 3x3
        // and 4x4 specific functions into the mixin above, writing new tests, etc.

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
        &math.vec3(1, 0, 1337),
        &math.vec3(0, 1, 7331),
        &math.vec3(0, 0, 1),
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
        &math.vec3(0, 1, 2),
        &math.vec3(3, 4, 5),
        &math.vec3(6, 7, 8),
    );
    try testing.expect(math.Vec3, math.vec3(0, 1, 2)).eql(m.row(0));
    try testing.expect(math.Vec3, math.vec3(3, 4, 5)).eql(m.row(1));
    try testing.expect(math.Vec3, math.vec3(6, 7, 8)).eql(m.row(@TypeOf(m).rows - 1));
}

test "Mat3x3_col" {
    const m = math.Mat3x3.init(
        &math.vec3(0, 1, 2),
        &math.vec3(3, 4, 5),
        &math.vec3(6, 7, 8),
    );
    try testing.expect(math.Vec3, math.vec3(0, 3, 6)).eql(m.col(0));
    try testing.expect(math.Vec3, math.vec3(1, 4, 7)).eql(m.col(1));
    try testing.expect(math.Vec3, math.vec3(2, 5, 8)).eql(m.col(@TypeOf(m).cols - 1));
}

test "Mat4x4_row" {
    const m = math.Mat4x4.init(
        &math.vec4(0, 1, 2, 3),
        &math.vec4(4, 5, 6, 7),
        &math.vec4(8, 9, 10, 11),
        &math.vec4(12, 13, 14, 15),
    );
    try testing.expect(math.Vec4, math.vec4(0, 1, 2, 3)).eql(m.row(0));
    try testing.expect(math.Vec4, math.vec4(4, 5, 6, 7)).eql(m.row(1));
    try testing.expect(math.Vec4, math.vec4(8, 9, 10, 11)).eql(m.row(2));
    try testing.expect(math.Vec4, math.vec4(12, 13, 14, 15)).eql(m.row(@TypeOf(m).rows - 1));
}

test "Mat4x4_col" {
    const m = math.Mat4x4.init(
        &math.vec4(0, 1, 2, 3),
        &math.vec4(4, 5, 6, 7),
        &math.vec4(8, 9, 10, 11),
        &math.vec4(12, 13, 14, 15),
    );
    try testing.expect(math.Vec4, math.vec4(0, 4, 8, 12)).eql(m.col(0));
    try testing.expect(math.Vec4, math.vec4(1, 5, 9, 13)).eql(m.col(1));
    try testing.expect(math.Vec4, math.vec4(2, 6, 10, 14)).eql(m.col(2));
    try testing.expect(math.Vec4, math.vec4(3, 7, 11, 15)).eql(m.col(@TypeOf(m).cols - 1));
}

test "Mat3x3_transpose" {
    const m = math.Mat3x3.init(
        &math.vec3(0, 1, 2),
        &math.vec3(3, 4, 5),
        &math.vec3(6, 7, 8),
    );
    try testing.expect(math.Mat3x3, math.Mat3x3.init(
        &math.vec3(0, 3, 6),
        &math.vec3(1, 4, 7),
        &math.vec3(2, 5, 8),
    )).eql(m.transpose());
}

test "Mat4x4_transpose" {
    const m = math.Mat4x4.init(
        &math.vec4(0, 1, 2, 3),
        &math.vec4(4, 5, 6, 7),
        &math.vec4(8, 9, 10, 11),
        &math.vec4(12, 13, 14, 15),
    );
    try testing.expect(math.Mat4x4, math.Mat4x4.init(
        &math.vec4(0, 4, 8, 12),
        &math.vec4(1, 5, 9, 13),
        &math.vec4(2, 6, 10, 14),
        &math.vec4(3, 7, 11, 15),
    )).eql(m.transpose());
}

test "Mat3x3_scale" {
    const m = math.Mat3x3.scale(math.vec2(2, 3));
    try testing.expect(math.Mat3x3, math.Mat3x3.init(
        &math.vec3(2, 0, 0),
        &math.vec3(0, 3, 0),
        &math.vec3(0, 0, 1),
    )).eql(m);
}

test "Mat3x3_scaleScalar" {
    const m = math.Mat3x3.scaleScalar(2);
    try testing.expect(math.Mat3x3, math.Mat3x3.init(
        &math.vec3(2, 0, 0),
        &math.vec3(0, 2, 0),
        &math.vec3(0, 0, 1),
    )).eql(m);
}

test "Mat4x4_scale" {
    const m = math.Mat4x4.scale(math.vec3(2, 3, 4));
    try testing.expect(math.Mat4x4, math.Mat4x4.init(
        &math.vec4(2, 0, 0, 0),
        &math.vec4(0, 3, 0, 0),
        &math.vec4(0, 0, 4, 0),
        &math.vec4(0, 0, 0, 1),
    )).eql(m);
}

test "Mat4x4_scaleScalar" {
    const m = math.Mat4x4.scaleScalar(2);
    try testing.expect(math.Mat4x4, math.Mat4x4.init(
        &math.vec4(2, 0, 0, 0),
        &math.vec4(0, 2, 0, 0),
        &math.vec4(0, 0, 2, 0),
        &math.vec4(0, 0, 0, 1),
    )).eql(m);
}

test "Mat3x3_translate" {
    const m = math.Mat3x3.translate(math.vec2(2, 3));
    try testing.expect(math.Mat3x3, math.Mat3x3.init(
        &math.vec3(1, 0, 2),
        &math.vec3(0, 1, 3),
        &math.vec3(0, 0, 1),
    )).eql(m);
}

test "Mat4x4_translate" {
    const m = math.Mat4x4.translate(math.vec3(2, 3, 4));
    try testing.expect(math.Mat4x4, math.Mat4x4.init(
        &math.vec4(1, 0, 0, 2),
        &math.vec4(0, 1, 0, 3),
        &math.vec4(0, 0, 1, 4),
        &math.vec4(0, 0, 0, 1),
    )).eql(m);
}

test "Mat3x3_translateScalar" {
    const m = math.Mat3x3.translateScalar(2);
    try testing.expect(math.Mat3x3, math.Mat3x3.init(
        &math.vec3(1, 0, 2),
        &math.vec3(0, 1, 2),
        &math.vec3(0, 0, 1),
    )).eql(m);
}

test "Mat4x4_translateScalar" {
    const m = math.Mat4x4.translateScalar(2);
    try testing.expect(math.Mat4x4, math.Mat4x4.init(
        &math.vec4(1, 0, 0, 2),
        &math.vec4(0, 1, 0, 2),
        &math.vec4(0, 0, 1, 2),
        &math.vec4(0, 0, 0, 1),
    )).eql(m);
}

test "Mat3x3_translation" {
    const m = math.Mat3x3.translate(math.vec2(2, 3));
    try testing.expect(math.Vec2, math.vec2(2, 3)).eql(m.translation());
}

test "Mat4x4_translation" {
    const m = math.Mat4x4.translate(math.vec3(2, 3, 4));
    try testing.expect(math.Vec3, math.vec3(2, 3, 4)).eql(m.translation());
}

test "Mat4x4_perspective" {
    const fov_radians = std.math.pi / 2.0; // Field of view in radians
    const aspect_ratio = 16.0 / 9.0; // Aspect ratio
    const near = 0.1; // Near clipping plane
    const far = 100.0; // Far clipping plane

    const m = math.Mat4x4.perspective(fov_radians, aspect_ratio, near, far);

    const expected = math.Mat4x4.init(&math.vec4(1.0 / (aspect_ratio * std.math.tan(fov_radians / 2.0)), 0.0, 0.0, 0.0), &math.vec4(0.0, 1.0 / std.math.tan(fov_radians / 2.0), 0.0, 0.0), &math.vec4(0.0, 0.0, -(far + near) / (far - near), -1.0), &math.vec4(0.0, 0.0, -(2.0 * far * near) / (far - near), 0.0));

    try testing.expect(math.Mat4x4, expected).eql(m);
}

test "Mat3x3_mulVec_vec3_ident" {
    const v = math.Vec3.splat(1);
    const ident = math.Mat3x3.ident;
    const expected = v;
    var m = math.Mat3x3.mulVec(&ident, &v);

    try testing.expect(math.Vec3, expected).eql(m);
}

test "Mat3x3_mulVec_vec3" {
    const v = math.Vec3.splat(1);
    const mat = math.Mat3x3.init(
        &math.vec3(2, 0, 0),
        &math.vec3(0, 2, 0),
        &math.vec3(0, 0, 3),
    );

    const m = math.Mat3x3.mulVec(&mat, &v);
    const expected = math.vec3(2,2,3);
    try testing.expect(math.Vec3, expected).eql(m);
}

test "Mat4x4_mulVec_vec4" {
    const v = math.vec4(2, 5, 1, 8);
    const mat = math.Mat4x4.init(
        &math.vec4(1, 0, 2, 0),
        &math.vec4(0, 3, 0, 4),
        &math.vec4(0, 0, 5, 0),
        &math.vec4(6, 0, 0, 7),
    );

    const m = math.Mat4x4.mulVec(&mat, &v);
    const expected = math.vec4(4, 47, 5, 68);
    try testing.expect(math.Vec4, expected).eql(m);
}
