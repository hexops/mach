const std = @import("std");
const builtin = @import("builtin");
const system_sdk = @import("libs/glfw/system_sdk.zig");
const glfw = @import("libs/glfw/build.zig");
const ecs = @import("libs/ecs/build.zig");
const freetype = @import("libs/freetype/build.zig");
const basisu = @import("libs/basisu/build.zig");
const sysjs = @import("libs/sysjs/build.zig");
const earcut = @import("libs/earcut/build.zig");
const gamemode = @import("libs/gamemode/build.zig");
const model3d = @import("libs/model3d/build.zig");
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

var cached_pkg: ?Pkg = null;

pub fn pkg(b: *Builder) Pkg {
    if (cached_pkg == null) {
        const dependencies = b.allocator.create([4]Pkg) catch unreachable;
        dependencies.* = .{
            gpu.pkg(b),
            ecs.pkg(b),
            sysaudio.pkg(b),
            earcut.pkg(b),
        };

        cached_pkg = .{
            .name = "mach",
            .source = .{ .path = sdkPath(b, "/src/main.zig") },
            .dependencies = dependencies,
        };
    }

    return cached_pkg.?;
}

pub const Options = struct {
    glfw_options: glfw.Options = .{},
    gpu_dawn_options: gpu_dawn.Options = .{},
    sysaudio_options: sysaudio.Options = .{},
    freetype_options: freetype.Options = .{},

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
        const model3d_test_step = b.step("test-model3d", "Run Model3D library tests");
        const mach_test_step = b.step("test-mach", "Run Mach Core library tests");

        glfw_test_step.dependOn(&(try glfw.testStep(b, mode, target)).step);
        gpu_test_step.dependOn(&(try gpu.testStep(b, mode, target, options.gpuOptions())).step);
        freetype_test_step.dependOn(&freetype.testStep(b, mode, target).step);
        ecs_test_step.dependOn(&ecs.testStep(b, mode, target).step);
        basisu_test_step.dependOn(&basisu.testStep(b, mode, target).step);
        sysaudio_test_step.dependOn(&sysaudio.testStep(b, mode, target).step);
        model3d_test_step.dependOn(&model3d.testStep(b, mode, target).step);
        mach_test_step.dependOn(&testStep(b, mode, target).step);

        all_tests_step.dependOn(glfw_test_step);
        all_tests_step.dependOn(gpu_test_step);
        all_tests_step.dependOn(ecs_test_step);
        all_tests_step.dependOn(basisu_test_step);
        all_tests_step.dependOn(freetype_test_step);
        all_tests_step.dependOn(sysaudio_test_step);
        all_tests_step.dependOn(model3d_test_step);
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
                .mode = mode,
            },
        );
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

    const compile_all = b.step("compile-all", "Compile Mach");
    compile_all.dependOn(b.getInstallStep());
}

