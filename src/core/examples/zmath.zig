//! Heavily stripped down zmath version.
//!
//! In your own projects, you should bring your own math library. This file is just for example
//! purposes.
//!

const builtin = @import("builtin");
const std = @import("std");
const math = std.math;
const assert = std.debug.assert;
const expect = std.testing.expect;

pub const Vec = @Vector(4, f32);
pub const Mat = [4]@Vector(4, f32);
pub const Quat = @Vector(4, f32);

pub inline fn abs(v: anytype) @TypeOf(v) {
    return @abs(v);
}

inline fn dot3(v0: Vec, v1: Vec) Vec {
    const dot = v0 * v1;
    return @splat(dot[0] + dot[1] + dot[2]);
}

pub inline fn normalize3(v: Vec) Vec {
    return v * @as(Vec, @splat(1.0)) / @sqrt(dot3(v, v));
}

pub fn scaling(x: f32, y: f32, z: f32) Mat {
    return .{
        .{ x, 0.0, 0.0, 0.0 },
        .{ 0.0, y, 0.0, 0.0 },
        .{ 0.0, 0.0, z, 0.0 },
        .{ 0.0, 0.0, 0.0, 1.0 },
    };
}

pub inline fn cross3(a: Vec, b: Vec) Vec {
    const v1 = Vec{ a[1], a[2], a[0], 1.0 };
    const v2 = Vec{ b[2], b[0], b[1], 1.0 };
    const sub1 = v1 * v2;

    const _v1 = Vec{ a[2], a[0], a[1], 1.0 };
    const _v2 = Vec{ b[1], b[2], b[0], 1.0 };
    const sub2 = _v1 * _v2;

    return sub1 - sub2;
}

pub fn orthographicRh(w: f32, h: f32, near: f32, far: f32) Mat {
    assert(!math.approxEqAbs(f32, w, 0.0, 0.001));
    assert(!math.approxEqAbs(f32, h, 0.0, 0.001));
    assert(!math.approxEqAbs(f32, far, near, 0.001));

    const r = 1 / (near - far);
    return .{
        .{ 2 / w, 0.0, 0.0, 0.0 },
        .{ 0.0, 2 / h, 0.0, 0.0 },
        .{ 0.0, 0.0, r, 0.0 },
        .{ 0.0, 0.0, r * near, 1.0 },
    };
}

