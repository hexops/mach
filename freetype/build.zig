const std = @import("std");
const Builder = std.build.Builder;

const ft_root = thisDir() ++ "/upstream/freetype";
const ft_include_path = ft_root ++ "/include";
const hb_root = thisDir() ++ "/upstream/harfbuzz";
const hb_include_path = ft_root ++ "/src";

pub const freetype_pkg = std.build.Pkg{
    .name = "freetype",
    .source = .{ .path = thisDir() ++ "/src/freetype/main.zig" },
};
pub const harfbuzz_pkg = std.build.Pkg{
    .name = "harfbuzz",
    .source = .{ .path = thisDir() ++ "/src/harfbuzz/main.zig" },
};

pub const Options = struct {
    harfbuzz: ?HarfbuzzOptions = null,
    freetype: FreetypeOptions = .{},
};
pub const FreetypeOptions = struct {
    /// the path you specify freetype options
    /// via `ftoptions.h` and `ftmodule.h`
    /// e.g `test/ft/`
    ft_config_path: ?[]const u8 = null,
};
pub const HarfbuzzOptions = struct {};

pub fn build(b: *std.build.Builder) !void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    const freetype_tests = b.addTestSource(freetype_pkg.source);
    freetype_tests.setBuildMode(mode);
    freetype_tests.setTarget(target);
    link(b, freetype_tests, .{});

    const main_tests = b.addTest("test/main.zig");
    main_tests.setBuildMode(mode);
    main_tests.setTarget(target);
    main_tests.addPackage(freetype_pkg);
    link(b, main_tests, .{ .freetype = .{ .ft_config_path = "./test/ft" } });

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&freetype_tests.step);
    test_step.dependOn(&main_tests.step);

    inline for ([_][]const u8{
        "single-glyph",
        "glyph-to-svg",
    }) |example| {
        const example_exe = b.addExecutable("example-" ++ example, "examples/" ++ example ++ ".zig");
        example_exe.setBuildMode(mode);
        example_exe.setTarget(target);
        example_exe.addPackage(freetype_pkg);
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
    const ft_lib = buildFreetype(b, step, options.freetype);
    step.linkLibrary(ft_lib);
    step.addIncludePath(ft_include_path);

    if (options.harfbuzz) |hb_options| {
        const hb_lib = buildHarfbuzz(b, step, hb_options);
        hb_lib.linkLibrary(ft_lib);
        step.linkLibrary(hb_lib);
    }
}

pub fn buildFreetype(b: *Builder, step: *std.build.LibExeObjStep, options: FreetypeOptions) *std.build.LibExeObjStep {
    // TODO(build-system): https://github.com/hexops/mach/issues/229#issuecomment-1100958939
    ensureDependencySubmodule(b.allocator, "upstream") catch unreachable;

    const main_abs = ft_root ++ "/src/base/ftbase.c";
    const lib = b.addStaticLibrary("freetype", main_abs);
    lib.defineCMacro("FT2_BUILD_LIBRARY", "1");
    lib.setBuildMode(step.build_mode);
    lib.setTarget(step.target);
    lib.linkLibC();
    lib.addIncludePath(ft_include_path);
    if (options.ft_config_path) |path|
        lib.addIncludePath(path);

    const target = (std.zig.system.NativeTargetInfo.detect(b.allocator, step.target) catch unreachable).target;

    if (target.os.tag == .windows) {
        lib.addCSourceFile(ft_root ++ "/builds/windows/ftsystem.c", &.{});
        lib.addCSourceFile(ft_root ++ "/builds/windows/ftdebug.c", &.{});
    } else {
        lib.addCSourceFile(ft_root ++ "/src/base/ftsystem.c", &.{});
        lib.addCSourceFile(ft_root ++ "/src/base/ftdebug.c", &.{});
    }
    if (target.os.tag.isBSD() or target.os.tag == .linux) {
        lib.defineCMacro("HAVE_UNISTD_H", "1");
        lib.defineCMacro("HAVE_FCNTL_H", "1");
        lib.addCSourceFile(ft_root ++ "/builds/unix/ftsystem.c", &.{});
        if (target.os.tag == .macos) {
            lib.addCSourceFile(ft_root ++ "/src/base/ftmac.c", &.{});
        }
    }

    lib.addCSourceFiles(freetype_base_sources, &.{});
    lib.install();
    return lib;
}

pub fn buildHarfbuzz(b: *Builder, step: *std.build.LibExeObjStep, options: HarfbuzzOptions) *std.build.LibExeObjStep {
    _ = options;
    const main_abs = hb_root ++ "/src/harfbuzz.cc";
    const lib = b.addStaticLibrary("harfbuzz", main_abs);
    lib.setBuildMode(step.build_mode);
    lib.setTarget(step.target);
    lib.linkLibCpp();
    lib.addIncludePath(hb_include_path);
    lib.addCSourceFiles(harfbuzz_base_sources, &.{});
    lib.install();
    return lib;
}

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
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

