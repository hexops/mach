const std = @import("std");
const Builder = std.build.Builder;

const basisu_root = sdkPath("/zig-deps/upstream/basisu");

pub const pkg = std.build.Pkg{
    .name = "basisu",
    .source = .{
        .path = "src/main.zig",
    },
};

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
    const main_tests = b.addTestExe("basisu-tests", sdkPath("/src/main.zig"));
    main_tests.setBuildMode(mode);
    main_tests.setTarget(target);
    main_tests.main_pkg_path = sdkPath("/");
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
        step.addCSourceFile(sdkPath("/src/encoder/wrapper.cpp"), &.{});
        step.addIncludePath(basisu_root ++ "/encoder");
    }
    if (options.transcoder) |transcoder_options| {
        step.linkLibrary(buildTranscoder(b, target, transcoder_options));
        step.addCSourceFile(sdkPath("/src/transcoder/wrapper.cpp"), &.{});
        step.addIncludePath(basisu_root ++ "/transcoder");
    }
}

pub fn buildEncoder(b: *Builder, target: std.zig.CrossTarget, options: EncoderOptions) *std.build.LibExeObjStep {
    const encoder = b.addStaticLibrary("basisu-encoder", null);
    encoder.setTarget(target);
    encoder.linkLibCpp();
    encoder.addCSourceFiles(
        encoder_sources,
        &.{},
    );
    encoder.defineCMacro("BASISU_FORCE_DEVEL_MESSAGES", "0");
    encoder.defineCMacro("BASISD_SUPPORT_KTX2_ZSTD", "0");

    if (options.install_libs)
        encoder.install();
    return encoder;
}

pub fn buildTranscoder(b: *Builder, target: std.zig.CrossTarget, options: TranscoderOptions) *std.build.LibExeObjStep {
    const transcoder = b.addStaticLibrary("basisu-transcoder", null);
    transcoder.setTarget(target);
    transcoder.linkLibCpp();
    transcoder.addCSourceFiles(
        transcoder_sources,
        &.{},
    );
    transcoder.defineCMacro("BASISU_FORCE_DEVEL_MESSAGES", "0");
    transcoder.defineCMacro("BASISD_SUPPORT_KTX2_ZSTD", "0");

    if (options.install_libs)
        transcoder.install();
    return transcoder;
}

fn sdkPath(comptime suffix: []const u8) []const u8 {
    if (suffix[0] != '/') @compileError("suffix must be an absolute path");
    return comptime blk: {
        const root_dir = std.fs.path.dirname(@src().file) orelse ".";
        break :blk root_dir ++ suffix;
    };
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
