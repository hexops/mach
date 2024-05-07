const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;
const builtin = @import("builtin");
const assert = std.debug.assert;
const query_mod = @import("query.zig");
const Archetype = @import("Archetype.zig");
const StringTable = @import("StringTable.zig");
const ComponentTypesByName = @import("module.zig").ComponentTypesByName;
const merge = @import("main.zig").merge;
const builtin_modules = @import("main.zig").builtin_modules;
const Entities = @import("main.zig").Entities;
const ModuleName = @import("module.zig").ModuleName;
const ComponentNameM = @import("module.zig").ComponentNameM;
const ComponentName = @import("module.zig").ComponentName;

/// An entity ID uniquely identifies an entity globally within a Database.
pub const EntityID = u64;

fn byTypeId(context: void, lhs: Archetype.Column, rhs: Archetype.Column) bool {
    _ = context;
    return lhs.type_id < rhs.type_id;
}

/// A database of entities. For example, all player, monster, etc. entities in a game world.
///
/// ```
/// const world = Database.init(allocator); // all entities in our world.
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
/// * Database is a database of tables, where each table represents a single archetype.
/// * Archetype is a table, whose rows are entities and columns are components.
/// * EntityID is a mere 32-bit array index, pointing to a 16-bit archetype table index and 32-bit
///   row index, enabling entities to "move" from one archetype table to another seamlessly and
///   making lookup by entity ID a few cheap array indexing operations.
/// * ComponentStorage(T) is a column of data within a table for a single type of component `T`.
pub fn Database(comptime modules: anytype) type {
    const component_types_by_name = ComponentTypesByName(modules){};
    return struct {
        allocator: Allocator,

        /// TODO!
        counter: EntityID = 0,

        /// A mapping of entity IDs (array indices) to where an entity's component values are actually
        /// stored.
        entities: std.AutoHashMapUnmanaged(EntityID, Pointer) = .{},

        // All archetypes are stored in a bucket. The number of buckets is configurable, and which
        // bucket an archetype will be stored in is based on the hash of all its columns / component
        // names.
        seed: u64 = 0xdeadbeef,
        buckets: []?u32, // indices into archetypes
        archetypes: std.ArrayListUnmanaged(Archetype) = .{},

        /// Maps component names <-> unique IDs
        component_names: *StringTable,
        id_name: StringTable.Index = 0,

        active_queries: std.ArrayListUnmanaged(QueryState) = .{},

        const Self = @This();

        /// Points to where an entity is stored, specifically in which archetype table and in which row
        /// of that table. That is, the entity's component values are stored at:
        ///
        /// ```
        /// Database.archetypes.items[ptr.archetype_index].rows[ptr.row_index]
        /// ```
        ///
        pub const Pointer = struct {
            archetype_index: u32,
            row_index: u32,
        };

        /// A complex query for entities matching a given criteria
        pub const QueryDeprecated = query_mod.QueryDeprecated(modules);
        pub const QueryTag = query_mod.QueryTag;

        pub fn init(allocator: Allocator) !Self {
            const component_names = try allocator.create(StringTable);
            errdefer allocator.destroy(component_names);
            component_names.* = .{};

            const buckets = try allocator.alloc(?u32, 1024); // TODO: configurable size
            errdefer allocator.free(buckets);
            for (buckets) |*b| b.* = null;

            var entities = Self{
                .allocator = allocator,
                .component_names = component_names,
                .buckets = buckets,
            };
            entities.id_name = entities.componentName(Entities.name, .id);

            const columns = try allocator.alloc(Archetype.Column, 1);
            columns[0] = .{
                .name = entities.id_name,
                .type_id = Archetype.typeId(EntityID),
                .size = @sizeOf(EntityID),
                .alignment = @alignOf(EntityID),
                .values = undefined,
            };

            const archetype_entry = try entities.archetypeOrPut(columns);
            archetype_entry.ptr.* = .{
                .len = 0,
                .capacity = 0,
                .columns = columns,
                .component_names = entities.component_names,
                .hash = archetype_entry.hash,
            };
            return entities;
        }

        pub fn deinit(entities: *Self) void {
            entities.entities.deinit(entities.allocator);
            entities.component_names.deinit(entities.allocator);
            entities.allocator.destroy(entities.component_names);
            entities.allocator.free(entities.buckets);
            for (entities.archetypes.items) |*archetype| archetype.deinit(entities.allocator);
            entities.archetypes.deinit(entities.allocator);
            entities.active_queries.deinit(entities.allocator);
        }

        fn archetypeOrPut(
            entities: *Self,
            columns: []const Archetype.Column,
        ) !struct {
            found_existing: bool,
            hash: u64,
            index: u32,
            ptr: *Archetype,
        } {
            var hasher = std.hash.XxHash64.init(entities.seed);
            for (columns) |column| {
                hasher.update(std.mem.asBytes(&column.name));
            }
            const hash = hasher.final();
            const bucket_index = hash % entities.buckets.len;
            if (entities.buckets[bucket_index]) |bucket| {
                // Bucket already exists
                const archetype = &entities.archetypes.items[bucket];
                if (archetype.next) |_| {
                    // Multiple archetypes in bucket (there were collisions)
                    while (archetype.next) |collision_index| {
                        const collision = &entities.archetypes.items[collision_index];
                        if (collision.hash == hash) {
                            // Probably a match
                            // TODO: technically a hash collision could occur here, so maybe check
                            // column IDs are equal here too?
                            return .{ .found_existing = true, .hash = hash, .index = collision_index, .ptr = collision };
                        }
                    }

                    // New collision
                    try entities.archetypes.append(entities.allocator, undefined);
                    const index = entities.archetypes.items.len - 1;
                    const ptr = &entities.archetypes.items[index];
                    archetype.next = @intCast(index);
                    return .{ .found_existing = false, .hash = hash, .index = @intCast(index), .ptr = ptr };
                } else if (archetype.hash == hash) {
                    // Exact match
                    return .{ .found_existing = true, .hash = hash, .index = bucket, .ptr = archetype };
                }

                // New collision
                try entities.archetypes.append(entities.allocator, undefined);
                const index = entities.archetypes.items.len - 1;
                const ptr = &entities.archetypes.items[index];
                archetype.next = @intCast(index);
                return .{ .found_existing = false, .hash = hash, .index = @intCast(index), .ptr = ptr };
            }

            // Bucket doesn't exist
            try entities.archetypes.append(entities.allocator, undefined);
            const index = entities.archetypes.items.len - 1;
            const ptr = &entities.archetypes.items[index];
            entities.buckets[bucket_index] = @intCast(index);
            return .{ .found_existing = false, .hash = hash, .index = @intCast(index), .ptr = ptr };
        }

        /// Returns a new entity.
        pub fn new(entities: *Self) !EntityID {
            const new_id = entities.counter;
            entities.counter += 1;

            // TODO: could skip this lookup if we store pointer
            const archetype_entry = try entities.archetypeOrPut(&.{
                .{
                    .name = entities.id_name,
                    .type_id = Archetype.typeId(EntityID),
                    .size = @sizeOf(EntityID),
                    .alignment = @alignOf(EntityID),
                    .values = undefined,
                },
            });
            assert(archetype_entry.found_existing);

            var void_archetype = archetype_entry.ptr;
            const new_row = try void_archetype.append(entities.allocator, .{ .id = new_id });
            const void_pointer = Pointer{
                .archetype_index = 0, // void archetype is guaranteed to be first index
                .row_index = new_row,
            };
            errdefer void_archetype.undoAppend();

            try entities.entities.put(entities.allocator, new_id, void_pointer);
            return new_id;
        }

        /// Removes an entity.
        pub fn remove(entities: *Self, entity: EntityID) !void {
            var archetype = entities.archetypeByID(entity);
            const ptr = entities.entities.get(entity).?;

            // A swap removal will be performed, update the entity stored in the last row of the
            // archetype table to point to the row the entity we are removing is currently located.
            if (archetype.len > 1) {
                const last_row_entity_id = archetype.get(archetype.len - 1, entities.id_name, EntityID).?;
                try entities.entities.put(entities.allocator, last_row_entity_id, Pointer{
                    .archetype_index = ptr.archetype_index,
                    .row_index = ptr.row_index,
                });
            }

            // Perform a swap removal to remove our entity from the archetype table.
            archetype.remove(ptr.row_index);

            _ = entities.entities.remove(entity);
        }

        /// Given a component name, returns its ID. A new ID is created if needed.
        ///
        /// The set of components used is expected to be static for the lifetime of the Database,
        /// and as such this function allocates component names but there is no way to release that
        /// memory until Database.deinit() is called.
        pub fn componentNameString(entities: *Self, name_str: []const u8) StringTable.Index {
            return entities.component_names.indexOrPut(entities.allocator, name_str) catch @panic("TODO: implement stateful OOM");
        }

        pub fn componentName(
            entities: *Self,
            comptime module_name: ModuleName(modules),
            comptime component_name: ComponentName(modules),
        ) StringTable.Index {
            return entities.componentNameString(@tagName(module_name) ++ "." ++ @tagName(component_name));
        }

        /// Returns the archetype storage for the given entity.
        pub inline fn archetypeByID(entities: *Self, entity: EntityID) *Archetype {
            const ptr = entities.entities.get(entity).?;
            return &entities.archetypes.items[ptr.archetype_index];
        }

        /// Sets the named component to the specified value for the given entity,
        /// moving the entity from it's current archetype table to the new archetype
        /// table if required.
        pub fn setComponent(
            entities: *Self,
            entity: EntityID,
            // TODO: cleanup comptime
            comptime namespace_name: std.meta.FieldEnum(@TypeOf(component_types_by_name)),
            comptime component_name: std.meta.FieldEnum(@TypeOf(@field(component_types_by_name, @tagName(namespace_name)))),
            component: @field(
                @field(component_types_by_name, @tagName(namespace_name)),
                @tagName(component_name),
            ).type,
        ) !void {
            const name_str = @tagName(namespace_name) ++ "." ++ @tagName(component_name);
            const name_id = try entities.component_names.indexOrPut(entities.allocator, name_str);

            const prev_archetype_idx = entities.entities.get(entity).?.archetype_index;
            var prev_archetype = &entities.archetypes.items[prev_archetype_idx];
            var archetype: ?*Archetype = if (prev_archetype.hasComponent(name_id)) prev_archetype else null;
            var archetype_idx: u32 = if (archetype != null) prev_archetype_idx else 0;

            if (archetype == null) {
                // TODO: eliminate the need for allocation and sorting here, since this can occur
                // if an archetype already exists (found_existing case below)
                const columns = try entities.allocator.alloc(Archetype.Column, prev_archetype.columns.len + 1);
                @memcpy(columns[0 .. columns.len - 1], prev_archetype.columns);
                for (columns) |*column| {
                    column.values = undefined;
                }
                columns[columns.len - 1] = .{
                    .name = name_id,
                    .type_id = Archetype.typeId(@TypeOf(component)),
                    .size = @sizeOf(@TypeOf(component)),
                    .alignment = if (@sizeOf(@TypeOf(component)) == 0) 1 else @alignOf(@TypeOf(component)),
                    .values = undefined,
                };
                std.sort.pdq(Archetype.Column, columns, {}, byTypeId);

                const archetype_entry = try entities.archetypeOrPut(columns);
                if (!archetype_entry.found_existing) {
                    // Update prev_archetype pointer, as it would now be invalidated due to the allocation
                    prev_archetype = &entities.archetypes.items[prev_archetype_idx];

                    archetype_entry.ptr.* = .{
                        .len = 0,
                        .capacity = 0,
                        .columns = columns,
                        .component_names = entities.component_names,
                        .hash = archetype_entry.hash,
                    };
                } else {
                    entities.allocator.free(columns);
                }
                archetype = archetype_entry.ptr;
                archetype_idx = archetype_entry.index;
            }

            // Either new storage (if the entity moved between storage tables due to having a new
            // component) or the prior storage (if the entity already had the component and it's value
            // is merely being updated.)
            var current_archetype_storage = archetype.?;

            if (archetype_idx == prev_archetype_idx) {
                // Update the value of the existing component of the entity.
                const ptr = entities.entities.get(entity).?;
                current_archetype_storage.set(ptr.row_index, name_id, component);
                return;
            }

            // Copy to all component values for our entity from the old archetype storage (archetype)
            // to the new one (current_archetype_storage).
            const new_row = try current_archetype_storage.appendUndefined(entities.allocator);
            const old_ptr = entities.entities.get(entity).?;

            // Update the storage/columns for all of the existing components on the entity.
            current_archetype_storage.set(new_row, entities.id_name, entity);
            for (prev_archetype.columns) |column| {
                if (column.name == entities.id_name) continue;
                for (current_archetype_storage.columns) |corresponding| {
                    if (column.name == corresponding.name) {
                        const old_value_raw = prev_archetype.getDynamic(old_ptr.row_index, column.name, column.size, column.alignment, column.type_id).?;
                        current_archetype_storage.setDynamic(new_row, corresponding.name, old_value_raw, corresponding.alignment, corresponding.type_id);
                        break;
                    }
                }
            }

            // Update the storage/column for the new component.
            current_archetype_storage.set(new_row, name_id, component);

            prev_archetype.remove(old_ptr.row_index);
            if (prev_archetype.len > 0) {
                const swapped_entity_id = prev_archetype.get(old_ptr.row_index, entities.id_name, EntityID).?;
                try entities.entities.put(entities.allocator, swapped_entity_id, old_ptr);
            }

            try entities.entities.put(entities.allocator, entity, Pointer{
                .archetype_index = archetype_idx,
                .row_index = new_row,
            });
            return;
        }

        /// Sets the named component to the specified value for the given entity,
        /// moving the entity from it's current archetype table to the new archetype
        /// table if required.
        ///
        /// For tags, set component.len = 0 and alignment = 1
        pub fn setComponentDynamic(
            entities: *Self,
            entity: EntityID,
            name_id: StringTable.Index,
            component: []const u8,
            alignment: u16,
            type_id: u32,
        ) !void {
            const prev_archetype_idx = entities.entities.get(entity).?.archetype_index;
            var prev_archetype = &entities.archetypes.items[prev_archetype_idx];
            var archetype: ?*Archetype = if (prev_archetype.hasComponent(name_id)) prev_archetype else null;
            var archetype_idx: u32 = if (archetype != null) prev_archetype_idx else 0;

            if (archetype == null) {
                // TODO: eliminate the need for allocation and sorting here, since this can occur
                // if an archetype already exists (found_existing case below)
                const columns = try entities.allocator.alloc(Archetype.Column, prev_archetype.columns.len + 1);
                @memcpy(columns[0 .. columns.len - 1], prev_archetype.columns);
                for (columns) |*column| {
                    column.values = undefined;
                }
                columns[columns.len - 1] = .{
                    .name = name_id,
                    .type_id = type_id,
                    .size = @intCast(component.len),
                    .alignment = alignment,
                    .values = undefined,
                };
                std.sort.pdq(Archetype.Column, columns, {}, byTypeId);

                const archetype_entry = try entities.archetypeOrPut(columns);
                if (!archetype_entry.found_existing) {
                    // Update prev_archetype pointer, as it would now be invalidated due to the allocation
                    prev_archetype = &entities.archetypes.items[prev_archetype_idx];

                    archetype_entry.ptr.* = .{
                        .len = 0,
                        .capacity = 0,
                        .columns = columns,
                        .component_names = entities.component_names,
                        .hash = archetype_entry.hash,
                    };
                } else {
                    entities.allocator.free(columns);
                }
                archetype = archetype_entry.ptr;
                archetype_idx = archetype_entry.index;
            }

            // Either new storage (if the entity moved between storage tables due to having a new
            // component) or the prior storage (if the entity already had the component and it's value
            // is merely being updated.)
            var current_archetype_storage = archetype.?;

            if (archetype_idx == prev_archetype_idx) {
                // Update the value of the existing component of the entity.
                const ptr = entities.entities.get(entity).?;
                current_archetype_storage.setDynamic(ptr.row_index, name_id, component, alignment, type_id);
                return;
            }

            // Copy to all component values for our entity from the old archetype storage (archetype)
            // to the new one (current_archetype_storage).
            const new_row = try current_archetype_storage.appendUndefined(entities.allocator);
            const old_ptr = entities.entities.get(entity).?;

            // Update the storage/columns for all of the existing components on the entity.
            current_archetype_storage.set(new_row, entities.id_name, entity);
            for (prev_archetype.columns) |column| {
                if (column.name == entities.id_name) continue;
                for (current_archetype_storage.columns) |corresponding| {
                    if (column.name == corresponding.name) {
                        const old_value_raw = prev_archetype.getDynamic(old_ptr.row_index, column.name, column.size, column.alignment, column.type_id).?;
                        current_archetype_storage.setDynamic(new_row, corresponding.name, old_value_raw, corresponding.alignment, corresponding.type_id);
                        break;
                    }
                }
            }

            // Update the storage/column for the new component.
            current_archetype_storage.setDynamic(new_row, name_id, component, alignment, type_id);

            prev_archetype.remove(old_ptr.row_index);
            if (prev_archetype.len > 0) {
                const swapped_entity_id = prev_archetype.get(old_ptr.row_index, entities.id_name, EntityID).?;
                try entities.entities.put(entities.allocator, swapped_entity_id, old_ptr);
            }

            try entities.entities.put(entities.allocator, entity, Pointer{
                .archetype_index = archetype_idx,
                .row_index = new_row,
            });
            return;
        }

        /// Gets the named component of the given type.
        /// Returns null if the component does not exist on the entity.
        pub fn getComponent(
            entities: *Self,
            entity: EntityID,
            // TODO: cleanup comptime
            comptime namespace_name: std.meta.FieldEnum(@TypeOf(component_types_by_name)),
            comptime component_name: std.meta.FieldEnum(@TypeOf(@field(component_types_by_name, @tagName(namespace_name)))),
        ) ?@field(
            @field(component_types_by_name, @tagName(namespace_name)),
            @tagName(component_name),
        ).type {
            // TODO: cleanup comptime
            const Component = comptime @field(
                @field(component_types_by_name, @tagName(namespace_name)),
                @tagName(component_name),
            ).type;

            const name_str = @tagName(namespace_name) ++ "." ++ @tagName(component_name);
            const name_id = entities.component_names.index(name_str) orelse return null;

            var archetype = entities.archetypeByID(entity);
            const ptr = entities.entities.get(entity).?;

            return archetype.get(ptr.row_index, name_id, Component);
        }

        /// Gets the named component of the given type.
        /// Returns null if the component does not exist on the entity.
        ///
        /// For tags, set size = 0 and alignment = 1
        pub fn getComponentDynamic(
            entities: *Self,
            entity: EntityID,
            name_id: StringTable.Index,
            size: u32,
            alignment: u16,
            type_id: u32,
        ) ?[]u8 {
            var archetype = entities.archetypeByID(entity);
            const ptr = entities.entities.get(entity).?;
            return archetype.getDynamic(ptr.row_index, name_id, size, alignment, type_id);
        }

        /// Removes the named component from the entity, or noop if it doesn't have such a component.
        pub fn removeComponent(
            entities: *Self,
            entity: EntityID,
            // TODO: cleanup comptime
            comptime namespace_name: std.meta.FieldEnum(@TypeOf(component_types_by_name)),
            comptime component_name: std.meta.FieldEnum(@TypeOf(@field(component_types_by_name, @tagName(namespace_name)))),
        ) !void {
            const name_str = @tagName(namespace_name) ++ "." ++ @tagName(component_name);
            const name_id = try entities.component_names.indexOrPut(entities.allocator, name_str);
            return entities.removeComponentDynamic(entity, name_id);
        }

        /// Removes the named component from the entity, or noop if it doesn't have such a component.
        pub fn removeComponentDynamic(
            entities: *Self,
            entity: EntityID,
            name_id: StringTable.Index,
        ) !void {
            const prev_archetype_idx = entities.entities.get(entity).?.archetype_index;
            var prev_archetype = &entities.archetypes.items[prev_archetype_idx];
            var archetype: ?*Archetype = if (prev_archetype.hasComponent(name_id)) prev_archetype else return;
            var archetype_idx: u32 = if (archetype != null) prev_archetype_idx else 0;

            // Determine which archetype the entity will move to.
            // TODO: eliminate this allocation in the found_existing case below
            const columns = try entities.allocator.alloc(Archetype.Column, prev_archetype.columns.len - 1);
            var i: usize = 0;
            for (prev_archetype.columns) |old_column| {
                if (old_column.name == name_id) continue;
                columns[i] = old_column;
                columns[i].values = undefined;
                i += 1;
            }

            const archetype_entry = try entities.archetypeOrPut(columns);
            if (!archetype_entry.found_existing) {
                // Update prev_archetype pointer, as it would now be invalidated due to the allocation
                prev_archetype = &entities.archetypes.items[prev_archetype_idx];

                archetype_entry.ptr.* = .{
                    .len = 0,
                    .capacity = 0,
                    .columns = columns,
                    .component_names = entities.component_names,
                    .hash = archetype_entry.hash,
                };
            } else {
                entities.allocator.free(columns);
            }
            archetype = archetype_entry.ptr;
            archetype_idx = archetype_entry.index;

            var current_archetype_storage = archetype.?;

            // Copy all component values for our entity from the old archetype storage (archetype)
            // to the new one (current_archetype_storage).
            const new_row = try current_archetype_storage.appendUndefined(entities.allocator);
            const old_ptr = entities.entities.get(entity).?;

            // Update the storage/columns for all of the existing components on the entity that exist in
            // the new archetype table (i.e. excluding the component to remove.)
            current_archetype_storage.set(new_row, entities.id_name, entity);
            for (current_archetype_storage.columns) |column| {
                if (column.name == entities.id_name) continue;
                for (prev_archetype.columns) |corresponding| {
                    if (column.name == corresponding.name) {
                        const old_value_raw = prev_archetype.getDynamic(old_ptr.row_index, column.name, column.size, column.alignment, column.type_id).?;
                        current_archetype_storage.setDynamic(new_row, column.name, old_value_raw, column.alignment, column.type_id);
                        break;
                    }
                }
            }

            prev_archetype.remove(old_ptr.row_index);
            if (prev_archetype.len > 0) {
                const swapped_entity_id = prev_archetype.get(old_ptr.row_index, entities.id_name, EntityID).?;
                try entities.entities.put(entities.allocator, swapped_entity_id, old_ptr);
            }

            try entities.entities.put(entities.allocator, entity, Pointer{
                .archetype_index = archetype_idx,
                .row_index = new_row,
            });
        }

        // Queries for archetypes matching the given query.
        pub fn queryDeprecated(
            entities: *Self,
            q: QueryDeprecated,
        ) ArchetypeIterator(modules) {
            return ArchetypeIterator(modules).init(entities, q);
        }

        /// Represents a dynamic (runtime-generated, non type safe) query.
        pub const QueryDynamic = union(enum) {
            /// Logical AND operator for query expressions
            op_and: []const @This(),

            /// Match a specific module component, indicating it will only be read.
            // TODO: add component name type and consider replacing StringTable approach with global enum
            read: StringTable.Index,

            /// Match a specific module component, indicating it will be read and potentially written.
            // TODO: add component name type and consider replacing StringTable approach with global enum
            write: StringTable.Index,

            pub fn match(q: @This(), archetype: *Archetype) bool {
                switch (q) {
                    .op_and => |e| {
                        for (e) |and_q| if (!and_q.match(archetype)) return false;
                        return true;
                    },
                    .read, .write => |e| {
                        for (archetype.columns) |column| if (column.name == e) return true;
                        return false;
                    },
                }
            }

            /// returns a copy of this query, using dst as storage space, returning the remaining space.
            fn copy(q: QueryDynamic, dst: []QueryDynamic) !struct { copy: QueryDynamic, remaining: []QueryDynamic } {
                switch (q) {
                    .op_and => |e| {
                        if (e.len >= dst.len) return error.OutOfSpace;
                        @memcpy(dst[0..e.len], e);
                        const cpy = QueryDynamic{ .op_and = dst[0..e.len] };

                        var remaining = dst[e.len..];
                        for (e) |and_q| {
                            const c = try and_q.copy(remaining);
                            remaining = c.remaining;
                        }
                        return .{ .copy = cpy, .remaining = remaining };
                    },
                    .read, .write => return .{ .copy = q, .remaining = dst },
                }
            }
        };

        /// When a query is first performed, it becomes active and its iterator state is stored
        /// and maintained. When all results in the iterator have been consumed, it is marked
        /// as finished and later recycled.
        pub const QueryState = struct {
            q: QueryDynamic,
            q_storage: [32]QueryDynamic,
            next_index: u31 = 0, // archetypes index
            finished: bool = false,
        };

        /// Represents a dynamic (runtime-generated, non type safe) query result.
        pub const QueryResultDynamic = struct {
            entities: *Self,
            index: u32, // active_queries index

            pub fn next(q: *QueryResultDynamic) ?*Archetype {
                const state = &q.entities.active_queries.items[q.index];
                if (state.finished) @panic("query iterator already finished, invoking next() is illegal");

                while (state.next_index < q.entities.archetypes.items.len) {
                    const archetype = &q.entities.archetypes.items[state.next_index];
                    state.next_index += 1;
                    if (state.q.match(archetype)) return archetype;
                }

                state.finished = true;
                q.entities.reuseInactiveQueries();
                return null;
            }
        };

        /// A qualified component name, describing a specific component in a specific module.
        pub const ModuleComponentName = struct {
            module: ModuleName(modules),
            component: ComponentName(modules),
        };

        pub const ComponentQuery = union(enum) {
            read: ModuleComponentName,
            write: ModuleComponentName,
        };

        pub fn QueryResult(comptime q: anytype) type {
            return struct {
                dynamic: QueryResultDynamic,

                pub const Slices = blk: {
                    var fields: []const std.builtin.Type.StructField = &[0]std.builtin.Type.StructField{};
                    fields = fields ++ [_]std.builtin.Type.StructField{.{
                        .name = "len",
                        .type = usize,
                        .default_value = null,
                        .is_comptime = false,
                        .alignment = @alignOf(usize),
                    }};
                    for (@typeInfo(@TypeOf(q)).Struct.fields) |slice| {
                        const value: ComponentQuery = @field(q, slice.name);
                        switch (value) {
                            .read => |v| {
                                const T = @field(
                                    @field(ComponentTypesByName(modules){}, @tagName(v.module)),
                                    @tagName(v.component),
                                ).type;
                                fields = fields ++ [_]std.builtin.Type.StructField{.{
                                    .name = slice.name,
                                    .type = []const T,
                                    .default_value = null,
                                    .is_comptime = false,
                                    .alignment = @alignOf([]const T),
                                }};
                            },
                            .write => |v| {
                                const T = @field(
                                    @field(ComponentTypesByName(modules){}, @tagName(v.module)),
                                    @tagName(v.component),
                                ).type;
                                fields = fields ++ [_]std.builtin.Type.StructField{.{
                                    .name = slice.name,
                                    .type = []T,
                                    .default_value = null,
                                    .is_comptime = false,
                                    .alignment = @alignOf([]T),
                                }};
                            },
                        }
                    }
                    break :blk @Type(.{
                        .Struct = .{
                            .layout = .Auto,
                            .is_tuple = false,
                            .fields = fields,
                            .decls = &[_]std.builtin.Type.Declaration{},
                        },
                    });
                };

                pub fn next(q2: *@This()) ?Slices {
                    const archetype = q2.dynamic.next() orelse return null;

                    var slices: Slices = undefined;
                    slices.len = archetype.len;
                    inline for (@typeInfo(@TypeOf(q)).Struct.fields) |slice| {
                        const value: ComponentQuery = @field(q, slice.name);
                        switch (value) {
                            .read => |v| {
                                const column_name = q2.dynamic.entities.componentName(v.module, v.component);
                                @field(slices, slice.name) = archetype.getColumnValues(column_name, std.meta.Elem(@TypeOf(@field(slices, slice.name)))).?[0..archetype.len];
                            },
                            .write => |v| {
                                const column_name = q2.dynamic.entities.componentName(v.module, v.component);
                                @field(slices, slice.name) = archetype.getColumnValues(column_name, std.meta.Elem(@TypeOf(@field(slices, slice.name)))).?[0..archetype.len];
                            },
                        }
                    }
                    return slices;
                }
            };
        }

        /// Performs a query which is comptime-known, enabling greater type-safety. Typical usage
        /// looks something like:
        ///
        /// ```
        /// var q = try world.query(.{
        ///     .ids = mach.Entities.Mod.read(.id),
        ///     .rotations = Game.Mod.write(.rotation),
        /// });
        /// while (q.next()) |v| {
        ///     for (v.ids, v.rotations) |id, *rotation| {
        ///         std.debug.print("entity ID: {}, rotation: {}\n", .{id, rotation.*});
        ///         rotation.x += 0.01;
        ///     }
        /// }
        /// ```
        ///
        /// The parameter `q` to query() has fields of arbitrary names (`.ids` and `.rotations` above)
        /// which define the name of the slice fields in each iterator value. Whether the component
        /// value is `.read()` or `.write()` determines whether the slices are `[]T` (mutable) or
        /// `[]const T` (immutable).
        pub fn query(entities: *Self, comptime q: anytype) !QueryResult(q) {
            var op_and: [@typeInfo(@TypeOf(q)).Struct.fields.len]QueryDynamic = undefined;
            inline for (@typeInfo(@TypeOf(q)).Struct.fields, 0..) |slice, i| {
                const value: ComponentQuery = @field(q, slice.name);
                switch (value) {
                    .read => |v| op_and[i] = .{ .read = entities.componentName(v.module, v.component) },
                    .write => |v| op_and[i] = .{ .write = entities.componentName(v.module, v.component) },
                }
            }
            return .{
                .dynamic = try entities.queryDynamic(.{ .op_and = &op_and }),
            };
        }

        /// Performs a dynamic (runtime-generated, non type safe) query.
        ///
        /// The query parameter will be copied and only needs to live until this function returns.
        pub fn queryDynamic(entities: *Self, q: QueryDynamic) !QueryResultDynamic {
            const new_query = QueryResultDynamic{
                .entities = entities,
                .index = @intCast(entities.active_queries.items.len),
            };
            try entities.active_queries.append(entities.allocator, QueryState{
                .q = undefined,
                .q_storage = undefined,
            });

            // Copy the input query into the state storage
            const state = &entities.active_queries.items[entities.active_queries.items.len - 1];
            const c = q.copy(&state.q_storage) catch @panic("mach: queries with >32 expressions not yet supported, please open an issue."); // TODO: heap allocation
            state.q = c.copy;

            return new_query;
        }

        /// Releases any inactive queries entities.active_queries state memory space at the end of
        /// the list, enabling reuse of it.
        fn reuseInactiveQueries(entities: *Self) void {
            var new_len: usize = entities.active_queries.items.len;
            while (new_len > 0 and entities.active_queries.items[new_len - 1].finished) {
                new_len -= 1;
            }
            entities.active_queries.shrinkRetainingCapacity(new_len);
        }

        // TODO: ability to remove archetype entirely, deleting all entities in it
        // TODO: ability to remove archetypes with no entities (garbage collection)
    };
}

