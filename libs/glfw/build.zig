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
    if (options.shared) step.defineCMacro("GLFW_DLL", null);
    const lib = try buildLibrary(b, step.optimize, step.target, options);
    step.linkLibrary(lib);
    addGLFWIncludes(step);
    linkGLFWDependencies(b, step, options);
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

fn buildLibrary(b: *Build, optimize: std.builtin.OptimizeMode, target: std.zig.CrossTarget, options: Options) !*std.build.CompileStep {
    // TODO(build-system): https://github.com/hexops/mach/issues/229#issuecomment-1100958939
    ensureDependencySubmodule(b.allocator, "upstream") catch return error.CannotEnsureDependency;

    const lib = if (options.shared)
        b.addSharedLibrary(.{ .name = "glfw", .target = target, .optimize = optimize })
    else
        b.addStaticLibrary(.{ .name = "glfw", .target = target, .optimize = optimize });

    if (options.shared)
        lib.defineCMacro("_GLFW_BUILD_DLL", null);

    addGLFWIncludes(lib);
    try addGLFWSources(b, lib, options);
    linkGLFWDependencies(b, lib, options);

    if (options.install_libs)
        b.installArtifact(lib);

    return lib;
}

fn addGLFWIncludes(step: *std.build.CompileStep) void {
    step.addIncludePath(sdkPath("/upstream/glfw/include"));
    step.addIncludePath(sdkPath("/src"));
}

fn addGLFWSources(b: *Build, lib: *std.build.CompileStep, options: Options) std.mem.Allocator.Error!void {
    const include_glfw_src = comptime "-I" ++ sdkPath("/upstream/glfw/src");
    switch (lib.target_info.target.os.tag) {
        .windows => lib.addCSourceFiles(&.{
            sdkPath("/src/sources_all.c"),
            sdkPath("/src/sources_windows.c"),
        }, &.{ "-D_GLFW_WIN32", include_glfw_src }),
        .macos => lib.addCSourceFiles(&.{
            sdkPath("/src/sources_all.c"),
            sdkPath("/src/sources_macos.m"),
            sdkPath("/src/sources_macos.c"),
        }, &.{ "-D_GLFW_COCOA", include_glfw_src }),
        else => {
            // TODO(future): for now, Linux can't be built with musl:
            //
            // ```
            // ld.lld: error: cannot create a copy relocation for symbol stderr
            // thread 2004762 panic: attempt to unwrap error: LLDReportedFailure
            // ```
            var sources = std.ArrayList([]const u8).init(b.allocator);
            var flags = std.ArrayList([]const u8).init(b.allocator);
            try sources.append(sdkPath("/src/sources_all.c"));
            try sources.append(sdkPath("/src/sources_linux.c"));
            if (options.x11) {
                try sources.append(sdkPath("/src/sources_linux_x11.c"));
                try flags.append("-D_GLFW_X11");
            }
            if (options.wayland) {
                try sources.append(sdkPath("/src/sources_linux_wayland.c"));
                try flags.append("-D_GLFW_WAYLAND");
            }
            try flags.append(comptime "-I" ++ sdkPath("/upstream/glfw/src"));
            // TODO(upstream): glfw can't compile on clang15 without this flag
            try flags.append("-Wno-implicit-function-declaration");

            lib.addCSourceFiles(sources.items, flags.items);
        },
    }
}

fn linkGLFWDependencies(b: *Build, step: *std.build.CompileStep, options: Options) void {
    if (step.target_info.target.os.tag == .windows) {
        step.linkLibrary(b.dependency("direct3d_headers", .{
            .target = step.target,
            .optimize = step.optimize,
        }).artifact("direct3d-headers"));
    }
    if (options.x11) {
        step.linkLibrary(b.dependency("x11_headers", .{
            .target = step.target,
            .optimize = step.optimize,
        }).artifact("x11-headers"));
    }
    if (options.vulkan) {
        step.linkLibrary(b.dependency("vulkan_headers", .{
            .target = step.target,
            .optimize = step.optimize,
        }).artifact("vulkan-headers"));
    }
    if (options.wayland) {
        step.defineCMacro("WL_MARSHAL_FLAG_DESTROY", null);
        step.linkLibrary(b.dependency("wayland_headers", .{
            .target = step.target,
            .optimize = step.optimize,
        }).artifact("wayland-headers"));
    }
    if (step.target_info.target.os.tag == .windows) @import("direct3d_headers").addLibraryPath(step);

    step.linkLibC();
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
    switch (step.target_info.target.os.tag) {
        .windows => {
            step.linkSystemLibraryName("gdi32");
            step.linkSystemLibraryName("user32");
            step.linkSystemLibraryName("shell32");
            if (options.opengl) {
                step.linkSystemLibraryName("opengl32");
            }
            if (options.gles) {
                step.linkSystemLibraryName("GLESv3");
            }
        },
        .macos => {
            step.linkFramework("IOKit");
            step.linkFramework("CoreFoundation");
            if (options.metal) {
                step.linkFramework("Metal");
            }
            if (options.opengl) {
                step.linkFramework("OpenGL");
            }
            step.linkSystemLibraryName("objc");
            step.linkFramework("AppKit");
            step.linkFramework("CoreServices");
            step.linkFramework("CoreGraphics");
            step.linkFramework("Foundation");
        },
        else => {
            // Assume Linux-like
            if (options.wayland) {
                step.defineCMacro("WL_MARSHAL_FLAG_DESTROY", null);
            }
        },
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
        xEnsureGitRepoCloned(b.allocator, "https://github.com/hexops/xcode-frameworks", "723aa55e9752c8c6c25d3413722b5fe13d72ac4f", "zig-cache/xcode_frameworks") catch |err| @panic(@errorName(err));

        step.addFrameworkPath("zig-cache/xcode_frameworks/Frameworks");
        step.addSystemIncludePath("zig-cache/xcode_frameworks/include");
        step.addLibraryPath("zig-cache/xcode_frameworks/lib");
    }

    fn xEnsureGitRepoCloned(allocator: std.mem.Allocator, clone_url: []const u8, revision: []const u8, dir: []const u8) !void {
        if (xIsEnvVarTruthy(allocator, "NO_ENSURE_SUBMODULES") or xIsEnvVarTruthy(allocator, "NO_ENSURE_GIT")) {
            return;
        }

        xEnsureGit(allocator);

        if (std.fs.cwd().openDir(dir, .{})) |_| {
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
};
