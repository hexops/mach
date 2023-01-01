const std = @import("std");
const Builder = std.build.Builder;

const ft_root = "/upstream/freetype";
const ft_include_path = ft_root ++ "/include";
const hb_root = "/upstream/harfbuzz";
const hb_include_path = hb_root ++ "/src";
const brotli_root = "/upstream/brotli";

var cached_pkg: ?std.build.Pkg = null;
var cached_harfbuzz_pkg: ?std.build.Pkg = null;

pub fn pkg(b: *Builder) std.build.Pkg {
    if (cached_pkg == null) {
        cached_pkg = .{
            .name = "freetype",
            .source = .{ .path = sdkPath(b, "/src/main.zig") },
            .dependencies = &.{},
        };
    }

    return cached_pkg.?;
}

pub fn harfbuzz_pkg(b: *Builder) std.build.Pkg {
    if (cached_harfbuzz_pkg == null) {
        const dependencies = b.allocator.create([1]std.build.Pkg) catch unreachable;
        dependencies.* = .{
            pkg(b),
        };

        cached_harfbuzz_pkg = .{
            .name = "harfbuzz",
            .source = .{ .path = sdkPath(b, "/src/harfbuzz/main.zig") },
            .dependencies = dependencies,
        };
    }

    return cached_harfbuzz_pkg.?;
}

pub const Options = struct {
    freetype: FreetypeOptions = .{},
    harfbuzz: ?HarfbuzzOptions = null,
};

pub const FreetypeOptions = struct {
    /// the path you specify freetype options
    /// via `ftoptions.h` and `ftmodule.h`
    config_path: ?[]const u8 = null,
    install_libs: bool = false,
    brotli: bool = false,
    use_system_zlib: bool = false,
};

pub const HarfbuzzOptions = struct {
    install_libs: bool = false,
};

pub fn build(b: *std.build.Builder) !void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&testStep(b, mode, target).step);

    inline for ([_][]const u8{
        "single-glyph",
        "glyph-to-svg",
    }) |example| {
        const example_exe = b.addExecutable("example-" ++ example, "examples/" ++ example ++ ".zig");
        example_exe.setBuildMode(mode);
        example_exe.setTarget(target);
        example_exe.addPackage(pkg(b));

        link(b, example_exe, .{});

        const example_install = b.addInstallArtifact(example_exe);

        var example_compile_step = b.step("example-" ++ example, "Compile '" ++ example ++ "' example");
        example_compile_step.dependOn(&example_install.step);

        const example_run_cmd = example_exe.run();
        if (b.args) |args| {
            example_run_cmd.addArgs(args);
        }

        const example_run_step = b.step("run-example-" ++ example, "Run '" ++ example ++ "' example");
        example_run_step.dependOn(&example_run_cmd.step);
    }
}

pub fn testStep(b: *Builder, mode: std.builtin.Mode, target: std.zig.CrossTarget) *std.build.RunStep {
    const main_tests = b.addTestExe("freetype-tests", sdkPath(b, "/src/main.zig"));
    main_tests.setBuildMode(mode);
    main_tests.setTarget(target);
    main_tests.addPackage(pkg(b));
    link(b, main_tests, .{
        .freetype = .{
            .brotli = true,
        },
        .harfbuzz = .{},
    });
    main_tests.main_pkg_path = sdkPath(b, "/");
    main_tests.install();

    const harfbuzz_tests = b.addTestExe("harfbuzz-tests", sdkPath(b, "/src/harfbuzz/main.zig"));
    harfbuzz_tests.setBuildMode(mode);
    harfbuzz_tests.setTarget(target);
    harfbuzz_tests.addPackage(pkg(b));
    link(b, harfbuzz_tests, .{
        .freetype = .{
            .brotli = true,
        },
        .harfbuzz = .{},
    });
    harfbuzz_tests.main_pkg_path = sdkPath(b, "/");
    harfbuzz_tests.install();

    const main_tests_run = main_tests.run();
    main_tests_run.step.dependOn(&harfbuzz_tests.run().step);
    return main_tests_run;
}

pub fn link(b: *Builder, step: *std.build.LibExeObjStep, options: Options) void {
    linkFreetype(b, step, options.freetype);
    if (options.harfbuzz) |harfbuzz_options|
        linkHarfbuzz(b, step, harfbuzz_options);
}

pub fn linkFreetype(b: *Builder, step: *std.build.LibExeObjStep, options: FreetypeOptions) void {
    const ft_lib = buildFreetype(b, step.build_mode, step.target, options);
    step.linkLibrary(ft_lib);
    step.addIncludePath(sdkPath(b, ft_include_path));
    if (options.brotli) {
        const brotli_lib = buildBrotli(b, step.build_mode, step.target);
        if (options.install_libs)
            brotli_lib.install();
        step.linkLibrary(brotli_lib);
    }
}

pub fn linkHarfbuzz(b: *Builder, step: *std.build.LibExeObjStep, options: HarfbuzzOptions) void {
    const hb_lib = buildHarfbuzz(b, step.build_mode, step.target, options);
    step.linkLibrary(hb_lib);
    step.addIncludePath(sdkPath(b, hb_include_path));
}

