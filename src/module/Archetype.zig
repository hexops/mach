//! Represents a single archetype. i.e., entities which have a specific set of components. When a
//! component is added or removed from an entity, it's archetype changes because the archetype is
//! the set of components an entity has.
//!
//! Database equivalent: a table where rows are entities and columns are components (dense storage).

const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;
const assert = std.debug.assert;
const builtin = @import("builtin");

const is_debug = @import("../main.zig").is_debug;

const StringTable = @import("StringTable.zig");
const ComponentTypesByName = @import("module.zig").ComponentTypesByName;

const Archetype = @This();

/// Describes a single column of the archetype (table); i.e. a single type of component
pub const Column = struct {
    /// The unique name of the component this column stores.
    name: StringTable.Index,

    /// A unique identifier for the programming-language type this column stores. In the case of Zig
    /// this is a comptime type identifier. For other languages, it may be something else or simply
    /// zero if unused.
    ///
    /// This value need only uniquely identify the column type for the duration of a single build of
    /// the program.
    type_id: u32,

    /// The size of the component this column stores.
    size: u32,

    /// The alignment of the component type this column stores.
    alignment: u16,

    /// The actual memory where the values are stored. The length/capacity is Archetype.len and
    /// Archetype.capacity, as all columns in an Archetype have identical lengths/capacities.
    values: []u8,
};

/// The length of the table (in-use number of rows)
len: u32,

/// The capacity of the table (total allocated number of rows)
capacity: u32,

/// Describes the columns in this table. Each column stores all rows for that column.
columns: []Column,

/// A reference to the string table that can be used to identify Column.name's
component_names: *StringTable,

/// A hash composed of all Column.name's, effectively acting as the unique name of this table.
hash: u64,

/// An index to Database.archetypes, used in the event of a *bucket* hash collision (not a collision
/// of the .hash field) - see Database.archetypeOrPut for details.
next: ?u32 = null,

pub fn deinit(storage: *Archetype, gpa: Allocator) void {
    if (storage.capacity > 0) {
        for (storage.columns) |column| gpa.free(column.values);
    }
    gpa.free(storage.columns);
}

/// appends a new row to this table, with all undefined values.
pub fn appendUndefined(storage: *Archetype, gpa: Allocator) !u32 {
    try storage.ensureUnusedCapacity(gpa, 1);
    assert(storage.len < storage.capacity);
    const row_index = storage.len;
    storage.len += 1;
    return row_index;
}

pub fn undoAppend(storage: *Archetype) void {
    storage.len -= 1;
}

/// Ensures there is enough unused capacity to store `num_rows`.
pub fn ensureUnusedCapacity(storage: *Archetype, gpa: Allocator, num_rows: usize) !void {
    return storage.ensureTotalCapacity(gpa, storage.len + num_rows);
}

/// Ensures the total capacity is enough to store `new_capacity` rows total.
pub fn ensureTotalCapacity(storage: *Archetype, gpa: Allocator, new_capacity: usize) !void {
    var better_capacity = storage.capacity;
    if (better_capacity >= new_capacity) return;

    while (true) {
        better_capacity +|= better_capacity / 2 + 8;
        if (better_capacity >= new_capacity) break;
    }

    return storage.setCapacity(gpa, better_capacity);
}

const max_align_padding = 64;

/// Sets the capacity to exactly `new_capacity` rows total
///
/// Asserts `new_capacity >= storage.len`, if you want to shrink capacity then change the len
/// yourself first.
pub fn setCapacity(storage: *Archetype, gpa: Allocator, new_capacity: usize) !void {
    assert(new_capacity >= storage.len);

    // TODO: ensure columns are sorted by type_id
    for (storage.columns) |*column| {
        const old_values = column.values;
        const new_values = try gpa.alloc(u8, (new_capacity * column.size) + max_align_padding);
        if (storage.capacity > 0) {
            // Note: this copies alignment padding (which is fine, since it is a constant amount.)
            @memcpy(new_values[0..old_values.len], old_values);
            gpa.free(old_values);
        }
        column.values = new_values;
    }
    storage.capacity = @as(u32, @intCast(new_capacity));
}

/// Sets the value of the named components (columns) for the given row in the table.
pub fn set(storage: *Archetype, row_index: u32, name: StringTable.Index, component: anytype) void {
    const ColumnType = @TypeOf(component);
    if (@sizeOf(ColumnType) == 0) return;
    if (is_debug) debugAssertColumnType(storage, storage.columnByName(name).?, @TypeOf(component));
    storage.setDynamic(
        row_index,
        name,
        std.mem.asBytes(&component),
        @alignOf(@TypeOf(component)),
        typeId(@TypeOf(component)),
    );
}

pub fn setDynamic(storage: *Archetype, row_index: u32, name: StringTable.Index, component: []const u8, alignment: u16, type_id: u32) void {
    if (is_debug) {
        // TODO: improve error messages
        assert(storage.len != 0 and storage.len >= row_index);
        assert(storage.columnByName(name).?.type_id == type_id);
        assert(storage.columnByName(name).?.size == component.len);
        assert(storage.columnByName(name).?.alignment == alignment);
    }

    const values = storage.getColumnValuesRaw(name) orelse @panic("no such component");
    const start = component.len * row_index;
    @memcpy(values[start .. start + component.len], component);
}

