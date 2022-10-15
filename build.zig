const std = @import("std");
const builtin = @import("builtin");
const system_sdk = @import("libs/glfw/system_sdk.zig");
const glfw = @import("libs/glfw/build.zig");
const ecs = @import("libs/ecs/build.zig");
const freetype = @import("libs/freetype/build.zig");
const basisu = @import("libs/basisu/build.zig");
const sysjs = @import("libs/sysjs/build.zig");
const gamemode = @import("libs/gamemode/build.zig");
const wasmserve = @import("tools/wasmserve/wasmserve.zig");
const gpu_dawn = @import("libs/gpu-dawn/sdk.zig").Sdk(.{
    .glfw = glfw,
    .glfw_include_dir = "glfw/upstream/glfw/include",
    .system_sdk = system_sdk,
});
const gpu = @import("libs/gpu/sdk.zig").Sdk(.{
    .glfw = glfw,
    .gpu_dawn = gpu_dawn,
});
const sysaudio = @import("libs/sysaudio/sdk.zig").Sdk(.{
    .system_sdk = system_sdk,
    .sysjs = sysjs,
});
const CrossTarget = std.zig.CrossTarget;
const Builder = std.build.Builder;
const Pkg = std.build.Pkg;

pub const pkg = Pkg{
    .name = "mach",
    .source = .{ .path = sdkPath("/src/main.zig") },
    .dependencies = &.{ gpu.pkg, ecs.pkg, sysaudio.pkg },
};

pub const Options = struct {
    glfw_options: glfw.Options = .{},
    gpu_dawn_options: gpu_dawn.Options = .{},
    sysaudio_options: sysaudio.Options = .{},

    pub fn gpuOptions(options: Options) gpu.Options {
        return .{
            .glfw_options = options.glfw_options,
            .gpu_dawn_options = options.gpu_dawn_options,
        };
    }
};

