const std = @import("std");

const mach = @import("../main.zig");
const testing = mach.testing;
const math = mach.math;
const vec = @import("vec.zig");
const quat = @import("quat.zig");

pub fn Mat2x2(Scalar: type) type {
    return Mat(Scalar, 2, 2);
}

pub fn Mat3x3(Scalar: type) type {
    return Mat(Scalar, 3, 3);
}

pub fn Mat4x4(Scalar: type) type {
    return Mat(Scalar, 4, 4);
}

pub fn Mat(Scalar: type, comptime m: usize, comptime n: usize) type {
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
        v: [cols]ColVec,

        /// The scalar type of this matrix, e.g. Mat3x3.T == f32
        pub const T = Scalar;

        /// The Vec type corresponding to the number of rows, e.g. Mat3x4.RowVec == Vec3
        pub const RowVec = vec.Vec(T, cols);

        /// The Vec type corresponding to the number of cols, e.g. Mat3x4.ColVec == Vec4
        pub const ColVec = vec.Vec(T, rows);

        /// The underlying Vec type, e.g. Mat3x3.MinVec == Vec3
        pub const MinVec = vec.Vec(T, @min(rows, cols));

        /// The Vec type whose length is one less than the minimum dimension of the matrix, e.g. Mat3x3.MinVecMinusOne == Vec2
        /// Useful for certain functions which return these, like translation()
        pub const MinVecMinusOne = vec.Vec(T, @min(rows, cols) - 1);

        /// The number of rows, e.g. Mat3x4.rows == 3
        pub const rows = m;

        /// The number of columns, e.g. Mat3x4.cols == 4
        pub const cols = n;

        const Self = @This();

        /// Constructs a MxN matrix with the given rows. For example to write a 4x4 translation
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
        /// const m = Mat4x4.init(.{
        ///     &vec4(1, 0, 0, tx),
        ///     &vec4(0, 1, 0, ty),
        ///     &vec4(0, 0, 1, tz),
        ///     &vec4(0, 0, 0, tw),
        /// });
        /// ```
        ///
        /// Note that Mach matrices use [column-major storage and column-vectors](https://machengine.org/engine/math/matrix-storage/).
        pub inline fn init(vecs: [rows]*const RowVec) Self {
            var result: Self = undefined;
            inline for (0..rows) |row_i| {
                inline for (0..cols) |col_i| {
                    result.v[col_i].v[row_i] = vecs[row_i].v[col_i];
                }
            }
            return result;
        }

        /// Init a 2x2 matrix
        pub inline fn init2(r0: *const RowVec, r1: *const RowVec) Mat2x2(T) {
            return .init(.{ r0, r1 });
        }
        /// Init a 3x3 matrix
        pub inline fn init3(r0: *const RowVec, r1: *const RowVec, r2: *const RowVec) Mat3x3(T) {
            return .init(.{ r0, r1, r2 });
        }
        /// Init a 4x4 matrix
        pub inline fn init4(r0: *const RowVec, r1: *const RowVec, r2: *const RowVec, r3: *const RowVec) Mat4x4(T) {
            return .init(.{ r0, r1, r2, r3 });
        }

        /// Identity matrix
        pub const ident: Self = blk: {
            var result: Self = undefined;
            for (0..rows) |row_i| {
                for (0..cols) |col_i| {
                    result.v[col_i].v[row_i] = if (row_i == col_i) 1 else 0;
                }
            }
            break :blk result;
        };

        /// Returns the row `i` of the matrix.
        pub inline fn row(self: *const Self, i: usize) RowVec {
            var result: RowVec = undefined;
            inline for (0..cols) |col_i| {
                result.v[col_i] = self.v[col_i].v[i];
            }
            return result;
        }

        /// Returns the column `i` of the matrix.
        pub inline fn col(self: *const Self, i: usize) ColVec {
            return self.v[i];
        }

        /// Transposes the matrix.
        pub inline fn transpose(self: *const Self) Mat(T, cols, rows) {
            var result: Mat(T, cols, rows) = undefined;
            for (0..rows) |row_i| {
                for (0..cols) |col_i| {
                    result.v[row_i].v[col_i] = self.v[col_i].v[row_i];
                }
            }
            return result;
        }

        /// Constructs a matrix which scales each dimension by the given vector.
        pub inline fn scale(s: MinVecMinusOne) Self {
            var result: Self = .ident;
            inline for (0..@TypeOf(s).n) |i| {
                result.v[i].v[i] *= s.v[i];
            }
            return result;
        }

        /// Constructs a matrix which scales each dimension by the given scalar.
        pub inline fn scaleScalar(t: T) Self {
            return scale(.splat(t));
        }

        /// Constructs a matrix which translates coordinates by the given vector.
        pub inline fn translate(t: MinVecMinusOne) Self {
            var result: Self = .ident;
            inline for (0..@TypeOf(t).n) |i| {
                result.v[cols - 1].v[i] += t.v[i];
            }
            return result;
        }

        /// Constructs a 1D matrix which translates coordinates by the given scalar.
        pub inline fn translateScalar(t: T) Self {
            return translate(.splat(t));
        }

        pub inline fn translation(t: *const Self) MinVecMinusOne {
            var result: MinVecMinusOne = undefined;
            inline for (0..MinVecMinusOne.n) |i| {
                result.v[i] = t.v[cols - 1].v[i];
            }
            return result;
        }

        /// Constructs a 3D matrix which rotates around the X axis by `angle_radians`.
        pub inline fn rotateX(angle_radians: f32) Mat4x4(T) {
            const c = math.cos(angle_radians);
            const s = math.sin(angle_radians);
            return .init(.{
                &.init(.{ 1, 0, 0, 0 }),
                &.init(.{ 0, c, -s, 0 }),
                &.init(.{ 0, s, c, 0 }),
                &.init(.{ 0, 0, 0, 1 }),
            });
        }

        /// Constructs a 3D matrix which rotates around the Y axis by `angle_radians`.
        pub inline fn rotateY(angle_radians: f32) Mat4x4(T) {
            const c = math.cos(angle_radians);
            const s = math.sin(angle_radians);
            return .init(.{
                &.init(.{ c, 0, s, 0 }),
                &.init(.{ 0, 1, 0, 0 }),
                &.init(.{ -s, 0, c, 0 }),
                &.init(.{ 0, 0, 0, 1 }),
            });
        }

        /// Constructs a 3D matrix which rotates around the Z axis by `angle_radians`.
        pub inline fn rotateZ(angle_radians: f32) Mat4x4(T) {
            const c = math.cos(angle_radians);
            const s = math.sin(angle_radians);
            return .init(.{
                &.init(.{ c, -s, 0, 0 }),
                &.init(.{ s, c, 0, 0 }),
                &.init(.{ 0, 0, 1, 0 }),
                &.init(.{ 0, 0, 0, 1 }),
            });
        }

        /// Constructs a 3D matrix which rotates around the X, Y, and Z axes by the given quaternion.
        /// Requires a normalized quaternion.
        // https://www.euclideanspace.com/maths/geometry/rotations/conversions/quaternionToMatrix/jay.htm
        pub inline fn rotateByQuaternion(quaternion: quat.Quat(T)) Mat4x4(T) {
            const qx = quaternion.v.x();
            const qy = quaternion.v.y();
            const qz = quaternion.v.z();
            const qw = quaternion.v.w();

            return .init(.{
                &.init(.{ 1 - 2 * qy * qy - 2 * qz * qz, 2 * qx * qy - 2 * qz * qw, 2 * qx * qz + 2 * qy * qw, 0 }),
                &.init(.{ 2 * qx * qy + 2 * qz * qw, 1 - 2 * qx * qx - 2 * qz * qz, 2 * qy * qz - 2 * qx * qw, 0 }),
                &.init(.{ 2 * qx * qz - 2 * qy * qw, 2 * qy * qz + 2 * qx * qw, 1 - 2 * qx * qx - 2 * qy * qy, 0 }),
                &.init(.{ 0, 0, 0, 1 }),
            });
        }

        /// Matrix multiplication a * b
        ///
        /// While this operation is defined for any two matrices such that
        /// the number of columns in the first equal the number of rows in
        /// the second, this function is only implemented for matrices where
        /// the second's number of rows is equal to the first's number of
        /// columns and the second's number of columns is equal to the
        /// first's number of rows. For matrices where this is not the case,
        /// see Mat.mulN.
        pub inline fn mul(a: *const Self, b: *const Mat(T, cols, rows)) Mat(T, rows, rows) {
            @setEvalBranchQuota(10000);
            var result: Mat(T, rows, rows) = undefined;
            inline for (0..rows) |row_i| {
                inline for (0..rows) |col_i| {
                    result.v[col_i].v[row_i] = a.row(row_i).dot(&b.col(col_i));
                }
            }
            return result;
        }

        /// Matrix multiplication a * b
        ///
        /// This function is defined for any two matrices such that the
        /// number of columns in the first equal the number of rows in the
        /// second. The number of columns must be provided as an argument for
        /// type checking. For a version of this function without the extra
        /// argument, see Mat.mul.
        pub inline fn mulN(columns: comptime_int, a: *const Self, b: *const Mat(T, cols, columns)) Mat(T, rows, columns) {
            @setEvalBranchQuota(10000);
            var result: Mat(T, rows, columns) = undefined;
            inline for (0..rows) |row_i| {
                inline for (0..columns) |col_i| {
                    result.v[col_i].v[row_i] = a.row(row_i).dot(&b.col(col_i));
                }
            }
            return result;
        }

        /// Matrix * Vector multiplication
        pub inline fn mulVec(matrix: *const Self, vector: *const RowVec) ColVec {
            var result: ColVec = undefined;
            inline for (0..rows) |i| {
                result.v[i] = matrix.row(i).dot(vector);
            }
            return result;
        }

        /// Check if two matrices are approximately equal. Returns true if the absolute difference between
        /// each element in matrix is less than or equal to the specified tolerance.
        pub inline fn eqlApprox(a: *const Self, b: *const Self, tolerance: ColVec.T) bool {
            inline for (0..rows) |row_i| {
                if (!ColVec.eqlApprox(&a.v[row_i], &b.v[row_i], tolerance)) {
                    return false;
                }
            }
            return true;
        }

        /// Check if two matrices are approximately equal. Returns true if the absolute difference between
        /// each element in matrix is less than or equal to the epsilon tolerance.
        pub inline fn eql(a: *const Self, b: *const Self) bool {
            inline for (0..rows) |row_i| {
                if (!ColVec.eql(&a.v[row_i], &b.v[row_i])) {
                    return false;
                }
            }
            return true;
        }

        /// Constructs a 2D projection matrix, aka. an orthographic projection matrix.
        ///
        /// First, a cuboid is defined with the parameters:
        ///
        /// * (right - left) defining the distance between the left and right faces of the cube
        /// * (top - bottom) defining the distance between the top and bottom faces of the cube
        /// * (near - far) defining the distance between the back (near) and front (far) faces of the cube
        ///
        /// We then need to construct a projection matrix which converts points in that
        /// cuboid's space into clip space:
        ///
        /// https://machengine.org/engine/math/traversing-coordinate-systems/#view---clip-space
        ///
        /// Normally, in sysgpu/webgpu the depth buffer of floating point values would
        /// have the range [0, 1] representing [near, far], i.e. a pixel very close to the
        /// viewer would have a depth value of 0.0, and a pixel very far from the viewer
        /// would have a depth value of 1.0. But this is an ineffective use of floating
        /// point precision, a better approach is a reversed depth buffer:
        ///
        /// * https://webgpu.github.io/webgpu-samples/samples/reversedZ
        /// * https://developer.nvidia.com/content/depth-precision-visualized
        ///
        /// Mach mandates the use of a reversed depth buffer, so the returned transformation
        /// matrix maps to near=1 and far=0.
        pub inline fn projection2D(v: struct {
            left: f32,
            right: f32,
            bottom: f32,
            top: f32,
            near: f32,
            far: f32,
        }) Mat4x4(T) {
            var p: Mat4x4(T) = .ident;
            p = p.mul(&.translate(math.vec3(
                (v.right + v.left) / (v.left - v.right), // translate X so that the middle of (left, right) maps to x=0 in clip space
                (v.top + v.bottom) / (v.bottom - v.top), // translate Y so that the middle of (bottom, top) maps to y=0 in clip space
                v.far / (v.far - v.near), // translate Z so that far maps to z=0
            )));
            p = p.mul(&.scale(math.vec3(
                2 / (v.right - v.left), // scale X so that [left, right] has a 2 unit range, e.g. [-1, +1]
                2 / (v.top - v.bottom), // scale Y so that [bottom, top] has a 2 unit range, e.g. [-1, +1]
                1 / (v.near - v.far), // scale Z so that [near, far] has a 1 unit range, e.g. [0, -1]
            )));
            return p;
        }

        /// Custom format function for all matrix types.
        pub inline fn format(
            self: Self,
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) @TypeOf(writer).Error!void {
            try writer.print("{{", .{});
            inline for (0..rows) |r| {
                try std.fmt.formatType(self.row(r), fmt, options, writer, 1);
                if (r < rows - 1) {
                    try writer.print(", ", .{});
                }
            }
            try writer.print("}}", .{});
        }
    };
}

