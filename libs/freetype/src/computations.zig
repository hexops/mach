const _c = @import("c.zig");
const intToError = @import("error.zig").intToError;
const Error = @import("error.zig").Error;

const Vector = @import("image.zig").Vector;
const Matrix = @import("types.zig").Matrix;

pub const angel_pi = _c.FT_ANGLE_PI;
pub const angel_2pi = _c.FT_ANGLE_2PI;
pub const angel_pi2 = _c.FT_ANGLE_PI2;
pub const angel_pi4 = _c.FT_ANGLE_PI4;

pub fn mulDiv(a: i32, b: i32, c: i32) i32 {
    return @as(i32, @intCast(_c.FT_MulDiv(a, b, c)));
}

pub fn mulFix(a: i32, b: i32) i32 {
    return @as(i32, @intCast(_c.FT_MulFix(a, b)));
}

pub fn divFix(a: i32, b: i32) i32 {
    return @as(i32, @intCast(_c.FT_DivFix(a, b)));
}

pub fn roundFix(a: i32) i32 {
    return @as(i32, @intCast(_c.FT_RoundFix(a)));
}

pub fn ceilFix(a: i32) i32 {
    return @as(i32, @intCast(_c.FT_CeilFix(a)));
}

pub fn floorFix(a: i32) i32 {
    return @as(i32, @intCast(_c.FT_FloorFix(a)));
}

pub fn vectorTransform(vec: *Vector, matrix: Matrix) void {
    _c.FT_Vector_Transform(vec, &matrix);
}

pub fn matrixMul(a: Matrix, b: *Matrix) void {
    _c.FT_Matrix_Multiply(&a, b);
}

pub fn matrixInvert(m: *Matrix) Error!void {
    try intToError(_c.FT_Matrix_Invert(m));
}

pub fn angleDiff(a: i32, b: i32) i32 {
    return @as(i32, @intCast(_c.FT_Angle_Diff(a, b)));
}

pub fn vectorUnit(vec: *Vector, angle: i32) void {
    _c.FT_Vector_Unit(vec, angle);
}

pub fn vectorRotate(vec: *Vector, angle: i32) void {
    _c.FT_Vector_Rotate(vec, angle);
}

pub fn vectorLength(vec: *Vector) i32 {
    return @as(i32, @intCast(_c.FT_Vector_Length(vec)));
}

pub fn vectorPolarize(vec: *Vector, length: *c_long, angle: *c_long) void {
    _c.FT_Vector_Polarize(vec, length, angle);
}

pub fn vectorFromPolar(vec: *Vector, length: i32, angle: i32) void {
    _c.FT_Vector_From_Polar(vec, length, angle);
}
