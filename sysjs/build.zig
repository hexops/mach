const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&testStep(b).step);
}

pub fn testStep(b: *std.build.Builder) *std.build.LibExeObjStep {
    return b.addTest(thisDir() ++ "/src/main.zig");
}

pub const pkg = std.build.Pkg{
    .name = "sysjs",
    .source = .{ .path = thisDir() ++ "/src/main.zig" },
    .dependencies = &[_]std.build.Pkg{},
};

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}
