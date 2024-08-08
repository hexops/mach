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
//! * Framebuffer coordinates:       +Y down; (0, 0) is at the top-left corner.
//! * Texture coordinates:           +Y down; (0, 0) is at the top-left corner.
//!
//! This coordinate system is consistent with WebGPU, Metal, DirectX, and Unity (NDC only.)
//!
//! Note that since +Y is up (not +Z), developers can seamlessly transition from 2D applications
//! to 3D applications by adding the Z component. This is in contrast to e.g. Z-up coordinate
//! systems, where 2D and 3D must differ.
//!
//! ## Additional reading
//!
//! * [Coordinate system explainer](https://machengine.org/engine/math/coordinate-system/)
//! * [Matrix storage explainer](https://machengine.org/engine/math/matrix-storage/)
//!

const std = @import("std");
const testing = std.testing;

const vec = @import("vec.zig");
const mat = @import("mat.zig");
const q = @import("quat.zig");
const ray = @import("ray.zig");

/// Public namespaces
pub const collision = @import("collision.zig");

/// Standard f32 precision types
pub const Vec2 = vec.Vec2(f32);
pub const Vec3 = vec.Vec3(f32);
pub const Vec4 = vec.Vec4(f32);
pub const Quat = q.Quat(f32);
pub const Mat2x2 = mat.Mat2x2(f32);
pub const Mat3x3 = mat.Mat3x3(f32);
pub const Mat4x4 = mat.Mat4x4(f32);
pub const Ray = ray.Ray3(f32);

/// Half-precision f16 types
pub const Vec2h = vec.Vec2(f16);
pub const Vec3h = vec.Vec3(f16);
pub const Vec4h = vec.Vec4(f16);
pub const Quath = q.Quat(f16);
pub const Mat2x2h = mat.Mat2x2(f16);
pub const Mat3x3h = mat.Mat3x3(f16);
pub const Mat4x4h = mat.Mat4x4(f16);
pub const Rayh = ray.Ray3(f16);

/// Double-precision f64 types
pub const Vec2d = vec.Vec2(f64);
pub const Vec3d = vec.Vec3(f64);
pub const Vec4d = vec.Vec4(f64);
pub const Quatd = q.Quat(f64);
pub const Mat2x2d = mat.Mat2x2(f64);
pub const Mat3x3d = mat.Mat3x3(f64);
pub const Mat4x4d = mat.Mat4x4(f64);
pub const Rayd = ray.Ray3(f64);

/// Standard f32 precision initializers
pub const vec2 = Vec2.init;
pub const vec3 = Vec3.init;
pub const vec4 = Vec4.init;
pub const vec2FromInt = Vec2.fromInt;
pub const vec3FromInt = Vec3.fromInt;
pub const vec4FromInt = Vec4.fromInt;
pub const quat = Quat.init;
pub const mat2x2 = Mat2x2.init;
pub const mat3x3 = Mat3x3.init;
pub const mat4x4 = Mat4x4.init;

/// Half-precision f16 initializers
pub const vec2h = Vec2h.init;
pub const vec3h = Vec3h.init;
pub const vec4h = Vec4h.init;
pub const vec2hFromInt = Vec2h.fromInt;
pub const vec3hFromInt = Vec3h.fromInt;
pub const vec4hFromInt = Vec4h.fromInt;
pub const quath = Quath.init;
pub const mat2x2h = Mat2x2h.init;
pub const mat3x3h = Mat3x3h.init;
pub const mat4x4h = Mat4x4h.init;

/// Double-precision f64 initializers
pub const vec2d = Vec2d.init;
pub const vec3d = Vec3d.init;
pub const vec4d = Vec4d.init;
pub const vec2dFromInt = Vec2d.fromInt;
pub const vec3dFromInt = Vec3d.fromInt;
pub const vec4dFromInt = Vec4d.fromInt;
pub const quatd = Quatd.init;
pub const mat2x2d = Mat2x2d.init;
pub const mat3x3d = Mat3x3d.init;
pub const mat4x4d = Mat4x4d.init;

test {
    testing.refAllDeclsRecursive(@This());
}

// std.math customizations
pub const eql = std.math.approxEqAbs;
pub const eps = std.math.floatEps;
pub const eps_f16 = std.math.floatEps(f16);
pub const eps_f32 = std.math.floatEps(f32);
pub const eps_f64 = std.math.floatEps(f64);
pub const nan_f16 = std.math.nan(f16);
pub const nan_f32 = std.math.nan(f32);
pub const nan_f64 = std.math.nan(f64);

// std.math 1:1 re-exports below here
//
// Having two 'math' imports in your code is annoying, so we in general expect that people will not
// need to do this and instead can just import mach.math - we add to this list of re-exports as
// needed.

pub const inf = std.math.inf;
pub const sqrt = std.math.sqrt;
pub const pow = std.math.pow;
pub const sin = std.math.sin;
pub const cos = std.math.cos;
pub const acos = std.math.acos;
pub const isNan = std.math.isNan;
pub const isInf = std.math.isInf;
pub const pi = std.math.pi;
pub const clamp = std.math.clamp;
pub const log10 = std.math.log10;
pub const degreesToRadians = std.math.degreesToRadians;
pub const radiansToDegrees = std.math.radiansToDegrees;
pub const maxInt = std.math.maxInt;
pub const lerp = std.math.lerp;

/// 2/sqrt(π)
pub const two_sqrtpi = std.math.two_sqrtpi;

/// sqrt(2)
pub const sqrt2 = std.math.sqrt2;

/// 1/sqrt(2)
pub const sqrt1_2 = std.math.sqrt1_2;
