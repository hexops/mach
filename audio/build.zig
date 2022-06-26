const std = @import("std");
const Builder = std.build.Builder;

const soundio_path = thisDir() ++ "/upstream/soundio";

pub const pkg = std.build.Pkg{
    .name = "soundio",
    .source = .{ .path = thisDir() ++ "/soundio/main.zig" },
};

pub const SoundIoOptions = struct {
    jack: bool = false,
    pulseaudio: bool = false,
    alsa: bool = false,
    coreaudio: bool = false,
    wasapi: bool = false,
};

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();

    const soundio_tests = b.addTest("soundio/main.zig");
    soundio_tests.setBuildMode(mode);
    soundio_tests.addPackage(pkg);
    link(b, soundio_tests, .{ .alsa = true });

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&soundio_tests.step);
}

pub fn link(b: *Builder, step: *std.build.LibExeObjStep, options: SoundIoOptions) void {
    const soundio_lib = buildSoundIo(b, step, options);
    step.linkLibrary(soundio_lib);
    step.addIncludePath(soundio_path);
}

pub fn buildSoundIo(b: *Builder, step: *std.build.LibExeObjStep, options: SoundIoOptions) *std.build.LibExeObjStep {
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
    if (options.jack) {
        lib.addCSourceFile(soundio_path ++ "/src/jack.c", &.{});
        lib.linkSystemLibrary("jack");
        config_file.writeAll("#define SOUNDIO_HAVE_JACK\n") catch unreachable;
    }
    if (target.isBSD() or target.os.tag == .linux) {
        if (options.pulseaudio) {
            lib.addCSourceFile(soundio_path ++ "/src/pulseaudio.c", &.{});
            lib.linkSystemLibrary("pulse");
            config_file.writeAll("#define SOUNDIO_HAVE_PULSEAUDIO\n") catch unreachable;
        }
        if (options.alsa) {
            lib.addCSourceFile(soundio_path ++ "/src/alsa.c", &.{});
            lib.linkSystemLibrary("asound");
            config_file.writeAll("#define SOUNDIO_HAVE_ALSA\n") catch unreachable;
        }
        if (options.coreaudio and target.isDarwin()) {
            lib.addCSourceFile(soundio_path ++ "/src/coreaudio.c", &.{});
            lib.linkFramework("CoreFoundation");
            lib.linkFramework("CoreAudio");
            config_file.writeAll("#define SOUNDIO_HAVE_COREAUDIO\n") catch unreachable;
        }
    } else if (options.wasapi and target.os.tag == .windows) {
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
