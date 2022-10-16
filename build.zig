const fetch = @import("fetch.zig");
const std = @import("std");

const deps = [_]fetch.Dependency{
    //--------------------------------------------------------------------------------
    // examples deps
    //--------------------------------------------------------------------------------
    .{
        .name = "zigimg",
        .vcs = .{
            .git = .{
                .url = "https://github.com/zigimg/zigimg",
                .commit = "fff6ea92a00c5f6092b896d754a932b8b88149ff",
                .shallow_branch = "stage2_compat",
            },
        },
        .recursive_fetch = false,
    },
    .{
        .name = "zmath",
        .vcs = .{
            .git = .{
                .url = "https://github.com/PiergiorgioZagaria/zmath",
                .commit = "c7f20369a142c8a817587da529787597461410a5",
            },
        },
        .recursive_fetch = false,
    },
    .{ .name = "../examples/image-blur/assets", .vcs = assets },
    .{ .name = "../examples/textured-cube/assets", .vcs = assets },
    .{ .name = "../examples/gkurve/assets", .vcs = assets },
    .{ .name = "../examples/cubemap/assets", .vcs = assets },

    //--------------------------------------------------------------------------------
    // mach/basisu deps
    //--------------------------------------------------------------------------------
    .{
        .name = "../libs/basisu/zig-deps/upstream",
        .vcs = .{
            .git = .{
                .url = "https://github.com/hexops/basisu",
                .commit = "d55a3f9f06adf9cc8c31f58e894d947cc6026da5",
            },
        },
    },

    //--------------------------------------------------------------------------------
    // mach/freetype deps
    //--------------------------------------------------------------------------------
    .{
        .name = "../libs/freetype/zig-deps/upstream",
        .vcs = .{
            .git = .{
                .url = "https://github.com/hexops/freetype",
                .commit = "d2eb35016c56cc3e2ef4076e8d61e3fd035071ab",
            },
        },
    },

    //--------------------------------------------------------------------------------
    // mach/glfw deps
    //--------------------------------------------------------------------------------
    .{
        .name = "../libs/glfw/zig-deps/upstream",
        .vcs = .{
            .git = .{
                .url = "https://github.com/hexops/glfw",
                .commit = "915548c8694c1b4a96abd5a8729d0e777582d077",
            },
        },
    },

    //--------------------------------------------------------------------------------
    // mach/sysaudio deps
    //--------------------------------------------------------------------------------
    .{
        .name = "../libs/sysaudio/zig-deps/upstream",
        .vcs = .{
            .git = .{
                .url = "https://github.com/hexops/soundio",
                .commit = "56c1f298c25388e78bedd48085c385aed945d1e5",
            },
        },
    },
};

const assets = .{
    .git = .{
        .url = "https://github.com/hexops/mach-example-assets",
        .commit = "b5a8404715e6cfc57e66c4a7cc0625e64b3b3c56",
    },
};

pub fn build(builder: *std.build.Builder) !void {
    fetch.addStep(builder, "test", "Run library tests");

    fetch.addStep(builder, "test", "Run library tests");
    fetch.addStep(builder, "test-glfw", "Run GLFW library tests");
    fetch.addStep(builder, "test-gpu", "Run GPU library tests");
    fetch.addStep(builder, "test-ecs", "Run ECS library tests");
    fetch.addStep(builder, "test-freetype", "Run Freetype library tests");
    fetch.addStep(builder, "test-basisu", "Run Basis-Universal library tests");
    fetch.addStep(builder, "test-sysaudio", "Run sysaudio library tests");
    fetch.addStep(builder, "test-mach", "Run Mach library tests");
    // TODO(build-system): need a way to test wasm
    // fetch.addStep(builder, "test-sysjs", "Run Mach library tests");

    fetch.addStep(builder, "shaderexp", "build shaderexp");
    fetch.addStep(builder, "run-shaderexp", "Run shaderexp (think 'shadertoy for WebGPU')");

    inline for ([_][]const u8{
        "triangle",
        "triangle-msaa",
        "boids",
        "rotating-cube",
        "pixel-post-process",
        "two-cubes",
        "instanced-cube",
        "advanced-gen-texture-light",
        "fractal-cube",
        "textured-cube",
        "ecs-app",
        "image-blur",
        "cubemap",
        "map-async",
        "sysaudio",
        "gkurve",
    }) |example| {
        fetch.addStep(builder, "example-" ++ example, "Compile '" ++ example ++ "' example");
        fetch.addStep(builder, "run-example-" ++ example, "Run '" ++ example ++ "' example");
    }

    fetch.addStep(builder, "compile-all", "Compile everything");
    fetch.addOption(builder, bool, "dawn-from-source", "Build Dawn purely from source (default false)");
    fetch.addOption(builder, bool, "dawn-debug", "Use a version of Dawn with full debug symbols");

    try fetch.fetchAndBuild(builder, "zig-deps", &deps, "compile.zig");
}
