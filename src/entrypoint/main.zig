const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.c_allocator;

    // The set of Mach modules our application may use.
    var mods: @import("app").Modules = undefined;
    try mods.init(allocator);
    // TODO: enable mods.deinit(allocator); for allocator leak detection
    // defer mods.deinit(allocator);

    const app = mods.get(.app);
    app.run(.main);
}
