const std = @import("std");
const builtin = @import("builtin");
const glfw = @import("libs/mach-glfw/build.zig");
const gpu_dawn = @import("libs/mach-gpu-dawn/build.zig").Sdk(.{
    // TODO(build-system): This cannot be imported with the Zig package manager
    // error: TarUnsupportedFileType
    .xcode_frameworks = @import("libs/mach-gpu-dawn/libs/xcode-frameworks/build.zig"),
});
const gpu = @import("libs/mach-gpu/build.zig").Sdk(.{
    .gpu_dawn = gpu_dawn,
});
const core = @import("build.zig").Sdk(.{
    .gpu = gpu,
    .gpu_dawn = gpu_dawn,
    .glfw = glfw,
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

        // Compiles the `libmachcore` shared library
        const shared_lib = try core.buildSharedLib(b, optimize, target, options);

        b.installArtifact(shared_lib);
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

pub fn Sdk(comptime deps: anytype) type {
    return struct {
        pub const Options = struct {
            glfw_options: deps.glfw.Options = .{},
            gpu_dawn_options: deps.gpu_dawn.Options = .{},

            pub fn gpuOptions(options: Options) deps.gpu.Options {
                return .{
                    .gpu_dawn_options = options.gpu_dawn_options,
                };
            }
        };

        var _module: ?*std.build.Module = null;

        pub fn module(b: *std.Build) *std.build.Module {
            if (_module) |m| return m;

            const gamemode_dep = b.dependency("mach_gamemode", .{});

            _module = b.createModule(.{
                .source_file = .{ .path = sdkPath("/src/main.zig") },
                .dependencies = &.{
                    .{ .name = "gpu", .module = deps.gpu.module(b) },
                    .{ .name = "glfw", .module = deps.glfw.module(b) },
                    .{ .name = "gamemode", .module = gamemode_dep.module("mach-gamemode") },
                },
            });
            return _module.?;
        }

        pub fn testStep(b: *std.Build, optimize: std.builtin.OptimizeMode, target: std.zig.CrossTarget) !*std.build.RunStep {
            const main_tests = b.addTest(.{
                .name = "core-tests",
                .root_source_file = .{ .path = sdkPath("/src/main.zig") },
                .target = target,
                .optimize = optimize,
            });
            var iter = module(b).dependencies.iterator();
            while (iter.next()) |e| {
                main_tests.addModule(e.key_ptr.*, e.value_ptr.*);
            }
            main_tests.addModule("glfw", deps.glfw.module(b));
            try deps.glfw.link(b, main_tests, .{});
            if (target.isLinux()) {
                const gamemode_dep = b.dependency("mach_gamemode", .{});
                main_tests.addModule("gamemode", gamemode_dep.module("mach-gamemode"));
            }
            main_tests.addIncludePath(sdkPath("/include"));
            b.installArtifact(main_tests);
            return b.addRunArtifact(main_tests);
        }

        pub fn buildSharedLib(b: *std.Build, optimize: std.builtin.OptimizeMode, target: std.zig.CrossTarget, options: Options) !*std.build.CompileStep {
            // TODO(build): this should use the App abstraction instead of being built manually
            const lib = b.addSharedLibrary(.{ .name = "machcore", .root_source_file = .{ .path = "src/platform/libmachcore.zig" }, .target = target, .optimize = optimize });
            lib.main_pkg_path = "src/";
            const app_module = b.createModule(.{
                .source_file = .{ .path = "src/platform/libmachcore_app.zig" },
            });
            lib.addModule("app", app_module);
            lib.addModule("glfw", deps.glfw.module(b));
            lib.addModule("gpu", deps.gpu.module(b));
            if (target.isLinux()) {
                const gamemode_dep = b.dependency("mach_gamemode", .{});
                lib.addModule("gamemode", gamemode_dep.module("mach-gamemode"));
            }
            try deps.glfw.link(b, lib, options.glfw_options);
            try deps.gpu.link(b, lib, options.gpuOptions());
            return lib;
        }

        pub const App = struct {
            b: *std.Build,
            name: []const u8,
            step: *std.build.CompileStep,
            platform: Platform,
            res_dirs: ?[]const []const u8,
            watch_paths: ?[]const []const u8,
            sysjs_dep: ?*std.Build.Dependency,

            const web_install_dir = std.build.InstallDir{ .custom = "www" };

            pub const Platform = enum {
                native,
                web,

                pub fn fromTarget(target: std.Target) Platform {
                    if (target.cpu.arch == .wasm32) return .web;
                    return .native;
                }
            };

            pub fn init(
                b: *std.Build,
                options: struct {
                    name: []const u8,
                    src: []const u8,
                    target: std.zig.CrossTarget,
                    optimize: std.builtin.OptimizeMode,
                    deps: ?[]const std.build.ModuleDependency = null,
                    res_dirs: ?[]const []const u8 = null,
                    watch_paths: ?[]const []const u8 = null,
                },
            ) !App {
                const target = (try std.zig.system.NativeTargetInfo.detect(options.target)).target;
                const platform = Platform.fromTarget(target);

                var dependencies = std.ArrayList(std.build.ModuleDependency).init(b.allocator);
                try dependencies.append(.{ .name = "core", .module = module(b) });
                if (options.deps) |app_deps| try dependencies.appendSlice(app_deps);

                const app_module = b.createModule(.{
                    .source_file = .{ .path = options.src },
                    .dependencies = try dependencies.toOwnedSlice(),
                });

                const sysjs_dep = if (platform == .web) b.dependency("mach_sysjs", .{
                    .target = options.target,
                    .optimize = options.optimize,
                }) else null;

                const step = blk: {
                    if (platform == .web) {
                        const lib = b.addSharedLibrary(.{
                            .name = options.name,
                            .root_source_file = .{ .path = sdkPath("/src/entry.zig") },
                            .target = options.target,
                            .optimize = options.optimize,
                        });
                        lib.rdynamic = true;
                        lib.addModule("sysjs", sysjs_dep.?.module("mach-sysjs"));
                        break :blk lib;
                    } else {
                        const exe = b.addExecutable(.{
                            .name = options.name,
                            .root_source_file = .{ .path = sdkPath("/src/entry.zig") },
                            .target = options.target,
                            .optimize = options.optimize,
                        });
                        // TODO(core): figure out why we need to disable LTO: https://github.com/hexops/mach/issues/597
                        exe.want_lto = false;
                        exe.addModule("glfw", deps.glfw.module(b));

                        if (target.os.tag == .linux) {
                            const gamemode_dep = b.dependency("mach_gamemode", .{});
                            exe.addModule("gamemode", gamemode_dep.module("mach-gamemode"));
                        }

                        break :blk exe;
                    }
                };

                step.main_pkg_path = sdkPath("/src");
                step.addModule("core", module(b));
                step.addModule("app", app_module);

                return .{
                    .b = b,
                    .step = step,
                    .name = options.name,
                    .platform = platform,
                    .res_dirs = options.res_dirs,
                    .watch_paths = options.watch_paths,
                    .sysjs_dep = sysjs_dep,
                };
            }

            pub fn link(app: *const App, options: Options) !void {
                if (app.platform != .web) {
                    try deps.glfw.link(app.b, app.step, options.glfw_options);
                    deps.gpu.link(app.b, app.step, options.gpuOptions()) catch return error.FailedToLinkGPU;
                }
            }

            pub fn install(app: *const App) void {
                app.b.installArtifact(app.step);

                // Install additional files (mach.js and mach-sysjs.js)
                // in case of wasm
                if (app.platform == .web) {
                    // Set install directory to '{prefix}/www'
                    app.getInstallStep().?.dest_dir = web_install_dir;

                    inline for (.{ sdkPath("/src/platform/wasm/mach.js"), @import("mach_sysjs").getJSPath() }) |js| {
                        const install_js = app.b.addInstallFileWithDir(
                            .{ .path = js },
                            web_install_dir,
                            std.fs.path.basename(js),
                        );
                        app.getInstallStep().?.step.dependOn(&install_js.step);
                    }
                }

                // Install resources
                if (app.res_dirs) |res_dirs| {
                    for (res_dirs) |res| {
                        const install_res = app.b.addInstallDirectory(.{
                            .source_dir = .{ .path = res },
                            .install_dir = app.getInstallStep().?.dest_dir,
                            .install_subdir = std.fs.path.basename(res),
                            .exclude_extensions = &.{},
                        });
                        app.getInstallStep().?.step.dependOn(&install_res.step);
                    }
                }
            }

            pub fn addRunArtifact(app: *const App) *std.build.RunStep {
                return app.b.addRunArtifact(app.step);
            }

            pub fn getInstallStep(app: *const App) ?*std.build.InstallArtifactStep {
                return app.b.addInstallArtifact(app.step);
            }
        };
    };
}