//---
// Public APIs used by examples that we should reduce to their minimal counterparts
//---
pub fn lookAtRh(eyepos: Vec, focuspos: Vec, updir: Vec) Mat {
    return lookToLh(eyepos, eyepos - focuspos, updir);
}
pub inline fn storeMat(mem: []f32, m: Mat) void {
    store(mem[0..4], m[0], 0);
    store(mem[4..8], m[1], 0);
    store(mem[8..12], m[2], 0);
    store(mem[12..16], m[3], 0);
}
pub fn quatFromAxisAngle(axis: Vec, angle: f32) Quat {
    assert(!all(axis == splat(F32x4, 0.0), 3));
    assert(!all(isInf(axis), 3));
    const normal = normalize3(axis);
    return quatFromNormAxisAngle(normal, angle);
}
pub fn perspectiveFovRh(fovy: f32, aspect: f32, near: f32, far: f32) Mat {
    const scfov = sincos(0.5 * fovy);

    assert(near > 0.0 and far > 0.0);
    assert(!math.approxEqAbs(f32, scfov[0], 0.0, 0.001));
    assert(!math.approxEqAbs(f32, far, near, 0.001));
    assert(!math.approxEqAbs(f32, aspect, 0.0, 0.01));

    const h = scfov[1] / scfov[0];
    const w = h / aspect;
    const r = far / (near - far);
    return .{
        f32x4(w, 0.0, 0.0, 0.0),
        f32x4(0.0, h, 0.0, 0.0),
        f32x4(0.0, 0.0, r, -1.0),
        f32x4(0.0, 0.0, r * near, 0.0),
    };
}
pub fn qmul(q0: Quat, q1: Quat) Quat {
    var result = swizzle(q1, .w, .w, .w, .w);
    var q1x = swizzle(q1, .x, .x, .x, .x);
    var q1y = swizzle(q1, .y, .y, .y, .y);
    var q1z = swizzle(q1, .z, .z, .z, .z);
    result = result * q0;
    var q0_shuf = swizzle(q0, .w, .z, .y, .x);
    q1x = q1x * q0_shuf;
    q0_shuf = swizzle(q0_shuf, .y, .x, .w, .z);
    result = mulAdd(q1x, f32x4(1.0, -1.0, 1.0, -1.0), result);
    q1y = q1y * q0_shuf;
    q0_shuf = swizzle(q0_shuf, .w, .z, .y, .x);
    q1y = q1y * f32x4(1.0, 1.0, -1.0, -1.0);
    q1z = q1z * q0_shuf;
    q1y = mulAdd(q1z, f32x4(-1.0, 1.0, 1.0, -1.0), q1y);
    return result + q1y;
}
pub fn mul(a: anytype, b: anytype) mulRetType(@TypeOf(a), @TypeOf(b)) {
    const Ta = @TypeOf(a);
    const Tb = @TypeOf(b);
    if (Ta == Mat and Tb == Mat) {
        return mulMat(a, b);
    } else if (Ta == f32 and Tb == Mat) {
        const va = splat(F32x4, a);
        return Mat{ va * b[0], va * b[1], va * b[2], va * b[3] };
    } else if (Ta == Mat and Tb == f32) {
        const vb = splat(F32x4, b);
        return Mat{ a[0] * vb, a[1] * vb, a[2] * vb, a[3] * vb };
    } else if (Ta == Vec and Tb == Mat) {
        return vecMulMat(a, b);
    } else if (Ta == Mat and Tb == Vec) {
        return matMulVec(a, b);
    } else {
        @compileError("zmath.mul() not implemented for types: " ++ @typeName(Ta) ++ ", " ++ @typeName(Tb));
    }
}
pub fn translationV(v: Vec) Mat {
    return translation(v[0], v[1], v[2]);
}
pub fn transpose(m: Mat) Mat {
    const temp1 = @shuffle(f32, m[0], m[1], [4]i32{ 0, 1, ~@as(i32, 0), ~@as(i32, 1) });
    const temp3 = @shuffle(f32, m[0], m[1], [4]i32{ 2, 3, ~@as(i32, 2), ~@as(i32, 3) });
    const temp2 = @shuffle(f32, m[2], m[3], [4]i32{ 0, 1, ~@as(i32, 0), ~@as(i32, 1) });
    const temp4 = @shuffle(f32, m[2], m[3], [4]i32{ 2, 3, ~@as(i32, 2), ~@as(i32, 3) });
    return .{
        @shuffle(f32, temp1, temp2, [4]i32{ 0, 2, ~@as(i32, 0), ~@as(i32, 2) }),
        @shuffle(f32, temp1, temp2, [4]i32{ 1, 3, ~@as(i32, 1), ~@as(i32, 3) }),
        @shuffle(f32, temp3, temp4, [4]i32{ 0, 2, ~@as(i32, 0), ~@as(i32, 2) }),
        @shuffle(f32, temp3, temp4, [4]i32{ 1, 3, ~@as(i32, 1), ~@as(i32, 3) }),
    };
}
pub fn rotationX(angle: f32) Mat {
    const sc = sincos(angle);
    return .{
        f32x4(1.0, 0.0, 0.0, 0.0),
        f32x4(0.0, sc[1], sc[0], 0.0),
        f32x4(0.0, -sc[0], sc[1], 0.0),
        f32x4(0.0, 0.0, 0.0, 1.0),
    };
}
pub fn rotationY(angle: f32) Mat {
    const sc = sincos(angle);
    return .{
        f32x4(sc[1], 0.0, -sc[0], 0.0),
        f32x4(0.0, 1.0, 0.0, 0.0),
        f32x4(sc[0], 0.0, sc[1], 0.0),
        f32x4(0.0, 0.0, 0.0, 1.0),
    };
}
pub fn rotationZ(angle: f32) Mat {
    const sc = sincos(angle);
    return .{
        f32x4(sc[1], sc[0], 0.0, 0.0),
        f32x4(-sc[0], sc[1], 0.0, 0.0),
        f32x4(0.0, 0.0, 1.0, 0.0),
        f32x4(0.0, 0.0, 0.0, 1.0),
    };
}
pub fn cos(v: anytype) @TypeOf(v) {
    const T = @TypeOf(v);
    return switch (T) {
        f32 => cos32(v),
        F32x4 => cos32xN(v),
        else => @compileError("zmath.cos() not implemented for " ++ @typeName(T)),
    };
}
pub fn sin(v: anytype) @TypeOf(v) {
    const T = @TypeOf(v);
    return switch (T) {
        f32 => sin32(v),
        F32x4 => sin32xN(v),
        else => @compileError("zmath.sin() not implemented for " ++ @typeName(T)),
    };
}
// Produces Z values in [-1.0, 1.0] range (OpenGL defaults)
pub fn perspectiveFovRhGl(fovy: f32, aspect: f32, near: f32, far: f32) Mat {
    const scfov = sincos(0.5 * fovy);

    assert(near > 0.0 and far > 0.0);
    assert(!math.approxEqAbs(f32, scfov[0], 0.0, 0.001));
    assert(!math.approxEqAbs(f32, far, near, 0.001));
    assert(!math.approxEqAbs(f32, aspect, 0.0, 0.01));

    const h = scfov[1] / scfov[0];
    const w = h / aspect;
    const r = near - far;
    return .{
        f32x4(w, 0.0, 0.0, 0.0),
        f32x4(0.0, h, 0.0, 0.0),
        f32x4(0.0, 0.0, (near + far) / r, -1.0),
        f32x4(0.0, 0.0, 2.0 * near * far / r, 0.0),
    };
}
pub inline fn clamp(v: anytype, vmin: anytype, vmax: anytype) @TypeOf(v, vmin, vmax) {
    var result = @max(vmin, v);
    result = min(vmax, result);
    return result;
}
pub fn inverse(a: anytype) @TypeOf(a) {
    const T = @TypeOf(a);
    return switch (T) {
        Mat => inverseMat(a),
        else => @compileError("zmath.inverse() not implemented for " ++ @typeName(T)),
    };
}
pub fn identity() Mat {
    const static = struct {
        const identity = Mat{
            f32x4(1.0, 0.0, 0.0, 0.0),
            f32x4(0.0, 1.0, 0.0, 0.0),
            f32x4(0.0, 0.0, 1.0, 0.0),
            f32x4(0.0, 0.0, 0.0, 1.0),
        };
    };
    return static.identity;
}
pub fn translation(x: f32, y: f32, z: f32) Mat {
    return .{
        f32x4(1.0, 0.0, 0.0, 0.0),
        f32x4(0.0, 1.0, 0.0, 0.0),
        f32x4(0.0, 0.0, 1.0, 0.0),
        f32x4(x, y, z, 1.0),
    };
}

