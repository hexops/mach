const fetch = @import("fetch.zig");
const std = @import("std");

const deps = [_]fetch.Dependency{
    .{
        .name = "upstream",
        .vcs = .{
            .git = .{
                .url = "https://github.com/hexops/glfw",
                .commit = "915548c8694c1b4a96abd5a8729d0e777582d077",
            },
        },
    },
};

pub fn build(builder: *std.build.Builder) !void {
    fetch.addStep(builder, "test", "Run library tests");
    try fetch.fetchAndBuild(builder, "zig-deps", &deps, "compile.zig");
}
