const std = @import("std");

const mach = @import("main.zig");
const gpu = mach.gpu;

// TODO(important): mach.core has a lot of standard Zig APIs, and some global variables, which are
// part of its old API design. We should elevate them into this module instead.

pub const name = .mach_core;

pub const Mod = mach.Mod(@This());

pub const systems = .{
    .start = .{ .handler = start, .description = 
    \\ Send this once your app is initialized and ready for .app.tick events.
    },

    .update = .{ .handler = update, .description = 
    \\ Send this when window entities have been updated and you want the new values respected.
    },

    .present_frame = .{ .handler = presentFrame, .description = 
    \\ Send this when rendering has finished and the swapchain should be presented.
    },

    .exit = .{ .handler = exit, .description = 
    \\ Send this when you would like to exit the application.
    \\
    \\ When the next .present_frame occurs, then .app.deinit will be sent giving your app a chance
    \\ to deinitialize itself and .app.tick will no longer be sent. Once your app is done with
    \\ deinitialization, you should send the final .mach_core.deinit event which will cause the
    \\ application to finish.
    },

    .deinit = .{ .handler = deinit, .description = 
    \\ Send this once your app is fully deinitialized and ready to exit for good.
    },

    // TODO(important): need some way to tie event execution to a specific thread once we have a
    // multithreaded dispatch implementation
    .init = .{ .handler = init },
    .main_thread_tick = .{ .handler = mainThreadTick },
    .main_thread_tick_done = .{ .handler = fn () void },
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

    .framebuffer_format = .{ .type = gpu.Texture.Format, .description = 
    \\ The texture format of the framebuffer
    },

    .framebuffer_width = .{ .type = u32, .description = 
    \\ The width of the framebuffer in texels
    },

    .framebuffer_height = .{ .type = u32, .description = 
    \\ The height of the framebuffer in texels
    },

    .width = .{ .type = u32, .description = 
    \\ The width of the window in virtual pixels
    },

    .height = .{ .type = u32, .description = 
    \\ The height of the window in virtual pixels
    },
};

/// Prints into the window title buffer using a format string and arguments. e.g.
///
/// ```
/// try mach.Core.printTitle(core_mod, core_mod.state().main_window, "Hello, {s}!", .{"Mach"});
/// ```
pub fn printTitle(
    core: *Mod,
    window_id: mach.EntityID,
    comptime fmt: []const u8,
    args: anytype,
) !void {
    // Free any previous window title slice
    // TODO: reuse allocations
    if (core.get(window_id, .title)) |slice| core.state().allocator.free(slice);

    // Allocate and assign a new window title slice.
    const slice = try std.fmt.allocPrintZ(core.state().allocator, fmt, args);
    try core.set(window_id, .title, slice);
}

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

allocator: std.mem.Allocator,
device: *mach.gpu.Device,
queue: *mach.gpu.Queue,
main_window: mach.EntityID,
run_state: enum {
    initialized,
    running,
    exiting,
    deinitializing,
    exited,
} = .initialized,

fn start(core: *Mod) !void {
    core.state().run_state = .running;
}

fn init(entities: *mach.Entities.Mod, core: *Mod) !void {
    mach.core.allocator = gpa.allocator(); // TODO: banish this global allocator

    // Initialize GPU implementation
    if (comptime !mach.use_sysgpu) try mach.wgpu.Impl.init(mach.core.allocator, .{});
    if (comptime mach.use_sysgpu) try mach.sysgpu.Impl.init(mach.core.allocator, .{});

    try mach.core.init(.{});

    const main_window = try entities.new();
    // TODO(important): update this information upon framebuffer resize events
    try core.set(main_window, .framebuffer_format, mach.core.descriptor.format);
    try core.set(main_window, .framebuffer_width, mach.core.descriptor.width);
    try core.set(main_window, .framebuffer_height, mach.core.descriptor.height);
    try core.set(main_window, .width, mach.core.size().width);
    try core.set(main_window, .height, mach.core.size().height);

    core.init(.{
        .allocator = mach.core.allocator,
        .device = mach.core.device,
        .queue = mach.core.device.getQueue(),
        .main_window = main_window,
    });

    mach.core.mods.schedule(.app, .init);
}

fn update(entities: *mach.Entities.Mod) !void {
    var num_windows: usize = 0;
    var q = try entities.query(.{
        .ids = mach.Entities.Mod.read(.id),
        .titles = Mod.read(.title),
    });
    while (q.next()) |v| {
        for (v.ids, v.titles) |window_id, title| {
            _ = window_id;
            num_windows += 1;
            try mach.core.printTitle("{s}", .{title});
        }
    }
    if (num_windows > 1) @panic("mach: Core currently only supports a single window");
}

fn presentFrame(core: *Mod) !void {
    switch (core.state().run_state) {
        .running => {
            mach.core.swap_chain.present();

            // TODO(important): update this information in response to resize events rather than
            // after frame submission
            const main_window = core.state().main_window;
            try core.set(main_window, .framebuffer_format, mach.core.descriptor.format);
            try core.set(main_window, .framebuffer_width, mach.core.descriptor.width);
            try core.set(main_window, .framebuffer_height, mach.core.descriptor.height);
            try core.set(main_window, .width, mach.core.size().width);
            try core.set(main_window, .height, mach.core.size().height);

            // Signal that mainThreadTick is done
            core.schedule(.main_thread_tick_done);
        },
        .exiting => {
            // Exit opportunity is here, deinitialize now
            core.state().run_state = .deinitializing;
            mach.core.mods.schedule(.app, .deinit);
        },
        else => return,
    }
}

fn deinit(entities: *mach.Entities.Mod, core: *Mod) !void {
    core.state().queue.release();
    mach.core.deinit();

    var q = try entities.query(.{
        .titles = Mod.read(.title),
    });
    while (q.next()) |v| {
        for (v.titles) |title| {
            core.state().allocator.free(title);
        }
    }

    _ = gpa.deinit();
    core.state().run_state = .exited;

    // Signal that mainThreadTick is done
    core.schedule(.main_thread_tick_done);
}

fn mainThreadTick(core: *Mod) !void {
    if (core.state().run_state != .running) return;
    _ = try mach.core.update(null);
    mach.core.mods.schedule(.app, .tick);
}

fn exit(core: *Mod) void {
    core.state().run_state = .exiting;
}
