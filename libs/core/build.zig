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
const CrossTarget = std.zig.CrossTarget;
const Builder = std.build.Builder;
const Pkg = std.build.Pkg;

pub const pkg = Pkg{
    .name = "core",
    .source = .{ .path = sdkPath("/src/main.zig") },
    .dependencies = &.{ gpu.pkg },
};

pub const Options = struct {
    glfw_options: glfw.Options = .{},
    gpu_dawn_options: gpu_dawn.Options = .{},

    pub fn gpuOptions(options: Options) gpu.Options {
        return .{
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
        const mach_test_step = b.step("test-mach", "Run Mach Core library tests");

        glfw_test_step.dependOn(&(try glfw.testStep(b, mode, target)).step);
        gpu_test_step.dependOn(&(try gpu.testStep(b, mode, target, options.gpuOptions())).step);
        mach_test_step.dependOn(&testStep(b, mode, target).step);

        all_tests_step.dependOn(glfw_test_step);
        all_tests_step.dependOn(gpu_test_step);
        all_tests_step.dependOn(mach_test_step);

        // TODO: we need a way to test wasm stuff
        // const sysjs_test_step = b.step( "test-sysjs", "Run sysjs library tests");
        // sysjs_test_step.dependOn(&sysjs.testStep(b, mode, target).step);
        // all_tests_step.dependOn(sysjs_test_step);

        // Compiles the `libmachcore` shared library
        const shared_lib = try buildSharedLib(b, mode, target, options);
        shared_lib.install();
    }

    const compile_all = b.step("compile-all", "Compile Mach");
    compile_all.dependOn(b.getInstallStep());
}

fn testStep(b: *Builder, mode: std.builtin.Mode, target: CrossTarget) *std.build.RunStep {
    const main_tests = b.addTestExe("core-tests", "src/main.zig");
    main_tests.setBuildMode(mode);
    main_tests.setTarget(target);
    for (pkg.dependencies.?) |dependency| {
        main_tests.addPackage(dependency);
    }
    main_tests.install();
    return main_tests.run();
}

fn buildSharedLib(b: *Builder, mode: std.builtin.Mode, target: CrossTarget, options: Options) !*std.build.LibExeObjStep {
    const lib = b.addSharedLibrary("machcore", "src/platform/libmachcore.zig", .unversioned);
    lib.setTarget(target);
    lib.setBuildMode(mode);
    lib.main_pkg_path = "src/";
    const app_pkg = Pkg{
        .name = "app",
        .source = .{ .path = "src/platform/libmachcore.zig" },
    };
    lib.addPackage(app_pkg);
    lib.addPackage(glfw.pkg);
    lib.addPackage(gpu.pkg);
    if (target.isLinux()) {
        lib.addPackage(gamemode.pkg);
        gamemode.link(lib);
    }
    try glfw.link(b, lib, options.glfw_options);
    try gpu.link(b, lib, options.gpuOptions());
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

    pub const InitError = error{OutOfMemory} || std.zig.system.NativeTargetInfo.DetectError;
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

    pub fn init(
        b: *Builder,
        options: struct {
            name: []const u8,
            src: []const u8,
            target: CrossTarget,
            mode: std.builtin.Mode,
            deps: ?[]const Pkg = null,
            res_dirs: ?[]const []const u8 = null,
            watch_paths: ?[]const []const u8 = null,
        },
    ) InitError!App {
        const target = (try std.zig.system.NativeTargetInfo.detect(options.target)).target;
        const platform = Platform.fromTarget(target);

        var deps = std.ArrayList(Pkg).init(b.allocator);
        try deps.append(pkg);
        try deps.append(gpu.pkg);
        switch (platform) {
            .native => try deps.append(glfw.pkg),
            .web => try deps.append(sysjs.pkg),
        }
        if (options.deps) |app_deps| try deps.appendSlice(app_deps);

        const app_pkg = Pkg{
            .name = "app",
            .source = .{ .path = options.src },
            .dependencies = try deps.toOwnedSlice(),
        };

        const step = blk: {
            if (platform == .web) {
                const lib = b.addSharedLibrary(options.name, sdkPath("/src/main.zig"), .unversioned);
                lib.rdynamic = true;
                lib.addPackage(sysjs.pkg);

                break :blk lib;
            } else {
                const exe = b.addExecutable(options.name, sdkPath("/src/main.zig"));
                exe.addPackage(glfw.pkg);

                if (target.os.tag == .linux)
                    exe.addPackage(gamemode.pkg);

                break :blk exe;
            }
        };

        step.main_pkg_path = sdkPath("/src");
        step.addPackage(gpu.pkg);
        step.addPackage(app_pkg);
        step.setTarget(options.target);
        step.setBuildMode(options.mode);

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
    }

    pub fn install(app: *const App) void {
        app.step.install();

        // Install additional files (src/mach.js and template.html)
        // in case of wasm
        if (app.platform == .web) {
            // Set install directory to '{prefix}/www'
            app.getInstallStep().?.dest_dir = web_install_dir;

            inline for (.{ "/src/platform/wasm/mach.js", "/libs/sysjs/src/mach-sysjs.js" }) |js| {
                const install_js = app.b.addInstallFileWithDir(
                    .{ .path = sdkPath(js) },
                    web_install_dir,
                    std.fs.path.basename(js),
                );
                app.getInstallStep().?.step.dependOn(&install_js.step);
            }

            const html_generator = app.b.addExecutable("html-generator", sdkPath("/tools/html-generator/main.zig"));
            const run_html_generator = html_generator.run();
            run_html_generator.addArgs(&.{ "index.html", app.name });

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
            const serve_step = try wasmserve.serve(
                app.step,
                .{
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

    pub fn getInstallStep(app: *const App) ?*std.build.InstallArtifactStep {
        return app.step.install_step;
    }
};

fn sdkPath(comptime suffix: []const u8) []const u8 {
    if (suffix[0] != '/') @compileError("suffix must be an absolute path");
    return comptime blk: {
        const root_dir = std.fs.path.dirname(@src().file) orelse ".";
        break :blk root_dir ++ suffix;
    };
}