pub fn build(b: *Builder) !void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    const gpu_dawn_options = gpu_dawn.Options{
        .from_source = b.option(bool, "dawn-from-source", "Build Dawn from source") orelse false,
        .debug = b.option(bool, "dawn-debug", "Use a debug build of Dawn") orelse false,
    };
    const options = Options{ .gpu_dawn_options = gpu_dawn_options };

    if (target.getCpuArch() != .wasm32) {
        const all_tests_step = b.step("test", "Run library tests");
        const glfw_test_step = b.step("test-glfw", "Run GLFW library tests");
        const gpu_test_step = b.step("test-gpu", "Run GPU library tests");
        const ecs_test_step = b.step("test-ecs", "Run ECS library tests");
        const freetype_test_step = b.step("test-freetype", "Run Freetype library tests");
        const basisu_test_step = b.step("test-basisu", "Run Basis-Universal library tests");
        const sysaudio_test_step = b.step("test-sysaudio", "Run sysaudio library tests");
        const mach_test_step = b.step("test-mach", "Run Mach Core library tests");

        glfw_test_step.dependOn(&(try glfw.testStep(b, mode, target)).step);
        gpu_test_step.dependOn(&(try gpu.testStep(b, mode, target, options.gpuOptions())).step);
        freetype_test_step.dependOn(&freetype.testStep(b, mode, target).step);
        ecs_test_step.dependOn(&ecs.testStep(b, mode, target).step);
        basisu_test_step.dependOn(&basisu.testStep(b, mode, target).step);
        sysaudio_test_step.dependOn(&sysaudio.testStep(b, mode, target).step);
        mach_test_step.dependOn(&testStep(b, mode, target).step);

        all_tests_step.dependOn(glfw_test_step);
        all_tests_step.dependOn(gpu_test_step);
        all_tests_step.dependOn(ecs_test_step);
        all_tests_step.dependOn(basisu_test_step);
        all_tests_step.dependOn(freetype_test_step);
        all_tests_step.dependOn(sysaudio_test_step);
        all_tests_step.dependOn(mach_test_step);

        // TODO: we need a way to test wasm stuff
        // const sysjs_test_step = b.step( "test-sysjs", "Run sysjs library tests");
        // sysjs_test_step.dependOn(&sysjs.testStep(b, mode, target).step);
        // all_tests_step.dependOn(sysjs_test_step);

        const shaderexp_app = try App.init(
            b,
            .{
                .name = "shaderexp",
                .src = "shaderexp/main.zig",
                .target = target,
            },
        );
        shaderexp_app.setBuildMode(mode);
        try shaderexp_app.link(options);
        shaderexp_app.install();

        const shaderexp_compile_step = b.step("shaderexp", "Compile shaderexp");
        shaderexp_compile_step.dependOn(&shaderexp_app.getInstallStep().?.step);

        const shaderexp_run_cmd = try shaderexp_app.run();
        shaderexp_run_cmd.dependOn(&shaderexp_app.getInstallStep().?.step);
        const shaderexp_run_step = b.step("run-shaderexp", "Run shaderexp");
        shaderexp_run_step.dependOn(shaderexp_run_cmd);

        // Compiles the `libmach` shared library
        const shared_lib = try buildSharedLib(b, mode, target, options);
        shared_lib.install();
    }

    try ensureExamplesDependencySubmodules(b.allocator);
    inline for ([_]struct {
        name: []const u8,
        deps: []const Pkg = &.{},
        std_platform_only: bool = false,
        has_assets: bool = false,
    }{
        .{ .name = "triangle" },
        .{ .name = "triangle-msaa" },
        .{ .name = "boids" },
        .{ .name = "rotating-cube", .deps = &.{Packages.zmath} },
        .{ .name = "pixel-post-process", .deps = &.{Packages.zmath} },
        .{ .name = "two-cubes", .deps = &.{Packages.zmath} },
        .{ .name = "instanced-cube", .deps = &.{Packages.zmath} },
        .{ .name = "advanced-gen-texture-light", .deps = &.{Packages.zmath} },
        .{ .name = "fractal-cube", .deps = &.{Packages.zmath} },
        .{ .name = "textured-cube", .deps = &.{ Packages.zmath, Packages.zigimg }, .has_assets = true },
        .{ .name = "ecs-app", .deps = &.{} },
        .{ .name = "image-blur", .deps = &.{Packages.zigimg}, .has_assets = true },
        .{ .name = "cubemap", .deps = &.{ Packages.zmath, Packages.zigimg }, .has_assets = true },
        .{ .name = "map-async", .deps = &.{} },
        .{ .name = "sysaudio", .deps = &.{} },
        .{ .name = "gkurve", .deps = &.{ Packages.zmath, Packages.zigimg, freetype.pkg }, .std_platform_only = true, .has_assets = true },
    }) |example| {
        // FIXME: this is workaround for a problem that some examples
        // (having the std_platform_only=true field) as well as zigimg
        // uses IO which is not supported in freestanding environments.
        // So break out of this loop as soon as any such examples is found.
        // This does means that any example which works on wasm should be
        // placed before those who dont.
        if (example.std_platform_only)
            if (target.getCpuArch() == .wasm32)
                break;

        const example_app = try App.init(
            b,
            .{
                .name = "example-" ++ example.name,
                .src = "examples/" ++ example.name ++ "/main.zig",
                .target = target,
                .deps = example.deps,
                .res_dirs = if (example.has_assets) &.{"examples/" ++ example.name ++ "/assets"} else null,
                .watch_paths = &.{"examples/" ++ example.name},
            },
        );
        example_app.setBuildMode(mode);
        inline for (example.deps) |p| {
            if (std.mem.eql(u8, p.name, freetype.pkg.name))
                freetype.link(example_app.b, example_app.step, .{});
        }
        try example_app.link(options);
        example_app.install();

        const example_compile_step = b.step("example-" ++ example.name, "Compile '" ++ example.name ++ "' example");
        example_compile_step.dependOn(&example_app.getInstallStep().?.step);

        const example_run_cmd = try example_app.run();
        example_run_cmd.dependOn(example_compile_step);
        const example_run_step = b.step("run-example-" ++ example.name, "Run '" ++ example.name ++ "' example");
        example_run_step.dependOn(example_run_cmd);
    }

    const compile_all = b.step("compile-all", "Compile all examples and applications");
    compile_all.dependOn(b.getInstallStep());
}

const Packages = struct {
    // Declared here because submodule may not be cloned at the time build.zig runs.
    const zmath = Pkg{
        .name = "zmath",
        .source = .{ .path = "examples/libs/zmath/src/zmath.zig" },
    };
    const zigimg = Pkg{
        .name = "zigimg",
        .source = .{ .path = "examples/libs/zigimg/zigimg.zig" },
    };
};

