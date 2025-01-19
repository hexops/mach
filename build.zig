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

    var examples = [_]Example{
        .{ .name = "core-custom-entrypoint", .deps = &.{} },
        .{ .name = "core-triangle", .deps = &.{} },
        .{ .name = "core-transparent-window", .deps = &.{} },
        .{ .name = "custom-renderer", .deps = &.{} },
        .{ .name = "glyphs", .deps = &.{ .assets, .freetype } },
        .{ .name = "hardware-check", .deps = &.{ .assets, .zigimg } },
        .{ .name = "piano", .deps = &.{} },
        .{ .name = "play-opus", .deps = &.{.assets} },
        .{ .name = "sprite", .deps = &.{ .zigimg, .assets } },
        .{ .name = "text", .deps = &.{.assets} },
    };

    var sysaudio_tests = [_]SysAudioTest{
        .{ .name = "record" },
        .{ .name = "sine" },
    };

    // Setup Steps
    const docs_step = b.step("docs", "Generate docs");
    for (&examples) |*example| {
        example.run_step = b.step(
            b.fmt("run-{s}", .{example.name}),
            b.fmt("Run example: {s}", .{example.name}),
        );
    }
    const test_step = b.step("test", "Test Run: Unit Tests");
    for (&sysaudio_tests) |*sysaudio_test| {
        sysaudio_test.run_step = b.step(
            b.fmt("test-sysaudio-{s}", .{sysaudio_test.name}),
            b.fmt("Test Run: sysaudio {s}", .{sysaudio_test.name}),
        );
    }

    const module = b.addModule("mach", .{
        .root_source_file = b.path("src/main.zig"),
        .optimize = optimize,
        .target = target,
    });
    module.addImport("build-options", build_options.createModule());

    buildExamples(
        b,
        optimize,
        target,
        module,
        &examples,
    );

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

        if (want_examples) {
            for (examples) |example| b.getInstallStep().dependOn(example.install_step);
        }
    }
    if (want_core) {
        if (target.result.os.tag == .linux) {
            module.addCSourceFile(.{
                .file = b.path("src/core/linux/wayland.c"),
            });
        }
        linkCore(b, module);
    }
    if (want_sysaudio) {
        linkSysaudio(b, module);
        if (target.result.os.tag == .linux) {
            module.addCSourceFile(.{
                .file = b.path("src/sysaudio/pipewire/sysaudio.c"),
                .flags = &.{"-std=gnu99"},
            });
        }
        if (target.result.cpu.arch != .wasm32) {
            for (&sysaudio_tests) |*sysaudio_test| {
                const test_exe = b.addExecutable(.{
                    .name = b.fmt("sysaudio-{s}", .{sysaudio_test.name}),
                    .root_source_file = b.path(b.fmt("src/sysaudio/tests/{s}.zig", .{sysaudio_test.name})),
                    .target = target,
                    .optimize = optimize,
                });
                test_exe.root_module.addImport("mach", module);

                const run_cmd = b.addRunArtifact(test_exe);
                if (b.args) |args| run_cmd.addArgs(args);

                sysaudio_test.run_step.dependOn(&run_cmd.step);
            }
        }
    }
    if (want_sysgpu) {
        linkSysgpu(b, module);
        if (b.lazyDependency("vulkan_zig_generated", .{})) |dep| module.addImport("vulkan", dep.module("vulkan-zig-generated"));
        if (target.result.isDarwin()) {
            if (b.lazyDependency("mach_objc", .{
                .target = target,
                .optimize = optimize,
            })) |dep| module.addImport("objc", dep.module("mach-objc"));
        }
        if (want_libs) {
            // TODO(build): make this 'libmach' and test the build of this in CI.
            const lib = b.addStaticLibrary(.{
                .name = "mach-sysgpu",
                .root_source_file = b.path("src/main.zig"),
                .target = target,
                .optimize = optimize,
            });
            var iter = module.import_table.iterator();
            while (iter.next()) |e| {
                lib.root_module.addImport(e.key_ptr.*, e.value_ptr.*);
            }
            linkSysgpu(b, lib.root_module);
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

        // Linux gamemode requires libc.
        if (target.result.os.tag == .linux) unit_tests.root_module.link_libc = true;

        // Exposes a `test` step to the `zig build --help` menu, providing a way for the user to
        // request running the unit tests.
        const run_unit_tests = b.addRunArtifact(unit_tests);
        test_step.dependOn(&run_unit_tests.step);

        if (want_sysgpu) linkSysgpu(b, unit_tests.root_module);
        if (want_core) linkCore(b, unit_tests.root_module);
        if (want_sysaudio) linkSysaudio(b, unit_tests.root_module);

        // Documentation
        const docs_obj = b.addObject(.{
            .name = "mach",
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = .Debug,
        });
        //docs_obj.root_module.addOptions("build_options", build_options);
        const docs = docs_obj.getEmittedDocs();
        const install_docs = b.addInstallDirectory(.{
            .source_dir = docs,
            .install_dir = .prefix,
            .install_subdir = "docs",
        });
        docs_step.dependOn(&install_docs.step);
    }
}

