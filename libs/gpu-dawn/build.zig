const std = @import("std");
const Build = std.Build;
const glfw = @import("libs/mach-glfw/build.zig");
const system_sdk = @import("libs/mach-glfw/system_sdk.zig");
const gpu_dawn_sdk = @import("sdk.zig");

pub fn build(b: *Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});
    const gpu_dawn = gpu_dawn_sdk.Sdk(.{
        .glfw_include_dir = "libs/mach-glfw/upstream/glfw/include",
        .system_sdk = system_sdk,
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
    try glfw.link(b, example, .{ .system_sdk = .{ .set_sysroot = false } });
    example.addModule("glfw", glfw.module(b));
    example.install();
}
