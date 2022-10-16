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
        // TODO(build-system): remove this once subrepo is updated
        .recursive_fetch = false,
    },
    .{
        .name = "mach-gpu-dawn",
        .vcs = .{
            .git = .{
                .url = "https://github.com/hexops/mach-gpu-dawn",
                .commit = "96808c0b6fe133cb982195916e8c0a1caa268c83",
            },
        },
        // TODO(build-system): remove this once subrepo is updated
        .recursive_fetch = false,
    },
};

pub fn build(builder: *std.build.Builder) !void {
    fetch.addStep(builder, "test", "Run library tests");
    fetch.addStep(builder, "run-example", "Run example");
    fetch.addOption(builder, bool, "dawn-from-source", "Build Dawn purely from source (default false)");
    fetch.addOption(builder, bool, "dawn-debug", "Use a version of Dawn with full debug symbols");

    try fetch.fetchAndBuild(builder, "zig-deps", &deps, "compile.zig");
}