pub const Platform = enum {
    wasm,
    linux,
    windows,
    darwin,
    null,

    pub fn fromTarget(target: std.Target) Platform {
        if (target.cpu.arch == .wasm32) return .wasm;
        if (target.os.tag.isDarwin()) return .darwin;
        if (target.os.tag == .windows) return .windows;
        if (target.os.tag == .linux) return .linux;
        return .null;
    }
};

/// Links the system libraries, macOS frameworks, etc. that are needed to build sysgpu.
fn linkSysgpu(b: *std.Build, module: *std.Build.Module) void {
    const target = module.resolved_target orelse @panic("module must have .target specified");
    const optimize = module.optimize orelse @panic("module must have .optimize specified");

    if (target.result.os.tag == .linux) {
        module.link_libc = true;
    } else if (target.result.isDarwin()) {
        module.linkFramework("CoreGraphics", .{});
        module.linkFramework("Foundation", .{});
        module.linkFramework("Metal", .{});
        module.linkFramework("QuartzCore", .{});

        if (b.lazyDependency("xcode_frameworks", .{
            .target = target,
            .optimize = optimize,
        })) |dep| {
            module.addSystemFrameworkPath(dep.path("Frameworks"));
            module.addSystemIncludePath(dep.path("include"));
            module.addLibraryPath(dep.path("lib"));
        }
    } else if (target.result.os.tag == .windows) {
        // TODO(build): Windows should never link OpenGL except in debug builds.
        module.linkSystemLibrary("dxgi", .{});
        module.linkSystemLibrary("d3d12", .{});
        module.linkSystemLibrary("d3dcompiler_47", .{});
        module.linkSystemLibrary("opengl32", .{});

        if (b.lazyDependency("directx_headers", .{
            .target = target,
            .optimize = optimize,
        })) |dep| module.linkLibrary(dep.artifact("directx-headers"));
        if (b.lazyDependency("opengl_headers", .{
            .target = target,
            .optimize = optimize,
        })) |dep| module.linkLibrary(dep.artifact("opengl-headers"));
    }
}

