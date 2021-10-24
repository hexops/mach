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
};

pub fn link(b: *Builder, step: *std.build.LibExeObjStep, options: Options) void {
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
                var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), path }) catch unreachable;
                sources.append(abs_path) catch unreachable;
            }
            step.addCSourceFiles(sources.items, &.{"-D_GLFW_WIN32"});
        },
        .macos => {
            includeSdkMacOS(b, step);
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
                var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), path }) catch unreachable;
                sources.append(abs_path) catch unreachable;
            }
            step.addCSourceFiles(sources.items, &.{"-D_GLFW_COCOA"});
        },
        else => {
            // Assume Linux-like
            includeSdkLinuxX8664(b, step);

            // TODO(future): for now, Linux must be built with glibc, not musl:
            //
            // ```
            // ld.lld: error: cannot create a copy relocation for symbol stderr
            // thread 2004762 panic: attempt to unwrap error: LLDReportedFailure
            // ```
            step.target.abi = .gnu;
            step.setTarget(step.target);

            var general_sources = std.ArrayList([]const u8).init(b.allocator);
            const flag = switch (options.linux_window_manager) {
                .X11 => "-D_GLFW_X11",
                .Wayland => "_D_GLFW_WAYLAND",
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
                var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), path }) catch unreachable;
                general_sources.append(abs_path) catch unreachable;
            }
            step.addCSourceFiles(general_sources.items, &.{flag});

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
                        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), path }) catch unreachable;
                        x11_sources.append(abs_path) catch unreachable;
                    }
                    step.addCSourceFiles(x11_sources.items, &.{flag});
                },
                .Wayland => {
                    var wayland_sources = std.ArrayList([]const u8).init(b.allocator);
                    for ([_][]const u8{
                        "upstream/glfw/src/wl_monitor.c",
                        "upstream/glfw/src/wl_window.c",
                        "upstream/glfw/src/wl_init.c",
                    }) |path| {
                        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), path }) catch unreachable;
                        wayland_sources.append(abs_path) catch unreachable;
                    }
                    step.addCSourceFiles(wayland_sources.items, &.{flag});
                },
            }
        },
    }
    linkGLFW(b, step, options);
}

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}

