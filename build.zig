const std = @import("std");
pub const gpu = @import("gpu/build.zig");
const gpu_dawn = @import("gpu-dawn/build.zig");
pub const glfw = @import("glfw/build.zig");
const Pkg = std.build.Pkg;

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    const gpu_dawn_options = gpu_dawn.Options{
        .from_source = b.option(bool, "dawn-from-source", "Build Dawn from source") orelse false,
    };
    const options = Options{ .gpu_dawn_options = gpu_dawn_options };

    const main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);
    main_tests.setTarget(target);
    main_tests.addPackage(pkg);
    main_tests.addPackage(gpu.pkg);
    main_tests.addPackage(glfw.pkg);
    link(b, main_tests, options);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);

    inline for ([_]ExampleDefinition{
        .{ .name = "triangle" },
        .{ .name = "boids" },
        .{ .name = "rotating-cube", .packages = &[_]Pkg{Packages.zmath} },
        .{ .name = "two-cubes", .packages = &[_]Pkg{Packages.zmath} },
    }) |example| {
        const example_exe = b.addExecutable("example-" ++ example.name, "examples/" ++ example.name ++ "/main.zig");
        example_exe.setTarget(target);
        example_exe.setBuildMode(mode);
        example_exe.addPackage(pkg);
        example_exe.addPackage(gpu.pkg);
        example_exe.addPackage(glfw.pkg);
        inline for (example.packages) |additional_package| {
            example_exe.addPackage(additional_package);
        }
        link(b, example_exe, options);
        example_exe.install();

        const example_run_cmd = example_exe.run();
        example_run_cmd.step.dependOn(b.getInstallStep());
        const example_run_step = b.step("run-example-" ++ example.name, "Run the example");
        example_run_step.dependOn(&example_run_cmd.step);
    }
}

pub const Options = struct {
    glfw_options: glfw.Options = .{},
    gpu_dawn_options: gpu_dawn.Options = .{},
};

const ExampleDefinition = struct {
    name: []const u8,
    packages: []const Pkg = &[_]Pkg{},
};

const Packages = struct {
    const zmath = @import("examples/libs/zmath/build.zig").pkg;
};

pub const pkg = std.build.Pkg{
    .name = "mach",
    .path = .{ .path = thisDir() ++ "/src/main.zig" },
    .dependencies = &.{ gpu.pkg, glfw.pkg },
};

pub fn link(b: *std.build.Builder, step: *std.build.LibExeObjStep, options: Options) void {
    const gpu_options = gpu.Options{
        .glfw_options = @bitCast(@import("gpu/libs/mach-glfw/build.zig").Options, options.glfw_options),
        .gpu_dawn_options = @bitCast(@import("gpu/libs/mach-gpu-dawn/build.zig").Options, options.gpu_dawn_options),
    };

    const main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/main.zig" }) catch unreachable;
    const lib = b.addStaticLibrary("mach", main_abs);
    lib.setBuildMode(step.build_mode);
    lib.setTarget(step.target);
    lib.addPackage(gpu.pkg);
    lib.addPackage(glfw.pkg);

    glfw.link(b, lib, options.glfw_options);
    gpu.link(b, lib, gpu_options);
    lib.install();

    glfw.link(b, step, options.glfw_options);
    gpu.link(b, step, gpu_options);
}

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}
