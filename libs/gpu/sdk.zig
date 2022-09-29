const std = @import("std");

pub fn Sdk(comptime deps: anytype) type {
    return struct {
        pub fn testStep(b: *std.build.Builder, mode: std.builtin.Mode, target: std.zig.CrossTarget, options: Options) !*std.build.RunStep {
            const main_tests = b.addTestExe("gpu-tests", sdkPath("/src/main.zig"));
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

        pub const pkg = std.build.Pkg{
            .name = "gpu",
            .source = .{ .path = sdkPath("/src/main.zig") },
            .dependencies = &.{deps.glfw.pkg},
        };

        pub fn link(b: *std.build.Builder, step: *std.build.LibExeObjStep, options: Options) !void {
            if (step.target.toTarget().cpu.arch != .wasm32) {
                try deps.glfw.link(b, step, options.glfw_options);
                try deps.gpu_dawn.link(b, step, options.gpu_dawn_options);
                step.addCSourceFile(sdkPath("/src/mach_dawn.cpp"), &.{"-std=c++17"});
                step.addIncludePath(sdkPath("/src"));
            }
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
