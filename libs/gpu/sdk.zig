const std = @import("std");
const Builder = std.build.Builder;

pub fn Sdk(comptime deps: anytype) type {
    return struct {
        pub fn testStep(b: *Builder, mode: std.builtin.Mode, target: std.zig.CrossTarget, options: Options) !*std.build.RunStep {
            const main_tests = b.addTestExe("gpu-tests", sdkPath(b, "/src/main.zig"));
            main_tests.setBuildMode(mode);
            main_tests.setTarget(target);
            try link(b, main_tests, options);
            main_tests.install();
            return main_tests.run();
        }

        pub const Options = struct {
            glfw_options: deps.glfw.Options = .{},
            gpu_dawn_options: deps.gpu_dawn.Options = .{},
        };

        var cached_pkg: ?std.build.Pkg = null;

        pub fn pkg(b: *Builder) std.build.Pkg {
            if (cached_pkg == null) {
                const dependencies = b.allocator.create([1]std.build.Pkg) catch unreachable;
                dependencies.* = .{
                    deps.glfw.pkg(b),
                };

                cached_pkg = .{
                    .name = "gpu",
                    .source = .{ .path = sdkPath(b, "/src/main.zig") },
                    .dependencies = dependencies,
                };
            }

            return cached_pkg.?;
        }

        pub fn link(b: *std.build.Builder, step: *std.build.LibExeObjStep, options: Options) !void {
            if (step.target.toTarget().cpu.arch != .wasm32) {
                try deps.glfw.link(b, step, options.glfw_options);
                try deps.gpu_dawn.link(b, step, options.gpu_dawn_options);
                step.addCSourceFile(sdkPath(b, "/src/mach_dawn.cpp"), &.{"-std=c++17"});
                step.addIncludePath(sdkPath(b, "/src"));
            }
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