//---
// Internal APIs
//---

inline fn f32x4(e0: f32, e1: f32, e2: f32, e3: f32) F32x4 {
    return .{ e0, e1, e2, e3 };
}

const F32x4 = @Vector(4, f32);

inline fn veclen(comptime T: type) comptime_int {
    return @typeInfo(T).Vector.len;
}

inline fn splat(comptime T: type, value: f32) T {
    return @splat(value);
}
inline fn splatInt(comptime T: type, value: u32) T {
    return @splat(@bitCast(value));
}

fn load(mem: []const f32, comptime T: type, comptime len: u32) T {
    var v = splat(T, 0.0);
    const loop_len = if (len == 0) veclen(T) else len;
    comptime var i: u32 = 0;
    inline while (i < loop_len) : (i += 1) {
        v[i] = mem[i];
    }
    return v;
}

fn store(mem: []f32, v: anytype, comptime len: u32) void {
    const T = @TypeOf(v);
    const loop_len = if (len == 0) veclen(T) else len;
    comptime var i: u32 = 0;
    inline while (i < loop_len) : (i += 1) {
        mem[i] = v[i];
    }
}

inline fn loadArr2(arr: [2]f32) F32x4 {
    return f32x4(arr[0], arr[1], 0.0, 0.0);
}
inline fn loadArr2zw(arr: [2]f32, z: f32, w: f32) F32x4 {
    return f32x4(arr[0], arr[1], z, w);
}
inline fn loadArr3(arr: [3]f32) F32x4 {
    return f32x4(arr[0], arr[1], arr[2], 0.0);
}
inline fn loadArr3w(arr: [3]f32, w: f32) F32x4 {
    return f32x4(arr[0], arr[1], arr[2], w);
}
inline fn loadArr4(arr: [4]f32) F32x4 {
    return f32x4(arr[0], arr[1], arr[2], arr[3]);
}

inline fn storeArr2(arr: *[2]f32, v: F32x4) void {
    arr.* = .{ v[0], v[1] };
}
inline fn storeArr3(arr: *[3]f32, v: F32x4) void {
    arr.* = .{ v[0], v[1], v[2] };
}

inline fn arr3Ptr(ptr: anytype) *const [3]f32 {
    comptime assert(@typeInfo(@TypeOf(ptr)) == .Pointer);
    const T = std.meta.Child(@TypeOf(ptr));
    comptime assert(T == F32x4);
    return @as(*const [3]f32, @ptrCast(ptr));
}

inline fn arrNPtr(ptr: anytype) [*]const f32 {
    comptime assert(@typeInfo(@TypeOf(ptr)) == .Pointer);
    const T = std.meta.Child(@TypeOf(ptr));
    comptime assert(T == Mat or T == F32x4);
    return @as([*]const f32, @ptrCast(ptr));
}

inline fn vecToArr2(v: Vec) [2]f32 {
    return .{ v[0], v[1] };
}
inline fn vecToArr3(v: Vec) [3]f32 {
    return .{ v[0], v[1], v[2] };
}
inline fn vecToArr4(v: Vec) [4]f32 {
    return .{ v[0], v[1], v[2], v[3] };
}

fn all(vb: anytype, comptime len: u32) bool {
    const T = @TypeOf(vb);
    if (len > veclen(T)) {
        @compileError("zmath.all(): 'len' is greater than vector len of type " ++ @typeName(T));
    }
    const loop_len = if (len == 0) veclen(T) else len;
    const ab: [veclen(T)]bool = vb;
    comptime var i: u32 = 0;
    var result = true;
    inline while (i < loop_len) : (i += 1) {
        result = result and ab[i];
    }
    return result;
}

fn any(vb: anytype, comptime len: u32) bool {
    const T = @TypeOf(vb);
    if (len > veclen(T)) {
        @compileError("zmath.any(): 'len' is greater than vector len of type " ++ @typeName(T));
    }
    const loop_len = if (len == 0) veclen(T) else len;
    const ab: [veclen(T)]bool = vb;
    comptime var i: u32 = 0;
    var result = false;
    inline while (i < loop_len) : (i += 1) {
        result = result or ab[i];
    }
    return result;
}

inline fn isNearEqual(
    v0: anytype,
    v1: anytype,
    epsilon: anytype,
) @Vector(veclen(@TypeOf(v0)), bool) {
    const T = @TypeOf(v0, v1, epsilon);
    const delta = v0 - v1;
    const temp = maxFast(delta, splat(T, 0.0) - delta);
    return temp <= epsilon;
}

inline fn isNan(
    v: anytype,
) @Vector(veclen(@TypeOf(v)), bool) {
    return v != v;
}

inline fn isInf(
    v: anytype,
) @Vector(veclen(@TypeOf(v)), bool) {
    const T = @TypeOf(v);
    return abs(v) == splat(T, math.inf(f32));
}

inline fn isInBounds(
    v: anytype,
    bounds: anytype,
) @Vector(veclen(@TypeOf(v)), bool) {
    const T = @TypeOf(v, bounds);
    const Tu = @Vector(veclen(T), u1);
    const Tr = @Vector(veclen(T), bool);

    // 2 x cmpleps, xorps, load, andps
    const b0 = v <= bounds;
    const b1 = (bounds * splat(T, -1.0)) <= v;
    const b0u = @as(Tu, @bitCast(b0));
    const b1u = @as(Tu, @bitCast(b1));
    return @as(Tr, @bitCast(b0u & b1u));
}

