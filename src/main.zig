pub usingnamespace @import("entry.zig");
pub const Core = @import("Core.zig");
pub const Timer = @import("Timer.zig");
pub const gpu = @import("gpu");
pub const ecs = @import("ecs");
pub const sysaudio = @import("sysaudio");
pub const sysjs = @import("sysjs");
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
