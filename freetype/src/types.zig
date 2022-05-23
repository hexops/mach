const std = @import("std");
const c = @import("c.zig");
const utils = @import("utils.zig");

pub const Vector = c.FT_Vector;
pub const Matrix = c.FT_Matrix;

pub const OpenFlags = packed struct {
    memory: bool = false,
    stream: bool = false,
    path: bool = false,
    driver: bool = false,
    params: bool = false,

    pub const Flag = enum(u5) {
        memory = c.FT_OPEN_MEMORY,
        stream = c.FT_OPEN_STREAM,
        path = c.FT_OPEN_PATHNAME,
        driver = c.FT_OPEN_DRIVER,
        params = c.FT_OPEN_PARAMS,
    };

    pub fn toBitFields(flags: OpenFlags) u5 {
        return utils.structToBitFields(u5, Flag, flags);
    }
};

pub const OpenArgs = struct {
    flags: OpenFlags,
    data: union(enum) {
        memory: []const u8,
        path: []const u8,
        stream: c.FT_Stream,
        driver: c.FT_Module,
        params: []const c.FT_Parameter,
    },

    pub fn toCInterface(self: OpenArgs) c.FT_Open_Args {
        var oa = std.mem.zeroes(c.FT_Open_Args);
        oa.flags = self.flags.toBitFields();
        switch (self.data) {
            .memory => |d| {
                oa.memory_base = d.ptr;
                oa.memory_size = @truncate(u31, d.len);
            },
            .path => |*d| oa.pathname = @intToPtr(*u8, @ptrToInt(d.ptr)),
            .stream => |d| oa.stream = d,
            .driver => |d| oa.driver = d,
            .params => |*d| {
                oa.params = @intToPtr(*c.FT_Parameter, @ptrToInt(d.ptr));
                oa.num_params = @intCast(u31, d.len);
            },
        }
        return oa;
    }
};