inline fn andInt(v0: anytype, v1: anytype) @TypeOf(v0, v1) {
    const T = @TypeOf(v0, v1);
    const Tu = @Vector(veclen(T), u32);
    const v0u = @as(Tu, @bitCast(v0));
    const v1u = @as(Tu, @bitCast(v1));
    return @as(T, @bitCast(v0u & v1u)); // andps
}

inline fn andNotInt(v0: anytype, v1: anytype) @TypeOf(v0, v1) {
    const T = @TypeOf(v0, v1);
    const Tu = @Vector(veclen(T), u32);
    const v0u = @as(Tu, @bitCast(v0));
    const v1u = @as(Tu, @bitCast(v1));
    return @as(T, @bitCast(~v0u & v1u)); // andnps
}

inline fn orInt(v0: anytype, v1: anytype) @TypeOf(v0, v1) {
    const T = @TypeOf(v0, v1);
    const Tu = @Vector(veclen(T), u32);
    const v0u = @as(Tu, @bitCast(v0));
    const v1u = @as(Tu, @bitCast(v1));
    return @as(T, @bitCast(v0u | v1u)); // orps
}

inline fn norInt(v0: anytype, v1: anytype) @TypeOf(v0, v1) {
    const T = @TypeOf(v0, v1);
    const Tu = @Vector(veclen(T), u32);
    const v0u = @as(Tu, @bitCast(v0));
    const v1u = @as(Tu, @bitCast(v1));
    return @as(T, @bitCast(~(v0u | v1u))); // por, pcmpeqd, pxor
}

inline fn xorInt(v0: anytype, v1: anytype) @TypeOf(v0, v1) {
    const T = @TypeOf(v0, v1);
    const Tu = @Vector(veclen(T), u32);
    const v0u = @as(Tu, @bitCast(v0));
    const v1u = @as(Tu, @bitCast(v1));
    return @as(T, @bitCast(v0u ^ v1u)); // xorps
}

inline fn minFast(v0: anytype, v1: anytype) @TypeOf(v0, v1) {
    return select(v0 < v1, v0, v1); // minps
}

inline fn maxFast(v0: anytype, v1: anytype) @TypeOf(v0, v1) {
    return select(v0 > v1, v0, v1); // maxps
}

inline fn min(v0: anytype, v1: anytype) @TypeOf(v0, v1) {
    // This will handle inf & nan
    return @min(v0, v1); // minps, cmpunordps, andps, andnps, orps
}

fn round(v: anytype) @TypeOf(v) {
    const T = @TypeOf(v);
    const sign = andInt(v, splatNegativeZero(T));
    const magic = orInt(splatNoFraction(T), sign);
    var r1 = v + magic;
    r1 = r1 - magic;
    const r2 = abs(v);
    const mask = r2 <= splatNoFraction(T);
    return select(mask, r1, v);
}

fn trunc(v: anytype) @TypeOf(v) {
    const T = @TypeOf(v);
    const mask = abs(v) < splatNoFraction(T);
    const result = floatToIntAndBack(v);
    return select(mask, result, v);
}

fn floor(v: anytype) @TypeOf(v) {
    const T = @TypeOf(v);
    const mask = abs(v) < splatNoFraction(T);
    var result = floatToIntAndBack(v);
    const larger_mask = result > v;
    const larger = select(larger_mask, splat(T, -1.0), splat(T, 0.0));
    result = result + larger;
    return select(mask, result, v);
}

fn ceil(v: anytype) @TypeOf(v) {
    const T = @TypeOf(v);
    const mask = abs(v) < splatNoFraction(T);
    var result = floatToIntAndBack(v);
    const smaller_mask = result < v;
    const smaller = select(smaller_mask, splat(T, -1.0), splat(T, 0.0));
    result = result - smaller;
    return select(mask, result, v);
}

inline fn clampFast(v: anytype, vmin: anytype, vmax: anytype) @TypeOf(v, vmin, vmax) {
    var result = maxFast(vmin, v);
    result = minFast(vmax, result);
    return result;
}

inline fn saturate(v: anytype) @TypeOf(v) {
    const T = @TypeOf(v);
    var result = @max(v, splat(T, 0.0));
    result = min(result, splat(T, 1.0));
    return result;
}

inline fn saturateFast(v: anytype) @TypeOf(v) {
    const T = @TypeOf(v);
    var result = maxFast(v, splat(T, 0.0));
    result = minFast(result, splat(T, 1.0));
    return result;
}

inline fn select(mask: anytype, v0: anytype, v1: anytype) @TypeOf(v0, v1) {
    return @select(f32, mask, v0, v1);
}

inline fn lerp(v0: anytype, v1: anytype, t: f32) @TypeOf(v0, v1) {
    const T = @TypeOf(v0, v1);
    return v0 + (v1 - v0) * splat(T, t); // subps, shufps, addps, mulps
}

inline fn lerpV(v0: anytype, v1: anytype, t: anytype) @TypeOf(v0, v1, t) {
    return v0 + (v1 - v0) * t; // subps, addps, mulps
}

inline fn lerpInverse(v0: anytype, v1: anytype, t: anytype) @TypeOf(v0, v1) {
    const T = @TypeOf(v0, v1);
    return (splat(T, t) - v0) / (v1 - v0);
}

inline fn lerpInverseV(v0: anytype, v1: anytype, t: anytype) @TypeOf(v0, v1, t) {
    return (t - v0) / (v1 - v0);
}

