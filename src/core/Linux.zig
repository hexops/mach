const std = @import("std");
const mach = @import("../main.zig");
const Core = @import("../Core.zig");
const X11 = @import("linux/X11.zig");
const Wayland = @import("linux/Wayland.zig");
const gpu = mach.gpu;
const InitOptions = Core.InitOptions;
const Event = Core.Event;
const KeyEvent = Core.KeyEvent;
const MouseButtonEvent = Core.MouseButtonEvent;
const MouseButton = Core.MouseButton;
const Size = Core.Size;
const DisplayMode = Core.DisplayMode;
const CursorShape = Core.CursorShape;
const VSyncMode = Core.VSyncMode;
const CursorMode = Core.CursorMode;
const Position = Core.Position;
const Key = Core.Key;
const KeyMods = Core.KeyMods;

const log = std.log.scoped(.mach);
const gamemode_log = std.log.scoped(.gamemode);

const BackendEnum = enum {
    x11,
    wayland,
};

const Backend = union(BackendEnum) {
    x11: X11,
    wayland: Wayland,
};

pub const Native = union(BackendEnum) {
    x11: X11.Native,
    wayland: Wayland.Native,
};

pub const Linux = @This();

allocator: std.mem.Allocator,
title: [:0]const u8,

display_mode: DisplayMode,
vsync_mode: VSyncMode,
cursor_mode: CursorMode,
cursor_shape: CursorShape,
border: bool,
headless: bool,
refresh_rate: u32,
size: Size,
surface_descriptor: gpu.Surface.Descriptor,
gamemode: ?bool = null,
backend: Backend,

// these arrays are used as info messages to the user that some features are missing
// please keep these up to date until we can remove them
const MISSING_FEATURES_X11 = [_][]const u8{ "Resizing window", "Changing display mode", "VSync", "Setting window border/cursor" };
const MISSING_FEATURES_WAYLAND = [_][]const u8{ "Changing display mode", "VSync", "Setting window border/cursor" };

pub fn run(comptime on_each_update_fn: anytype, args_tuple: std.meta.ArgsTuple(@TypeOf(on_each_update_fn))) void {
    while (@call(.auto, on_each_update_fn, args_tuple) catch false) {}
}

pub fn tick(core: *Core, core_mod: mach.Mod(Core)) !void {
    var windows = core.windows.slice();
    while (windows.next()) |window_id| {
        const native_opt: ?Native = core.windows.get(window_id, .native);
        if (native_opt) |native| {
            // checks for updates in mach object fields
            const core_window = core.windows.getValue(window_id);
            if (core.windows.updated(window_id, .title)) {
                setTitle(&native, core_window.title);
            }
            if (core.windows.updated(window_id, .display_mode) or core.windows.updated(window_id, .decorated)) {
                setDisplayMode(&native, core_window.display_mode, core_window.decorated);
                setBorder(&native, core_window.decorated);
            }
            // check for display server events
            switch (native) {
                .x11 => try X11.tick(window_id),
                .wayland => try Wayland.tick(window_id),
            }
            renewSwapChain(core, window_id);

            // Re-read after renewSwapChain may have replaced the swap chain
            const updated_window = core.windows.getValue(window_id);

            // Run render callback and present frame
            if (updated_window.on_render) |on_render| {
                core_mod.run(on_render);
                mach.sysgpu.Impl.deviceTick(updated_window.device);
                updated_window.swap_chain.present();
            }
        } else {
            try initWindow(core, window_id);
            // Consume the initial updated flags so we don't spuriously
            // call setDisplayMode/setBorder on the next tick.
            _ = core.windows.updated(window_id, .display_mode);
            _ = core.windows.updated(window_id, .decorated);
        }
    }
}

inline fn renewSwapChain(core: *Core, window_id: mach.ObjectID) void {
    var core_window = core.windows.getValue(window_id);
    if (core_window.framebuffer_width != core_window.width or
        core_window.framebuffer_height != core_window.height)
    {
        core_window.framebuffer_width = core_window.width;
        core_window.framebuffer_height = core_window.height;
        core_window.swap_chain_descriptor.height = core_window.framebuffer_height;
        core_window.swap_chain_descriptor.width = core_window.framebuffer_width;

        core_window.swap_chain.release();
        core_window.swap_chain = core_window.device.createSwapChain(core_window.surface, &core_window.swap_chain_descriptor);
        core.windows.setValueRaw(window_id, core_window);
    }
}

