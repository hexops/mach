const fetch = @import("fetch.zig");
const std = @import("std");

const deps = [_]fetch.Dependency{
    .{
        .name = "upstream",
        .vcs = .{
            .git = .{
                .url = "https://github.com/hexops/freetype",
                .commit = "d2eb35016c56cc3e2ef4076e8d61e3fd035071ab",
            },
        },
    },
};

pub fn build(builder: *std.build.Builder) !void {
    fetch.addStep(builder, "test", "Run library tests");
    inline for ([_][]const u8{
        "single-glyph",
        "glyph-to-svg",
    }) |example| {
        fetch.addStep(builder, "example-" ++ example, "Compile '" ++ example ++ "' example");
        fetch.addStep(builder, "run-example-" ++ example, "Run '" ++ example ++ "' example");
    }

    try fetch.fetchAndBuild(builder, "zig-deps", &deps, "compile.zig");
}
