const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&testStep(b, optimize, target).step);

    inline for ([_][]const u8{
        "sine-wave",
    }) |example| {
        const example_exe = b.addExecutable(.{
            .name = "example-" ++ example,
            .root_source_file = .{ .path = "examples/" ++ example ++ ".zig" },
            .target = target,
            .optimize = optimize,
        });
        example_exe.addModule("sysaudio", module(b, optimize, target));
        link(b, example_exe, .{});
        b.installArtifact(example_exe);

        const example_compile_step = b.step("example-" ++ example, "Compile '" ++ example ++ "' example");
        example_compile_step.dependOn(b.getInstallStep());

        const example_run_cmd = b.addRunArtifact(example_exe);
        example_run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            example_run_cmd.addArgs(args);
        }

        const example_run_step = b.step("run-example-" ++ example, "Run '" ++ example ++ "' example");
        example_run_step.dependOn(&example_run_cmd.step);
    }
}

pub const Options = struct {
    install_libs: bool = false,
};

var _module: ?*std.build.Module = null;

pub fn module(b: *std.Build, optimize: std.builtin.OptimizeMode, target: std.zig.CrossTarget) *std.build.Module {
    if (_module) |m| return m;

    if (target.getCpuArch() == .wasm32) {
        const sysjs_dep = b.dependency("mach_sysjs", .{
            .target = target,
            .optimize = optimize,
        });
        _module = b.createModule(.{
            .source_file = .{ .path = sdkPath("/src/main.zig") },
            .dependencies = &.{
                .{ .name = "sysjs", .module = sysjs_dep.module("mach-sysjs") },
            },
        });
    } else {
        _module = b.createModule(.{
            .source_file = .{ .path = sdkPath("/src/main.zig") },
        });
    }
    return _module.?;
}

pub fn testStep(b: *std.Build, optimize: std.builtin.OptimizeMode, target: std.zig.CrossTarget) *std.build.RunStep {
    const main_tests = b.addTest(.{
        .name = "sysaudio-tests",
        .root_source_file = .{ .path = sdkPath("/src/main.zig") },
        .target = target,
        .optimize = optimize,
    });
    link(b, main_tests, .{});
    b.installArtifact(main_tests);
    return b.addRunArtifact(main_tests);
}

pub fn link(b: *std.Build, step: *std.build.CompileStep, options: Options) void {
    if (step.target.toTarget().cpu.arch != .wasm32) {
        if (step.target.toTarget().isDarwin()) {
            // TODO(build-system): This cannot be imported with the Zig package manager
            // error: TarUnsupportedFileType
            //
            // step.linkLibrary(b.dependency("xcode_frameworks", .{
            //     .target = step.target,
            //     .optimize = step.optimize,
            // }).artifact("xcode-frameworks"));
            // @import("xcode_frameworks").addPaths(step);
            xcode_frameworks.addPaths(b, step);

            step.linkFramework("AudioToolbox");
            step.linkFramework("CoreFoundation");
            step.linkFramework("CoreAudio");
        } else if (step.target.toTarget().os.tag == .linux) {
            step.linkLibrary(b.dependency("linux_audio_headers", .{
                .target = step.target,
                .optimize = step.optimize,
            }).artifact("linux-audio-headers"));
            step.addCSourceFile(sdkPath("/src/pipewire/sysaudio.c"), &.{"-std=gnu99"});
            step.linkLibC();
        }
    }
    if (options.install_libs) {
        b.installArtifact(step);
    }
}

fn ensureDependencySubmodule(allocator: std.mem.Allocator, path: []const u8) !void {
    if (std.process.getEnvVarOwned(allocator, "NO_ENSURE_SUBMODULES")) |no_ensure_submodules| {
        defer allocator.free(no_ensure_submodules);
        if (std.mem.eql(u8, no_ensure_submodules, "true")) return;
    } else |_| {}
    var child = std.ChildProcess.init(&.{ "git", "submodule", "update", "--init", path }, allocator);
    child.cwd = sdkPath("/");
    child.stderr = std.io.getStdErr();
    child.stdout = std.io.getStdOut();

    _ = try child.spawnAndWait();
}

