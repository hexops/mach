const std = @import("std");
const testing = std.testing;
const ComponentTypesByName = @import("module.zig").ComponentTypesByName;
const merge = @import("main.zig").merge;
const builtin_modules = @import("main.zig").builtin_modules;

pub const QueryTag = enum {
    any,
    all,
};

/// A complex query for entities matching a given criteria
pub fn Query(comptime modules: anytype) type {
    const component_types_by_name = ComponentTypesByName(modules){};
    return union(QueryTag) {
        // TODO: cleanup comptime
        /// Enum matching a namespace. e.g. `.game` or `.physics2d`
        pub const Namespace = std.meta.FieldEnum(@TypeOf(component_types_by_name));

        // TODO: cleanup comptime
        /// Enum matching a component within a namespace
        /// e.g. `var a: Component(.physics2d) = .location`
        pub fn Component(comptime namespace: Namespace) type {
            const components = @field(component_types_by_name, @tagName(namespace));
            if (@typeInfo(@TypeOf(components)).Struct.fields.len == 0) return enum {};
            return std.meta.FieldEnum(@TypeOf(components));
        }

        // TODO: cleanup comptime
        /// Slice of enums matching a component within a namespace
        /// e.g. `&.{.location, .rotation}`
        pub fn ComponentList(comptime namespace: Namespace) type {
            return []const Component(namespace);
        }

        // TODO: cleanup comptime
        /// Tagged union of namespaces matching lists of components
        /// e.g. `.physics2d = &.{ .location, .rotation }`
        pub const NamespaceComponent = T: {
            const namespaces = std.meta.fields(Namespace);
            var fields: [namespaces.len]std.builtin.Type.UnionField = undefined;
            for (namespaces, 0..) |namespace, i| {
                const ns = stringToEnum(Namespace, namespace.name).?;
                fields[i] = .{
                    .name = namespace.name,
                    .type = ComponentList(ns),
                    .alignment = @alignOf(ComponentList(ns)),
                };
            }

            break :T @Type(.{ .Union = .{
                .layout = .Auto,
                .tag_type = Namespace,
                .fields = &fields,
                .decls = &.{},
            } });
        };

        /// Matches any of these components
        any: []const NamespaceComponent,

        /// Matches all of these components
        all: []const NamespaceComponent,
    };
}

// TODO: cannot use std.meta.stringToEnum for some reason; an issue with its internal comptime map and u0 values
pub fn stringToEnum(comptime T: type, str: []const u8) ?T {
    inline for (@typeInfo(T).Enum.fields) |enumField| {
        if (std.mem.eql(u8, str, enumField.name)) {
            return @field(T, enumField.name);
        }
    }
}

test "query" {
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
            };
        },
        struct {
            pub const name = .physics;
            pub const components = .{
                .location = .{ .type = Location },
                .rotation = .{ .type = Rotation },
            };
        },
        struct {
            pub const name = .renderer;
        },
    });

    const Q = Query(modules);

    // Namespace type lets us select a single namespace.
    try testing.expectEqual(@as(Q.Namespace, .game), .game);
    try testing.expectEqual(@as(Q.Namespace, .physics), .physics);

    // Component type lets us select a single component within a namespace.
    try testing.expectEqual(@as(Q.Component(.physics), .location), .location);
    try testing.expectEqual(@as(Q.Component(.game), .name), .name);

    // ComponentList type lets us select multiple components within a namespace.
    const x: Q.ComponentList(.physics) = &.{
        .location,
        .rotation,
    };
    _ = x;

    // NamespaceComponent lets us select multiple components within multiple namespaces.
    const y: []const Q.NamespaceComponent = &.{
        .{ .physics = &.{ .location, .rotation } },
        .{ .game = &.{.name} },
    };
    _ = y;

    // Query matching entities with *any* of these components
    const z: Q = .{ .any = &.{
        .{ .physics = &.{ .location, .rotation } },
        .{ .game = &.{.name} },
    } };
    _ = z;

    // Query matching entities with *all* of these components.
    const w: Q = .{ .all = &.{
        .{ .physics = &.{ .location, .rotation } },
        .{ .game = &.{.name} },
    } };
    _ = w;
}
