const builtin = @import("builtin");
const std = @import("std");
const Build = std.Build;
const glfw = @import("sdk.zig").Sdk(.{
    // TODO(build-system): This cannot be imported with the Zig package manager
    // error: TarUnsupportedFileType
    .xcode_frameworks = @import("libs/xcode-frameworks/build.zig"),
});

pub fn build(b: *Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&(try glfw.testStep(b, optimize, target)).step);
    test_step.dependOn(&(try glfw.testStepShared(b, optimize, target)).step);
}
