const std = @import("std");
const asBytes = std.mem.asBytes;
const bytesAsValue = std.mem.bytesAsValue;
const shl = std.math.shl;
const shr = std.math.shr;
const maxInt = std.math.maxInt;
const expectEqual = std.testing.expectEqual;

// TODO: SIMD
pub fn unsignedToSigned(
    comptime SrcType: type,
    src_stride: u8,
    src: []const u8,
    comptime DstType: type,
    dst_stride: u8,
    dst: []u8,
    len: usize,
) void {
    const half = (maxInt(SrcType) + 1) / 2;
    const trunc = @bitSizeOf(DstType) - @bitSizeOf(SrcType);
    for (0..len) |i| {
        const src_sample: *const SrcType = @ptrCast(@alignCast(src[i * src_stride ..][0..src_stride]));
        const dst_sample: DstType = shl(DstType, @intCast(src_sample.* -% half), trunc);
        @memcpy(dst[i * dst_stride ..][0..dst_stride], asBytes(&dst_sample)[0..dst_stride]);
    }
}

test unsignedToSigned {
    var u8_to_i16: [1]i16 = undefined;
    var u8_to_i24: [1]i24 = undefined;
    var u8_to_i32: [1]i32 = undefined;

    unsignedToSigned(u8, 1, &[_]u8{5}, i16, 2, asBytes(&u8_to_i16), 1);
    unsignedToSigned(u8, 1, &[_]u8{5}, i24, 3, asBytes(&u8_to_i24), 1);
    unsignedToSigned(u8, 1, &[_]u8{5}, i32, 4, asBytes(&u8_to_i32), 1);

    try expectEqual(@as(i16, -31488), u8_to_i16[0]);
    try expectEqual(@as(i24, -8060928), u8_to_i24[0]);
    try expectEqual(@as(i32, -2063597568), u8_to_i32[0]);
}

// TODO: SIMD
pub fn unsignedToFloat(
    comptime SrcType: type,
    src_stride: u8,
    src: []const u8,
    comptime DstType: type,
    dst_stride: u8,
    dst: []u8,
    len: usize,
) void {
    const half = (maxInt(SrcType) + 1) / 2;
    for (0..len) |i| {
        const src_sample: *const SrcType = @ptrCast(@alignCast(src[i * src_stride ..][0..src_stride]));
        const dst_sample: DstType = (@as(DstType, @floatFromInt(src_sample.*)) - half) * 1.0 / half;
        @memcpy(dst[i * dst_stride ..][0..dst_stride], asBytes(&dst_sample)[0..dst_stride]);
    }
}

test unsignedToFloat {
    var u8_to_f32: [1]f32 = undefined;
    unsignedToFloat(u8, 1, &[_]u8{5}, f32, 4, asBytes(&u8_to_f32), 1);
    try expectEqual(@as(f32, -0.9609375), u8_to_f32[0]);
}

// TODO: SIMD
pub fn signedToUnsigned(
    comptime SrcType: type,
    src_stride: u8,
    src: []const u8,
    comptime DstType: type,
    dst_stride: u8,
    dst: []u8,
    len: usize,
) void {
    const half = (maxInt(DstType) + 1) / 2;
    const trunc = @bitSizeOf(SrcType) - @bitSizeOf(DstType);
    for (0..len) |i| {
        const src_sample: *const SrcType = @ptrCast(@alignCast(src[i * src_stride ..][0..src_stride]));
        const dst_sample: DstType = shr(DstType, @intCast(src_sample.*), trunc) + half;
        @memcpy(dst[i * dst_stride ..][0..dst_stride], asBytes(&dst_sample)[0..dst_stride]);
    }
}

