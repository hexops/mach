//! Mach system SDK inclusion
//!
//! This file contains all that you need to include the Mach system SDKs in your own build.zig,
//! allowing you to cross-compile most OpenGL/Vulkan applications with ease.
//!
//! The SDKs used by this script by default are:
//!
//! * Windows: https://github.com/hexops/sdk-windows-x86_64 (~7MB, updated DirectX headers for Zig/MinGW)
//! * Linux: https://github.com/hexops/sdk-linux-x86_64 (~40MB, X11, Wayland, etc. development libraries)
//! * MacOS (most frameworks you'd find in the XCode SDK):
//!     * https://github.com/hexops/sdk-macos-11.3 (~160MB)
//!     * https://github.com/hexops/sdk-macos-12.0 (~112MB)
//!     * https://github.com/hexops/sdk-macos-13.3 (~160MB)
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
//! version: Mar 4, 2022

const std = @import("std");
const Build = std.Build;

pub const Options = struct {
    pub const Sdk = struct {
        is_default: bool = false,
        name: []const u8,
        git_addr: []const u8,
        git_revision: []const u8,
        cpu_arch: []const std.Target.Cpu.Arch,
        os_tag: std.Target.Os.Tag,
        os_version: std.Target.Os.TaggedVersionRange,
    };

    sdk_list: []const Sdk = &.{
        .{
            .name = "sdk-macos-13.3",
            .git_addr = "https://github.com/hexops/sdk-macos-13.3",
            .git_revision = "1615cd09b3a42ae590e05e63251a0e9fbc47bab5",
            .cpu_arch = &.{ .aarch64, .x86_64 },
            .os_tag = .macos,
            .os_version = .{
                .semver = .{
                    .min = .{ .major = 13, .minor = 0, .patch = 0 },
                    .max = .{ .major = 14, .minor = std.math.maxInt(u32), .patch = std.math.maxInt(u32) },
                },
            },
        },
        .{
            .is_default = true,
            .name = "sdk-macos-12.0",
            .git_addr = "https://github.com/hexops/sdk-macos-12.0",
            .git_revision = "14613b4917c7059dad8f3789f55bb13a2548f83d",
            .cpu_arch = &.{ .aarch64, .x86_64 },
            .os_tag = .macos,
            .os_version = .{
                .semver = .{
                    // Note: we force 11.0 compatibility here, in practice it works and the 11.3 SDK
                    // is missing AudioToolbox
                    .min = .{ .major = 11, .minor = 0, .patch = 0 },
                    .max = .{ .major = 12, .minor = std.math.maxInt(u32), .patch = std.math.maxInt(u32) },
                },
            },
        },
        // .{
        //     .name = "sdk-macos-11.3",
        //     .git_addr = "https://github.com/hexops/sdk-macos-11.3",
        //     .git_revision = "ccbaae84cc39469a6792108b24480a4806e09d59",
        //     .cpu_arch = &.{ .aarch64, .x86_64 },
        //     .os_tag = .macos,
        //     .os_version = .{
        //         .semver = .{
        //             .min = .{ .major = 11, .minor = 0, .patch = 0 },
        //             .max = .{ .major = 11, .minor = std.math.maxInt(u32), .patch = std.math.maxInt(u32) },
        //         },
        //     },
        // },
        .{
            .is_default = true,
            .name = "sdk-linux-x86_64",
            .git_addr = "https://github.com/hexops/sdk-linux-x86_64",
            .git_revision = "311a0f18a2350c032a40b5917ae25c05cf500683s",
            .cpu_arch = &.{.x86_64},
            .os_tag = .linux,
            .os_version = .{
                .linux = .{
                    .range = .{
                        .min = .{ .major = 3, .minor = 16, .patch = 0 },
                        .max = .{ .major = 6, .minor = std.math.maxInt(u32), .patch = std.math.maxInt(u32) },
                    },
                    .glibc = .{ .major = 0, .minor = 0, .patch = std.math.maxInt(u32) },
                },
            },
        },
        .{
            .is_default = true,
            .name = "sdk-linux-aarch64",
            .git_addr = "https://github.com/hexops/sdk-linux-aarch64",
            .git_revision = "cefd56ea2e97623d308e1897491a322fdca23d97",
            .cpu_arch = &.{.aarch64},
            .os_tag = .linux,
            .os_version = .{
                .linux = .{
                    .range = .{
                        .min = .{ .major = 3, .minor = 16, .patch = std.math.maxInt(u32) },
                        .max = .{ .major = 6, .minor = std.math.maxInt(u32), .patch = std.math.maxInt(u32) },
                    },
                    .glibc = .{ .major = 0, .minor = 0, .patch = std.math.maxInt(u32) },
                },
            },
        },
        .{
            .is_default = true,
            .name = "sdk-windows-x86_64",
            .git_addr = "https://github.com/hexops/sdk-windows-x86_64",
            .git_revision = "13dcda7fe3f1aec0fc6130527226ad7ae0f4b792",
            .cpu_arch = &.{.x86_64},
            .os_tag = .windows,
            .os_version = .{
                .windows = .{
                    .min = .win7,
                    .max = std.Target.Os.WindowsVersion.latest,
                },
            },
        },
    },

    /// If true, the Builder.sysroot will set to the SDK path. This has the drawback of preventing
    /// you from including headers, libraries, etc. from outside the SDK generally. However, it can
    /// be useful in order to identify which libraries, headers, frameworks, etc. may be missing in
    /// your SDK for cross compilation.
    set_sysroot: bool = false,
};

