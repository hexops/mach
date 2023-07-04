const std = @import("std");
const Build = std.Build;
const glfw = @import("libs/mach-glfw/sdk.zig").Sdk(.{
    // TODO(build-system): This cannot be imported with the Zig package manager
    // error: TarUnsupportedFileType
    .xcode_frameworks = @import("libs/xcode-frameworks/build.zig"),
});
const gpu_dawn_sdk = @import("sdk.zig");

pub fn build(b: *Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});
    const gpu_dawn = gpu_dawn_sdk.Sdk(.{
        // TODO(build-system): This cannot be imported with the Zig package manager
        // error: TarUnsupportedFileType
        .xcode_frameworks = @import("libs/xcode-frameworks/build.zig"),
    });

    const options = gpu_dawn.Options{
        .install_libs = true,
        .from_source = true,
    };

    // Just to demonstrate/test linking. This is not a functional example, see the mach/gpu examples
    // or Dawn C++ examples for functional example code.
    const example = b.addExecutable(.{
        .name = "dawn-example",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    try gpu_dawn.link(b, example, options);
    try glfw.link(b, example, .{});
    example.addModule("glfw", glfw.module(b));
    b.installArtifact(example);
}
