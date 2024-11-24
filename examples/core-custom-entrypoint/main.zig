const std = @import("std");
const mach = @import("mach");

// The set of Mach modules our application may use.
const Modules = mach.Modules(.{
    mach.Core,
    @import("App.zig"),
});

pub fn main() !void {
    const allocator = std.heap.c_allocator;

    // The set of Mach modules our application may use.
    var mods: Modules = undefined;
    try mods.init(allocator);

    // On some platforms, you can drive the mach.Core main loop yourself - but this isn't possible
    // on all platforms. If mach.Core.non_blocking is set to true, and the platform supports
    // non-blocking mode, then .mach_core.main will return without blocking. Otherwise it will block
    // forever and app.run(.main) will never return.
    if (mach.Core.supports_non_blocking) {
        defer mods.deinit(allocator);

        mach.Core.non_blocking = true;

        const app = mods.get(.app);
        app.run(.main);

        // If you are driving the main loop yourself, you should call tick until exit.
        const core = mods.get(.mach_core);
        while (mods.mods.mach_core.state != .exited) {
            core.run(.tick);
        }
    } else {
        const app = mods.get(.app);
        app.run(.main);
    }
}
