const std = @import("std");
const mach = @import("mach");

// The set of Mach modules our application may use.
const Modules = mach.Modules(.{
    mach.Core,
    mach.gfx.sprite_modules,
    mach.gfx.text_modules,
    mach.Audio,
    @import("App.zig"),
});

// TODO: move this to a mach "entrypoint" zig module which handles nuances like WASM requires.
pub fn main() !void {
    const allocator = std.heap.c_allocator;

    // The set of Mach modules our application may use.
    var mods: Modules = undefined;
    try mods.init(allocator);
    // TODO: enable mods.deinit(allocator); for allocator leak detection
    // defer mods.deinit(allocator);

    const app = mods.get(.app);
    app.run(.main);
}