pub fn include(b: *Build, step: *std.build.CompileStep, options: Options) void {
    const target = step.target_info.target;
    var best_sdk: ?Options.Sdk = null;

    // Try to find an SDK that matches our minimum target version
    for (options.sdk_list) |sdk| {
        if (!std.mem.containsAtLeast(std.Target.Cpu.Arch, sdk.cpu_arch, 1, &.{target.cpu.arch}))
            continue;
        if (sdk.os_tag != target.os.tag) continue;

        const version_ok = switch (sdk.os_version) {
            .semver => |vr| vr.includesVersion(target.os.version_range.semver.min),
            .linux => |vr| vr.includesVersion(target.os.version_range.linux.range.min),
            .windows => |vr| vr.includesVersion(target.os.version_range.windows.min),
            .none => false,
        };
        if (!version_ok) continue;

        best_sdk = sdk;
    }

    if (best_sdk == null) {
        // We found no SDK matching our minimum target version, select the default one matching our os+arch then
        for (options.sdk_list) |sdk| {
            if (!std.mem.containsAtLeast(std.Target.Cpu.Arch, sdk.cpu_arch, 1, &.{target.cpu.arch}))
                continue;
            if (sdk.os_tag != target.os.tag) continue;

            if (sdk.is_default) best_sdk = sdk;
        }
    }

    const sdk_root_dir = getSdkRoot(b.allocator, best_sdk.?) catch unreachable;
    if (options.set_sysroot) {
        // We have no sysroot for Windows, but we still set one to prevent inclusion of other system
        // libs (if set_sysroot is set, don't want to accidentally depend on system libs.)
        b.sysroot = sdk_root_dir;
    }
    return switch (target.os.tag) {
        .windows => {
            const sdk_includes = std.fs.path.join(b.allocator, &.{ sdk_root_dir, "include" }) catch unreachable;
            const sdk_libs = std.fs.path.join(b.allocator, &.{ sdk_root_dir, "lib" }) catch unreachable;
            defer {
                b.allocator.free(sdk_includes);
                b.allocator.free(sdk_libs);
            }
            step.addIncludePath(sdk_includes);
            step.addLibraryPath(sdk_libs);
        },
        .macos => {
            if (options.set_sysroot) {
                step.addFrameworkPath("/System/Library/Frameworks");
                step.addSystemIncludePath("/usr/include");
                step.addLibraryPath("/usr/lib");
                return;
            }

            const sdk_framework_dir = std.fs.path.join(b.allocator, &.{ sdk_root_dir, "root/System/Library/Frameworks" }) catch unreachable;
            const sdk_include_dir = std.fs.path.join(b.allocator, &.{ sdk_root_dir, "root/usr/include" }) catch unreachable;
            const sdk_lib_dir = std.fs.path.join(b.allocator, &.{ sdk_root_dir, "root/usr/lib" }) catch unreachable;
            defer {
                b.allocator.free(sdk_framework_dir);
                b.allocator.free(sdk_include_dir);
                b.allocator.free(sdk_lib_dir);
            }
            step.addFrameworkPath(sdk_framework_dir);
            step.addSystemIncludePath(sdk_include_dir);
            step.addLibraryPath(sdk_lib_dir);
        },
        .linux => {
            if (options.set_sysroot) return;

            const sdk_root_includes = std.fs.path.join(b.allocator, &.{ sdk_root_dir, "root/usr/include" }) catch unreachable;
            const wayland_protocols_include = std.fs.path.join(b.allocator, &.{ sdk_root_dir, "root/usr/share/wayland-generated" }) catch unreachable;
            const sdk_root_libs = switch (target.cpu.arch) {
                .x86_64 => std.fs.path.join(b.allocator, &.{ sdk_root_dir, "root/usr/lib/x86_64-linux-gnu" }) catch unreachable,
                .aarch64 => std.fs.path.join(b.allocator, &.{ sdk_root_dir, "root/usr/lib/aarch64-linux-gnu" }) catch unreachable,
                else => unreachable,
            };
            defer {
                b.allocator.free(sdk_root_includes);
                b.allocator.free(wayland_protocols_include);
                b.allocator.free(sdk_root_libs);
            }
            step.addSystemIncludePath(sdk_root_includes);
            step.addSystemIncludePath(wayland_protocols_include);
            step.addLibraryPath(sdk_root_libs);
        },
        else => unreachable,
    };
}