test "gpu_compatibility" {
    // https://www.w3.org/TR/WGSL/#alignment-and-size
    try testing.expect(usize, 16).eql(@sizeOf(math.Mat2x2));
    try testing.expect(usize, 48).eql(@sizeOf(math.Mat3x3));
    try testing.expect(usize, 64).eql(@sizeOf(math.Mat4x4));

    try testing.expect(usize, 8).eql(@sizeOf(math.Mat2x2h));
    try testing.expect(usize, 24).eql(@sizeOf(math.Mat3x3h));
    try testing.expect(usize, 32).eql(@sizeOf(math.Mat4x4h));

    try testing.expect(usize, 32).eql(@sizeOf(math.Mat2x2d)); // speculative
    try testing.expect(usize, 96).eql(@sizeOf(math.Mat3x3d)); // speculative
    try testing.expect(usize, 128).eql(@sizeOf(math.Mat4x4d)); // speculative
}

test "zero_struct_overhead" {
    // Proof that using e.g. [3]Vec3 is equal to [3]@Vector(3, f32)
    try testing.expect(usize, @alignOf([2]@Vector(2, f32))).eql(@alignOf(math.Mat2x2));
    try testing.expect(usize, @alignOf([3]@Vector(3, f32))).eql(@alignOf(math.Mat3x3));
    try testing.expect(usize, @alignOf([4]@Vector(4, f32))).eql(@alignOf(math.Mat4x4));
    try testing.expect(usize, @sizeOf([2]@Vector(2, f32))).eql(@sizeOf(math.Mat2x2));
    try testing.expect(usize, @sizeOf([3]@Vector(3, f32))).eql(@sizeOf(math.Mat3x3));
    try testing.expect(usize, @sizeOf([4]@Vector(4, f32))).eql(@sizeOf(math.Mat4x4));
}

