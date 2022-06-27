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
//! Critically, this entity component system stores components for a classified archetype using
//! independent arrays allocated per component as well as hashmaps for sparse component data as an
//! optimization. This is a novel and fundamentally different process than what is described in
//! Unity Software Inc's patent US 10,599,560. This is not legal advice.
//!

const std = @import("std");
const testing = std.testing;

pub const EntityID = @import("entities.zig").EntityID;
pub const Entities = @import("entities.zig").Entities;

pub const Adapter = @import("systems.zig").Adapter;
pub const System = @import("systems.zig").System;
pub const Module = @import("systems.zig").Module;
pub const Modules = @import("systems.zig").Modules;
pub const Messages = @import("systems.zig").Messages;
pub const MessagesTag = @import("systems.zig").MessagesTag;
pub const World = @import("systems.zig").World;

// TODO:
// * Iteration
// * Querying
// * Multi threading
// * Multiple entities having one value
// * Sparse storage?

test "inclusion" {
    _ = Entities;
}

test "example" {
    const allocator = testing.allocator;

    const PhysicsMsg = Messages(.{
        .tick = void,
    });
    const physicsUpdate = (struct {
        pub fn physicsUpdate(msg: PhysicsMsg) void {
            switch (msg) {
                .tick => std.debug.print("\nphysics tick!\n", .{}),
            }
        }
    }).physicsUpdate;

    const modules = Modules(.{
        .physics = Module(.{
            .components = .{
                .id = u32,
            },
            .globals = struct {
                pointer: u8,
            },
            .messages = PhysicsMsg,
            .update = physicsUpdate,
        }),
        .renderer = Module(.{
            .components = .{
                .id = u16,
            },
        }),
    });

    //-------------------------------------------------------------------------
    // Create a world.
    var world = try World(modules).init(allocator);
    defer world.deinit();

    // Initialize globals.
    world.set(.physics, .pointer, 123);
    _ = world.get(.physics, .pointer); // == 123

    const player1 = try world.entities.new();
    const player2 = try world.entities.new();
    const player3 = try world.entities.new();
    try world.entities.setComponent(player1, .physics, .id, 1234);
    try world.entities.setComponent(player1, .renderer, .id, 1234);

    try world.entities.setComponent(player2, .physics, .id, 1234);
    try world.entities.setComponent(player3, .physics, .id, 1234);

    world.tick();
}
