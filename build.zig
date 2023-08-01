const std = @import("std");
const builtin = @import("builtin");
const glfw = @import("mach_glfw");
const sysaudio = @import("mach_sysaudio");
pub const gpu_dawn = @import("libs/mach-gpu-dawn/build.zig"); // TODO(build-system): make this private
const gpu = @import("libs/mach-gpu/build.zig").Sdk(.{
    .gpu_dawn = gpu_dawn,
});
const core = @import("libs/mach-core/build.zig").Sdk(.{
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
            .{ .name = "core", .module = core.module(b, optimize, target) },
            .{ .name = "ecs", .module = mach_ecs.module("mach-ecs") },
            .{ .name = "earcut", .module = mach_earcut.module("mach-earcut") },
            .{ .name = "sysaudio", .module = sysaudio.module(b, optimize, target) },
            .{ .name = "basisu", .module = mach_basisu.module("mach-basisu") },
        },
    });
    return _module.?;
}

pub const Options = struct { sysaudio: sysaudio.Options = .{} };

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const options = Options{};

    if (target.getCpuArch() != .wasm32) {
        const tests_step = b.step("test", "Run tests");
        tests_step.dependOn(&testStep(b, optimize, target).step);

        const editor = try App.init(
            b,
            .{
                .name = "mach",
                .src = "src/editor/app.zig",
                .custom_entrypoint = "src/editor/main.zig",
                .target = target,
                .optimize = optimize,
            },
        );
        try editor.link(options);

        const editor_install_step = b.step("editor", "Install editor");
        editor_install_step.dependOn(&editor.install.step);

        const editor_run_step = b.step("run", "Run the editor");
        editor_run_step.dependOn(&editor.run.step);
    }
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
    compile: *std.build.Step.Compile,
    install: *std.build.Step.InstallArtifact,
    run: *std.build.Step.Run,
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
            custom_entrypoint: ?[]const u8 = null,
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
        if (options.use_freetype) |name| {
            const freetype_dep = b.dependency("mach_freetype", .{ .target = options.target, .optimize = options.optimize });
            try deps.append(.{ .name = name, .module = freetype_dep.module("mach-freetype") });
        }

        const app = try core.App.init(b, .{
            .name = options.name,
            .src = options.src,
            .target = options.target,
            .optimize = options.optimize,
            .custom_entrypoint = options.custom_entrypoint,
            .deps = deps.items,
            .res_dirs = options.res_dirs,
            .watch_paths = options.watch_paths,
        });
        return .{
            .core = app,
            .b = app.b,
            .name = app.name,
            .compile = app.compile,
            .install = app.install,
            .run = app.run,
            .platform = app.platform,
            .use_freetype = options.use_freetype,
        };
    }

    pub fn link(app: *const App, options: Options) !void {
        sysaudio.link(app.b, app.compile, options.sysaudio);

        // TODO: basisu support in wasm
        if (app.platform != .web) {
            const mach_basisu = app.b.dependency("mach_basisu", .{
                .target = app.compile.target,
                .optimize = app.compile.optimize,
            });
            app.compile.linkLibrary(mach_basisu.artifact("mach-basisu"));
        }
    }
};

fn sdkPath(comptime suffix: []const u8) []const u8 {
    if (suffix[0] != '/') @compileError("suffix must be an absolute path");
    return comptime blk: {
        const root_dir = std.fs.path.dirname(@src().file) orelse ".";
        break :blk root_dir ++ suffix;
    };
}

comptime {
    const min_zig = std.SemanticVersion.parse("0.11.0-dev.3947+89396ff02") catch unreachable;
    if (builtin.zig_version.order(min_zig) == .lt) {
        @compileError(std.fmt.comptimePrint("Your Zig version v{} does not meet the minimum build requirement of v{}", .{ builtin.zig_version, min_zig }));
    }
}
