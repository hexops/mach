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
//! Critically, this entity component system stores components for a classified archetype using both
//! a multi array list (independent arrays allocated per component) as well as hashmaps for sparse
//! component data for optimization. This is a novel and fundamentally different process than what
//! is described Unity Software Inc's patent US 10,599,560. This is not legal advice.
//!
const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const testing = std.testing;
const builtin = @import("builtin");

const is_debug = builtin.mode == .Debug;

const Entity = u32;

pub fn TypedEntities(comptime Archetype: type) type {
    return struct {
        allocator: Allocator,
        components: std.MultiArrayList(Archetype),
        free_slots: std.AutoHashMap(Entity, void),

        pub const Archetype = Archetype;
        const Self = @This();

        pub const Iterator = struct {
            e: *Self,
            index: Entity = 0,

            pub fn next(it: *Iterator) ?Archetype {
                std.debug.assert(it.index <= it.e.components.len);
                if (it.e.components.len == 0) return null;

                while (it.index < it.e.components.len) {
                    if (it.e.contains(it.index)) {
                        const current = it.index;
                        it.index += 1;
                        return it.e.get(current);
                    }
                    it.index += 1;
                }
                return null;
            }
        };

        pub fn init(allocator: Allocator) Self {
            return .{
                .allocator = allocator,
                .components = std.MultiArrayList(Archetype){},
                .free_slots = std.AutoHashMap(Entity, void).init(allocator),
            };
        }

        pub fn add(self: *Self, components: Archetype) error{OutOfMemory}!Entity {
            // Reuse a free slot, if available.
            if (self.free_slots.count() > 0) {
                var iter = self.free_slots.keyIterator();
                const taken = iter.next().?.*;
                _ = self.free_slots.remove(taken);
                self.components.set(taken, components);
                return taken;
            }

            // Create a new slot, potentially allocating.
            try self.components.append(self.allocator, components);
            return @intCast(Entity, self.components.len-1);
        }

        // In debug builds, panics if the entity does not exist.
        pub fn update(self: *Self, entity: Entity, partial_components: anytype) void {
            if (is_debug and !self.contains(entity)) @panic("no such entity");
            inline for (@typeInfo(@TypeOf(partial_components)).Struct.fields) |field, i| {
                const fieldEnum = @intToEnum(std.MultiArrayList(Archetype).Field, i);
                self.components.items(fieldEnum)[entity] = @field(partial_components, field.name);
            }
        }

        // In debug builds, panics if the entity does not exist.
        pub fn set(self: *Self, entity: Entity, components: Archetype) void {
            if (is_debug and !self.contains(entity)) @panic("no such entity");
            self.components.set(entity, components);
        }

        // In debug builds, panics if the entity does not exist.
        pub fn remove(self: *Self, entity: Entity) error{OutOfMemory}!void {
            if (is_debug and !self.contains(entity)) @panic("no such entity");
            try self.free_slots.put(entity, {});
        }

        pub fn contains(self: *Self, entity: Entity) bool {
            if (entity > self.components.len-1) return false;
            return !self.free_slots.contains(entity);
        }

        // In debug builds, panics if the entity does not exist.
        pub fn get(self: *Self, entity: Entity) Archetype {
            if (is_debug and !self.contains(entity)) @panic("no such entity");
            return self.components.get(entity);
        }

        /// Creates a copy using the same allocator
        pub inline fn clone(self: Self) !Self {
            return self.cloneWithAllocator(self.allocator);
        }

        /// Creates a copy using a specified allocator
        pub inline fn cloneWithAllocator(self: Self, new_allocator: Allocator) !Self {
            return Self{
                .allocator = new_allocator,
                .components = try self.components.clone(new_allocator),
                .free_slots = try self.free_slots.cloneWithAllocator(new_allocator),
            };
        }

        pub fn iterator(self: *Self) Iterator {
            return .{ .e = self };
        }

        pub fn deinit(self: *Self) void {
            self.components.deinit(self.allocator);
            self.free_slots.deinit();
        }
    };
}

