const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&testStep(b, mode).step);
}

pub fn testStep(b: *std.build.Builder, mode: std.builtin.Mode) *std.build.LibExeObjStep {
    const main_tests = b.addTest(thisDir() ++ "/src/main.zig");
    main_tests.setBuildMode(mode);
    return main_tests;
}

pub const pkg = std.build.Pkg{
    .name = "sysjs",
    .source = .{ .path = thisDir() ++ "/src/main.zig" },
    .dependencies = &[_]std.build.Pkg{},
};

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}
