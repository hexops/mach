//! The Mach standard library

const build_options = @import("build-options");
const builtin = @import("builtin");
const std = @import("std");

pub const is_debug = builtin.mode == .Debug;

// Core
pub const Core = if (build_options.want_core) @import("Core.zig") else struct {};

// note: gamemode requires libc on linux
pub const gamemode = if (builtin.os.tag != .linux or builtin.link_libc) @import("gamemode.zig");
pub const gfx = if (build_options.want_mach) @import("gfx/main.zig") else struct {};
pub const Audio = if (build_options.want_sysaudio) @import("Audio.zig") else struct {};
pub const math = @import("math/main.zig");
pub const testing = @import("testing.zig");
pub const time = @import("time/main.zig");

pub const sysaudio = if (build_options.want_sysaudio) @import("sysaudio/main.zig") else struct {};
pub const sysgpu = if (build_options.want_sysgpu) @import("sysgpu/main.zig") else struct {};
pub const gpu = if (build_options.want_sysgpu) @import("sysgpu/main.zig").sysgpu else struct {};

pub const Modules = @import("module.zig").Modules;

pub const ModuleID = @import("module.zig").ModuleID;
pub const ModuleFunctionID = @import("module.zig").ModuleFunctionID;
pub const FunctionID = @import("module.zig").FunctionID;
pub const Functions = @import("module.zig").Functions;

pub const ObjectID = u32;

pub fn Objects(comptime T: type) type {
    return struct {
        internal: struct {
            allocator: std.mem.Allocator,
            id_counter: ObjectID = 0,
            ids: std.AutoArrayHashMapUnmanaged(ObjectID, u32) = .{},
            data: std.MultiArrayList(T) = .{},
        },

        pub const IsMachObjects = void;

        // Only iteration, get(i) and set(i) are supported currently.
        pub const Slice = struct {
            len: usize,

            internal: std.MultiArrayList(T).Slice,

            pub fn set(s: *Slice, index: usize, elem: T) void {
                s.internal.set(index, elem);
            }

            pub fn get(s: Slice, index: usize) T {
                return s.internal.get(index);
            }
        };

        pub fn new(objs: *@This(), value: T) std.mem.Allocator.Error!ObjectID {
            const allocator = objs.internal.allocator;
            const ids = &objs.internal.ids;
            const data = &objs.internal.data;

            const new_index = try data.addOne(allocator);
            errdefer _ = data.pop();

            const new_object_id = objs.internal.id_counter;
            try ids.putNoClobber(allocator, new_object_id, @intCast(new_index));
            objs.internal.id_counter += 1;
            data.set(new_index, value);
            return new_object_id;
        }

        pub fn set(objs: *@This(), id: ObjectID, value: T) void {
            const ids = &objs.internal.ids;
            const data = &objs.internal.data;

            const index = ids.get(id) orelse std.debug.panic("invalid object: {any}", .{id});
            data.set(index, value);
        }

        pub fn get(objs: *@This(), id: ObjectID) ?T {
            const ids = &objs.internal.ids;
            const data = &objs.internal.data;

            const index = ids.get(id) orelse return null;
            return data.get(index);
        }

        pub fn slice(objs: *@This()) Slice {
            return Slice{ .len = objs.internal.data.len, .internal = objs.internal.data };
        }
    };
}

pub fn Object(comptime T: type) type {
    return T;
}

pub fn schedule(v: anytype) @TypeOf(v) {
    return v;
}

test {
    // TODO: refactor code so we can use this here:
    // std.testing.refAllDeclsRecursive(@This());
    _ = Core;
    _ = gpu;
    _ = sysaudio;
    _ = sysgpu;
    _ = gfx;
    _ = math;
    _ = testing;
    _ = time;
    std.testing.refAllDeclsRecursive(gamemode);
    std.testing.refAllDeclsRecursive(math);
}