test "n" {
    try testing.expect(usize, 3).eql(math.Mat3x3.cols);
    try testing.expect(usize, 3).eql(math.Mat3x3.rows);
    try testing.expect(type, math.Vec3).eql(math.Mat3x3.MinVec);
    try testing.expect(usize, 3).eql(math.Mat3x3.MinVec.n);
}

test "init" {
    try testing.expect(math.Mat3x3, math.mat3x3(
        &math.vec3(1, 0, 1337),
        &math.vec3(0, 1, 7331),
        &math.vec3(0, 0, 1),
    )).eql(math.Mat3x3{
        .v = [_]math.Vec3{
            math.vec3(1, 0, 0),
            math.vec3(0, 1, 0),
            math.vec3(1337, 7331, 1),
        },
    });
}

test "Mat2x2_ident" {
    try testing.expect(math.Mat2x2, math.Mat2x2.ident).eql(math.Mat2x2{
        .v = [_]math.Vec2{
            math.vec2(1, 0),
            math.vec2(0, 1),
        },
    });
}

test "Mat3x3_ident" {
    try testing.expect(math.Mat3x3, math.Mat3x3.ident).eql(math.Mat3x3{
        .v = [_]math.Vec3{
            math.vec3(1, 0, 0),
            math.vec3(0, 1, 0),
            math.vec3(0, 0, 1),
        },
    });
}

