const std = @import("std");
const Builder = std.build.Builder;

pub fn Sdk(comptime deps: anytype) type {
    return struct {
        var cached_pkg: ?std.build.Pkg = null;

        pub fn pkg(b: *Builder) std.build.Pkg {
            if (cached_pkg == null) {
                const dependencies = b.allocator.create([1]std.build.Pkg) catch unreachable;
                dependencies.* = .{
                    deps.sysjs.pkg(b),
                };

                cached_pkg = .{
                    .name = "sysaudio",
                    .source = .{ .path = sdkPath(b, "/src/main.zig") },
                    .dependencies = dependencies,
                };
            }

            return cached_pkg.?;
        }

        pub const Options = struct {
            install_libs: bool = false,

            /// System SDK options.
            system_sdk: deps.system_sdk.Options = .{},
        };

        pub fn testStep(b: *Builder, mode: std.builtin.Mode, target: std.zig.CrossTarget) *std.build.RunStep {
            const main_tests = b.addTestExe("sysaudio-tests", sdkPath(b, "/src/main.zig"));
            main_tests.setBuildMode(mode);
            main_tests.setTarget(target);
            link(b, main_tests, .{});
            main_tests.install();
            return main_tests.run();
        }

        pub fn link(b: *Builder, step: *std.build.LibExeObjStep, options: Options) void {
            if (step.target.toTarget().cpu.arch != .wasm32) {
                // TODO(build-system): pass system SDK options through
                deps.system_sdk.include(b, step, .{});
                if (step.target.toTarget().isDarwin()) {
                    step.linkFramework("AudioToolbox");
                    step.linkFramework("CoreFoundation");
                    step.linkFramework("CoreAudio");
                } else if (step.target.toTarget().os.tag == .linux) {
                    step.linkSystemLibrary("asound");
                    step.linkSystemLibrary("pulse");
                    step.linkSystemLibrary("jack");
                    step.linkLibC();
                }
            }
            if (options.install_libs) {
                step.install();
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

        var this_dir: ?[]const u8 = null;

        fn thisDir(allocator: std.mem.Allocator) []const u8 {
            if (this_dir == null) {
                const unresolved_dir = comptime std.fs.path.dirname(@src().file) orelse ".";

                if (comptime unresolved_dir[0] == '/') {
                    this_dir = unresolved_dir;
                } else {
                    this_dir = std.fs.cwd().realpathAlloc(allocator, unresolved_dir) catch unreachable;
                }
            }

            return this_dir.?;
        }

        fn sdkPath(b: *Builder, comptime suffix: []const u8) []const u8 {
            return sdkPathAllocator(b.allocator, suffix);
        }

        fn sdkPathAllocator(allocator: std.mem.Allocator, comptime suffix: []const u8) []const u8 {
            if (suffix[0] != '/') @compileError("suffix must be an absolute path");

            return std.fs.path.resolve(allocator, &.{ thisDir(allocator), suffix[1..] }) catch unreachable;
        }
    };
}
