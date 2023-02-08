const std = @import("std");
const builtin = @import("builtin");
const system_sdk = @import("libs/mach-glfw/system_sdk.zig");
const glfw = @import("libs/mach-glfw/build.zig");
const sysjs = @import("libs/mach-sysjs/build.zig");
const gamemode = @import("libs/mach-gamemode/build.zig");
const wasmserve = @import("libs/mach-wasmserve/wasmserve.zig");
const gpu_dawn = @import("libs/mach-gpu-dawn/sdk.zig").Sdk(.{
    .glfw_include_dir = sdkPath("/libs/mach-glfw/upstream/glfw/include"),
    .system_sdk = system_sdk,
});
const gpu = @import("libs/mach-gpu/sdk.zig").Sdk(.{
    .gpu_dawn = gpu_dawn,
});
const core = @import("sdk.zig").Sdk(.{
    .gpu = gpu,
    .gpu_dawn = gpu_dawn,
    .glfw = glfw,
    .gamemode = gamemode,
    .wasmserve = wasmserve,
    .sysjs = sysjs,
});

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const gpu_dawn_options = gpu_dawn.Options{
        .from_source = b.option(bool, "dawn-from-source", "Build Dawn from source") orelse false,
        .debug = b.option(bool, "dawn-debug", "Use a debug build of Dawn") orelse false,
    };
    const options = core.Options{ .gpu_dawn_options = gpu_dawn_options };

    if (target.getCpuArch() != .wasm32) {
        const all_tests_step = b.step("test", "Run library tests");
        const glfw_test_step = b.step("test-glfw", "Run GLFW library tests");
        const gpu_test_step = b.step("test-gpu", "Run GPU library tests");
        const core_test_step = b.step("test-core", "Run Mach Core library tests");

        glfw_test_step.dependOn(&(try glfw.testStep(b, optimize, target)).step);
        gpu_test_step.dependOn(&(try gpu.testStep(b, optimize, target, options.gpuOptions())).step);
        core_test_step.dependOn(&(try core.testStep(b, optimize, target)).step);

        all_tests_step.dependOn(glfw_test_step);
        all_tests_step.dependOn(gpu_test_step);
        all_tests_step.dependOn(core_test_step);

        // TODO: we need a way to test wasm stuff
        // const sysjs_test_step = b.step( "test-sysjs", "Run sysjs library tests");
        // sysjs_test_step.dependOn(&sysjs.testStep(b, optimize, target).step);
        // all_tests_step.dependOn(sysjs_test_step);

        // Compiles the `libmachcore` shared library
        const shared_lib = try core.buildSharedLib(b, optimize, target, options);

        shared_lib.install();
    }

    const compile_all = b.step("compile-all", "Compile Mach");
    compile_all.dependOn(b.getInstallStep());
}

fn sdkPath(comptime suffix: []const u8) []const u8 {
    if (suffix[0] != '/') @compileError("suffix must be an absolute path");
    return comptime blk: {
        const root_dir = std.fs.path.dirname(@src().file) orelse ".";
        break :blk root_dir ++ suffix;
    };
}
