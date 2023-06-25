const std = @import("std");
const c = @import("c.zig");

pub const MemoryMode = enum(u2) {
    duplicate = c.HB_MEMORY_MODE_DUPLICATE,
    readonly = c.HB_MEMORY_MODE_READONLY,
    writable = c.HB_MEMORY_MODE_WRITABLE,
    readonly_may_make_writable = c.HB_MEMORY_MODE_READONLY_MAY_MAKE_WRITABLE,
};

pub const Blob = struct {
    handle: *c.hb_blob_t,

    pub fn init(data: []u8, mode: MemoryMode) ?Blob {
        return Blob{
            .handle = c.hb_blob_create_or_fail(&data[0], @intCast(c_uint, data.len), @intFromEnum(mode), null, null) orelse return null,
        };
    }

    pub fn initOrEmpty(data: []u8, mode: MemoryMode) Blob {
        return .{
            .handle = c.hb_blob_create(&data[0], @intCast(c_uint, data.len), @intFromEnum(mode), null, null).?,
        };
    }

    pub fn initFromFile(path: [*:0]const u8) ?Blob {
        return Blob{
            .handle = c.hb_blob_create_from_file_or_fail(path) orelse return null,
        };
    }

    pub fn initFromFileOrEmpty(path: [*:0]const u8) Blob {
        return .{
            .handle = c.hb_blob_create_from_file(path).?,
        };
    }

    pub fn initEmpty() Blob {
        return .{ .handle = c.hb_blob_get_empty().? };
    }

    pub fn createSubBlobOrEmpty(self: Blob, offset: u32, len: u32) Blob {
        return .{
            .handle = c.hb_blob_create_sub_blob(self.handle, offset, len).?,
        };
    }

    pub fn copyWritable(self: Blob) ?Blob {
        return Blob{
            .handle = c.hb_blob_copy_writable_or_fail(self.handle) orelse return null,
        };
    }

    pub fn deinit(self: Blob) void {
        c.hb_blob_destroy(self.handle);
    }

    pub fn getData(self: Blob, len: ?u32) []const u8 {
        var l = len;
        const data = c.hb_blob_get_data(self.handle, if (l) |_| &l.? else null);
        return if (l) |_|
            data[0..l.?]
        else
            std.mem.sliceTo(data, 0);
    }

    pub fn getDataWritable(self: Blob, len: ?u32) ?[]const u8 {
        var l = len;
        const data = c.hb_blob_get_data(self.handle, if (l) |_| &l.? else null);
        return if (data == null)
            null
        else if (l) |_|
            data[0..l.?]
        else
            std.mem.sliceTo(data, 0);
    }

    pub fn getLength(self: Blob) u32 {
        return c.hb_blob_get_length(self.handle);
    }

    pub fn isImmutable(self: Blob) bool {
        return c.hb_blob_is_immutable(self.handle) > 0;
    }

    pub fn makeImmutable(self: Blob) void {
        c.hb_blob_make_immutable(self.handle);
    }

    pub fn reference(self: Blob) Blob {
        return .{
            .handle = c.hb_blob_reference(self.handle).?,
        };
    }
};
