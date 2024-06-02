const std = @import("std");
const Allocator = std.mem.Allocator;
const builtin = @import("builtin");

const js = struct {
    extern "sysjs" fn zigCreateMap() u32;
    extern "sysjs" fn zigCreateArray() u32;
    extern "sysjs" fn zigCreateString(str: [*]const u8, len: u32) u32;
    extern "sysjs" fn zigCreateFunction(id: *const anyopaque, captures: [*]Value, len: u32) u32;
    extern "sysjs" fn zigGetAttributeCount(id: u64) u32;
    extern "sysjs" fn zigGetProperty(id: u64, name: [*]const u8, len: u32, ret_ptr: *anyopaque) void;
    extern "sysjs" fn zigSetProperty(id: u64, name: [*]const u8, len: u32, set_ptr: *const anyopaque) void;
    extern "sysjs" fn zigDeleteProperty(id: u64, name: [*]const u8, len: u32) void;
    extern "sysjs" fn zigGetIndex(id: u64, index: u32, ret_ptr: *anyopaque) void;
    extern "sysjs" fn zigSetIndex(id: u64, index: u32, set_ptr: *const anyopaque) void;
    extern "sysjs" fn zigGetString(val_id: u64, ptr: [*]const u8) void;
    extern "sysjs" fn zigGetStringLength(val_id: u64) u32;
    extern "sysjs" fn zigValueEqual(val: *const anyopaque, other: *const anyopaque) bool;
    extern "sysjs" fn zigValueInstanceOf(val: *const anyopaque, other: *const anyopaque) bool;
    extern "sysjs" fn zigDeleteIndex(id: u64, index: u32) void;
    extern "sysjs" fn zigCopyBytes(id: u64, bytes: [*]u8, expected_len: u32) void;
    extern "sysjs" fn zigFunctionCall(id: u64, name: [*]const u8, len: u32, args: ?*const anyopaque, args_len: u32, ret_ptr: *anyopaque) void;
    extern "sysjs" fn zigFunctionInvoke(id: u64, args: ?*const anyopaque, args_len: u32, ret_ptr: *anyopaque) void;
    extern "sysjs" fn zigGetParamCount(id: u64) u32;
    extern "sysjs" fn zigConstructType(id: u64, args: ?*const anyopaque, args_len: u32) u32;
    extern "sysjs" fn zigCleanupObject(id: u64) void;
};

pub const Value = extern struct {
    tag: Tag,
    val: extern union {
        ref: u64,
        num: f64,
        bool: bool,
    },

    pub const Tag = enum(u8) {
        object,
        num,
        bool,
        str,
        null,
        undefined,
        func,
    };

    pub fn is(val: *const Value, comptime tag: Tag) bool {
        return val.tag == tag;
    }

    pub fn view(val: *const Value, comptime tag: Tag) switch (tag) {
        .object => Object,
        .num => f64,
        .bool => bool,
        .str => String,
        .func => Function,
        .null, .undefined => @compileError("Cannot get null or undefined as a value"),
    } {
        return switch (tag) {
            .object => Object{ .ref = val.val.ref },
            .num => val.val.num,
            .bool => val.val.bool,
            .str => String{ .ref = val.val.ref },
            .func => Function{ .ref = val.val.ref },
            else => unreachable,
        };
    }

    pub fn eql(val: *const Value, other: Value) bool {
        if (val.tag != other.tag)
            return false;

        return switch (val.tag) {
            .num => val.val.num == other.val.num,
            .bool => val.val.bool == other.val.bool,
            // Using JS equality (===) is better here since lets say a ref can be dangling
            else => js.zigValueEqual(val, &other),
        };
    }

    pub fn instanceOf(val: *const Value, other: Value) bool {
        return js.zigValueInstanceOf(val, &other);
    }

    pub fn format(val: *const Value, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        switch (val.tag) {
            .object => try writer.print("Object@{}({})", .{ val.val.ref, val.view(.object).attributeCount() }),
            .num => if (val.val.num > 10000)
                try writer.print("{e}", .{val.val.num})
            else
                try writer.print("{d}", .{val.val.num}),
            .bool => try writer.writeAll(if (val.view(.bool)) "true" else "false"),
            .str => try writer.print("String@{}({})", .{ val.val.ref, val.view(.str).getLength() }),
            .func => try writer.print("Function@{}({})", .{ val.val.ref, val.view(.func).paramCount() }),
            .null => try writer.writeAll("null"),
            .undefined => try writer.writeAll("undefined"),
        }
    }
};

