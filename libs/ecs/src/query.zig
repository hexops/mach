const std = @import("std");
const testing = std.testing;

pub const QueryTag = enum {
    any,
    all,
};

/// A complex query for entities matching a given criteria
pub fn Query(comptime all_components: anytype) type {
    return union(QueryTag) {
        /// Enum matching a namespace. e.g. `.game` or `.physics2d`
        pub const Namespace = std.meta.FieldEnum(@TypeOf(all_components));

        /// Enum matching a component within a namespace
        /// e.g. `var a: Component(.physics2d) = .location`
        pub fn Component(comptime namespace: Namespace) type {
            return std.meta.FieldEnum(@TypeOf(@field(all_components, @tagName(namespace))));
        }

        /// Slice of enums matching a component within a namespace
        /// e.g. `&.{.location, .rotation}`
        pub fn ComponentList(comptime namespace: Namespace) type {
            return []const Component(namespace);
        }

        /// Tagged union of namespaces matching lists of components
        /// e.g. `.physics2d = &.{ .location, .rotation }`
        pub const NamespaceComponent = T: {
            const namespaces = std.meta.fields(Namespace);
            var fields: [namespaces.len]std.builtin.Type.UnionField = undefined;
            inline for (namespaces, 0..) |namespace, i| {
                const ns = std.meta.stringToEnum(Namespace, namespace.name).?;
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

test "query" {
    const Location = struct {
        x: f32 = 0,
        y: f32 = 0,
        z: f32 = 0,
    };

    const Rotation = struct { degrees: f32 };

    const all_components = .{
        .game = .{
            .name = []const u8,
        },
        .physics = .{
            .location = Location,
            .rotation = Rotation,
        },
    };

    const Q = Query(all_components);

    // Namespace type lets us select a single namespace.
    try testing.expectEqual(@as(Q.Namespace, .game), .game);
    try testing.expectEqual(@as(Q.Namespace, .physics), .physics);

    // Component type lets us select a single component within a namespace.
    try testing.expectEqual(@as(Q.Component(.physics), .location), .location);
    try testing.expectEqual(@as(Q.Component(.game), .name), .name);

    // ComponentList type lets us select multiple components within a namespace.
    var x: Q.ComponentList(.physics) = &.{
        .location,
        .rotation,
    };
    _ = x;

    // NamespaceComponent lets us select multiple components within multiple namespaces.
    var y: []const Q.NamespaceComponent = &.{
        .{ .physics = &.{ .location, .rotation } },
        .{ .game = &.{.name} },
    };
    _ = y;

    // Query matching entities with *any* of these components
    var z: Q = .{ .any = &.{
        .{ .physics = &.{ .location, .rotation } },
        .{ .game = &.{.name} },
    } };
    _ = z;

    // Query matching entities with *all* of these components.
    var w: Q = .{ .all = &.{
        .{ .physics = &.{ .location, .rotation } },
        .{ .game = &.{.name} },
    } };
    _ = w;
}
