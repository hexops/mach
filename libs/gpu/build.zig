const std = @import("std");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});
    const gpu_dawn = @import("libs/mach-gpu-dawn/build.zig");
    const gpu = Sdk(.{
        .gpu_dawn = gpu_dawn,
    });

    const gpu_dawn_options = gpu_dawn.Options{
        .from_source = b.option(bool, "dawn-from-source", "Build Dawn from source") orelse false,
        .debug = b.option(bool, "dawn-debug", "Use a debug build of Dawn") orelse false,
    };

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&(try gpu.testStep(b, optimize, target, .{ .gpu_dawn_options = gpu_dawn_options })).step);

    const example = b.addExecutable(.{
        .name = "gpu-hello-triangle",
        .root_source_file = .{ .path = "examples/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const glfw_dep = b.dependency("mach_glfw", .{
        .target = example.target,
        .optimize = example.optimize,
    });
    example.linkLibrary(glfw_dep.artifact("mach-glfw"));
    example.addModule("glfw", glfw_dep.module("mach-glfw"));

    example.addModule("gpu", gpu.module(b));
    try gpu.link(b, example, .{ .gpu_dawn_options = gpu_dawn_options });

    // TODO(build-system): package manager can't handle transitive deps like this, so we need to use
    // these explicitly here:
    @import("glfw").addPaths(example);
    if (example.target.toTarget().isDarwin()) xcode_frameworks.addPaths(b, example);
    example.linkLibrary(b.dependency("vulkan_headers", .{
        .target = example.target,
        .optimize = example.optimize,
    }).artifact("vulkan-headers"));

    b.installArtifact(example);

    const example_run_cmd = b.addRunArtifact(example);
    example_run_cmd.step.dependOn(b.getInstallStep());
    const example_run_step = b.step("run-example", "Run the example");
    example_run_step.dependOn(&example_run_cmd.step);
}

pub fn Sdk(comptime deps: anytype) type {
    return struct {
        pub fn testStep(b: *std.Build, optimize: std.builtin.OptimizeMode, target: std.zig.CrossTarget, options: Options) !*std.build.RunStep {
            const main_tests = b.addTest(.{
                .name = "gpu-tests",
                .root_source_file = .{ .path = sdkPath("/src/main.zig") },
                .target = target,
                .optimize = optimize,
            });
            try link(b, main_tests, options);
            b.installArtifact(main_tests);
            return b.addRunArtifact(main_tests);
        }

        pub const Options = struct {
            gpu_dawn_options: deps.gpu_dawn.Options = .{},
        };

        var _module: ?*std.build.Module = null;

        pub fn module(b: *std.Build) *std.build.Module {
            if (_module) |m| return m;
            _module = b.createModule(.{
                .source_file = .{ .path = sdkPath("/src/main.zig") },
            });
            return _module.?;
        }

        pub fn link(b: *std.Build, step: *std.build.CompileStep, options: Options) !void {
            if (step.target.toTarget().cpu.arch != .wasm32) {
                try deps.gpu_dawn.link(b, step, options.gpu_dawn_options);
                step.addCSourceFile(sdkPath("/src/mach_dawn.cpp"), &.{"-std=c++17"});
                step.addIncludePath(sdkPath("/src"));
            }
        }

        fn sdkPath(comptime suffix: []const u8) []const u8 {
            if (suffix[0] != '/') @compileError("suffix must be an absolute path");
            return comptime blk: {
                const root_dir = std.fs.path.dirname(@src().file) orelse ".";
                break :blk root_dir ++ suffix;
            };
        }
    };
}

