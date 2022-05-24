const std = @import("std");
const Builder = std.build.Builder;

const ft_root = thisDir() ++ "/upstream/freetype";
const ft_include_path = ft_root ++ "/include";

pub fn build(b: *std.build.Builder) !void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    const dedicated_tests = b.addTest("src/main.zig");
    dedicated_tests.setBuildMode(mode);
    dedicated_tests.setTarget(target);
    dedicated_tests.addPackage(pkg);
    link(b, dedicated_tests, .{});

    const main_tests = b.addTest("test/main.zig");
    main_tests.setBuildMode(mode);
    main_tests.setTarget(target);
    main_tests.addPackage(pkg);
    link(b, main_tests, .{ .custom_config_path = "./test/ft" });

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&dedicated_tests.step);
    test_step.dependOn(&main_tests.step);
}

pub const Options = struct {
    /// the path you specify freetype options
    /// via `ftoptions.h` and `ftmodule.h`
    /// e.g `test/ft/`
    custom_config_path: ?[]const u8 = null,
};

pub const pkg = std.build.Pkg{
    .name = "freetype",
    .path = .{ .path = thisDir() ++ "/src/main.zig" },
};

pub fn link(b: *Builder, step: *std.build.LibExeObjStep, options: Options) void {
    const lib = buildLibrary(b, step, options);
    step.linkLibrary(lib);
    if (options.custom_config_path) |path|
        step.addIncludePath(path);
    step.addIncludePath(ft_include_path);
}

pub fn buildLibrary(b: *Builder, step: *std.build.LibExeObjStep, options: Options) *std.build.LibExeObjStep {
    const main_abs = ft_root ++ "/src/base/ftbase.c";

    // TODO(build-system): https://github.com/hexops/mach/issues/229#issuecomment-1100958939
    ensureDependencySubmodule(b.allocator, "upstream") catch unreachable;

    const lib = b.addStaticLibrary("freetype", main_abs);
    lib.defineCMacro("FT2_BUILD_LIBRARY", "1");
    lib.setBuildMode(step.build_mode);
    lib.setTarget(step.target);
    lib.linkLibC();
    lib.addIncludePath(ft_include_path);
    if (options.custom_config_path) |path|
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
