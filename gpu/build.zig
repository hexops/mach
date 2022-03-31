const std = @import("std");
const gpu_dawn = @import("libs/mach-gpu-dawn/build.zig");
const glfw = @import("libs/mach-glfw/build.zig");

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    const gpu_dawn_options = gpu_dawn.Options{
        .from_source = b.option(bool, "dawn-from-source", "Build Dawn from source") orelse false,
    };

    const lib = b.addStaticLibrary("gpu", "src/main.zig");
    lib.setTarget(target);
    lib.setBuildMode(mode);
    lib.install();
    glfw.link(b, lib, .{});
    gpu_dawn.link(b, lib, gpu_dawn_options);

    const main_tests = b.addTest("src/main.zig");
    main_tests.setTarget(target);
    main_tests.setBuildMode(mode);
    glfw.link(b, main_tests, .{});
    gpu_dawn.link(b, main_tests, gpu_dawn_options);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);

    const example = b.addExecutable("gpu-hello-triangle", "examples/main.zig");
    example.setTarget(target);
    example.setBuildMode(mode);
    example.install();
    example.linkLibC();
    example.addPackagePath("gpu", "src/main.zig");
    example.addPackagePath("glfw", "libs/mach-glfw/src/main.zig");
    glfw.link(b, example, .{});
    gpu_dawn.link(b, example, gpu_dawn_options);

    const example_run_cmd = example.run();
    example_run_cmd.step.dependOn(b.getInstallStep());
    const example_run_step = b.step("run-example", "Run the example");
    example_run_step.dependOn(&example_run_cmd.step);
}
