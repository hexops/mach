const std = @import("std");
const builtin = @import("builtin");
const glfw = @import("mach_glfw");

pub const SysgpuBackend = enum {
    default,
    webgpu,
    d3d12,
    metal,
    vulkan,
    opengl,
};

/// Examples:
///
/// `zig build` -> builds all of Mach
/// `zig build test` -> runs all tests
///
/// ## (optional) minimal dependency fetching
///
/// By default, all Mach dependencies will be added to the build. If you only depend on a specific
/// part of Mach, then you can opt to have only the dependencies you need fetched as part of the
/// build:
///
/// ```
/// b.dependency("mach", .{
///   .target = target,
///   .optimize = optimize,
///   .core = true,
///   .sysaudio = true,
/// });
/// ```
///
/// The presense of `.core = true` and `.sysaudio = true` indicate Mach should add the dependencies
/// required by `@import("mach").core` and `@import("mach").sysaudio` to the build. You can use this
/// option with the following:
///
/// * core (also implies sysgpu)
/// * sysaudio
/// * sysgpu
///
/// Note that Zig's dead code elimination and, more importantly, lazy code evaluation means that
/// you really only pay for the parts of `@import("mach")` that you use/reference.
pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const sysgpu_backend = b.option(SysgpuBackend, "sysgpu_backend", "sysgpu API backend") orelse .default;
    const core_platform = b.option(CoreApp.Platform, "core_platform", "mach core platform to use") orelse CoreApp.Platform.fromTarget(target.result);

    const build_examples = b.option(bool, "examples", "build/install examples specifically");
    const build_libs = b.option(bool, "libs", "build/install libraries specifically");
    const build_mach = b.option(bool, "mach", "build mach specifically");
    const build_core = b.option(bool, "core", "build core specifically");
    const build_sysaudio = b.option(bool, "sysaudio", "build sysaudio specifically");
    const build_sysgpu = b.option(bool, "sysgpu", "build sysgpu specifically");
    const build_all = build_examples == null and build_libs == null and build_mach == null and build_core == null and build_sysaudio == null and build_sysgpu == null;

    const want_examples = build_all or (build_examples orelse false);
    const want_libs = build_all or (build_libs orelse false);
    const want_mach = build_all or (build_mach orelse false);
    const want_core = build_all or want_mach or (build_core orelse false);
    const want_sysaudio = build_all or want_mach or (build_sysaudio orelse false);
    const want_sysgpu = build_all or want_mach or want_core or (build_sysgpu orelse false);

    const build_options = b.addOptions();
    build_options.addOption(bool, "want_mach", want_mach);
    build_options.addOption(bool, "want_core", want_core);
    build_options.addOption(bool, "want_sysaudio", want_sysaudio);
    build_options.addOption(bool, "want_sysgpu", want_sysgpu);
    build_options.addOption(SysgpuBackend, "sysgpu_backend", sysgpu_backend);
    build_options.addOption(CoreApp.Platform, "core_platform", core_platform);

    const module = b.addModule("mach", .{
        .root_source_file = .{ .path = "src/main.zig" },
        .optimize = optimize,
        .target = target,
    });
    module.addImport("build-options", build_options.createModule());

    if ((want_mach or want_core or want_sysaudio) and target.result.cpu.arch == .wasm32) {
        if (b.lazyDependency("mach_sysjs", .{
            .target = target,
            .optimize = optimize,
        })) |dep| module.addImport("mach-sysjs", dep.module("mach-sysjs"));
    }

    if (want_mach) {
        // Linux gamemode requires libc.
        if (target.result.os.tag == .linux) module.link_libc = true;

        if (target.result.cpu.arch != .wasm32) {
            if (b.lazyDependency("mach_freetype", .{
                .target = target,
                .optimize = optimize,
            })) |dep| {
                module.addImport("mach-freetype", dep.module("mach-freetype"));
                module.addImport("mach-harfbuzz", dep.module("mach-harfbuzz"));
            }

            if (b.lazyDependency("mach_opus", .{
                .target = target,
                .optimize = optimize,
            })) |dep| {
                module.addImport("mach-opus", dep.module("mach-opus"));
            }
        }
        if (b.lazyDependency("font_assets", .{})) |dep| module.addImport("font-assets", dep.module("font-assets"));

        if (want_examples) try buildExamples(b, optimize, target, module);
    }
    if (want_core) {
        if (target.result.cpu.arch != .wasm32) {
            // TODO: for some reason this is not functional, a Zig bug (only when using this Zig package
            // externally):
            //
            // module.addCSourceFile(.{ .file = .{ .path = sdkPath("src/core/platform/wayland/wayland.c" } });
            //
            // error: unable to check cache: stat file '/Volumes/data/hexops/mach-core-starter-project/zig-cache//Volumes/data/hexops/mach-core-starter-project/src/core/platform/wayland/wayland.c' failed: FileNotFound
            //
            // So instead we do this:
            const lib = b.addStaticLibrary(.{
                .name = "core-wayland",
                .target = target,
                .optimize = optimize,
            });
            lib.addCSourceFile(.{
                .file = .{ .path = "src/core/platform/wayland/wayland.c" },
            });
            lib.linkLibC();
            module.linkLibrary(lib);

            if (b.lazyDependency("mach_glfw", .{
                .target = target,
                .optimize = optimize,
            })) |dep| module.addImport("mach-glfw", dep.module("mach-glfw"));
            if (b.lazyDependency("x11_headers", .{
                .target = target,
                .optimize = optimize,
            })) |dep| {
                module.linkLibrary(dep.artifact("x11-headers"));
                lib.linkLibrary(dep.artifact("x11-headers"));
            }
            if (b.lazyDependency("wayland_headers", .{
                .target = target,
                .optimize = optimize,
            })) |dep| {
                module.linkLibrary(dep.artifact("wayland-headers"));
                lib.linkLibrary(dep.artifact("wayland-headers"));
            }
        }
        if (want_examples) try buildCoreExamples(b, optimize, target, module, core_platform);
    }
    if (want_sysaudio) {
        // Can build sysaudio examples if desired, then.
        if (target.result.cpu.arch != .wasm32) {
            if (want_examples) {
                inline for ([_][]const u8{
                    "sine",
                    "record",
                }) |example| {
                    const example_exe = b.addExecutable(.{
                        .name = "sysaudio-" ++ example,
                        .root_source_file = .{ .path = "src/sysaudio/examples/" ++ example ++ ".zig" },
                        .target = target,
                        .optimize = optimize,
                    });
                    example_exe.root_module.addImport("mach", module);
                    addPaths(&example_exe.root_module);
                    // b.installArtifact(example_exe);

                    const example_compile_step = b.step("sysaudio-" ++ example, "Compile 'sysaudio-" ++ example ++ "' example");
                    example_compile_step.dependOn(b.getInstallStep());

                    const example_run_cmd = b.addRunArtifact(example_exe);
                    example_run_cmd.step.dependOn(b.getInstallStep());
                    if (b.args) |args| example_run_cmd.addArgs(args);

                    const example_run_step = b.step("run-sysaudio-" ++ example, "Run '" ++ example ++ "' example");
                    example_run_step.dependOn(&example_run_cmd.step);
                }
            }
            if (b.lazyDependency("mach_objc", .{
                .target = target,
                .optimize = optimize,
            })) |dep| module.addImport("objc", dep.module("mach-objc"));
        }

        if (target.result.isDarwin()) {
            // Transitive dependencies, explicit linkage of these works around
            // ziglang/zig#17130
            module.linkSystemLibrary("objc", .{});
            module.linkFramework("CoreImage", .{});
            module.linkFramework("CoreVideo", .{});

            // Direct dependencies
            module.linkFramework("AudioToolbox", .{});
            module.linkFramework("CoreFoundation", .{});
            module.linkFramework("CoreAudio", .{});
        }
        if (target.result.os.tag == .linux) {
            module.link_libc = true;

            // TODO: for some reason this is not functional, a Zig bug (only when using this Zig package
            // externally):
            //
            // module.addCSourceFile(.{
            //     .file = .{ .path = "src/sysaudio/pipewire/sysaudio.c" },
            //     .flags = &.{"-std=gnu99"},
            // });
            //
            // error: unable to check cache: stat file '/Volumes/data/hexops/mach-flac/zig-cache//Volumes/data/hexops/mach-flac/src/pipewire/sysaudio.c' failed: FileNotFound
            //
            // So instead we do this:
            const lib = b.addStaticLibrary(.{
                .name = "sysaudio-pipewire",
                .target = target,
                .optimize = optimize,
            });
            lib.linkLibC();
            lib.addCSourceFile(.{
                .file = .{ .path = "src/sysaudio/pipewire/sysaudio.c" },
                .flags = &.{"-std=gnu99"},
            });
            module.linkLibrary(lib);

            if (b.lazyDependency("linux_audio_headers", .{
                .target = target,
                .optimize = optimize,
            })) |dep| {
                module.linkLibrary(dep.artifact("linux-audio-headers"));
                lib.linkLibrary(dep.artifact("linux-audio-headers"));
            }
        }
    }
    if (want_sysgpu) {
        if (b.lazyDependency("vulkan_zig_generated", .{})) |dep| module.addImport("vulkan", dep.module("vulkan-zig-generated"));
        if (b.lazyDependency("mach_objc", .{
            .target = target,
            .optimize = optimize,
        })) |dep| module.addImport("objc", dep.module("mach-objc"));
        linkSysgpu(b, module);

        if (want_libs) {
            const lib = b.addStaticLibrary(.{
                .name = "mach-sysgpu",
                .root_source_file = b.addWriteFiles().add("empty.c", ""),
                .target = target,
                .optimize = optimize,
            });
            var iter = module.import_table.iterator();
            while (iter.next()) |e| {
                lib.root_module.addImport(e.key_ptr.*, e.value_ptr.*);
            }
            linkSysgpu(b, &lib.root_module);
            addPaths(&lib.root_module);
            b.installArtifact(lib);
        }
    }

    if (true) { // want_gpu
        if (b.lazyDependency("mach_gpu_dawn", .{
            .target = target,
            .optimize = optimize,
        })) |dep| {
            _ = dep;
            const gpu_dawn = @import("mach_gpu_dawn");
            gpu_dawn.addPathsToModule(b, module, .{});
            module.addIncludePath(.{ .path = sdkPath("/src/gpu") });
        }

        if (want_examples) {
            const example_exe = b.addExecutable(.{
                .name = "dawn-gpu-hello-triangle",
                .root_source_file = .{ .path = "src/gpu/example/main.zig" },
                .target = target,
                .optimize = optimize,
            });
            example_exe.root_module.addImport("mach", module);
            link(b, example_exe);

            if (b.lazyDependency("mach_glfw", .{
                .target = target,
                .optimize = optimize,
            })) |dep| example_exe.root_module.addImport("mach-glfw", dep.module("mach-glfw"));

            const example_compile_step = b.step("dawn-gpu-hello-triangle", "Install 'dawn-gpu-hello-triangle'");
            example_compile_step.dependOn(b.getInstallStep());

            const example_run_cmd = b.addRunArtifact(example_exe);
            example_run_cmd.step.dependOn(b.getInstallStep());
            if (b.args) |args| example_run_cmd.addArgs(args);

            const example_run_step = b.step("run-dawn-gpu-hello-triangle", "Run 'dawn-gpu-hello-triangle' example");
            example_run_step.dependOn(&example_run_cmd.step);
        }
    }

    if (target.result.cpu.arch != .wasm32) {
        // Creates a step for unit testing. This only builds the test executable
        // but does not run it.
        const unit_tests = b.addTest(.{
            .root_source_file = .{ .path = "src/main.zig" },
            .target = target,
            .optimize = optimize,
        });
        var iter = module.import_table.iterator();
        while (iter.next()) |e| {
            unit_tests.root_module.addImport(e.key_ptr.*, e.value_ptr.*);
        }
        addPaths(&unit_tests.root_module);
        link(b, unit_tests);

        // Linux gamemode requires libc.
        if (target.result.os.tag == .linux) unit_tests.root_module.link_libc = true;

        // Exposes a `test` step to the `zig build --help` menu, providing a way for the user to
        // request running the unit tests.
        const run_unit_tests = b.addRunArtifact(unit_tests);
        const test_step = b.step("test", "Run unit tests");
        test_step.dependOn(&run_unit_tests.step);

        if (want_sysgpu) linkSysgpu(b, &unit_tests.root_module);
    }
}

