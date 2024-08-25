const std = @import("std");
const builtin = @import("builtin");

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
    const core_platform = b.option(Platform, "core_platform", "mach core platform to use") orelse Platform.fromTarget(target.result);

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
    build_options.addOption(Platform, "core_platform", core_platform);

    const module = b.addModule("mach", .{
        .root_source_file = b.path("src/main.zig"),
        .optimize = optimize,
        .target = target,
    });
    module.addImport("build-options", build_options.createModule());

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
                .optimize = .ReleaseFast,
            })) |dep| {
                module.addImport("mach-opus", dep.module("mach-opus"));
            }
        }
        if (b.lazyDependency("font_assets", .{})) |dep| module.addImport("font-assets", dep.module("font-assets"));

        if (want_examples) try buildExamples(b, optimize, target, module);
    }
    if (want_core) {
        if (target.result.isDarwin()) {
            if (b.lazyDependency("mach_objc", .{
                .target = target,
                .optimize = optimize,
            })) |dep| module.addImport("objc", dep.module("mach-objc"));
        }
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
                        .root_source_file = b.path("src/sysaudio/examples/" ++ example ++ ".zig"),
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
            if (target.result.isDarwin()) {
                if (b.lazyDependency("mach_objc", .{
                    .target = target,
                    .optimize = optimize,
                })) |dep| module.addImport("objc", dep.module("mach-objc"));
            }
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
            //     .file = b.path("src/sysaudio/pipewire/sysaudio.c"),
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
                .file = b.path("src/sysaudio/pipewire/sysaudio.c"),
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
        if (target.result.isDarwin()) {
            if (b.lazyDependency("mach_objc", .{
                .target = target,
                .optimize = optimize,
            })) |dep| module.addImport("objc", dep.module("mach-objc"));
        }

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

    if (target.result.cpu.arch != .wasm32) {
        // Creates a step for unit testing. This only builds the test executable
        // but does not run it.
        const unit_tests = b.addTest(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        });
        var iter = module.import_table.iterator();
        while (iter.next()) |e| {
            unit_tests.root_module.addImport(e.key_ptr.*, e.value_ptr.*);
        }
        addPaths(&unit_tests.root_module);

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

pub const Platform = enum {
    wasm,
    win32,
    darwin,
    null,

    pub fn fromTarget(target: std.Target) Platform {
        if (target.cpu.arch == .wasm32) return .wasm;
        if (target.os.tag.isDarwin()) return .darwin;
        if (target.os.tag == .windows) return .win32;
        return .null;
    }
};

fn linkSysgpu(b: *std.Build, module: *std.Build.Module) void {
    const resolved_target = module.resolved_target orelse b.host;
    const target = resolved_target.result;
    if (target.cpu.arch != .wasm32) module.link_libc = true;
    if (target.isDarwin()) {
        module.linkSystemLibrary("objc", .{});
        if (target.os.tag == .macos) {
            module.linkFramework("AppKit", .{});
        } else {
            module.linkFramework("UIKit", .{});
        }
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

fn buildExamples(
    b: *std.Build,
    optimize: std.builtin.OptimizeMode,
    target: std.Build.ResolvedTarget,
    mach_mod: *std.Build.Module,
) !void {
    const Dependency = enum {
        assets,
        freetype,
        zigimg,
    };

    for ([_]struct {
        core: bool = false,
        name: []const u8,
        deps: []const Dependency = &.{},
        has_assets: bool = false,
    }{
        // Mach core examples
        .{ .core = true, .name = "custom-entrypoint", .deps = &.{} },
        .{ .core = true, .name = "triangle", .deps = &.{} },

        // Mach engine examples
        .{ .name = "hardware-check", .deps = &.{ .assets, .zigimg } },
        .{ .name = "custom-renderer", .deps = &.{} },
        .{ .name = "glyphs", .deps = &.{ .freetype, .assets } },
        .{ .name = "piano", .deps = &.{} },
        .{ .name = "play-opus", .deps = &.{.assets} },
        .{ .name = "sprite", .deps = &.{ .zigimg, .assets } },
        .{ .name = "text", .deps = &.{.assets} },
    }) |example| {
        const exe = b.addExecutable(.{
            .name = if (example.core) b.fmt("core-{s}", .{example.name}) else example.name,
            .root_source_file = if (example.core)
                b.path(b.fmt("examples/core/{s}/main.zig", .{example.name}))
            else
                b.path(b.fmt("examples/{s}/main.zig", .{example.name})),
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.addImport("mach", mach_mod);
        addPaths(&exe.root_module);
        b.installArtifact(exe);

        for (example.deps) |d| {
            switch (d) {
                .assets => {
                    if (b.lazyDependency("mach_example_assets", .{
                        .target = target,
                        .optimize = optimize,
                    })) |dep| exe.root_module.addImport("assets", dep.module("mach-example-assets"));
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

comptime {
    const supported_zig = std.SemanticVersion.parse("0.13.0-dev.351+64ef45eb0") catch unreachable;
    if (builtin.zig_version.order(supported_zig) != .eq) {
        @compileError(std.fmt.comptimePrint("unsupported Zig version ({}). Required Zig version 2024.5.0-mach: https://machengine.org/about/nominated-zig/#202450-mach", .{builtin.zig_version}));
    }
}
