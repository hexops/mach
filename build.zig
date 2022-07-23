const std = @import("std");
const builtin = @import("builtin");
pub const gpu = @import("gpu/build.zig");
const gpu_dawn = @import("gpu-dawn/build.zig");
pub const glfw = @import("glfw/build.zig");
pub const ecs = @import("ecs/build.zig");
const freetype = @import("freetype/build.zig");
const sysaudio = @import("sysaudio/build.zig");
const sysjs = @import("sysjs/build.zig");
const Pkg = std.build.Pkg;

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    const gpu_dawn_options = gpu_dawn.Options{
        .from_source = b.option(bool, "dawn-from-source", "Build Dawn from source") orelse false,
    };
    const options = Options{ .gpu_dawn_options = gpu_dawn_options };

    const main_tests = b.addTestExe("mach-tests", "src/main.zig");
    main_tests.setBuildMode(mode);
    main_tests.setTarget(target);
    main_tests.addPackage(pkg);
    main_tests.addPackage(gpu.pkg);
    main_tests.addPackage(glfw.pkg);
    main_tests.install();

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.run().step);
    test_step.dependOn(&gpu.testStep(b, mode, target, @bitCast(gpu.Options, options)).step);
    test_step.dependOn(&glfw.testStep(b, mode, target).step);
    test_step.dependOn(&ecs.testStep(b, mode, target).step);
    test_step.dependOn(&freetype.testStep(b, mode, target).step);
    test_step.dependOn(&sysaudio.testStep(b, mode, target, .{}).step);
    // TODO: we need a way to test wasm stuff
    // test_mach_step.dependOn(&sysjs.testStep(b, mode, target).step);

    const test_mach_step = b.step("test-mach", "Run Mach Core library tests");
    test_mach_step.dependOn(&main_tests.run().step);

    // TODO(build-system): https://github.com/hexops/mach/issues/229#issuecomment-1100958939
    ensureGit(b.allocator);
    ensureDependencySubmodule(b.allocator, "examples/libs/zmath") catch unreachable;
    ensureDependencySubmodule(b.allocator, "examples/libs/zigimg") catch unreachable;
    ensureDependencySubmodule(b.allocator, "examples/assets") catch unreachable;

    inline for ([_]ExampleDefinition{
        .{ .name = "triangle" },
        .{ .name = "boids" },
        .{ .name = "audio", .packages = &[_]Pkg{sysaudio.pkg} },
        .{ .name = "rotating-cube", .packages = &[_]Pkg{Packages.zmath} },
        .{ .name = "two-cubes", .packages = &[_]Pkg{Packages.zmath} },
        .{ .name = "instanced-cube", .packages = &[_]Pkg{Packages.zmath} },
        .{ .name = "advanced-gen-texture-light", .packages = &[_]Pkg{Packages.zmath} },
        .{ .name = "fractal-cube", .packages = &[_]Pkg{Packages.zmath} },
        .{ .name = "textured-cube", .packages = &[_]Pkg{ Packages.zmath, Packages.zigimg } },
        .{ .name = "ecs-app", .packages = &[_]Pkg{} },
        .{ .name = "image-blur", .packages = &[_]Pkg{Packages.zigimg} },
        .{ .name = "map-async", .packages = &[_]Pkg{} },
        // NOTE: examples with std_platform_only should be placed at last
        .{ .name = "gkurve", .packages = &[_]Pkg{ Packages.zmath, Packages.zigimg, freetype.pkg }, .std_platform_only = true },
    }) |example| {
        // FIXME: this is workaround for a problem that some examples (having the std_platform_only=true field) as
        // well as zigimg uses IO which is not supported in freestanding environments. So break out of this loop
        // as soon as any such examples is found. This does means that any example which works on wasm should be
        // placed before those who dont.
        if (example.std_platform_only)
            if (target.toTarget().cpu.arch == .wasm32)
                break;

        const example_app = App.init(
            b,
            .{
                .name = "example-" ++ example.name,
                .src = "examples/" ++ example.name ++ "/main.zig",
                .target = target,
                .deps = example.packages,
                .res_dirs = &.{thisDir() ++ "/examples/assets"},
            },
        );
        example_app.setBuildMode(mode);
        inline for (example.packages) |p| {
            if (std.mem.eql(u8, p.name, freetype.pkg.name))
                freetype.link(example_app.b, example_app.step, .{});

            if (std.mem.eql(u8, p.name, sysaudio.pkg.name))
                sysaudio.link(example_app.b, example_app.step, .{});
        }

        example_app.link(options);
        example_app.install();

        const example_compile_step = b.step("example-" ++ example.name, "Compile '" ++ example.name ++ "' example");
        example_compile_step.dependOn(&example_app.getInstallStep().?.step);

        const example_run_cmd = example_app.run();
        example_run_cmd.step.dependOn(&example_app.getInstallStep().?.step);
        const example_run_step = b.step("run-example-" ++ example.name, "Run '" ++ example.name ++ "' example");
        example_run_step.dependOn(&example_run_cmd.step);
    }

    if (target.toTarget().cpu.arch != .wasm32) {
        const shaderexp_app = App.init(
            b,
            .{
                .name = "shaderexp",
                .src = "shaderexp/main.zig",
                .target = target,
            },
        );
        shaderexp_app.setBuildMode(mode);
        shaderexp_app.link(options);
        shaderexp_app.install();

        const shaderexp_compile_step = b.step("shaderexp", "Compile shaderexp");
        shaderexp_compile_step.dependOn(&shaderexp_app.getInstallStep().?.step);

        const shaderexp_run_cmd = shaderexp_app.run();
        shaderexp_run_cmd.step.dependOn(&shaderexp_app.getInstallStep().?.step);
        const shaderexp_run_step = b.step("run-shaderexp", "Run shaderexp");
        shaderexp_run_step.dependOn(&shaderexp_run_cmd.step);
    }

    const compile_all = b.step("compile-all", "Compile all examples and applications");
    compile_all.dependOn(b.getInstallStep());

    // compiles the `libmach` shared library
    const lib = b.addSharedLibrary("mach", "src/platform/libmach.zig", .unversioned);
    lib.setTarget(target);
    lib.setBuildMode(mode);
    lib.main_pkg_path = "src/";
    const app_pkg = std.build.Pkg{
        .name = "app",
        .source = .{ .path = "src/platform/libmach.zig" },
    };
    lib.addPackage(app_pkg);
    lib.addPackage(gpu.pkg);
    lib.addPackage(glfw.pkg);
    const gpu_options = gpu.Options{
        .glfw_options = @bitCast(@import("gpu/libs/mach-glfw/build.zig").Options, options.glfw_options),
        .gpu_dawn_options = @bitCast(@import("gpu/libs/mach-gpu-dawn/build.zig").Options, options.gpu_dawn_options),
    };
    glfw.link(b, lib, options.glfw_options);
    gpu.link(b, lib, gpu_options);
    lib.setOutputDir("./libmach/build");
    lib.install();
}

