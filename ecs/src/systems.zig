const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const testing = std.testing;

const Entities = @import("entities.zig").Entities;

pub fn Adapter(all_components: anytype) type {
    return struct {
        world: *World(all_components),

        const Self = @This();
        pub const Iterator = Entities(all_components).Iterator;

        pub fn query(adapter: *Self, components: []const []const u8) Iterator {
            return adapter.world.entities.query(components);
        }
    };
}

pub fn World(all_components: anytype) type {
    return struct {
        allocator: Allocator,
        systems: std.StringArrayHashMapUnmanaged(System) = .{},
        entities: Entities(all_components),

        const Self = @This();
        pub const System = fn (adapter: *Adapter(all_components)) void;

        pub fn init(allocator: Allocator) !Self {
            return Self{
                .allocator = allocator,
                .entities = try Entities(all_components).init(allocator),
            };
        }

        pub fn deinit(world: *Self) void {
            world.systems.deinit(world.allocator);
            world.entities.deinit();
        }

        pub fn register(world: *Self, name: []const u8, system: System) !void {
            try world.systems.put(world.allocator, name, system);
        }

        pub fn unregister(world: *Self, name: []const u8) void {
            world.systems.orderedRemove(name);
        }

        pub fn tick(world: *Self) void {
            var i: usize = 0;
            while (i < world.systems.count()) : (i += 1) {
                const system = world.systems.entries.get(i).value;

                var adapter = Adapter(all_components){
                    .world = world,
                };
                system(&adapter);
            }
        }
    };
}
