const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const testing = std.testing;
const builtin = @import("builtin");
const assert = std.debug.assert;

/// An entity ID uniquely identifies an entity globally within an Entities set.
pub const EntityID = u64;

/// Represents the storage for a single type of component within a single type of entity.
///
/// Database equivalent: a column within a table.
pub fn ComponentStorage(comptime Component: type) type {
    return struct {
        /// A reference to the total number of entities with the same type as is being stored here.
        total_rows: *usize,

        /// The actual component data. This starts as empty, and then based on the first call to
        /// .set() or .setDense() is initialized as dense storage (an array) or sparse storage (a
        /// hashmap.)
        ///
        /// Sparse storage may turn to dense storage if someone later calls .set(), see that method
        /// for details.
        data: std.ArrayListUnmanaged(Component) = .{},

        const Self = @This();

        pub fn deinit(storage: *Self, allocator: Allocator) void {
            storage.data.deinit(allocator);
        }

        // If the storage of this component is sparse, it is turned dense as calling this method
        // indicates that the caller expects to set this component for most entities rather than
        // sparsely.
        pub fn set(storage: *Self, allocator: Allocator, row_index: u32, component: Component) !void {
            if (storage.data.items.len <= row_index) try storage.data.appendNTimes(allocator, undefined, storage.data.items.len + 1 - row_index);
            storage.data.items[row_index] = component;
        }

        /// Removes the given row index.
        pub fn remove(storage: *Self, row_index: u32) void {
            if (storage.data.items.len > row_index) {
                _ = storage.data.swapRemove(row_index);
            }
        }

        /// Gets the component value for the given entity ID.
        pub inline fn get(storage: Self, row_index: u32) Component {
            return storage.data.items[row_index];
        }

        pub inline fn copy(dst: *Self, allocator: Allocator, src_row: u32, dst_row: u32, src: *Self) !void {
            try dst.set(allocator, dst_row, src.get(src_row));
        }

        pub inline fn copySparse(dst: *Self, allocator: Allocator, src_row: u32, dst_row: u32, src: *Self) !void {
            // TODO: setSparse!
            try dst.set(allocator, dst_row, src.get(src_row));
        }
    };
}

/// A type-erased representation of ComponentStorage(T) (where T is unknown).
///
/// This is useful as it allows us to store all of the typed ComponentStorage as values in a hashmap
/// despite having different types, and allows us to still deinitialize them without knowing the
/// underlying type.
pub const ErasedComponentStorage = struct {
    ptr: *anyopaque,
    deinit: fn (erased: *anyopaque, allocator: Allocator) void,
    remove: fn (erased: *anyopaque, row: u32) void,
    cloneType: fn (erased: ErasedComponentStorage, total_entities: *usize, allocator: Allocator, retval: *ErasedComponentStorage) error{OutOfMemory}!void,
    copy: fn (dst_erased: *anyopaque, allocator: Allocator, src_row: u32, dst_row: u32, src_erased: *anyopaque) error{OutOfMemory}!void,
    copySparse: fn (dst_erased: *anyopaque, allocator: Allocator, src_row: u32, dst_row: u32, src_erased: *anyopaque) error{OutOfMemory}!void,

    pub fn cast(ptr: *anyopaque, comptime Component: type) *ComponentStorage(Component) {
        var aligned = @alignCast(@alignOf(*ComponentStorage(Component)), ptr);
        return @ptrCast(*ComponentStorage(Component), aligned);
    }
};

