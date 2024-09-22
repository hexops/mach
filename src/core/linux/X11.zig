const Linux = @import("../Linux.zig");
const Core = @import("../../Core.zig");
const InitOptions = Core.InitOptions;

pub const X11 = @This();

pub fn init(
    linux: *Linux,
    core: *Core,
    options: InitOptions,
) !X11 {
    _ = linux;
    _ = core;
    _ = options;
    // TODO(core): return errors.NotSupported if not supported
    return .{};
}

pub fn deinit(
    w: *X11,
    linux: *Linux,
) void {
    _ = w;
    _ = linux;
}
