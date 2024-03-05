const builtin = @import("builtin");

// Extracted from `zig translate-c tmp.c` with `#include <objc/message.h>` in the file.
pub const SEL = opaque {};
pub const Class = opaque {};

pub extern fn sel_getUid(str: [*c]const u8) ?*SEL;
pub extern fn objc_getClass(name: [*c]const u8) ?*Class;
pub extern fn objc_msgSend() void;

pub const AutoReleasePool = if (!builtin.target.isDarwin()) opaque {
    pub fn init() error{OutOfMemory}!?*AutoReleasePool {
        return null;
    }

    pub fn release(pool: ?*AutoReleasePool) void {
        _ = pool;
        return;
    }
} else opaque {
    pub fn init() error{OutOfMemory}!?*AutoReleasePool {
        // pool = [NSAutoreleasePool alloc];
        var pool = msgSend(objc_getClass("NSAutoreleasePool"), "alloc", .{}, ?*AutoReleasePool);
        if (pool == null) return error.OutOfMemory;

        // pool = [pool init];
        pool = msgSend(pool, "init", .{}, ?*AutoReleasePool);
        if (pool == null) unreachable;

        return pool;
    }

    pub fn release(pool: ?*AutoReleasePool) void {
        // [pool release];
        msgSend(pool, "release", .{}, void);
    }
};

// Borrowed from https://github.com/hazeycode/zig-objcrt
pub fn msgSend(obj: anytype, sel_name: [:0]const u8, args: anytype, comptime ReturnType: type) ReturnType {
    const args_meta = @typeInfo(@TypeOf(args)).Struct.fields;

    const FnType = switch (args_meta.len) {
        0 => *const fn (@TypeOf(obj), ?*SEL) callconv(.C) ReturnType,
        1 => *const fn (@TypeOf(obj), ?*SEL, args_meta[0].type) callconv(.C) ReturnType,
        2 => *const fn (@TypeOf(obj), ?*SEL, args_meta[0].type, args_meta[1].type) callconv(.C) ReturnType,
        3 => *const fn (@TypeOf(obj), ?*SEL, args_meta[0].type, args_meta[1].type, args_meta[2].type) callconv(.C) ReturnType,
        4 => *const fn (@TypeOf(obj), ?*SEL, args_meta[0].type, args_meta[1].type, args_meta[2].type, args_meta[3].type) callconv(.C) ReturnType,
        else => @compileError("Unsupported number of args"),
    };

    // NOTE: func is a var because making it const causes a compile error which I believe is a compiler bug
    const func = @as(FnType, @ptrCast(&objc_msgSend));
    const sel = sel_getUid(@as([*c]const u8, @ptrCast(sel_name)));

    return @call(.auto, func, .{ obj, sel } ++ args);
}
