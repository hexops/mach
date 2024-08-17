const build_options = @import("build-options");
const builtin = @import("builtin");
const std = @import("std");

// Core
pub const Core = if (build_options.want_core) @import("Core.zig") else struct {};
pub const Timer = if (build_options.want_core) Core.Timer else struct {};
pub const sysjs = if (build_options.want_core) @import("mach-sysjs") else struct {};

// Mach standard library
// gamemode requires libc on linux
pub const gamemode = if (builtin.os.tag != .linux or builtin.link_libc) @import("gamemode.zig");
pub const gfx = if (build_options.want_mach) @import("gfx/main.zig") else struct {};
pub const Audio = if (build_options.want_sysaudio) @import("Audio.zig") else struct {};
pub const math = @import("math/main.zig");
pub const testing = @import("testing.zig");

pub const sysaudio = if (build_options.want_sysaudio) @import("sysaudio/main.zig") else struct {};
pub const sysgpu = if (build_options.want_sysgpu) @import("sysgpu/main.zig") else struct {};
pub const gpu = sysgpu.sysgpu;

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
pub const ModuleName = @import("module/main.zig").ModuleName(modules);
pub const EntityID = @import("module/main.zig").EntityID; // TODO: rename to just Entity?
pub const Archetype = @import("module/main.zig").Archetype;

pub const ModuleID = @import("module/main.zig").ModuleID;
pub const SystemID = @import("module/main.zig").SystemID;
pub const AnySystem = @import("module/main.zig").AnySystem;
pub const merge = @import("module/main.zig").merge;
pub const builtin_modules = @import("module/main.zig").builtin_modules;
pub const Entities = @import("module/main.zig").Entities;

pub const is_debug = builtin.mode == .Debug;

pub const App = struct {
    mods: *Modules,
    comptime main_mod: ModuleName = .app,

    pub fn init(allocator: std.mem.Allocator, comptime main_mod: ModuleName) !App {
        var mods: *Modules = try allocator.create(Modules);
        try mods.init(allocator);

        return .{
            .mods = mods,
            .main_mod = main_mod,
        };
    }

    pub fn deinit(app: *App, allocator: std.mem.Allocator) void {
        app.mods.deinit(allocator);
        allocator.destroy(app.mods);
    }

    pub fn run(app: *App, core_options: Core.InitOptions) !void {
        var stack_space: [8 * 1024 * 1024]u8 = undefined;

        app.mods.mod.mach_core.init(undefined); // TODO
        app.mods.scheduleWithArgs(.mach_core, .init, .{core_options});
        app.mods.schedule(app.main_mod, .init);

        // Main loop
        if (comptime builtin.target.isDarwin()) {
            Core.Platform.run(on_each_update, .{app, &stack_space});
        } else {
            while (try app.on_each_update(&stack_space)) {}
        }
    }

    fn on_each_update(app: *App, stack_space: []u8) !bool {
        if (app.mods.mod.mach_core.state().should_close) {
            // Final Dispatch to deinitalize resources
            app.mods.schedule(app.main_mod, .deinit);
            try app.mods.dispatch(stack_space, .{});
            app.mods.schedule(.mach_core, .deinit);
            try app.mods.dispatch(stack_space, .{});
            return false;
        }

        // Dispatch events until queue is empty
        try app.mods.dispatch(stack_space, .{});
        // Run `update` when `init` and all other systems are exectued
        app.mods.schedule(app.main_mod, .update);
        return true;
    }
};

test {
    // TODO: refactor code so we can use this here:
    // std.testing.refAllDeclsRecursive(@This());
    _ = Core;
    _ = gpu;
    _ = sysaudio;
    _ = sysgpu;
    _ = gfx;
    _ = math;
    _ = testing;
    std.testing.refAllDeclsRecursive(@import("module/Archetype.zig"));
    std.testing.refAllDeclsRecursive(@import("module/entities.zig"));
    // std.testing.refAllDeclsRecursive(@import("module/main.zig"));
    std.testing.refAllDeclsRecursive(@import("module/module.zig"));
    std.testing.refAllDeclsRecursive(@import("module/StringTable.zig"));
    std.testing.refAllDeclsRecursive(gamemode);
    std.testing.refAllDeclsRecursive(math);
}
