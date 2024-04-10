const std = @import("std");

const mach = @import("mach");
const Game = @import("Game.zig");

// The global list of Mach modules registered for use in our application.
pub const modules = .{
    mach.Core,
    Game,
};

pub fn main() !void {
    // Initialize mach.Core
    try mach.core.initModule();

    // Main loop
    while (try mach.core.tick()) {}
}
