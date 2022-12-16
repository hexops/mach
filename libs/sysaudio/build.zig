const std = @import("std");
const sysaudio_sdk = @import("sdk.zig");
const system_sdk = @import("libs/mach-glfw/system_sdk.zig");
const sysjs = @import("libs/mach-sysjs/build.zig");

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});
    const sysaudio = sysaudio_sdk.Sdk(.{
        .system_sdk = system_sdk,
        .sysjs = sysjs,
    });

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&sysaudio.testStep(b, mode, target).step);

    inline for ([_][]const u8{
        "sine-wave",
    }) |example| {
        const example_exe = b.addExecutable("example-" ++ example, "examples/" ++ example ++ ".zig");
        example_exe.setBuildMode(mode);
        example_exe.setTarget(target);
        example_exe.addPackage(sysaudio.pkg);
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
