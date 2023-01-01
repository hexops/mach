const std = @import("std");
const Builder = std.build.Builder;

const basisu_root = "/upstream/basisu";

var cached_pkg: ?std.build.Pkg = null;

pub fn pkg(b: *Builder) std.build.Pkg {
    if (cached_pkg == null) {
        cached_pkg = .{
            .name = "basisu",
            .source = .{ .path = sdkPath(b, "/src/main.zig") },
            .dependencies = &.{},
        };
    }

    return cached_pkg.?;
}

pub const Options = struct {
    encoder: ?EncoderOptions,
    transcoder: ?TranscoderOptions,
};

pub const EncoderOptions = struct {
    install_libs: bool = false,
};

pub const TranscoderOptions = struct {
    install_libs: bool = false,
};

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&testStep(b, mode, target).step);
}

pub fn testStep(b: *Builder, mode: std.builtin.Mode, target: std.zig.CrossTarget) *std.build.RunStep {
    const main_tests = b.addTestExe("basisu-tests", sdkPath(b, "/src/main.zig"));
    main_tests.setBuildMode(mode);
    main_tests.setTarget(target);
    main_tests.main_pkg_path = sdkPath(b, "/");
    link(b, main_tests, target, .{
        .encoder = .{},
        .transcoder = .{},
    });
    main_tests.install();
    return main_tests.run();
}

pub fn link(b: *Builder, step: *std.build.LibExeObjStep, target: std.zig.CrossTarget, options: Options) void {
    if (options.encoder) |encoder_options| {
        step.linkLibrary(buildEncoder(b, target, encoder_options));
        step.addCSourceFile(sdkPath(b, "/src/encoder/wrapper.cpp"), &.{});
        step.addIncludePath(sdkPath(b, basisu_root ++ "/encoder"));
    }
    if (options.transcoder) |transcoder_options| {
        step.linkLibrary(buildTranscoder(b, target, transcoder_options));
        step.addCSourceFile(sdkPath(b, "/src/transcoder/wrapper.cpp"), &.{});
        step.addIncludePath(sdkPath(b, basisu_root ++ "/transcoder"));
    }
}

pub fn buildEncoder(b: *Builder, target: std.zig.CrossTarget, options: EncoderOptions) *std.build.LibExeObjStep {
    // TODO(build-system): https://github.com/hexops/mach/issues/229#issuecomment-1100958939
    ensureDependencySubmodule(b.allocator, "upstream") catch unreachable;

    const encoder = b.addStaticLibrary("basisu-encoder", null);
    encoder.setTarget(target);
    encoder.linkLibCpp();

    inline for (encoder_sources) |encoder_source| {
        encoder.addCSourceFile(sdkPath(b, encoder_source), &.{});
    }

    encoder.defineCMacro("BASISU_FORCE_DEVEL_MESSAGES", "0");
    encoder.defineCMacro("BASISD_SUPPORT_KTX2_ZSTD", "0");

    if (options.install_libs)
        encoder.install();
    return encoder;
}

pub fn buildTranscoder(b: *Builder, target: std.zig.CrossTarget, options: TranscoderOptions) *std.build.LibExeObjStep {
    // TODO(build-system): https://github.com/hexops/mach/issues/229#issuecomment-1100958939
    ensureDependencySubmodule(b.allocator, "upstream") catch unreachable;

    const transcoder = b.addStaticLibrary("basisu-transcoder", null);
    transcoder.setTarget(target);
    transcoder.linkLibCpp();

    inline for (transcoder_sources) |transcoder_source| {
        transcoder.addCSourceFile(sdkPath(b, transcoder_source), &.{});
    }

    transcoder.defineCMacro("BASISU_FORCE_DEVEL_MESSAGES", "0");
    transcoder.defineCMacro("BASISD_SUPPORT_KTX2_ZSTD", "0");

    if (options.install_libs)
        transcoder.install();
    return transcoder;
}

fn ensureDependencySubmodule(allocator: std.mem.Allocator, path: []const u8) !void {
    if (std.process.getEnvVarOwned(allocator, "NO_ENSURE_SUBMODULES")) |no_ensure_submodules| {
        defer allocator.free(no_ensure_submodules);
        if (std.mem.eql(u8, no_ensure_submodules, "true")) return;
    } else |_| {}
    var child = std.ChildProcess.init(&.{ "git", "submodule", "update", "--init", path }, allocator);
    child.cwd = sdkPathAllocator(allocator, "/");
    child.stderr = std.io.getStdErr();
    child.stdout = std.io.getStdOut();

    _ = try child.spawnAndWait();
}

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

const transcoder_sources = &[_][]const u8{
    basisu_root ++ "/transcoder/basisu_transcoder.cpp",
};

const encoder_sources = &[_][]const u8{
    basisu_root ++ "/encoder/basisu_backend.cpp",
    basisu_root ++ "/encoder/basisu_basis_file.cpp",
    basisu_root ++ "/encoder/basisu_bc7enc.cpp",
    basisu_root ++ "/encoder/basisu_comp.cpp",
    basisu_root ++ "/encoder/basisu_enc.cpp",
    basisu_root ++ "/encoder/basisu_etc.cpp",
    basisu_root ++ "/encoder/basisu_frontend.cpp",
    basisu_root ++ "/encoder/basisu_gpu_texture.cpp",
    basisu_root ++ "/encoder/basisu_kernels_sse.cpp",
    basisu_root ++ "/encoder/basisu_opencl.cpp",
    basisu_root ++ "/encoder/basisu_pvrtc1_4.cpp",
    basisu_root ++ "/encoder/basisu_resample_filters.cpp",
    basisu_root ++ "/encoder/basisu_resampler.cpp",
    basisu_root ++ "/encoder/basisu_ssim.cpp",
    basisu_root ++ "/encoder/basisu_uastc_enc.cpp",
    basisu_root ++ "/encoder/jpgd.cpp",
    basisu_root ++ "/encoder/pvpngreader.cpp",
};