test "Mat4x4_ident" {
    try testing.expect(math.Mat4x4, math.Mat4x4.ident).eql(math.Mat4x4{
        .v = [_]math.Vec4{
            math.vec4(1, 0, 0, 0),
            math.vec4(0, 1, 0, 0),
            math.vec4(0, 0, 1, 0),
            math.vec4(0, 0, 0, 1),
        },
    });
}

test "Mat2x2_row" {
    const m = math.mat2x2(
        &math.vec2(0, 1),
        &math.vec2(2, 3),
    );
    try testing.expect(math.Vec2, math.vec2(0, 1)).eql(m.row(0));
    try testing.expect(math.Vec2, math.vec2(2, 3)).eql(m.row(@TypeOf(m).rows - 1));
}

test "Mat2x2_col" {
    const m = math.mat2x2(
        &math.vec2(0, 1),
        &math.vec2(2, 3),
    );
    try testing.expect(math.Vec2, math.vec2(0, 2)).eql(m.col(0));
    try testing.expect(math.Vec2, math.vec2(1, 3)).eql(m.col(@TypeOf(m).cols - 1));
}

test "Mat3x3_row" {
    const m = math.mat3x3(
        &math.vec3(0, 1, 2),
        &math.vec3(3, 4, 5),
        &math.vec3(6, 7, 8),
    );
    try testing.expect(math.Vec3, math.vec3(0, 1, 2)).eql(m.row(0));
    try testing.expect(math.Vec3, math.vec3(3, 4, 5)).eql(m.row(1));
    try testing.expect(math.Vec3, math.vec3(6, 7, 8)).eql(m.row(@TypeOf(m).rows - 1));
}

test "Mat3x3_col" {
    const m = math.mat3x3(
        &math.vec3(0, 1, 2),
        &math.vec3(3, 4, 5),
        &math.vec3(6, 7, 8),
    );
    try testing.expect(math.Vec3, math.vec3(0, 3, 6)).eql(m.col(0));
    try testing.expect(math.Vec3, math.vec3(1, 4, 7)).eql(m.col(1));
    try testing.expect(math.Vec3, math.vec3(2, 5, 8)).eql(m.col(@TypeOf(m).cols - 1));
}

