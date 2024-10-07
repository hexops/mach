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

pub const Linux = @This();

allocator: std.mem.Allocator,

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

pub fn init(
    linux: *Linux,
    core: *Core.Mod,
    options: InitOptions,
) !void {
    linux.allocator = options.allocator;

    if (!options.is_app and try wantGamemode(linux.allocator)) linux.gamemode = initLinuxGamemode();

    const desired_backend: BackendEnum = blk: {
        const backend = std.process.getEnvVarOwned(
            linux.allocator,
            "MACH_CORE_BACKEND",
        ) catch |err| switch (err) {
            error.EnvironmentVariableNotFound => {
                // TODO(core): default to .x11 in the future
                break :blk .wayland;
            },
            else => return err,
        };
        defer linux.allocator.free(backend);

        if (std.ascii.eqlIgnoreCase(backend, "x11")) break :blk .x11;
        if (std.ascii.eqlIgnoreCase(backend, "wayland")) break :blk .wayland;
        std.debug.panic("mach: unknown MACH_CORE_BACKEND: {s}", .{backend});
    };

    if (desired_backend == .x11) {
        // TODO(core): support X11 in the future
        @panic("X11 is not supported...YET");
    }

    // Try to initialize the desired backend, falling back to the other if that one is not supported
    switch (desired_backend) {
        .x11 => {
            // const x11 = X11.init(linux, core, options) catch |err| switch (err) {
            //     error.NotSupported => {
            //         log.err("failed to initialize X11 backend, falling back to Wayland", .{});
            //         linux.backend = .{ .wayland = try Wayland.init(linux, core, options) };
            //     },
            //     else => return err,
            // };
            // linux.backend = .{ .x11 = x11 };
        },
        .wayland => {
            const wayland = Wayland.init(linux, core, options) catch |err| switch (err) {
                error.LibraryNotFound => {
                    log.err("failed to initialize Wayland backend, falling back to X11", .{});
                    linux.backend = .{ .x11 = try X11.init(linux, core, options) };

                    // TODO(core): support X11 in the future
                    @panic("X11 is not supported...YET");
                },
                else => return err,
            };
            linux.backend = .{ .wayland = wayland };
        },
    }

    switch (linux.backend) {
        .wayland => |be| {
            linux.surface_descriptor = .{ .next_in_chain = .{ .from_wayland_surface = be.surface_descriptor } };
        },
        .x11 => |be| {
            linux.surface_descriptor = .{ .next_in_chain = .{ .from_xlib_window = be.surface_descriptor } };
        },
    }

    linux.refresh_rate = 60; // TODO: set to something meaningful

    return;
}

pub fn deinit(linux: *Linux) void {
    if (linux.gamemode != null and linux.gamemode.?) deinitLinuxGamemode();
    switch (linux.backend) {
        .wayland => linux.backend.wayland.deinit(linux),
        .x11 => linux.backend.x11.deinit(linux),
    }

    return;
}

pub fn update(_: *Linux) !void {
    return;
}

pub fn setTitle(_: *Linux, _: [:0]const u8) void {
    return;
}

pub fn setDisplayMode(_: *Linux, _: DisplayMode) void {
    return;
}

pub fn setBorder(_: *Linux, _: bool) void {
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

pub fn size(_: *Linux) Size {
    return Size{ .width = 100, .height = 100 };
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
    gamemode_log.info("gamemode: activated", .{});
    return true;
}

pub fn deinitLinuxGamemode() void {
    mach.gamemode.stop();
    gamemode_log.info("gamemode: deactivated", .{});
}
