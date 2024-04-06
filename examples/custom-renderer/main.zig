const mach = @import("mach");

const Renderer = @import("Renderer.zig");
const Game = @import("Game.zig");

// The global list of Mach modules registered for use in our application.
pub const modules = .{
    mach.Engine,
    Renderer,
    Game,
};

pub const App = mach.App;
