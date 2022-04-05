const std = @import("std");
const gpu = @import("gpu/build.zig");
const gpu_dawn = @import("gpu-dawn/build.zig");
const glfw = @import("glfw/build.zig");

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    const gpu_dawn_options = gpu_dawn.Options{
        .from_source = b.option(bool, "dawn-from-source", "Build Dawn from source") orelse false,
    };
    const options = Options {.gpu_dawn_options = gpu_dawn_options};

    const main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);
    main_tests.setTarget(target);
    main_tests.addPackage(pkg);
    main_tests.addPackage(gpu.pkg);
    main_tests.addPackage(glfw.pkg);
    link(b, main_tests, options);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);

    const example = b.addExecutable("hello-triangle", "examples/main.zig");
    example.setTarget(target);
    example.setBuildMode(mode);
    example.addPackage(pkg);
    example.addPackage(gpu.pkg);
    example.addPackage(glfw.pkg);
    link(b, example, options);
    example.install();

    const example_run_cmd = example.run();
    example_run_cmd.step.dependOn(b.getInstallStep());
    const example_run_step = b.step("run-example", "Run the example");
    example_run_step.dependOn(&example_run_cmd.step);
}

pub const Options = struct {
    glfw_options: glfw.Options = .{},
    gpu_dawn_options: gpu_dawn.Options = .{},
};

pub const pkg = .{
    .name = "mach",
    .path = .{ .path = thisDir() ++ "/src/main.zig" },
    .dependencies = &.{ gpu.pkg, glfw.pkg },
};

pub fn link(b: *std.build.Builder, step: *std.build.LibExeObjStep, options: Options) void {
    const gpu_options = gpu.Options{
        .glfw_options = @bitCast(@import("gpu/libs/mach-glfw/build.zig").Options, options.glfw_options),
        .gpu_dawn_options = @bitCast(@import("gpu/libs/mach-gpu-dawn/build.zig").Options, options.gpu_dawn_options),
    };

    const main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/main.zig" }) catch unreachable;
    const lib = b.addStaticLibrary("mach", main_abs);
    lib.setBuildMode(step.build_mode);
    lib.setTarget(step.target);
    lib.addPackage(gpu.pkg);
    lib.addPackage(glfw.pkg);

    glfw.link(b, lib, options.glfw_options);
    gpu.link(b, lib, gpu_options);
    lib.install();

    glfw.link(b, step, options.glfw_options);
    gpu.link(b, step, gpu_options);
}

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}
