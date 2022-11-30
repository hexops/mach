pub usingnamespace @import("structs.zig");
pub usingnamespace @import("enums.zig");
pub const Core = @import("Core.zig");
pub const Timer = @import("Timer.zig");
pub const ResourceManager = @import("resource/ResourceManager.zig");

pub const gpu = @import("gpu");
pub const ecs = @import("ecs");
pub const sysaudio = @import("sysaudio");
pub const sysjs = @import("sysjs");
pub const earcut = @import("earcut");
pub const gfx = @import("gfx/util.zig");

// Engine exports
pub const App = @import("engine.zig").App;
pub const module = @import("engine.zig").module;

const std = @import("std");
const testing = std.testing;

test {
    // TODO: can't reference because they import "app"
    // testing.refAllDeclsRecursive(Core);
    // testing.refAllDeclsRecursive(Timer);
    testing.refAllDeclsRecursive(ResourceManager);
    testing.refAllDeclsRecursive(gfx);
}
