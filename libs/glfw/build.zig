const builtin = @import("builtin");
const std = @import("std");
const Builder = std.build.Builder;

const system_sdk = @import("system_sdk.zig");

pub fn build(b: *Builder) !void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&(try testStep(b, mode, target)).step);
    test_step.dependOn(&(try testStepShared(b, mode, target)).step);
}

pub fn testStep(b: *Builder, mode: std.builtin.Mode, target: std.zig.CrossTarget) !*std.build.RunStep {
    const main_tests = b.addTestExe("glfw-tests", sdkPath(b, "/src/main.zig"));
    main_tests.setBuildMode(mode);
    main_tests.setTarget(target);
    try link(b, main_tests, .{});
    main_tests.install();
    return main_tests.run();
}

fn testStepShared(b: *Builder, mode: std.builtin.Mode, target: std.zig.CrossTarget) !*std.build.RunStep {
    const main_tests = b.addTestExe("glfw-tests-shared", sdkPath(b, "/src/main.zig"));
    main_tests.setBuildMode(mode);
    main_tests.setTarget(target);
    try link(b, main_tests, .{ .shared = true });
    main_tests.install();
    return main_tests.run();
}

pub const LinuxWindowManager = enum {
    X11,
    Wayland,
};

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

var cached_pkg: ?std.build.Pkg = null;

pub fn pkg(b: *Builder) std.build.Pkg {
    if (cached_pkg == null) {
        cached_pkg = .{
            .name = "glfw",
            .source = .{ .path = sdkPath(b, "/src/main.zig") },
            .dependencies = &.{},
        };
    }

    return cached_pkg.?;
}

pub const LinkError = error{FailedToLinkGPU} || BuildError;
pub fn link(b: *Builder, step: *std.build.LibExeObjStep, options: Options) LinkError!void {
    const lib = try buildLibrary(b, step.build_mode, step.target, options);
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
fn buildLibrary(b: *Builder, mode: std.builtin.Mode, target: std.zig.CrossTarget, options: Options) BuildError!*std.build.LibExeObjStep {
    // TODO(build-system): https://github.com/hexops/mach/issues/229#issuecomment-1100958939
    ensureDependencySubmodule(b.allocator, "upstream") catch return error.CannotEnsureDependency;

    const lib = if (options.shared)
        b.addSharedLibrary("glfw", null, .unversioned)
    else
        b.addStaticLibrary("glfw", null);
    lib.setBuildMode(mode);
    lib.setTarget(target);

    if (options.shared)
        lib.defineCMacro("_GLFW_BUILD_DLL", null);

    addGLFWIncludes(lib);
    try addGLFWSources(b, lib, options);
    linkGLFWDependencies(b, lib, options);

    if (options.install_libs)
        lib.install();

    return lib;
}

fn addGLFWIncludes(step: *std.build.LibExeObjStep) void {
    step.addIncludePath(sdkPath(step.builder, "/upstream/glfw/include"));
    step.addIncludePath(sdkPath(step.builder, "/upstream/vulkan_headers/include"));
}

fn addGLFWSources(b: *Builder, lib: *std.build.LibExeObjStep, options: Options) std.mem.Allocator.Error!void {
    const include_glfw_src = try std.mem.concat(b.allocator, u8, &.{ "-I", sdkPath(b, "/upstream/glfw/src") });
    switch (lib.target_info.target.os.tag) {
        .windows => lib.addCSourceFiles(&.{
            sdkPath(b, "/src/sources_all.c"),
            sdkPath(b, "/src/sources_windows.c"),
        }, &.{ "-D_GLFW_WIN32", include_glfw_src }),
        .macos => lib.addCSourceFiles(&.{
            sdkPath(b, "/src/sources_all.c"),
            sdkPath(b, "/src/sources_macos.m"),
            sdkPath(b, "/src/sources_macos.c"),
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
            try sources.append(sdkPath(b, "/src/sources_all.c"));
            try sources.append(sdkPath(b, "/src/sources_linux.c"));
            if (options.x11) {
                try sources.append(sdkPath(b, "/src/sources_linux_x11.c"));
                try flags.append("-D_GLFW_X11");
            }
            if (options.wayland) {
                try sources.append(sdkPath(b, "/src/sources_linux_wayland.c"));
                try flags.append("-D_GLFW_WAYLAND");
            }
            try flags.append(include_glfw_src);
            // TODO(upstream): glfw can't compile on clang15 without this flag
            try flags.append("-Wno-implicit-function-declaration");

            lib.addCSourceFiles(sources.items, flags.items);
        },
    }
}

fn linkGLFWDependencies(b: *Builder, step: *std.build.LibExeObjStep, options: Options) void {
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
    child.cwd = sdkPathAllocator(allocator, "/");
    child.stderr = std.io.getStdErr();
    child.stdout = std.io.getStdOut();

    _ = try child.spawnAndWait();
}

const unresolved_dir = (struct {
    inline fn unresolvedDir() []const u8 {
        return comptime std.fs.path.dirname(@src().file) orelse ".";
    }
}).unresolvedDir();

fn thisDir(allocator: std.mem.Allocator) []const u8 {
    if (comptime unresolved_dir[0] == '/') {
        return unresolved_dir;
    }

    const cached_dir = &(struct {
        var cached_dir: ?[]const u8 = null;
    }).cached_dir;

    if (cached_dir.* == null) {
        cached_dir.* = std.fs.cwd().realpathAlloc(allocator, unresolved_dir) catch unreachable;
    }

    return cached_dir.*.?;
}

inline fn sdkPath(b: *Builder, comptime suffix: []const u8) []const u8 {
    return sdkPathAllocator(b.allocator, suffix);
}

inline fn sdkPathAllocator(allocator: std.mem.Allocator, comptime suffix: []const u8) []const u8 {
    return sdkPathInternal(allocator, suffix.len, suffix[0..suffix.len].*);
}

fn sdkPathInternal(allocator: std.mem.Allocator, comptime len: usize, comptime suffix: [len]u8) []const u8 {
    if (suffix[0] != '/') @compileError("suffix must be an absolute path");

    if (comptime unresolved_dir[0] == '/') {
        return unresolved_dir ++ @as([]const u8, &suffix);
    }

    const cached_dir = &(struct {
        var cached_dir: ?[]const u8 = null;
    }).cached_dir;

    if (cached_dir.* == null) {
        cached_dir.* = std.fs.path.resolve(allocator, &.{ thisDir(allocator), suffix[1..] }) catch unreachable;
    }

    return cached_dir.*.?;
}