// TODO: move this type somewhere else
pub fn ArchetypeIterator(comptime modules: anytype) type {
    const DatabaseT = Database(modules);
    return struct {
        entities: *DatabaseT,
        query: DatabaseT.QueryDeprecated,
        index: usize,

        const Self = @This();

        pub fn init(entities: *DatabaseT, query: DatabaseT.QueryDeprecated) Self {
            return Self{
                .entities = entities,
                .query = query,
                .index = 0,
            };
        }

        // TODO: component_types_by_name is a superset of queried items, not type-safe.
        pub fn next(iter: *Self) ?Archetype.Slicer(modules) {
            while (iter.index < iter.entities.archetypes.items.len) {
                const archetype = &iter.entities.archetypes.items[iter.index];
                iter.index += 1;
                if (iter.match(archetype)) return Archetype.Slicer(modules){ .archetype = archetype };
            }
            return null;
        }

        pub fn match(iter: *Self, consideration: *Archetype) bool {
            if (consideration.len == 0) return false;
            var buf: [2048]u8 = undefined;
            switch (iter.query) {
                .all => {
                    for (iter.query.all) |namespace| {
                        switch (namespace) {
                            inline else => |components| {
                                for (components) |component| {
                                    if (@typeInfo(@TypeOf(component)).Enum.fields.len == 0) continue;
                                    const name = switch (component) {
                                        inline else => |c| std.fmt.bufPrint(&buf, "{s}.{s}", .{ @tagName(namespace), @tagName(c) }) catch break,
                                    };
                                    const name_id = iter.entities.componentNameString(name);
                                    var has_column = false;
                                    for (consideration.columns) |column| {
                                        if (column.name == name_id) {
                                            has_column = true;
                                            break;
                                        }
                                    }
                                    if (!has_column) return false;
                                }
                            },
                        }
                    }
                    return true;
                },
                .any => @panic("TODO"),
            }
        }
    };
}

