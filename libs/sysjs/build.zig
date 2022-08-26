const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&testStep(b, mode, target).step);
}

pub fn testStep(b: *std.build.Builder, mode: std.builtin.Mode, target: std.zig.CrossTarget) *std.build.RunStep {
    const main_tests = b.addTestExe("sysjs-tests", thisDir() ++ "/src/main.zig");
    main_tests.setBuildMode(mode);
    main_tests.setTarget(target);
    return main_tests.run();
}

pub const pkg = std.build.Pkg{
    .name = "sysjs",
    .source = .{ .path = thisDir() ++ "/src/main.zig" },
    .dependencies = &[_]std.build.Pkg{},
};

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}
