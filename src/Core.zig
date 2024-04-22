const std = @import("std");
const mach = @import("main.zig");

// TODO(important): mach.core has a lot of standard Zig APIs, and some global variables, which are
// part of its old API design. We should elevate them into this module instead.

pub const name = .mach_core;

pub const Mod = mach.Mod(@This());

pub const global_events = .{
    .init = .{ .handler = fn () void },
    .deinit = .{ .handler = fn () void },
    .tick = .{ .handler = fn () void },
};

pub const local_events = .{
    .update = .{ .handler = update, .description = 
    \\ Send this when window entities have been updated and you want the new values respected.
    },

    .init = .{ .handler = init },
    .init_done = .{ .handler = fn () void },

    // TODO(important): need some way to tie event execution to a specific thread once we have a
    // multithreaded dispatch implementation
    .main_thread_tick = .{ .handler = mainThreadTick },
    .main_thread_tick_done = .{ .handler = fn () void },
    .deinit = .{ .handler = deinit },
    .exit = .{ .handler = exit },
};

pub const components = .{
    .title = .{ .type = [:0]u8, .description = 
    \\ Window title slice. Can be set with a format string and arguments via:
    \\
    \\ ```
    \\ try mach.Core.printTitle(core_mod, core_mod.state().main_window, "Hello, {s}!", .{"Mach"});
    \\ ```
    \\
    \\ If setting this component yourself, ensure the buffer is allocated using core.state().allocator
    \\ as it will be freed for you as part of the .deinit event.
    },
};

/// Prints into the window title buffer using a format string and arguments. e.g.
///
/// ```
/// try mach.Core.printTitle(core_mod, core_mod.state().main_window, "Hello, {s}!", .{"Mach"});
/// ```
pub fn printTitle(
    core: *mach.Core.Mod,
    window_id: mach.EntityID,
    comptime fmt: []const u8,
    args: anytype,
) !void {
    const slice = try std.fmt.allocPrintZ(core.state().allocator, fmt, args);
    try core.set(window_id, .title, slice);
}

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

allocator: std.mem.Allocator,
device: *mach.gpu.Device,
queue: *mach.gpu.Queue,
main_window: mach.EntityID,
should_exit: bool = false,

fn init(core: *Mod) !void {
    // Initialize GPU implementation
    if (comptime !mach.use_sysgpu) try mach.wgpu.Impl.init(mach.core.allocator, .{});
    if (comptime mach.use_sysgpu) try mach.sysgpu.Impl.init(mach.core.allocator, .{});

    mach.core.allocator = gpa.allocator(); // TODO: banish this global allocator
    try mach.core.init(.{});

    core.init(.{
        .allocator = mach.core.allocator,
        .device = mach.core.device,
        .queue = mach.core.device.getQueue(),
        .main_window = try core.newEntity(),
    });

    core.sendGlobal(.init, .{});
    core.send(.init_done, .{});
}

fn update(core: *Mod) !void {
    var archetypes_iter = core.entities.query(.{ .all = &.{
        .{ .mach_core = &.{
            .title,
        } },
    } });

    var num_windows: usize = 0;
    while (archetypes_iter.next()) |archetype| {
        for (
            archetype.slice(.entity, .id),
            archetype.slice(.mach_core, .title),
        ) |window_id, title| {
            num_windows += 1;
            _ = window_id;
            try mach.core.printTitle("{s}", .{title});
        }
    }
    if (num_windows > 1) @panic("mach: Core currently only supports a single window");
}

fn deinit(core: *Mod) void {
    core.state().queue.release();
    // TODO: this triggers a device loss error, which we should handle correctly
    // core.state().device.release();
    mach.core.deinit();

    var archetypes_iter = core.entities.query(.{ .all = &.{
        .{ .mach_core = &.{
            .title,
        } },
    } });
    while (archetypes_iter.next()) |archetype| {
        for (archetype.slice(.mach_core, .title)) |title| core.state().allocator.free(title);
    }

    _ = gpa.deinit();
}

fn mainThreadTick(core: *Mod) !void {
    _ = try mach.core.update(null);

    // Send .tick to anyone interested
    core.sendGlobal(.tick, .{});

    // Signal that mainThreadTick is done
    core.send(.main_thread_tick_done, .{});
}

fn exit(core: *Mod) void {
    core.state().should_exit = true;
}
