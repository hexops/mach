const Linux = @import("../Linux.zig");
const Core = @import("../../Core.zig");
const InitOptions = Core.InitOptions;

pub const Wayland = @This();

pub fn init(
    linux: *Linux,
    core: *Core.Mod,
    options: InitOptions,
) !Wayland {
    _ = linux;
    _ = core;
    _ = options;
    // TODO(core): return errors.NotSupported if not supported
    return .{};
}

pub fn deinit(
    w: *Wayland,
    linux: *Linux,
) void {
    _ = w;
    _ = linux;
}
