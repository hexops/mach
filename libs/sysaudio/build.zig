const fetch = @import("fetch.zig");
const std = @import("std");

const deps = [_]fetch.Dependency{
    .{
        .name = "upstream",
        .vcs = .{
            .git = .{
                .url = "https://github.com/hexops/soundio",
                .commit = "56c1f298c25388e78bedd48085c385aed945d1e5",
            },
        },
    },
};

pub fn build(builder: *std.build.Builder) !void {
    fetch.addStep(builder, "test", "Run library tests");
    inline for ([_][]const u8{
        "soundio-sine-wave",
    }) |example| {
        fetch.addStep(builder, "example-" ++ example, "Compile '" ++ example ++ "' example");
        fetch.addStep(builder, "run-example-" ++ example, "Run '" ++ example ++ "' example");
    }

    try fetch.fetchAndBuild(builder, "zig-deps", &deps, "compile.zig");
}
