//! Stores null-terminated strings and maps them to unique 32-bit indices.
//!
//! Lookups are omnidirectional: both (string -> index) and (index -> string) are supported
//! operations.
//!
//! The implementation is based on:
//! https://zig.news/andrewrk/how-to-use-hash-map-contexts-to-save-memory-when-doing-a-string-table-3l33

const std = @import("std");

const StringTable = @This();

string_bytes: std.ArrayListUnmanaged(u8) = .{},

/// Key is string_bytes index.
string_table: std.HashMapUnmanaged(u32, void, IndexContext, std.hash_map.default_max_load_percentage) = .{},

pub const Index = u32;

/// Returns the index of a string key, if it exists
/// complexity: hashmap lookup
pub fn index(table: *const StringTable, key: []const u8) ?Index {
    const slice_context: SliceAdapter = .{ .string_bytes = &table.string_bytes };
    const found_entry = table.string_table.getEntryAdapted(key, slice_context);
    if (found_entry) |e| return e.key_ptr.*;
    return null;
}

/// Returns the index of a string key, inserting if not exists
/// complexity: hashmap lookup / update
///
/// Assumes `key` does not contain any zero bytes
pub fn indexOrPut(table: *StringTable, allocator: std.mem.Allocator, key: []const u8) error{OutOfMemory}!Index {
    const slice_context: SliceAdapter = .{ .string_bytes = &table.string_bytes };
    const index_context: IndexContext = .{ .string_bytes = &table.string_bytes };
    const entry = try table.string_table.getOrPutContextAdapted(allocator, key, slice_context, index_context);
    if (!entry.found_existing) {
        errdefer table.string_table.removeByPtr(entry.key_ptr);

        entry.key_ptr.* = std.math.cast(Index, table.string_bytes.items.len) orelse return error.OutOfMemory;
        try table.string_bytes.ensureUnusedCapacity(allocator, key.len + 1);

        table.string_bytes.appendSliceAssumeCapacity(key);
        table.string_bytes.appendAssumeCapacity('\x00');
    }
    return entry.key_ptr.*;
}

/// Returns a null-terminated string given the index
/// complexity: O(n)
pub fn string(table: *const StringTable, idx: Index) [:0]const u8 {
    return std.mem.span(@as([*:0]const u8, @ptrCast(table.string_bytes.items.ptr)) + idx);
}

pub fn deinit(table: *StringTable, allocator: std.mem.Allocator) void {
    table.string_bytes.deinit(allocator);
    table.string_table.deinit(allocator);
}

const IndexContext = struct {
    string_bytes: *std.ArrayListUnmanaged(u8),

    pub fn eql(ctx: IndexContext, a: u32, b: u32) bool {
        _ = ctx;
        return a == b;
    }

    pub fn hash(ctx: IndexContext, x: u32) u64 {
        const x_slice = std.mem.span(@as([*:0]const u8, @ptrCast(ctx.string_bytes.items.ptr)) + x);
        return std.hash_map.hashString(x_slice);
    }
};

const SliceAdapter = struct {
    string_bytes: *std.ArrayListUnmanaged(u8),

    pub fn eql(adapter: SliceAdapter, a_slice: []const u8, b: u32) bool {
        const b_slice = std.mem.span(@as([*:0]const u8, @ptrCast(adapter.string_bytes.items.ptr)) + b);
        return std.mem.eql(u8, a_slice, b_slice);
    }

    pub fn hash(adapter: SliceAdapter, adapted_key: []const u8) u64 {
        _ = adapter;
        return std.hash_map.hashString(adapted_key);
    }
};

test {
    const gpa = std.testing.allocator;

    var table: StringTable = .{};
    defer table.deinit(gpa);

    const index_context: IndexContext = .{ .string_bytes = &table.string_bytes };
    _ = index_context;

    // "hello" -> index 0
    const hello_index = try table.indexOrPut(gpa, "hello");
    try std.testing.expectEqual(@as(Index, 0), hello_index);

    try std.testing.expectEqual(@as(Index, 6), try table.indexOrPut(gpa, "world"));
    try std.testing.expectEqual(@as(Index, 12), try table.indexOrPut(gpa, "foo"));
    try std.testing.expectEqual(@as(Index, 16), try table.indexOrPut(gpa, "bar"));
    try std.testing.expectEqual(@as(Index, 20), try table.indexOrPut(gpa, "baz"));

    // index 0 -> "hello"
    try std.testing.expectEqualStrings("hello", table.string(hello_index));

    // Lookup "hello" -> index 0
    try std.testing.expectEqual(hello_index, table.index("hello").?);

    // Lookup "foobar" -> null
    try std.testing.expectEqual(@as(?Index, null), table.index("foobar"));
}