// Frame rate independent lerp (or "damp"), for approaching things over time.
// Reference: https://www.gamedeveloper.com/programming/improved-lerp-smoothing-
inline fn lerpOverTime(v0: anytype, v1: anytype, rate: anytype, dt: anytype) @TypeOf(v0, v1) {
    const t = std.math.exp2(-rate * dt);
    return lerp(v0, v1, t);
}

inline fn lerpVOverTime(v0: anytype, v1: anytype, rate: anytype, dt: anytype) @TypeOf(v0, v1, rate, dt) {
    const t = std.math.exp2(-rate * dt);
    return lerpV(v0, v1, t);
}

/// To transform a vector of values from one range to another.
inline fn mapLinear(v: anytype, min1: anytype, max1: anytype, min2: anytype, max2: anytype) @TypeOf(v) {
    const T = @TypeOf(v);
    const min1V = splat(T, min1);
    const max1V = splat(T, max1);
    const min2V = splat(T, min2);
    const max2V = splat(T, max2);
    const dV = max1V - min1V;
    return min2V + (v - min1V) * (max2V - min2V) / dV;
}

inline fn mapLinearV(v: anytype, min1: anytype, max1: anytype, min2: anytype, max2: anytype) @TypeOf(v, min1, max1, min2, max2) {
    const d = max1 - min1;
    return min2 + (v - min1) * (max2 - min2) / d;
}

const F32x4Component = enum { x, y, z, w };

inline fn swizzle(
    v: F32x4,
    comptime x: F32x4Component,
    comptime y: F32x4Component,
    comptime z: F32x4Component,
    comptime w: F32x4Component,
) F32x4 {
    return @shuffle(f32, v, undefined, [4]i32{ @intFromEnum(x), @intFromEnum(y), @intFromEnum(z), @intFromEnum(w) });
}

inline fn mod(v0: anytype, v1: anytype) @TypeOf(v0, v1) {
    // vdivps, vroundps, vmulps, vsubps
    return v0 - v1 * trunc(v0 / v1);
}

fn modAngle(v: anytype) @TypeOf(v) {
    const T = @TypeOf(v);
    return switch (T) {
        f32 => modAngle32(v),
        F32x4 => modAngle32xN(v),
        else => @compileError("zmath.modAngle() not implemented for " ++ @typeName(T)),
    };
}

inline fn modAngle32xN(v: anytype) @TypeOf(v) {
    const T = @TypeOf(v);
    return v - splat(T, math.tau) * round(v * splat(T, 1.0 / math.tau)); // 2 x vmulps, 2 x load, vroundps, vaddps
}

inline fn mulAdd(v0: anytype, v1: anytype, v2: anytype) @TypeOf(v0, v1, v2) {
    return v0 * v1 + v2; // Compiler will generate mul, add sequence (no fma even if the target supports it).
}

fn sin32xN(v: anytype) @TypeOf(v) {
    // 11-degree minimax approximation
    const T = @TypeOf(v);

    var x = modAngle(v);
    const sign = andInt(x, splatNegativeZero(T));
    const c = orInt(sign, splat(T, math.pi));
    const absx = andNotInt(sign, x);
    const rflx = c - x;
    const comp = absx <= splat(T, 0.5 * math.pi);
    x = select(comp, x, rflx);
    const x2 = x * x;

    var result = mulAdd(splat(T, -2.3889859e-08), x2, splat(T, 2.7525562e-06));
    result = mulAdd(result, x2, splat(T, -0.00019840874));
    result = mulAdd(result, x2, splat(T, 0.0083333310));
    result = mulAdd(result, x2, splat(T, -0.16666667));
    result = mulAdd(result, x2, splat(T, 1.0));
    return x * result;
}

fn cos32xN(v: anytype) @TypeOf(v) {
    // 10-degree minimax approximation
    const T = @TypeOf(v);

    var x = modAngle(v);
    var sign = andInt(x, splatNegativeZero(T));
    const c = orInt(sign, splat(T, math.pi));
    const absx = andNotInt(sign, x);
    const rflx = c - x;
    const comp = absx <= splat(T, 0.5 * math.pi);
    x = select(comp, x, rflx);
    sign = select(comp, splat(T, 1.0), splat(T, -1.0));
    const x2 = x * x;

    var result = mulAdd(splat(T, -2.6051615e-07), x2, splat(T, 2.4760495e-05));
    result = mulAdd(result, x2, splat(T, -0.0013888378));
    result = mulAdd(result, x2, splat(T, 0.041666638));
    result = mulAdd(result, x2, splat(T, -0.5));
    result = mulAdd(result, x2, splat(T, 1.0));
    return sign * result;
}

fn sincos(v: anytype) [2]@TypeOf(v) {
    const T = @TypeOf(v);
    return switch (T) {
        f32 => sincos32(v),
        else => @compileError("zmath.sincos() not implemented for " ++ @typeName(T)),
    };
}

inline fn dot2(v0: Vec, v1: Vec) F32x4 {
    var xmm0 = v0 * v1; // | x0*x1 | y0*y1 | -- | -- |
    const xmm1 = swizzle(xmm0, .y, .x, .x, .x); // | y0*y1 | -- | -- | -- |
    xmm0 = f32x4(xmm0[0] + xmm1[0], xmm0[1], xmm0[2], xmm0[3]); // | x0*x1 + y0*y1 | -- | -- | -- |
    return swizzle(xmm0, .x, .x, .x, .x);
}

