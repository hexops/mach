const std = @import("std");

const mach = @import("mach");
const Game = @import("Game.zig");

// The global list of Mach modules registered for use in our application.
pub const modules = .{
    mach.Core,
    Game,
};

pub const GPUInterface = mach.core.wgpu.dawn.Interface;

pub fn main() !void {
    // Initialize mach.Core
    try mach.core.initModule();

    // Main loop
    while (try mach.core.tick()) {}
}
