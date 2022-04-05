const std = @import("std");
const Builder = std.build.Builder;

const system_sdk = @import("system_sdk.zig");

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    const main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);
    main_tests.setTarget(target);
    link(b, main_tests, .{});

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
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
    linux_window_manager: LinuxWindowManager = .X11,

    /// System SDK options.
    system_sdk: system_sdk.Options = .{},
};

pub const pkg = .{
    .name = "glfw",
    .path = .{ .path = thisDir() ++ "/src/main.zig" },
};

pub fn link(b: *Builder, step: *std.build.LibExeObjStep, options: Options) void {
    const lib = buildLibrary(b, step, options);
    step.linkLibrary(lib);
    linkGLFWDependencies(b, step, options);
}

fn buildLibrary(b: *Builder, step: *std.build.LibExeObjStep, options: Options) *std.build.LibExeObjStep {
    const main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/main.zig" }) catch unreachable;
    const lib = b.addStaticLibrary("glfw", main_abs);
    lib.setBuildMode(step.build_mode);
    lib.setTarget(step.target);

    // TODO(build-system): pass system SDK options through
    system_sdk.include(b, step, .{});
    const target = (std.zig.system.NativeTargetInfo.detect(b.allocator, step.target) catch unreachable).target;
    const include_glfw_src = "-I" ++ thisDir() ++ "/upstream/glfw/src";
    switch (target.os.tag) {
        .windows => lib.addCSourceFile(thisDir() ++ "/src/sources_windows.c", &.{ "-D_GLFW_WIN32", include_glfw_src }),
        .macos => lib.addCSourceFiles(&.{
            thisDir() ++ "/src/sources_macos.m",
            thisDir() ++ "/src/sources_macos.c",
        }, &.{ "-D_GLFW_COCOA", include_glfw_src }),
        else => {
            // TODO(future): for now, Linux must be built with glibc, not musl:
            //
            // ```
            // ld.lld: error: cannot create a copy relocation for symbol stderr
            // thread 2004762 panic: attempt to unwrap error: LLDReportedFailure
            // ```
            step.target.abi = .gnu;
            lib.setTarget(step.target);

            var sources = std.ArrayList([]const u8).init(b.allocator);
            const flag = switch (options.linux_window_manager) {
                .X11 => "-D_GLFW_X11",
                .Wayland => "-D_GLFW_WAYLAND",
            };
            sources.append(thisDir() ++ "/src/sources_linux.c") catch unreachable;
            switch (options.linux_window_manager) {
                .X11 => sources.append(thisDir() ++ "/src/sources_linux_x11.c") catch unreachable,
                .Wayland => sources.append(thisDir() ++ "/src/sources_linux_wayland.c") catch unreachable,
            }
            lib.addCSourceFiles(sources.items, &.{ flag, "-I" ++ thisDir() ++ "/upstream/glfw/src" });
        },
    }
    linkGLFWDependencies(b, lib, options);
    lib.install();
    return lib;
}

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}

fn linkGLFWDependencies(b: *Builder, step: *std.build.LibExeObjStep, options: Options) void {
    const include_dir = std.fs.path.join(b.allocator, &.{ thisDir(), "upstream/glfw/include" }) catch unreachable;
    defer b.allocator.free(include_dir);
    step.addIncludeDir(include_dir);

    const vulkan_include_dir = std.fs.path.join(b.allocator, &.{ thisDir(), "upstream/vulkan_headers/include" }) catch unreachable;
    defer b.allocator.free(vulkan_include_dir);
    step.addIncludeDir(vulkan_include_dir);

    step.linkLibC();
    // TODO(build-system): pass system SDK options through
    system_sdk.include(b, step, .{});
    const target = (std.zig.system.NativeTargetInfo.detect(b.allocator, step.target) catch unreachable).target;
    switch (target.os.tag) {
        .windows => {
            step.linkSystemLibrary("gdi32");
            step.linkSystemLibrary("user32");
            step.linkSystemLibrary("shell32");
            if (options.opengl) {
                step.linkSystemLibrary("opengl32");
            }
            if (options.gles) {
                step.linkSystemLibrary("GLESv3");
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
            step.linkSystemLibrary("objc");
            step.linkFramework("AppKit");
            step.linkFramework("CoreServices");
            step.linkFramework("CoreGraphics");
            step.linkFramework("Foundation");
        },
        else => {
            // Assume Linux-like
            switch (options.linux_window_manager) {
                .X11 => {
                    step.linkSystemLibrary("X11");
                    step.linkSystemLibrary("xcb");
                    step.linkSystemLibrary("Xau");
                    step.linkSystemLibrary("Xdmcp");
                },
                .Wayland => step.linkSystemLibrary("wayland-client"),
            }
            // Note: no need to link against vulkan, GLFW finds it dynamically at runtime.
            // https://www.glfw.org/docs/3.3/vulkan_guide.html#vulkan_loader
            if (options.opengl) {
                step.linkSystemLibrary("GL");
            }
            if (options.gles) {
                step.linkSystemLibrary("GLESv3");
            }
        },
    }
}
