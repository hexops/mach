const std = @import("std");
const builtin = @import("builtin");
const system_sdk = @import("libs/glfw/system_sdk.zig");
const glfw = @import("libs/glfw/build.zig");
const ecs = @import("libs/ecs/build.zig");
const freetype = @import("libs/freetype/build.zig");
const basisu = @import("libs/basisu/build.zig");
const sysjs = @import("libs/sysjs/build.zig");
const earcut = @import("libs/earcut/build.zig");
const gamemode = @import("libs/gamemode/build.zig");
const model3d = @import("libs/model3d/build.zig");
const wasmserve = @import("tools/wasmserve/wasmserve.zig");
const gpu_dawn = @import("libs/gpu-dawn/sdk.zig").Sdk(.{
    .glfw_include_dir = sdkPath("/libs/glfw/upstream/glfw/include"),
    .system_sdk = system_sdk,
});
const gpu = @import("libs/gpu/sdk.zig").Sdk(.{
    .gpu_dawn = gpu_dawn,
});
const sysaudio = @import("libs/sysaudio/sdk.zig").Sdk(.{
    .system_sdk = system_sdk,
    .sysjs = sysjs,
});
const core = @import("libs/core/sdk.zig").Sdk(.{
    .gpu = gpu,
    .gpu_dawn = gpu_dawn,
    .glfw = glfw,
    .gamemode = gamemode,
    .wasmserve = wasmserve,
    .sysjs = sysjs,
});

pub fn module(b: *std.Build) *std.build.Module {
    return b.createModule(.{
        .source_file = .{ .path = sdkPath("/src/main.zig") },
        .dependencies = &.{
            .{ .name = "core", .module = core.module(b) },
            .{ .name = "ecs", .module = ecs.module(b) },
            .{ .name = "sysaudio", .module = sysaudio.module(b) },
            .{ .name = "earcut", .module = earcut.module(b) },
        },
    });
}

pub const Options = struct {
    core: core.Options = .{},
    sysaudio: sysaudio.Options = .{},
    freetype: freetype.Options = .{},
};

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const gpu_dawn_options = gpu_dawn.Options{
        .from_source = b.option(bool, "dawn-from-source", "Build Dawn from source") orelse false,
        .debug = b.option(bool, "dawn-debug", "Use a debug build of Dawn") orelse false,
    };
    const options = Options{ .core = .{ .gpu_dawn_options = gpu_dawn_options } };

    if (target.getCpuArch() != .wasm32) {
        const all_tests_step = b.step("test", "Run library tests");
        const core_test_step = b.step("test-core", "Run Core library tests");
        const ecs_test_step = b.step("test-ecs", "Run ECS library tests");
        const freetype_test_step = b.step("test-freetype", "Run Freetype library tests");
        const basisu_test_step = b.step("test-basisu", "Run Basis-Universal library tests");
        const sysaudio_test_step = b.step("test-sysaudio", "Run sysaudio library tests");
        const model3d_test_step = b.step("test-model3d", "Run Model3D library tests");
        const mach_test_step = b.step("test-mach", "Run Engine library tests");

        core_test_step.dependOn(&(try core.testStep(b, optimize, target)).step);
        freetype_test_step.dependOn(&freetype.testStep(b, optimize, target).step);
        ecs_test_step.dependOn(&ecs.testStep(b, optimize, target).step);
        basisu_test_step.dependOn(&basisu.testStep(b, optimize, target).step);
        sysaudio_test_step.dependOn(&sysaudio.testStep(b, optimize, target).step);
        model3d_test_step.dependOn(&model3d.testStep(b, optimize, target).step);
        mach_test_step.dependOn(&testStep(b, optimize, target).step);

        all_tests_step.dependOn(core_test_step);
        all_tests_step.dependOn(ecs_test_step);
        all_tests_step.dependOn(basisu_test_step);
        all_tests_step.dependOn(freetype_test_step);
        all_tests_step.dependOn(sysaudio_test_step);
        all_tests_step.dependOn(model3d_test_step);
        all_tests_step.dependOn(mach_test_step);

        const shaderexp_app = try App.init(
            b,
            .{
                .name = "shaderexp",
                .src = "shaderexp/main.zig",
                .target = target,
                .optimize = optimize,
            },
        );
        try shaderexp_app.link(options);
        shaderexp_app.install();

        const shaderexp_compile_step = b.step("shaderexp", "Compile shaderexp");
        shaderexp_compile_step.dependOn(&shaderexp_app.getInstallStep().?.step);

        const shaderexp_run_cmd = try shaderexp_app.run();
        shaderexp_run_cmd.dependOn(&shaderexp_app.getInstallStep().?.step);
        const shaderexp_run_step = b.step("run-shaderexp", "Run shaderexp");
        shaderexp_run_step.dependOn(shaderexp_run_cmd);
    }

    const compile_all = b.step("compile-all", "Compile Mach");
    compile_all.dependOn(b.getInstallStep());
}

