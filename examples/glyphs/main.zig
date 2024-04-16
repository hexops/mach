// TODO(important): review all code in this file in-depth

// Experimental ECS app example. Not yet ready for actual use.
const mach = @import("mach");

const Game = @import("Game.zig");
const Text = @import("Text.zig");

// The list of modules to be used in our application. Our game itself is implemented in our own
// module called Game.
pub const modules = .{
    mach.Engine,
    mach.gfx.Sprite,
    mach.gfx.SpritePipeline,
    Text,
    Game,
};

pub const App = mach.App;
