const builtin = @import("builtin");
const std = @import("std");
const Build = std.Build;

const system_sdk = @import("system_sdk.zig");

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

fn testStepShared(b: *Build, optimize: std.builtin.OptimizeMode, target: std.zig.CrossTarget) !*std.build.RunStep {
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

    /// System SDK options.
    system_sdk: system_sdk.Options = .{},

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

pub const LinkError = error{FailedToLinkGPU} || BuildError;
pub fn link(b: *Build, step: *std.build.CompileStep, options: Options) LinkError!void {
    const lib = try buildLibrary(b, step.optimize, step.target, options);
    step.linkLibrary(lib);
    addGLFWIncludes(step);
    if (options.shared) {
        step.defineCMacro("GLFW_DLL", null);
        system_sdk.include(b, step, options.system_sdk);
    } else {
        linkGLFWDependencies(b, step, options);
    }
}

pub const BuildError = error{CannotEnsureDependency} || std.mem.Allocator.Error;
fn buildLibrary(b: *Build, optimize: std.builtin.OptimizeMode, target: std.zig.CrossTarget, options: Options) BuildError!*std.build.CompileStep {
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
    step.addIncludePath(sdkPath("/upstream/vulkan_headers/include"));
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
    step.linkLibC();
    system_sdk.include(b, step, options.system_sdk);
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