// TODO(build-system): This is a workaround that we copy anywhere xcode_frameworks needs to be used.
// With the Zig package manager, it should be possible to remove this entirely and instead just
// write:
//
// ```
// step.linkLibrary(b.dependency("xcode_frameworks", .{
//     .target = step.target,
//     .optimize = step.optimize,
// }).artifact("xcode-frameworks"));
// @import("xcode_frameworks").addPaths(step);
// ```
//
// However, today this package cannot be imported with the Zig package manager due to `error: TarUnsupportedFileType`
// which would be fixed by https://github.com/ziglang/zig/pull/15382 - so instead for now you must
// copy+paste this struct into your `build.zig` and write:
//
// ```
// try xcode_frameworks.addPaths(b, step);
// ```
const xcode_frameworks = struct {
    pub fn addPaths(b: *std.Build, step: *std.build.CompileStep) void {
        // branch: mach
        xEnsureGitRepoCloned(b.allocator, "https://github.com/hexops/xcode-frameworks", "723aa55e9752c8c6c25d3413722b5fe13d72ac4f", xSdkPath("/zig-cache/xcode_frameworks")) catch |err| @panic(@errorName(err));

        step.addFrameworkPath("zig-cache/xcode_frameworks/Frameworks");
        step.addSystemIncludePath("zig-cache/xcode_frameworks/include");
        step.addLibraryPath("zig-cache/xcode_frameworks/lib");
    }

    fn xEnsureGitRepoCloned(allocator: std.mem.Allocator, clone_url: []const u8, revision: []const u8, dir: []const u8) !void {
        if (xIsEnvVarTruthy(allocator, "NO_ENSURE_SUBMODULES") or xIsEnvVarTruthy(allocator, "NO_ENSURE_GIT")) {
            return;
        }

        xEnsureGit(allocator);

        if (std.fs.openDirAbsolute(dir, .{})) |_| {
            const current_revision = try xGetCurrentGitRevision(allocator, dir);
            if (!std.mem.eql(u8, current_revision, revision)) {
                // Reset to the desired revision
                xExec(allocator, &[_][]const u8{ "git", "fetch" }, dir) catch |err| std.debug.print("warning: failed to 'git fetch' in {s}: {s}\n", .{ dir, @errorName(err) });
                try xExec(allocator, &[_][]const u8{ "git", "checkout", "--quiet", "--force", revision }, dir);
                try xExec(allocator, &[_][]const u8{ "git", "submodule", "update", "--init", "--recursive" }, dir);
            }
            return;
        } else |err| return switch (err) {
            error.FileNotFound => {
                std.log.info("cloning required dependency..\ngit clone {s} {s}..\n", .{ clone_url, dir });

                try xExec(allocator, &[_][]const u8{ "git", "clone", "-c", "core.longpaths=true", clone_url, dir }, ".");
                try xExec(allocator, &[_][]const u8{ "git", "checkout", "--quiet", "--force", revision }, dir);
                try xExec(allocator, &[_][]const u8{ "git", "submodule", "update", "--init", "--recursive" }, dir);
                return;
            },
            else => err,
        };
    }

    fn xExec(allocator: std.mem.Allocator, argv: []const []const u8, cwd: []const u8) !void {
        var child = std.ChildProcess.init(argv, allocator);
        child.cwd = cwd;
        _ = try child.spawnAndWait();
    }

    fn xGetCurrentGitRevision(allocator: std.mem.Allocator, cwd: []const u8) ![]const u8 {
        const result = try std.ChildProcess.exec(.{ .allocator = allocator, .argv = &.{ "git", "rev-parse", "HEAD" }, .cwd = cwd });
        allocator.free(result.stderr);
        if (result.stdout.len > 0) return result.stdout[0 .. result.stdout.len - 1]; // trim newline
        return result.stdout;
    }

    fn xEnsureGit(allocator: std.mem.Allocator) void {
        const argv = &[_][]const u8{ "git", "--version" };
        const result = std.ChildProcess.exec(.{
            .allocator = allocator,
            .argv = argv,
            .cwd = ".",
        }) catch { // e.g. FileNotFound
            std.log.err("mach: error: 'git --version' failed. Is git not installed?", .{});
            std.process.exit(1);
        };
        defer {
            allocator.free(result.stderr);
            allocator.free(result.stdout);
        }
        if (result.term.Exited != 0) {
            std.log.err("mach: error: 'git --version' failed. Is git not installed?", .{});
            std.process.exit(1);
        }
    }

    fn xIsEnvVarTruthy(allocator: std.mem.Allocator, name: []const u8) bool {
        if (std.process.getEnvVarOwned(allocator, name)) |truthy| {
            defer allocator.free(truthy);
            if (std.mem.eql(u8, truthy, "true")) return true;
            return false;
        } else |_| {
            return false;
        }
    }

    fn xSdkPath(comptime suffix: []const u8) []const u8 {
        if (suffix[0] != '/') @compileError("suffix must be an absolute path");
        return comptime blk: {
            const root_dir = std.fs.path.dirname(@src().file) orelse ".";
            break :blk root_dir ++ suffix;
        };
    }
};