fn testStep(b: *std.Build, optimize: std.builtin.OptimizeMode, target: std.zig.CrossTarget) *std.build.RunStep {
    const main_tests = b.addTest(.{
        .name = "mach-tests",
        .kind = .test_exe,
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    var iter = module(b).dependencies.iterator();
    while (iter.next()) |e| {
        main_tests.addModule(e.key_ptr.*, e.value_ptr.*);
    }
    main_tests.install();
    return main_tests.run();
}

pub const App = struct {
    b: *std.Build,
    name: []const u8,
    step: *std.build.CompileStep,
    platform: core.App.Platform,

    core: core.App,
    use_freetype: ?[]const u8 = null,
    use_model3d: bool = false,

    pub const InitError = core.App.InitError;
    pub const LinkError = core.App.LinkError;
    pub const RunError = core.App.RunError;

    pub fn init(
        b: *std.Build,
        options: struct {
            name: []const u8,
            src: []const u8,
            target: std.zig.CrossTarget,
            optimize: std.builtin.OptimizeMode,
            deps: ?[]const std.build.ModuleDependency = null,
            res_dirs: ?[]const []const u8 = null,
            watch_paths: ?[]const []const u8 = null,

            /// If set, freetype will be linked and can be imported using this name.
            // TODO(build-system): name is currently not used / always "freetype"
            use_freetype: ?[]const u8 = null,
            use_model3d: bool = false,
        },
    ) InitError!App {
        var deps = std.ArrayList(std.build.ModuleDependency).init(b.allocator);
        if (options.deps) |v| try deps.appendSlice(v);
        try deps.append(.{ .name = "mach", .module = module(b) });
        try deps.append(.{ .name = "sysaudio", .module = sysaudio.module(b) });
        if (options.use_freetype) |_| try deps.append(.{ .name = "freetype", .module = freetype.module(b) });

        const app = try core.App.init(b, .{
            .name = options.name,
            .src = options.src,
            .target = options.target,
            .optimize = options.optimize,
            .deps = deps.items,
            .res_dirs = options.res_dirs,
            .watch_paths = options.watch_paths,
        });
        return .{
            .core = app,
            .b = app.b,
            .name = app.name,
            .step = app.step,
            .platform = app.platform,
            .use_freetype = options.use_freetype,
            .use_model3d = options.use_model3d,
        };
    }

    pub fn link(app: *const App, options: Options) LinkError!void {
        try app.core.link(options.core);
        sysaudio.link(app.b, app.step, options.sysaudio);
        if (app.use_freetype) |_| freetype.link(app.b, app.step, options.freetype);
        if (app.use_model3d) {
            model3d.link(app.b, app.step, app.step.target);
        }
    }

    pub fn install(app: *const App) void {
        app.core.install();
    }

    pub fn run(app: *const App) RunError!*std.build.Step {
        return try app.core.run();
    }

    pub fn getInstallStep(app: *const App) ?*std.build.InstallArtifactStep {
        return app.core.getInstallStep();
    }
};

fn sdkPath(comptime suffix: []const u8) []const u8 {
    if (suffix[0] != '/') @compileError("suffix must be an absolute path");
    return comptime blk: {
        const root_dir = std.fs.path.dirname(@src().file) orelse ".";
        break :blk root_dir ++ suffix;
    };
}