test signedToUnsigned {
    var i16_to_u8: [1]u8 = undefined;
    var i24_to_u8: [1]u8 = undefined;
    var i32_to_u8: [1]u8 = undefined;

    signedToUnsigned(i16, 2, asBytes(&[_]i16{5}), u8, 1, asBytes(&i16_to_u8), 1);
    signedToUnsigned(i24, 3, asBytes(&[_]i24{5}), u8, 1, asBytes(&i24_to_u8), 1);
    signedToUnsigned(i32, 4, asBytes(&[_]i32{5}), u8, 1, asBytes(&i32_to_u8), 1);

    try expectEqual(@as(u8, 128), i16_to_u8[0]);
    try expectEqual(@as(u8, 128), i24_to_u8[0]);
    try expectEqual(@as(u8, 128), i32_to_u8[0]);
}

pub fn signedToSigned(
    comptime SrcType: type,
    src_stride: u8,
    src: []const u8,
    comptime DstType: type,
    dst_stride: u8,
    dst: []u8,
    len: usize,
) void {
    const trunc = @bitSizeOf(SrcType) - @bitSizeOf(DstType);
    var i: usize = 0;

    // Use SIMD when available
    if (std.simd.suggestVectorLength(SrcType)) |vec_size| {
        const VecSrc = @Vector(vec_size, SrcType);
        const VecDst = @Vector(vec_size, DstType);
        const vec_blocks_len = len - (len % vec_size);
        while (i < vec_blocks_len) : (i += vec_size) {
            const src_vec = bytesAsValue(VecSrc, src[i * src_stride ..][0 .. vec_size * src_stride]).*;
            const dst_sample: VecDst = shr(VecDst, @intCast(src_vec), trunc);
            @memcpy(dst[i * dst_stride ..][0 .. vec_size * dst_stride], asBytes(&dst_sample)[0 .. vec_size * dst_stride]);
        }
    }

    // Convert the remaining samples

    while (i < len) : (i += 1) {
        const src_sample: *const SrcType = @ptrCast(@alignCast(src[i * src_stride ..][0..src_stride]));
        const dst_sample: DstType = shr(DstType, @intCast(src_sample.*), trunc);
        @memcpy(dst[i * dst_stride ..][0..dst_stride], asBytes(&dst_sample)[0..dst_stride]);
    }
}

test "signedToSigned single" {
    var i16_to_i24: [1]i24 = undefined;
    var i16_to_i32: [1]i32 = undefined;
    var i24_to_i16: [1]i16 = undefined;
    var i24_to_i32: [1]i32 = undefined;
    var i32_to_i16: [1]i16 = undefined;
    var i32_to_i24: [1]i24 = undefined;

    signedToSigned(i24, 3, asBytes(&[_]i24{5}), i16, 2, asBytes(&i24_to_i16), 1);
    signedToSigned(i32, 4, asBytes(&[_]i32{5}), i16, 2, asBytes(&i32_to_i16), 1);

    signedToSigned(i16, 2, asBytes(&[_]i16{5}), i24, 3, asBytes(&i16_to_i24), 1);
    signedToSigned(i32, 4, asBytes(&[_]i32{5}), i24, 3, asBytes(&i32_to_i24), 1);

    signedToSigned(i16, 2, asBytes(&[_]i16{5}), i32, 4, asBytes(&i16_to_i32), 1);
    signedToSigned(i24, 3, asBytes(&[_]i24{5}), i32, 4, asBytes(&i24_to_i32), 1);

    try expectEqual(@as(i24, 1280), i16_to_i24[0]);
    try expectEqual(@as(i32, 327680), i16_to_i32[0]);

    try expectEqual(@as(i16, 0), i24_to_i16[0]);
    try expectEqual(@as(i32, 1280), i24_to_i32[0]);

    try expectEqual(@as(i16, 0), i32_to_i16[0]);
    try expectEqual(@as(i24, 0), i32_to_i24[0]);
}

test "signedToSigned multi" {
    const len = 32 + 7;
    var i16_to_i32: [len]i32 = undefined;
    const items = [1]i16{5} ** (len);
    signedToSigned(i16, 2, asBytes(&items), i32, 4, asBytes(&i16_to_i32), len);
    try expectEqual(@as(i32, 327680), i16_to_i32[0]);
    try expectEqual(i16_to_i32[0], i16_to_i32[i16_to_i32.len - 1]);
}

