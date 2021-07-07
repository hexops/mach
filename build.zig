const Builder = @import("std").build.Builder;
const glfw = @import("glfw/build.zig");

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const lib = b.addStaticLibrary("engine", "src/main.zig");
    lib.addPackagePath("glfw", "glfw/src/main.zig");
    lib.setBuildMode(mode);
    glfw.link(b, lib, .{});
    lib.install();

    var main_tests = b.addTest("src/main.zig");
    main_tests.addPackagePath("glfw", "glfw/src/main.zig");
    glfw.link(b, main_tests, .{});
    main_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}
