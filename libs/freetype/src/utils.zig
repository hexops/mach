const std = @import("std");

pub fn structToBitFields(comptime IntType: type, comptime EnumDataType: type, flags: anytype) IntType {
    var value: IntType = 0;
    inline for (comptime std.meta.fieldNames(EnumDataType)) |field_name| {
        if (@field(flags, field_name)) {
            value |= @enumToInt(@field(EnumDataType, field_name));
        }
    }
    return value;
}

pub fn bitFieldsToStruct(comptime StructType: type, comptime EnumDataType: type, flags: anytype) StructType {
    var value = std.mem.zeroes(StructType);
    inline for (comptime std.meta.fieldNames(EnumDataType)) |field_name| {
        if (flags & (@enumToInt(@field(EnumDataType, field_name))) != 0) {
            @field(value, field_name) = true;
        }
    }
    return value;
}