pub fn signedToFloat(
    comptime SrcType: type,
    src_stride: u8,
    src: []const u8,
    comptime DstType: type,
    dst_stride: u8,
    dst: []u8,
    len: usize,
) void {
    const div_by_max = 1.0 / @as(comptime_float, maxInt(SrcType) + 1);
    var i: usize = 0;

    // Use SIMD when available
    if (std.simd.suggestVectorLength(SrcType)) |vec_size| {
        const VecSrc = @Vector(vec_size, SrcType);
        const VecDst = @Vector(vec_size, DstType);
        const vec_blocks_len = len - (len % vec_size);
        const div_by_max_vec: VecDst = @splat(div_by_max);
        while (i < vec_blocks_len) : (i += vec_size) {
            const src_vec = bytesAsValue(VecSrc, src[i * src_stride ..][0 .. vec_size * src_stride]).*;
            const dst_sample: VecDst = @as(VecDst, @floatFromInt(src_vec)) * div_by_max_vec;
            @memcpy(dst[i * dst_stride ..][0 .. vec_size * dst_stride], asBytes(&dst_sample)[0 .. vec_size * dst_stride]);
        }
    }

    // Convert the remaining samples
    while (i < len) : (i += 1) {
        const src_sample: *const SrcType = @ptrCast(@alignCast(src[i * src_stride ..][0..src_stride]));
        const dst_sample: DstType = @as(DstType, @floatFromInt(src_sample.*)) * div_by_max;
        @memcpy(dst[i * dst_stride ..][0..dst_stride], asBytes(&dst_sample)[0..dst_stride]);
    }
}

test "signedToFloat single" {
    var i16_to_f32: [1]f32 = undefined;
    var i24_to_f32: [1]f32 = undefined;
    var i32_to_f32: [1]f32 = undefined;

    signedToFloat(i16, 2, asBytes(&[_]i16{5}), f32, 4, asBytes(&i16_to_f32), 1);
    signedToFloat(i24, 3, asBytes(&[_]i24{5}), f32, 4, asBytes(&i24_to_f32), 1);
    signedToFloat(i32, 4, asBytes(&[_]i32{5}), f32, 4, asBytes(&i32_to_f32), 1);

    try expectEqual(@as(f32, 1.52587890625e-4), i16_to_f32[0]);
    try expectEqual(@as(f32, 5.9604644775391e-7), i24_to_f32[0]);
    try expectEqual(@as(f32, 2.32830643e-09), i32_to_f32[0]);
}

test "signedToFloat multi" {
    const len = 32 + 7;
    var i32_to_f32: [len]f32 = undefined;
    const items = [1]i32{5} ** (len);
    signedToFloat(i32, 4, asBytes(&items), f32, 4, asBytes(&i32_to_f32), len);
    try expectEqual(@as(f32, 2.32830643e-09), i32_to_f32[0]);
    try expectEqual(i32_to_f32[0], i32_to_f32[i32_to_f32.len - 1]);
}

pub fn floatToUnsigned(
    comptime SrcType: type,
    src_stride: u8,
    src: []const u8,
    comptime DstType: type,
    dst_stride: u8,
    dst: []u8,
    len: usize,
) void {
    const half = maxInt(DstType) / 2;
    const half_plus_one = half + 1;
    var i: usize = 0;

    // Use SIMD when available
    if (std.simd.suggestVectorLength(SrcType)) |vec_size| {
        const VecSrc = @Vector(vec_size, SrcType);
        const VecDst = @Vector(vec_size, DstType);
        const half_vec: VecSrc = @splat(half);
        const half_plus_one_vec: VecSrc = @splat(half_plus_one);
        const vec_blocks_len = len - (len % vec_size);
        while (i < vec_blocks_len) : (i += vec_size) {
            const src_vec = bytesAsValue(VecSrc, src[i * src_stride ..][0 .. vec_size * src_stride]).*;
            const dst_sample: VecDst = @intFromFloat(src_vec * half_vec + half_plus_one_vec);
            @memcpy(dst[i * dst_stride ..][0 .. vec_size * dst_stride], asBytes(&dst_sample)[0 .. vec_size * dst_stride]);
        }
    }

    // Convert the remaining samples
    while (i < len) : (i += 1) {
        const src_sample: *const SrcType = @ptrCast(@alignCast(src[i * src_stride ..][0..src_stride]));
        const dst_sample: DstType = @intFromFloat(src_sample.* * half + half_plus_one);
        @memcpy(dst[i * dst_stride ..][0..dst_stride], asBytes(&dst_sample)[0..dst_stride]);
    }
}

