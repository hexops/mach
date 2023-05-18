//! # mach/math is opinionated
//!
//! Math is hard enough as-is, without you having to question ground truths while problem solving.
//! As a result, mach/math takes a more opinionated approach than some other math libraries: we try
//! to encourage you through API design to use what we believe to be the best choices. For example,
//! other math libraries provide both LH and RH (left-handed and right-handed) variants for each
//! operation, and they sit on equal footing for you to choose from; mach/math may also provide both
//! variants as needed for conversions, but unlike other libraries will bless one choice with e.g.
//! a shorter function name to nudge you in the right direction and towards _consistency_.
//!
//! ## Matrices
//!
//! * Column-major matrix storage
//! * Column-vectors (i.e. right-associative multiplication, matrix * vector = vector)
//!
//! The benefit of using this "OpenGL-style" matrix is that it matches the conventions accepted by
//! the scientific community, it's what you'll find in linear algebra textbooks. It also matches
//! WebGPU, Vulkan, Unity3D, etc. It does NOT match DirectX-style which e.g. Unreal Engine uses.
//!
//! Note: many people will say "row major" or "column major" and implicitly mean three or more
//! different concepts; to avoid confusion we'll go over this in more depth below.
//!
//! ## Coordinate system (+Y up, left-handed)
//!
//! * Normalized Device coordinates: +Y up; (-1, -1) is at the bottom-left corner.
//! * Framebuffer coordinates: +Y down; (0, 0) is at the top-left corner.
//! * Texture coordinates:     +Y down; (0, 0) is at the top-left corner.
//!
//! This coordinate system is consistent with WebGPU, Metal, DirectX, and Unity (NDC only.)
//!
//! Note that since +Y is up (not +Z), developers can seamlessly transition from 2D applications
//! to 3D applications by adding the Z component. This is in contrast to e.g. Z-up coordinate
//! systems, where 2D and 3D must differ.
//!
//! ## Additional reading
//!
//! * [Coordinate system explainer](https://machengine.org/next/engine/math/coordinate-system/)
//! * [Matrix storage explainer](https://machengine.org/next/engine/math/matrix-storage/)
//!

const std = @import("std");

pub const Vec2 = @Vector(2, f32);
pub const Vec3 = @Vector(3, f32);
pub const Vec4 = @Vector(4, f32);
pub const Mat3x3 = @Vector(3 * 4, f32);
pub const Mat4x4 = @Vector(4 * 4, f32);

/// Vector operations
pub const vec = struct {
    /// Returns the vector dimension size of the given type
    ///
    /// ```
    /// vec.size(Vec3) == 3
    /// ```
    pub inline fn size(comptime T: type) comptime_int {
        switch (@typeInfo(T)) {
            .Vector => |info| return info.len,
            else => @compileError("Expected vector, found '" ++ @typeName(T) ++ "'"),
        }
    }

    /// Returns a vector with all components set to the `scalar` value:
    ///
    /// ```
    /// var v = vec.splat(Vec3, 1337.0);
    /// // v.x == 1337, v.y == 1337, v.z == 1337
    /// ```
    pub inline fn splat(comptime V: type, scalar: f32) V {
        return @splat(size(V), scalar);
    }

    /// Computes the squared length of the vector. Faster than `len()`
    pub inline fn len2(v: anytype) f32 {
        switch (@TypeOf(v)) {
            Vec2 => return (v[0] * v[0]) + (v[1] * v[1]),
            Vec3 => return (v[0] * v[0]) + (v[1] * v[1]) + (v[2] * v[2]),
            Vec4 => return (v[0] * v[0]) + (v[1] * v[1]) + (v[2] * v[2]) + (v[3] * v[3]),
            else => @compileError("Expected vector, found '" ++ @typeName(@TypeOf(v)) ++ "'"),
        }
    }

    /// Computes the length of the vector.
    pub inline fn len(v: anytype) f32 {
        return std.math.sqrt(len2(v));
    }

    /// Normalizes a vector, such that all components end up in the range [0.0, 1.0].
    ///
    /// d0 is added to the divisor, which means that e.g. if you provide a near-zero value, then in
    /// situations where you would otherwise get NaN back you will instead get a near-zero vector.
    ///
    /// ```
    /// var v = normalize(v, 0.00000001);
    /// ```
    pub inline fn normalize(v: anytype, d0: f32) @TypeOf(v) {
        return v / (splat(@TypeOf(v), len(v) + d0));
    }

    /// Returns the normalized direction vector from points a and b.
    ///
    /// d0 is added to the divisor, which means that e.g. if you provide a near-zero value, then in
    /// situations where you would otherwise get NaN back you will instead get a near-zero vector.
    ///
    /// ```
    /// var v = dir(a_point, b_point);
    /// ```
    pub inline fn dir(a: anytype, b: @TypeOf(a), d0: f32) @TypeOf(a) {
        return normalize(b - a, d0);
    }

    /// Calculates the squared distance between points a and b. Faster than `dist()`.
    pub inline fn dist2(a: anytype, b: @TypeOf(a)) f32 {
        return len2(b - a);
    }

    /// Calculates the distance between points a and b.
    pub inline fn dist(a: anytype, b: @TypeOf(a)) f32 {
        return std.math.sqrt(dist2(a, b));
    }

    /// Performs linear interpolation between a and b by some amount.
    ///
    /// ```
    /// lerp(a, b, 0.0) == a
    /// lerp(a, b, 1.0) == b
    /// ```
    pub inline fn lerp(a: anytype, b: @TypeOf(a), amount: f32) @TypeOf(a) {
        return (a * splat(@TypeOf(a), 1.0 - amount)) + (b * splat(@TypeOf(a), amount));
    }
};