inline fn dot4(v0: Vec, v1: Vec) F32x4 {
    var xmm0 = v0 * v1; // | x0*x1 | y0*y1 | z0*z1 | w0*w1 |
    var xmm1 = swizzle(xmm0, .y, .x, .w, .x); // | y0*y1 | -- | w0*w1 | -- |
    xmm1 = xmm0 + xmm1; // | x0*x1 + y0*y1 | -- | z0*z1 + w0*w1 | -- |
    xmm0 = swizzle(xmm1, .z, .x, .x, .x); // | z0*z1 + w0*w1 | -- | -- | -- |
    xmm0 = f32x4(xmm0[0] + xmm1[0], xmm0[1], xmm0[2], xmm0[2]); // addss
    return swizzle(xmm0, .x, .x, .x, .x);
}

inline fn lengthSq2(v: Vec) F32x4 {
    return dot2(v, v);
}
inline fn lengthSq3(v: Vec) F32x4 {
    return dot3(v, v);
}

inline fn length2(v: Vec) F32x4 {
    return @sqrt(dot2(v, v));
}
inline fn length3(v: Vec) F32x4 {
    return @sqrt(dot3(v, v));
}
inline fn length4(v: Vec) F32x4 {
    return @sqrt(dot4(v, v));
}

inline fn normalize2(v: Vec) Vec {
    return v * splat(F32x4, 1.0) / @sqrt(dot2(v, v));
}
inline fn normalize4(v: Vec) Vec {
    return v * splat(F32x4, 1.0) / @sqrt(dot4(v, v));
}

fn vecMulMat(v: Vec, m: Mat) Vec {
    const vx = @shuffle(f32, v, undefined, [4]i32{ 0, 0, 0, 0 });
    const vy = @shuffle(f32, v, undefined, [4]i32{ 1, 1, 1, 1 });
    const vz = @shuffle(f32, v, undefined, [4]i32{ 2, 2, 2, 2 });
    const vw = @shuffle(f32, v, undefined, [4]i32{ 3, 3, 3, 3 });
    return vx * m[0] + vy * m[1] + vz * m[2] + vw * m[3];
}
fn matMulVec(m: Mat, v: Vec) Vec {
    return .{ dot4(m[0], v)[0], dot4(m[1], v)[0], dot4(m[2], v)[0], dot4(m[3], v)[0] };
}

fn matFromArr(arr: [16]f32) Mat {
    return Mat{
        f32x4(arr[0], arr[1], arr[2], arr[3]),
        f32x4(arr[4], arr[5], arr[6], arr[7]),
        f32x4(arr[8], arr[9], arr[10], arr[11]),
        f32x4(arr[12], arr[13], arr[14], arr[15]),
    };
}

fn mulRetType(comptime Ta: type, comptime Tb: type) type {
    if (Ta == Mat and Tb == Mat) {
        return Mat;
    } else if ((Ta == f32 and Tb == Mat) or (Ta == Mat and Tb == f32)) {
        return Mat;
    } else if ((Ta == Vec and Tb == Mat) or (Ta == Mat and Tb == Vec)) {
        return Vec;
    }
    @compileError("zmath.mul() not implemented for types: " ++ @typeName(Ta) ++ @typeName(Tb));
}

fn mulMat(m0: Mat, m1: Mat) Mat {
    var result: Mat = undefined;
    comptime var row: u32 = 0;
    inline while (row < 4) : (row += 1) {
        const vx = swizzle(m0[row], .x, .x, .x, .x);
        const vy = swizzle(m0[row], .y, .y, .y, .y);
        const vz = swizzle(m0[row], .z, .z, .z, .z);
        const vw = swizzle(m0[row], .w, .w, .w, .w);
        result[row] = mulAdd(vx, m1[0], vz * m1[2]) + mulAdd(vy, m1[1], vw * m1[3]);
    }
    return result;
}
fn lookToLh(eyepos: Vec, eyedir: Vec, updir: Vec) Mat {
    const az = normalize3(eyedir);
    const ax = normalize3(cross3(updir, az));
    const ay = normalize3(cross3(az, ax));
    return transpose(.{
        f32x4(ax[0], ax[1], ax[2], -dot3(ax, eyepos)[0]),
        f32x4(ay[0], ay[1], ay[2], -dot3(ay, eyepos)[0]),
        f32x4(az[0], az[1], az[2], -dot3(az, eyepos)[0]),
        f32x4(0.0, 0.0, 0.0, 1.0),
    });
}

fn inverseMat(m: Mat) Mat {
    return inverseDet(m, null);
}

