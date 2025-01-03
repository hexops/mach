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

    const app = mods.get(.app);
    app.run(.main);
}
