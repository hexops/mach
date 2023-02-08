const std = @import("std");
const sysaudio_sdk = @import("sdk.zig");
const system_sdk = @import("libs/mach-glfw/system_sdk.zig");
const sysjs = @import("libs/mach-sysjs/build.zig");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});
    const sysaudio = sysaudio_sdk.Sdk(.{
        .system_sdk = system_sdk,
        .sysjs = sysjs,
    });

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&sysaudio.testStep(b, optimize, target).step);

    inline for ([_][]const u8{
        "sine-wave",
    }) |example| {
        const example_exe = b.addExecutable(.{
            .name = "example-" ++ example,
            .root_source_file = .{ .path = "examples/" ++ example ++ ".zig" },
            .target = target,
            .optimize = optimize,
        });
        example_exe.addModule("sysaudio", sysaudio.module(b));
        sysaudio.link(b, example_exe, .{});
        example_exe.install();

        const example_compile_step = b.step("example-" ++ example, "Compile '" ++ example ++ "' example");
        example_compile_step.dependOn(b.getInstallStep());

        const example_run_cmd = example_exe.run();
        example_run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            example_run_cmd.addArgs(args);
        }

        const example_run_step = b.step("run-example-" ++ example, "Run '" ++ example ++ "' example");
        example_run_step.dependOn(&example_run_cmd.step);
    }
}