fn inverseDet(m: Mat, out_det: ?*F32x4) Mat {
    const mt = transpose(m);
    var v0: [4]F32x4 = undefined;
    var v1: [4]F32x4 = undefined;

    v0[0] = swizzle(mt[2], .x, .x, .y, .y);
    v1[0] = swizzle(mt[3], .z, .w, .z, .w);
    v0[1] = swizzle(mt[0], .x, .x, .y, .y);
    v1[1] = swizzle(mt[1], .z, .w, .z, .w);
    v0[2] = @shuffle(f32, mt[2], mt[0], [4]i32{ 0, 2, ~@as(i32, 0), ~@as(i32, 2) });
    v1[2] = @shuffle(f32, mt[3], mt[1], [4]i32{ 1, 3, ~@as(i32, 1), ~@as(i32, 3) });

    var d0 = v0[0] * v1[0];
    var d1 = v0[1] * v1[1];
    var d2 = v0[2] * v1[2];

    v0[0] = swizzle(mt[2], .z, .w, .z, .w);
    v1[0] = swizzle(mt[3], .x, .x, .y, .y);
    v0[1] = swizzle(mt[0], .z, .w, .z, .w);
    v1[1] = swizzle(mt[1], .x, .x, .y, .y);
    v0[2] = @shuffle(f32, mt[2], mt[0], [4]i32{ 1, 3, ~@as(i32, 1), ~@as(i32, 3) });
    v1[2] = @shuffle(f32, mt[3], mt[1], [4]i32{ 0, 2, ~@as(i32, 0), ~@as(i32, 2) });

    d0 = mulAdd(-v0[0], v1[0], d0);
    d1 = mulAdd(-v0[1], v1[1], d1);
    d2 = mulAdd(-v0[2], v1[2], d2);

    v0[0] = swizzle(mt[1], .y, .z, .x, .y);
    v1[0] = @shuffle(f32, d0, d2, [4]i32{ ~@as(i32, 1), 1, 3, 0 });
    v0[1] = swizzle(mt[0], .z, .x, .y, .x);
    v1[1] = @shuffle(f32, d0, d2, [4]i32{ 3, ~@as(i32, 1), 1, 2 });
    v0[2] = swizzle(mt[3], .y, .z, .x, .y);
    v1[2] = @shuffle(f32, d1, d2, [4]i32{ ~@as(i32, 3), 1, 3, 0 });
    v0[3] = swizzle(mt[2], .z, .x, .y, .x);
    v1[3] = @shuffle(f32, d1, d2, [4]i32{ 3, ~@as(i32, 3), 1, 2 });

    var c0 = v0[0] * v1[0];
    var c2 = v0[1] * v1[1];
    var c4 = v0[2] * v1[2];
    var c6 = v0[3] * v1[3];

    v0[0] = swizzle(mt[1], .z, .w, .y, .z);
    v1[0] = @shuffle(f32, d0, d2, [4]i32{ 3, 0, 1, ~@as(i32, 0) });
    v0[1] = swizzle(mt[0], .w, .z, .w, .y);
    v1[1] = @shuffle(f32, d0, d2, [4]i32{ 2, 1, ~@as(i32, 0), 0 });
    v0[2] = swizzle(mt[3], .z, .w, .y, .z);
    v1[2] = @shuffle(f32, d1, d2, [4]i32{ 3, 0, 1, ~@as(i32, 2) });
    v0[3] = swizzle(mt[2], .w, .z, .w, .y);
    v1[3] = @shuffle(f32, d1, d2, [4]i32{ 2, 1, ~@as(i32, 2), 0 });

    c0 = mulAdd(-v0[0], v1[0], c0);
    c2 = mulAdd(-v0[1], v1[1], c2);
    c4 = mulAdd(-v0[2], v1[2], c4);
    c6 = mulAdd(-v0[3], v1[3], c6);

    v0[0] = swizzle(mt[1], .w, .x, .w, .x);
    v1[0] = @shuffle(f32, d0, d2, [4]i32{ 2, ~@as(i32, 1), ~@as(i32, 0), 2 });
    v0[1] = swizzle(mt[0], .y, .w, .x, .z);
    v1[1] = @shuffle(f32, d0, d2, [4]i32{ ~@as(i32, 1), 0, 3, ~@as(i32, 0) });
    v0[2] = swizzle(mt[3], .w, .x, .w, .x);
    v1[2] = @shuffle(f32, d1, d2, [4]i32{ 2, ~@as(i32, 3), ~@as(i32, 2), 2 });
    v0[3] = swizzle(mt[2], .y, .w, .x, .z);
    v1[3] = @shuffle(f32, d1, d2, [4]i32{ ~@as(i32, 3), 0, 3, ~@as(i32, 2) });

    const c1 = mulAdd(-v0[0], v1[0], c0);
    const c3 = mulAdd(v0[1], v1[1], c2);
    const c5 = mulAdd(-v0[2], v1[2], c4);
    const c7 = mulAdd(v0[3], v1[3], c6);

    c0 = mulAdd(v0[0], v1[0], c0);
    c2 = mulAdd(-v0[1], v1[1], c2);
    c4 = mulAdd(v0[2], v1[2], c4);
    c6 = mulAdd(-v0[3], v1[3], c6);

    var mr = Mat{
        f32x4(c0[0], c1[1], c0[2], c1[3]),
        f32x4(c2[0], c3[1], c2[2], c3[3]),
        f32x4(c4[0], c5[1], c4[2], c5[3]),
        f32x4(c6[0], c7[1], c6[2], c7[3]),
    };

    const det = dot4(mr[0], mt[0]);
    if (out_det != null) {
        out_det.?.* = det;
    }

    if (math.approxEqAbs(f32, det[0], 0.0, math.floatEps(f32))) {
        return .{
            f32x4(0.0, 0.0, 0.0, 0.0),
            f32x4(0.0, 0.0, 0.0, 0.0),
            f32x4(0.0, 0.0, 0.0, 0.0),
            f32x4(0.0, 0.0, 0.0, 0.0),
        };
    }

    const scale = splat(F32x4, 1.0) / det;
    mr[0] *= scale;
    mr[1] *= scale;
    mr[2] *= scale;
    mr[3] *= scale;
    return mr;
}

fn quatFromNormAxisAngle(axis: Vec, angle: f32) Quat {
    const n = f32x4(axis[0], axis[1], axis[2], 1.0);
    const sc = sincos(0.5 * angle);
    return n * f32x4(sc[0], sc[0], sc[0], sc[1]);
}