test "floatToUnsigned single" {
    var f32_to_u8: [1]u8 = undefined;
    floatToUnsigned(f32, 4, asBytes(&[_]f32{0.5}), u8, 1, asBytes(&f32_to_u8), 1);
    try expectEqual(@as(u8, 191), f32_to_u8[0]);
}

test "floatToUnsigned multi" {
    const len = 32 + 7;
    var f32_to_u8: [len]u8 = undefined;
    const items = [1]f32{0.5} ** (len);
    floatToUnsigned(f32, 4, asBytes(&items), u8, 1, asBytes(&f32_to_u8), len);
    try expectEqual(@as(u8, 191), f32_to_u8[0]);
    try expectEqual(f32_to_u8[0], f32_to_u8[f32_to_u8.len - 1]);
}

pub fn floatToSigned(
    comptime SrcType: type,
    src_stride: u8,
    src: []const u8,
    comptime DstType: type,
    dst_stride: u8,
    dst: []u8,
    len: usize,
) void {
    const max = maxInt(DstType) + 1;
    var i: usize = 0;

    // Use SIMD when available
    if (std.simd.suggestVectorLength(SrcType)) |vec_size| {
        const VecSrc = @Vector(vec_size, SrcType);
        const VecDst = @Vector(vec_size, DstType);
        const max_vec: VecSrc = @splat(max);
        const vec_blocks_len = len - (len % vec_size);
        while (i < vec_blocks_len) : (i += vec_size) {
            const src_vec = bytesAsValue(VecSrc, src[i * src_stride ..][0 .. vec_size * src_stride]).*;
            const dst_sample: VecDst = @intFromFloat(src_vec * max_vec);
            @memcpy(dst[i * dst_stride ..][0 .. vec_size * dst_stride], asBytes(&dst_sample)[0 .. vec_size * dst_stride]);
        }
    }

    // Convert the remaining samples
    while (i < len) : (i += 1) {
        const src_sample: *const SrcType = @ptrCast(@alignCast(src[i * src_stride ..][0..src_stride]));
        const dst_sample: DstType = @truncate(@as(i32, @intFromFloat(src_sample.* * max)));
        @memcpy(dst[i * dst_stride ..][0..dst_stride], asBytes(&dst_sample)[0..dst_stride]);
    }
}

test "floatToSigned single" {
    var f32_to_i16: [1]i16 = undefined;
    var f32_to_i24: [1]i24 = undefined;
    var f32_to_i32: [1]i32 = undefined;

    floatToSigned(f32, 4, asBytes(&[_]f32{0.5}), i16, 2, asBytes(&f32_to_i16), 1);
    floatToSigned(f32, 4, asBytes(&[_]f32{0.5}), i24, 3, asBytes(&f32_to_i24), 1);
    floatToSigned(f32, 4, asBytes(&[_]f32{0.5}), i32, 4, asBytes(&f32_to_i32), 1);

    try expectEqual(@as(i16, 16384), f32_to_i16[0]);
    try expectEqual(@as(i24, 4194304), f32_to_i24[0]);
    try expectEqual(@as(i32, 1073741824), f32_to_i32[0]);
}

test "floatToSigned multi" {
    const len = 32 + 7;
    var f32_to_i16: [len]i16 = undefined;
    const items = [1]f32{0.5} ** (len);
    floatToSigned(f32, 4, asBytes(&items), i16, 2, asBytes(&f32_to_i16), len);
    try expectEqual(@as(i16, 16384), f32_to_i16[0]);
    try expectEqual(f32_to_i16[0], f32_to_i16[f32_to_i16.len - 1]);
}
