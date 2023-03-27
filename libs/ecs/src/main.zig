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
const testing = std.testing;

pub const EntityID = @import("entities.zig").EntityID;
pub const Entities = @import("entities.zig").Entities;

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
    std.testing.refAllDeclsRecursive(@This());
}

test "example" {
    const allocator = testing.allocator;

    const Physics2D = Module(struct {
        pointer: u8,

        pub const name = .physics;
        pub const components = .{
            .id = u32,
        };
        pub const Message = .{
            .tick = void,
        };

        pub fn update(msg: Message) void {
            switch (msg) {
                .tick => std.debug.print("\nphysics tick!\n", .{}),
            }
        }
    });

    const Renderer = Module(struct {
        pub const name = .renderer;
        pub const components = .{
            .id = u16,
        };
    });

    const modules = Modules(.{
        Physics2D,
        Renderer,
    });

    //-------------------------------------------------------------------------
    // Create a world.
    var world = try World(modules).init(allocator);
    defer world.deinit();

    // Initialize module state.
    var physics = world.mod(.physics);
    var renderer = world.mod(.renderer);
    physics.initState(.{ .pointer = 123 });
    _ = physics.state().pointer; // == 123

    const player1 = try world.newEntity();
    const player2 = try world.newEntity();
    const player3 = try world.newEntity();
    try physics.set(player1, .id, 1234);
    try renderer.set(player1, .id, 1234);

    try physics.set(player2, .id, 1234);
    try physics.set(player3, .id, 1234);

    try world.send(.tick);
}
