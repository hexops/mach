const std = @import("std");

const ft_root = thisDir() ++ "/upstream/freetype";

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}

pub fn buildFreeType(b: *std.build.Builder, mode: std.builtin.Mode, target: std.zig.CrossTarget, root_path: []const u8, custom_config_path: ?[]const u8) !*std.build.LibExeObjStep {
    const main_abs = try std.fs.path.join(b.allocator, &.{ root_path, "src/base/ftbase.c" });
    const include_path = try std.fs.path.join(b.allocator, &.{ root_path, "include" });
    defer b.allocator.free(main_abs);
    defer b.allocator.free(include_path);

    const lib = b.addStaticLibrary("freetype", main_abs);
    lib.defineCMacro("FT2_BUILD_LIBRARY", "1");
    lib.setBuildMode(mode);
    lib.setTarget(target);
    lib.linkLibC();
    lib.addIncludePath(include_path);
    if (custom_config_path) |path| lib.addIncludeDir(path);

    var sources = std.ArrayList([]const u8).init(b.allocator);
    defer sources.deinit();

    inline for (freetype_base_sources) |source|
        try sources.append(source);

    const detected_target = (try std.zig.system.NativeTargetInfo.detect(b.allocator, target)).target;

    if (detected_target.os.tag == .windows) {
        try sources.append("builds/windows/ftsystem.c");
        try sources.append("builds/windows/ftdebug.c");
    } else {
        try sources.append("src/base/ftsystem.c");
        try sources.append("src/base/ftdebug.c");
    }
    if (detected_target.os.tag.isBSD() or detected_target.os.tag == .linux) {
        lib.defineCMacro("HAVE_UNISTD_H", "1");
        lib.defineCMacro("HAVE_FCNTL_H", "1");
        try sources.append("builds/unix/ftsystem.c");
        if (detected_target.os.tag == .macos) {
            try sources.append("src/base/ftmac.c");
        }
    }

    for (sources.items) |source| {
        var path = try std.fs.path.join(b.allocator, &.{ root_path, source });
        defer b.allocator.free(path);
        lib.addCSourceFile(path, &.{});
    }

    lib.install();

    return lib;
}

pub fn build(b: *std.build.Builder) !void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    const freetype = try buildFreeType(b, mode, target, ft_root, thisDir() ++ "/test/ft");

    const dedicated_tests = b.addTest("src/main.zig");
    dedicated_tests.setBuildMode(mode);
    dedicated_tests.setTarget(target);
    dedicated_tests.linkLibrary(freetype);
    dedicated_tests.addIncludePath(ft_root ++ "/include");

    const main_tests = b.addTest("test/main.zig");
    main_tests.setBuildMode(mode);
    main_tests.setTarget(target);
    main_tests.addPackagePath("freetype", "src/main.zig");
    main_tests.linkLibrary(freetype);
    main_tests.addIncludePath(thisDir() ++ "/test/ft");
    main_tests.addIncludePath(ft_root ++ "/include");

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&dedicated_tests.step);
    test_step.dependOn(&main_tests.step);
}

const freetype_base_sources = &[_][]const u8{
    "src/autofit/autofit.c",
    "src/base/ftbbox.c",
    "src/base/ftbdf.c",
    "src/base/ftbitmap.c",
    "src/base/ftcid.c",
    "src/base/ftfstype.c",
    "src/base/ftgasp.c",
    "src/base/ftglyph.c",
    "src/base/ftgxval.c",
    "src/base/ftinit.c",
    "src/base/ftmm.c",
    "src/base/ftotval.c",
    "src/base/ftpatent.c",
    "src/base/ftpfr.c",
    "src/base/ftstroke.c",
    "src/base/ftsynth.c",
    "src/base/fttype1.c",
    "src/base/ftwinfnt.c",
    "src/bdf/bdf.c",
    "src/bzip2/ftbzip2.c",
    "src/cache/ftcache.c",
    "src/cff/cff.c",
    "src/cid/type1cid.c",
    "src/gzip/ftgzip.c",
    "src/lzw/ftlzw.c",
    "src/pcf/pcf.c",
    "src/pfr/pfr.c",
    "src/psaux/psaux.c",
    "src/pshinter/pshinter.c",
    "src/psnames/psnames.c",
    "src/raster/raster.c",
    "src/sdf/sdf.c",
    "src/sfnt/sfnt.c",
    "src/smooth/smooth.c",
    "src/svg/svg.c",
    "src/truetype/truetype.c",
    "src/type1/type1.c",
    "src/type42/type42.c",
    "src/winfonts/winfnt.c",
};
