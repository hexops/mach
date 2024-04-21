const mach = @import("mach");

// The global list of Mach modules registered for use in our application.
pub const modules = .{
    mach.Core,
    mach.Audio,
    @import("Piano.zig"),
};

// TODO(important): use standard entrypoint instead
pub fn main() !void {
    // Initialize mach.Core
    try mach.core.initModule();

    // Main loop
    while (try mach.core.tick()) {}
}
