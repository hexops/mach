const fetch = @import("fetch.zig");
const std = @import("std");

const deps = [_]fetch.Dependency{
    .{
        .name = "upstream",
        .vcs = .{
            .git = .{
                .url = "https://github.com/hexops/basisu",
                .commit = "d55a3f9f06adf9cc8c31f58e894d947cc6026da5",
            },
        },
    },
};

pub fn build(builder: *std.build.Builder) !void {
    fetch.addStep(builder, "test", "Run library tests");
    try fetch.fetchAndBuild(builder, "zig-deps", &deps, "compile.zig");
}
