const std = @import("std");
const sysjs = @import("libs/mach-sysjs/build.zig");

pub fn Sdk(comptime deps: anytype) type {
    return struct {
        const soundio_path = thisDir() ++ "/upstream/soundio";

        pub const pkg = std.build.Pkg{
            .name = "sysaudio",
            .source = .{ .path = thisDir() ++ "/src/main.zig" },
            .dependencies = &.{ sysjs.pkg, soundio_pkg },
        };

        pub const soundio_pkg = std.build.Pkg{
            .name = "soundio",
            .source = .{ .path = thisDir() ++ "/soundio/main.zig" },
        };

        pub const Options = struct {
            install_libs: bool = false,
        };

        pub fn testStep(b: *std.build.Builder, mode: std.builtin.Mode, target: std.zig.CrossTarget) *std.build.RunStep {
            const soundio_tests = b.addTestExe("soundio-tests", (comptime thisDir()) ++ "/soundio/main.zig");
            soundio_tests.setBuildMode(mode);
            soundio_tests.setTarget(target);
            link(b, soundio_tests, .{});
            soundio_tests.install();

            const main_tests = b.addTestExe("sysaudio-tests", (comptime thisDir()) ++ "/src/main.zig");
            main_tests.setBuildMode(mode);
            main_tests.setTarget(target);
            main_tests.addPackage(soundio_pkg);
            link(b, main_tests, .{});
            main_tests.install();

            const main_tests_run = main_tests.run();
            main_tests_run.step.dependOn(&soundio_tests.run().step);
            return main_tests_run;
        }

        pub fn link(b: *std.build.Builder, step: *std.build.LibExeObjStep, options: Options) void {
            if (step.target.toTarget().cpu.arch != .wasm32) {
                // TODO(build-system): pass system SDK options through
                const soundio_lib = buildSoundIo(b, step.build_mode, step.target, options);
                step.linkLibrary(soundio_lib);
                step.addIncludePath(soundio_path);
                deps.system_sdk.include(b, step, .{});
            }
        }

        fn buildSoundIo(b: *std.build.Builder, mode: std.builtin.Mode, target: std.zig.CrossTarget, options: Options) *std.build.LibExeObjStep {
            // TODO(build-system): https://github.com/hexops/mach/issues/229#issuecomment-1100958939
            ensureDependencySubmodule(b.allocator, "upstream") catch unreachable;

            const config_base =
                \\#ifndef SOUNDIO_CONFIG_H
                \\#define SOUNDIO_CONFIG_H
                \\#define SOUNDIO_VERSION_MAJOR 2
                \\#define SOUNDIO_VERSION_MINOR 0
                \\#define SOUNDIO_VERSION_PATCH 0
                \\#define SOUNDIO_VERSION_STRING "2.0.0"
                \\
            ;

            var config_file = std.fs.cwd().createFile(soundio_path ++ "/src/config.h", .{}) catch unreachable;
            defer config_file.close();
            config_file.writeAll(config_base) catch unreachable;

            const lib = b.addStaticLibrary("soundio", null);
            lib.setBuildMode(mode);
            lib.setTarget(target);
            lib.linkLibC();
            lib.addIncludePath(soundio_path);
            lib.addCSourceFiles(soundio_sources, &.{});
            deps.system_sdk.include(b, lib, .{});

            const target_info = (std.zig.system.NativeTargetInfo.detect(target) catch unreachable).target;
            if (target_info.isDarwin()) {
                lib.addCSourceFile(soundio_path ++ "/src/coreaudio.c", &.{});
                lib.linkFramework("AudioToolbox");
                lib.linkFramework("CoreFoundation");
                lib.linkFramework("CoreAudio");
                config_file.writeAll("#define SOUNDIO_HAVE_COREAUDIO\n") catch unreachable;
            } else if (target_info.os.tag == .linux) {
                lib.addCSourceFile(soundio_path ++ "/src/alsa.c", &.{});
                lib.linkSystemLibrary("asound");
                config_file.writeAll("#define SOUNDIO_HAVE_ALSA\n") catch unreachable;
            } else if (target_info.os.tag == .windows) {
                lib.addCSourceFile(soundio_path ++ "/src/wasapi.c", &.{});
                lib.linkSystemLibrary("ole32");
                config_file.writeAll("#define SOUNDIO_HAVE_WASAPI\n") catch unreachable;
            }

            config_file.writeAll("#endif\n") catch unreachable;

            if (options.install_libs)
                lib.install();
            return lib;
        }

        fn ensureDependencySubmodule(allocator: std.mem.Allocator, path: []const u8) !void {
            if (std.process.getEnvVarOwned(allocator, "NO_ENSURE_SUBMODULES")) |no_ensure_submodules| {
                defer allocator.free(no_ensure_submodules);
                if (std.mem.eql(u8, no_ensure_submodules, "true")) return;
            } else |_| {}
            var child = std.ChildProcess.init(&.{ "git", "submodule", "update", "--init", path }, allocator);
            child.cwd = (comptime thisDir());
            child.stderr = std.io.getStdErr();
            child.stdout = std.io.getStdOut();

            _ = try child.spawnAndWait();
        }

        fn thisDir() []const u8 {
            return std.fs.path.dirname(@src().file) orelse ".";
        }

        const soundio_sources = &[_][]const u8{
            soundio_path ++ "/src/soundio.c",
            soundio_path ++ "/src/util.c",
            soundio_path ++ "/src/os.c",
            soundio_path ++ "/src/dummy.c",
            soundio_path ++ "/src/channel_layout.c",
            soundio_path ++ "/src/ring_buffer.c",
        };
    };
}
