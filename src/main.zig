const core = @import("core");
pub const GPUInterface = core.GPUInterface;
pub const scope_levels = core.scope_levels;
pub const log_level = core.log_level;
pub const Core = core.Core;
pub const Timer = core.Timer;
pub const gpu = core.gpu;
pub const sysjs = core.sysjs;

pub const ecs = @import("ecs");
pub const sysaudio = @import("sysaudio");
pub const earcut = @import("earcut");
pub const gfx = @import("gfx/util.zig");
pub const ResourceManager = @import("resource/ResourceManager.zig");

// Engine exports
pub const App = @import("engine.zig").App;
pub const module = @import("engine.zig").module;

const std = @import("std");

test {
    std.testing.refAllDeclsRecursive(ResourceManager);
    std.testing.refAllDeclsRecursive(gfx);
}
