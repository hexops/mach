const Builder = @import("std").build.Builder;
const dawn = @import("build_dawn.zig");

const glfw = @import("./libs/dawn/mach-old/glfw/build.zig"); // TODO: mach-old path

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    const lib = b.addStaticLibrary("webgpu", "src/main.zig");
    lib.setBuildMode(mode);
    lib.setTarget(target);
    lib.install();
    dawn.link(b, lib, .{});

    var main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);

    const dawn_example = b.addExecutable("dawn-example", "src/dawn/hello_triangle.zig");
    dawn_example.setBuildMode(mode);
    dawn_example.setTarget(target);
    dawn.link(b, dawn_example, .{});
    glfw.link(b, dawn_example, .{.system_sdk = .{.set_sysroot = false}});
    dawn_example.addPackagePath("glfw", "./libs/dawn/mach-old/glfw/src/main.zig"); // TODO: mach-old path
    dawn_example.addIncludeDir("libs/dawn/out/Debug/gen/src/include");
    dawn_example.addIncludeDir("libs/dawn/out/Debug/gen/src");
    dawn_example.addIncludeDir("libs/dawn/src/include");
    dawn_example.addIncludeDir("src/dawn");
    dawn_example.install();

    const dawn_example_run_cmd = dawn_example.run();
    dawn_example_run_cmd.step.dependOn(b.getInstallStep());
    const dawn_example_run_step = b.step("run-dawn-example", "Run the dawn example");
    dawn_example_run_step.dependOn(&dawn_example_run_cmd.step);
}
