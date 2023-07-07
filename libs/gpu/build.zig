const std = @import("std");
const glfw = @import("libs/mach-glfw/build.zig").Sdk(.{
    // TODO(build-system): This cannot be imported with the Zig package manager
    // error: TarUnsupportedFileType
    .xcode_frameworks = @import("libs/mach-gpu-dawn/libs/xcode-frameworks/build.zig"),
});
const gpu_dawn_sdk = @import("libs/mach-gpu-dawn/sdk.zig");
const gpu_sdk = @import("sdk.zig");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});
    const gpu_dawn = gpu_dawn_sdk.Sdk(.{
        // TODO(build-system): This cannot be imported with the Zig package manager
        // error: TarUnsupportedFileType
        .xcode_frameworks = @import("libs/mach-gpu-dawn/libs/xcode-frameworks/build.zig"),
    });
    const gpu = gpu_sdk.Sdk(.{
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
