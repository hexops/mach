const std = @import("std");

pub const pkg = std.build.Pkg{
    .name = "model3d",
    .source = .{ .path = sdkPath("/src/main.zig") },
};

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&testStep(b, mode, target).step);
}

pub fn testStep(b: *std.build.Builder, mode: std.builtin.Mode, target: std.zig.CrossTarget) *std.build.RunStep {
    const main_tests = b.addTestExe("model3d-tests", "src/main.zig");
    main_tests.setBuildMode(mode);
    main_tests.setTarget(target);
    link(b, main_tests, target);
    main_tests.install();
    return main_tests.run();
}

pub fn link(b: *std.build.Builder, step: *std.build.LibExeObjStep, target: std.zig.CrossTarget) void {
    const lib = b.addStaticLibrarySource("model3d", null);
    lib.setTarget(target);
    lib.addCSourceFile(sdkPath("/src/c/m3d.c"), &.{ "-std=c89", "-DM3D_ASCII" });
    lib.linkLibC();
    step.addIncludePath(sdkPath("/src/c/"));
    step.linkLibrary(lib);
}

fn sdkPath(comptime suffix: []const u8) []const u8 {
    if (suffix[0] != '/') @compileError("suffix must be an absolute path");
    return comptime blk: {
        const root_dir = std.fs.path.dirname(@src().file) orelse ".";
        break :blk root_dir ++ suffix;
    };
}