pub fn Entities(comptime archetypes: anytype) type {
    comptime var fields: []const std.builtin.TypeInfo.StructField = &.{};
    inline for (archetypes) |Archetype| {
        fields = fields ++ [_]std.builtin.TypeInfo.StructField{.{
            .name = @typeName(Archetype),
            .field_type = TypedEntities(Archetype),
            .is_comptime = false,
            .default_value = null,
            .alignment = 0,
        }};
    }
    const ComptimeEntities = @Type(.{
        .Struct = .{
            .layout = .Auto,
            .is_tuple = false,
            .decls = &.{},
            .fields = fields,
        },
    });

    const RuntimeEntities = struct {
        erased: *anyopaque,
        deinit: fn(Allocator, *anyopaque) void,
        clone: fn(Allocator, *anyopaque) error{OutOfMemory}!*anyopaque,
    };

    return struct {
        allocator: Allocator,
        comptime_entities: ComptimeEntities,
        runtime_entities: std.StringHashMap(RuntimeEntities),

        const Self = @This();

        pub fn init(allocator: Allocator) Self {
            var comptime_entities: ComptimeEntities = undefined;
            inline for (archetypes) |Archetype| {
                @field(comptime_entities, @typeName(Archetype)) = TypedEntities(Archetype).init(allocator);
            }

            return .{
                .allocator = allocator,
                .comptime_entities = comptime_entities,
                .runtime_entities = std.StringHashMap(RuntimeEntities).init(allocator),
            };
        }

        pub fn get(self: *Self, comptime Archetype: type) !*TypedEntities(Archetype) {
            // Comptime archetype lookup
            if (@hasField(ComptimeEntities, @typeName(Archetype))) {
                return &@field(self.comptime_entities, @typeName(Archetype));
            }

            // Runtime archetype lookup
            var v = try self.runtime_entities.getOrPut(@typeName(Archetype));
            if (!v.found_existing) {
                const new = try self.allocator.create(TypedEntities(Archetype));
                new.* = TypedEntities(Archetype).init(self.allocator);
                v.value_ptr.* = RuntimeEntities{
                    .erased = new,
                    .deinit = (struct{
                        pub fn deinit(allocator: Allocator, erased: *anyopaque) void {
                            const aligned = @alignCast(@alignOf(*TypedEntities(Archetype)), erased);
                            const entities = @ptrCast(*TypedEntities(Archetype), aligned);
                            entities.deinit();
                            allocator.destroy(entities);
                        }
                    }.deinit),
                    .clone = (struct {
                        pub fn clone(new_allocator: Allocator, erased: *anyopaque) error{OutOfMemory}!*anyopaque {
                            const aligned = @alignCast(@alignOf(*TypedEntities(Archetype)), erased);
                            const entities = @ptrCast(*TypedEntities(Archetype), aligned);
                            const new_erased = try new_allocator.create(TypedEntities(Archetype));
                            new_erased.* = try entities.cloneWithAllocator(new_allocator);
                            return new_erased;
                        }
                    }).clone,
                };
            }
            const aligned = @alignCast(@alignOf(*TypedEntities(Archetype)), v.value_ptr.erased);
            return @ptrCast(*TypedEntities(Archetype), aligned);
        }

        /// Creates a copy using the same allocator
        pub inline fn clone(self: Self) !Self {
            return self.cloneWithAllocator(self.allocator);
        }

        /// Creates a copy using a specified allocator
        pub fn cloneWithAllocator(self: Self, new_allocator: Allocator) !Self {
            var comptime_entities: ComptimeEntities = undefined;
            inline for (archetypes) |Archetype| {
                const field = @field(self.comptime_entities, @typeName(Archetype));
                @field(comptime_entities, @typeName(Archetype)) = try field.cloneWithAllocator(new_allocator);
            }

            var runtime_entities = try self.runtime_entities.cloneWithAllocator(new_allocator);
            var iter = runtime_entities.valueIterator();
            while (iter.next()) |entities| {
                entities.erased = try entities.clone(new_allocator, entities.erased);
            }

            return Self{
                .allocator = new_allocator,
                .comptime_entities = comptime_entities,
                .runtime_entities = runtime_entities,
            };
        }

        pub fn deinit(self: *Self) void {
            inline for (archetypes) |Archetype| {
                @field(self.comptime_entities, @typeName(Archetype)).deinit();
            }
            var runtime_iter = self.runtime_entities.valueIterator();
            while (runtime_iter.next()) |runtime_entities| {
                runtime_entities.deinit(self.allocator, runtime_entities.erased);
            }
            self.runtime_entities.deinit();
        }
    };
}

test "example" {
    // A location component.
    const Location = struct {
        x: f32 = 0,
        y: f32 = 0,
        z: f32 = 0,
    };

    // A name component.
    const Name = []const u8;

    // A player archetype.
    const Player = struct {
        name: Name,
        location: Location = .{},
    };

    const allocator = testing.allocator;

    // Entities for e.g. a world. Stores multiple archetypes!
    var entities = Entities(.{
        // Predeclare your archetypes up front here and you get Archetype lookups at comptime / for free!
        Player,
    }).init(allocator);
    defer entities.deinit();

    // Get the player entities
    var players = try entities.get(Player);

    // A monster archetype
    const Monster = struct {
        name: Name,
    };

    // Get the monster entities - note that we didn't declare this archetype up front in Entities.init!
    // This archetype lookup will be done at runtime via a type name hashmap
    var monsters = try entities.get(Monster);

    // Let's add some entities!
    const carrot = try monsters.add(.{.name = "carrot"});
    const tomato = try monsters.add(.{.name = "tomato"});
    const potato = try monsters.add(.{.name = "potato"});

    // Remove some of our entities
    try monsters.remove(carrot);
    try monsters.remove(tomato);

    // Change an entity's components
    monsters.set(potato, .{.name = "totally real potato"});

    // Don't want to set all the components of an entity? i.e. just want to set one field? This can
    // be more efficient:
    monsters.update(potato, .{.name = "secretly tomato"});

    // Get all components of an entity
    try testing.expectEqual(Monster{.name = "secretly tomato"}, monsters.get(potato));

    // Iterate entities.
    _ = try players.add(.{.name = "jane"});
    _ = try players.add(.{.name = "bob"});
    var iter = players.iterator();
    try testing.expectEqualStrings("jane", iter.next().?.name);
    try testing.expectEqualStrings("bob", iter.next().?.name);

    // We can clone sets of entities, if needed.
    var players2 = try players.clone();
    defer players2.deinit();

    // Or maybe clone ALL entities!
    var entities2 = try entities.clone();
    defer entities2.deinit();
}
