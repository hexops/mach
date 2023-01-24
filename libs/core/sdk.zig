const std = @import("std");

pub fn Sdk(comptime deps: anytype) type {
    return struct {
        pub const pkg = std.build.Pkg{
            .name = "core",
            .source = .{ .path = sdkPath("/src/main.zig") },
            .dependencies = &.{deps.gpu.pkg},
        };

        pub const Options = struct {
            glfw_options: deps.glfw.Options = .{},
            gpu_dawn_options: deps.gpu_dawn.Options = .{},

            pub fn gpuOptions(options: Options) deps.gpu.Options {
                return .{
                    .gpu_dawn_options = options.gpu_dawn_options,
                };
            }
        };

        pub fn testStep(b: *std.build.Builder, mode: std.builtin.Mode, target: std.zig.CrossTarget) *std.build.RunStep {
            const main_tests = b.addTestExe("core-tests", "src/main.zig");
            main_tests.setBuildMode(mode);
            main_tests.setTarget(target);
            for (pkg.dependencies.?) |dependency| {
                main_tests.addPackage(dependency);
            }
            main_tests.install();
            return main_tests.run();
        }

        pub fn buildSharedLib(b: *std.build.Builder, mode: std.builtin.Mode, target: std.zig.CrossTarget, options: Options) !*std.build.LibExeObjStep {
            // TODO(build): this should use the App abstraction instead of being built manually
            const lib = b.addSharedLibrary("machcore", "src/platform/libmachcore.zig", .unversioned);
            lib.setTarget(target);
            lib.setBuildMode(mode);
            lib.main_pkg_path = "src/";
            const app_pkg = std.build.Pkg{
                .name = "app",
                .source = .{ .path = "src/platform/libmachcore.zig" },
            };
            lib.addPackage(app_pkg);
            lib.addPackage(deps.glfw.pkg);
            lib.addPackage(deps.gpu.pkg);
            if (target.isLinux()) {
                lib.addPackage(deps.gamemode.pkg);
                deps.gamemode.link(lib);
            }
            try deps.glfw.link(b, lib, options.glfw_options);
            try deps.gpu.link(b, lib, options.gpuOptions());
            return lib;
        }

        fn sdkPath(comptime suffix: []const u8) []const u8 {
            if (suffix[0] != '/') @compileError("suffix must be an absolute path");
            return comptime blk: {
                const root_dir = std.fs.path.dirname(@src().file) orelse ".";
                break :blk root_dir ++ suffix;
            };
        }

        pub const App = struct {
            b: *std.build.Builder,
            name: []const u8,
            step: *std.build.LibExeObjStep,
            platform: Platform,
            res_dirs: ?[]const []const u8,
            watch_paths: ?[]const []const u8,

            const web_install_dir = std.build.InstallDir{ .custom = "www" };

            pub const InitError = error{OutOfMemory} || std.zig.system.NativeTargetInfo.DetectError;
            pub const LinkError = deps.glfw.LinkError;
            pub const RunError = error{
                ParsingIpFailed,
            } || deps.wasmserve.Error || std.fmt.ParseIntError;

            pub const Platform = enum {
                native,
                web,

                pub fn fromTarget(target: std.Target) Platform {
                    if (target.cpu.arch == .wasm32) return .web;
                    return .native;
                }
            };

            pub fn init(
                b: *std.build.Builder,
                options: struct {
                    name: []const u8,
                    src: []const u8,
                    target: std.zig.CrossTarget,
                    mode: std.builtin.Mode,
                    deps: ?[]const std.build.Pkg = null,
                    res_dirs: ?[]const []const u8 = null,
                    watch_paths: ?[]const []const u8 = null,
                },
            ) InitError!App {
                const target = (try std.zig.system.NativeTargetInfo.detect(options.target)).target;
                const platform = Platform.fromTarget(target);

                var dependencies = std.ArrayList(std.build.Pkg).init(b.allocator);
                try dependencies.append(pkg);
                try dependencies.append(deps.gpu.pkg);
                switch (platform) {
                    .native => try dependencies.append(deps.glfw.pkg),
                    .web => try dependencies.append(deps.sysjs.pkg),
                }
                if (options.deps) |app_deps| try dependencies.appendSlice(app_deps);

                const app_pkg = std.build.Pkg{
                    .name = "app",
                    .source = .{ .path = options.src },
                    .dependencies = try dependencies.toOwnedSlice(),
                };

                const step = blk: {
                    if (platform == .web) {
                        const lib = b.addSharedLibrary(options.name, sdkPath("/src/main.zig"), .unversioned);
                        lib.rdynamic = true;
                        lib.addPackage(deps.sysjs.pkg);

                        break :blk lib;
                    } else {
                        const exe = b.addExecutable(options.name, sdkPath("/src/main.zig"));
                        exe.addPackage(deps.glfw.pkg);

                        if (target.os.tag == .linux)
                            exe.addPackage(deps.gamemode.pkg);

                        break :blk exe;
                    }
                };

                step.main_pkg_path = sdkPath("/src");
                step.addPackage(deps.gpu.pkg);
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
                    try deps.glfw.link(app.b, app.step, options.glfw_options);
                    deps.gpu.link(app.b, app.step, options.gpuOptions()) catch return error.FailedToLinkGPU;
                    if (app.step.target.isLinux())
                        deps.gamemode.link(app.step);
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
                    const serve_step = try deps.wasmserve.serve(
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
    };
}
