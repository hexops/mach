const std = @import("std");
const Core = @import("../Core.zig");
const gpu = @import("gpu");
const ecs = @import("ecs");

pub const App = @This();

// Zig says that *App has a size of 0 bits, and it won't compile if
// pub const core_callback_t = fn (*App, *Core) callconv(.C) void;
// What is *App needed for anyway?
pub const CoreCallback = fn (*Core) callconv(.C) void;

pub const CoreCallbacks = struct {
    core_init: ?CoreCallback,
    core_update: ?CoreCallback,
    core_deinit: ?CoreCallback,
};

pub var core_callbacks = CoreCallbacks {
    .core_init = null,
    .core_update = null,
    .core_deinit = null,
};

pub fn init(_: *App, core: *Core) !void {
    core_callbacks.core_init.?(core);
}

pub fn deinit(_: *App, core: *Core) void {
    core_callbacks.core_deinit.?(core);
}

pub fn update(_: *App, core: *Core) !void {
    core_callbacks.core_update.?(core);
}