const freetype_base_sources = &[_][]const u8{
    ft_root ++ "/src/autofit/autofit.c",
    ft_root ++ "/src/base/ftbbox.c",
    ft_root ++ "/src/base/ftbdf.c",
    ft_root ++ "/src/base/ftbitmap.c",
    ft_root ++ "/src/base/ftcid.c",
    ft_root ++ "/src/base/ftfstype.c",
    ft_root ++ "/src/base/ftgasp.c",
    ft_root ++ "/src/base/ftglyph.c",
    ft_root ++ "/src/base/ftgxval.c",
    ft_root ++ "/src/base/ftinit.c",
    ft_root ++ "/src/base/ftmm.c",
    ft_root ++ "/src/base/ftotval.c",
    ft_root ++ "/src/base/ftpatent.c",
    ft_root ++ "/src/base/ftpfr.c",
    ft_root ++ "/src/base/ftstroke.c",
    ft_root ++ "/src/base/ftsynth.c",
    ft_root ++ "/src/base/fttype1.c",
    ft_root ++ "/src/base/ftwinfnt.c",
    ft_root ++ "/src/bdf/bdf.c",
    ft_root ++ "/src/bzip2/ftbzip2.c",
    ft_root ++ "/src/cache/ftcache.c",
    ft_root ++ "/src/cff/cff.c",
    ft_root ++ "/src/cid/type1cid.c",
    ft_root ++ "/src/gzip/ftgzip.c",
    ft_root ++ "/src/lzw/ftlzw.c",
    ft_root ++ "/src/pcf/pcf.c",
    ft_root ++ "/src/pfr/pfr.c",
    ft_root ++ "/src/psaux/psaux.c",
    ft_root ++ "/src/pshinter/pshinter.c",
    ft_root ++ "/src/psnames/psnames.c",
    ft_root ++ "/src/raster/raster.c",
    ft_root ++ "/src/sdf/sdf.c",
    ft_root ++ "/src/sfnt/sfnt.c",
    ft_root ++ "/src/smooth/smooth.c",
    ft_root ++ "/src/svg/svg.c",
    ft_root ++ "/src/truetype/truetype.c",
    ft_root ++ "/src/type1/type1.c",
    ft_root ++ "/src/type42/type42.c",
    ft_root ++ "/src/winfonts/winfnt.c",
};

const harfbuzz_base_sources = &[_][]const u8{
    hb_root ++ "/src/hb-aat-layout.cc",
    hb_root ++ "/src/hb-aat-map.cc",
    hb_root ++ "/src/hb-blob.cc",
    hb_root ++ "/src/hb-buffer-serialize.cc",
    hb_root ++ "/src/hb-buffer-verify.cc",
    hb_root ++ "/src/hb-buffer.cc",
    hb_root ++ "/src/hb-common.cc",
    hb_root ++ "/src/hb-draw.cc",
    hb_root ++ "/src/hb-face.cc",
    hb_root ++ "/src/hb-fallback-shape.cc",
    hb_root ++ "/src/hb-font.cc",
    hb_root ++ "/src/hb-map.cc",
    hb_root ++ "/src/hb-number.cc",
    hb_root ++ "/src/hb-ot-cff1-table.cc",
    hb_root ++ "/src/hb-ot-cff2-table.cc",
    hb_root ++ "/src/hb-ot-color.cc",
    hb_root ++ "/src/hb-ot-face.cc",
    hb_root ++ "/src/hb-ot-font.cc",
    hb_root ++ "/src/hb-ot-layout.cc",
    hb_root ++ "/src/hb-ot-map.cc",
    hb_root ++ "/src/hb-ot-math.cc",
    hb_root ++ "/src/hb-ot-meta.cc",
    hb_root ++ "/src/hb-ot-metrics.cc",
    hb_root ++ "/src/hb-ot-name.cc",
    hb_root ++ "/src/hb-ot-shaper-arabic.cc",
    hb_root ++ "/src/hb-ot-shaper-default.cc",
    hb_root ++ "/src/hb-ot-shaper-hangul.cc",
    hb_root ++ "/src/hb-ot-shaper-hebrew.cc",
    hb_root ++ "/src/hb-ot-shaper-indic-table.cc",
    hb_root ++ "/src/hb-ot-shaper-indic.cc",
    hb_root ++ "/src/hb-ot-shaper-khmer.cc",
    hb_root ++ "/src/hb-ot-shaper-myanmar.cc",
    hb_root ++ "/src/hb-ot-shaper-syllabic.cc",
    hb_root ++ "/src/hb-ot-shaper-thai.cc",
    hb_root ++ "/src/hb-ot-shaper-use.cc",
    hb_root ++ "/src/hb-ot-shaper-vowel-constraints.cc",
    hb_root ++ "/src/hb-ot-shape-fallback.cc",
    hb_root ++ "/src/hb-ot-shape-normalize.cc",
    hb_root ++ "/src/hb-ot-shape.cc",
    hb_root ++ "/src/hb-ot-tag.cc",
    hb_root ++ "/src/hb-ot-var.cc",
    hb_root ++ "/src/hb-set.cc",
    hb_root ++ "/src/hb-shape-plan.cc",
    hb_root ++ "/src/hb-shape.cc",
    hb_root ++ "/src/hb-shaper.cc",
    hb_root ++ "/src/hb-static.cc",
    hb_root ++ "/src/hb-style.cc",
    hb_root ++ "/src/hb-ucd.cc",
    hb_root ++ "/src/hb-unicode.cc",
    hb_root ++ "/src/hb-ft.cc", // freetype integration
};
