//! mach/ecs is an Entity component system implementation.
//!
//! ## Design principles:
//!
//! * Clean-room implementation (author has not read any other ECS implementation code.)
//! * Solve the problems ECS solves, in a way that is natural to Zig and leverages Zig comptime.
//! * Avoid patent infringement upon Unity ECS patent claims.
//! * Fast. Optimal for CPU caches, multi-threaded, leverage comptime as much as is reasonable.
//! * Simple. Small API footprint, should be natural and fun - not like you're writing boilerplate.
//! * Enable other libraries to provide tracing, editors, visualizers, profilers, etc.
//!
//! ## Copyright & patent mitigation
//!
//! The initial implementation was a clean-room implementation by Stephen Gutekanst without having
//! read other ECS implementations' code, but with speaking to people familiar with other ECS
//! implementations. Contributions past the initial implementation may be made by individuals in
//! non-clean-room settings.
//!
//! Critically, this entity component system stores components for a classified archetype using
//! independent arrays allocated per component as well as hashmaps for sparse component data as an
//! optimization. This is a novel and fundamentally different process than what is described in
//! Unity Software Inc's patent US 10,599,560. This is not legal advice.
//!
const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const testing = std.testing;
const builtin = @import("builtin");
const assert = std.debug.assert;

/// An entity ID uniquely identifies an entity globally within an Entities set.
///
/// It stores the type of entity, as well the index of the entity within EntityTypeStorage, in only
/// 48 bits.
///
/// Database equivalent: a row within a table
pub const EntityID = packed struct {
    /// Entity type ("table ID")
    type_id: u16,

    /// Entity ID ("row index")
    id: u32,
};

/// Entity is a thin wrapper over an entity ID that makes interacting with a specific entity nicer.
///
/// Database equivalent: a row within a table
pub const Entity = struct {
    /// The ID of the entity.
    id: EntityID,

    /// The entity type corresponding to id.type_id. You can look this up using Entities.byID()
    ///
    /// Database equivalent: table of entities
    entity_type: *EntityTypeStorage,

    /// Adds or updates a component for this entity.
    ///
    /// Optimized for *most* entities (of this type) having this type of component. If only a few
    /// entities will have it, use `.setSparse()` instead.
    pub inline fn set(entity: Entity, name: []const u8, component: anytype) !void {
        var entity_type = entity.entity_type;
        var storage = try entity_type.get(name, @TypeOf(component));
        try storage.set(entity_type.allocator, entity.id.id, component);
    }

    /// Adds or updates a component for this entity.
    ///
    /// Optimized for *few* entities (of this type) having this type of component. If most entities
    /// will have it, use `.set()` instead.
    pub inline fn setSparse(entity: Entity, component_name: []const u8, component: anytype) !void {
        var entity_type = entity.entity_type;
        var storage = try entity_type.get(component_name, @TypeOf(component));
        try storage.setSparse(entity_type.allocator, entity.id.id, component);
    }

    /// Gets a component for this entity, returns null if that component is not set on this entity.
    pub inline fn get(entity: Entity, component_name: []const u8, comptime Component: anytype) ?Component {
        var entity_type = entity.entity_type;
        var storage = entity_type.getIfExists(component_name, Component) orelse return null;
        return storage.get(entity.id.id);
    }

    /// Removes the given component from this entity, returning a boolean indicating if it did
    /// exist on the entity.
    pub inline fn remove(entity: Entity, component_name: []const u8) bool {
        var entity_type = entity.entity_type;
        var storage = entity_type.getErasedIfExists(component_name) orelse return false;
        return storage.remove(storage.ptr, entity.id.id);
    }

    // Deletes this entity.
    pub inline fn delete(entity: Entity) !void {
        var entity_type = entity.entity_type;
        try entity_type.delete(entity.id);
    }

    // TODO: iterator over all components for the entity
};