pub fn get(storage: *Archetype, row_index: u32, name: StringTable.Index, comptime ColumnType: type) ?ColumnType {
    if (is_debug) debugAssertColumnType(storage, storage.columnByName(name) orelse return null, ColumnType);

    const bytes = storage.getDynamic(row_index, name, @sizeOf(ColumnType), @alignOf(ColumnType), typeId(ColumnType)) orelse return null;
    return @as(*ColumnType, @alignCast(@ptrCast(bytes.ptr))).*;
}

pub fn getDynamic(storage: *Archetype, row_index: u32, name: StringTable.Index, size: u32, alignment: u16, type_id: u32) ?[]u8 {
    const values = storage.getColumnValuesRaw(name) orelse return null;
    if (is_debug) {
        // TODO: improve error messages
        assert(storage.columnByName(name).?.size == size);
        assert(storage.columnByName(name).?.alignment == alignment);
        assert(storage.columnByName(name).?.type_id == type_id);
    }

    const start = size * row_index;
    const end = start + size;
    return values[start..end];
}

/// Swap-removes the specified row with the last row in the table.
pub fn remove(storage: *Archetype, row_index: u32) void {
    assert(row_index < storage.len);
    if (storage.len > 1 and row_index != storage.len - 1) {
        for (storage.columns) |column| {
            const aligned_values = storage.aligned(&column, column.values);
            const dstStart = column.size * row_index;
            const dst = aligned_values[dstStart .. dstStart + column.size];
            const srcStart = column.size * (storage.len - 1);
            const src = aligned_values[srcStart .. srcStart + column.size];
            @memcpy(dst, src);
        }
    }
    storage.len -= 1;
}

/// Tells if this archetype has every one of the given components.
pub fn hasComponents(storage: *Archetype, names: []const u32) bool {
    for (names) |name| {
        if (!storage.hasComponent(name)) return false;
    }
    return true;
}

/// Tells if this archetype has a component with the specified name.
pub fn hasComponent(storage: *Archetype, name: StringTable.Index) bool {
    return storage.columnByName(name) != null;
}

/// Given a column.values slice which is unaligned, adds the neccessary padding
/// to achieve alignment for the column's data type, and returns the padded slice.
inline fn aligned(storage: *Archetype, column: *const Column, values: []u8) []u8 {
    const aligned_addr = std.mem.alignForward(usize, @intFromPtr(values.ptr), column.alignment);
    if (is_debug) {
        const padding_bytes = aligned_addr - @as(usize, @intFromPtr(values.ptr));
        if (padding_bytes > max_align_padding) @panic("mach: max_align_padding is too low, this is a bug");
    }
    return @as([*]u8, @ptrFromInt(aligned_addr))[0 .. storage.capacity * column.size];
}

pub fn getColumnValues(storage: *Archetype, name: StringTable.Index, comptime ColumnType: type) ?[]ColumnType {
    const values = storage.getColumnValuesRaw(name) orelse return null;
    if (is_debug) debugAssertColumnType(storage, storage.columnByName(name).?, ColumnType);
    var ptr = @as([*]ColumnType, @ptrCast(@alignCast(values.ptr)));
    const column_values = ptr[0..storage.capacity];
    return column_values;
}

pub fn getColumnValuesRaw(storage: *Archetype, name: StringTable.Index) ?[]u8 {
    const column = storage.columnByName(name) orelse return null;
    return storage.aligned(column, column.values);
}

pub inline fn columnByName(storage: *Archetype, name: StringTable.Index) ?*Column {
    for (storage.columns) |*column| {
        if (column.name == name) return column;
    }
    return null;
}

pub fn debugPrint(storage: *Archetype) void {
    std.debug.print("Archetype hash={} len={} capacity={} columns={}\n", .{ storage.hash, storage.len, storage.capacity, storage.columns.len });
    for (storage.columns, 0..) |*column, i| {
        std.debug.print("{}. '{s}'\n", .{ i, storage.component_names.string(column.name) });
    }
}

/// Returns a unique comptime usize integer representing the type T. Value will change across
/// different compilations.
pub fn typeId(comptime T: type) u32 {
    _ = T;
    return @truncate(@intFromPtr(&struct {
        var x: u8 = 0;
    }.x));
}

/// Asserts that T matches the type of the column.
pub inline fn debugAssertColumnType(storage: *Archetype, column: *Archetype.Column, comptime T: type) void {
    if (is_debug) {
        if (typeId(T) != column.type_id) std.debug.panic("unexpected type: {s} expected: {s}", .{
            @typeName(T),
            storage.component_names.string(column.name),
        });
    }
}

/// Asserts that a tuple `row` to be e.g. appended to an archetype has values that actually match
/// all of the columns of the archetype table.
pub inline fn debugAssertRowType(storage: *Archetype, row: anytype) void {
    if (is_debug) {
        inline for (std.meta.fields(@TypeOf(row)), 0..) |field, index| {
            debugAssertColumnType(storage, &storage.columns[index], field.type);
        }
    }
}