pub const CoreApp = struct {
    b: *std.Build,
    name: []const u8,
    module: *std.Build.Module,
    compile: *std.Build.Step.Compile,
    install: *std.Build.Step.InstallArtifact,
    run: *std.Build.Step.Run,
    platform: Platform,
    res_dirs: ?[]const []const u8,
    watch_paths: ?[]const []const u8,

    pub const Platform = enum {
        glfw,
        x11,
        wayland,
        web,

        pub fn fromTarget(target: std.Target) Platform {
            if (target.cpu.arch == .wasm32) return .web;
            return .glfw;
        }
    };

    pub fn init(
        app_builder: *std.Build,
        mach_builder: *std.Build,
        options: struct {
            name: []const u8,
            src: []const u8,
            target: std.Build.ResolvedTarget,
            optimize: std.builtin.OptimizeMode,
            custom_entrypoint: ?[]const u8 = null,
            deps: ?[]const std.Build.Module.Import = null,
            res_dirs: ?[]const []const u8 = null,
            watch_paths: ?[]const []const u8 = null,
            mach_mod: ?*std.Build.Module = null,
            platform: ?Platform = null,
        },
    ) !CoreApp {
        const target = options.target.result;
        const platform = options.platform orelse Platform.fromTarget(target);

        var imports = std.ArrayList(std.Build.Module.Import).init(app_builder.allocator);

        const mach_mod = options.mach_mod orelse app_builder.dependency("mach", .{
            .target = options.target,
            .optimize = options.optimize,
        }).module("mach");
        try imports.append(.{
            .name = "mach",
            .module = mach_mod,
        });

        if (options.deps) |app_deps| try imports.appendSlice(app_deps);

        const app_module = app_builder.createModule(.{
            .root_source_file = .{ .path = options.src },
            .imports = try imports.toOwnedSlice(),
        });

        // Tell mach about the chosen platform
        const platform_options = app_builder.addOptions();
        platform_options.addOption(Platform, "platform", platform);
        mach_mod.addOptions("platform_options", platform_options);

        const compile = blk: {
            if (platform == .web) {
                // wasm libraries should go into zig-out/www/
                app_builder.lib_dir = app_builder.fmt("{s}/www", .{app_builder.install_path});

                const lib = app_builder.addStaticLibrary(.{
                    .name = options.name,
                    .root_source_file = .{ .path = options.custom_entrypoint orelse sdkPath("/src/core/platform/wasm/entrypoint.zig") },
                    .target = options.target,
                    .optimize = options.optimize,
                });
                lib.rdynamic = true;

                break :blk lib;
            } else {
                const exe = app_builder.addExecutable(.{
                    .name = options.name,
                    .root_source_file = .{ .path = options.custom_entrypoint orelse sdkPath("/src/core/platform/native_entrypoint.zig") },
                    .target = options.target,
                    .optimize = options.optimize,
                });
                // TODO(core): figure out why we need to disable LTO: https://github.com/hexops/mach/issues/597
                exe.want_lto = false;

                break :blk exe;
            }
        };

        compile.root_module.addImport("mach", mach_mod);
        compile.root_module.addImport("app", app_module);

        // Installation step
        const install = app_builder.addInstallArtifact(compile, .{});
        if (options.res_dirs) |res_dirs| {
            for (res_dirs) |res| {
                const install_res = app_builder.addInstallDirectory(.{
                    .source_dir = .{ .path = res },
                    .install_dir = install.dest_dir.?,
                    .install_subdir = std.fs.path.basename(res),
                    .exclude_extensions = &.{},
                });
                install.step.dependOn(&install_res.step);
            }
        }
        if (platform == .web) {
            inline for (.{ sdkPath("/src/core/platform/wasm/mach.js"), @import("mach_sysjs").getJSPath() }) |js| {
                const install_js = app_builder.addInstallFileWithDir(
                    .{ .path = js },
                    std.Build.InstallDir{ .custom = "www" },
                    std.fs.path.basename(js),
                );
                install.step.dependOn(&install_js.step);
            }
        }

        // Link dependencies
        if (platform != .web) {
            link(mach_builder, compile);
        }

        const run = app_builder.addRunArtifact(compile);
        run.step.dependOn(&install.step);
        return .{
            .b = app_builder,
            .module = app_module,
            .compile = compile,
            .install = install,
            .run = run,
            .name = options.name,
            .platform = platform,
            .res_dirs = options.res_dirs,
            .watch_paths = options.watch_paths,
        };
    }
};