pub fn buildFreetype(b: *Builder, mode: std.builtin.Mode, target: std.zig.CrossTarget, options: FreetypeOptions) *std.build.LibExeObjStep {
    // TODO(build-system): https://github.com/hexops/mach/issues/229#issuecomment-1100958939
    ensureDependencySubmodule(b.allocator, "upstream") catch unreachable;

    const lib = b.addStaticLibrary("freetype", null);
    lib.defineCMacro("FT2_BUILD_LIBRARY", "1");
    if (options.use_system_zlib) {
        lib.defineCMacro("FT_CONFIG_OPTION_SYSTEM_ZLIB", "1");
    }
    lib.setBuildMode(mode);
    lib.setTarget(target);
    lib.linkLibC();
    lib.addIncludePath(sdkPath(b, ft_include_path));

    if (options.config_path) |path|
        lib.addIncludePath(path);

    if (options.brotli)
        lib.defineCMacro("FT_REQUIRE_BROTLI", "1");

    const target_info = (std.zig.system.NativeTargetInfo.detect(target) catch unreachable).target;

    if (target_info.os.tag == .windows) {
        lib.addCSourceFile(sdkPath(b, ft_root ++ "/builds/windows/ftsystem.c"), &.{});
        lib.addCSourceFile(sdkPath(b, ft_root ++ "/builds/windows/ftdebug.c"), &.{});
    } else {
        lib.addCSourceFile(sdkPath(b, ft_root ++ "/src/base/ftsystem.c"), &.{});
        lib.addCSourceFile(sdkPath(b, ft_root ++ "/src/base/ftdebug.c"), &.{});
    }
    if (target_info.os.tag.isBSD() or target_info.os.tag == .linux) {
        lib.defineCMacro("HAVE_UNISTD_H", "1");
        lib.defineCMacro("HAVE_FCNTL_H", "1");
        lib.addCSourceFile(sdkPath(b, ft_root ++ "/builds/unix/ftsystem.c"), &.{});
        if (target_info.os.tag == .macos)
            lib.addCSourceFile(sdkPath(b, ft_root ++ "/src/base/ftmac.c"), &.{});
    }

    inline for (freetype_base_sources) |ft_source| {
        lib.addCSourceFile(sdkPath(b, ft_source), &.{});
    }

    if (options.install_libs)
        lib.install();
    return lib;
}

pub fn buildHarfbuzz(b: *Builder, mode: std.builtin.Mode, target: std.zig.CrossTarget, options: HarfbuzzOptions) *std.build.LibExeObjStep {
    const main_abs = sdkPath(b, hb_root ++ "/src/harfbuzz.cc");
    const lib = b.addStaticLibrary("harfbuzz", main_abs);
    lib.setBuildMode(mode);
    lib.setTarget(target);
    lib.linkLibCpp();
    lib.addIncludePath(sdkPath(b, hb_include_path));
    lib.addIncludePath(sdkPath(b, ft_include_path));
    lib.defineCMacro("HAVE_FREETYPE", "1");

    if (options.install_libs)
        lib.install();
    return lib;
}

fn buildBrotli(b: *Builder, mode: std.builtin.Mode, target: std.zig.CrossTarget) *std.build.LibExeObjStep {
    const lib = b.addStaticLibrary("brotli", null);
    lib.setBuildMode(mode);
    lib.setTarget(target);
    lib.linkLibC();
    lib.addIncludePath(sdkPath(b, brotli_root ++ "/include"));

    inline for (brotli_base_sources) |brotli_source| {
        lib.addCSourceFile(sdkPath(b, brotli_source), &.{});
    }

    return lib;
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

const freetype_base_sources = &[_][]const u8{
    ft_root ++ "/src/autofit/autofit.c",
    ft_root ++ "/src/base/ftbase.c",
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

const brotli_base_sources = &[_][]const u8{
    brotli_root ++ "/enc/backward_references.c",
    brotli_root ++ "/enc/fast_log.c",
    brotli_root ++ "/enc/histogram.c",
    brotli_root ++ "/enc/cluster.c",
    brotli_root ++ "/enc/command.c",
    brotli_root ++ "/enc/compress_fragment_two_pass.c",
    brotli_root ++ "/enc/entropy_encode.c",
    brotli_root ++ "/enc/bit_cost.c",
    brotli_root ++ "/enc/memory.c",
    brotli_root ++ "/enc/backward_references_hq.c",
    brotli_root ++ "/enc/dictionary_hash.c",
    brotli_root ++ "/enc/encoder_dict.c",
    brotli_root ++ "/enc/block_splitter.c",
    brotli_root ++ "/enc/compress_fragment.c",
    brotli_root ++ "/enc/literal_cost.c",
    brotli_root ++ "/enc/brotli_bit_stream.c",
    brotli_root ++ "/enc/encode.c",
    brotli_root ++ "/enc/static_dict.c",
    brotli_root ++ "/enc/utf8_util.c",
    brotli_root ++ "/enc/metablock.c",
    brotli_root ++ "/dec/decode.c",
    brotli_root ++ "/dec/bit_reader.c",
    brotli_root ++ "/dec/huffman.c",
    brotli_root ++ "/dec/state.c",
    brotli_root ++ "/common/constants.c",
    brotli_root ++ "/common/context.c",
    brotli_root ++ "/common/dictionary.c",
    brotli_root ++ "/common/transform.c",
    brotli_root ++ "/common/platform.c",
};
