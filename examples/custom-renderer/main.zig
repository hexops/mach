const mach = @import("mach");

// The global list of Mach modules registered for use in our application.
pub const modules = .{
    mach.Core,
    @import("App.zig"),
    @import("Renderer.zig"),
};

// TODO: move this to a mach "entrypoint" zig module
pub fn main() !void {
    // Initialize mach core
    try mach.core.initModule();

    // Main loop
    while (try mach.core.tick()) {}
}
