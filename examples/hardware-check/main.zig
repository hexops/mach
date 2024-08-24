const std = @import("std");
const mach = @import("mach");

// The global list of Mach modules registered for use in our application.
pub const modules = .{
    mach.Core,
    mach.gfx.sprite_modules,
    mach.gfx.text_modules,
    mach.Audio,
    @import("App.zig"),
};

// TODO(important): use standard entrypoint instead
pub fn main() !void {
    // Initialize mach.Core
    try mach.core.initModule();

    // Main loop
    while (try mach.core.tick()) {}
}