fn linkGLFW(b: *Builder, step: *std.build.LibExeObjStep, options: Options) void {
    var include_dir = std.fs.path.join(b.allocator, &.{ thisDir(), "upstream/glfw/include" }) catch unreachable;
    defer b.allocator.free(include_dir);
    step.addIncludeDir(include_dir);

    var vulkan_include_dir = std.fs.path.join(b.allocator, &.{ thisDir(), "upstream/vulkan_headers/include" }) catch unreachable;
    defer b.allocator.free(vulkan_include_dir);
    step.addIncludeDir(vulkan_include_dir);

    step.linkLibC();
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
            includeSdkMacOS(b, step);
            step.linkFramework("Cocoa");
            step.linkFramework("IOKit");
            step.linkFramework("CoreFoundation");
            if (options.metal) {
                step.linkFramework("Metal");
            }
            if (options.opengl) {
                step.linkFramework("OpenGL");
            }
        },
        else => {
            // Assume Linux-like
            includeSdkLinuxX8664(b, step);
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

fn includeSdkMacOS(b: *Builder, step: *std.build.LibExeObjStep) void {
    step.addFrameworkDir("/System/Library/Frameworks");
    step.addSystemIncludeDir("/usr/include");
    step.addLibPath("/usr/lib");

    // Add the SDK as a sysroot. Using this instead of, say, absolute framework/include/lib paths
    // to the SDK without a sysroot ensures that we use the same libraries/frameworks/headers on
    // Mac hosts and non-Mac hosts.
    const sdk_root_dir = getSdkRoot(b.allocator, "sdk-macos-11.3") catch unreachable;
    defer b.allocator.free(sdk_root_dir);
    var sdk_sysroot = std.fs.path.join(b.allocator, &.{ sdk_root_dir, "root/" }) catch unreachable;
    b.sysroot = sdk_sysroot;
}

fn includeSdkLinuxX8664(b: *Builder, step: *std.build.LibExeObjStep) void {
    const sdk_root_dir = getSdkRoot(b.allocator, "sdk-linux-x86_64") catch unreachable;
    defer b.allocator.free(sdk_root_dir);

    var sdk_root_includes = std.fs.path.join(b.allocator, &.{ sdk_root_dir, "root/usr/include" }) catch unreachable;
    defer b.allocator.free(sdk_root_includes);
    step.addSystemIncludeDir(sdk_root_includes);

    var sdk_root_libs = std.fs.path.join(b.allocator, &.{ sdk_root_dir, "root/usr/lib/x86_64-linux-gnu" }) catch unreachable;
    defer b.allocator.free(sdk_root_libs);
    step.addLibPath(sdk_root_libs);
}

/// Caller owns returned memory.
fn getSdkRoot(allocator: *std.mem.Allocator, comptime name: []const u8) ![]const u8 {
    // Find the directory where the SDK should be located. We'll consider two locations:
    //
    // 1. $SDK_PATH/<name> (if set, e.g. for testing changes to SDKs easily)
    // 2. <appdata>/<name> (default)
    //
    // Where `<name>` is the name of the SDK, e.g. `sdk-macos-11.3`.
    var sdk_root_dir: []const u8 = undefined;
    var sdk_path_dir: []const u8 = undefined;
    defer allocator.free(sdk_path_dir);
    if (std.process.getEnvVarOwned(allocator, "SDK_PATH")) |sdk_path| {
        sdk_path_dir = sdk_path;
        sdk_root_dir = try std.fs.path.join(allocator, &.{ sdk_path, name });
    } else |err| switch (err) {
        error.EnvironmentVariableNotFound => {
            sdk_path_dir = try std.fs.getAppDataDir(allocator, "mach");
            sdk_root_dir = try std.fs.path.join(allocator, &.{ sdk_path_dir, name });
        },
        else => |e| return e,
    }

    // If the SDK exists, return it. Otherwise, clone it.
    if (std.fs.openDirAbsolute(sdk_root_dir, .{})) {
        return sdk_root_dir;
    } else |err| return switch (err) {
        error.FileNotFound => {
            std.log.info("cloning required sdk..\ngit clone https://github.com/hexops/{s} '{s}'..\n", .{ name, sdk_root_dir });
            if (std.mem.eql(u8, name, "sdk-macos-11.3")) {
                if (!try confirmAppleSDKAgreement(allocator)) @panic("cannot continue");
            }
            try std.fs.cwd().makePath(sdk_path_dir);
            const argv = &[_][]const u8{ "git", "clone", "https://github.com/hexops/" ++ name };
            const child = try std.ChildProcess.init(argv, allocator);
            child.cwd = sdk_path_dir;
            child.stdin = std.io.getStdOut();
            child.stderr = std.io.getStdErr();
            child.stdout = std.io.getStdOut();
            try child.spawn();
            _ = try child.wait();
            return sdk_root_dir;
        },
        else => err,
    };
}

fn confirmAppleSDKAgreement(allocator: *std.mem.Allocator) !bool {
    if (std.process.getEnvVarOwned(allocator, "AGREE")) |agree| {
        defer allocator.free(agree);
        return std.mem.eql(u8, agree, "true");
    } else |err| switch (err) {
        error.EnvironmentVariableNotFound => {},
        else => |e| return e,
    }

    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();
    var buf: [10]u8 = undefined;
    try stdout.print("This SDK is distributed under the terms of the Xcode and Apple SDKs agreement:\n", .{});
    try stdout.print("  https://www.apple.com/legal/sla/docs/xcode.pdf\n", .{});
    try stdout.print("\n", .{});
    try stdout.print("Do you agree to those terms? [Y/n] ", .{});
    if (try stdin.readUntilDelimiterOrEof(buf[0..], '\n')) |user_input| {
        try stdout.print("\n", .{});
        var in = user_input;
        if (in.len > 0 and in[in.len - 1] == '\r') in = in[0 .. in.len - 1];
        return std.mem.eql(u8, in, "y") or std.mem.eql(u8, in, "Y") or std.mem.eql(u8, in, "yes") or std.mem.eql(u8, in, "");
    } else {
        return false;
    }
}
