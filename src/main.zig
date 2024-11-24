//! The Mach standard library

const build_options = @import("build-options");
const builtin = @import("builtin");
const std = @import("std");

pub const is_debug = builtin.mode == .Debug;

// Core
pub const Core = if (build_options.want_core) @import("Core.zig") else struct {};

// note: gamemode requires libc on linux
pub const gamemode = if (builtin.os.tag != .linux or builtin.link_libc) @import("gamemode.zig");
// TODO(object)
// pub const gfx = if (build_options.want_mach) @import("gfx/main.zig") else struct {};
// TODO(object)
// pub const Audio = if (build_options.want_sysaudio) @import("Audio.zig") else struct {};
pub const math = @import("math/main.zig");
pub const testing = @import("testing.zig");
pub const time = @import("time/main.zig");

pub const sysaudio = if (build_options.want_sysaudio) @import("sysaudio/main.zig") else struct {};
pub const sysgpu = if (build_options.want_sysgpu) @import("sysgpu/main.zig") else struct {};
pub const gpu = if (build_options.want_sysgpu) @import("sysgpu/main.zig").sysgpu else struct {};

pub const Modules = @import("module.zig").Modules;

pub const ModuleID = @import("module.zig").ModuleID;
pub const ModuleFunctionID = @import("module.zig").ModuleFunctionID;
pub const FunctionID = @import("module.zig").FunctionID;
pub const Mod = @import("module.zig").Mod;
pub const ObjectID = @import("module.zig").ObjectID;
pub const Objects = @import("module.zig").Objects;

// TODO(object): remove this?
pub fn schedule(v: anytype) @TypeOf(v) {
    return v;
}

test {
    // TODO: refactor code so we can use this here:
    // std.testing.refAllDeclsRecursive(@This());
    _ = Core;
    _ = gpu;
    _ = sysaudio;
    _ = sysgpu;
    // TODO(object)
    // _ = gfx;
    // TODO(object)
    // _ = Audio;
    _ = math;
    _ = testing;
    _ = time;
    _ = @import("mpsc.zig");
    _ = @import("graph.zig");
    std.testing.refAllDeclsRecursive(gamemode);
    std.testing.refAllDeclsRecursive(math);
}