fn sdkPath(comptime suffix: []const u8) []const u8 {
    if (suffix[0] != '/') @compileError("suffix must be an absolute path");
    return comptime blk: {
        const root_dir = std.fs.path.dirname(@src().file) orelse ".";
        break :blk root_dir ++ suffix;
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
        ensureGitRepoCloned(b.allocator, "https://github.com/hexops/xcode-frameworks", "723aa55e9752c8c6c25d3413722b5fe13d72ac4f", "zig-cache/xcode_frameworks") catch |err| @panic(@errorName(err));

        step.addFrameworkPath("zig-cache/xcode_frameworks/Frameworks");
        step.addSystemIncludePath("zig-cache/xcode_frameworks/include");
        step.addLibraryPath("zig-cache/xcode_frameworks/lib");
    }

    fn xcodeSdkPath(comptime suffix: []const u8) []const u8 {
        if (suffix[0] != '/') @compileError("suffix must be an absolute path");
        return comptime blk: {
            const root_dir = std.fs.path.dirname(@src().file) orelse ".";
            break :blk root_dir ++ suffix;
        };
    }

    fn ensureGitRepoCloned(allocator: std.mem.Allocator, clone_url: []const u8, revision: []const u8, rel_dir: []const u8) !void {
        if (isEnvVarTruthy(allocator, "NO_ENSURE_SUBMODULES") or isEnvVarTruthy(allocator, "NO_ENSURE_GIT")) {
            return;
        }

        ensureGit(allocator);

        if (std.fs.cwd().realpathAlloc(allocator, rel_dir)) |dir| {
            const current_revision = try getCurrentGitRevision(allocator, dir);
            if (!std.mem.eql(u8, current_revision, revision)) {
                // Reset to the desired revision
                exec(allocator, &[_][]const u8{ "git", "fetch" }, dir) catch |err| std.debug.print("warning: failed to 'git fetch' in {s}: {s}\n", .{ dir, @errorName(err) });
                try exec(allocator, &[_][]const u8{ "git", "checkout", "--quiet", "--force", revision }, dir);
                try exec(allocator, &[_][]const u8{ "git", "submodule", "update", "--init", "--recursive" }, dir);
            }
            return;
        } else |err| return switch (err) {
            error.FileNotFound => {
                std.log.info("cloning required dependency..\ngit clone {s} {s}..\n", .{ clone_url, rel_dir });

                try exec(allocator, &[_][]const u8{ "git", "clone", "-c", "core.longpaths=true", clone_url, rel_dir }, xcodeSdkPath("/"));
                try exec(allocator, &[_][]const u8{ "git", "checkout", "--quiet", "--force", revision }, rel_dir);
                try exec(allocator, &[_][]const u8{ "git", "submodule", "update", "--init", "--recursive" }, rel_dir);
                return;
            },
            else => err,
        };
    }

    fn exec(allocator: std.mem.Allocator, argv: []const []const u8, cwd: []const u8) !void {
        var child = std.ChildProcess.init(argv, allocator);
        child.cwd = cwd;
        _ = try child.spawnAndWait();
    }

    fn getCurrentGitRevision(allocator: std.mem.Allocator, cwd: []const u8) ![]const u8 {
        const result = try std.ChildProcess.exec(.{ .allocator = allocator, .argv = &.{ "git", "rev-parse", "HEAD" }, .cwd = cwd });
        allocator.free(result.stderr);
        if (result.stdout.len > 0) return result.stdout[0 .. result.stdout.len - 1]; // trim newline
        return result.stdout;
    }

    fn ensureGit(allocator: std.mem.Allocator) void {
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

    fn isEnvVarTruthy(allocator: std.mem.Allocator, name: []const u8) bool {
        if (std.process.getEnvVarOwned(allocator, name)) |truthy| {
            defer allocator.free(truthy);
            if (std.mem.eql(u8, truthy, "true")) return true;
            return false;
        } else |_| {
            return false;
        }
    }
};
