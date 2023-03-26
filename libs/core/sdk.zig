const std = @import("std");

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
            _module = b.createModule(.{
                .source_file = .{ .path = sdkPath("/src/main.zig") },
                .dependencies = &.{
                    .{ .name = "gpu", .module = deps.gpu.module(b) },
                    .{ .name = "glfw", .module = deps.glfw.module(b) },
                    .{ .name = "gamemode", .module = deps.gamemode.module(b) },
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
                main_tests.addModule("gamemode", deps.gamemode.module(b));
                deps.gamemode.link(main_tests);
            }
            main_tests.addIncludePath(sdkPath("/include"));
            main_tests.install();
            return main_tests.run();
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
                lib.addModule("gamemode", deps.gamemode.module(b));
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
            b: *std.Build,
            name: []const u8,
            step: *std.build.CompileStep,
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
            ) InitError!App {
                const target = (try std.zig.system.NativeTargetInfo.detect(options.target)).target;
                const platform = Platform.fromTarget(target);

                var dependencies = std.ArrayList(std.build.ModuleDependency).init(b.allocator);
                try dependencies.append(.{ .name = "core", .module = module(b) });
                if (options.deps) |app_deps| try dependencies.appendSlice(app_deps);

                const app_module = b.createModule(.{
                    .source_file = .{ .path = options.src },
                    .dependencies = try dependencies.toOwnedSlice(),
                });

                const step = blk: {
                    if (platform == .web) {
                        const lib = b.addSharedLibrary(.{
                            .name = options.name,
                            .root_source_file = .{ .path = sdkPath("/src/entry.zig") },
                            .target = options.target,
                            .optimize = options.optimize,
                        });
                        lib.rdynamic = true;
                        lib.addModule("sysjs", deps.sysjs.module(b));

                        break :blk lib;
                    } else {
                        const exe = b.addExecutable(.{
                            .name = options.name,
                            .root_source_file = .{ .path = sdkPath("/src/entry.zig") },
                            .target = options.target,
                            .optimize = options.optimize,
                        });
                        exe.addModule("glfw", deps.glfw.module(b));

                        if (target.os.tag == .linux)
                            exe.addModule("gamemode", deps.gamemode.module(b));

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

                    inline for (.{ "/src/platform/wasm/mach.js", "/libs/mach-sysjs/src/mach-sysjs.js" }) |js| {
                        const install_js = app.b.addInstallFileWithDir(
                            .{ .path = sdkPath(js) },
                            web_install_dir,
                            std.fs.path.basename(js),
                        );
                        app.getInstallStep().?.step.dependOn(&install_js.step);
                    }

                    genHtml(app.b.allocator, app.b.getInstallPath(web_install_dir, "index.html"), app.name) catch |err| {
                        std.log.err("unable to generate html: {s}", .{@errorName(err)});
                    };
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
                        app.b,
                        .{
                            // .step_name =
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

        pub fn genHtml(allocator: std.mem.Allocator, output_name: []const u8, app_name: []const u8) !void {
            const file = try std.fs.cwd().createFile(output_name, .{});
            defer file.close();

            var buf = try std.fmt.allocPrint(allocator, html_template, .{ .app_name = app_name });
            defer allocator.free(buf);

            _ = try file.write(buf);
        }

        const html_template =
            \\<!doctype html>
            \\<html>
            \\
            \\<head>
            \\  <meta charset="utf-8">
            \\  <title>{[app_name]s}</title>
            \\</head>
            \\
            \\<body>
            \\  <script type="module">
            \\    import {{ mach }} from "./mach.js";
            \\    import {{ sysjs }} from "./mach-sysjs.js";
            \\    import setupWasmserve from "./wasmserve.js";
            \\
            \\    setupWasmserve();
            \\
            \\    let imports = {{
            \\      mach,
            \\      sysjs,
            \\    }};
            \\
            \\    fetch("{[app_name]s}.wasm")
            \\      .then(response => response.arrayBuffer())
            \\      .then(buffer => WebAssembly.instantiate(buffer, imports))
            \\      .then(results => results.instance)
            \\      .then(instance => {{
            \\        sysjs.init(instance);
            \\        mach.init(instance);
            \\        instance.exports.wasmInit();
            \\
            \\        let frame = true;
            \\        let last_update_time = performance.now();
            \\        let update = function () {{
            \\          if (!frame) {{
            \\            instance.exports.wasmDeinit();
            \\            return;
            \\          }}
            \\          if (mach.machHasEvent() ||
            \\              last_update_time + mach.wait_timeout * 1000 <= performance.now()) {{
            \\            if (instance.exports.wasmUpdate()) {{
            \\              instance.exports.wasmDeinit();
            \\              return;
            \\            }}
            \\            last_update_time = performance.now();
            \\          }}
            \\          window.requestAnimationFrame(update);
            \\        }};
            \\        window.requestAnimationFrame(update);
            \\      }})
            \\      .catch(err => console.error(err));
            \\  </script>
            \\</body>
            \\
            \\</html>
        ;
    };
}