test {
    const modules = merge(.{
        builtin_modules,
    });
    std.testing.refAllDeclsRecursive(Database(modules));
}

// TODO: require "one big registration of components" even when using dynamic API? Would alleviate
// some of the confusion about using world.componentName, and would perhaps improve GUI editor
// compatibility in practice.
test "dynamic" {
    const allocator = testing.allocator;
    const asBytes = std.mem.asBytes;

    const Location = struct {
        x: f32 = 0,
        y: f32 = 0,
        z: f32 = 0,
    };

    const Rotation = struct { degrees: f32 };

    // Create a world.
    var world = try Database(merge(.{builtin_modules})).init(allocator);
    defer world.deinit();

    // Create an entity and add dynamic components.
    const player1 = try world.new();
    try world.setComponentDynamic(player1, world.componentNameString("game.name"), "jane", @alignOf([]const u8), 100);
    try world.setComponentDynamic(player1, world.componentNameString("game.name"), "joey", @alignOf([]const u8), 100);
    try world.setComponentDynamic(player1, world.componentNameString("game.location"), asBytes(&Location{ .x = 1, .y = 2, .z = 3 }), @alignOf(Location), 101);

    // Get components
    try testing.expect(world.getComponentDynamic(player1, world.componentNameString("game.rotation"), @sizeOf(Rotation), @alignOf(Rotation), 102) == null);
    const loc = world.getComponentDynamic(player1, world.componentNameString("game.location"), @sizeOf(Location), @alignOf(Location), 101);
    try testing.expectEqual(Location{ .x = 1, .y = 2, .z = 3 }, std.mem.bytesToValue(Location, @as(*[12]u8, @ptrCast(loc.?.ptr))));
    try testing.expectEqualStrings(world.getComponentDynamic(player1, world.componentNameString("game.name"), 4, @alignOf([]const u8), 100).?, "joey");
}

