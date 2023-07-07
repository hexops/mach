const std = @import("std");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});
    const glfw = @import("libs/mach-glfw/build.zig").Sdk(.{
        // TODO(build-system): This cannot be imported with the Zig package manager
        // error: TarUnsupportedFileType
        .xcode_frameworks = @import("libs/mach-gpu-dawn/libs/xcode-frameworks/build.zig"),
    });
    const gpu_dawn = @import("libs/mach-gpu-dawn/build.zig").Sdk(.{
        // TODO(build-system): This cannot be imported with the Zig package manager
        // error: TarUnsupportedFileType
        .xcode_frameworks = @import("libs/mach-gpu-dawn/libs/xcode-frameworks/build.zig"),
    });
    const gpu = Sdk(.{
        .gpu_dawn = gpu_dawn,
    });

    const gpu_dawn_options = gpu_dawn.Options{
        .from_source = b.option(bool, "dawn-from-source", "Build Dawn from source") orelse false,
        .debug = b.option(bool, "dawn-debug", "Use a debug build of Dawn") orelse false,
    };

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&(try gpu.testStep(b, optimize, target, .{ .gpu_dawn_options = gpu_dawn_options })).step);

    const example = b.addExecutable(.{
        .name = "gpu-hello-triangle",
        .root_source_file = .{ .path = "examples/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    example.addModule("gpu", gpu.module(b));
    example.addModule("glfw", glfw.module(b));
    try gpu.link(b, example, .{ .gpu_dawn_options = gpu_dawn_options });
    try glfw.link(b, example, .{});
    b.installArtifact(example);

    const example_run_cmd = b.addRunArtifact(example);
    example_run_cmd.step.dependOn(b.getInstallStep());
    const example_run_step = b.step("run-example", "Run the example");
    example_run_step.dependOn(&example_run_cmd.step);
}

pub fn Sdk(comptime deps: anytype) type {
    return struct {
        pub fn testStep(b: *std.Build, optimize: std.builtin.OptimizeMode, target: std.zig.CrossTarget, options: Options) !*std.build.RunStep {
            const main_tests = b.addTest(.{
                .name = "gpu-tests",
                .root_source_file = .{ .path = sdkPath("/src/main.zig") },
                .target = target,
                .optimize = optimize,
            });
            try link(b, main_tests, options);
            b.installArtifact(main_tests);
            return b.addRunArtifact(main_tests);
        }

        pub const Options = struct {
            gpu_dawn_options: deps.gpu_dawn.Options = .{},
        };

        var _module: ?*std.build.Module = null;

        pub fn module(b: *std.Build) *std.build.Module {
            if (_module) |m| return m;
            _module = b.createModule(.{
                .source_file = .{ .path = sdkPath("/src/main.zig") },
            });
            return _module.?;
        }

        pub fn link(b: *std.Build, step: *std.build.CompileStep, options: Options) !void {
            if (step.target.toTarget().cpu.arch != .wasm32) {
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
