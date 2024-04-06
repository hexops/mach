const std = @import("std");
const mach = @import("../main.zig");
const testing = std.testing;

pub const EntityID = @import("entities.zig").EntityID;
pub const Entities = @import("entities.zig").Entities;
pub const Archetype = @import("Archetype.zig");
pub const ModSet = @import("module.zig").ModSet;
pub const Modules = @import("module.zig").Modules;

test {
    std.testing.refAllDeclsRecursive(@This());
    std.testing.refAllDeclsRecursive(@import("Archetype.zig"));
    std.testing.refAllDeclsRecursive(@import("entities.zig"));
    std.testing.refAllDeclsRecursive(@import("query.zig"));
    std.testing.refAllDeclsRecursive(@import("StringTable.zig"));
}

test "entities DB" {
    const allocator = testing.allocator;

    const root = struct {
        pub const modules = .{ Renderer, Physics };

        const Physics = struct {
            pointer: u8,

            pub const name = .physics;
            pub const components = .{
                .id = .{ .type = u32 },
            };
            pub const global_events = .{
                .tick = .{ .handler = tick },
            };

            fn tick(physics: *mach.ModSet(modules).Mod(Physics)) void {
                _ = physics;
            }
        };

        const Renderer = struct {
            pub const name = .renderer;
            pub const components = .{
                .id = .{ .type = u16 },
            };
            pub const global_events = .{
                .tick = .{ .handler = tick },
            };

            fn tick(
                physics: *mach.ModSet(modules).Mod(Physics),
                renderer: *mach.ModSet(modules).Mod(Renderer),
            ) void {
                _ = renderer;
                _ = physics;
            }
        };
    };

    //-------------------------------------------------------------------------
    // Create a world.
    var world: Modules(root.modules) = undefined;
    try world.init(allocator);
    defer world.deinit(allocator);

    // Initialize module state.
    var physics = &world.mod.physics;
    var renderer = &world.mod.renderer;
    physics.init(.{ .pointer = 123 });
    _ = physics.state().pointer; // == 123

    const player1 = try physics.newEntity();
    const player2 = try physics.newEntity();
    const player3 = try physics.newEntity();
    try physics.set(player1, .id, 1001);
    try renderer.set(player1, .id, 1001);

    try physics.set(player2, .id, 1002);
    try physics.set(player3, .id, 1003);

    //-------------------------------------------------------------------------
    // Querying
    var iter = world.entities.query(.{ .all = &.{
        .{ .physics = &.{.id} },
    } });

    var archetype = iter.next().?;
    var ids = archetype.slice(.physics, .id);
    try testing.expectEqual(@as(usize, 2), ids.len);
    try testing.expectEqual(@as(usize, 1002), ids[0]);
    try testing.expectEqual(@as(usize, 1003), ids[1]);

    archetype = iter.next().?;
    ids = archetype.slice(.physics, .id);
    try testing.expectEqual(@as(usize, 1), ids.len);
    try testing.expectEqual(@as(usize, 1001), ids[0]);

    // TODO: can't write @as type here easily due to generic parameter, should be exposed
    // ?Archetype.Slicer(all_components)
    try testing.expectEqual(iter.next(), null);

    //-------------------------------------------------------------------------
    // Send events to modules
    world.mod.renderer.sendGlobal(.tick, .{});
    try world.dispatch(.{});
}