/// Represents a single archetype, that is, entities which have the same exact set of component
/// types. When a component is added or removed from an entity, it's archetype changes.
///
/// Database equivalent: a table where rows are entities and columns are components (dense storage).
pub const ArchetypeStorage = struct {
    allocator: Allocator,

    /// The hash of every component name in this archetype, i.e. the name of this archetype.
    hash: u64,

    /// A mapping of rows in the table to entity IDs.
    ///
    /// Doubles as the counter of total number of rows that have been reserved within this
    /// archetype table.
    entity_ids: std.ArrayListUnmanaged(EntityID) = .{},

    /// A string hashmap of component_name -> type-erased *ComponentStorage(Component)
    components: std.StringArrayHashMapUnmanaged(ErasedComponentStorage),

    /// Calculates the storage.hash value. This is a hash of all the component names, and can
    /// effectively be used to uniquely identify this table within the database.
    pub fn calculateHash(storage: *ArchetypeStorage) void {
        storage.hash = 0;
        var iter = storage.components.iterator();
        while (iter.next()) |entry| {
            const component_name = entry.key_ptr.*;
            storage.hash ^= std.hash_map.hashString(component_name);
        }
    }

    pub fn deinit(storage: *ArchetypeStorage) void {
        for (storage.components.values()) |erased| {
            erased.deinit(erased.ptr, storage.allocator);
        }
        storage.entity_ids.deinit(storage.allocator);
        storage.components.deinit(storage.allocator);
    }

    /// New reserves a row for storing an entity within this archetype table.
    pub fn new(storage: *ArchetypeStorage, entity: EntityID) !u32 {
        // Return a new row index
        const new_row_index = storage.entity_ids.items.len;
        try storage.entity_ids.append(storage.allocator, entity);
        return @intCast(u32, new_row_index);
    }

    /// Undoes the last call to the new() operation, effectively unreserving the row that was last
    /// reserved.
    pub fn undoNew(storage: *ArchetypeStorage) void {
        _ = storage.entity_ids.pop();
    }

    /// Sets the value of the named component (column) for the given row in the table. Realizes the
    /// deferred allocation of column storage for N entities (storage.counter) if it is not already.
    pub fn set(storage: *ArchetypeStorage, row_index: u32, name: []const u8, component: anytype) !void {
        var component_storage_erased = storage.components.get(name).?;
        var component_storage = ErasedComponentStorage.cast(component_storage_erased.ptr, @TypeOf(component));
        try component_storage.set(storage.allocator, row_index, component);
    }

    /// Removes the specified row. See also the `Entity.delete()` helper.
    ///
    /// This merely marks the row as removed, the same row index will be recycled the next time a
    /// new row is requested via `new()`.
    pub fn remove(storage: *ArchetypeStorage, row_index: u32) !void {
        _ = storage.entity_ids.swapRemove(row_index);
        for (storage.components.values()) |component_storage| {
            component_storage.remove(component_storage.ptr, row_index);
        }
    }

    /// The number of entities actively stored in this table (not counting entities which are
    /// allocated in this table but have been removed)
    pub fn count(storage: *ArchetypeStorage) usize {
        return storage.entity_ids.items.len;
    }

    /// Tells if this archetype has every one of the given components.
    pub fn hasComponents(storage: *ArchetypeStorage, components: []const []const u8) bool {
        for (components) |component_name| {
            if (!storage.components.contains(component_name)) return false;
        }
        return true;
    }
};

pub const void_archetype_hash = std.math.maxInt(u64);