/// Matrix operations
pub const mat = struct {
    /// Constructs an identity matrix of type T.
    pub inline fn identity(comptime T: type) T {
        return if (T == Mat3x3) .{
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
        } else if (T == Mat4x4) .{
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1,
        } else @compileError("Expected matrix, found '" ++ @typeName(T) ++ "'");
    }

    /// Constructs an orthographic projection matrix; an orthogonal transformation matrix which
    /// transforms from the given left, right, bottom, and top dimensions into -1 +1 in x and y,
    /// and 0 to +1 in z.
    ///
    /// The near/far parameters denotes the depth (z coordinate) of the near/far clipping plane.
    ///
    /// Returns an orthographic projection matrix.
    pub inline fn ortho(
        /// The sides of the near clipping plane viewport
        left: f32,
        right: f32,
        bottom: f32,
        top: f32,
        /// The depth (z coordinate) of the near/far clipping plane.
        near: f32,
        far: f32,
    ) Mat4x4 {
        const xx = 2 / (right - left);
        const yy = 2 / (top - bottom);
        const zz = 1 / (near - far);
        const tx = (right + left) / (left - right);
        const ty = (top + bottom) / (bottom - top);
        const tz = near / (near - far);
        return .{
            xx, 0,  0,  0,
            0,  yy, 0,  0,
            0,  0,  zz, 0,
            tx, ty, tz, 1,
        };
    }

    /// Constructs a 2D matrix which translates coordinates by v.
    pub inline fn translate2d(v: Vec2) Mat3x3 {
        return .{
            1,    0,    0, 0,
            0,    1,    0, 0,
            v[0], v[1], 1, 0,
        };
    }

    /// Constructs a 3D matrix which translates coordinates by v.
    pub inline fn translate3d(v: Vec3) Mat4x4 {
        return .{
            1,    0,    0,    0,
            0,    1,    0,    0,
            0,    0,    1,    0,
            v[0], v[1], v[2], 1,
        };
    }

    /// Returns the translation component of the 2D matrix.
    pub inline fn translation2d(v: Mat3x3) Vec2 {
        return .{ v[8], v[9] };
    }

    /// Returns the translation component of the 3D matrix.
    pub inline fn translation3d(v: Mat4x4) Vec3 {
        return .{ v[12], v[13], v[14] };
    }

    /// Constructs a 3D matrix which scales each dimension by the given vector.
    pub inline fn scale3d(v: Vec3) Mat4x4 {
        return .{
            v[0], 0,    0,    0,
            0,    v[1], 0,    0,
            0,    0,    v[2], 0,
            0,    0,    0,    1,
        };
    }

    /// Constructs a 3D matrix which scales each dimension by the given vector.
    pub inline fn scale2d(v: Vec2) Mat3x3 {
        return .{
            v[0], 0,    0, 0,
            0,    v[1], 0, 0,
            0,    0,    1, 0,
        };
    }

    // Multiplies matrices a * b
    pub inline fn mul(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
        return if (@TypeOf(a) == Mat3x3) {
            const a00 = a[0];
            const a01 = a[1];
            const a02 = a[2];
            const a10 = a[4 + 0];
            const a11 = a[4 + 1];
            const a12 = a[4 + 2];
            const a20 = a[8 + 0];
            const a21 = a[8 + 1];
            const a22 = a[8 + 2];
            const b00 = b[0];
            const b01 = b[1];
            const b02 = b[2];
            const b10 = b[4 + 0];
            const b11 = b[4 + 1];
            const b12 = b[4 + 2];
            const b20 = b[8 + 0];
            const b21 = b[8 + 1];
            const b22 = b[8 + 2];
            return .{
                a00 * b00 + a10 * b01 + a20 * b02,
                a01 * b00 + a11 * b01 + a21 * b02,
                a02 * b00 + a12 * b01 + a22 * b02,
                a00 * b10 + a10 * b11 + a20 * b12,
                a01 * b10 + a11 * b11 + a21 * b12,
                a02 * b10 + a12 * b11 + a22 * b12,
                a00 * b20 + a10 * b21 + a20 * b22,
                a01 * b20 + a11 * b21 + a21 * b22,
                a02 * b20 + a12 * b21 + a22 * b22,
            };
        } else if (@TypeOf(a) == Mat4x4) {
            const a00 = a[0];
            const a01 = a[1];
            const a02 = a[2];
            const a03 = a[3];
            const a10 = a[4 + 0];
            const a11 = a[4 + 1];
            const a12 = a[4 + 2];
            const a13 = a[4 + 3];
            const a20 = a[8 + 0];
            const a21 = a[8 + 1];
            const a22 = a[8 + 2];
            const a23 = a[8 + 3];
            const a30 = a[12 + 0];
            const a31 = a[12 + 1];
            const a32 = a[12 + 2];
            const a33 = a[12 + 3];
            const b00 = b[0];
            const b01 = b[1];
            const b02 = b[2];
            const b03 = b[3];
            const b10 = b[4 + 0];
            const b11 = b[4 + 1];
            const b12 = b[4 + 2];
            const b13 = b[4 + 3];
            const b20 = b[8 + 0];
            const b21 = b[8 + 1];
            const b22 = b[8 + 2];
            const b23 = b[8 + 3];
            const b30 = b[12 + 0];
            const b31 = b[12 + 1];
            const b32 = b[12 + 2];
            const b33 = b[12 + 3];
            return .{
                a00 * b00 + a10 * b01 + a20 * b02 + a30 * b03,
                a01 * b00 + a11 * b01 + a21 * b02 + a31 * b03,
                a02 * b00 + a12 * b01 + a22 * b02 + a32 * b03,
                a03 * b00 + a13 * b01 + a23 * b02 + a33 * b03,
                a00 * b10 + a10 * b11 + a20 * b12 + a30 * b13,
                a01 * b10 + a11 * b11 + a21 * b12 + a31 * b13,
                a02 * b10 + a12 * b11 + a22 * b12 + a32 * b13,
                a03 * b10 + a13 * b11 + a23 * b12 + a33 * b13,
                a00 * b20 + a10 * b21 + a20 * b22 + a30 * b23,
                a01 * b20 + a11 * b21 + a21 * b22 + a31 * b23,
                a02 * b20 + a12 * b21 + a22 * b22 + a32 * b23,
                a03 * b20 + a13 * b21 + a23 * b22 + a33 * b23,
                a00 * b30 + a10 * b31 + a20 * b32 + a30 * b33,
                a01 * b30 + a11 * b31 + a21 * b32 + a31 * b33,
                a02 * b30 + a12 * b31 + a22 * b32 + a32 * b33,
                a03 * b30 + a13 * b31 + a23 * b32 + a33 * b33,
            };
        } else @compileError("Expected matrix, found '" ++ @typeName(@TypeOf(a)) ++ "'");
    }

    /// Constructs a 3D matrix which rotates around the Z axis by `angle_radians`.
    pub inline fn rotateZ(angle_radians: f32) Mat4x4 {
        const c = std.math.cos(angle_radians);
        const s = std.math.sin(angle_radians);

        return .{
            c,  s, 0, 0,
            -s, c, 0, 0,
            0,  0, 1, 0,
            0,  0, 0, 1,
        };
    }
};
