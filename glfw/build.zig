const std = @import("std");
const Builder = std.build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    var main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);
    main_tests.setTarget(target);
    link(b, main_tests, .{});

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}

pub const Options = struct {
    GLES: bool = false,
    OpenGL: bool = true,
    Vulkan: bool = true,
};

pub fn link(b: *Builder, step: *std.build.LibExeObjStep, options: Options) void {
    var arena = std.heap.ArenaAllocator.init(b.allocator);
    defer arena.deinit();

    const lib = b.addStaticLibrary("engine", "src/main.zig");
    lib.setBuildMode(step.build_mode);
    lib.setTarget(step.target);

    const target = (std.zig.system.NativeTargetInfo.detect(b.allocator, step.target) catch unreachable).target;
    switch (target.os.tag) {
        .windows => {
            // TODO(slimsag): implement
            // upstream/glfw/src/win32_thread.c
            // upstream/glfw/src/wgl_context.c
            // upstream/glfw/src/win32_init.c
            // upstream/glfw/src/win32_monitor.c
            // upstream/glfw/src/win32_time.c
            // upstream/glfw/src/win32_joystick.c
            // upstream/glfw/src/win32_window.c
        },
        .macos => {
            var sources = std.ArrayList([]const u8).init(&arena.allocator);
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
                // "upstream/glfw/src/null_init.c",
                // "upstream/glfw/src/null_joystick.c",
                "upstream/glfw/src/init.c",
                "upstream/glfw/src/vulkan.c",
                // "upstream/glfw/src/null_monitor.c",
                "upstream/glfw/src/input.c",
                "upstream/glfw/src/osmesa_context.c",
                // "upstream/glfw/src/null_window.c",
                "upstream/glfw/src/egl_context.c",
                "upstream/glfw/src/context.c",
                "upstream/glfw/src/window.c",
            }) |path| {
                var abs_path = std.fs.path.join(&arena.allocator, &.{ thisDir(), path }) catch unreachable;
                sources.append(abs_path) catch unreachable;
            }
            lib.addCSourceFiles(sources.items, &.{"-D_GLFW_COCOA"});
        },
        else => {
            // Assume Linux-like
            // TODO(slimsag): implement

            // upstream/glfw/src/posix_time.c
            // upstream/glfw/src/posix_thread.c

            // upstream/glfw/src/wl_monitor.c
            // upstream/glfw/src/wl_window.c
            // upstream/glfw/src/wl_init.c

            // upstream/glfw/src/x11_init.c
            // upstream/glfw/src/x11_window.c
            // upstream/glfw/src/x11_monitor.c
            // upstream/glfw/src/xkb_unicode.c

            // upstream/glfw/src/linux_joystick.c
            // upstream/glfw/src/glx_context.c
        },
    }
    linkGLFW(b, lib, options);
    lib.install();

    step.linkLibrary(lib);
    linkGLFW(b, step, options);
}

fn linkGLFW(b: *Builder, step: *std.build.LibExeObjStep, options: Options) void {
    var include_dir = std.fs.path.join(b.allocator, &.{ thisDir(), "upstream/glfw/include" }) catch unreachable;
    defer b.allocator.free(include_dir);
    step.addIncludeDir(include_dir);

    const target = (std.zig.system.NativeTargetInfo.detect(b.allocator, step.target) catch unreachable).target;
    switch (target.os.tag) {
        .windows => {},
        .macos => {
            step.linkFramework("Cocoa");
            step.linkFramework("IOKit");
            step.linkFramework("CoreFoundation");
            if (options.GLES) {
                step.linkSystemLibrary("GLESv2");
            }
            if (options.OpenGL) {
                step.linkFramework("OpenGL");
            }
        },
        else => {
            // Assume Linux-like
        },
    }
}