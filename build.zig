const std = @import("std");
const builtin = @import("builtin");
const freetype = @import("libs/freetype/build.zig");
const glfw = @import("libs/glfw/build.zig").Sdk(.{
    // TODO(build-system): This cannot be imported with the Zig package manager
    // error: TarUnsupportedFileType
    .xcode_frameworks = @import("libs/gpu-dawn/libs/xcode-frameworks/build.zig"),
});
const sysaudio = @import("libs/sysaudio/build.zig").Sdk(.{
    // TODO(build-system): This cannot be imported with the Zig package manager
    // error: TarUnsupportedFileType
    .xcode_frameworks = @import("libs/gpu-dawn/libs/xcode-frameworks/build.zig"),
});
pub const gpu_dawn = @import("libs/gpu-dawn/build.zig").Sdk(.{
    // TODO(build-system): This cannot be imported with the Zig package manager
    // error: TarUnsupportedFileType
    .xcode_frameworks = @import("libs/gpu-dawn/libs/xcode-frameworks/build.zig"),
});
const gpu = @import("libs/gpu/sdk.zig").Sdk(.{
    .gpu_dawn = gpu_dawn,
});
const core = @import("libs/core/sdk.zig").Sdk(.{
    .gpu = gpu,
    .gpu_dawn = gpu_dawn,
    .glfw = glfw,
});

var _module: ?*std.build.Module = null;

pub fn module(b: *std.Build, optimize: std.builtin.OptimizeMode, target: std.zig.CrossTarget) *std.build.Module {
    if (_module) |m| return m;

    const mach_ecs = b.dependency("mach_ecs", .{
        .target = target,
        .optimize = optimize,
    });
    const mach_earcut = b.dependency("mach_earcut", .{
        .target = target,
        .optimize = optimize,
    });
    const mach_basisu = b.dependency("mach_basisu", .{
        .target = target,
        .optimize = optimize,
    });

    _module = b.createModule(.{
        .source_file = .{ .path = sdkPath("/src/main.zig") },
        .dependencies = &.{
            .{ .name = "core", .module = core.module(b) },
            .{ .name = "ecs", .module = mach_ecs.module("mach-ecs") },
            .{ .name = "earcut", .module = mach_earcut.module("mach-earcut") },
            .{ .name = "sysaudio", .module = sysaudio.module(b, optimize, target) },
            .{ .name = "basisu", .module = mach_basisu.module("mach-basisu") },
        },
    });
    return _module.?;
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
        const app = b.addExecutable(.{
            .name = "mach",
            .root_source_file = .{ .path = "app/main.zig" },
            .version = .{ .major = 0, .minor = 1, .patch = 0 },
            .optimize = optimize,
            .target = target,
        });
        app.addModule("mach", module(b, optimize, target));
        if (app.target.getOsTag() == .windows) app.linkLibC();
        b.installArtifact(app);

        const app_run_cmd = b.addRunArtifact(app);
        if (b.args) |args| app_run_cmd.addArgs(args);
        const app_run_step = b.step("run", "Run Mach Engine Application");
        app_run_step.dependOn(&app_run_cmd.step);

        const all_tests_step = b.step("test", "Run library tests");
        const core_test_step = b.step("test-core", "Run Core library tests");
        const freetype_test_step = b.step("test-freetype", "Run Freetype library tests");
        const sysaudio_test_step = b.step("test-sysaudio", "Run sysaudio library tests");
        const mach_test_step = b.step("test-mach", "Run Engine library tests");

        core_test_step.dependOn(&(try core.testStep(b, optimize, target)).step);
        freetype_test_step.dependOn(&freetype.testStep(b, optimize, target).step);
        sysaudio_test_step.dependOn(&sysaudio.testStep(b, optimize, target).step);
        mach_test_step.dependOn(&testStep(b, optimize, target).step);

        all_tests_step.dependOn(core_test_step);
        all_tests_step.dependOn(freetype_test_step);
        all_tests_step.dependOn(sysaudio_test_step);
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

        const shaderexp_install_step = b.step("shaderexp", "Install shaderexp");
        shaderexp_install_step.dependOn(&shaderexp_app.getInstallStep().?.step);
        const shaderexp_run_cmd = shaderexp_app.addRunArtifact();
        shaderexp_run_cmd.step.dependOn(shaderexp_install_step);

        const shaderexp_run_step = b.step("run-shaderexp", "Run shaderexp");
        shaderexp_run_step.dependOn(&shaderexp_run_cmd.step);
        b.getInstallStep().dependOn(shaderexp_install_step);
    }

    const compile_all = b.step("compile-all", "Compile Mach");
    compile_all.dependOn(b.getInstallStep());
}

fn testStep(b: *std.Build, optimize: std.builtin.OptimizeMode, target: std.zig.CrossTarget) *std.build.RunStep {
    const main_tests = b.addTest(.{
        .name = "mach-tests",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    var iter = module(b, optimize, target).dependencies.iterator();
    while (iter.next()) |e| {
        main_tests.addModule(e.key_ptr.*, e.value_ptr.*);
    }
    b.installArtifact(main_tests);
    return b.addRunArtifact(main_tests);
}

pub const App = struct {
    b: *std.Build,
    name: []const u8,
    step: *std.build.CompileStep,
    platform: core.App.Platform,

    core: core.App,
    use_freetype: ?[]const u8 = null,

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
        },
    ) !App {
        var deps = std.ArrayList(std.build.ModuleDependency).init(b.allocator);
        if (options.deps) |v| try deps.appendSlice(v);
        try deps.append(.{ .name = "mach", .module = module(b, options.optimize, options.target) });
        try deps.append(.{ .name = "sysaudio", .module = sysaudio.module(b, options.optimize, options.target) });
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
        };
    }

    pub fn link(app: *const App, options: Options) !void {
        try app.core.link(options.core);
        sysaudio.link(app.b, app.step, options.sysaudio);
        if (app.use_freetype) |_| freetype.link(app.b, app.step, options.freetype);

        const mach_basisu = app.b.dependency("mach_basisu", .{
            .target = app.step.target,
            .optimize = app.step.optimize,
        });
        app.step.linkLibrary(mach_basisu.artifact("mach-basisu"));
    }

    pub fn install(app: *const App) void {
        app.core.install();
    }

    pub fn addRunArtifact(app: *const App) *std.build.RunStep {
        return app.core.addRunArtifact();
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
