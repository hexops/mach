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

    // TODO: re-enable tests
    const main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);
    main_tests.setTarget(target);
    main_tests.addPackage(pkg);
    main_tests.addPackage(gpu.pkg);
    main_tests.addPackage(glfw.pkg);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);

    // TODO(build-system): https://github.com/hexops/mach/issues/229#issuecomment-1100958939
    ensureDependencySubmodule(b.allocator, "examples/libs/zmath") catch unreachable;
    ensureDependencySubmodule(b.allocator, "examples/libs/zigimg") catch unreachable;
    ensureDependencySubmodule(b.allocator, "examples/assets") catch unreachable;

    inline for ([_]ExampleDefinition{
        .{ .name = "triangle" },
        .{ .name = "boids" },
        .{ .name = "rotating-cube", .packages = &[_]Pkg{Packages.zmath} },
        .{ .name = "two-cubes", .packages = &[_]Pkg{Packages.zmath} },
        .{ .name = "instanced-cube", .packages = &[_]Pkg{Packages.zmath} },
        .{ .name = "gkurve", .packages = &[_]Pkg{ Packages.zmath, Packages.zigimg } },
        .{ .name = "advanced-gen-texture-light", .packages = &[_]Pkg{Packages.zmath} },
        .{ .name = "textured-cube", .packages = &[_]Pkg{ Packages.zmath, Packages.zigimg } },
        .{ .name = "fractal-cube", .packages = &[_]Pkg{Packages.zmath} },
    }) |example| {
        const example_app = App.init(
            b,
            .{
                .name = "example-" ++ example.name,
                .src = "examples/" ++ example.name ++ "/main.zig",
                .target = target,
                .deps = comptime example.packages ++ &[_]Pkg{ glfw.pkg, gpu.pkg, pkg },
            },
        );
        example_app.setBuildMode(mode);
        example_app.link(options);

        const example_run_cmd = example_app.run();
        example_run_cmd.step.dependOn(&example_app.getInstallStep().?.step);
        const example_run_step = b.step("run-example-" ++ example.name, "Run the example");
        example_run_step.dependOn(&example_run_cmd.step);
    }

    const shaderexp_app = App.init(
        b,
        .{
            .name = "shaderexp",
            .src = "shaderexp/main.zig",
            .target = target,
            .deps = &.{ glfw.pkg, gpu.pkg, pkg },
        },
    );
    shaderexp_app.setBuildMode(mode);
    shaderexp_app.link(options);

    const shaderexp_run_cmd = shaderexp_app.run();
    shaderexp_run_cmd.step.dependOn(&shaderexp_app.getInstallStep().?.step);
    const shaderexp_run_step = b.step("run-shaderexp", "Run shaderexp");
    shaderexp_run_step.dependOn(&shaderexp_run_cmd.step);

    const compile_all = b.step("compile-all", "Compile all examples and applications");
    compile_all.dependOn(b.getInstallStep());
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
    // Declared here because submodule may not be cloned at the time build.zig runs.
    const zmath = std.build.Pkg{
        .name = "zmath",
        .path = .{ .path = "examples/libs/zmath/src/zmath.zig" },
    };
    const zigimg = std.build.Pkg{
        .name = "zigimg",
        .path = .{ .path = "examples/libs/zigimg/zigimg.zig" },
    };
};

const App = struct {
    b: *std.build.Builder,
    name: []const u8,
    step: *std.build.LibExeObjStep,

    pub fn init(b: *std.build.Builder, options: struct {
        name: []const u8,
        src: []const u8,
        target: std.zig.CrossTarget,
        deps: ?[]const Pkg = null,
    }) App {
        const app_pkg = std.build.Pkg{
            .name = "app",
            .path = .{ .path = options.src },
            .dependencies = options.deps,
        };

        const step = blk: {
            if (options.target.toTarget().cpu.arch == .wasm32) {
                // TODO: use options.name
                const lib = b.addSharedLibrary("application", "src/wasm.zig", .unversioned);

                break :blk lib;
            } else {
                const exe = b.addExecutable(options.name, "src/native.zig");
                exe.addPackage(gpu.pkg);
                exe.addPackage(glfw.pkg);

                break :blk exe;
            }
        };

        step.addPackage(app_pkg);
        step.setTarget(options.target);
        step.install();

        return .{
            .b = b,
            .step = step,
            .name = options.name,
        };
    }

    pub fn link(app: *const App, options: Options) void {
        const gpu_options = gpu.Options{
            .glfw_options = @bitCast(@import("gpu/libs/mach-glfw/build.zig").Options, options.glfw_options),
            .gpu_dawn_options = @bitCast(@import("gpu/libs/mach-gpu-dawn/build.zig").Options, options.gpu_dawn_options),
        };

        glfw.link(app.b, app.step, options.glfw_options);
        gpu.link(app.b, app.step, gpu_options);
    }

    pub fn setBuildMode(app: *const App, mode: std.builtin.Mode) void {
        app.step.setBuildMode(mode);
    }

    pub fn getInstallStep(app: *const App) ?*std.build.InstallArtifactStep {
        return app.step.install_step;
    }

    pub fn run(app: *const App) *std.build.RunStep {
        if (app.step.target.toTarget().cpu.arch != .wasm32) {
            return app.step.run();
        }
        unreachable;
    }
};

pub const pkg = std.build.Pkg{
    .name = "mach",
    .path = .{ .path = thisDir() ++ "/src/main.zig" },
    .dependencies = &.{ gpu.pkg, glfw.pkg },
};

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}

fn ensureDependencySubmodule(allocator: std.mem.Allocator, path: []const u8) !void {
    if (std.process.getEnvVarOwned(allocator, "NO_ENSURE_SUBMODULES")) |no_ensure_submodules| {
        if (std.mem.eql(u8, no_ensure_submodules, "true")) return;
    } else |_| {}
    var child = std.ChildProcess.init(&.{ "git", "submodule", "update", "--init", path }, allocator);
    child.cwd = thisDir();
    child.stderr = std.io.getStdErr();
    child.stdout = std.io.getStdOut();

    _ = try child.spawnAndWait();
}
