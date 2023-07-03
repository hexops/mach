const std = @import("std");

pub fn Sdk(comptime deps: anytype) type {
    return struct {
        pub const Options = struct {
            install_libs: bool = false,
        };

        var _module: ?*std.build.Module = null;

        pub fn module(b: *std.Build, optimize: std.builtin.OptimizeMode, target: std.zig.CrossTarget) *std.build.Module {
            if (_module) |m| return m;

            if (target.getCpuArch() == .wasm32) {
                const sysjs_dep = b.dependency("mach_sysjs", .{
                    .target = target,
                    .optimize = optimize,
                });
                _module = b.createModule(.{
                    .source_file = .{ .path = sdkPath("/src/main.zig") },
                    .dependencies = &.{
                        .{ .name = "sysjs", .module = sysjs_dep.module("mach-sysjs") },
                    },
                });
            } else {
                _module = b.createModule(.{
                    .source_file = .{ .path = sdkPath("/src/main.zig") },
                });
            }
            return _module.?;
        }

        pub fn testStep(b: *std.Build, optimize: std.builtin.OptimizeMode, target: std.zig.CrossTarget) *std.build.RunStep {
            const main_tests = b.addTest(.{
                .name = "sysaudio-tests",
                .root_source_file = .{ .path = sdkPath("/src/main.zig") },
                .target = target,
                .optimize = optimize,
            });
            link(b, main_tests, .{});
            b.installArtifact(main_tests);
            return b.addRunArtifact(main_tests);
        }

        pub fn link(b: *std.Build, step: *std.build.CompileStep, options: Options) void {
            if (step.target.toTarget().cpu.arch != .wasm32) {
                if (step.target.toTarget().isDarwin()) {
                    // TODO(build-system): This cannot be imported with the Zig package manager
                    // error: TarUnsupportedFileType
                    //
                    // step.linkLibrary(b.dependency("xcode_frameworks", .{
                    //     .target = step.target,
                    //     .optimize = step.optimize,
                    // }).artifact("xcode-frameworks"));
                    // @import("xcode_frameworks").addPaths(step);
                    deps.xcode_frameworks.addPaths(step);

                    step.linkFramework("AudioToolbox");
                    step.linkFramework("CoreFoundation");
                    step.linkFramework("CoreAudio");
                } else if (step.target.toTarget().os.tag == .linux) {
                    step.linkLibrary(b.dependency("linux_audio_headers", .{
                        .target = step.target,
                        .optimize = step.optimize,
                    }).artifact("linux-audio-headers"));
                    step.addCSourceFile(sdkPath("/src/pipewire/sysaudio.c"), &.{"-std=gnu99"});
                    step.linkLibC();
                }
            }
            if (options.install_libs) {
                b.installArtifact(step);
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
    };
}
