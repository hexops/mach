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
    link(b, lib, .{ .gpu_dawn_options = gpu_dawn_options });

    const main_tests = b.addTest("src/main.zig");
    main_tests.setTarget(target);
    main_tests.setBuildMode(mode);
    link(b, main_tests, .{ .gpu_dawn_options = gpu_dawn_options });

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);

    const example = b.addExecutable("gpu-hello-triangle", "examples/main.zig");
    example.setTarget(target);
    example.setBuildMode(mode);
    example.install();
    example.linkLibC();
    example.addPackagePath("gpu", "src/main.zig");
    example.addPackagePath("glfw", "libs/mach-glfw/src/main.zig");
    link(b, example, .{ .gpu_dawn_options = gpu_dawn_options });

    const example_run_cmd = example.run();
    example_run_cmd.step.dependOn(b.getInstallStep());
    const example_run_step = b.step("run-example", "Run the example");
    example_run_step.dependOn(&example_run_cmd.step);
}

const Options = struct {
    glfw_options: glfw.Options = .{},
    gpu_dawn_options: gpu_dawn.Options = .{},
};

pub const pkg = .{
    .name = "gpu",
    .path = .{ .path = thisDir() ++ "/src/main.zig" },
    .dependencies = &.{glfw.pkg},
};

pub fn link(b: *std.build.Builder, step: *std.build.LibExeObjStep, options: Options) void {
    const main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/main.zig" }) catch unreachable;
    const lib = b.addStaticLibrary("gpu", main_abs);
    lib.setBuildMode(step.build_mode);
    lib.setTarget(step.target);

    const glfw_main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/mach-glfw/src/main.zig" }) catch unreachable;
    lib.addPackagePath("glfw", glfw_main_abs);

    glfw.link(b, lib, options.glfw_options);
    gpu_dawn.link(b, lib, options.gpu_dawn_options);
    lib.install();

    glfw.link(b, step, options.glfw_options);
    gpu_dawn.link(b, step, options.gpu_dawn_options);
}

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}
