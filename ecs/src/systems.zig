const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const testing = std.testing;
const StructField = std.builtin.Type.StructField;

const Entities = @import("entities.zig").Entities;

pub fn Adapter(modules: anytype) type {
    const all_components = NamespacedComponents(modules);
    return struct {
        world: *World(modules),

        const Self = @This();
        pub const Iterator = Entities(all_components).Iterator;

        pub fn query(adapter: *Self, components: []const []const u8) Iterator {
            return adapter.world.entities.query(components);
        }
    };
}

/// An ECS module can provide components, systems, and global values.
pub fn Module(comptime Params: anytype) @TypeOf(Params) {
    // TODO: validate the type
    return Params;
}

/// Describes a set of ECS modules, each of which can provide components, systems, and more.
pub fn Modules(modules: anytype) @TypeOf(modules) {
    // TODO: validate the type
    return modules;
}

/// Returns the namespaced components struct **type**.
//
/// Consult `namespacedComponents` for how a value of this type looks.
fn NamespacedComponents(comptime modules: anytype) type {
    var fields: []const StructField = &[0]StructField{};
    inline for (std.meta.fields(@TypeOf(modules))) |module_field| {
        const module = @field(modules, module_field.name);
        if (@hasField(@TypeOf(module), "components")) {
            fields = fields ++ [_]std.builtin.Type.StructField{.{
                .name = module_field.name,
                .field_type = @TypeOf(module.components),
                .default_value = null,
                .is_comptime = false,
                .alignment = @alignOf(@TypeOf(module.components)),
            }};
        }
    }
    return @Type(.{
        .Struct = .{
            .layout = .Auto,
            .is_tuple = false,
            .fields = fields,
            .decls = &[_]std.builtin.Type.Declaration{},
        },
    });
}

/// Extracts namespaces components from modules like this:
///
/// ```
/// .{
///     .renderer = .{
///         .components = .{
///             .location = Vec3,
///             .rotation = Vec3,
///         },
///         ...
///     },
///     .physics2d = .{
///         .components = .{
///             .location = Vec2
///             .velocity = Vec2,
///         },
///         ...
///     },
/// }
/// ```
///
/// Returning a namespaced components value like this:
///
/// ```
/// .{
///     .renderer = .{
///         .location = Vec3,
///         .rotation = Vec3,
///     },
///     .physics2d = .{
///         .location = Vec2
///         .velocity = Vec2,
///     },
/// }
/// ```
///
fn namespacedComponents(comptime modules: anytype) NamespacedComponents(modules) {
    var x: NamespacedComponents(modules) = undefined;
    inline for (std.meta.fields(@TypeOf(modules))) |module_field| {
        const module = @field(modules, module_field.name);
        if (@hasField(@TypeOf(module), "components")) {
            @field(x, module_field.name) = module.components;
        }
    }
    return x;
}

pub fn World(comptime modules: anytype) type {
    const all_components = namespacedComponents(modules);
    return struct {
        allocator: Allocator,
        systems: std.StringArrayHashMapUnmanaged(System) = .{},
        entities: Entities(all_components),

        const Self = @This();
        pub const System = fn (adapter: *Adapter(modules)) void;

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

                var adapter = Adapter(modules){
                    .world = world,
                };
                system(&adapter);
            }
        }
    };
}