pub const Options = struct {
    glfw_options: glfw.Options = .{},
    gpu_dawn_options: gpu_dawn.Options = .{},
};

const ExampleDefinition = struct {
    name: []const u8,
    packages: []const Pkg = &[_]Pkg{},
    std_platform_only: bool = false,
};

const Packages = struct {
    // Declared here because submodule may not be cloned at the time build.zig runs.
    const zmath = std.build.Pkg{
        .name = "zmath",
        .source = .{ .path = "examples/libs/zmath/src/zmath.zig" },
    };
    const zigimg = std.build.Pkg{
        .name = "zigimg",
        .source = .{ .path = "examples/libs/zigimg/zigimg.zig" },
    };
};

const web_install_dir = std.build.InstallDir{ .custom = "www" };

pub const App = struct {
    b: *std.build.Builder,
    name: []const u8,
    step: *std.build.LibExeObjStep,
    platform: Platform,
    res_dirs: ?[]const []const u8,

    pub const Platform = enum {
        native,
        web,

        pub fn fromTarget(target: std.Target) Platform {
            if (target.cpu.arch == .wasm32) return .web;
            return .native;
        }
    };

    pub fn init(b: *std.build.Builder, options: struct {
        name: []const u8,
        src: []const u8,
        target: std.zig.CrossTarget,
        deps: ?[]const Pkg = null,
        res_dirs: ?[]const []const u8 = null,
    }) App {
        const target = (std.zig.system.NativeTargetInfo.detect(b.allocator, options.target) catch unreachable).target;
        const platform = Platform.fromTarget(target);

        var deps = std.ArrayList(std.build.Pkg).init(b.allocator);
        deps.append(pkg) catch unreachable;
        deps.append(gpu.pkg) catch unreachable;
        switch (platform) {
            .native => deps.append(glfw.pkg) catch unreachable,
            .web => deps.append(sysjs.pkg) catch unreachable,
        }
        if (options.deps) |app_deps| deps.appendSlice(app_deps) catch unreachable;

        const app_pkg = std.build.Pkg{
            .name = "app",
            .source = .{ .path = options.src },
            .dependencies = deps.toOwnedSlice(),
        };

        const step = blk: {
            if (platform == .web) {
                const lib = b.addSharedLibrary(options.name, thisDir() ++ "/src/platform/wasm.zig", .unversioned);
                lib.addPackage(gpu.pkg);
                lib.addPackage(sysjs.pkg);

                break :blk lib;
            } else {
                const exe = b.addExecutable(options.name, thisDir() ++ "/src/platform/native.zig");
                exe.addPackage(gpu.pkg);
                exe.addPackage(glfw.pkg);

                if (target.os.tag == .linux) {
                    exe.addPackagePath("gamemode", thisDir() ++ "/gamemode/gamemode.zig");
                }

                break :blk exe;
            }
        };

        step.main_pkg_path = thisDir() ++ "/src";
        step.addPackage(app_pkg);
        step.setTarget(options.target);

        return .{
            .b = b,
            .step = step,
            .name = options.name,
            .platform = platform,
            .res_dirs = options.res_dirs,
        };
    }

    pub fn install(app: *const App) void {
        app.step.install();

        // Install additional files (src/mach.js and template.html)
        // in case of wasm
        if (app.platform == .web) {
            // Set install directory to '{prefix}/www'
            app.getInstallStep().?.dest_dir = web_install_dir;

            inline for (.{ "/src/platform/mach.js", "/sysjs/src/mach-sysjs.js" }) |js| {
                const install_js = app.b.addInstallFileWithDir(
                    .{ .path = thisDir() ++ js },
                    web_install_dir,
                    std.fs.path.basename(js),
                );
                app.getInstallStep().?.step.dependOn(&install_js.step);
            }

            const html_generator = app.b.addExecutable("html-generator", thisDir() ++ "/tools/html-generator.zig");
            html_generator.main_pkg_path = thisDir();
            const run_html_generator = html_generator.run();
            run_html_generator.addArgs(&.{ std.mem.concat(
                app.b.allocator,
                u8,
                &.{ app.name, ".html" },
            ) catch unreachable, app.name });

            run_html_generator.cwd = app.b.getInstallPath(web_install_dir, "");
            app.getInstallStep().?.step.dependOn(&run_html_generator.step);
        }

        // Install resources
        if (app.res_dirs) |res_dirs| {
            for (res_dirs) |res| {
                const install_res = app.b.addInstallDirectory(.{
                    .source_dir = res,
                    .install_dir = app.getInstallStep().?.dest_dir,
                    .install_subdir = std.fs.path.basename(res),
                    .exclude_extensions = &.{},
                });
                app.getInstallStep().?.step.dependOn(&install_res.step);
            }
        }
    }

    pub fn link(app: *const App, options: Options) void {
        const gpu_options = gpu.Options{
            .glfw_options = @bitCast(@import("gpu/libs/mach-glfw/build.zig").Options, options.glfw_options),
            .gpu_dawn_options = @bitCast(@import("gpu/libs/mach-gpu-dawn/build.zig").Options, options.gpu_dawn_options),
        };

        if (app.platform != .web) {
            glfw.link(app.b, app.step, options.glfw_options);
            gpu.link(app.b, app.step, gpu_options);
        }
    }

    pub fn setBuildMode(app: *const App, mode: std.builtin.Mode) void {
        app.step.setBuildMode(mode);
    }

    pub fn getInstallStep(app: *const App) ?*std.build.InstallArtifactStep {
        return app.step.install_step;
    }

    pub fn run(app: *const App) *std.build.RunStep {
        if (app.platform == .web) {
            ensureDependencySubmodule(app.b.allocator, "tools/libs/apple_pie") catch unreachable;

            const http_server = app.b.addExecutable("http-server", thisDir() ++ "/tools/http-server.zig");
            http_server.addPackage(.{
                .name = "apple_pie",
                .source = .{ .path = "tools/libs/apple_pie/src/apple_pie.zig" },
            });

            // NOTE: The launch actually takes place in reverse order. The browser is launched first
            // and then the http-server.
            // This is because running the server would block the process (a limitation of current
            // RunStep). So we assume that (xdg-)open is a launcher and not a blocking process.

            const address = std.process.getEnvVarOwned(app.b.allocator, "MACH_ADDRESS") catch "127.0.0.1";
            const port = std.process.getEnvVarOwned(app.b.allocator, "MACH_PORT") catch "8000";

            const launch = app.b.addSystemCommand(&.{
                switch (builtin.os.tag) {
                    .macos, .windows => "open",
                    else => "xdg-open", // Assume linux-like
                },
                app.b.fmt("http://{s}:{s}/{s}.html", .{ address, port, app.name }),
            });
            launch.step.dependOn(&app.getInstallStep().?.step);

            const serve = http_server.run();
            serve.addArgs(&.{ app.name, address, port });
            serve.step.dependOn(&launch.step);
            serve.cwd = app.b.getInstallPath(web_install_dir, "");

            return serve;
        } else {
            return app.step.run();
        }
    }
};

pub const pkg = std.build.Pkg{
    .name = "mach",
    .source = .{ .path = thisDir() ++ "/src/main.zig" },
    .dependencies = &.{ gpu.pkg, ecs.pkg },
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

fn ensureGit(allocator: std.mem.Allocator) void {
    const argv = &[_][]const u8{ "git", "--version" };
    const result = std.ChildProcess.exec(.{
        .allocator = allocator,
        .argv = argv,
        .cwd = ".",
    }) catch { // e.g. FileNotFound
        std.log.err("mach: error: 'git --version' failed. Is git not installed?", .{});
        std.process.exit(1);
    };
    defer {
        allocator.free(result.stderr);
        allocator.free(result.stdout);
    }
    if (result.term.Exited != 0) {
        std.log.err("mach: error: 'git --version' failed. Is git not installed?", .{});
        std.process.exit(1);
    }
}
