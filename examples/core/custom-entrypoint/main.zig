const std = @import("std");
const mach = @import("mach");

// The global list of Mach modules our application may use.
pub const modules = .{
    mach.Core,
    @import("App.zig"),
};

pub fn main() !void {
    const allocator = std.heap.c_allocator;

    // Initialize module system
    try mach.mods.init(allocator);

    // Schedule .app.start to run.
    mach.mods.schedule(.app, .start);

    // If desired, it is possible to observe when the app has finished starting by dispatching
    // systems until the app has started:
    const stack_space = try allocator.alloc(u8, 8 * 1024 * 1024);
    try mach.mods.dispatchUntil(stack_space, .mach_core, .started);

    // On some platforms, you can drive the mach.Core main loop yourself - but this isn't
    // possible on all platforms.
    if (mach.Core.supports_non_blocking) {
        mach.Core.non_blocking = true;
        while (mach.mods.mod.mach_core.state != .exited) {
            // Execute systems until a frame has been finished.
            try mach.mods.dispatchUntil(stack_space, .mach_core, .frame_finished);
        }
    } else {
        // On platforms where you cannot control the mach.Core main loop, the .mach_core.start
        // system your app schedules will block forever and the function call below will NEVER
        // return (std.process.exit will occur first.)
        //
        // In this case we can just dispatch systems until there are no more left to execute, which
        // conviently works even if you aren't using mach.Core in your program.
        try mach.mods.dispatch(stack_space, .{});
    }
}