// TODO(sysgpu): remove this once we switch to sysgpu fully
pub fn link(mach_builder: *std.Build, step: *std.Build.Step.Compile) void {
    const target = step.root_module.resolved_target.?.result;
    if (target.cpu.arch == .wasm32) return;

    if (mach_builder.lazyDependency("mach_gpu_dawn", .{
        .target = step.root_module.resolved_target.?,
        .optimize = step.root_module.optimize.?,
    })) |dep| {
        _ = dep;
        const gpu_dawn = @import("mach_gpu_dawn");
        const Options = struct {
            gpu_dawn_options: gpu_dawn.Options = .{},
        };
        const options: Options = .{};

        gpu_dawn.link(
            mach_builder,
            step,
            &step.root_module,
            options.gpu_dawn_options,
        );
        step.addCSourceFile(.{ .file = .{ .path = sdkPath("/src/gpu/mach_dawn.cpp") }, .flags = &.{"-std=c++17"} });
        step.addIncludePath(.{ .path = sdkPath("/src/gpu") });
    }
}

fn linkSysgpu(b: *std.Build, module: *std.Build.Module) void {
    const resolved_target = module.resolved_target orelse b.host;
    const target = resolved_target.result;
    if (target.cpu.arch != .wasm32) module.link_libc = true;
    if (target.isDarwin()) {
        module.linkSystemLibrary("objc", .{});
        module.linkFramework("AppKit", .{});
        module.linkFramework("CoreGraphics", .{});
        module.linkFramework("Foundation", .{});
        module.linkFramework("Metal", .{});
        module.linkFramework("QuartzCore", .{});
    }
    if (target.os.tag == .windows) {
        module.linkSystemLibrary("d3d12", .{});
        module.linkSystemLibrary("d3dcompiler_47", .{});
        module.linkSystemLibrary("opengl32", .{});
        if (b.lazyDependency("direct3d_headers", .{
            .target = resolved_target,
            .optimize = module.optimize.?,
        })) |dep| {
            module.linkLibrary(dep.artifact("direct3d-headers"));
            @import("direct3d_headers").addLibraryPathToModule(module);
        }
        if (b.lazyDependency("opengl_headers", .{
            .target = resolved_target,
            .optimize = module.optimize.?,
        })) |dep| module.linkLibrary(dep.artifact("opengl-headers"));
    }
    if (target.cpu.arch != .wasm32) {
        // TODO: spirv-cross / spirv-tools support
        // if (b.lazyDependency("spirv_cross", .{
        //     .target = resolved_target,
        //     .optimize = module.optimize.?,
        // })) |dep| module.linkLibrary(dep.artifact("spirv-cross"));
        // if (b.lazyDependency("spirv_tools", .{
        //     .target = resolved_target,
        //     .optimize = module.optimize.?,
        // })) |dep| module.linkLibrary(dep.artifact("spirv-opt"));
    }
}

