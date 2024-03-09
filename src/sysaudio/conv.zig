const std = @import("std");
const expectEqual = std.testing.expectEqual;
const shl = std.math.shl;
const shr = std.math.shr;
const maxInt = std.math.maxInt;

pub fn unsignedToSigned(
    comptime SrcType: type,
    src: []const SrcType,
    comptime DestType: type,
    dst: []DestType,
) void {
    for (src, dst) |*src_sample, *dst_sample| {
        const half = (maxInt(SrcType) + 1) / 2;
        const trunc = @bitSizeOf(DestType) - @bitSizeOf(SrcType);
        dst_sample.* = shl(DestType, @intCast(src_sample.* -% half), trunc);
    }
}

test unsignedToSigned {
    var u8_to_i16: [1]i16 = undefined;
    var u8_to_i24: [1]i24 = undefined;
    var u8_to_i32: [1]i32 = undefined;

    unsignedToSigned(u8, &.{5}, i16, &u8_to_i16);
    unsignedToSigned(u8, &.{5}, i24, &u8_to_i24);
    unsignedToSigned(u8, &.{5}, i32, &u8_to_i32);

    try expectEqual(@as(i16, -31488), u8_to_i16[0]);
    try expectEqual(@as(i24, -8060928), u8_to_i24[0]);
    try expectEqual(@as(i32, -2063597568), u8_to_i32[0]);
}

pub fn unsignedToFloat(
    comptime SrcType: type,
    src: []const SrcType,
    comptime DestType: type,
    dst: []DestType,
) void {
    for (src, dst) |*src_sample, *dst_sample| {
        const half = (maxInt(SrcType) + 1) / 2;
        dst_sample.* = (@as(DestType, @floatFromInt(src_sample.*)) - half) * 1.0 / half;
    }
}

test unsignedToFloat {
    var u8_to_f32: [1]f32 = undefined;
    unsignedToFloat(u8, &.{5}, f32, &u8_to_f32);
    try expectEqual(@as(f32, -0.9609375), u8_to_f32[0]);
}

pub fn signedToUnsigned(
    comptime SrcType: type,
    src: []const SrcType,
    comptime DestType: type,
    dst: []DestType,
) void {
    for (src, dst) |*src_sample, *dst_sample| {
        const half = (maxInt(DestType) + 1) / 2;
        const trunc = @bitSizeOf(SrcType) - @bitSizeOf(DestType);
        dst_sample.* = shr(DestType, @intCast(src_sample.*), trunc) + half;
    }
}

test signedToUnsigned {
    var i16_to_u8: [1]u8 = undefined;
    var i24_to_u8: [1]u8 = undefined;
    var i32_to_u8: [1]u8 = undefined;

    signedToUnsigned(i16, &.{5}, u8, &i16_to_u8);
    signedToUnsigned(i24, &.{5}, u8, &i24_to_u8);
    signedToUnsigned(i32, &.{5}, u8, &i32_to_u8);

    try expectEqual(@as(u8, 128), i16_to_u8[0]);
    try expectEqual(@as(u8, 128), i24_to_u8[0]);
    try expectEqual(@as(u8, 128), i32_to_u8[0]);
}

pub fn signedToSigned(
    comptime SrcType: type,
    src: []const SrcType,
    comptime DestType: type,
    dst: []DestType,
) void {
    // TODO: Uncomment this (zig crashes)
    // if (std.simd.suggestVectorLength(SrcType)) |_| {
    //     signedToSignedSIMD(SrcType, src, DestType, dst);
    // } else {
    signedToSignedScalar(SrcType, src, DestType, dst);
    // }
}

pub fn signedToSignedScalar(
    comptime SrcType: type,
    src: []const SrcType,
    comptime DestType: type,
    dst: []DestType,
) void {
    for (src, dst) |*src_sample, *dst_sample| {
        const trunc = @bitSizeOf(SrcType) - @bitSizeOf(DestType);
        dst_sample.* = shr(DestType, @intCast(src_sample.*), trunc);
    }
}

test signedToSignedScalar {
    var i16_to_i24: [1]i24 = undefined;
    var i16_to_i32: [1]i32 = undefined;
    var i24_to_i16: [1]i16 = undefined;
    var i24_to_i32: [1]i32 = undefined;
    var i32_to_i16: [1]i16 = undefined;
    var i32_to_i24: [1]i24 = undefined;

    signedToSignedScalar(i24, &.{5}, i16, &i24_to_i16);
    signedToSignedScalar(i32, &.{5}, i16, &i32_to_i16);

    signedToSignedScalar(i16, &.{5}, i24, &i16_to_i24);
    signedToSignedScalar(i32, &.{5}, i24, &i32_to_i24);

    signedToSignedScalar(i16, &.{5}, i32, &i16_to_i32);
    signedToSignedScalar(i24, &.{5}, i32, &i24_to_i32);

    try expectEqual(@as(i24, 1280), i16_to_i24[0]);
    try expectEqual(@as(i32, 327680), i16_to_i32[0]);

    try expectEqual(@as(i16, 0), i24_to_i16[0]);
    try expectEqual(@as(i32, 1280), i24_to_i32[0]);

    try expectEqual(@as(i16, 0), i32_to_i16[0]);
    try expectEqual(@as(i24, 0), i32_to_i24[0]);
}

