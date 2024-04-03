//! mach/ecs is an Entity component system implementation.
//!
//! ## Design principles:
//!
//! * Initially a 100% clean-room implementation, working from first-principles. Later informed by
//!   research into how other ECS work, with advice from e.g. Bevy and Flecs authors at different
//!   points (thank you!)
//! * Solve the problems ECS solves, in a way that is natural to Zig and leverages Zig comptime.
//! * Fast. Optimal for CPU caches, multi-threaded, leverage comptime as much as is reasonable.
//! * Simple. Small API footprint, should be natural and fun - not like you're writing boilerplate.
//! * Enable other libraries to provide tracing, editors, visualizers, profilers, etc.
//!

const std = @import("std");
const mach = @import("../main.zig");
const testing = std.testing;

pub const EntityID = @import("entities.zig").EntityID;
pub const Entities = @import("entities.zig").Entities;
pub const Archetype = @import("Archetype.zig");

pub const Modules = @import("../module.zig").Modules;

// TODO:
// * Iteration
// * Querying
// * Multi threading
// * Multiple entities having one value
// * Sparse storage?

test {
    std.testing.refAllDeclsRecursive(@This());
    std.testing.refAllDeclsRecursive(@import("Archetype.zig"));
    std.testing.refAllDeclsRecursive(@import("entities.zig"));
    std.testing.refAllDeclsRecursive(@import("query.zig"));
    std.testing.refAllDeclsRecursive(@import("StringTable.zig"));
}

test "example" {
    const allocator = testing.allocator;

    const root = struct {
        pub const modules = .{ Renderer, Physics };

        const Physics = struct {
            pointer: u8,

            pub const name = .physics;
            pub const components = .{
                .{ .name = .id, .type = u32 },
            };
            pub const global_events = .{
                .tick = .{ .handler = tick },
            };

            fn tick(physics: *Modules(modules).Mod(Physics)) void {
                _ = physics;
            }
        };

        const Renderer = struct {
            pub const name = .renderer;
            pub const components = .{
                .{ .name = .id, .type = u16 },
            };
            pub const global_events = .{
                .tick = .{ .handler = tick },
            };

            fn tick(
                physics: *Modules(modules).Mod(Physics),
                renderer: *Modules(modules).Mod(Renderer),
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

    // TODO: better module initialization location
    world.mod.physics.entities = &world.entities;
    world.mod.physics.allocator = world.entities.allocator;
    world.mod.renderer.entities = &world.entities;
    world.mod.renderer.allocator = world.entities.allocator;

    // Initialize module state.
    var physics = &world.mod.physics;
    var renderer = &world.mod.renderer;
    physics.state = .{ .pointer = 123 };
    _ = physics.state.pointer; // == 123

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
    // ?comp.ArchetypeSlicer(all_components)
    try testing.expectEqual(iter.next(), null);

    //-------------------------------------------------------------------------
    // Send events to modules
    world.mod.renderer.sendGlobal(.tick, .{});
    try world.dispatch();
}
