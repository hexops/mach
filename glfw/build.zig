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

    system_sdk.include(b, step, .{});
    const target = (std.zig.system.NativeTargetInfo.detect(b.allocator, step.target) catch unreachable).target;
    switch (target.os.tag) {
        .windows => {
            var sources = std.ArrayList([]const u8).init(b.allocator);
            for ([_][]const u8{
                // Windows-specific sources
                "upstream/glfw/src/win32_thread.c",
                "upstream/glfw/src/wgl_context.c",
                "upstream/glfw/src/win32_init.c",
                "upstream/glfw/src/win32_monitor.c",
                "upstream/glfw/src/win32_time.c",
                "upstream/glfw/src/win32_joystick.c",
                "upstream/glfw/src/win32_window.c",

                // General sources
                "upstream/glfw/src/monitor.c",
                "upstream/glfw/src/init.c",
                "upstream/glfw/src/vulkan.c",
                "upstream/glfw/src/input.c",
                "upstream/glfw/src/osmesa_context.c",
                "upstream/glfw/src/egl_context.c",
                "upstream/glfw/src/context.c",
                "upstream/glfw/src/window.c",
            }) |path| {
                const abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), path }) catch unreachable;
                sources.append(abs_path) catch unreachable;
            }
            lib.addCSourceFiles(sources.items, &.{"-D_GLFW_WIN32"});
        },
        .macos => {
            var sources = std.ArrayList([]const u8).init(b.allocator);
            for ([_][]const u8{
                // MacOS-specific sources
                "upstream/glfw/src/cocoa_joystick.m",
                "upstream/glfw/src/cocoa_init.m",
                "upstream/glfw/src/cocoa_window.m",
                "upstream/glfw/src/cocoa_time.c",
                "upstream/glfw/src/cocoa_monitor.m",
                "upstream/glfw/src/nsgl_context.m",
                "upstream/glfw/src/posix_thread.c",

                // General sources
                "upstream/glfw/src/monitor.c",
                "upstream/glfw/src/init.c",
                "upstream/glfw/src/vulkan.c",
                "upstream/glfw/src/input.c",
                "upstream/glfw/src/osmesa_context.c",
                "upstream/glfw/src/egl_context.c",
                "upstream/glfw/src/context.c",
                "upstream/glfw/src/window.c",
            }) |path| {
                const abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), path }) catch unreachable;
                sources.append(abs_path) catch unreachable;
            }
            lib.addCSourceFiles(sources.items, &.{"-D_GLFW_COCOA"});
        },
        else => {
            // TODO(future): for now, Linux must be built with glibc, not musl:
            //
            // ```
            // ld.lld: error: cannot create a copy relocation for symbol stderr
            // thread 2004762 panic: attempt to unwrap error: LLDReportedFailure
            // ```
            step.target.abi = .gnu;
            lib.setTarget(step.target);

            var general_sources = std.ArrayList([]const u8).init(b.allocator);
            const flag = switch (options.linux_window_manager) {
                .X11 => "-D_GLFW_X11",
                .Wayland => "-D_GLFW_WAYLAND",
            };
            for ([_][]const u8{
                // General Linux-like sources
                "upstream/glfw/src/posix_time.c",
                "upstream/glfw/src/posix_thread.c",
                "upstream/glfw/src/linux_joystick.c",

                // General sources
                "upstream/glfw/src/monitor.c",
                "upstream/glfw/src/init.c",
                "upstream/glfw/src/vulkan.c",
                "upstream/glfw/src/input.c",
                "upstream/glfw/src/osmesa_context.c",
                "upstream/glfw/src/egl_context.c",
                "upstream/glfw/src/context.c",
                "upstream/glfw/src/window.c",
            }) |path| {
                const abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), path }) catch unreachable;
                general_sources.append(abs_path) catch unreachable;
            }
            lib.addCSourceFiles(general_sources.items, &.{flag});

            switch (options.linux_window_manager) {
                .X11 => {
                    var x11_sources = std.ArrayList([]const u8).init(b.allocator);
                    for ([_][]const u8{
                        "upstream/glfw/src/x11_init.c",
                        "upstream/glfw/src/x11_window.c",
                        "upstream/glfw/src/x11_monitor.c",
                        "upstream/glfw/src/xkb_unicode.c",
                        "upstream/glfw/src/glx_context.c",
                    }) |path| {
                        const abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), path }) catch unreachable;
                        x11_sources.append(abs_path) catch unreachable;
                    }
                    lib.addCSourceFiles(x11_sources.items, &.{flag});
                },
                .Wayland => {
                    var wayland_sources = std.ArrayList([]const u8).init(b.allocator);
                    for ([_][]const u8{
                        "upstream/glfw/src/wl_monitor.c",
                        "upstream/glfw/src/wl_window.c",
                        "upstream/glfw/src/wl_init.c",
                    }) |path| {
                        const abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), path }) catch unreachable;
                        wayland_sources.append(abs_path) catch unreachable;
                    }
                    lib.addCSourceFiles(wayland_sources.items, &.{flag});
                },
            }
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
    system_sdk.include(b, step, .{});
    const target = (std.zig.system.NativeTargetInfo.detect(b.allocator, step.target) catch unreachable).target;
    switch (target.os.tag) {
        .windows => {
            step.linkSystemLibrary("gdi32");
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
