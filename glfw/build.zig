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
    Vulkan: bool = true,
    Metal: bool = true,
    OpenGL: bool = false,
    GLES: bool = false,
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
                "upstream/glfw/src/init.c",
                "upstream/glfw/src/vulkan.c",
                "upstream/glfw/src/input.c",
                "upstream/glfw/src/osmesa_context.c",
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
            const sdk_root_dir = getSdkRoot(b.allocator, "sdk-macos-11.3") catch unreachable;
            defer b.allocator.free(sdk_root_dir);

            var sdk_root_frameworks = std.fs.path.join(b.allocator, &.{ sdk_root_dir, "root/System/Library/Frameworks" }) catch unreachable;
            defer b.allocator.free(sdk_root_frameworks);
            step.addFrameworkDir(sdk_root_frameworks);

            var sdk_root_includes = std.fs.path.join(b.allocator, &.{ sdk_root_dir, "root/usr/include" }) catch unreachable;
            defer b.allocator.free(sdk_root_includes);
            step.addSystemIncludeDir(sdk_root_includes);

            step.linkFramework("Cocoa");
            step.linkFramework("IOKit");
            step.linkFramework("CoreFoundation");
            if (options.OpenGL) {
                step.linkFramework("OpenGL");
            }
        },
        else => {
            // Assume Linux-like
        },
    }
}

// Caller owns returned memory.
fn getSdkRoot(allocator: *std.mem.Allocator, comptime name: []const u8) ![]const u8 {
    const app_data_dir = try std.fs.getAppDataDir(allocator, "mach");
    var sdk_root_dir = try std.fs.path.join(allocator, &.{ app_data_dir, name });
    if (std.fs.openDirAbsolute(sdk_root_dir, .{})) {
        return sdk_root_dir;
    } else |err| return switch (err) {
        error.FileNotFound => {
            std.log.info("cloning required sdk..\ngit clone https://github.com/hexops/{s} '{s}'..\n", .{ name, sdk_root_dir });
            if (std.mem.eql(u8, name, "sdk-macos-11.3")) {
                if (!try confirmAppleSDKAgreement()) @panic("cannot continue");
            }
            try std.fs.cwd().makePath(app_data_dir);
            const argv = &[_][]const u8{ "git", "clone", "https://github.com/hexops/" ++ name };
            const child = try std.ChildProcess.init(argv, allocator);
            child.cwd = app_data_dir;
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

fn confirmAppleSDKAgreement() !bool {
    if (std.mem.eql(u8, std.os.getenv("AGREE") orelse "", "true")) return true;
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();
    var buf: [10]u8 = undefined;
    try stdout.print("This SDK is distributed under the terms of the Xcode and Apple SDKs agreement:\n", .{});
    try stdout.print("  https://www.apple.com/legal/sla/docs/xcode.pdf\n", .{});
    try stdout.print("\n", .{});
    try stdout.print("Do you agree to those terms? [Y/n] ", .{});
    if (try stdin.readUntilDelimiterOrEof(buf[0..], '\n')) |user_input| {
        try stdout.print("\n", .{});
        return std.mem.eql(u8, user_input, "y") or std.mem.eql(u8, user_input, "Y") or std.mem.eql(u8, user_input, "yes") or std.mem.eql(u8, user_input, "");
    } else {
        return false;
    }
}