/// Represents the storage for a single type of component within a single type of entity.
///
/// Database equivalent: a column within a table.
pub fn ComponentStorage(comptime Component: type) type {
    return struct {
        /// A reference to the total number of entities with the same type as is being stored here.
        total_entities: *u32,

        /// The actual component data. This starts as empty, and then based on the first call to
        /// .set() or .setDense() is initialized as dense storage (an array) or sparse storage (a
        /// hashmap.)
        ///
        /// Sparse storage may turn to dense storage if someone later calls .set(), see that method
        /// for details.
        data: union(StorageType) {
            empty: void,
            dense: std.ArrayListUnmanaged(?Component),
            sparse: std.AutoArrayHashMapUnmanaged(u32, Component),
        } = .{ .empty = {} },

        pub const StorageType = enum {
            empty,
            dense,
            sparse,
        };

        const Self = @This();

        pub fn deinit(storage: *Self, allocator: Allocator) void {
            switch (storage.data) {
                .empty => {},
                .dense => storage.data.dense.deinit(allocator),
                .sparse => storage.data.sparse.deinit(allocator),
            }
        }

        // If the storage of this component is sparse, it is turned dense as calling this method
        // indicates that the caller expects to set this component for most entities rather than
        // sparsely.
        pub fn set(storage: *Self, allocator: Allocator, row: u32, component: ?Component) !void {
            switch (storage.data) {
                .empty => if (component) |c| {
                    var new_dense = std.ArrayListUnmanaged(?Component){};
                    try new_dense.ensureTotalCapacityPrecise(allocator, storage.total_entities.*);
                    try new_dense.appendNTimes(allocator, null, storage.total_entities.*);
                    new_dense.items[row] = c;
                    storage.data = .{ .dense = new_dense };
                } else return,
                .dense => |dense| {
                    if (dense.items.len >= row) try storage.data.dense.appendNTimes(allocator, null, dense.items.len + 1 - row);
                    dense.items[row] = component;
                },
                .sparse => |sparse| {
                    // Turn sparse storage into dense storage.
                    defer storage.data.sparse.deinit(allocator);

                    var new_dense = std.ArrayListUnmanaged(?Component){};
                    try new_dense.ensureTotalCapacityPrecise(allocator, storage.total_entities.*);
                    var i: u32 = 0;
                    while (i < storage.total_entities.*) : (i += 1) {
                        new_dense.appendAssumeCapacity(sparse.get(i));
                    }
                    new_dense.items[row] = component;
                    storage.data = .{ .dense = new_dense };
                },
            }
        }

        // If the storage of this component is dense, it remains dense.
        pub fn setSparse(storage: *Self, allocator: Allocator, row: u32, component: ?Component) !void {
            switch (storage.data) {
                .empty => if (component) |c| {
                    var new_sparse = std.AutoArrayHashMapUnmanaged(u32, Component){};
                    try new_sparse.put(allocator, row, c);
                    storage.data = .{ .sparse = new_sparse };
                } else return,
                .dense => |dense| {
                    if (dense.items.len >= row) try storage.data.dense.appendNTimes(allocator, null, dense.items.len + 1 - row);
                    dense.items[row] = component;
                },
                .sparse => if (component) |c| try storage.data.sparse.put(allocator, row, c) else {
                    _ = storage.data.sparse.swapRemove(row);
                },
            }
        }

        /// Removes the given entity ID.
        pub fn remove(storage: *Self, row: u32) bool {
            return switch (storage.data) {
                .empty => false,
                .dense => |dense| if (dense.items.len > row and dense.items[row] != null) {
                    dense.items[row] = null;
                    return true;
                } else false,
                .sparse => storage.data.sparse.swapRemove(row),
            };
        }

        /// Gets the component value for the given entity ID.
        pub inline fn get(storage: Self, row: u32) ?Component {
            return switch (storage.data) {
                .empty => null,
                .dense => |dense| if (dense.items.len > row) dense.items[row] else null,
                .sparse => |sparse| sparse.get(row),
            };
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
    remove: fn (erased: *anyopaque, row: u32) bool,

    pub fn cast(ptr: *anyopaque, comptime Component: type) *ComponentStorage(Component) {
        var aligned = @alignCast(@alignOf(*ComponentStorage(Component)), ptr);
        return @ptrCast(*ComponentStorage(Component), aligned);
    }
};

/// Represents a single type of entity, e.g. a player, monster, or some other arbitrary entity type.
///
/// See the `Entities` documentation for more information about entity types and how they enable
/// performance.
///
/// Database equivalent: a table where rows are entities and columns are components (dense storage)
/// or a secondary table with entity ID -> component value relations (sparse storage.)
pub const EntityTypeStorage = struct {
    allocator: Allocator,

    /// This entity type storage identifier. This is used to uniquely identify this entity type
    /// within the global set of Entities, and is identical to the EntityID.type_id value.
    id: u16,

    /// The number of entities that have been allocated within this entity type. This is identical
    /// to the EntityID.id value.
    count: u32 = 0,

    /// A string hashmap of component_name -> type-erased *ComponentStorage(Component)
    components: std.StringArrayHashMapUnmanaged(ErasedComponentStorage) = .{},

    /// Free entity slots. When an entity is deleted, it is added to this map and recycled the next
    /// time a new entity is requested.
    free_slots: std.AutoArrayHashMapUnmanaged(u32, void) = .{},

    pub fn init(allocator: Allocator, type_id: u16) EntityTypeStorage {
        return .{
            .allocator = allocator,
            .id = type_id,
        };
    }

    pub fn deinit(storage: *EntityTypeStorage) void {
        for (storage.components.values()) |erased| {
            erased.deinit(erased.ptr, storage.allocator);
        }
        storage.components.deinit(storage.allocator);
        storage.free_slots.deinit(storage.allocator);
    }

    /// Creates a new entity of this type.
    pub fn new(storage: *EntityTypeStorage) !Entity {
        return Entity{
            .id = try storage.newID(),
            .entity_type = storage,
        };
    }

    // TODO: bulk allocation of entities

    /// Creates a new entity of this type.
    pub fn newID(storage: *EntityTypeStorage) !EntityID {
        // If there is a previously deleted entity, recycle it's ID.
        // TODO: add some "debug" mode which catches use-after-delete of entities (could be super
        // confusing if one system deletes it and another creates it and you don't notice!)
        const free_slot = storage.free_slots.popOrNull();
        if (free_slot) |recycled| return EntityID{ .type_id = storage.id, .id = recycled.key };

        // Create a new entity ID and space to store it in each component array.
        const new_id = storage.count;
        storage.count += 1;
        return EntityID{ .type_id = storage.id, .id = new_id };
    }

    /// Deletes the specified entity. See also the `Entity.delete()` helper.
    ///
    /// This merely marks the entity as deleted, the same ID will be recycled the next time a new
    /// entity is created.
    pub fn delete(storage: *EntityTypeStorage, id: EntityID) !void {
        assert(id.type_id == storage.id);
        try storage.free_slots.put(storage.allocator, id.id, .{});
    }

    /// Returns the component storage for the given component. Creates storage for this type of
    /// component if it does not exist.
    ///
    /// Note: This is a low-level API, you probably want to use `Entity.get()` instead.
    pub fn get(storage: *EntityTypeStorage, component_name: []const u8, comptime Component: type) !*ComponentStorage(Component) {
        var v = try storage.components.getOrPut(storage.allocator, component_name);
        if (!v.found_existing) {
            var new_ptr = try storage.allocator.create(ComponentStorage(Component));
            new_ptr.* = ComponentStorage(Component){
                .total_entities = &storage.count,
            };

            v.value_ptr.* = ErasedComponentStorage{
                .ptr = new_ptr,
                .deinit = (struct {
                    pub fn deinit(erased: *anyopaque, allocator: Allocator) void {
                        var ptr = ErasedComponentStorage.cast(erased, Component);
                        ptr.deinit(allocator);
                        allocator.destroy(ptr);
                    }
                }).deinit,
                .remove = (struct {
                    pub fn remove(erased: *anyopaque, row: u32) bool {
                        var ptr = ErasedComponentStorage.cast(erased, Component);
                        return ptr.remove(row);
                    }
                }).remove,
            };
        }
        return ErasedComponentStorage.cast(v.value_ptr.ptr, Component);
    }

    /// Returns the component storage for the given component, returning null if it does not exist.
    ///
    /// Note: This is a low-level API, you probably want to use `Entity.get()` instead.
    pub fn getIfExists(storage: *EntityTypeStorage, component_name: []const u8, comptime Component: type) ?*ComponentStorage(Component) {
        var v = storage.components.get(component_name);
        if (v == null) return null;
        return ErasedComponentStorage.cast(v.?.ptr, Component);
    }

    /// Returns the type-erased component storage for the given component, returning null if it does
    /// not exist.
    ///
    /// Note: This is a low-level API, you probably want to use `Entity.get()` instead.
    pub inline fn getErasedIfExists(storage: *EntityTypeStorage, component_name: []const u8) ?ErasedComponentStorage {
        return storage.components.get(component_name);
    }
};

/// A database of entities. For example, all player, monster, etc. entities in a game world.
///
/// Entities are divided into "entity types", arbitrary named groups of entities that are likely to
/// have the same components. If you are used to archetypes from other ECS systems, know that these
/// are NOT the same as archetypes: you can add or remove components from an entity type at will
/// without getting a new type of entity. You can get an entity type using e.g.:
///
/// ```
/// const world = Entities.init(allocator); // all entities in our world
/// const players = world.get("player"); // the player entities
///
/// const player1 = players.new(); // a new entity of type "player"
/// const player2 = players.new(); // a new entity of type "player"
/// ```
///
/// Storage is optimized around the idea that all entities of the same type *generally* have the
/// same type of components. Storing entities by type also enables quickly iterating over all
/// entities with some logical type without any sorting needed (e.g. iterating over all "player"
/// entities but not "monster" entities.) This also reduces the search area for more complex queries
/// and makes filtering entities by e.g. "all entities with a Renderer component" more efficient
/// as we just *know* that if player1 has that component, then player2 almost certainly does too.
///
/// You can have 65,535 entity types in total.
///
/// Although storage is *generally* optimized for all entities within a given type having the same
/// components, you may set/remove components on an entity at will via e.g. `player1.set(component)`
/// and `player1.remove(Component)`. `player1` and `player2` may not both have a Renderer component,
/// for example.
///
/// If you use `player1.set(myRenderer);` then dense storage will be used: we will optimize for
/// *every* entity of type "player" having a Renderer component. In this case, every "player" entity
/// will pay the cost of storing a Renderer component even if they do not have one.
///
/// If you use `player1.setSparse(myRenderer);` then sparse storage will be used: we will optimize
/// for *most* entities of type "player" not having a Renderer component. In this case, only the
/// "player" entities which have a Renderer component pay a storage cost. If most entities have a
/// Renderer component, this would be the wrong type of storage and less efficient.
///
/// Database equivalents:
/// * Entities is a database of tables, where each table represents a type of entity.
/// * EntityTypeStorage is a table, whose rows are entities.
/// * EntityID is a 32-bit row ID and a 16-bit table ID, and so globally unique.
/// * ComponentStorage(T) is a column of data in a table for a specific component type
///     * Densely stored as an array of component values.
///     * Sparsely stored as a map of (row ID -> component value).
pub const Entities = struct {
    allocator: Allocator,

    /// A mapping of entity type names to their storage.
    ///
    /// Database equivalent: table name -> tables representing entities.
    types: std.StringArrayHashMapUnmanaged(EntityTypeStorage),

    pub fn init(allocator: Allocator) Entities {
        return .{
            .allocator = allocator,
            .types = std.StringArrayHashMapUnmanaged(EntityTypeStorage){},
        };
    }

    pub fn deinit(entities: *Entities) void {
        var iter = entities.types.iterator();
        while (iter.next()) |entry| {
            entry.value_ptr.deinit();
        }
        entities.types.deinit(entities.allocator);
    }

    // TODO: iteration over all entities
    // TODO: iteration over all entities with components (U, V, ...)
    // TODO: iteration over all entities with type T
    // TODO: iteration over all entities with type T and components (U, V, ...)

    // TODO: "indexes" - a few ideas we could express either within a single entity type or across
    // all entities:
    //
    // * Graph relations index: e.g. parent-child entity relations for a DOM / UI / scene graph.
    // * Spatial index: "give me all entities within 5 units distance from (x, y, z)"
    // * Generic index: "give me all entities where arbitraryFunction(e) returns true"
    //

    /// Returns a nice helper for interfacing with the specified entity.
    ///
    /// This is a mere O(1) array access and so is very cheap.
    pub inline fn byID(entities: *const Entities, id: EntityID) Entity {
        return .{
            .id = id,

            // TODO: entity type lookup `entities.types.entries.get(id.type_id).value`
            // would not give us a pointer to the entry, which is required. I am 99% sure we can do this
            // in O(1) time, but MultiArrayList (`entries`) doesn't currently expose a getPtr method.
            //
            // For now this is actually not O(1), but still very fast.
            .entity_type = entities.types.getPtr(entities.typeName(id)).?,
        };
    }

    /// Returns the entity type name of the entity given its ID.
    ///
    /// This is a mere O(1) array access and so is very cheap.
    pub inline fn typeName(entities: *const Entities, id: EntityID) []const u8 {
        return entities.types.entries.get(id.type_id).key;
    }

    // Returns the storage for the given entity type name, creating it if necessary.
    // TODO: copy name?
    pub fn get(entities: *Entities, entity_type_name: []const u8) !*EntityTypeStorage {
        const num_types = entities.types.count();
        var v = try entities.types.getOrPut(entities.allocator, entity_type_name);
        if (!v.found_existing) {
            v.value_ptr.* = EntityTypeStorage.init(entities.allocator, @intCast(u16, num_types));
        }
        return v.value_ptr;
    }

    // TODO: ability to remove entity type entirely, deleting all entities in it
    // TODO: ability to remove entity types with no entities (garbage collect)
};

test "example" {
    const allocator = testing.allocator;

    //-------------------------------------------------------------------------
    // Create a world.
    var world = Entities.init(allocator);
    defer world.deinit();

    //-------------------------------------------------------------------------
    // Define component types, any Zig type will do!
    // A location component.
    const Location = struct {
        x: f32 = 0,
        y: f32 = 0,
        z: f32 = 0,
    };

    // A name component.
    const Name = []const u8;

    //-------------------------------------------------------------------------
    // Create a player entity type. Every entity with the same type ("player" here)
    // will pay to store the same set of components, whether they use them or not.
    var players = try world.get("player");

    // Create first player entity.
    var player1 = try players.new();
    try player1.set("name", @as(Name, "jane")); // add Name component
    try player1.set("location", Location{}); // add Location component

    // Create second player entity. Note that it pays the cost of storing a Name and Location
    // component regardless of whether or not we use it: all entities in the same type ("players")
    // pays to store the same set of components.
    var player2 = try players.new();
    try testing.expect(player2.get("location", Location) == null);
    try testing.expect(player2.get("name", Name) == null);

    //-------------------------------------------------------------------------
    // We can add new components at will. Now every player entity will pay to store a Rotation
    // component.
    const Rotation = struct { degrees: f32 };
    try player2.set("rotation", Rotation{ .degrees = 90 });
    try testing.expect(player1.get("rotation", Rotation) == null); // player1 has no rotation

    //-------------------------------------------------------------------------
    // Most of your entities don't have a component, but a few do? Use setSparse instead!
    // This is optimized for some entities having the component, but most not having it.
    const Weapon = struct { name: []const u8 };
    try player1.setSparse("weapon", Weapon{ .name = "sword" });
    try testing.expectEqualStrings("sword", player1.get("weapon", Weapon).?.name); // lookup is the same regardless of storage type
    try testing.expect(player2.get("weapon", Weapon) == null); // player2 has no weapon

    //-------------------------------------------------------------------------
    // Remove a component from any entity at will. We'll still pay the cost of storing it for each
    // component, it's just set to `null` now.
    // TODO: add a way to "cleanup" truly unused components.
    _ = player1.remove("location"); // remove Location component
    _ = player1.remove("weapon"); // remove Weapon component

    //-------------------------------------------------------------------------
    // At runtime we can query the type of any entity.
    try testing.expectEqualStrings("player", world.typeName(player1.id));

    //-------------------------------------------------------------------------
    // Entity IDs are all you need to store, they're 48 bits. You can always look up an entity by ID
    // in O(1) time (mere array access):
    const player1_by_id = world.byID(player1.id);

    //-------------------------------------------------------------------------
    // Introspect things.
    // Entity types
    var entity_types = world.types.keys();
    try testing.expectEqual(@as(usize, 1), entity_types.len);
    try testing.expectEqualStrings("player", entity_types[0]);

    // Component types for a given entity type "player"
    var component_names = (try world.get("player")).components.keys();
    try testing.expectEqual(@as(usize, 4), component_names.len);
    try testing.expectEqualStrings("name", component_names[0]);
    try testing.expectEqualStrings("location", component_names[1]);
    try testing.expectEqualStrings("rotation", component_names[2]);
    try testing.expectEqualStrings("weapon", component_names[3]);

    // TODO: iterating components an entity has not currently supported.

    //-------------------------------------------------------------------------
    // Delete an entity whenever you wish. Just be sure not to try and use it later!
    try player1_by_id.delete();
}

test "entity ID size" {
    try testing.expectEqual(6, @sizeOf(EntityID));
}