/// Links the system libraries, macOS frameworks, etc. that are needed to build core.
fn linkCore(b: *std.Build, module: *std.Build.Module) void {
    const target = module.resolved_target orelse @panic("module must have .target specified");
    const optimize = module.optimize orelse @panic("module must have .optimize specified");

    if (target.result.os.tag == .linux) {
        if (b.lazyDependency("wayland_headers", .{
            .target = target,
            .optimize = optimize,
        })) |dep| {
            module.addIncludePath(dep.path("libdecor"));
            module.addIncludePath(dep.path("wayland"));
            module.addIncludePath(dep.path("wayland-protocols"));
        }
        if (b.lazyDependency("x11_headers", .{
            .target = target,
            .optimize = optimize,
        })) |dep| {
            module.linkLibrary(dep.artifact("x11-headers"));
        }
    } else if (target.result.isDarwin()) {
        if (target.result.os.tag == .macos) {
            module.linkFramework("AppKit", .{});
        } else {
            module.linkFramework("UIKit", .{});
        }
        module.linkFramework("CoreGraphics", .{});
        module.linkFramework("Foundation", .{});
        module.linkFramework("Metal", .{});
        module.linkFramework("QuartzCore", .{});

        if (b.lazyDependency("xcode_frameworks", .{
            .target = target,
            .optimize = optimize,
        })) |dep| {
            module.addSystemFrameworkPath(dep.path("Frameworks"));
            module.addSystemIncludePath(dep.path("include"));
            module.addLibraryPath(dep.path("lib"));
        }
        if (b.lazyDependency("mach_objc", .{
            .target = target,
            .optimize = optimize,
        })) |dep| module.addImport("objc", dep.module("mach-objc"));
    }
}

/// Links the system libraries, macOS frameworks, etc. that are needed to build sysaudio.
fn linkSysaudio(b: *std.Build, module: *std.Build.Module) void {
    const target = module.resolved_target orelse @panic("module must have .target specified");
    const optimize = module.optimize orelse @panic("module must have .optimize specified");

    if (target.result.os.tag == .linux) {
        module.link_libc = true;

        if (b.lazyDependency("linux_audio_headers", .{
            .target = target,
            .optimize = optimize,
        })) |dep| {
            module.linkLibrary(dep.artifact("linux-audio-headers"));
        }
    } else if (target.result.isDarwin()) {
        module.linkFramework("AudioToolbox", .{});
        module.linkFramework("CoreFoundation", .{});
        module.linkFramework("CoreAudio", .{});

        if (b.lazyDependency("xcode_frameworks", .{
            .target = target,
            .optimize = optimize,
        })) |dep| {
            module.addSystemFrameworkPath(dep.path("Frameworks"));
            module.addSystemIncludePath(dep.path("include"));
            module.addLibraryPath(dep.path("lib"));
        }
    }
}

const Dependency = enum {
    assets,
    freetype,
    zigimg,
};

const Example = struct {
    name: []const u8,
    deps: []const Dependency = &.{},

    install_step: *std.Build.Step = undefined,
    run_step: *std.Build.Step = undefined,
};

fn buildExamples(
    b: *std.Build,
    optimize: std.builtin.OptimizeMode,
    target: std.Build.ResolvedTarget,
    mach_mod: *std.Build.Module,
    examples: []Example,
) void {
    for (examples) |*example| {
        const exe = b.addExecutable(.{
            .name = example.name,
            .root_source_file = b.path(b.fmt("examples/{s}/main.zig", .{example.name})),
            .target = target,
            .optimize = optimize,
            .win32_manifest = b.path("src/core/windows/win32.manifest"),
        });
        exe.root_module.addImport("mach", mach_mod);

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

        const run_cmd = b.addRunArtifact(exe);
        if (b.args) |args| run_cmd.addArgs(args);

        const installArtifact = b.addInstallArtifact(exe, .{});
        example.install_step = &installArtifact.step;
        run_cmd.step.dependOn(&installArtifact.step);
        example.run_step.dependOn(&run_cmd.step);
    }
}

const SysAudioTest = struct {
    name: []const u8,
    run_step: *std.Build.Step = undefined,
};

comptime {
    const supported_zig = std.SemanticVersion.parse("0.14.0-dev.2577+271452d22") catch unreachable;
    if (builtin.zig_version.order(supported_zig) != .eq) {
        @compileError(std.fmt.comptimePrint("unsupported Zig version ({}). Required Zig version 2024.11.0-mach: https://machengine.org/docs/zig-version/", .{builtin.zig_version}));
    }
}
