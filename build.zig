const std = @import("std");
const builtin = @import("builtin");
const glfw = @import("mach_glfw");
const core = @import("mach_core");

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
    const core_deps = b.option(bool, "core", "build core specifically");
    const sysaudio_deps = b.option(bool, "sysaudio", "build sysaudio specifically");
    const sysgpu_deps = b.option(bool, "sysgpu", "build sysgpu specifically");

    const want_mach = core_deps != null or sysaudio_deps != null or sysgpu_deps != null;
    const want_core = want_mach or (core_deps orelse false);
    const want_sysaudio = want_mach or (sysaudio_deps orelse false);
    const want_sysgpu = want_mach or (sysgpu_deps orelse false);

    const build_options = b.addOptions();
    build_options.addOption(bool, "want_mach", want_mach);
    build_options.addOption(bool, "want_core", want_core);
    build_options.addOption(bool, "want_sysaudio", want_sysaudio);
    build_options.addOption(bool, "want_sysgpu", want_sysgpu);

    const module = b.addModule("mach", .{
        .root_source_file = .{ .path = sdkPath("/src/main.zig") },
        .optimize = optimize,
        .target = target,
    });
    module.addImport("build-options", build_options.createModule());
    if (want_mach) {
        // Linux gamemode requires libc.
        if (target.result.os.tag == .linux) module.link_libc = true;

        // TODO(Zig 2024.03): use b.lazyDependency
        const mach_core_dep = b.dependency("mach_core", .{
            .target = target,
            .optimize = optimize,
        });
        const mach_basisu_dep = b.dependency("mach_basisu", .{
            .target = target,
            .optimize = optimize,
        });
        const mach_freetype_dep = b.dependency("mach_freetype", .{
            .target = target,
            .optimize = optimize,
        });
        const mach_sysjs_dep = b.dependency("mach_sysjs", .{
            .target = target,
            .optimize = optimize,
        });
        const font_assets_dep = b.dependency("font_assets", .{});

        module.addImport("mach-core", mach_core_dep.module("mach-core"));
        module.addImport("mach-basisu", mach_basisu_dep.module("mach-basisu"));
        module.addImport("mach-freetype", mach_freetype_dep.module("mach-freetype"));
        module.addImport("mach-harfbuzz", mach_freetype_dep.module("mach-harfbuzz"));
        module.addImport("mach-sysjs", mach_sysjs_dep.module("mach-sysjs"));
        module.addImport("font-assets", font_assets_dep.module("font-assets"));
    }
    if (want_sysaudio) {
        // Can build sysaudio examples if desired, then.
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
            b.installArtifact(example_exe);

            const example_compile_step = b.step("sysaudio-" ++ example, "Compile 'sysaudio-" ++ example ++ "' example");
            example_compile_step.dependOn(b.getInstallStep());

            const example_run_cmd = b.addRunArtifact(example_exe);
            example_run_cmd.step.dependOn(b.getInstallStep());
            if (b.args) |args| example_run_cmd.addArgs(args);

            const example_run_step = b.step("run-sysaudio-" ++ example, "Run '" ++ example ++ "' example");
            example_run_step.dependOn(&example_run_cmd.step);
        }

        // Add sysaudio dependencies to the module.
        // TODO(Zig 2024.03): use b.lazyDependency
        const mach_sysjs_dep = b.dependency("mach_sysjs", .{
            .target = target,
            .optimize = optimize,
        });
        const mach_objc_dep = b.dependency("mach_objc", .{
            .target = target,
            .optimize = optimize,
        });
        module.addImport("sysjs", mach_sysjs_dep.module("mach-sysjs"));
        module.addImport("objc", mach_objc_dep.module("mach-objc"));

        if (target.result.isDarwin()) {
            // Transitive dependencies, explicit linkage of these works around
            // ziglang/zig#17130
            module.linkSystemLibrary("objc", .{});

            // Direct dependencies
            module.linkFramework("AudioToolbox", .{});
            module.linkFramework("CoreFoundation", .{});
            module.linkFramework("CoreAudio", .{});
        }
        if (target.result.os.tag == .linux) {
            // TODO(Zig 2024.03): use b.lazyDependency
            const linux_audio_headers_dep = b.dependency("linux_audio_headers", .{
                .target = target,
                .optimize = optimize,
            });
            module.link_libc = true;
            module.linkLibrary(linux_audio_headers_dep.artifact("linux-audio-headers"));

            // TODO: for some reason this is not functional, a Zig bug (only when using this Zig package
            // externally):
            //
            // module.addCSourceFile(.{
            //     .file = .{ .path = "src/pipewire/sysaudio.c" },
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
                .file = .{ .path = "src/pipewire/sysaudio.c" },
                .flags = &.{"-std=gnu99"},
            });
            lib.linkLibrary(linux_audio_headers_dep.artifact("linux-audio-headers"));
            module.linkLibrary(lib);
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

        // Exposes a `test` step to the `zig build --help` menu, providing a way for the user to
        // request running the unit tests.
        const run_unit_tests = b.addRunArtifact(unit_tests);
        const test_step = b.step("test", "Run unit tests");
        test_step.dependOn(&run_unit_tests.step);

        // TODO: autodoc segfaults the build if we have this enabled
        // https://github.com/hexops/mach/issues/1145
        //
        // const install_docs = b.addInstallDirectory(.{
        //     .source_dir = unit_tests.getEmittedDocs(),
        //     .install_dir = .prefix, // default build output prefix, ./zig-out
        //     .install_subdir = "docs",
        // });
        // const docs_step = b.step("docs", "Generate API docs");
        // docs_step.dependOn(&install_docs.step);
    }
}