fn testStep(b: *Builder, mode: std.builtin.Mode, target: CrossTarget) *std.build.RunStep {
    const main_tests = b.addTestExe("mach-tests", "src/main.zig");
    main_tests.setBuildMode(mode);
    main_tests.setTarget(target);
    main_tests.addPackage(pkg);
    main_tests.addPackage(gpu.pkg);
    main_tests.addPackage(glfw.pkg);
    main_tests.install();

    return main_tests.run();
}

fn buildSharedLib(b: *Builder, mode: std.builtin.Mode, target: CrossTarget, options: Options) !*std.build.LibExeObjStep {
    const lib = b.addSharedLibrary("mach", "src/platform/libmach.zig", .unversioned);
    lib.setTarget(target);
    lib.setBuildMode(mode);
    lib.main_pkg_path = "src/";
    const app_pkg = Pkg{
        .name = "app",
        .source = .{ .path = "src/platform/libmach.zig" },
    };
    lib.addPackage(app_pkg);
    lib.addPackage(glfw.pkg);
    lib.addPackage(gpu.pkg);
    lib.addPackage(sysaudio.pkg);
    if (target.isLinux()) {
        lib.addPackage(gamemode.pkg);
        gamemode.link(lib);
    }
    try glfw.link(b, lib, options.glfw_options);
    try gpu.link(b, lib, options.gpuOptions());
    lib.setOutputDir("libmach/build");
    return lib;
}

const web_install_dir = std.build.InstallDir{ .custom = "www" };

