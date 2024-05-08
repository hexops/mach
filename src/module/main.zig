const std = @import("std");
const mach = @import("../main.zig");
const testing = std.testing;

pub const EntityID = @import("entities.zig").EntityID;
pub const Database = @import("entities.zig").Database;
pub const Archetype = @import("Archetype.zig");
pub const ModSet = @import("module.zig").ModSet;
pub const Modules = @import("module.zig").Modules;
pub const ModuleID = @import("module.zig").ModuleID;
pub const EventID = @import("module.zig").EventID;
pub const AnyEvent = @import("module.zig").AnyEvent;
pub const Merge = @import("module.zig").Merge;
pub const merge = @import("module.zig").merge;

pub const builtin_modules = .{Entities};

/// Builtin .entities module
pub const Entities = struct {
    pub const name = .entities;

    pub const Mod = mach.Mod(@This());

    pub const components = .{
        .id = .{ .type = EntityID, .description = "Entity ID" },
    };
};

test {
    // std.testing.refAllDeclsRecursive(@This());
    std.testing.refAllDeclsRecursive(@import("Archetype.zig"));
    std.testing.refAllDeclsRecursive(@import("entities.zig"));
    std.testing.refAllDeclsRecursive(@import("StringTable.zig"));
}

test "entities DB" {
    const allocator = testing.allocator;

    const root = struct {
        pub const modules = merge(.{ builtin_modules, Renderer, Physics });

        const Physics = struct {
            pointer: u8,

            pub const name = .physics;
            pub const components = .{
                .id = .{ .type = u32 },
            };
            pub const events = .{
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
            pub const events = .{
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
    var entities = &world.mod.entities;
    var physics = &world.mod.physics;
    var renderer = &world.mod.renderer;
    physics.init(.{ .pointer = 123 });
    _ = physics.state().pointer; // == 123

    const player1 = try entities.new();
    const player2 = try entities.new();
    const player3 = try entities.new();
    try physics.set(player1, .id, 1001);
    try renderer.set(player1, .id, 1001);

    try physics.set(player2, .id, 1002);
    try physics.set(player3, .id, 1003);

    //-------------------------------------------------------------------------
    // Send events to modules
    world.mod.renderer.send(.tick, .{});
    var stack_space: [8 * 1024 * 1024]u8 = undefined;
    try world.dispatch(&stack_space, .{});
}
