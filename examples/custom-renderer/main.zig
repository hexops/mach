const std = @import("std");

const mach = @import("mach");

// The global list of Mach modules registered for use in our application.
pub const modules = .{
    mach.Core,
    @import("App.zig"),
    @import("Renderer.zig"),
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var app = try mach.App.init(allocator, .app);
    defer app.deinit(allocator);
    try app.run(.{ .allocator = allocator });
}
