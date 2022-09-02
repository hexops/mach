const std = @import("std");
// const gpu_dawn = @import("libs/mach-gpu-dawn/build.zig");
// const glfw = @import("libs/mach-glfw/build.zig");

pub fn Sdk(comptime deps: anytype) type {
    return struct {
        pub fn testStep(b: *std.build.Builder, mode: std.builtin.Mode, target: std.zig.CrossTarget, options: Options) *std.build.RunStep {
            const main_tests = b.addTestExe("gpu-tests", (comptime thisDir()) ++ "/src/main.zig");
            main_tests.setBuildMode(mode);
            main_tests.setTarget(target);
            link(b, main_tests, options);
            main_tests.install();
            return main_tests.run();
        }

        pub const Options = struct {
            glfw_options: deps.glfw.Options = .{},
            gpu_dawn_options: deps.gpu_dawn.Options = .{},
        };

        pub const pkg = std.build.Pkg{
            .name = "gpu",
            .source = .{ .path = thisDir() ++ "/src/main.zig" },
            .dependencies = &.{deps.glfw.pkg},
        };

        pub fn link(b: *std.build.Builder, step: *std.build.LibExeObjStep, options: Options) void {
            if (step.target.toTarget().cpu.arch != .wasm32) {
                deps.glfw.link(b, step, options.glfw_options);
                deps.gpu_dawn.link(b, step, options.gpu_dawn_options);
                step.addCSourceFile((comptime thisDir()) ++ "/src/mach_dawn.cpp", &.{"-std=c++17"});
                step.addIncludePath((comptime thisDir()) ++ "/src");
            }
        }

        fn thisDir() []const u8 {
            return std.fs.path.dirname(@src().file) orelse ".";
        }
    };
}