test "entity ID size" {
    try testing.expectEqual(8, @sizeOf(EntityID));
}

test "example" {
    const allocator = testing.allocator;

    const Location = struct {
        x: f32 = 0,
        y: f32 = 0,
        z: f32 = 0,
    };

    const Rotation = struct { degrees: f32 };

    const Game = struct {
        pub const name = .game;
        pub const components = .{
            .name = .{ .type = []const u8 },
            .location = .{ .type = Location },
            .rotation = .{ .type = Rotation },
            .is_monster = .{ .type = void },
        };
    };

    const modules = merge(.{
        builtin_modules,
        Game,
    });

    //-------------------------------------------------------------------------
    // Create a world.
    var world = try Database(modules).init(allocator);
    defer world.deinit();

    //-------------------------------------------------------------------------
    // Create first player entity.
    const player1 = try world.new();
    try world.setComponent(player1, .game, .name, "jane"); // add .name component
    try world.setComponent(player1, .game, .name, "joe"); // update .name component
    try world.setComponent(player1, .game, .location, .{}); // add .location component

    // Create second player entity.
    const player2 = try world.new();
    try testing.expect(world.getComponent(player2, .game, .location) == null);
    try testing.expect(world.getComponent(player2, .game, .name) == null);

    //-------------------------------------------------------------------------
    // We can add new components at will.
    try world.setComponent(player2, .game, .rotation, .{ .degrees = 90 });
    try world.setComponent(player2, .game, .rotation, .{ .degrees = 91 }); // update .rotation component
    try testing.expect(world.getComponent(player1, .game, .rotation) == null); // player1 has no rotation

    //-------------------------------------------------------------------------
    // Remove a component from any entity at will.
    // TODO: add a way to "cleanup" truly unused archetypes
    try world.removeComponent(player1, .game, .name);
    try world.removeComponent(player1, .game, .location);
    // try world.removeComponent(player1, .game, .location); // doesn't exist? no problem.

    //-------------------------------------------------------------------------
    // Zero-size tags, these can be put on entities to indicate they are unique
    // in some way. e.g. to indicate which entities are monsters, which you can
    // then query
    try testing.expectEqual(@as(?void, null), world.getComponent(player1, .game, .is_monster));

    try world.setComponent(player1, .game, .is_monster, {});
    try testing.expectEqual(@as(?void, {}), world.getComponent(player1, .game, .is_monster));
    try testing.expectEqual(@as(?void, null), world.getComponent(player2, .game, .is_monster));

    try world.removeComponent(player1, .game, .is_monster);
    try testing.expectEqual(@as(?void, null), world.getComponent(player1, .game, .is_monster));
    try testing.expectEqual(@as(?void, null), world.getComponent(player2, .game, .is_monster));

    //-------------------------------------------------------------------------
    // Introspect things.
    //
    // Archetype IDs, these are our "table names" - they're just hashes of all the component names
    // within the archetype table.
    const archetypes = world.archetypes.items;
    try testing.expectEqual(@as(usize, 6), archetypes.len);
    // TODO: better table names, based on columns
    // try testing.expectEqual(@as(u64, 0), archetypes[0].hash);
    // try testing.expectEqual(@as(u32, 4), archetypes[1].name);
    // try testing.expectEqual(@as(u32, 14), archetypes[2].name);
    // try testing.expectEqual(@as(u32, 28), archetypes[3].name);
    // try testing.expectEqual(@as(u32, 14), archetypes[4].name);

    // Number of (living) entities stored in an archetype table.
    try testing.expectEqual(@as(usize, 1), archetypes[0].len);
    try testing.expectEqual(@as(usize, 0), archetypes[1].len);
    try testing.expectEqual(@as(usize, 0), archetypes[2].len);
    try testing.expectEqual(@as(usize, 1), archetypes[3].len);
    try testing.expectEqual(@as(usize, 0), archetypes[4].len);
    try testing.expectEqual(@as(usize, 0), archetypes[5].len);

    // Resolve archetype by entity ID and print column names
    const columns = world.archetypeByID(player2).columns;
    try testing.expectEqual(@as(usize, 2), columns.len);
    try testing.expectEqualStrings("entity.id", world.component_names.string(columns[0].name));
    try testing.expectEqualStrings("game.rotation", world.component_names.string(columns[1].name));

    //-------------------------------------------------------------------------
    // Query for all entities that have all of the given components
    const W = @TypeOf(world);
    var q = try world.query(.{
        .ids = W.ComponentQuery{ .read = W.ModuleComponentName{ .module = Entities.name, .component = .id } },
        .rotations = W.ComponentQuery{ .write = W.ModuleComponentName{ .module = Game.name, .component = .rotation } },
    });
    while (q.next()) |v| {
        try testing.expectEqual(@as(usize, 1), v.len);
        try testing.expectEqual([]const EntityID, @TypeOf(v.ids));
        try testing.expectEqual([]Rotation, @TypeOf(v.rotations));
        try testing.expectEqual(@as(usize, 1), v.ids.len);
        try testing.expectEqual(@as(usize, 1), v.rotations.len);
    }

    // Dynamic queries (e.g. issued from another programming language without comptime)
    var q2 = try world.queryDynamic(.{
        .op_and = &.{
            .{ .read = world.componentName(Entities.name, .id) },
            .{ .read = world.componentName(Game.name, .rotation) },
        },
    });
    while (q2.next()) |archtype| {
        try testing.expectEqual(@as(usize, 1), archtype.len);
        try testing.expectEqual(@as(usize, 2), archtype.columns.len);

        try testing.expectEqualStrings("entity.id", world.component_names.string(archtype.columns[0].name));
        try testing.expectEqualStrings("game.rotation", world.component_names.string(archtype.columns[1].name));
    }

    // TODO: iterating components an entity has not currently supported.

    //-------------------------------------------------------------------------
    // Remove an entity whenever you wish. Just be sure not to try and use it later!
    try world.remove(player1);
}