pub fn signedToSignedSIMD(
    comptime SrcType: type,
    src: []const SrcType,
    comptime DestType: type,
    dst: []DestType,
) void {
    const vec_size = std.simd.suggestVectorLength(SrcType).?;
    const VecSrc = @Vector(vec_size, SrcType);
    const VecDst = @Vector(vec_size, DestType);
    const trunc = @bitSizeOf(SrcType) - @bitSizeOf(DestType);
    const vec_blocks_len = src.len - (src.len % vec_size);
    var i: usize = 0;
    while (i < vec_blocks_len) : (i += vec_size) {
        const src_vec: VecSrc = src[i..][0..vec_size].*;
        dst[i..][0..vec_size].* = shr(VecDst, @intCast(src_vec), trunc);
    }
    if (i != src.len) signedToSignedScalar(SrcType, src[i..], DestType, dst[i..]);
}

test signedToSignedSIMD {
    var i16_to_i32: [32 + 7]i32 = undefined;
    const items = [1]i16{5} ** (32 + 7);
    signedToSignedSIMD(i16, &items, i32, &i16_to_i32);
    try expectEqual(@as(i32, 327680), i16_to_i32[0]);
    try expectEqual(i16_to_i32[0], i16_to_i32[i16_to_i32.len - 1]);
}

pub fn signedToFloat(
    comptime SrcType: type,
    src: []const SrcType,
    comptime DestType: type,
    dst: []DestType,
) void {
    if (std.simd.suggestVectorLength(SrcType)) |_| {
        signedToFloatSIMD(SrcType, src, DestType, dst);
    } else {
        signedToFloatScalar(SrcType, src, DestType, dst);
    }
}

pub fn signedToFloatScalar(
    comptime SrcType: type,
    src: []const SrcType,
    comptime DestType: type,
    dst: []DestType,
) void {
    const max: comptime_float = maxInt(SrcType) + 1;
    const div_by_max = 1.0 / max;
    for (src, dst) |*src_sample, *dst_sample| {
        dst_sample.* = @as(DestType, @floatFromInt(src_sample.*)) * div_by_max;
    }
}

test signedToFloatScalar {
    var i16_to_f32: [1]f32 = undefined;
    var i24_to_f32: [1]f32 = undefined;
    var i32_to_f32: [1]f32 = undefined;

    signedToFloatScalar(i16, &.{5}, f32, &i16_to_f32);
    signedToFloatScalar(i24, &.{5}, f32, &i24_to_f32);
    signedToFloatScalar(i32, &.{5}, f32, &i32_to_f32);

    try expectEqual(@as(f32, 1.52587890625e-4), i16_to_f32[0]);
    try expectEqual(@as(f32, 5.9604644775391e-7), i24_to_f32[0]);
    try expectEqual(@as(f32, 2.32830643e-09), i32_to_f32[0]);
}

pub fn signedToFloatSIMD(
    comptime SrcType: type,
    src: []const SrcType,
    comptime DestType: type,
    dst: []DestType,
) void {
    const vec_size = std.simd.suggestVectorLength(SrcType).?;
    const VecSrc = @Vector(vec_size, SrcType);
    const VecDst = @Vector(vec_size, DestType);
    const div_by_max: VecDst = @splat(1.0 / @as(comptime_float, maxInt(SrcType) + 1));
    const vec_blocks_len = src.len - (src.len % vec_size);
    var i: usize = 0;
    while (i < vec_blocks_len) : (i += vec_size) {
        const src_vec: VecSrc = src[i..][0..vec_size].*;
        dst[i..][0..vec_size].* = @as(VecDst, @floatFromInt(src_vec)) * div_by_max;
    }
    if (i != src.len) signedToFloatScalar(SrcType, src[i..], DestType, dst[i..]);
}

test signedToFloatSIMD {
    var i32_to_f32: [32 + 7]f32 = undefined;
    const items = [1]i32{5} ** (32 + 7);
    signedToFloatSIMD(i32, &items, f32, &i32_to_f32);
    try expectEqual(@as(f32, 2.32830643e-09), i32_to_f32[0]);
    try expectEqual(i32_to_f32[0], i32_to_f32[i32_to_f32.len - 1]);
}

pub fn floatToUnsigned(
    comptime SrcType: type,
    src: []const SrcType,
    comptime DestType: type,
    dst: []DestType,
) void {
    if (std.simd.suggestVectorLength(SrcType)) |_| {
        floatToUnsignedSIMD(SrcType, src, DestType, dst);
    } else {
        floatToUnsignedScalar(SrcType, src, DestType, dst);
    }
}