pub const App = struct {
    b: *Builder,
    name: []const u8,
    step: *std.build.LibExeObjStep,
    platform: Platform,
    res_dirs: ?[]const []const u8,
    watch_paths: ?[]const []const u8,

    pub const InitError = std.zig.system.NativeTargetInfo.DetectError;
    pub const LinkError = glfw.LinkError;
    pub const RunError = error{
        ParsingIpFailed,
    } || wasmserve.Error || std.fmt.ParseIntError;

    pub const Platform = enum {
        native,
        web,

        pub fn fromTarget(target: std.Target) Platform {
            if (target.cpu.arch == .wasm32) return .web;
            return .native;
        }
    };

    pub fn init(b: *Builder, options: struct {
        name: []const u8,
        src: []const u8,
        target: CrossTarget,
        deps: ?[]const Pkg = null,
        res_dirs: ?[]const []const u8 = null,
        watch_paths: ?[]const []const u8 = null,
    }) InitError!App {
        const target = (try std.zig.system.NativeTargetInfo.detect(options.target)).target;
        const platform = Platform.fromTarget(target);

        var deps = std.ArrayList(Pkg).init(b.allocator);
        try deps.append(pkg);
        try deps.append(gpu.pkg);
        try deps.append(sysaudio.pkg);
        switch (platform) {
            .native => try deps.append(glfw.pkg),
            .web => try deps.append(sysjs.pkg),
        }
        if (options.deps) |app_deps| try deps.appendSlice(app_deps);

        const app_pkg = Pkg{
            .name = "app",
            .source = .{ .path = options.src },
            .dependencies = deps.toOwnedSlice(),
        };

        const step = blk: {
            if (platform == .web) {
                const lib = b.addSharedLibrary(options.name, sdkPath("/src/platform/wasm.zig"), .unversioned);
                lib.addPackage(gpu.pkg);
                lib.addPackage(sysaudio.pkg);
                lib.addPackage(sysjs.pkg);

                break :blk lib;
            } else {
                const exe = b.addExecutable(options.name, sdkPath("/src/platform/native.zig"));
                exe.addPackage(gpu.pkg);
                exe.addPackage(sysaudio.pkg);
                exe.addPackage(glfw.pkg);

                if (target.os.tag == .linux)
                    exe.addPackage(gamemode.pkg);

                break :blk exe;
            }
        };

        step.main_pkg_path = sdkPath("/src");
        step.addPackage(app_pkg);
        step.setTarget(options.target);

        return .{
            .b = b,
            .step = step,
            .name = options.name,
            .platform = platform,
            .res_dirs = options.res_dirs,
            .watch_paths = options.watch_paths,
        };
    }

    pub fn link(app: *const App, options: Options) LinkError!void {
        if (app.platform != .web) {
            try glfw.link(app.b, app.step, options.glfw_options);
            gpu.link(app.b, app.step, options.gpuOptions()) catch return error.FailedToLinkGPU;
            if (app.step.target.isLinux())
                gamemode.link(app.step);
        }
        sysaudio.link(app.b, app.step, options.sysaudio_options);
    }

    pub fn install(app: *const App) void {
        app.step.install();

        // Install additional files (src/mach.js and template.html)
        // in case of wasm
        if (app.platform == .web) {
            // Set install directory to '{prefix}/www'
            app.getInstallStep().?.dest_dir = web_install_dir;

            inline for (.{ "/src/platform/mach.js", "/libs/sysjs/src/mach-sysjs.js" }) |js| {
                const install_js = app.b.addInstallFileWithDir(
                    .{ .path = sdkPath(js) },
                    web_install_dir,
                    std.fs.path.basename(js),
                );
                app.getInstallStep().?.step.dependOn(&install_js.step);
            }

            const html_generator = app.b.addExecutable("html-generator", sdkPath("/tools/html-generator/main.zig"));
            const run_html_generator = html_generator.run();
            const html_file_name = std.mem.concat(
                app.b.allocator,
                u8,
                &.{ app.name, ".html" },
            ) catch unreachable;
            defer app.b.allocator.free(html_file_name);
            run_html_generator.addArgs(&.{ html_file_name, app.name });

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

    pub fn run(app: *const App) RunError!*std.build.Step {
        if (app.platform == .web) {
            const address = std.process.getEnvVarOwned(app.b.allocator, "MACH_ADDRESS") catch try app.b.allocator.dupe(u8, "127.0.0.1");
            const port = std.process.getEnvVarOwned(app.b.allocator, "MACH_PORT") catch try app.b.allocator.dupe(u8, "8080");
            const address_parsed = std.net.Address.parseIp4(address, try std.fmt.parseInt(u16, port, 10)) catch return error.ParsingIpFailed;
            const install_step_name = if (std.mem.startsWith(u8, app.step.name, "example-"))
                app.step.name
            else
                null;
            const serve_step = try wasmserve.serve(
                app.step,
                .{
                    .install_step_name = install_step_name,
                    .install_dir = web_install_dir,
                    .watch_paths = app.watch_paths,
                    .listen_address = address_parsed,
                },
            );
            return &serve_step.step;
        } else {
            return &app.step.run().step;
        }
    }

    pub fn setBuildMode(app: *const App, mode: std.builtin.Mode) void {
        app.step.setBuildMode(mode);
    }

    pub fn getInstallStep(app: *const App) ?*std.build.InstallArtifactStep {
        return app.step.install_step;
    }
};

fn ensureExamplesDependencySubmodules(allocator: std.mem.Allocator) !void {
    // TODO(build-system): https://github.com/hexops/mach/issues/229#issuecomment-1100958939
    ensureGit(allocator);
    try ensureDependencySubmodule(allocator, "examples/libs/zmath");
    try ensureDependencySubmodule(allocator, "examples/libs/zigimg");
    try ensureDependencySubmodule(allocator, "examples/gkurve/assets");
    try ensureDependencySubmodule(allocator, "examples/image-blur/assets");
    try ensureDependencySubmodule(allocator, "examples/textured-cube/assets");
    try ensureDependencySubmodule(allocator, "examples/cubemap/assets");
}

fn ensureDependencySubmodule(allocator: std.mem.Allocator, path: []const u8) !void {
    if (std.process.getEnvVarOwned(allocator, "NO_ENSURE_SUBMODULES")) |no_ensure_submodules| {
        defer allocator.free(no_ensure_submodules);
        if (std.mem.eql(u8, no_ensure_submodules, "true")) return;
    } else |_| {}
    var child = std.ChildProcess.init(&.{ "git", "submodule", "update", "--init", path }, allocator);
    child.cwd = sdkPath("/");
    child.stderr = std.io.getStdErr();
    child.stdout = std.io.getStdOut();

    _ = try child.spawnAndWait();
}

fn ensureGit(allocator: std.mem.Allocator) void {
    const result = std.ChildProcess.exec(.{
        .allocator = allocator,
        .argv = &.{ "git", "--version" },
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

fn sdkPath(comptime suffix: []const u8) []const u8 {
    if (suffix[0] != '/') @compileError("suffix must be an absolute path");
    return comptime blk: {
        const root_dir = std.fs.path.dirname(@src().file) orelse ".";
        break :blk root_dir ++ suffix;
    };
}
