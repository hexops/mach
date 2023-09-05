pub const core = @import("core");
pub const GPUInterface = core.GPUInterface;
pub const scope_levels = core.scope_levels;
pub const log_level = core.log_level;
pub const Timer = core.Timer;
pub const gpu = core.gpu;

pub const sysjs = @import("sysjs");
pub const ecs = @import("ecs");
pub const sysaudio = @import("sysaudio");
pub const earcut = @import("earcut");
pub const gfx = @import("gfx/util.zig");
pub const gfx2d = struct {
    pub const Sprite2D = @import("gfx2d/Sprite2D.zig");
};
pub const math = @import("math/main.zig");
pub const testing = @import("testing.zig");

pub const Atlas = @import("atlas/Atlas.zig");

// Engine exports
pub const App = @import("engine.zig").App;
pub const Engine = @import("engine.zig").Engine;
pub const World = @import("engine.zig").World;
pub const Mod = World.Mod;

const std = @import("std");

test {
    std.testing.refAllDeclsRecursive(gfx);
    std.testing.refAllDeclsRecursive(Atlas);
    std.testing.refAllDeclsRecursive(math);
    _ = ecs;
    _ = earcut;
}
