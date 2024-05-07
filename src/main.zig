const build_options = @import("build-options");
const builtin = @import("builtin");

// Core
pub const core = if (build_options.want_core) @import("core/main.zig") else struct {};
pub const Timer = if (build_options.want_core) core.Timer else struct {};
pub const wgpu = if (build_options.want_core) @import("gpu/main.zig") else struct {};
pub const sysjs = if (build_options.want_core) @import("mach-sysjs") else struct {};
pub const Core = if (build_options.want_core) @import("Core.zig") else struct {};

// Mach standard library
// gamemode requires libc on linux
pub const gamemode = if (builtin.os.tag != .linux or builtin.link_libc) @import("gamemode.zig");
pub const gfx = if (build_options.want_mach) @import("gfx/main.zig") else struct {};
pub const Audio = if (build_options.want_sysaudio) @import("Audio.zig") else struct {};
pub const math = @import("math/main.zig");
pub const testing = @import("testing.zig");

pub const sysaudio = if (build_options.want_sysaudio) @import("sysaudio/main.zig") else struct {};
pub const sysgpu = if (build_options.want_sysgpu) @import("sysgpu/main.zig") else struct {};

// Module system
pub const modules = blk: {
    if (!@hasDecl(@import("root"), "modules")) {
        @compileError("expected `pub const modules = .{};` in root file");
    }
    break :blk merge(.{
        builtin_modules,
        @import("root").modules,
    });
};
pub const ModSet = @import("module/main.zig").ModSet;
pub const Modules = @import("module/main.zig").Modules(modules);
pub const Mod = ModSet(modules).Mod;
pub const EntityID = @import("module/main.zig").EntityID; // TODO: rename to just Entity?
pub const Archetype = @import("module/main.zig").Archetype;

pub const ModuleID = @import("module/main.zig").ModuleID;
pub const EventID = @import("module/main.zig").EventID;
pub const AnyEvent = @import("module/main.zig").AnyEvent;
pub const merge = @import("module/main.zig").merge;
pub const builtin_modules = @import("module/main.zig").builtin_modules;
pub const Entity = @import("module/main.zig").Entity;

/// To use experimental sysgpu graphics API, you can write this in your main.zig:
///
/// ```
/// pub const use_sysgpu = true;
/// ```
pub const use_sysgpu = if (@hasDecl(@import("root"), "use_sysgpu")) @import("root").use_sysgpu else false;
pub const gpu = if (use_sysgpu) sysgpu.sysgpu else wgpu;

test {
    const std = @import("std");
    // TODO: refactor code so we can use this here:
    // std.testing.refAllDeclsRecursive(@This());
    _ = core;
    _ = gpu;
    _ = sysaudio;
    _ = sysgpu;
    _ = gfx;
    _ = math;
    _ = testing;
    // std.testing.refAllDeclsRecursive(@import("module/main.zig"));
    std.testing.refAllDeclsRecursive(gamemode);
    std.testing.refAllDeclsRecursive(math);
}