fn testStep(b: *Builder, mode: std.builtin.Mode, target: CrossTarget) *std.build.RunStep {
    const main_tests = b.addTestExe("mach-tests", "src/main.zig");
    main_tests.setBuildMode(mode);
    main_tests.setTarget(target);

    for (pkg(b).dependencies.?) |dependency| {
        main_tests.addPackage(dependency);
    }

    main_tests.addPackage(freetype.pkg(b));
    freetype.link(b, main_tests, .{});

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
    lib.addPackage(glfw.pkg(b));
    lib.addPackage(gpu.pkg(b));
    lib.addPackage(sysaudio.pkg(b));
    if (target.isLinux()) {
        lib.addPackage(gamemode.pkg(b));
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
    use_freetype: ?[]const u8 = null,
    use_model3d: bool = false,

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

            /// If set, freetype will be linked and can be imported using this name.
            // TODO(build-system): name is currently not used / always "freetype"
            use_freetype: ?[]const u8 = null,
            use_model3d: bool = false,
        },
    ) InitError!App {
        const target = (try std.zig.system.NativeTargetInfo.detect(options.target)).target;
        const platform = Platform.fromTarget(target);

        var deps = std.ArrayList(Pkg).init(b.allocator);
        try deps.append(pkg(b));
        try deps.append(gpu.pkg(b));
        try deps.append(sysaudio.pkg(b));
        switch (platform) {
            .native => try deps.append(glfw.pkg(b)),
            .web => try deps.append(sysjs.pkg(b)),
        }
        if (options.use_freetype) |_| try deps.append(freetype.pkg(b));
        if (options.deps) |app_deps| try deps.appendSlice(app_deps);

        const app_pkg = Pkg{
            .name = "app",
            .source = .{ .path = options.src },
            .dependencies = try deps.toOwnedSlice(),
        };

        const step = blk: {
            if (platform == .web) {
                const lib = b.addSharedLibrary(options.name, sdkPath(b, "/src/platform/wasm.zig"), .unversioned);
                lib.addPackage(gpu.pkg(b));
                lib.addPackage(sysaudio.pkg(b));
                lib.addPackage(sysjs.pkg(b));

                break :blk lib;
            } else {
                const exe = b.addExecutable(options.name, sdkPath(b, "/src/platform/native.zig"));
                exe.addPackage(gpu.pkg(b));
                exe.addPackage(sysaudio.pkg(b));
                exe.addPackage(glfw.pkg(b));

                if (target.os.tag == .linux)
                    exe.addPackage(gamemode.pkg(b));

                break :blk exe;
            }
        };

        step.main_pkg_path = sdkPath(b, "/src");
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
            .use_freetype = options.use_freetype,
            .use_model3d = options.use_model3d,
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
        if (app.use_freetype) |_| freetype.link(app.b, app.step, options.freetype_options);
        if (app.use_model3d) {
            model3d.link(app.b, app.step, app.step.target);
        }
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
                    .{ .path = sdkPath(app.b, js) },
                    web_install_dir,
                    std.fs.path.basename(js),
                );
                app.getInstallStep().?.step.dependOn(&install_js.step);
            }

            const html_generator = app.b.addExecutable("html-generator", sdkPath(app.b, "/tools/html-generator/main.zig"));
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

const unresolved_dir = (struct {
    inline fn unresolvedDir() []const u8 {
        return comptime std.fs.path.dirname(@src().file) orelse ".";
    }
}).unresolvedDir();

fn thisDir(allocator: std.mem.Allocator) []const u8 {
    if (comptime unresolved_dir[0] == '/') {
        return unresolved_dir;
    }

    const cached_dir = &(struct {
        var cached_dir: ?[]const u8 = null;
    }).cached_dir;

    if (cached_dir.* == null) {
        cached_dir.* = std.fs.cwd().realpathAlloc(allocator, unresolved_dir) catch unreachable;
    }

    return cached_dir.*.?;
}

inline fn sdkPath(b: *Builder, comptime suffix: []const u8) []const u8 {
    return sdkPathAllocator(b.allocator, suffix);
}

inline fn sdkPathAllocator(allocator: std.mem.Allocator, comptime suffix: []const u8) []const u8 {
    return sdkPathInternal(allocator, suffix.len, suffix[0..suffix.len].*);
}

fn sdkPathInternal(allocator: std.mem.Allocator, comptime len: usize, comptime suffix: [len]u8) []const u8 {
    if (suffix[0] != '/') @compileError("suffix must be an absolute path");

    if (comptime unresolved_dir[0] == '/') {
        return unresolved_dir ++ @as([]const u8, &suffix);
    }

    const cached_dir = &(struct {
        var cached_dir: ?[]const u8 = null;
    }).cached_dir;

    if (cached_dir.* == null) {
        cached_dir.* = std.fs.path.resolve(allocator, &.{ thisDir(allocator), suffix[1..] }) catch unreachable;
    }

    return cached_dir.*.?;
}