pub fn floatToUnsignedScalar(
    comptime SrcType: type,
    src: []const SrcType,
    comptime DestType: type,
    dst: []DestType,
) void {
    for (src, dst) |*src_sample, *dst_sample| {
        const half = maxInt(DestType) / 2;
        dst_sample.* = @intFromFloat(src_sample.* * half + (half + 1));
    }
}

test floatToUnsignedScalar {
    var f32_to_u8: [1]u8 = undefined;
    floatToUnsignedScalar(f32, &.{0.5}, u8, &f32_to_u8);
    try expectEqual(@as(u8, 191), f32_to_u8[0]);
}

pub fn floatToUnsignedSIMD(
    comptime SrcType: type,
    src: []const SrcType,
    comptime DestType: type,
    dst: []DestType,
) void {
    const vec_size = std.simd.suggestVectorLength(SrcType).?;
    const VecSrc = @Vector(vec_size, SrcType);
    const VecDst = @Vector(vec_size, DestType);
    const half: VecSrc = @splat(maxInt(DestType) / 2);
    const half_plus_one: VecSrc = @splat(maxInt(DestType) / 2 + 1);
    const vec_blocks_len = src.len - (src.len % vec_size);
    var i: usize = 0;
    while (i < vec_blocks_len) : (i += vec_size) {
        const src_vec: VecSrc = src[i..][0..vec_size].*;
        dst[i..][0..vec_size].* = @as(VecDst, @intFromFloat(src_vec * half + half_plus_one));
    }
    if (i != src.len) floatToUnsignedScalar(SrcType, src[i..], DestType, dst[i..]);
}

test floatToUnsignedSIMD {
    var f32_to_u8: [32 + 7]u8 = undefined;
    const items = [1]f32{0.5} ** (32 + 7);
    floatToUnsignedSIMD(f32, &items, u8, &f32_to_u8);
    try expectEqual(@as(u8, 191), f32_to_u8[0]);
    try expectEqual(f32_to_u8[0], f32_to_u8[f32_to_u8.len - 1]);
}

pub fn floatToSigned(
    comptime SrcType: type,
    src: []const SrcType,
    comptime DestType: type,
    dst: []DestType,
) void {
    if (std.simd.suggestVectorLength(SrcType)) |_| {
        floatToSignedSIMD(SrcType, src, DestType, dst);
    } else {
        floatToSignedScalar(SrcType, src, DestType, dst);
    }
}

pub fn floatToSignedScalar(
    comptime SrcType: type,
    src: []const SrcType,
    comptime DestType: type,
    dst: []DestType,
) void {
    for (src, dst) |*src_sample, *dst_sample| {
        const max = maxInt(DestType) + 1;
        dst_sample.* = @truncate(@as(i32, @intFromFloat(src_sample.* * max)));
    }
}

test floatToSignedScalar {
    var f32_to_i16: [1]i16 = undefined;
    var f32_to_i24: [1]i24 = undefined;
    var f32_to_i32: [1]i32 = undefined;

    floatToSignedScalar(f32, &.{0.5}, i16, &f32_to_i16);
    floatToSignedScalar(f32, &.{0.5}, i24, &f32_to_i24);
    floatToSignedScalar(f32, &.{0.5}, i32, &f32_to_i32);

    try expectEqual(@as(i16, 16384), f32_to_i16[0]);
    try expectEqual(@as(i24, 4194304), f32_to_i24[0]);
    try expectEqual(@as(i32, 1073741824), f32_to_i32[0]);
}

pub fn floatToSignedSIMD(
    comptime SrcType: type,
    src: []const SrcType,
    comptime DestType: type,
    dst: []DestType,
) void {
    const vec_size = std.simd.suggestVectorLength(SrcType).?;
    const VecSrc = @Vector(vec_size, SrcType);
    const VecDst = @Vector(vec_size, DestType);
    const max: VecSrc = @splat(maxInt(DestType) + 1);
    const vec_blocks_len = src.len - (src.len % vec_size);
    var i: usize = 0;
    while (i < vec_blocks_len) : (i += vec_size) {
        const src_vec: VecSrc = src[i..][0..vec_size].*;
        dst[i..][0..vec_size].* = @as(VecDst, @intFromFloat(src_vec * max));
    }
    if (i != src.len) floatToSignedScalar(SrcType, src[i..], DestType, dst[i..]);
}

test floatToSignedSIMD {
    var f32_to_i16: [32 + 7]i16 = undefined;
    const items = [1]f32{0.5} ** (32 + 7);
    floatToSignedSIMD(f32, &items, i16, &f32_to_i16);
    try expectEqual(@as(i16, 16384), f32_to_i16[0]);
    try expectEqual(f32_to_i16[0], f32_to_i16[f32_to_i16.len - 1]);
}