test "Mat4x4_row" {
    const m = math.mat4x4(
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
    const m = math.mat4x4(
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

test "Mat2x2_transpose" {
    const m = math.mat2x2(
        &math.vec2(0, 1),
        &math.vec2(2, 3),
    );
    try testing.expect(math.Mat2x2, math.mat2x2(
        &math.vec2(0, 2),
        &math.vec2(1, 3),
    )).eql(m.transpose());
}

test "Mat3x3_transpose" {
    const m = math.mat3x3(
        &math.vec3(0, 1, 2),
        &math.vec3(3, 4, 5),
        &math.vec3(6, 7, 8),
    );
    try testing.expect(math.Mat3x3, math.mat3x3(
        &math.vec3(0, 3, 6),
        &math.vec3(1, 4, 7),
        &math.vec3(2, 5, 8),
    )).eql(m.transpose());
}

test "Mat4x4_transpose" {
    const m = math.mat4x4(
        &math.vec4(0, 1, 2, 3),
        &math.vec4(4, 5, 6, 7),
        &math.vec4(8, 9, 10, 11),
        &math.vec4(12, 13, 14, 15),
    );
    try testing.expect(math.Mat4x4, math.mat4x4(
        &math.vec4(0, 4, 8, 12),
        &math.vec4(1, 5, 9, 13),
        &math.vec4(2, 6, 10, 14),
        &math.vec4(3, 7, 11, 15),
    )).eql(m.transpose());
}

test "Mat2x2_scaleScalar" {
    const m = math.Mat2x2.scaleScalar(2);
    try testing.expect(math.Mat2x2, math.mat2x2(
        &math.vec2(2, 0),
        &math.vec2(0, 1),
    )).eql(m);
}

test "Mat3x3_scale" {
    const m = math.Mat3x3.scale(math.vec2(2, 3));
    try testing.expect(math.Mat3x3, math.mat3x3(
        &math.vec3(2, 0, 0),
        &math.vec3(0, 3, 0),
        &math.vec3(0, 0, 1),
    )).eql(m);
}

test "Mat3x3_scaleScalar" {
    const m = math.Mat3x3.scaleScalar(2);
    try testing.expect(math.Mat3x3, math.mat3x3(
        &math.vec3(2, 0, 0),
        &math.vec3(0, 2, 0),
        &math.vec3(0, 0, 1),
    )).eql(m);
}

test "Mat4x4_scale" {
    const m = math.Mat4x4.scale(math.vec3(2, 3, 4));
    try testing.expect(math.Mat4x4, math.mat4x4(
        &math.vec4(2, 0, 0, 0),
        &math.vec4(0, 3, 0, 0),
        &math.vec4(0, 0, 4, 0),
        &math.vec4(0, 0, 0, 1),
    )).eql(m);
}

test "Mat4x4_scaleScalar" {
    const m = math.Mat4x4.scaleScalar(2);
    try testing.expect(math.Mat4x4, math.mat4x4(
        &math.vec4(2, 0, 0, 0),
        &math.vec4(0, 2, 0, 0),
        &math.vec4(0, 0, 2, 0),
        &math.vec4(0, 0, 0, 1),
    )).eql(m);
}

test "Mat3x3_translate" {
    const m = math.Mat3x3.translate(math.vec2(2, 3));
    try testing.expect(math.Mat3x3, math.mat3x3(
        &math.vec3(1, 0, 2),
        &math.vec3(0, 1, 3),
        &math.vec3(0, 0, 1),
    )).eql(m);
}

test "Mat4x4_translate" {
    const m = math.Mat4x4.translate(math.vec3(2, 3, 4));
    try testing.expect(math.Mat4x4, math.mat4x4(
        &math.vec4(1, 0, 0, 2),
        &math.vec4(0, 1, 0, 3),
        &math.vec4(0, 0, 1, 4),
        &math.vec4(0, 0, 0, 1),
    )).eql(m);
}

test "Mat3x3_translateScalar" {
    const m = math.Mat3x3.translateScalar(2);
    try testing.expect(math.Mat3x3, math.mat3x3(
        &math.vec3(1, 0, 2),
        &math.vec3(0, 1, 2),
        &math.vec3(0, 0, 1),
    )).eql(m);
}

test "Mat2x2_translateScalar" {
    const m = math.Mat2x2.translateScalar(2);
    try testing.expect(math.Mat2x2, math.mat2x2(
        &math.vec2(1, 2),
        &math.vec2(0, 1),
    )).eql(m);
}

test "Mat4x4_translateScalar" {
    const m = math.Mat4x4.translateScalar(2);
    try testing.expect(math.Mat4x4, math.mat4x4(
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

test "Mat2x2_mulVec_vec2_ident" {
    const v = math.Vec2.splat(1);
    const ident = math.Mat2x2.ident;
    const expected = v;
    const m = math.Mat2x2.mulVec(&ident, &v);

    try testing.expect(math.Vec2, expected).eql(m);
}

test "Mat2x2_mulVec_vec2" {
    const v = math.Vec2.splat(1);
    const mat = math.mat2x2(
        &math.vec2(2, 0),
        &math.vec2(0, 2),
    );

    const m = math.Mat2x2.mulVec(&mat, &v);
    const expected = math.vec2(2, 2);
    try testing.expect(math.Vec2, expected).eql(m);
}

test "Mat3x3_mulVec_vec3_ident" {
    const v = math.Vec3.splat(1);
    const ident = math.Mat3x3.ident;
    const expected = v;
    const m = math.Mat3x3.mulVec(&ident, &v);

    try testing.expect(math.Vec3, expected).eql(m);
}

test "Mat3x3_mulVec_vec3" {
    const v = math.Vec3.splat(1);
    const mat = math.mat3x3(
        &math.vec3(2, 0, 0),
        &math.vec3(0, 2, 0),
        &math.vec3(0, 0, 3),
    );

    const m = math.Mat3x3.mulVec(&mat, &v);
    const expected = math.vec3(2, 2, 3);
    try testing.expect(math.Vec3, expected).eql(m);
}

test "Mat4x4_mulVec_vec4" {
    const v = math.vec4(2, 5, 1, 8);
    const mat = math.mat4x4(
        &math.vec4(1, 0, 2, 0),
        &math.vec4(0, 3, 0, 4),
        &math.vec4(0, 0, 5, 0),
        &math.vec4(6, 0, 0, 7),
    );

    const m = math.Mat4x4.mulVec(&mat, &v);
    const expected = math.vec4(4, 47, 5, 68);
    try testing.expect(math.Vec4, expected).eql(m);
}

test "Mat2x2_mul" {
    const a = math.mat2x2(
        &math.vec2(4, 2),
        &math.vec2(7, 9),
    );
    const b = math.mat2x2(
        &math.vec2(5, -7),
        &math.vec2(6, -3),
    );
    const c = math.Mat2x2.mul(&a, &b);

    const expected = math.mat2x2(
        &math.vec2(32, -34),
        &math.vec2(89, -76),
    );
    try testing.expect(math.Mat2x2, expected).eql(c);
}

test "Mat3x2_mul" {
    const a = math.MatMxN(3, 2).init(.{
        &math.vec2(4, 2),
        &math.vec2(7, 9),
        &math.vec2(-1, 8),
    });
    const b = math.MatMxN(2, 3).init(.{
        &math.vec3(5, -7, -8),
        &math.vec3(6, -3, 2),
    });
    const c = math.MatMxN(3, 2).mul(&a, &b);

    const expected = math.mat3x3(
        &math.vec3(32, -34, -28),
        &math.vec3(89, -76, -38),
        &math.vec3(43, -17, 24),
    );
    try testing.expect(math.Mat3x3, expected).eql(c);
}

test "Mat3x3_mul" {
    const a = math.mat3x3(
        &math.vec3(4, 2, -3),
        &math.vec3(7, 9, -8),
        &math.vec3(-1, 8, -8),
    );
    const b = math.mat3x3(
        &math.vec3(5, -7, -8),
        &math.vec3(6, -3, 2),
        &math.vec3(-3, -4, 4),
    );
    const c = math.Mat3x3.mul(&a, &b);

    const expected = math.mat3x3(
        &math.vec3(41, -22, -40),
        &math.vec3(113, -44, -70),
        &math.vec3(67, 15, -8),
    );
    try testing.expect(math.Mat3x3, expected).eql(c);
}

test "Mat3x4_mul" {
    const a = math.MatMxN(3, 4).init(.{
        &math.vec4(10, -5, 6, -2),
        &math.vec4(0, -1, 0, 9),
        &math.vec4(-1, 6, -4, 8),
    });
    const b = math.MatMxN(4, 3).init(.{
        &math.vec3(7, -7, -3),
        &math.vec3(1, -1, -7),
        &math.vec3(-10, 2, 2),
        &math.vec3(10, -7, 7),
    });
    const c = math.MatMxN(3, 4).mul(&a, &b);

    const expected = math.mat3x3(
        &math.vec3(-15, -39, 3),
        &math.vec3(89, -62, 70),
        &math.vec3(119, -63, 9),
    );
    try testing.expect(math.Mat3x3, expected).eql(c);
}

test "Mat4x4_mul" {
    const a = math.mat4x4(
        &math.vec4(10, -5, 6, -2),
        &math.vec4(0, -1, 0, 9),
        &math.vec4(-1, 6, -4, 8),
        &math.vec4(9, -8, -6, -10),
    );
    const b = math.mat4x4(
        &math.vec4(7, -7, -3, -8),
        &math.vec4(1, -1, -7, -2),
        &math.vec4(-10, 2, 2, -2),
        &math.vec4(10, -7, 7, 1),
    );
    const c = math.Mat4x4.mul(&a, &b);

    const expected = math.mat4x4(
        &math.vec4(-15, -39, 3, -84),
        &math.vec4(89, -62, 70, 11),
        &math.vec4(119, -63, 9, 12),
        &math.vec4(15, 3, -53, -54),
    );
    try testing.expect(math.Mat4x4, expected).eql(c);
}

test "Mat1x3_mulN" {
    const a = math.MatMxN(1, 3).init(.{
        &math.vec3(3, 4, 2),
    });
    const b = math.MatMxN(3, 4).init(.{
        &math.vec4(13, 9, 7, 15),
        &math.vec4(8, 7, 4, 6),
        &math.vec4(6, 4, 0, 3),
    });
    const c = math.MatMxN(1, 3).mulN(4, &a, &b);

    const expected = math.MatMxN(1, 4).init(.{
        &math.vec4(83, 63, 37, 75),
    });
    try testing.expect(math.MatMxN(1, 4), expected).eql(c);
}

test "Mat4x4_eql_not_ident" {
    const m1 = math.mat4x4(
        &math.vec4(0, 1, 2, 3),
        &math.vec4(4, 5, 6, 7),
        &math.vec4(8, 9, 10, 11),
        &math.vec4(12, 13, 14, 15),
    );
    const m2 = math.mat4x4(
        &math.vec4(0, 1, 2, 3),
        &math.vec4(4.5, 5, 6, 7),
        &math.vec4(8, 9, 10, 11),
        &math.vec4(12, 13, 14, 15),
    );
    try testing.expect(bool, math.Mat4x4.eql(&m1, &m2)).eql(false);
}

test "Mat4x4_eql_ident" {
    const m1 = math.mat4x4(
        &math.vec4(0, 1, 2, 3),
        &math.vec4(4, 5, 6, 7),
        &math.vec4(8, 9, 10, 11),
        &math.vec4(12, 13, 14, 15),
    );
    const m2 = math.mat4x4(
        &math.vec4(0, 1, 2, 3),
        &math.vec4(4, 5, 6, 7),
        &math.vec4(8, 9, 10, 11),
        &math.vec4(12, 13, 14, 15),
    );
    try testing.expect(bool, math.Mat4x4.eql(&m1, &m2)).eql(true);
}

test "Mat4x4_eqlApprox_not_ident" {
    const m1 = math.mat4x4(
        &math.vec4(0, 1, 2, 3),
        &math.vec4(4, 5, 6, 7),
        &math.vec4(8, 9, 10, 11),
        &math.vec4(12, 13, 14, 15),
    );
    const m2 = math.mat4x4(
        &math.vec4(0, 1, 2, 3),
        &math.vec4(4.11, 5, 6, 7),
        &math.vec4(8, 9, 10, 11),
        &math.vec4(12, 13, 14, 15),
    );
    try testing.expect(bool, math.Mat4x4.eqlApprox(&m1, &m2, 0.1)).eql(false);
}

test "Mat4x4_eqlApprox_ident" {
    const m1 = math.mat4x4(
        &math.vec4(0, 1, 2, 3),
        &math.vec4(4, 5, 6, 7),
        &math.vec4(8, 9, 10, 11),
        &math.vec4(12, 13, 14, 15),
    );
    const m2 = math.mat4x4(
        &math.vec4(0, 1, 2, 3),
        &math.vec4(4.09, 5, 6, 7),
        &math.vec4(8, 9, 10, 11),
        &math.vec4(12, 13, 14, 15),
    );
    try testing.expect(bool, math.Mat4x4.eqlApprox(&m1, &m2, 0.1)).eql(true);
}

test "projection2D_xy_centered" {
    const left = -400;
    const right = 400;
    const bottom = -200;
    const top = 200;
    const near = 0;
    const far = 100;
    const m = math.Mat4x4.projection2D(.{
        .left = left,
        .right = right,
        .bottom = bottom,
        .top = top,
        .near = near,
        .far = far,
    });

    // Calculate some reference points
    const width = right - left;
    const height = top - bottom;
    const width_mid = left + (width / 2.0);
    const height_mid = bottom + (height / 2.0);
    try testing.expect(f32, 800).eql(width);
    try testing.expect(f32, 400).eql(height);
    try testing.expect(f32, 0).eql(width_mid);
    try testing.expect(f32, 0).eql(height_mid);

    // Probe some points on the X axis from beyond the left face, all the way to beyond the right face.
    try testing.expect(math.Vec4, math.vec4(-2, 0, 1, 1)).eql(m.mulVec(&math.vec4(left - (width / 2), height_mid, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(-1, 0, 1, 1)).eql(m.mulVec(&math.vec4(left, height_mid, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(-0.5, 0, 1, 1)).eql(m.mulVec(&math.vec4(left + (width / 4.0), height_mid, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 0, 1, 1)).eql(m.mulVec(&math.vec4(width_mid, height_mid, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0.5, 0, 1, 1)).eql(m.mulVec(&math.vec4(right - (width / 4.0), height_mid, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(1, 0, 1, 1)).eql(m.mulVec(&math.vec4(right, height_mid, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(2, 0, 1, 1)).eql(m.mulVec(&math.vec4(right + (width / 2), height_mid, 0, 1)));

    // Probe some points on the Y axis from beyond the bottom face, all the way to beyond the top face.
    try testing.expect(math.Vec4, math.vec4(0, -2, 1, 1)).eql(m.mulVec(&math.vec4(width_mid, bottom - (height / 2), 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0, -1, 1, 1)).eql(m.mulVec(&math.vec4(width_mid, bottom, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0, -0.5, 1, 1)).eql(m.mulVec(&math.vec4(width_mid, bottom + (height / 4.0), 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 0, 1, 1)).eql(m.mulVec(&math.vec4(width_mid, height_mid, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 0.5, 1, 1)).eql(m.mulVec(&math.vec4(width_mid, top - (height / 4.0), 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 1, 1, 1)).eql(m.mulVec(&math.vec4(width_mid, top, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 2, 1, 1)).eql(m.mulVec(&math.vec4(width_mid, top + (height / 2), 0, 1)));
}

test "projection2D_xy_offcenter" {
    const left = 100;
    const right = 500;
    const bottom = 100;
    const top = 500;
    const near = 0;
    const far = 100;
    const m = math.Mat4x4.projection2D(.{
        .left = left,
        .right = right,
        .bottom = bottom,
        .top = top,
        .near = near,
        .far = far,
    });

    // Calculate some reference points
    const width = right - left;
    const height = top - bottom;
    const width_mid = left + (width / 2.0);
    const height_mid = bottom + (height / 2.0);
    try testing.expect(f32, 400).eql(width);
    try testing.expect(f32, 400).eql(height);
    try testing.expect(f32, 300).eql(width_mid);
    try testing.expect(f32, 300).eql(height_mid);

    // Probe some points on the X axis from beyond the left face, all the way to beyond the right face.
    try testing.expect(math.Vec4, math.vec4(-2, 0, 1, 1)).eql(m.mulVec(&math.vec4(left - (width / 2), height_mid, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(-1, 0, 1, 1)).eql(m.mulVec(&math.vec4(left, height_mid, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(-0.5, 0, 1, 1)).eql(m.mulVec(&math.vec4(left + (width / 4.0), height_mid, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 0, 1, 1)).eql(m.mulVec(&math.vec4(width_mid, height_mid, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0.5, 0, 1, 1)).eql(m.mulVec(&math.vec4(right - (width / 4.0), height_mid, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(1, 0, 1, 1)).eql(m.mulVec(&math.vec4(right, height_mid, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(2, 0, 1, 1)).eql(m.mulVec(&math.vec4(right + (width / 2), height_mid, 0, 1)));

    // Probe some points on the Y axis from beyond the bottom face, all the way to beyond the top face.
    try testing.expect(math.Vec4, math.vec4(0, -2, 1, 1)).eql(m.mulVec(&math.vec4(width_mid, bottom - (height / 2), 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0, -1, 1, 1)).eql(m.mulVec(&math.vec4(width_mid, bottom, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0, -0.5, 1, 1)).eql(m.mulVec(&math.vec4(width_mid, bottom + (height / 4.0), 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 0, 1, 1)).eql(m.mulVec(&math.vec4(width_mid, height_mid, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 0.5, 1, 1)).eql(m.mulVec(&math.vec4(width_mid, top - (height / 4.0), 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 1, 1, 1)).eql(m.mulVec(&math.vec4(width_mid, top, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 2, 1, 1)).eql(m.mulVec(&math.vec4(width_mid, top + (height / 2), 0, 1)));
}

test "projection2D_z" {
    const m = math.Mat4x4.projection2D(.{
        // Set x=0 and y=0 as centers, so we can specify 0 centers in our testing.expects below
        .left = -400,
        .right = 400,
        .bottom = -200,
        .top = 200,

        // Choose some near/far plane values that we can easily test against
        // We'll have [near, far] == [-100, 100] == [1, 0]
        .near = -100,
        .far = 100,
    });

    // Probe some points on the Z axis from the near plane, all the way to the far plane.
    try testing.expect(math.Vec4, math.vec4(0, 0, 1, 1)).eql(m.mulVec(&math.vec4(0, 0, -100, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 0, 0.75, 1)).eql(m.mulVec(&math.vec4(0, 0, -50, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 0, 0.5, 1)).eql(m.mulVec(&math.vec4(0, 0, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 0, 0.25, 1)).eql(m.mulVec(&math.vec4(0, 0, 50, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 0, 0, 1)).eql(m.mulVec(&math.vec4(0, 0, 100, 1)));

    // Probe some points outside the near/far planes
    try testing.expect(math.Vec4, math.vec4(0, 0, 2, 1)).eql(m.mulVec(&math.vec4(0, 0, -100 - 200, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 0, -1, 1)).eql(m.mulVec(&math.vec4(0, 0, 100 + 200, 1)));
}

test "projection2D_z_positive" {
    const m = math.Mat4x4.projection2D(.{
        // Set x=0 and y=0 as centers, so we can specify 0 centers in our testing.expects below
        .left = -400,
        .right = 400,
        .bottom = -200,
        .top = 200,

        // Choose some near/far plane values that we can easily test against
        // We'll have [near, far] == [0, 100] == [1, 0]
        .near = 0,
        .far = 100,
    });

    // Probe some points on the Z axis from the near plane, all the way to the far plane.
    try testing.expect(math.Vec4, math.vec4(0, 0, 1, 1)).eql(m.mulVec(&math.vec4(0, 0, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 0, 0.75, 1)).eql(m.mulVec(&math.vec4(0, 0, 25, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 0, 0.5, 1)).eql(m.mulVec(&math.vec4(0, 0, 50, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 0, 0.25, 1)).eql(m.mulVec(&math.vec4(0, 0, 75, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 0, 0, 1)).eql(m.mulVec(&math.vec4(0, 0, 100, 1)));

    // Probe some points outside the near/far planes
    try testing.expect(math.Vec4, math.vec4(0, 0, 2, 1)).eql(m.mulVec(&math.vec4(0, 0, 0 - 100, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 0, -1, 1)).eql(m.mulVec(&math.vec4(0, 0, 100 + 100, 1)));
}

test "projection2D_model_to_clip_space" {
    const model = math.Mat4x4.ident;
    const view = math.Mat4x4.ident;
    const proj = math.Mat4x4.projection2D(.{
        .left = -50,
        .right = 50,
        .bottom = -50,
        .top = 50,
        .near = 0,
        .far = 100,
    });
    const mvp = model.mul(&view).mul(&proj);

    try testing.expect(math.Vec4, math.vec4(0, 0, 1.0, 1)).eql(mvp.mulVec(&math.vec4(0, 0, 0, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 0, 0.5, 1)).eql(mvp.mulVec(&math.vec4(0, 0, 50, 1)));
    try testing.expect(math.Vec4, math.vec4(0, -1, 1, 1)).eql(mvp.mul(&math.Mat4x4.rotateX(math.degreesToRadians(90))).mulVec(&math.vec4(0, 0, 50, 1)));
    try testing.expect(math.Vec4, math.vec4(1, 0, 1, 1)).eql(mvp.mul(&math.Mat4x4.rotateY(math.degreesToRadians(90))).mulVec(&math.vec4(0, 0, 50, 1)));
    try testing.expect(math.Vec4, math.vec4(0, 0, 0.5, 1)).eql(mvp.mul(&math.Mat4x4.rotateZ(math.degreesToRadians(90))).mulVec(&math.vec4(0, 0, 50, 1)));
}

test "quaternion_rotation" {
    const expected = math.mat4x4(
        &math.vec4(0.7716905, 0.5519065, 0.3160585, 0),
        &math.vec4(-0.0782971, -0.4107276, 0.9083900, 0),
        &math.vec4(0.6311602, -0.7257425, -0.2737419, 0),
        &math.vec4(0, 0, 0, 1),
    );

    const q = math.Quat.fromAxisAngle(math.vec3(0.9182788, 0.1770672, 0.3541344), 4.2384558);
    const result = math.Mat4x4.rotateByQuaternion(q.normalize());

    try testing.expect(bool, true).eql(expected.eqlApprox(&result, 0.0000002));
}