var cached_sdk_roots: ?std.AutoHashMap(*const Options.Sdk, []const u8) = null;

/// returns the SDK root path, determining it iff necessary. In a real application, this may be
/// tens or hundreds of times and so the result is cached in-memory (this also means the result
/// cannot be freed until the result will never be used again, which is fine as the Zig build system
/// Builder.allocator is an arena, you don't need to free.)
fn getSdkRoot(allocator: std.mem.Allocator, sdk: Options.Sdk) ![]const u8 {
    if (cached_sdk_roots == null)
        cached_sdk_roots = std.AutoHashMap(*const Options.Sdk, []const u8).init(allocator);

    var entry = try cached_sdk_roots.?.getOrPut(&sdk);
    if (entry.found_existing) return entry.value_ptr.*;
    const sdk_root = try determineSdkRoot(allocator, sdk);
    entry.value_ptr.* = sdk_root;
    return sdk_root;
}

fn determineSdkRoot(allocator: std.mem.Allocator, sdk: Options.Sdk) ![]const u8 {
    // Find the directory where the SDK should be located. We'll consider two locations:
    //
    // 1. $SDK_PATH/<name> (if set, e.g. for testing changes to SDKs easily)
    // 2. <appdata>/<name> (default)
    //
    // Where `<name>` is the name of the SDK, e.g. `sdk-macos-12.0`.
    var sdk_root_dir: []const u8 = undefined;
    var sdk_path_dir: []const u8 = undefined;
    var custom_sdk_path = false;
    if (std.process.getEnvVarOwned(allocator, "MACH_SDK_PATH")) |sdk_path| {
        custom_sdk_path = true;
        sdk_path_dir = sdk_path;
        sdk_root_dir = try std.fs.path.join(allocator, &.{ sdk_path, sdk.name });
    } else |err| switch (err) {
        error.EnvironmentVariableNotFound => {
            sdk_path_dir = try std.fs.getAppDataDir(allocator, "mach");
            sdk_root_dir = try std.fs.path.join(allocator, &.{ sdk_path_dir, sdk.name });
        },
        else => |e| return e,
    }

    ensureGit(allocator);

    // If the SDK exists, return it. Otherwise, clone it.
    if (std.fs.openDirAbsolute(sdk_root_dir, .{})) |_| {
        const current_revision = try getCurrentGitRevision(allocator, sdk_root_dir);
        if (!std.mem.eql(u8, current_revision, sdk.git_revision)) {
            // Update the SDK to the target revision. This may be either forward or backwards in
            // history (e.g. if building an old project) and so we use a hard reset.
            //
            // No reset is performed if specifying a custom SDK_PATH, as that is a development/debug
            // option and could wipe out dev history.
            exec(allocator, &[_][]const u8{ "git", "fetch" }, sdk_root_dir) catch |err| std.debug.print("warning: failed to check for updates to {s}: {s}\n", .{ sdk.name, @errorName(err) });
            if (!custom_sdk_path)
                try exec(allocator, &[_][]const u8{ "git", "reset", "--quiet", "--hard", sdk.git_revision }, sdk_root_dir);
        }
        return sdk_root_dir;
    } else |err| return switch (err) {
        error.FileNotFound => {
            std.log.info("cloning required sdk..\ngit clone {s} '{s}'..\n", .{ sdk.git_addr, sdk_root_dir });
            switch (sdk.os_tag) {
                .macos, .ios, .watchos, .tvos => {
                    if (!try confirmAppleSDKAgreement(allocator)) @panic("cannot continue");
                },
                else => {},
            }
            try std.fs.cwd().makePath(sdk_path_dir);

            try exec(allocator, &[_][]const u8{ "git", "clone", "-c", "core.longpaths=true", sdk.git_addr }, sdk_path_dir);
            return sdk_root_dir;
        },
        else => err,
    };
}

fn exec(allocator: std.mem.Allocator, argv: []const []const u8, cwd: []const u8) !void {
    var child = std.ChildProcess.init(argv, allocator);
    child.cwd = cwd;
    _ = try child.spawnAndWait();
}

fn getCurrentGitRevision(allocator: std.mem.Allocator, cwd: []const u8) ![]const u8 {
    const result = try std.ChildProcess.exec(.{ .allocator = allocator, .argv = &.{ "git", "rev-parse", "HEAD" }, .cwd = cwd });
    allocator.free(result.stderr);
    if (result.stdout.len > 0) return result.stdout[0 .. result.stdout.len - 1]; // trim newline
    return result.stdout;
}

fn confirmAppleSDKAgreement(allocator: std.mem.Allocator) !bool {
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

fn ensureGit(allocator: std.mem.Allocator) void {
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
