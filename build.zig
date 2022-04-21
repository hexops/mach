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

    // TODO(build-system): https://github.com/hexops/mach/issues/229#issuecomment-1100958939
    ensureDependencySubmodule(b.allocator, "examples/libs/zmath") catch unreachable;

    inline for ([_]ExampleDefinition{
        .{ .name = "triangle" },
        .{ .name = "boids" },
        .{ .name = "rotating-cube", .packages = &[_]Pkg{Packages.zmath} },
        .{ .name = "two-cubes", .packages = &[_]Pkg{Packages.zmath} },
        .{ .name = "instanced-cube", .packages = &[_]Pkg{Packages.zmath} },
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
    const zmath = zmath_pkg;
};

// Declared here because submodule may not be cloned at the time build.zig runs.
const zmath_pkg = std.build.Pkg{
    .name = "zmath",
    .path = .{ .path = "examples/libs/zmath/src/zmath.zig" },
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

    glfw.link(b, step, options.glfw_options);
    gpu.link(b, step, gpu_options);
}

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}

fn ensureDependencySubmodule(allocator: std.mem.Allocator, path: []const u8) !void {
    if (std.process.getEnvVarOwned(allocator, "NO_ENSURE_SUBMODULES")) |no_ensure_submodules| {
        if (std.mem.eql(u8, no_ensure_submodules, "true")) return;
    } else |_| {}
    const child = try std.ChildProcess.init(&.{ "git", "submodule", "update", "--init", path }, allocator);
    child.cwd = thisDir();
    child.stderr = std.io.getStdErr();
    child.stdout = std.io.getStdOut();

    _ = try child.spawnAndWait();
}
