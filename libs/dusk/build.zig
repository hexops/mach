const std = @import("std");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&testStep(b, optimize, target).step);
}

var _module: ?*std.build.Module = null;

pub fn module(b: *std.Build) *std.build.Module {
    if (_module) |m| return m;
    _module = b.createModule(.{
        .source_file = .{ .path = sdkPath("/src/main.zig") },
    });
    return _module.?;
}

pub fn testStep(b: *std.Build, optimize: std.builtin.OptimizeMode, target: std.zig.CrossTarget) *std.build.RunStep {
    const lib_tests = b.addTest(.{
        .name = "dusk-lib-tests",
        .root_source_file = .{ .path = sdkPath("/src/main.zig") },
        .target = target,
        .optimize = optimize,
    });
    lib_tests.install();

    const main_tests = b.addTest(.{
        .name = "dusk-tests",
        .root_source_file = .{ .path = sdkPath("/test/main.zig") },
        .target = target,
        .optimize = optimize,
    });
    main_tests.addModule("dusk", module(b));
    main_tests.install();

    const run_step = main_tests.run();
    run_step.step.dependOn(&lib_tests.run().step);
    return main_tests.run();
}

fn sdkPath(comptime suffix: []const u8) []const u8 {
    if (suffix[0] != '/') @compileError("suffix must be an absolute path");
    return comptime blk: {
        const root_dir = std.fs.path.dirname(@src().file) orelse ".";
        break :blk root_dir ++ suffix;
    };
}
