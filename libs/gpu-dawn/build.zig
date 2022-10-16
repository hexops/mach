const fetch = @import("fetch.zig");
const std = @import("std");

const deps = [_]fetch.Dependency{
    .{
        .name = "mach-glfw",
        .vcs = .{
            .git = .{
                .url = "https://github.com/hexops/mach-glfw",
                .commit = "b803782349c9ab80ba885054e23133b468ec041a",
            },
        },
    },
};

pub fn build(builder: *std.build.Builder) !void {
    try fetch.fetchAndBuild(builder, "zig-deps", &deps, "compile.zig");
}