pub fn initWindow(
    core: *Core,
    window_id: mach.ObjectID,
) !void {
    const force_backend: ?BackendEnum = blk: {
        const backend = std.process.getEnvVarOwned(
            core.allocator,
            "MACH_FORCE_BACKEND",
        ) catch |err| switch (err) {
            error.EnvironmentVariableNotFound => break :blk null,
            else => return err,
        };
        defer core.allocator.free(backend);

        if (std.ascii.eqlIgnoreCase(backend, "x11")) break :blk .x11;
        if (std.ascii.eqlIgnoreCase(backend, "wayland")) break :blk .wayland;
        std.debug.panic("mach: unknown MACH_FORCE_BACKEND: {s}", .{backend});
    };

    const desired_backend: BackendEnum = force_backend orelse .wayland;

    if (force_backend) |forced| {
        // MACH_FORCE_BACKEND: no fallback, fail hard if the forced backend can't init
        switch (forced) {
            .x11 => {
                X11.initWindow(core, window_id) catch |err| {
                    log.err("MACH_FORCE_BACKEND=x11: failed to initialize X11: {}", .{err});
                    return err;
                };
            },
            .wayland => {
                Wayland.initWindow(core, window_id) catch |err| {
                    log.err("MACH_FORCE_BACKEND=wayland: failed to initialize Wayland: {}", .{err});
                    return err;
                };
            },
        }
    } else {
        // Default: try Wayland first, fall back to X11
        Wayland.initWindow(core, window_id) catch |err| {
            const err_msg = switch (err) {
                error.NoDecorationSupport => "No window decoration support available",
                error.LibraryNotFound => "Missing Wayland library",
                error.FailedToConnectToDisplay => "Failed to connect to Wayland display",
                else => "An unknown error occured while trying to connect to Wayland",
            };

            log.err("{s}\n\nFalling back to X11\n", .{err_msg});
            X11.initWindow(core, window_id) catch |e| {
                log.err("Failed to connect to fallback display server, X11.\n", .{});
                var libs = std.ArrayList(u8).init(core.allocator);
                defer libs.deinit();
                if (Wayland.libwaylandclient == null) {
                    try libs.appendSlice("\t* " ++ Wayland.LibWaylandClient.lib_name ++ "\n");
                }
                if (Wayland.libxkbcommon == null) {
                    try libs.appendSlice("\t* " ++ Wayland.LibXkbCommon.lib_name ++ "\n");
                }
                log.err("The following Wayland libraries were not available:\n{s}", .{libs.items});
                return e;
            };
        };
    }

    // warn about incomplete features
    // TODO: remove this when linux is not missing major features
    try warnAboutIncompleteFeatures(desired_backend, &MISSING_FEATURES_X11, &MISSING_FEATURES_WAYLAND, core.allocator);
}

pub fn update(linux: *Linux) !void {
    switch (linux.backend) {
        .wayland => try linux.backend.wayland.update(linux),
        .x11 => try linux.backend.x11.update(linux),
    }
}

fn setTitle(native: *const Native, title: [:0]const u8) void {
    switch (native.*) {
        .wayland => |wl| Wayland.setTitle(&wl, title),
        .x11 => |x| X11.setTitle(&x, title),
    }
}

fn setDisplayMode(native: *const Native, display_mode: DisplayMode, decorated: bool) void {
    switch (native.*) {
        .wayland => Wayland.setDisplayMode(&native.wayland, display_mode),
        .x11 => X11.setDisplayMode(&native.x11, display_mode, decorated),
    }
}

fn setBorder(_: *const Native, _: bool) void {
    return;
}

pub fn setHeadless(_: *Linux, _: bool) void {
    return;
}

pub fn setVSync(_: *Linux, _: VSyncMode) void {
    return;
}

pub fn setSize(_: *Linux, _: Size) void {
    return;
}

pub fn setCursorMode(_: *Linux, _: CursorMode) void {
    return;
}

pub fn setCursorShape(_: *Linux, _: CursorShape) void {
    return;
}

/// Check if gamemode should be activated
pub fn wantGamemode(allocator: std.mem.Allocator) error{ OutOfMemory, InvalidWtf8 }!bool {
    const use_gamemode = std.process.getEnvVarOwned(
        allocator,
        "MACH_USE_GAMEMODE",
    ) catch |err| switch (err) {
        error.EnvironmentVariableNotFound => return true,
        else => |e| return e,
    };
    defer allocator.free(use_gamemode);

    return !(std.ascii.eqlIgnoreCase(use_gamemode, "off") or std.ascii.eqlIgnoreCase(use_gamemode, "false"));
}

pub fn initLinuxGamemode() bool {
    mach.gamemode.start();
    if (!mach.gamemode.isActive()) return false;
    gamemode_log.info("gamemode: activated\n", .{});
    return true;
}

pub fn deinitLinuxGamemode() void {
    mach.gamemode.stop();
    gamemode_log.info("gamemode: deactivated\n", .{});
}

/// Used to inform users that some features are not present. Remove when features are complete.
fn warnAboutIncompleteFeatures(backend: BackendEnum, missing_features_x11: []const []const u8, missing_features_wayland: []const []const u8, alloc: std.mem.Allocator) !void {
    const features_incomplete_message =
        \\You are using the {s} backend, which is currently experimental as we continue to rewrite Mach in Zig instead of using C libraries like GLFW/etc. The following features are expected to not work:
        \\
        \\{s}
        \\
        \\Contributions welcome!
        \\
    ;
    const bullet_points = switch (backend) {
        .x11 => try generateFeatureBulletPoints(missing_features_x11, alloc),
        .wayland => try generateFeatureBulletPoints(missing_features_wayland, alloc),
    };
    defer bullet_points.deinit();
    log.warn(features_incomplete_message, .{ @tagName(backend), bullet_points.items });
}

/// Turn an array of strings into a single, bullet-pointed string, like this:
/// * Item one
/// * Item two
///
/// Returned value will need to be deinitialized.
fn generateFeatureBulletPoints(features: []const []const u8, alloc: std.mem.Allocator) !std.ArrayList(u8) {
    var message = std.ArrayList(u8).init(alloc);
    for (features, 0..) |str, i| {
        try message.appendSlice("* ");
        try message.appendSlice(str);
        if (i < features.len - 1) {
            try message.appendSlice("\n");
        }
    }
    return message;
}
