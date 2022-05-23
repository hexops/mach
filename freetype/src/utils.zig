const std = @import("std");
const meta = std.meta;
const mem = std.mem;
const testing = std.testing;

pub fn structToBitFields(comptime IntType: type, comptime EnumDataType: type, flags: anytype) IntType {
    var value: IntType = 0;
    inline for (comptime meta.fieldNames(EnumDataType)) |field_name| {
        if (@field(flags, field_name)) {
            value |= @enumToInt(@field(EnumDataType, field_name));
        }
    }
    return value;
}

pub fn bitFieldsToStruct(comptime StructType: type, comptime EnumDataType: type, flags: anytype) StructType {
    var value = mem.zeroes(StructType);
    inline for (comptime meta.fieldNames(EnumDataType)) |field_name| {
        if (flags & (@enumToInt(@field(EnumDataType, field_name))) != 0) {
            @field(value, field_name) = true;
        }
    }
    return value;
}

const TestEnum = enum(u16) {
    filed_1 = (1 << 1),
    filed_2 = (1 << 2),
    filed_3 = (1 << 3),
};

const TestStruct = packed struct {
    filed_1: bool = false,
    filed_2: bool = false,
    filed_3: bool = false,
};

test "struct fields to bit fields" {
    try testing.expectEqual(@as(u16, (1 << 1) | (1 << 3)), structToBitFields(u16, TestEnum, TestStruct{
        .filed_1 = true,
        .filed_3 = true,
    }));
    try testing.expectEqual(@as(u16, 0), structToBitFields(u16, TestEnum, TestStruct{}));
}

test "bit fields to struct" {
    try testing.expectEqual(TestStruct{ .filed_1 = true, .filed_2 = true, .filed_3 = false }, bitFieldsToStruct(TestStruct, TestEnum, (1 << 1) | (1 << 2)));
}