pub fn addPaths(mod: *std.Build.Module) void {
    if (mod.resolved_target.?.result.isDarwin()) @import("xcode_frameworks").addPaths(mod);
}

fn sdkPath(comptime suffix: []const u8) []const u8 {
    if (suffix[0] != '/') @compileError("suffix must be an absolute path");
    return comptime blk: {
        const root_dir = std.fs.path.dirname(@src().file) orelse ".";
        break :blk root_dir ++ suffix;
    };
}

comptime {
    const supported_zig = std.SemanticVersion.parse("0.12.0-dev.3180+83e578a18") catch unreachable;
    if (builtin.zig_version.order(supported_zig) != .eq) {
        @compileError(std.fmt.comptimePrint("unsupported Zig version ({}). Required Zig version 2024.3.0-mach: https://machengine.org/about/nominated-zig/#202430-mach", .{builtin.zig_version}));
    }
}

fn buildExamples(
    b: *std.Build,
    optimize: std.builtin.OptimizeMode,
    target: std.Build.ResolvedTarget,
    mach_mod: *std.Build.Module,
) !void {
    const Dependency = enum {
        assets,
        model3d,
        freetype,
        zigimg,
    };

    for ([_]struct {
        name: []const u8,
        deps: []const Dependency = &.{},
        wasm: bool = false,
        has_assets: bool = false,
    }{
        .{ .name = "hardware-check", .deps = &.{ .assets, .zigimg } },
        .{ .name = "core-custom-entrypoint", .deps = &.{} },
        .{ .name = "custom-renderer", .deps = &.{} },
        .{ .name = "glyphs", .deps = &.{ .freetype, .assets } },
        .{ .name = "piano", .deps = &.{} },
        .{ .name = "play-opus", .deps = &.{.assets} },
        .{ .name = "sprite", .deps = &.{ .zigimg, .assets } },
        .{ .name = "text", .deps = &.{.assets} },
    }) |example| {
        if (target.result.cpu.arch == .wasm32 and !example.wasm) continue;
        const exe = b.addExecutable(.{
            .name = example.name,
            .root_source_file = .{ .path = b.fmt("examples/{s}/main.zig", .{example.name}) },
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.addImport("mach", mach_mod);
        addPaths(&exe.root_module);
        link(b, exe);
        b.installArtifact(exe);

        for (example.deps) |d| {
            switch (d) {
                .assets => {
                    if (b.lazyDependency("mach_example_assets", .{
                        .target = target,
                        .optimize = optimize,
                    })) |dep| exe.root_module.addImport("assets", dep.module("mach-example-assets"));
                },
                .model3d => {
                    if (b.lazyDependency("mach_model3d", .{
                        .target = target,
                        .optimize = optimize,
                    })) |dep| exe.root_module.addImport("model3d", dep.module("mach-model3d"));
                },
                .freetype => {
                    if (b.lazyDependency("mach_freetype", .{
                        .target = target,
                        .optimize = optimize,
                    })) |dep| exe.root_module.addImport("freetype", dep.module("mach-freetype"));
                },
                .zigimg => {
                    if (b.lazyDependency("zigimg", .{
                        .target = target,
                        .optimize = optimize,
                    })) |dep| exe.root_module.addImport("zigimg", dep.module("zigimg"));
                },
            }
        }

        const compile_step = b.step(example.name, b.fmt("Compile {s}", .{example.name}));
        compile_step.dependOn(b.getInstallStep());

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| run_cmd.addArgs(args);

        const run_step = b.step(b.fmt("run-{s}", .{example.name}), b.fmt("Run {s}", .{example.name}));
        run_step.dependOn(&run_cmd.step);
    }
}

fn buildCoreExamples(
    b: *std.Build,
    optimize: std.builtin.OptimizeMode,
    target: std.Build.ResolvedTarget,
    mach_mod: *std.Build.Module,
    platform: CoreApp.Platform,
) !void {
    const Dependency = enum {
        zigimg,
        model3d,
        assets,
        zmath,
    };

    inline for ([_]struct {
        name: []const u8,
        deps: []const Dependency = &.{},
        std_platform_only: bool = false,
        sysgpu: bool = false,
    }{
        .{ .name = "wasm-test", .deps = &.{.zmath} },
        .{ .name = "triangle", .deps = &.{.zmath} },
        .{ .name = "triangle-msaa", .deps = &.{.zmath} },
        .{ .name = "clear-color", .deps = &.{.zmath} },
        .{ .name = "procedural-primitives", .deps = &.{.zmath} },
        .{ .name = "boids", .deps = &.{.zmath} },
        .{ .name = "rotating-cube", .deps = &.{.zmath} },
        .{ .name = "pixel-post-process", .deps = &.{.zmath} },
        .{ .name = "two-cubes", .deps = &.{.zmath} },
        .{ .name = "instanced-cube", .deps = &.{.zmath} },
        .{ .name = "gen-texture-light", .deps = &.{.zmath} },
        .{ .name = "fractal-cube", .deps = &.{.zmath} },
        .{ .name = "map-async", .deps = &.{.zmath} },
        .{ .name = "rgb-quad", .deps = &.{.zmath} },
        .{
            .name = "pbr-basic",
            .deps = &.{ .zmath, .model3d, .assets },
            .std_platform_only = true,
        },
        .{
            .name = "deferred-rendering",
            .deps = &.{ .zmath, .model3d, .assets },
            .std_platform_only = true,
        },
        .{ .name = "textured-cube", .deps = &.{ .zmath, .zigimg, .assets } },
        .{ .name = "textured-quad", .deps = &.{ .zmath, .zigimg, .assets } },
        .{ .name = "sprite2d", .deps = &.{ .zmath, .zigimg, .assets } },
        .{ .name = "image", .deps = &.{ .zmath, .zigimg, .assets } },
        .{ .name = "image-blur", .deps = &.{ .zmath, .zigimg, .assets } },
        .{ .name = "cubemap", .deps = &.{ .zmath, .zigimg, .assets } },

        // sysgpu
        .{ .name = "boids", .deps = &.{.zmath}, .sysgpu = true },
        .{ .name = "clear-color", .deps = &.{.zmath}, .sysgpu = true },
        .{ .name = "cubemap", .deps = &.{ .zmath, .zigimg, .assets }, .sysgpu = true },
        .{ .name = "deferred-rendering", .deps = &.{ .zmath, .model3d, .assets }, .std_platform_only = true, .sysgpu = true },
        .{ .name = "fractal-cube", .deps = &.{.zmath}, .sysgpu = true },
        .{ .name = "gen-texture-light", .deps = &.{.zmath}, .sysgpu = true },
        .{ .name = "image-blur", .deps = &.{ .zmath, .zigimg, .assets }, .sysgpu = true },
        .{ .name = "instanced-cube", .deps = &.{.zmath}, .sysgpu = true },
        .{ .name = "map-async", .deps = &.{.zmath}, .sysgpu = true },
        .{ .name = "pbr-basic", .deps = &.{ .zmath, .model3d, .assets }, .std_platform_only = true, .sysgpu = true },
        .{ .name = "pixel-post-process", .deps = &.{.zmath}, .sysgpu = true },
        .{ .name = "procedural-primitives", .deps = &.{.zmath}, .sysgpu = true },
        .{ .name = "rotating-cube", .deps = &.{.zmath}, .sysgpu = true },
        .{ .name = "sprite2d", .deps = &.{ .zmath, .zigimg, .assets }, .sysgpu = true },
        .{ .name = "image", .deps = &.{ .zmath, .zigimg, .assets }, .sysgpu = true },
        .{ .name = "textured-cube", .deps = &.{ .zmath, .zigimg, .assets }, .sysgpu = true },
        .{ .name = "textured-quad", .deps = &.{ .zmath, .zigimg, .assets }, .sysgpu = true },
        .{ .name = "triangle", .deps = &.{.zmath}, .sysgpu = true },
        .{ .name = "triangle-msaa", .deps = &.{.zmath}, .sysgpu = true },
        .{ .name = "two-cubes", .deps = &.{.zmath}, .sysgpu = true },
        .{ .name = "rgb-quad", .deps = &.{.zmath}, .sysgpu = true },
    }) |example| {
        // FIXME: this is workaround for a problem that some examples
        // (having the std_platform_only=true field) as well as zigimg
        // uses IO and depends on gpu-dawn which is not supported
        // in freestanding environments. So break out of this loop
        // as soon as any such examples is found. This does means that any
        // example which works on wasm should be placed before those who dont.
        if (example.std_platform_only)
            if (target.result.cpu.arch == .wasm32)
                break;

        const cmd_name = if (example.sysgpu) "sysgpu-" ++ example.name else example.name;
        const app = try CoreApp.init(
            b,
            b,
            .{
                .name = "core-" ++ cmd_name,
                .src = if (example.sysgpu)
                    "src/core/examples/sysgpu/" ++ example.name ++ "/main.zig"
                else
                    "src/core/examples/" ++ example.name ++ "/main.zig",
                .target = target,
                .optimize = optimize,
                .watch_paths = if (example.sysgpu)
                    &.{"src/core/examples/sysgpu/" ++ example.name}
                else
                    &.{"src/core/examples/" ++ example.name},
                .mach_mod = mach_mod,
                .platform = platform,
            },
        );

        for (example.deps) |d| {
            switch (d) {
                .zigimg => {
                    if (b.lazyDependency("zigimg", .{
                        .target = target,
                        .optimize = optimize,
                    })) |dep| app.module.addImport("zigimg", dep.module("zigimg"));
                },
                .model3d => {
                    if (b.lazyDependency("mach_model3d", .{
                        .target = target,
                        .optimize = optimize,
                    })) |dep| app.module.addImport("model3d", dep.module("mach-model3d"));
                },
                .assets => {
                    if (b.lazyDependency("mach_example_assets", .{
                        .target = target,
                        .optimize = optimize,
                    })) |dep| app.module.addImport("assets", dep.module("mach-example-assets"));
                },
                .zmath => {
                    const zmath = b.createModule(.{
                        .root_source_file = .{ .path = "src/core/examples/zmath.zig" },
                    });
                    app.module.addImport("zmath", zmath);
                },
            }
        }

        const install_step = b.step("core-" ++ cmd_name, "Install core-" ++ cmd_name);
        install_step.dependOn(&app.install.step);

        const run_step = b.step("run-core-" ++ cmd_name, "Run core-" ++ cmd_name);
        run_step.dependOn(&app.run.step);
    }
}