test "empty_world" {
    const allocator = testing.allocator;
    //-------------------------------------------------------------------------
    var world = try Database(merge(.{builtin_modules})).init(allocator);
    // Create a world.
    defer world.deinit();
}

test "many entities" {
    const allocator = testing.allocator;

    const Location = struct {
        x: f32 = 0,
        y: f32 = 0,
        z: f32 = 0,
    };

    const Rotation = struct { degrees: f32 };

    const modules = merge(.{
        builtin_modules,
        struct {
            pub const name = .game;
            pub const components = .{
                .name = .{ .type = []const u8 },
                .location = .{ .type = Location },
                .rotation = .{ .type = Rotation },
            };
        },
    });

    // Create many entities
    var world = try Database(modules).init(allocator);
    defer world.deinit();
    for (0..8192) |_| {
        const player = try world.new();
        try world.setComponent(player, .game, .name, "jane");
        try world.setComponent(player, .game, .location, .{});
    }

    // Confirm the number of archetypes created
    const archetypes = world.archetypes.items;
    try testing.expectEqual(@as(usize, 3), archetypes.len);

    // Confirm archetypes
    var columns = archetypes[0].columns;
    try testing.expectEqual(@as(usize, 1), columns.len);
    try testing.expectEqualStrings("entity.id", world.component_names.string(columns[0].name));

    columns = archetypes[1].columns;
    try testing.expectEqual(@as(usize, 2), columns.len);
    try testing.expectEqualStrings("entity.id", world.component_names.string(columns[0].name));
    try testing.expectEqualStrings("game.name", world.component_names.string(columns[1].name));

    columns = archetypes[2].columns;
    try testing.expectEqual(@as(usize, 3), columns.len);
    try testing.expectEqualStrings("entity.id", world.component_names.string(columns[0].name));
    try testing.expectEqualStrings("game.name", world.component_names.string(columns[1].name));
    try testing.expectEqualStrings("game.location", world.component_names.string(columns[2].name));
}
