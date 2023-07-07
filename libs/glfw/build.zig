const builtin = @import("builtin");
const std = @import("std");
const Build = std.Build;

pub fn build(b: *Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&(try testStep(b, optimize, target)).step);
    test_step.dependOn(&(try testStepShared(b, optimize, target)).step);
}

pub fn testStep(b: *Build, optimize: std.builtin.OptimizeMode, target: std.zig.CrossTarget) !*std.build.RunStep {
    const main_tests = b.addTest(.{
        .name = "glfw-tests",
        .root_source_file = .{ .path = sdkPath("/src/main.zig") },
        .target = target,
        .optimize = optimize,
    });

    try link(b, main_tests, .{});
    b.installArtifact(main_tests);
    return b.addRunArtifact(main_tests);
}

pub fn testStepShared(b: *Build, optimize: std.builtin.OptimizeMode, target: std.zig.CrossTarget) !*std.build.RunStep {
    const main_tests = b.addTest(.{
        .name = "glfw-tests-shared",
        .root_source_file = .{ .path = sdkPath("/src/main.zig") },
        .target = target,
        .optimize = optimize,
    });

    try link(b, main_tests, .{ .shared = true });
    b.installArtifact(main_tests);
    return b.addRunArtifact(main_tests);
}

pub const Options = struct {
    /// Not supported on macOS.
    vulkan: bool = true,

    /// Only respected on macOS.
    metal: bool = true,

    /// Deprecated on macOS.
    opengl: bool = false,

    /// Not supported on macOS. GLES v3.2 only, currently.
    gles: bool = false,

    /// Only respected on Linux.
    x11: bool = true,

    /// Only respected on Linux.
    wayland: bool = true,

    /// Build and link GLFW as a shared library.
    shared: bool = false,

    install_libs: bool = false,
};

var _module: ?*std.build.Module = null;

pub fn module(b: *std.Build) *std.build.Module {
    if (_module) |m| return m;
    _module = b.createModule(.{
        .source_file = .{ .path = sdkPath("/src/main.zig") },
    });
    return _module.?;
}

pub fn link(b: *Build, step: *std.build.CompileStep, options: Options) !void {
    _ = options;
    step.linkLibrary(b.dependency("glfw", .{
        .target = step.target,
        .optimize = step.optimize,
    }).artifact("glfw"));

    step.linkLibrary(b.dependency("vulkan_headers", .{
        .target = step.target,
        .optimize = step.optimize,
    }).artifact("vulkan-headers"));

    if (step.target_info.target.os.tag == .macos) {
        // TODO(build-system): This cannot be imported with the Zig package manager
        // error: TarUnsupportedFileType
        //
        // step.linkLibrary(b.dependency("xcode_frameworks", .{
        //     .target = step.target,
        //     .optimize = step.optimize,
        // }).artifact("xcode-frameworks"));
        // @import("xcode_frameworks").addPaths(step);
        xcode_frameworks.addPaths(b, step);
    }
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