fn sin32(v: f32) f32 {
    var y = v - math.tau * @round(v * 1.0 / math.tau);

    if (y > 0.5 * math.pi) {
        y = math.pi - y;
    } else if (y < -math.pi * 0.5) {
        y = -math.pi - y;
    }
    const y2 = y * y;

    // 11-degree minimax approximation
    var sinv = mulAdd(@as(f32, -2.3889859e-08), y2, 2.7525562e-06);
    sinv = mulAdd(sinv, y2, -0.00019840874);
    sinv = mulAdd(sinv, y2, 0.0083333310);
    sinv = mulAdd(sinv, y2, -0.16666667);
    return y * mulAdd(sinv, y2, 1.0);
}
fn cos32(v: f32) f32 {
    var y = v - math.tau * @round(v * 1.0 / math.tau);

    const sign = blk: {
        if (y > 0.5 * math.pi) {
            y = math.pi - y;
            break :blk @as(f32, -1.0);
        } else if (y < -math.pi * 0.5) {
            y = -math.pi - y;
            break :blk @as(f32, -1.0);
        } else {
            break :blk @as(f32, 1.0);
        }
    };
    const y2 = y * y;

    // 10-degree minimax approximation
    var cosv = mulAdd(@as(f32, -2.6051615e-07), y2, 2.4760495e-05);
    cosv = mulAdd(cosv, y2, -0.0013888378);
    cosv = mulAdd(cosv, y2, 0.041666638);
    cosv = mulAdd(cosv, y2, -0.5);
    return sign * mulAdd(cosv, y2, 1.0);
}
fn sincos32(v: f32) [2]f32 {
    var y = v - math.tau * @round(v * 1.0 / math.tau);

    const sign = blk: {
        if (y > 0.5 * math.pi) {
            y = math.pi - y;
            break :blk @as(f32, -1.0);
        } else if (y < -math.pi * 0.5) {
            y = -math.pi - y;
            break :blk @as(f32, -1.0);
        } else {
            break :blk @as(f32, 1.0);
        }
    };
    const y2 = y * y;

    // 11-degree minimax approximation
    var sinv = mulAdd(@as(f32, -2.3889859e-08), y2, 2.7525562e-06);
    sinv = mulAdd(sinv, y2, -0.00019840874);
    sinv = mulAdd(sinv, y2, 0.0083333310);
    sinv = mulAdd(sinv, y2, -0.16666667);
    sinv = y * mulAdd(sinv, y2, 1.0);

    // 10-degree minimax approximation
    var cosv = mulAdd(@as(f32, -2.6051615e-07), y2, 2.4760495e-05);
    cosv = mulAdd(cosv, y2, -0.0013888378);
    cosv = mulAdd(cosv, y2, 0.041666638);
    cosv = mulAdd(cosv, y2, -0.5);
    cosv = sign * mulAdd(cosv, y2, 1.0);

    return .{ sinv, cosv };
}

fn modAngle32(in_angle: f32) f32 {
    const angle = in_angle + math.pi;
    var temp: f32 = @abs(angle);
    temp = temp - (2.0 * math.pi * @as(f32, @floatFromInt(@as(i32, @intFromFloat(temp / math.pi)))));
    temp = temp - math.pi;
    if (angle < 0.0) {
        temp = -temp;
    }
    return temp;
}

const f32x4_sign_mask1: F32x4 = F32x4{ @as(f32, @bitCast(@as(u32, 0x8000_0000))), 0, 0, 0 };
const f32x4_mask2: F32x4 = F32x4{
    @as(f32, @bitCast(@as(u32, 0xffff_ffff))),
    @as(f32, @bitCast(@as(u32, 0xffff_ffff))),
    0,
    0,
};
const f32x4_mask3: F32x4 = F32x4{
    @as(f32, @bitCast(@as(u32, 0xffff_ffff))),
    @as(f32, @bitCast(@as(u32, 0xffff_ffff))),
    @as(f32, @bitCast(@as(u32, 0xffff_ffff))),
    0,
};

inline fn splatNegativeZero(comptime T: type) T {
    return @splat(@as(f32, @bitCast(@as(u32, 0x8000_0000))));
}
inline fn splatNoFraction(comptime T: type) T {
    return @splat(@as(f32, 8_388_608.0));
}

fn floatToIntAndBack(v: anytype) @TypeOf(v) {
    // This routine won't handle nan, inf and numbers greater than 8_388_608.0 (will generate undefined values).
    @setRuntimeSafety(false);

    const T = @TypeOf(v);
    const len = veclen(T);

    var vi32: [len]i32 = undefined;
    comptime var i: u32 = 0;
    // vcvttps2dq
    inline while (i < len) : (i += 1) {
        vi32[i] = @as(i32, @intFromFloat(v[i]));
    }

    var vf32: [len]f32 = undefined;
    i = 0;
    // vcvtdq2ps
    inline while (i < len) : (i += 1) {
        vf32[i] = @as(f32, @floatFromInt(vi32[i]));
    }

    return vf32;
}

fn approxEqAbs(v0: anytype, v1: anytype, eps: f32) bool {
    const T = @TypeOf(v0, v1);
    comptime var i: comptime_int = 0;
    inline while (i < veclen(T)) : (i += 1) {
        if (!math.approxEqAbs(f32, v0[i], v1[i], eps)) {
            return false;
        }
    }
    return true;
}
