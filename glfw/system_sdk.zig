//! Mach system SDK inclusion
//!
//! This file contains all that you need to include the Mach system SDKs in your own build.zig,
//! allowing you to cross-compile most OpenGL/Vulkan applications with ease.
//!
//! The SDKs used by this script by default are:
//!
//! * Linux: https://github.com/hexops/sdk-linux-x86_64 (~40MB, X11, Wayland, etc. development libraries)
//! * MacOS: https://github.com/hexops/sdk-macos-11.3 (~160MB, most frameworks you'd find in the XCode SDK)
//! * Windows: not needed
//!
//! You may supply your own SDKs via the Options struct if needed, although the Mach versions above
//! will generally work for most OpenGL/Vulkan applications.
//!
//! How it works: When `include` is called, the compilation target is detected. If it does not
//! already exist, the SDK repository for the target platform is cloned via `git clone`. If the
//! target is MacOS, an interactive license agreement prompt (agreeing to the XCode SDK terms)
//! will appear. You can also set the environment variable `AGREE=true` to dismiss this.
//!
//! Once downloaded, `include` will add the SDK library, header, etc. directions to the build step
//! so that you can just include and link against libraries/frameworks as if they were there, and
//! you may then cross-compile your code with ease. See https://github.com/hexops/mach-glfw for an
//! example.
//!
//! Best way to get this file in your own repository? We suggest just copying it, or importing it
//! from a project that includes it if you're using one (e.g. mach-glfw)
//!
//! version: 1.0

const std = @import("std");
const Builder = std.build.Builder;

pub const Options = struct {
    /// The github org to find repositories in.
    github_org: []const u8 = "hexops",

    /// The MacOS SDK repository name.
    macos_sdk: []const u8 = "sdk-macos-11.3",

    /// The Linux x86-64 SDK repository name.
    linux_x86_64_sdk: []const u8 = "sdk-linux-x86_64",

    /// If true, the Builder.sysroot will set to the SDK path. This has the drawback of preventing
    /// you from including headers, libraries, etc. from outside the SDK generally. However, it can
    /// be useful in order to identify which libraries, headers, frameworks, etc. may be missing in
    /// your SDK for cross compilation.
    set_sysroot: bool = false,
};

pub fn include(b: *Builder, step: *std.build.LibExeObjStep, options: Options) void {
    const target = (std.zig.system.NativeTargetInfo.detect(b.allocator, step.target) catch unreachable).target;
    switch (target.os.tag) {
        .windows => {},
        .macos => includeSdkMacOS(b, step, options),
        else => includeSdkLinuxX8664(b, step, options), // Assume Linux-like for now
    }
}

fn includeSdkMacOS(b: *Builder, step: *std.build.LibExeObjStep, options: Options) void {
    const sdk_root_dir = getSdkRoot(b.allocator, options.github_org, options.macos_sdk) catch unreachable;

    if (options.set_sysroot) {
        step.addFrameworkDir("/System/Library/Frameworks");
        step.addSystemIncludeDir("/usr/include");
        step.addLibPath("/usr/lib");

        var sdk_sysroot = std.fs.path.join(b.allocator, &.{ sdk_root_dir, "root/" }) catch unreachable;
        b.sysroot = sdk_sysroot;
        return;
    }

    var sdk_framework_dir = std.fs.path.join(b.allocator, &.{ sdk_root_dir, "root/System/Library/Frameworks" }) catch unreachable;
    step.addFrameworkDir(sdk_framework_dir);

    var sdk_include_dir = std.fs.path.join(b.allocator, &.{ sdk_root_dir, "root/usr/include" }) catch unreachable;
    step.addSystemIncludeDir(sdk_include_dir);

    var sdk_lib_dir = std.fs.path.join(b.allocator, &.{ sdk_root_dir, "root/usr/lib" }) catch unreachable;
    step.addLibPath(sdk_lib_dir);
}

fn includeSdkLinuxX8664(b: *Builder, step: *std.build.LibExeObjStep, options: Options) void {
    const sdk_root_dir = getSdkRoot(b.allocator, options.github_org, options.linux_x86_64_sdk) catch unreachable;
    defer b.allocator.free(sdk_root_dir);

    if (options.set_sysroot) {
        var sdk_sysroot = std.fs.path.join(b.allocator, &.{ sdk_root_dir, "root/" }) catch unreachable;
        b.sysroot = sdk_sysroot;
        return;
    }

    var sdk_root_includes = std.fs.path.join(b.allocator, &.{ sdk_root_dir, "root/usr/include" }) catch unreachable;
    defer b.allocator.free(sdk_root_includes);
    step.addSystemIncludeDir(sdk_root_includes);

    var sdk_root_libs = std.fs.path.join(b.allocator, &.{ sdk_root_dir, "root/usr/lib/x86_64-linux-gnu" }) catch unreachable;
    defer b.allocator.free(sdk_root_libs);
    step.addLibPath(sdk_root_libs);
}

fn getSdkRoot(allocator: *std.mem.Allocator, org: []const u8, name: []const u8) ![]const u8 {
    // Find the directory where the SDK should be located. We'll consider two locations:
    //
    // 1. $SDK_PATH/<name> (if set, e.g. for testing changes to SDKs easily)
    // 2. <appdata>/<name> (default)
    //
    // Where `<name>` is the name of the SDK, e.g. `sdk-macos-11.3`.
    var sdk_root_dir: []const u8 = undefined;
    var sdk_path_dir: []const u8 = undefined;
    if (std.process.getEnvVarOwned(allocator, "SDK_PATH")) |sdk_path| {
        sdk_path_dir = sdk_path;
        sdk_root_dir = try std.fs.path.join(allocator, &.{ sdk_path, name });
    } else |err| switch (err) {
        error.EnvironmentVariableNotFound => {
            sdk_path_dir = try std.fs.getAppDataDir(allocator, org);
            sdk_root_dir = try std.fs.path.join(allocator, &.{ sdk_path_dir, name });
        },
        else => |e| return e,
    }

    // If the SDK exists, return it. Otherwise, clone it.
    if (std.fs.openDirAbsolute(sdk_root_dir, .{})) {
        return sdk_root_dir;
    } else |err| return switch (err) {
        error.FileNotFound => {
            std.log.info("cloning required sdk..\ngit clone https://github.com/{s}/{s} '{s}'..\n", .{ org, name, sdk_root_dir });
            if (std.mem.eql(u8, name, "sdk-macos-11.3")) {
                if (!try confirmAppleSDKAgreement(allocator)) @panic("cannot continue");
            }
            try std.fs.cwd().makePath(sdk_path_dir);

            var buf: [1000]u8 = undefined;
            var repo_url_fbs = std.io.fixedBufferStream(&buf);
            try std.fmt.format(repo_url_fbs.writer(), "https://github.com/{s}/{s}", .{org, name});

            const argv = &[_][]const u8{ "git", "clone", repo_url_fbs.getWritten() };
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
