const std = @import("std");
const c = @import("c.zig");

pub const ListShapers = struct {
    index: usize,
    list: [*:null]const ?[*:0]const u8,

    pub fn init() ListShapers {
        return .{ .index = 0, .list = c.hb_shape_list_shapers() };
    }

    pub fn next(self: *ListShapers) ?[:0]const u8 {
        self.index += 1;
        return std.mem.span(
            self.list[self.index - 1] orelse return null,
        );
    }
};
