const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const testing = std.testing;

const Entities = @import("entities.zig").Entities;
const Iterator = Entities.Iterator;

pub const Adapter = struct {
    world: *World,

    pub fn query(adapter: *Adapter, components: []const []const u8) Iterator {
        return adapter.world.entities.query(components);
    }
};

pub const System = fn (adapter: *Adapter) void;

pub const World = struct {
    allocator: Allocator,
    systems: std.StringArrayHashMapUnmanaged(System) = .{},
    entities: Entities,

    pub fn init(allocator: Allocator) !World {
        return World{
            .allocator = allocator,
            .entities = try Entities.init(allocator),
        };
    }

    pub fn deinit(world: *World) void {
        world.systems.deinit(world.allocator);
        world.entities.deinit();
    }

    pub fn register(world: *World, name: []const u8, system: System) !void {
        try world.systems.put(world.allocator, name, system);
    }

    pub fn unregister(world: *World, name: []const u8) void {
        world.systems.orderedRemove(name);
    }

    pub fn tick(world: *World) void {
        var i: usize = 0;
        while (i < world.systems.count()) : (i += 1) {
            const system = world.systems.entries.get(i).value;

            var adapter = Adapter{
                .world = world,
            };
            system(&adapter);
        }
    }
};
