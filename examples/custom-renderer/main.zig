const std = @import("std");

const mach = @import("mach");
const Renderer = @import("Renderer.zig");
const Game = @import("Game.zig");

// The global list of Mach modules registered for use in our application.
pub const modules = .{
    mach.Core,
    Renderer,
    Game,
};

pub const GPUInterface = mach.core.wgpu.dawn.Interface;

// TODO: move this to a mach "entrypoint" zig module
pub fn main() !void {
    // Initialize mach core
    try mach.core.initModule();

    // Main loop
    while (try mach.core.tick()) {}
}