pub const App = struct {
    b: *std.Build,
    mach_builder: *std.Build,
    name: []const u8,
    compile: *std.Build.Step.Compile,
    install: *std.Build.Step.InstallArtifact,
    run: *std.Build.Step.Run,
    platform: core.App.Platform,
    core: core.App,

    pub fn init(
        app_builder: *std.Build,
        options: struct {
            name: []const u8,
            src: []const u8,
            target: std.Build.ResolvedTarget,
            optimize: std.builtin.OptimizeMode,
            custom_entrypoint: ?[]const u8 = null,
            deps: ?[]const std.Build.Module.Import = null,
            res_dirs: ?[]const []const u8 = null,
            watch_paths: ?[]const []const u8 = null,
            mach_builder: ?*std.Build = null,
            mach_mod: ?*std.Build.Module = null,
        },
    ) !App {
        const mach_builder = options.mach_builder orelse app_builder.dependency("mach", .{
            .target = options.target,
            .optimize = options.optimize,
        }).builder;
        const mach_mod = options.mach_mod orelse app_builder.dependency("mach", .{
            .target = options.target,
            .optimize = options.optimize,
        }).module("mach");

        var deps = std.ArrayList(std.Build.Module.Import).init(app_builder.allocator);
        if (options.deps) |v| try deps.appendSlice(v);
        try deps.append(.{ .name = "mach", .module = mach_mod });

        const mach_core_dep = mach_builder.dependency("mach_core", .{
            .target = options.target,
            .optimize = options.optimize,
        });
        const app = try core.App.init(app_builder, mach_core_dep.builder, .{
            .name = options.name,
            .src = options.src,
            .target = options.target,
            .optimize = options.optimize,
            .custom_entrypoint = options.custom_entrypoint,
            .deps = deps.items,
            .res_dirs = options.res_dirs,
            .watch_paths = options.watch_paths,
            .mach_core_mod = mach_core_dep.module("mach-core"),
        });
        return .{
            .core = app,
            .b = app.b,
            .mach_builder = mach_builder,
            .name = app.name,
            .compile = app.compile,
            .install = app.install,
            .run = app.run,
            .platform = app.platform,
        };
    }

    pub fn link(app: *const App) !void {
        // TODO: basisu support in wasm
        if (app.platform != .web) {
            app.compile.linkLibrary(app.mach_builder.dependency("mach_basisu", .{
                .target = app.compile.root_module.resolved_target.?,
                .optimize = app.compile.root_module.optimize.?,
            }).artifact("mach-basisu"));
            addPaths(app.compile);
        }
    }
};

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
    const supported_zig = std.SemanticVersion.parse("0.12.0-dev.2063+804cee3b9") catch unreachable;
    if (builtin.zig_version.order(supported_zig) != .eq) {
        @compileError(std.fmt.comptimePrint("unsupported Zig version ({}). Required Zig version 2024.1.0-mach: https://machengine.org/about/nominated-zig/#202410-mach", .{builtin.zig_version}));
    }
}
