const std = @import("std");
const Builder = std.build.Builder;
const sysjs = @import("libs/mach-sysjs/build.zig");

const soundio_path = thisDir() ++ "/upstream/soundio";

pub const pkg = std.build.Pkg{
    .name = "sysaudio",
    .source = .{ .path = thisDir() ++ "/src/main.zig" },
    .dependencies = &.{sysjs.pkg},
};

const soundio_pkg = std.build.Pkg{
    .name = "soundio",
    .source = .{ .path = thisDir() ++ "/soundio/main.zig" },
};

pub const Options = struct {};

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    const soundio_tests = b.addTest("soundio/main.zig");
    soundio_tests.setBuildMode(mode);
    link(b, soundio_tests, .{});

    const main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);
    main_tests.addPackage(soundio_pkg);
    link(b, main_tests, .{});

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&soundio_tests.step);
    test_step.dependOn(&main_tests.step);

    inline for ([_][]const u8{
        "soundio-sine-wave",
    }) |example| {
        const example_exe = b.addExecutable("example-" ++ example, "examples/" ++ example ++ ".zig");
        example_exe.setBuildMode(mode);
        example_exe.setTarget(target);
        example_exe.addPackage(soundio_pkg);
        link(b, example_exe, .{});
        example_exe.install();

        const example_compile_step = b.step("example-" ++ example, "Compile '" ++ example ++ "' example");
        example_compile_step.dependOn(b.getInstallStep());

        const example_run_cmd = example_exe.run();
        example_run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            example_run_cmd.addArgs(args);
        }

        const example_run_step = b.step("run-example-" ++ example, "Run '" ++ example ++ "' example");
        example_run_step.dependOn(&example_run_cmd.step);
    }
}

pub fn link(b: *Builder, step: *std.build.LibExeObjStep, options: Options) void {
    _ = options;
    if (step.target.toTarget().cpu.arch != .wasm32) {
        const soundio_lib = buildSoundIo(b, step);
        step.linkLibrary(soundio_lib);
        step.addIncludePath(soundio_path);
    }
}

fn buildSoundIo(b: *Builder, step: *std.build.LibExeObjStep) *std.build.LibExeObjStep {
    // TODO(build-system): https://github.com/hexops/mach/issues/229#issuecomment-1100958939
    ensureDependencySubmodule(b.allocator, "upstream") catch unreachable;

    const config_base =
        \\#ifndef SOUNDIO_CONFIG_H
        \\#define SOUNDIO_CONFIG_H
        \\#define SOUNDIO_VERSION_MAJOR 2
        \\#define SOUNDIO_VERSION_MINOR 0
        \\#define SOUNDIO_VERSION_PATCH 0
        \\#define SOUNDIO_VERSION_STRING "2.0.0"
        \\
    ;

    var config_file = std.fs.cwd().createFile(soundio_path ++ "/src/config.h", .{}) catch unreachable;
    defer config_file.close();
    config_file.writeAll(config_base) catch unreachable;

    const lib = b.addStaticLibrary("soundio", null);
    lib.setTarget(step.target);
    lib.setBuildMode(step.build_mode);
    lib.linkLibC();
    lib.addIncludePath(soundio_path);
    lib.addCSourceFiles(soundio_sources, &.{});

    const target = (std.zig.system.NativeTargetInfo.detect(b.allocator, step.target) catch unreachable).target;
    if (target.isDarwin()) {
        lib.addCSourceFile(soundio_path ++ "/src/coreaudio.c", &.{});
        lib.linkFramework("AudioToolbox");
        lib.linkFramework("CoreFoundation");
        lib.linkFramework("CoreAudio");
        config_file.writeAll("#define SOUNDIO_HAVE_COREAUDIO\n") catch unreachable;
    } else if (target.os.tag == .linux) {
        lib.addCSourceFile(soundio_path ++ "/src/alsa.c", &.{});
        lib.linkSystemLibrary("asound");
        config_file.writeAll("#define SOUNDIO_HAVE_ALSA\n") catch unreachable;
    } else if (target.os.tag == .windows) {
        lib.addCSourceFile(soundio_path ++ "/src/wasapi.c", &.{});
        config_file.writeAll("#define SOUNDIO_HAVE_WASAPI\n") catch unreachable;
    }

    config_file.writeAll("#endif\n") catch unreachable;

    lib.install();
    return lib;
}

fn ensureDependencySubmodule(allocator: std.mem.Allocator, path: []const u8) !void {
    if (std.process.getEnvVarOwned(allocator, "NO_ENSURE_SUBMODULES")) |no_ensure_submodules| {
        if (std.mem.eql(u8, no_ensure_submodules, "true")) return;
    } else |_| {}
    var child = std.ChildProcess.init(&.{ "git", "submodule", "update", "--init", path }, allocator);
    child.cwd = thisDir();
    child.stderr = std.io.getStdErr();
    child.stdout = std.io.getStdOut();

    _ = try child.spawnAndWait();
}

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}

const soundio_sources = &[_][]const u8{
    soundio_path ++ "/src/soundio.c",
    soundio_path ++ "/src/util.c",
    soundio_path ++ "/src/os.c",
    soundio_path ++ "/src/dummy.c",
    soundio_path ++ "/src/channel_layout.c",
    soundio_path ++ "/src/ring_buffer.c",
};