pub const Object = struct {
    ref: u64,

    pub fn deinit(obj: *const Object) void {
        js.zigCleanupObject(obj.ref);
    }

    pub fn toValue(obj: *const Object) Value {
        return .{ .tag = .object, .val = .{ .ref = obj.ref } };
    }

    pub fn attributeCount(obj: *const Object) usize {
        return js.zigGetAttributeCount(obj.ref);
    }

    pub fn get(obj: *const Object, prop: []const u8) Value {
        var ret: Value = undefined;
        js.zigGetProperty(obj.ref, prop.ptr, @as(u32, @intCast(prop.len)), &ret);
        return ret;
    }

    pub fn set(obj: *const Object, prop: []const u8, value: Value) void {
        js.zigSetProperty(obj.ref, prop.ptr, @as(u32, @intCast(prop.len)), &value);
    }

    pub fn delete(obj: *const Object, prop: []const u8) void {
        js.zigDeleteProperty(obj.ref, prop.ptr, @as(u32, @intCast(prop.len)));
    }

    pub fn getIndex(obj: *const Object, index: u32) Value {
        var ret: Value = undefined;
        js.zigGetIndex(obj.ref, index, &ret);
        return ret;
    }

    pub fn setIndex(obj: *const Object, index: u32, value: Value) void {
        js.zigSetIndex(obj.ref, index, &value);
    }

    pub fn deleteIndex(obj: *const Object, index: u32) void {
        js.zigDeleteIndex(obj.ref, index);
    }

    pub fn copyBytes(obj: *const Object, bytes: []u8) void {
        js.zigCopyBytes(obj.ref, bytes.ptr, @as(u32, @intCast(bytes.len)));
    }

    pub fn call(obj: *const Object, fun: []const u8, args: []const Value) Value {
        var ret: Value = undefined;
        js.zigFunctionCall(obj.ref, fun.ptr, @as(u32, @intCast(fun.len)), args.ptr, @as(u32, @intCast(args.len)), &ret);
        return ret;
    }
};

pub const Function = struct {
    ref: u64,

    pub fn deinit(func: *const Function) void {
        js.zigCleanupObject(func.ref);
    }

    pub fn toValue(func: *const Function) Value {
        return .{ .tag = .func, .val = .{ .ref = func.ref } };
    }

    pub fn paramCount(func: *const Function) usize {
        // FIXME: native functions would always return 0
        return js.zigGetParamCount(func.ref);
    }

    pub fn construct(func: *const Function, args: []const Value) Object {
        return .{ .ref = js.zigConstructType(func.ref, args.ptr, @as(u32, @intCast(args.len))) };
    }

    pub fn invoke(func: *const Function, args: []const Value) Value {
        var ret: Value = undefined;
        js.zigFunctionInvoke(func.ref, args.ptr, @as(u32, @intCast(args.len)), &ret);
        return ret;
    }
};

pub const String = struct {
    ref: u64,

    pub fn deinit(string: *const String) void {
        js.zigCleanupObject(string.ref);
    }

    pub fn toValue(string: *const String) Value {
        return .{ .tag = .str, .val = .{ .ref = string.ref } };
    }

    pub fn getLength(string: *const String) usize {
        return js.zigGetStringLength(string.ref);
    }

    pub fn getOwnedSlice(string: *const String, allocator: std.mem.Allocator) ![]const u8 {
        const slice = try allocator.alloc(u8, string.getLength());
        errdefer allocator.free(slice);
        js.zigGetString(string.ref, slice.ptr);
        return slice;
    }
};

export fn wasmCallFunction(id: *anyopaque, args: u32, len: u32, captures: [*]Value, captures_len: u32) void {
    var captures_slice: []Value = undefined;
    captures_slice.ptr = captures;
    captures_slice.len = captures_len;

    const obj = Object{ .ref = args };
    const func = @as(FunType, @ptrCast(@alignCast(id)));
    obj.set("return_value", func(obj, len, captures_slice));
}

pub fn global() Object {
    return Object{ .ref = 0 };
}

pub fn createMap() Object {
    return .{ .ref = js.zigCreateMap() };
}

pub fn createArray() Object {
    return .{ .ref = js.zigCreateArray() };
}

pub fn createString(string: []const u8) String {
    return .{ .ref = js.zigCreateString(string.ptr, @as(u32, @intCast(string.len))) };
}

pub fn createNumber(num: anytype) Value {
    switch (@typeInfo(@TypeOf(num))) {
        .Int,
        .Float,
        .ComptimeInt,
        .ComptimeFloat,
        => return .{ .tag = .num, .val = .{ .num = std.math.lossyCast(f64, num) } },
        else => @compileError("expected integer, found " ++ @typeName(@TypeOf(num))),
    }
}

pub fn createBool(val: bool) Value {
    return .{ .tag = .bool, .val = .{ .bool = val } };
}

pub fn createNull() Value {
    return .{ .tag = .null, .val = undefined };
}

pub fn createUndefined() Value {
    return .{ .tag = .undefined, .val = undefined };
}

const FunType = *const fn (args: Object, args_len: u32, captures: []Value) Value;

pub fn createFunction(fun: FunType, captures: []Value) Function {
    return .{ .ref = js.zigCreateFunction(fun, captures.ptr, @as(u32, @intCast(captures.len))) };
}

pub fn constructType(t: []const u8, args: []const Value) Object {
    const constructor = global().get(t).view(.func);
    defer constructor.deinit();

    return constructor.construct(args);
}

test {
    std.testing.refAllDeclsRecursive(@This());
}
