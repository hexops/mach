// Check that the user's app matches the required interface.
comptime {
    if (!@import("builtin").is_test) @import("mach").core.AppInterface(@import("app"));
}

// Forward "app" declarations into our namespace, such that @import("root").foo works as expected.
pub usingnamespace @import("app");
const App = @import("app").App;

const std = @import("std");

const mach = @import("mach");
const core = mach.core;

pub usingnamespace if (!@hasDecl(App, "GPUInterface")) struct {
    pub const GPUInterface = mach.wgpu.dawn.Interface;
} else struct {};

pub usingnamespace if (!@hasDecl(App, "SYSGPUInterface")) extern struct {
    pub const SYSGPUInterface = mach.sysgpu.Impl;
} else struct {};

pub fn main() !void {
    // Run from the directory where the executable is located so relative assets can be found.
    var buffer: [1024]u8 = undefined;
    const path = std.fs.selfExeDirPath(buffer[0..]) catch ".";
    std.posix.chdir(path) catch {};

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    core.allocator = gpa.allocator();

    // Initialize GPU implementation
    if (comptime !mach.use_sysgpu) try mach.wgpu.Impl.init(core.allocator, .{});
    if (comptime mach.use_sysgpu) try mach.sysgpu.Impl.init(core.allocator, .{});

    var app: App = undefined;
    try app.init();
    defer app.deinit();
    while (!try core.update(&app)) {}
}