/// A database of entities. For example, all player, monster, etc. entities in a game world.
///
/// ```
/// const world = Entities.init(allocator); // all entities in our world.
/// defer world.deinit();
///
/// const player1 = world.new(); // our first "player" entity
/// const player2 = world.new(); // our second "player" entity
/// ```
///
/// Entities are divided into archetypes for optimal, CPU cache efficient storage. For example, all
/// entities with two components `Location` and `Name` are stored in the same table dedicated to
/// densely storing `(Location, Name)` rows in contiguous memory. This not only ensures CPU cache
/// efficiency (leveraging data oriented design) which improves iteration speed over entities for
/// example, but makes queries like "find all entities with a Location component" ridiculously fast
/// because one need only find the tables which have a column for storing Location components and it
/// is then guaranteed every entity in the table has that component (entities do not need to be
/// checked one by one to determine if they have a Location component.)
///
/// Components can be added and removed to entities at runtime as you please:
///
/// ```
/// try player1.set("rotation", Rotation{ .degrees = 90 });
/// try player1.remove("rotation");
/// ```
///
/// When getting a component value, you must know it's type or undefined behavior will occur:
/// TODO: improve this!
///
/// ```
/// if (player1.get("rotation", Rotation)) |rotation| {
///     // player1 had a rotation component!
/// }
/// ```
///
/// When a component is added or removed from an entity, it's archetype is said to change. For
/// example player1 may have had the archetype `(Location, Name)` before, and after adding the
/// rotation component has the archetype `(Location, Name, Rotation)`. It will be automagically
/// "moved" from the table that stores entities with `(Location, Name)` components to the table that
/// stores `(Location, Name, Rotation)` components for you.
///
/// You can have 65,535 archetypes in total, and 4,294,967,295 entities total. Entities which are
/// deleted are merely marked as "unused" and recycled
///
/// Database equivalents:
/// * Entities is a database of tables, where each table represents a single archetype.
/// * ArchetypeStorage is a table, whose rows are entities and columns are components.
/// * EntityID is a mere 32-bit array index, pointing to a 16-bit archetype table index and 32-bit
///   row index, enabling entities to "move" from one archetype table to another seamlessly and
///   making lookup by entity ID a few cheap array indexing operations.
/// * ComponentStorage(T) is a column of data within a table for a single type of component `T`.
pub const Entities = struct {
    allocator: Allocator,

    /// TODO!
    counter: EntityID = 0,

    /// A mapping of entity IDs (array indices) to where an entity's component values are actually
    /// stored.
    entities: std.AutoHashMapUnmanaged(EntityID, Pointer) = .{},

    /// A mapping of archetype hash to their storage.
    ///
    /// Database equivalent: table name -> tables representing entities.
    archetypes: std.AutoArrayHashMapUnmanaged(u64, ArchetypeStorage) = .{},

    /// Points to where an entity is stored, specifically in which archetype table and in which row
    /// of that table. That is, the entity's component values are stored at:
    ///
    /// ```
    /// Entities.archetypes[ptr.archetype_index].rows[ptr.row_index]
    /// ```
    ///
    pub const Pointer = struct {
        archetype_index: u16,
        row_index: u32,
    };

    pub const Iterator = struct {
        entities: *Entities,
        components: []const []const u8,
        archetype_index: usize = 0,
        row_index: usize = 0,

        pub const Entry = struct {
            entity: EntityID,

            pub fn unlock(e: Entry) void {
                _ = e;
            }
        };

        pub fn next(iter: *Iterator) ?Entry {
            const entities = iter.entities;

            // If the archetype table we're looking at does not contain the components we're
            // querying for, keep searching through tables until we find one that does.
            var archetype = entities.archetypes.entries.get(iter.archetype_index).value;
            while (!archetype.hasComponents(iter.components) or iter.row_index >= archetype.count()) {
                iter.archetype_index += 1;
                iter.row_index = 0;
                if (iter.archetype_index >= entities.archetypes.count()) {
                    return null;
                }
                archetype = entities.archetypes.entries.get(iter.archetype_index).value;
            }

            const row_entity_id = archetype.entity_ids.items[iter.row_index];
            iter.row_index += 1;
            return Entry{ .entity = row_entity_id };
        }
    };

    pub fn query(entities: *Entities, components: []const []const u8) Iterator {
        return Iterator{
            .entities = entities,
            .components = components,
        };
    }

    pub fn init(allocator: Allocator) !Entities {
        var entities = Entities{ .allocator = allocator };

        try entities.archetypes.put(allocator, void_archetype_hash, ArchetypeStorage{
            .allocator = allocator,
            .components = .{},
            .hash = void_archetype_hash,
        });

        return entities;
    }

    pub fn deinit(entities: *Entities) void {
        entities.entities.deinit(entities.allocator);

        var iter = entities.archetypes.iterator();
        while (iter.next()) |entry| {
            entry.value_ptr.deinit();
        }
        entities.archetypes.deinit(entities.allocator);
    }

    /// Returns a new entity.
    pub fn new(entities: *Entities) !EntityID {
        const new_id = entities.counter;
        entities.counter += 1;

        var void_archetype = entities.archetypes.getPtr(void_archetype_hash).?;
        const new_row = try void_archetype.new(new_id);
        const void_pointer = Pointer{
            .archetype_index = 0, // void archetype is guaranteed to be first index
            .row_index = new_row,
        };

        entities.entities.put(entities.allocator, new_id, void_pointer) catch |err| {
            void_archetype.undoNew();
            return err;
        };
        return new_id;
    }

    /// Removes an entity.
    pub fn remove(entities: *Entities, entity: EntityID) !void {
        var archetype = entities.archetypeByID(entity);
        const ptr = entities.entities.get(entity).?;

        // A swap removal will be performed, update the entity stored in the last row of the
        // archetype table to point to the row the entity we are removing is currently located.
        const last_row_entity_id = archetype.entity_ids.items[archetype.entity_ids.items.len - 1];
        try entities.entities.put(entities.allocator, last_row_entity_id, Pointer{
            .archetype_index = ptr.archetype_index,
            .row_index = ptr.row_index,
        });

        // Perform a swap removal to remove our entity from the archetype table.
        try archetype.remove(ptr.row_index);

        _ = entities.entities.remove(entity);
    }

    /// Returns the archetype storage for the given entity.
    pub inline fn archetypeByID(entities: *Entities, entity: EntityID) *ArchetypeStorage {
        const ptr = entities.entities.get(entity).?;
        return &entities.archetypes.values()[ptr.archetype_index];
    }

    /// Sets the named component to the specified value for the given entity,
    /// moving the entity from it's current archetype table to the new archetype
    /// table if required.
    pub fn setComponent(entities: *Entities, entity: EntityID, name: []const u8, component: anytype) !void {
        var archetype = entities.archetypeByID(entity);

        // Determine the old hash for the archetype.
        const old_hash = archetype.hash;

        // Determine the new hash for the archetype + new component
        var have_already = archetype.components.contains(name);
        const new_hash = if (have_already) old_hash else old_hash ^ std.hash_map.hashString(name);

        // Find the archetype storage for this entity. Could be a new archetype storage table (if a
        // new component was added), or the same archetype storage table (if just updating the
        // value of a component.)
        var archetype_entry = try entities.archetypes.getOrPut(entities.allocator, new_hash);
        if (!archetype_entry.found_existing) {
            archetype_entry.value_ptr.* = ArchetypeStorage{
                .allocator = entities.allocator,
                .components = .{},
                .hash = 0,
            };
            var new_archetype = archetype_entry.value_ptr;

            // Create storage/columns for all of the existing components on the entity.
            var column_iter = archetype.components.iterator();
            while (column_iter.next()) |entry| {
                var erased: ErasedComponentStorage = undefined;
                entry.value_ptr.cloneType(entry.value_ptr.*, &new_archetype.entity_ids.items.len, entities.allocator, &erased) catch |err| {
                    assert(entities.archetypes.swapRemove(new_hash));
                    return err;
                };
                new_archetype.components.put(entities.allocator, entry.key_ptr.*, erased) catch |err| {
                    assert(entities.archetypes.swapRemove(new_hash));
                    return err;
                };
            }

            // Create storage/column for the new component.
            const erased = entities.initErasedStorage(&new_archetype.entity_ids.items.len, @TypeOf(component)) catch |err| {
                assert(entities.archetypes.swapRemove(new_hash));
                return err;
            };
            new_archetype.components.put(entities.allocator, name, erased) catch |err| {
                assert(entities.archetypes.swapRemove(new_hash));
                return err;
            };

            new_archetype.calculateHash();
        }

        // Either new storage (if the entity moved between storage tables due to having a new
        // component) or the prior storage (if the entity already had the component and it's value
        // is merely being updated.)
        var current_archetype_storage = archetype_entry.value_ptr;

        if (new_hash == old_hash) {
            // Update the value of the existing component of the entity.
            const ptr = entities.entities.get(entity).?;
            try current_archetype_storage.set(ptr.row_index, name, component);
            return;
        }

        // Copy to all component values for our entity from the old archetype storage
        // (archetype) to the new one (current_archetype_storage).
        const new_row = try current_archetype_storage.new(entity);
        const old_ptr = entities.entities.get(entity).?;

        // Update the storage/columns for all of the existing components on the entity.
        var column_iter = archetype.components.iterator();
        while (column_iter.next()) |entry| {
            var old_component_storage = entry.value_ptr;
            var new_component_storage = current_archetype_storage.components.get(entry.key_ptr.*).?;
            new_component_storage.copy(new_component_storage.ptr, entities.allocator, new_row, old_ptr.row_index, old_component_storage.ptr) catch |err| {
                current_archetype_storage.undoNew();
                return err;
            };
        }
        current_archetype_storage.entity_ids.items[new_row] = entity;

        // Update the storage/column for the new component.
        current_archetype_storage.set(new_row, name, component) catch |err| {
            current_archetype_storage.undoNew();
            return err;
        };

        var swapped_entity_id = archetype.entity_ids.items[archetype.entity_ids.items.len - 1];
        archetype.remove(old_ptr.row_index) catch |err| {
            current_archetype_storage.undoNew();
            return err;
        };
        try entities.entities.put(entities.allocator, swapped_entity_id, old_ptr);

        try entities.entities.put(entities.allocator, entity, Pointer{
            .archetype_index = @intCast(u16, archetype_entry.index),
            .row_index = new_row,
        });
        return;
    }

    /// gets the named component of the given type (which must be correct, otherwise undefined
    /// behavior will occur). Returns null if the component does not exist on the entity.
    pub fn getComponent(entities: *Entities, entity: EntityID, name: []const u8, comptime Component: type) ?Component {
        var archetype = entities.archetypeByID(entity);

        var component_storage_erased = archetype.components.get(name) orelse return null;

        const ptr = entities.entities.get(entity).?;
        var component_storage = ErasedComponentStorage.cast(component_storage_erased.ptr, Component);
        return component_storage.get(ptr.row_index);
    }

    /// Removes the named component from the entity, or noop if it doesn't have such a component.
    pub fn removeComponent(entities: *Entities, entity: EntityID, name: []const u8) !void {
        var archetype = entities.archetypeByID(entity);
        if (!archetype.components.contains(name)) return;

        // Determine the old hash for the archetype.
        const old_hash = archetype.hash;

        // Determine the new hash for the archetype with the component removed
        var new_hash: u64 = 0;
        var iter = archetype.components.iterator();
        while (iter.next()) |entry| {
            const component_name = entry.key_ptr.*;
            if (!std.mem.eql(u8, component_name, name)) new_hash ^= std.hash_map.hashString(component_name);
        }
        assert(new_hash != old_hash);

        // Find the archetype storage for this entity. Could be a new archetype storage table (if a
        // new component was added), or the same archetype storage table (if just updating the
        // value of a component.)
        var archetype_entry = try entities.archetypes.getOrPut(entities.allocator, new_hash);
        if (!archetype_entry.found_existing) {
            archetype_entry.value_ptr.* = ArchetypeStorage{
                .allocator = entities.allocator,
                .components = .{},
                .hash = 0,
            };
            var new_archetype = archetype_entry.value_ptr;

            // Create storage/columns for all of the existing components on the entity.
            var column_iter = archetype.components.iterator();
            while (column_iter.next()) |entry| {
                if (std.mem.eql(u8, entry.key_ptr.*, name)) continue;
                var erased: ErasedComponentStorage = undefined;
                entry.value_ptr.cloneType(entry.value_ptr.*, &new_archetype.entity_ids.items.len, entities.allocator, &erased) catch |err| {
                    assert(entities.archetypes.swapRemove(new_hash));
                    return err;
                };
                new_archetype.components.put(entities.allocator, entry.key_ptr.*, erased) catch |err| {
                    assert(entities.archetypes.swapRemove(new_hash));
                    return err;
                };
            }
            new_archetype.calculateHash();
        }

        // Either new storage (if the entity moved between storage tables due to having a new
        // component) or the prior storage (if the entity already had the component and it's value
        // is merely being updated.)
        var current_archetype_storage = archetype_entry.value_ptr;

        // Copy to all component values for our entity from the old archetype storage
        // (archetype) to the new one (current_archetype_storage).
        const new_row = try current_archetype_storage.new(entity);
        const old_ptr = entities.entities.get(entity).?;

        // Update the storage/columns for all of the existing components on the entity.
        var column_iter = current_archetype_storage.components.iterator();
        while (column_iter.next()) |entry| {
            var src_component_storage = archetype.components.get(entry.key_ptr.*).?;
            var dst_component_storage = entry.value_ptr;
            dst_component_storage.copy(dst_component_storage.ptr, entities.allocator, new_row, old_ptr.row_index, src_component_storage.ptr) catch |err| {
                current_archetype_storage.undoNew();
                return err;
            };
        }
        current_archetype_storage.entity_ids.items[new_row] = entity;

        var swapped_entity_id = archetype.entity_ids.items[archetype.entity_ids.items.len - 1];
        archetype.remove(old_ptr.row_index) catch |err| {
            current_archetype_storage.undoNew();
            return err;
        };
        try entities.entities.put(entities.allocator, swapped_entity_id, old_ptr);

        try entities.entities.put(entities.allocator, entity, Pointer{
            .archetype_index = @intCast(u16, archetype_entry.index),
            .row_index = new_row,
        });
        return;
    }

    // TODO: iteration over all entities
    // TODO: iteration over all entities with components (U, V, ...)
    // TODO: iteration over all entities with type T
    // TODO: iteration over all entities with type T and components (U, V, ...)

    // TODO: "indexes" - a few ideas we could express:
    //
    // * Graph relations index: e.g. parent-child entity relations for a DOM / UI / scene graph.
    // * Spatial index: "give me all entities within 5 units distance from (x, y, z)"
    // * Generic index: "give me all entities where arbitraryFunction(e) returns true"
    //

    pub fn initErasedStorage(entities: *const Entities, total_rows: *usize, comptime Component: type) !ErasedComponentStorage {
        var new_ptr = try entities.allocator.create(ComponentStorage(Component));
        new_ptr.* = ComponentStorage(Component){ .total_rows = total_rows };

        return ErasedComponentStorage{
            .ptr = new_ptr,
            .deinit = (struct {
                pub fn deinit(erased: *anyopaque, allocator: Allocator) void {
                    var ptr = ErasedComponentStorage.cast(erased, Component);
                    ptr.deinit(allocator);
                    allocator.destroy(ptr);
                }
            }).deinit,
            .remove = (struct {
                pub fn remove(erased: *anyopaque, row: u32) void {
                    var ptr = ErasedComponentStorage.cast(erased, Component);
                    ptr.remove(row);
                }
            }).remove,
            .cloneType = (struct {
                pub fn cloneType(erased: ErasedComponentStorage, _total_rows: *usize, allocator: Allocator, retval: *ErasedComponentStorage) !void {
                    var new_clone = try allocator.create(ComponentStorage(Component));
                    new_clone.* = ComponentStorage(Component){ .total_rows = _total_rows };
                    var tmp = erased;
                    tmp.ptr = new_clone;
                    retval.* = tmp;
                }
            }).cloneType,
            .copy = (struct {
                pub fn copy(dst_erased: *anyopaque, allocator: Allocator, src_row: u32, dst_row: u32, src_erased: *anyopaque) !void {
                    var dst = ErasedComponentStorage.cast(dst_erased, Component);
                    var src = ErasedComponentStorage.cast(src_erased, Component);
                    return dst.copy(allocator, src_row, dst_row, src);
                }
            }).copy,
            .copySparse = (struct {
                pub fn copySparse(dst_erased: *anyopaque, allocator: Allocator, src_row: u32, dst_row: u32, src_erased: *anyopaque) !void {
                    var dst = ErasedComponentStorage.cast(dst_erased, Component);
                    var src = ErasedComponentStorage.cast(src_erased, Component);
                    return dst.copySparse(allocator, src_row, dst_row, src);
                }
            }).copySparse,
        };
    }

    // TODO: ability to remove archetype entirely, deleting all entities in it
    // TODO: ability to remove archetypes with no entities (garbage collection)
};

