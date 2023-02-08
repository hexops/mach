const std = @import("std");

pub fn module(b: *std.Build) *std.build.Module {
    return b.createModule(.{
        .source_file = .{ .path = sdkPath("/src/main.zig") },
    });
}

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&testStep(b, optimize, target).step);
}

pub fn testStep(b: *std.Build, optimize: std.builtin.OptimizeMode, target: std.zig.CrossTarget) *std.build.RunStep {
    const main_tests = b.addTest(.{
        .name = "model3d-tests",
        .kind = .test_exe,
        .root_source_file = .{ .path = sdkPath("/src/main.zig") },
        .target = target,
        .optimize = optimize,
    });
    link(b, main_tests, target);
    main_tests.install();
    return main_tests.run();
}

pub fn link(b: *std.Build, step: *std.build.CompileStep, target: std.zig.CrossTarget) void {
    const lib = b.addStaticLibrary(.{
        .name = "model3d",
        .target = target,
        .optimize = step.optimize,
    });
    // Note: model3d needs unaligned accesses, which are safe on all modern architectures.
    // See https://gitlab.com/bztsrc/model3d/-/issues/19
    lib.addCSourceFile(sdkPath("/src/c/m3d.c"), &.{ "-std=c89", "-fno-sanitize=alignment" });
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
