const std = @import("std");
const mach = @import("main.zig");

pub const name = .mach_core;

pub const Mod = mach.Mod(@This());

pub const global_events = .{
    .init = .{ .handler = fn () void },
    .deinit = .{ .handler = fn () void },
    .tick = .{ .handler = fn () void },
};

pub const local_events = .{
    .init = .{ .handler = init },

    // TODO(important): need some way to tie event execution to a specific thread once we have a
    // multithreaded dispatch implementation
    .main_thread_tick = .{ .handler = mainThreadTick },
    .main_thread_tick_done = .{ .handler = fn () void },
    .deinit = .{ .handler = deinit },
    .exit = .{ .handler = exit },
};

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

device: *mach.gpu.Device,
queue: *mach.gpu.Queue,
should_exit: bool = false,

fn init(core: *Mod) !void {
    // Initialize GPU implementation
    if (comptime mach.core.options.use_wgpu) try mach.core.wgpu.Impl.init(mach.core.allocator, .{});
    if (comptime mach.core.options.use_sysgpu) try mach.core.sysgpu.Impl.init(mach.core.allocator, .{});

    mach.core.allocator = gpa.allocator(); // TODO: banish this global allocator
    try mach.core.init(.{});

    core.init(.{
        .device = mach.core.device,
        .queue = mach.core.device.getQueue(),
    });

    core.sendGlobal(.init, .{});
}

fn deinit(core: *Mod) void {
    core.state().queue.release();
    // TODO: this triggers a device loss error, which we should handle correctly
    // core.state().device.release();
    mach.core.deinit();
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