test "entity ID size" {
    try testing.expectEqual(8, @sizeOf(EntityID));
}

test "example" {
    const allocator = testing.allocator;

    //-------------------------------------------------------------------------
    // Create a world.
    var world = try Entities.init(allocator);
    defer world.deinit();

    //-------------------------------------------------------------------------
    // Define component types, any Zig type will do!
    // A location component.
    const Location = struct {
        x: f32 = 0,
        y: f32 = 0,
        z: f32 = 0,
    };

    //-------------------------------------------------------------------------
    // Create first player entity.
    var player1 = try world.new();
    try world.setComponent(player1, "name", "jane"); // add Name component
    try world.setComponent(player1, "location", Location{}); // add Location component

    // Create second player entity.
    var player2 = try world.new();
    try testing.expect(world.getComponent(player2, "location", Location) == null);
    try testing.expect(world.getComponent(player2, "name", []const u8) == null);

    //-------------------------------------------------------------------------
    // We can add new components at will.
    const Rotation = struct { degrees: f32 };
    try world.setComponent(player2, "rotation", Rotation{ .degrees = 90 });
    try testing.expect(world.getComponent(player1, "rotation", Rotation) == null); // player1 has no rotation

    //-------------------------------------------------------------------------
    // Remove a component from any entity at will.
    // TODO: add a way to "cleanup" truly unused archetypes
    try world.removeComponent(player1, "name");
    try world.removeComponent(player1, "location");
    try world.removeComponent(player1, "location"); // doesn't exist? no problem.

    //-------------------------------------------------------------------------
    // Introspect things.
    //
    // Archetype IDs, these are our "table names" - they're just hashes of all the component names
    // within the archetype table.
    var archetypes = world.archetypes.keys();
    try testing.expectEqual(@as(usize, 6), archetypes.len);
    try testing.expectEqual(@as(u64, 18446744073709551615), archetypes[0]);
    try testing.expectEqual(@as(u64, 6893717443977936573), archetypes[1]);
    try testing.expectEqual(@as(u64, 7008573051677164842), archetypes[2]);
    try testing.expectEqual(@as(u64, 14420739110802803032), archetypes[3]);
    try testing.expectEqual(@as(u64, 13913849663823266920), archetypes[4]);
    try testing.expectEqual(@as(u64, 0), archetypes[5]);

    // Number of (living) entities stored in an archetype table.
    try testing.expectEqual(@as(usize, 0), world.archetypes.get(archetypes[2]).?.count());

    // Component names for a given archetype.
    var component_names = world.archetypes.get(archetypes[2]).?.components.keys();
    try testing.expectEqual(@as(usize, 2), component_names.len);
    try testing.expectEqualStrings("name", component_names[0]);
    try testing.expectEqualStrings("location", component_names[1]);

    // Component names for a given entity
    var player2_archetype = world.archetypeByID(player2);
    component_names = player2_archetype.components.keys();
    try testing.expectEqual(@as(usize, 1), component_names.len);
    try testing.expectEqualStrings("rotation", component_names[0]);

    // TODO: iterating components an entity has not currently supported.

    //-------------------------------------------------------------------------
    // Remove an entity whenever you wish. Just be sure not to try and use it later!
    try world.remove(player1);
}
