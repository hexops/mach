const mach = @import("mach");

// The global list of Mach modules registered for use in our application.
pub const modules = .{
    mach.Core,
    mach.gfx.Text,
    mach.gfx.TextPipeline,
    mach.gfx.TextStyle,
    @import("Game.zig"),
};

// TODO(important): use standard entrypoint instead
pub fn main() !void {
    // Initialize mach.Core
    try mach.core.initModule();

    // Main loop
    while (try mach.core.tick()) {}
}
