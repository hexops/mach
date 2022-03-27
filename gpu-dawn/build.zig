const std = @import("std");
const Builder = std.build.Builder;
const glfw = @import("libs/mach-glfw/build.zig");
const system_sdk = @import("libs/mach-glfw/system_sdk.zig");

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    const options = Options{
        .from_source = b.option(bool, "dawn-from-source", "Build Dawn from source") orelse false,
    };

    const lib = b.addStaticLibrary("gpu", "src/main.zig");
    lib.setBuildMode(mode);
    lib.setTarget(target);
    lib.install();
    link(b, lib, options);

    const main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);

    const dawn_example = b.addExecutable("dawn-example", "src/dawn/hello_triangle.zig");
    dawn_example.setBuildMode(mode);
    dawn_example.setTarget(target);
    link(b, dawn_example, options);
    glfw.link(b, dawn_example, .{ .system_sdk = .{ .set_sysroot = false } });
    dawn_example.addPackagePath("glfw", "libs/mach-glfw/src/main.zig");
    dawn_example.install();

    const dawn_example_run_cmd = dawn_example.run();
    dawn_example_run_cmd.step.dependOn(b.getInstallStep());
    const dawn_example_run_step = b.step("run-dawn-example", "Run the dawn example");
    dawn_example_run_step.dependOn(&dawn_example_run_cmd.step);
}

pub const LinuxWindowManager = enum {
    X11,
    Wayland,
};

pub const Options = struct {
    /// Defaults to X11 on Linux.
    linux_window_manager: ?LinuxWindowManager = null,

    /// Defaults to true on Windows
    d3d12: ?bool = null,

    /// Defaults to true on Darwin
    metal: ?bool = null,

    /// Defaults to true on Linux, Fuchsia
    // TODO(build-system): enable on Windows if we can cross compile Vulkan
    vulkan: ?bool = null,

    /// Defaults to true on Linux
    desktop_gl: ?bool = null,

    /// Defaults to true on Android, Linux, Windows, Emscripten
    // TODO(build-system): not respected at all currently
    opengl_es: ?bool = null,

    /// Whether or not minimal debug symbols should be emitted. This is -g1 in most cases, enough to
    /// produce stack traces but omitting debug symbols for locals. For spirv-tools and tint in
    /// specific, -g0 will be used (no debug symbols at all) to save an additional ~39M.
    ///
    /// When enabled, a debug build of the static library goes from ~947M to just ~53M.
    minimal_debug_symbols: bool = true,

    /// Whether or not to produce separate static libraries for each component of Dawn (reduces
    /// iteration times when building from source / testing changes to Dawn source code.)
    separate_libs: bool = false,

    /// Whether to build Dawn from source or not.
    from_source: bool = false,

    /// The binary release version to use from https://github.com/hexops/mach-gpu-dawn/releases
    binary_version: []const u8 = "release-5fe08ee",

    /// Detects the default options to use for the given target.
    pub fn detectDefaults(self: Options, target: std.Target) Options {
        const tag = target.os.tag;
        const linux_desktop_like = isLinuxDesktopLike(target);

        var options = self;
        if (options.linux_window_manager == null and linux_desktop_like) options.linux_window_manager = .X11;
        if (options.d3d12 == null) options.d3d12 = tag == .windows;
        if (options.metal == null) options.metal = tag.isDarwin();
        if (options.vulkan == null) options.vulkan = tag == .fuchsia or linux_desktop_like;

        // TODO(build-system): technically Dawn itself defaults desktop_gl to true on Windows.
        if (options.desktop_gl == null) options.desktop_gl = linux_desktop_like;
        options.opengl_es = false; // TODO(build-system): OpenGL ES
        // if (options.opengl_es == null) options.opengl_es = tag == .windows or tag == .emscripten or target.isAndroid() or linux_desktop_like;
        return options;
    }

    pub fn appendFlags(self: Options, flags: *std.ArrayList([]const u8), zero_debug_symbols: bool, is_cpp: bool) !void {
        if (self.minimal_debug_symbols) {
            if (zero_debug_symbols) try flags.append("-g0") else try flags.append("-g1");
        }
        if (is_cpp) try flags.append("-std=c++17");
        if (self.linux_window_manager != null and self.linux_window_manager.? == .X11) try flags.append("-DDAWN_USE_X11");
    }
};

pub fn link(b: *Builder, step: *std.build.LibExeObjStep, options: Options) void {
    const target = (std.zig.system.NativeTargetInfo.detect(b.allocator, step.target) catch unreachable).target;
    const opt = options.detectDefaults(target);

    if (options.from_source) linkFromSource(b, step, opt) else linkFromBinary(b, step, opt);
}

fn linkFromSource(b: *Builder, step: *std.build.LibExeObjStep, options: Options) void {
    ensureSubmodules(b.allocator) catch |err| @panic(@errorName(err));

    step.addIncludeDir(thisDir() ++ "/libs/dawn/out/Debug/gen/include");
    step.addIncludeDir(thisDir() ++ "/libs/dawn/include");
    step.addIncludeDir(thisDir() ++ "/src/dawn");

    if (options.separate_libs) {
        const lib_mach_dawn_native = buildLibMachDawnNative(b, step, options);
        step.linkLibrary(lib_mach_dawn_native);

        const lib_dawn_common = buildLibDawnCommon(b, step, options);
        step.linkLibrary(lib_dawn_common);

        const lib_dawn_platform = buildLibDawnPlatform(b, step, options);
        step.linkLibrary(lib_dawn_platform);

        // dawn-native
        const lib_abseil_cpp = buildLibAbseilCpp(b, step, options);
        step.linkLibrary(lib_abseil_cpp);
        const lib_dawn_native = buildLibDawnNative(b, step, options);
        step.linkLibrary(lib_dawn_native);

        if (options.d3d12.?) {
            const lib_dxcompiler = buildLibDxcompiler(b, step, options);
            step.linkLibrary(lib_dxcompiler);
        }

        const lib_dawn_wire = buildLibDawnWire(b, step, options);
        step.linkLibrary(lib_dawn_wire);

        const lib_dawn_utils = buildLibDawnUtils(b, step, options);
        step.linkLibrary(lib_dawn_utils);

        const lib_spirv_tools = buildLibSPIRVTools(b, step, options);
        step.linkLibrary(lib_spirv_tools);

        const lib_tint = buildLibTint(b, step, options);
        step.linkLibrary(lib_tint);
        return;
    }

    var main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/dawn/dummy.zig" }) catch unreachable;
    const lib_dawn = b.addStaticLibrary("dawn", main_abs);
    lib_dawn.install();
    lib_dawn.setBuildMode(step.build_mode);
    lib_dawn.setTarget(step.target);
    lib_dawn.linkLibCpp();
    step.linkLibrary(lib_dawn);

    _ = buildLibMachDawnNative(b, lib_dawn, options);
    _ = buildLibDawnCommon(b, lib_dawn, options);
    _ = buildLibDawnPlatform(b, lib_dawn, options);
    _ = buildLibAbseilCpp(b, lib_dawn, options);
    _ = buildLibDawnNative(b, lib_dawn, options);
    _ = buildLibDawnWire(b, lib_dawn, options);
    _ = buildLibDawnUtils(b, lib_dawn, options);
    _ = buildLibSPIRVTools(b, lib_dawn, options);
    _ = buildLibTint(b, lib_dawn, options);
    if (options.d3d12.?) _ = buildLibDxcompiler(b, lib_dawn, options);
}

fn ensureSubmodules(allocator: std.mem.Allocator) !void {
    if (std.process.getEnvVarOwned(allocator, "NO_ENSURE_SUBMODULES")) |no_ensure_submodules| {
        if (std.mem.eql(u8, no_ensure_submodules, "true")) return;
    } else |_| {}
    const child = try std.ChildProcess.init(&.{ "git", "submodule", "update", "--init", "--recursive" }, allocator);
    child.cwd = thisDir();
    child.stderr = std.io.getStdErr();
    child.stdout = std.io.getStdOut();
    _ = try child.spawnAndWait();
}

pub fn linkFromBinary(b: *Builder, step: *std.build.LibExeObjStep, options: Options) void {
    const target = (std.zig.system.NativeTargetInfo.detect(b.allocator, step.target) catch unreachable).target;
    const binaries_available = switch (target.os.tag) {
        .windows => target.abi.isGnu(),
        .linux => target.cpu.arch.isX86() and (target.abi.isGnu() or target.abi.isMusl()),
        .macos => blk: {
            if (!target.cpu.arch.isX86() and !target.cpu.arch.isAARCH64()) break :blk false;
            if (!target.abi.isGnu()) break :blk false;

            // If min. target macOS version is lesser than the min version we have available, then
            // our binary is incompatible with the target.
            const min_available = std.builtin.Version{ .major = 12, .minor = 0 };
            if (target.os.version_range.semver.min.order(min_available) == .lt) break :blk false;
            break :blk true;
        },
        else => false,
    };
    if (!binaries_available) {
        const zig_triple = target.zigTriple(b.allocator) catch unreachable;
        std.log.err("gpu-dawn binaries for {s} not available.", .{zig_triple});
        std.log.err("-> open an issue: https://github.com/hexops/mach/issues", .{});
        std.log.err("-> build from source (takes 5-15 minutes):", .{});
        std.log.err("       use -Ddawn-from-source=true or set `Options.from_source = true`\n", .{});
        if (target.os.tag == .macos) {
            std.log.err("", .{});
            if (target.cpu.arch.isX86()) std.log.err("-> Did you mean to use -Dtarget=x86_64-macos.12 ?", .{});
            if (target.cpu.arch.isAARCH64()) std.log.err("-> Did you mean to use -Dtarget=aarch64-macos.12 ?", .{});
        }
        std.process.exit(1);
    }

    // Remove OS version range / glibc version from triple (we do not include that in our download
    // URLs.)
    var binary_target = std.zig.CrossTarget.fromTarget(target);
    binary_target.os_version_min = .{ .none = .{} };
    binary_target.os_version_max = .{ .none = .{} };
    binary_target.glibc_version = null;
    const zig_triple = binary_target.zigTriple(b.allocator) catch unreachable;
    ensureBinaryDownloaded(b.allocator, zig_triple, b.is_release, target.os.tag == .windows, options.binary_version);

    const base_cache_dir_rel = std.fs.path.join(b.allocator, &.{ "zig-cache", "mach", "gpu-dawn" }) catch unreachable;
    std.fs.cwd().makePath(base_cache_dir_rel) catch unreachable;
    const base_cache_dir = std.fs.cwd().realpathAlloc(b.allocator, base_cache_dir_rel) catch unreachable;
    const commit_cache_dir = std.fs.path.join(b.allocator, &.{ base_cache_dir, options.binary_version }) catch unreachable;
    const release_tag = if (b.is_release) "release-fast" else "debug";
    const target_cache_dir = std.fs.path.join(b.allocator, &.{ commit_cache_dir, zig_triple, release_tag }) catch unreachable;
    const include_dir = std.fs.path.join(b.allocator, &.{ commit_cache_dir, "include" }) catch unreachable;

    step.addLibraryPath(target_cache_dir);
    step.linkSystemLibrary("dawn");
    step.linkLibCpp();

    step.addIncludeDir(include_dir);
    step.addIncludeDir(thisDir() ++ "/src/dawn");

    if (options.linux_window_manager != null and options.linux_window_manager.? == .X11) {
        step.linkSystemLibrary("X11");
    }
    if (options.metal.?) {
        step.linkFramework("Metal");
        step.linkFramework("CoreGraphics");
        step.linkFramework("Foundation");
        step.linkFramework("IOKit");
        step.linkFramework("IOSurface");
        step.linkFramework("QuartzCore");
    }
    if (options.d3d12.?) {
        step.linkSystemLibrary("ole32");
        step.linkSystemLibrary("dxguid");
    }
}

pub fn ensureBinaryDownloaded(
    allocator: std.mem.Allocator,
    zig_triple: []const u8,
    is_release: bool,
    is_windows: bool,
    version: []const u8,
) void {
    // If zig-cache/mach/gpu-dawn/<git revision> does not exist:
    //   If on a commit in the main branch => rm -r zig-cache/mach/gpu-dawn/
    //   else => noop
    // If zig-cache/mach/gpu-dawn/<git revision>/<target> exists:
    //   noop
    // else:
    //   Download archive to zig-cache/mach/gpu-dawn/download/macos-aarch64
    //   Extract to zig-cache/mach/gpu-dawn/<git revision>/macos-aarch64/libgpu.a
    //   Remove zig-cache/mach/gpu-dawn/download

    const base_cache_dir_rel = std.fs.path.join(allocator, &.{ "zig-cache", "mach", "gpu-dawn" }) catch unreachable;
    std.fs.cwd().makePath(base_cache_dir_rel) catch unreachable;
    const base_cache_dir = std.fs.cwd().realpathAlloc(allocator, base_cache_dir_rel) catch unreachable;
    const commit_cache_dir = std.fs.path.join(allocator, &.{ base_cache_dir, version }) catch unreachable;

    if (!dirExists(commit_cache_dir)) {
        // Commit cache dir does not exist. If the commit we're on is in the main branch, we're
        // probably moving to a newer commit and so we should cleanup older cached binaries.
        const current_git_commit = getCurrentGitCommit(allocator) catch unreachable;
        if (gitBranchContainsCommit(allocator, "main", current_git_commit) catch false) {
            std.fs.deleteTreeAbsolute(base_cache_dir) catch {};
        }
    }

    const release_tag = if (is_release) "release-fast" else "debug";
    const target_cache_dir = std.fs.path.join(allocator, &.{ commit_cache_dir, zig_triple, release_tag }) catch unreachable;
    if (dirExists(target_cache_dir)) {
        return; // nothing to do, already have the binary
    }
    downloadBinary(allocator, commit_cache_dir, release_tag, target_cache_dir, zig_triple, is_windows, version) catch |err| {
        // A download failed, or extraction failed, so wipe out the directory to ensure we correctly
        // try again next time.
        std.fs.deleteTreeAbsolute(base_cache_dir) catch {};
        std.log.err("mach/gpu-dawn: prebuilt binary download failed: {s}", .{@errorName(err)});
        std.process.exit(1);
    };
}

fn downloadBinary(
    allocator: std.mem.Allocator,
    commit_cache_dir: []const u8,
    release_tag: []const u8,
    target_cache_dir: []const u8,
    zig_triple: []const u8,
    is_windows: bool,
    version: []const u8,
) !void {
    try ensureCanDownloadFiles(allocator);

    const download_dir = try std.fs.path.join(allocator, &.{ target_cache_dir, "download" });
    try std.fs.cwd().makePath(download_dir);

    // Replace "..." with "---" because GitHub releases has very weird restrictions on file names.
    // https://twitter.com/slimsag/status/1498025997987315713
    const github_triple = try std.mem.replaceOwned(u8, allocator, zig_triple, "...", "---");

    // Compose the download URL, e.g.:
    // https://github.com/hexops/mach-gpu-dawn/releases/download/release-6b59025/libdawn_x86_64-macos-gnu_debug.a.gz
    const lib_prefix = if (is_windows) "dawn_" else "libdawn_";
    const lib_ext = if (is_windows) ".lib" else ".a";
    const lib_file_name = if (is_windows) "dawn.lib" else "libdawn.a";
    const download_url = try std.mem.concat(allocator, u8, &.{
        "https://github.com/hexops/mach-gpu-dawn/releases/download/",
        version,
        "/",
        lib_prefix,
        github_triple,
        "_",
        release_tag,
        lib_ext,
        ".gz",
    });

    // Download and decompress libdawn
    const gz_target_file = try std.fs.path.join(allocator, &.{ download_dir, "compressed.gz" });
    try downloadFile(allocator, gz_target_file, download_url);
    const target_file = try std.fs.path.join(allocator, &.{ target_cache_dir, lib_file_name });
    try gzipDecompress(allocator, gz_target_file, target_file);

    // If we don't yet have the headers (these are shared across architectures), download them.
    const include_dir = try std.fs.path.join(allocator, &.{ commit_cache_dir, "include" });
    if (!dirExists(include_dir)) {
        // Compose the headers download URL, e.g.:
        // https://github.com/hexops/mach-gpu-dawn/releases/download/release-6b59025/headers.json.gz
        const headers_download_url = try std.mem.concat(allocator, u8, &.{
            "https://github.com/hexops/mach-gpu-dawn/releases/download/",
            version,
            "/headers.json.gz",
        });

        // Download and decompress headers.json.gz
        const headers_gz_target_file = try std.fs.path.join(allocator, &.{ download_dir, "headers.json.gz" });
        try downloadFile(allocator, headers_gz_target_file, headers_download_url);
        const headers_target_file = try std.fs.path.join(allocator, &.{ target_cache_dir, "headers.json" });
        try gzipDecompress(allocator, headers_gz_target_file, headers_target_file);

        // Extract headers JSON archive.
        try extractHeaders(allocator, headers_target_file, commit_cache_dir);
    }

    try std.fs.deleteTreeAbsolute(download_dir);
}

fn extractHeaders(allocator: std.mem.Allocator, json_file: []const u8, out_dir: []const u8) !void {
    const contents = try std.fs.cwd().readFileAlloc(allocator, json_file, std.math.maxInt(usize));

    var parser = std.json.Parser.init(allocator, false);
    defer parser.deinit();
    var tree = try parser.parse(contents);
    defer tree.deinit();

    var iter = tree.root.Object.iterator();
    while (iter.next()) |f| {
        const out_path = try std.fs.path.join(allocator, &.{ out_dir, f.key_ptr.* });
        try std.fs.cwd().makePath(std.fs.path.dirname(out_path).?);

        var new_file = try std.fs.createFileAbsolute(out_path, .{});
        defer new_file.close();
        try new_file.writeAll(f.value_ptr.*.String);
    }
}

fn dirExists(path: []const u8) bool {
    var dir = std.fs.openDirAbsolute(path, .{}) catch return false;
    dir.close();
    return true;
}

fn gzipDecompress(allocator: std.mem.Allocator, src_absolute_path: []const u8, dst_absolute_path: []const u8) !void {
    var file = try std.fs.openFileAbsolute(src_absolute_path, .{ .mode = .read_only });
    defer file.close();

    var gzip_stream = try std.compress.gzip.gzipStream(allocator, file.reader());
    defer gzip_stream.deinit();

    // Read and decompress the whole file
    const buf = try gzip_stream.reader().readAllAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(buf);

    var new_file = try std.fs.createFileAbsolute(dst_absolute_path, .{});
    defer new_file.close();

    try new_file.writeAll(buf);
}

fn gitBranchContainsCommit(allocator: std.mem.Allocator, branch: []const u8, commit: []const u8) !bool {
    const result = try std.ChildProcess.exec(.{
        .allocator = allocator,
        .argv = &.{ "git", "branch", branch, "--contains", commit },
        .cwd = thisDir(),
    });
    return result.term.Exited == 0;
}

fn getCurrentGitCommit(allocator: std.mem.Allocator) ![]const u8 {
    const result = try std.ChildProcess.exec(.{
        .allocator = allocator,
        .argv = &.{ "git", "rev-parse", "HEAD" },
        .cwd = thisDir(),
    });
    if (result.stdout.len > 0) return result.stdout[0 .. result.stdout.len - 1]; // trim newline
    return result.stdout;
}

fn gitClone(allocator: std.mem.Allocator, repository: []const u8, dir: []const u8) !bool {
    const result = try std.ChildProcess.exec(.{
        .allocator = allocator,
        .argv = &.{ "git", "clone", repository, dir },
        .cwd = thisDir(),
    });
    return result.term.Exited == 0;
}

fn downloadFile(allocator: std.mem.Allocator, target_file: []const u8, url: []const u8) !void {
    std.debug.print("downloading {s}..\n", .{url});
    const child = try std.ChildProcess.init(&.{ "curl", "-L", "-o", target_file, url }, allocator);
    child.cwd = thisDir();
    child.stderr = std.io.getStdErr();
    child.stdout = std.io.getStdOut();
    _ = try child.spawnAndWait();
}

fn ensureCanDownloadFiles(allocator: std.mem.Allocator) !void {
    const argv = &[_][]const u8{ "curl", "--version" };
    const result = try std.ChildProcess.exec(.{
        .allocator = allocator,
        .argv = argv,
        .cwd = thisDir(),
    });
    defer {
        allocator.free(result.stderr);
        allocator.free(result.stdout);
    }
    if (result.term.Exited != 0) {
        std.log.err("mach: error: 'curl --version' failed. Is curl not installed?", .{});
        std.process.exit(1);
    }
}

fn isLinuxDesktopLike(target: std.Target) bool {
    const tag = target.os.tag;
    return !tag.isDarwin() and tag != .windows and tag != .fuchsia and tag != .emscripten and !target.isAndroid();
}

fn buildLibMachDawnNative(b: *Builder, step: *std.build.LibExeObjStep, options: Options) *std.build.LibExeObjStep {
    const lib = if (!options.separate_libs) step else blk: {
        var main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/dawn/dummy.zig" }) catch unreachable;
        const separate_lib = b.addStaticLibrary("dawn-native-mach", main_abs);
        separate_lib.install();
        separate_lib.setBuildMode(step.build_mode);
        separate_lib.setTarget(step.target);
        separate_lib.linkLibCpp();
        break :blk separate_lib;
    };

    // TODO(build-system): pass system SDK options through
    glfw.link(b, lib, .{ .system_sdk = .{ .set_sysroot = false } });

    var cpp_flags = std.ArrayList([]const u8).init(b.allocator);
    options.appendFlags(&cpp_flags, false, true) catch unreachable;
    appendDawnEnableBackendTypeFlags(&cpp_flags, options) catch unreachable;
    cpp_flags.appendSlice(&.{
        include("libs/mach-glfw/upstream/glfw/include"),
        include("libs/dawn/out/Debug/gen/include"),
        include("libs/dawn/out/Debug/gen/src"),
        include("libs/dawn/include"),
        include("libs/dawn/src"),
    }) catch unreachable;
    const target = (std.zig.system.NativeTargetInfo.detect(b.allocator, step.target) catch unreachable).target;
    if (target.os.tag == .windows) {
        cpp_flags.appendSlice(&.{
            "-D_DEBUG",
            "-D_MT",
            "-D_DLL",
        }) catch unreachable;
    }

    lib.addCSourceFile("src/dawn/dawn_native_mach.cpp", cpp_flags.items);
    return lib;
}

// Builds common sources; derived from src/common/BUILD.gn
fn buildLibDawnCommon(b: *Builder, step: *std.build.LibExeObjStep, options: Options) *std.build.LibExeObjStep {
    const lib = if (!options.separate_libs) step else blk: {
        var main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/dawn/dummy.zig" }) catch unreachable;
        const separate_lib = b.addStaticLibrary("dawn-common", main_abs);
        separate_lib.install();
        separate_lib.setBuildMode(step.build_mode);
        separate_lib.setTarget(step.target);
        separate_lib.linkLibCpp();
        break :blk separate_lib;
    };

    var flags = std.ArrayList([]const u8).init(b.allocator);
    flags.append(include("libs/dawn/src")) catch unreachable;
    appendLangScannedSources(b, lib, options, .{
        .rel_dirs = &.{"libs/dawn/src/dawn/common/"},
        .flags = flags.items,
        .excluding_contains = &.{
            "test",
            "benchmark",
            "mock",
            "WindowsUtils.cpp",
        },
    }) catch unreachable;

    var cpp_sources = std.ArrayList([]const u8).init(b.allocator);
    const target = (std.zig.system.NativeTargetInfo.detect(b.allocator, step.target) catch unreachable).target;
    if (target.os.tag == .macos) {
        // TODO(build-system): pass system SDK options through
        system_sdk.include(b, lib, .{});
        lib.linkFramework("Foundation");
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn/src/dawn/common/SystemUtils_mac.mm" }) catch unreachable;
        cpp_sources.append(abs_path) catch unreachable;
    }
    if (target.os.tag == .windows) {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn/src/dawn/common/WindowsUtils.cpp" }) catch unreachable;
        cpp_sources.append(abs_path) catch unreachable;
    }

    var cpp_flags = std.ArrayList([]const u8).init(b.allocator);
    cpp_flags.appendSlice(flags.items) catch unreachable;
    options.appendFlags(&cpp_flags, false, true) catch unreachable;
    lib.addCSourceFiles(cpp_sources.items, cpp_flags.items);
    return lib;
}

// Build dawn platform sources; derived from src/dawn/platform/BUILD.gn
fn buildLibDawnPlatform(b: *Builder, step: *std.build.LibExeObjStep, options: Options) *std.build.LibExeObjStep {
    const lib = if (!options.separate_libs) step else blk: {
        var main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/dawn/dummy.zig" }) catch unreachable;
        const separate_lib = b.addStaticLibrary("dawn-platform", main_abs);
        separate_lib.install();
        separate_lib.setBuildMode(step.build_mode);
        separate_lib.setTarget(step.target);
        separate_lib.linkLibCpp();
        break :blk separate_lib;
    };

    var cpp_flags = std.ArrayList([]const u8).init(b.allocator);
    options.appendFlags(&cpp_flags, false, true) catch unreachable;
    cpp_flags.appendSlice(&.{
        include("libs/dawn/src"),
        include("libs/dawn/include"),

        include("libs/dawn/out/Debug/gen/include"),
    }) catch unreachable;

    var cpp_sources = std.ArrayList([]const u8).init(b.allocator);
    for ([_][]const u8{
        "src/dawn/platform/DawnPlatform.cpp",
        "src/dawn/platform/WorkerThread.cpp",
        "src/dawn/platform/tracing/EventTracer.cpp",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        cpp_sources.append(abs_path) catch unreachable;
    }

    lib.addCSourceFiles(cpp_sources.items, cpp_flags.items);
    return lib;
}

fn appendDawnEnableBackendTypeFlags(flags: *std.ArrayList([]const u8), options: Options) !void {
    const d3d12 = "-DDAWN_ENABLE_BACKEND_D3D12";
    const metal = "-DDAWN_ENABLE_BACKEND_METAL";
    const vulkan = "-DDAWN_ENABLE_BACKEND_VULKAN";
    const opengl = "-DDAWN_ENABLE_BACKEND_OPENGL";
    const desktop_gl = "-DDAWN_ENABLE_BACKEND_DESKTOP_GL";
    const opengl_es = "-DDAWN_ENABLE_BACKEND_OPENGLES";
    const backend_null = "-DDAWN_ENABLE_BACKEND_NULL";

    try flags.append(backend_null);
    if (options.d3d12.?) try flags.append(d3d12);
    if (options.metal.?) try flags.append(metal);
    if (options.vulkan.?) try flags.append(vulkan);
    if (options.desktop_gl.?) try flags.appendSlice(&.{ opengl, desktop_gl });
    if (options.opengl_es.?) try flags.appendSlice(&.{ opengl, opengl_es });
}

const dawn_d3d12_flags = &[_][]const u8{
    "-DDAWN_NO_WINDOWS_UI",
    "-D__EMULATE_UUID=1",
    "-Wno-nonportable-include-path",
    "-Wno-extern-c-compat",
    "-Wno-invalid-noreturn",
    "-Wno-pragma-pack",
    "-Wno-microsoft-template-shadow",
    "-Wno-unused-command-line-argument",
    "-Wno-microsoft-exception-spec",
    "-Wno-implicit-exception-spec-mismatch",
    "-Wno-unknown-attributes",
    "-Wno-c++20-extensions",
    "-D_CRT_SECURE_NO_WARNINGS",
    "-DWIN32_LEAN_AND_MEAN",
    "-DD3D10_ARBITRARY_HEADER_ORDERING",
    "-DNOMINMAX",
};

// Builds dawn native sources; derived from src/dawn/native/BUILD.gn
fn buildLibDawnNative(b: *Builder, step: *std.build.LibExeObjStep, options: Options) *std.build.LibExeObjStep {
    const lib = if (!options.separate_libs) step else blk: {
        var main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/dawn/dummy.zig" }) catch unreachable;
        const separate_lib = b.addStaticLibrary("dawn-native", main_abs);
        separate_lib.install();
        separate_lib.setBuildMode(step.build_mode);
        separate_lib.setTarget(step.target);
        separate_lib.linkLibCpp();
        break :blk separate_lib;
    };
    system_sdk.include(b, lib, .{});

    var flags = std.ArrayList([]const u8).init(b.allocator);
    appendDawnEnableBackendTypeFlags(&flags, options) catch unreachable;
    flags.appendSlice(&.{
        include("libs/dawn"),
        include("libs/dawn/src"),
        include("libs/dawn/include"),
        include("libs/dawn/third_party/vulkan-deps/spirv-tools/src/include"),
        include("libs/dawn/third_party/abseil-cpp"),
        include("libs/dawn/third_party/khronos"),

        // TODO(build-system): make these optional
        "-DTINT_BUILD_SPV_READER=1",
        "-DTINT_BUILD_SPV_WRITER=1",
        "-DTINT_BUILD_WGSL_READER=1",
        "-DTINT_BUILD_WGSL_WRITER=1",
        "-DTINT_BUILD_MSL_WRITER=1",
        "-DTINT_BUILD_HLSL_WRITER=1",
        "-DTINT_BUILD_GLSL_WRITER=1",

        include("libs/dawn/third_party/tint"),
        include("libs/dawn/third_party/tint/include"),

        include("libs/dawn/out/Debug/gen/include"),
        include("libs/dawn/out/Debug/gen/src"),
    }) catch unreachable;
    if (options.d3d12.?) flags.appendSlice(dawn_d3d12_flags) catch unreachable;

    appendLangScannedSources(b, lib, options, .{
        .rel_dirs = &.{
            "libs/dawn/out/Debug/gen/src/dawn/",
            "libs/dawn/src/dawn/native/",
            "libs/dawn/src/dawn/native/utils/",
        },
        .flags = flags.items,
        .excluding_contains = &.{
            "test",
            "benchmark",
            "mock",
            "SpirvValidation.cpp",
            "XlibXcbFunctions.cpp",
        },
    }) catch unreachable;

    // dawn_native_gen
    appendLangScannedSources(b, lib, options, .{
        .rel_dirs = &.{
            "libs/dawn/out/Debug/gen/src/dawn/native/",
        },
        .flags = flags.items,
        .excluding_contains = &.{ "test", "benchmark", "mock" },
    }) catch unreachable;

    // TODO(build-system): could allow enable_vulkan_validation_layers here. See src/dawn/native/BUILD.gn
    // TODO(build-system): allow use_angle here. See src/dawn/native/BUILD.gn
    // TODO(build-system): could allow use_swiftshader here. See src/dawn/native/BUILD.gn

    var cpp_sources = std.ArrayList([]const u8).init(b.allocator);
    if (options.d3d12.?) {
        lib.linkSystemLibrary("dxgi");
        lib.linkSystemLibrary("dxguid");

        for ([_][]const u8{
            "src/dawn/mingw_helpers.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), path }) catch unreachable;
            cpp_sources.append(abs_path) catch unreachable;
        }

        appendLangScannedSources(b, lib, options, .{
            .rel_dirs = &.{
                "libs/dawn/src/dawn/native/d3d12/",
            },
            .flags = flags.items,
            .excluding_contains = &.{ "test", "benchmark", "mock" },
        }) catch unreachable;
    }
    if (options.metal.?) {
        lib.linkFramework("Metal");
        lib.linkFramework("CoreGraphics");
        lib.linkFramework("Foundation");
        lib.linkFramework("IOKit");
        lib.linkFramework("IOSurface");
        lib.linkFramework("QuartzCore");

        appendLangScannedSources(b, lib, options, .{
            .objc = true,
            .rel_dirs = &.{
                "libs/dawn/src/dawn/native/metal/",
                "libs/dawn/src/dawn/native/",
            },
            .flags = flags.items,
            .excluding_contains = &.{ "test", "benchmark", "mock" },
        }) catch unreachable;
    }

    if (options.linux_window_manager != null and options.linux_window_manager.? == .X11) {
        lib.linkSystemLibrary("X11");
        for ([_][]const u8{
            "src/dawn/native/XlibXcbFunctions.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            cpp_sources.append(abs_path) catch unreachable;
        }
    }

    for ([_][]const u8{
        "src/dawn/native/null/DeviceNull.cpp",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        cpp_sources.append(abs_path) catch unreachable;
    }

    if (options.desktop_gl.? or options.vulkan.?) {
        for ([_][]const u8{
            "src/dawn/native/SpirvValidation.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            cpp_sources.append(abs_path) catch unreachable;
        }
    }

    if (options.desktop_gl.?) {
        appendLangScannedSources(b, lib, options, .{
            .rel_dirs = &.{
                "libs/dawn/out/Debug/gen/src/dawn/native/opengl/",
                "libs/dawn/src/dawn/native/opengl/",
            },
            .flags = flags.items,
            .excluding_contains = &.{ "test", "benchmark", "mock" },
        }) catch unreachable;
    }

    const target = (std.zig.system.NativeTargetInfo.detect(b.allocator, step.target) catch unreachable).target;
    if (options.vulkan.?) {
        appendLangScannedSources(b, lib, options, .{
            .rel_dirs = &.{
                "libs/dawn/src/dawn/native/vulkan/",
            },
            .flags = flags.items,
            .excluding_contains = &.{ "test", "benchmark", "mock" },
        }) catch unreachable;

        if (isLinuxDesktopLike(target)) {
            for ([_][]const u8{
                "src/dawn/native/vulkan/external_memory/MemoryServiceOpaqueFD.cpp",
                "src/dawn/native/vulkan/external_semaphore/SemaphoreServiceFD.cpp",
            }) |path| {
                var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
                cpp_sources.append(abs_path) catch unreachable;
            }
        } else if (target.os.tag == .fuchsia) {
            for ([_][]const u8{
                "src/dawn/native/vulkan/external_memory/MemoryServiceZirconHandle.cpp",
                "src/dawn/native/vulkan/external_semaphore/SemaphoreServiceZirconHandle.cpp",
            }) |path| {
                var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
                cpp_sources.append(abs_path) catch unreachable;
            }
        } else {
            for ([_][]const u8{
                "src/dawn/native/vulkan/external_memory/MemoryServiceNull.cpp",
                "src/dawn/native/vulkan/external_semaphore/SemaphoreServiceNull.cpp",
            }) |path| {
                var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
                cpp_sources.append(abs_path) catch unreachable;
            }
        }
    }

    // TODO(build-system): fuchsia: add is_fuchsia here from upstream source file

    if (options.vulkan.?) {
        // TODO(build-system): vulkan
        //     if (enable_vulkan_validation_layers) {
        //       defines += [
        //         "DAWN_ENABLE_VULKAN_VALIDATION_LAYERS",
        //         "DAWN_VK_DATA_DIR=\"$vulkan_data_subdir\"",
        //       ]
        //     }
        //     if (enable_vulkan_loader) {
        //       data_deps += [ "${dawn_vulkan_loader_dir}:libvulkan" ]
        //       defines += [ "DAWN_ENABLE_VULKAN_LOADER" ]
        //     }
    }
    // TODO(build-system): swiftshader
    //     if (use_swiftshader) {
    //       data_deps += [
    //         "${dawn_swiftshader_dir}/src/Vulkan:icd_file",
    //         "${dawn_swiftshader_dir}/src/Vulkan:swiftshader_libvulkan",
    //       ]
    //       defines += [
    //         "DAWN_ENABLE_SWIFTSHADER",
    //         "DAWN_SWIFTSHADER_VK_ICD_JSON=\"${swiftshader_icd_file_name}\"",
    //       ]
    //     }
    //   }

    if (options.opengl_es.?) {
        // TODO(build-system): gles
        //   if (use_angle) {
        //     data_deps += [
        //       "${dawn_angle_dir}:libEGL",
        //       "${dawn_angle_dir}:libGLESv2",
        //     ]
        //   }
        // }
    }

    for ([_][]const u8{
        "src/dawn/native/null/NullBackend.cpp",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        cpp_sources.append(abs_path) catch unreachable;
    }

    if (options.d3d12.?) {
        for ([_][]const u8{
            "src/dawn/native/d3d12/D3D12Backend.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            cpp_sources.append(abs_path) catch unreachable;
        }
    }
    if (options.desktop_gl.?) {
        for ([_][]const u8{
            "src/dawn/native/opengl/OpenGLBackend.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            cpp_sources.append(abs_path) catch unreachable;
        }
    }
    if (options.vulkan.?) {
        for ([_][]const u8{
            "src/dawn/native/vulkan/VulkanBackend.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            cpp_sources.append(abs_path) catch unreachable;
        }
        // TODO(build-system): vulkan
        //     if (enable_vulkan_validation_layers) {
        //       data_deps =
        //           [ "${dawn_vulkan_validation_layers_dir}:vulkan_validation_layers" ]
        //       if (!is_android) {
        //         data_deps +=
        //             [ "${dawn_vulkan_validation_layers_dir}:vulkan_gen_json_files" ]
        //       }
        //     }
    }

    var cpp_flags = std.ArrayList([]const u8).init(b.allocator);
    cpp_flags.appendSlice(flags.items) catch unreachable;
    options.appendFlags(&cpp_flags, false, true) catch unreachable;
    lib.addCSourceFiles(cpp_sources.items, cpp_flags.items);
    return lib;
}

// Builds third party tint sources; derived from third_party/tint/src/tint/BUILD.gn
fn buildLibTint(b: *Builder, step: *std.build.LibExeObjStep, options: Options) *std.build.LibExeObjStep {
    const lib = if (!options.separate_libs) step else blk: {
        var main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/dawn/dummy.zig" }) catch unreachable;
        const separate_lib = b.addStaticLibrary("tint", main_abs);
        separate_lib.install();
        separate_lib.setBuildMode(step.build_mode);
        separate_lib.setTarget(step.target);
        separate_lib.linkLibCpp();
        break :blk separate_lib;
    };

    var flags = std.ArrayList([]const u8).init(b.allocator);
    flags.appendSlice(&.{
        // TODO(build-system): make these optional
        "-DTINT_BUILD_SPV_READER=1",
        "-DTINT_BUILD_SPV_WRITER=1",
        "-DTINT_BUILD_WGSL_READER=1",
        "-DTINT_BUILD_WGSL_WRITER=1",
        "-DTINT_BUILD_MSL_WRITER=1",
        "-DTINT_BUILD_HLSL_WRITER=1",
        "-DTINT_BUILD_GLSL_WRITER=1",

        include("libs/dawn"),
        include("libs/dawn/third_party/tint"),
        include("libs/dawn/third_party/tint/include"),

        // Required for TINT_BUILD_SPV_READER=1 and TINT_BUILD_SPV_WRITER=1, if specified
        include("libs/dawn/third_party/vulkan-deps"),
        include("libs/dawn/third_party/vulkan-deps/spirv-tools/src"),
        include("libs/dawn/third_party/vulkan-deps/spirv-tools/src/include"),
        include("libs/dawn/third_party/vulkan-deps/spirv-headers/src/include"),
        include("libs/dawn/out/Debug/gen/third_party/vulkan-deps/spirv-tools/src"),
        include("libs/dawn/out/Debug/gen/third_party/vulkan-deps/spirv-tools/src/include"),
    }) catch unreachable;

    // libtint_core_all_src
    appendLangScannedSources(b, lib, options, .{
        .rel_dirs = &.{
            "libs/dawn/third_party/tint/src/tint/ast/",
            "libs/dawn/third_party/tint/src/tint/",
            "libs/dawn/third_party/tint/src/tint/diagnostic/",
            "libs/dawn/third_party/tint/src/tint/inspector/",
            "libs/dawn/third_party/tint/src/tint/reader/",
            "libs/dawn/third_party/tint/src/tint/resolver/",
            "libs/dawn/third_party/tint/src/tint/utils",
            "libs/dawn/third_party/tint/src/tint/text/",
            "libs/dawn/third_party/tint/src/tint/transform/",
            "libs/dawn/third_party/tint/src/tint/transform/utils",
            "libs/dawn/third_party/tint/src/tint/writer/",
            "libs/dawn/third_party/tint/src/tint/ast/",
            "libs/dawn/third_party/tint/src/tint/val/",
        },
        .flags = flags.items,
        .excluding_contains = &.{ "test", "bench", "printer_windows", "printer_linux", "printer_other", "glsl.cc" },
    }) catch unreachable;

    var cpp_sources = std.ArrayList([]const u8).init(b.allocator);
    const target = (std.zig.system.NativeTargetInfo.detect(b.allocator, step.target) catch unreachable).target;
    switch (target.os.tag) {
        .windows => cpp_sources.append(thisDir() ++ "/libs/dawn/third_party/tint/src/tint/diagnostic/printer_windows.cc") catch unreachable,
        .linux => cpp_sources.append(thisDir() ++ "/libs/dawn/third_party/tint/src/tint/diagnostic/printer_linux.cc") catch unreachable,
        else => cpp_sources.append(thisDir() ++ "/libs/dawn/third_party/tint/src/tint/diagnostic/printer_other.cc") catch unreachable,
    }

    // libtint_sem_src
    appendLangScannedSources(b, lib, options, .{
        .rel_dirs = &.{
            "libs/dawn/third_party/tint/src/tint/sem/",
        },
        .flags = flags.items,
        .excluding_contains = &.{ "test", "benchmark" },
    }) catch unreachable;

    // libtint_spv_reader_src
    appendLangScannedSources(b, lib, options, .{
        .rel_dirs = &.{
            "libs/dawn/third_party/tint/src/tint/reader/spirv/",
        },
        .flags = flags.items,
        .excluding_contains = &.{ "test", "benchmark" },
    }) catch unreachable;

    // libtint_spv_writer_src
    appendLangScannedSources(b, lib, options, .{
        .rel_dirs = &.{
            "libs/dawn/third_party/tint/src/tint/writer/spirv/",
        },
        .flags = flags.items,
        .excluding_contains = &.{ "test", "bench" },
    }) catch unreachable;

    // TODO(build-system): make optional
    // libtint_wgsl_reader_src
    appendLangScannedSources(b, lib, options, .{
        .rel_dirs = &.{
            "libs/dawn/third_party/tint/src/tint/reader/wgsl/",
        },
        .flags = flags.items,
        .excluding_contains = &.{ "test", "bench" },
    }) catch unreachable;

    // TODO(build-system): make optional
    // libtint_wgsl_writer_src
    appendLangScannedSources(b, lib, options, .{
        .rel_dirs = &.{
            "libs/dawn/third_party/tint/src/tint/writer/wgsl/",
        },
        .flags = flags.items,
        .excluding_contains = &.{ "test", "bench" },
    }) catch unreachable;

    // TODO(build-system): make optional
    // libtint_msl_writer_src
    appendLangScannedSources(b, lib, options, .{
        .rel_dirs = &.{
            "libs/dawn/third_party/tint/src/tint/writer/msl/",
        },
        .flags = flags.items,
        .excluding_contains = &.{ "test", "bench" },
    }) catch unreachable;

    // TODO(build-system): make optional
    // libtint_hlsl_writer_src
    appendLangScannedSources(b, lib, options, .{
        .rel_dirs = &.{
            "libs/dawn/third_party/tint/src/tint/writer/hlsl/",
        },
        .flags = flags.items,
        .excluding_contains = &.{ "test", "bench" },
    }) catch unreachable;

    // TODO(build-system): make optional
    // libtint_glsl_writer_src
    appendLangScannedSources(b, lib, options, .{
        .rel_dirs = &.{
            "libs/dawn/third_party/tint/src/tint/writer/glsl/",
        },
        .flags = flags.items,
        .excluding_contains = &.{ "test", "bench" },
    }) catch unreachable;
    for ([_][]const u8{
        "third_party/tint/src/tint/transform/glsl.cc",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        cpp_sources.append(abs_path) catch unreachable;
    }

    var cpp_flags = std.ArrayList([]const u8).init(b.allocator);
    cpp_flags.appendSlice(flags.items) catch unreachable;
    options.appendFlags(&cpp_flags, false, true) catch unreachable;
    lib.addCSourceFiles(cpp_sources.items, cpp_flags.items);
    return lib;
}

// Builds third_party/vulkan-deps/spirv-tools sources; derived from third_party/vulkan-deps/spirv-tools/src/BUILD.gn
fn buildLibSPIRVTools(b: *Builder, step: *std.build.LibExeObjStep, options: Options) *std.build.LibExeObjStep {
    const lib = if (!options.separate_libs) step else blk: {
        var main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/dawn/dummy.zig" }) catch unreachable;
        const separate_lib = b.addStaticLibrary("spirv-tools", main_abs);
        separate_lib.install();
        separate_lib.setBuildMode(step.build_mode);
        separate_lib.setTarget(step.target);
        separate_lib.linkLibCpp();
        break :blk separate_lib;
    };

    var flags = std.ArrayList([]const u8).init(b.allocator);
    flags.appendSlice(&.{
        include("libs/dawn"),
        include("libs/dawn/third_party/vulkan-deps/spirv-tools/src"),
        include("libs/dawn/third_party/vulkan-deps/spirv-tools/src/include"),
        include("libs/dawn/third_party/vulkan-deps/spirv-headers/src/include"),
        include("libs/dawn/out/Debug/gen/third_party/vulkan-deps/spirv-tools/src"),
        include("libs/dawn/out/Debug/gen/third_party/vulkan-deps/spirv-tools/src/include"),
        include("libs/dawn/third_party/vulkan-deps/spirv-headers/src/include/spirv/unified1"),
    }) catch unreachable;

    // spvtools
    appendLangScannedSources(b, lib, options, .{
        .rel_dirs = &.{
            "libs/dawn/third_party/vulkan-deps/spirv-tools/src/source/",
            "libs/dawn/third_party/vulkan-deps/spirv-tools/src/source/util/",
        },
        .flags = flags.items,
        .excluding_contains = &.{ "test", "benchmark" },
    }) catch unreachable;

    // spvtools_val
    appendLangScannedSources(b, lib, options, .{
        .rel_dirs = &.{
            "libs/dawn/third_party/vulkan-deps/spirv-tools/src/source/val/",
        },
        .flags = flags.items,
        .excluding_contains = &.{ "test", "benchmark" },
    }) catch unreachable;

    // spvtools_opt
    appendLangScannedSources(b, lib, options, .{
        .rel_dirs = &.{
            "libs/dawn/third_party/vulkan-deps/spirv-tools/src/source/opt/",
        },
        .flags = flags.items,
        .excluding_contains = &.{ "test", "benchmark" },
    }) catch unreachable;

    // spvtools_link
    appendLangScannedSources(b, lib, options, .{
        .rel_dirs = &.{
            "libs/dawn/third_party/vulkan-deps/spirv-tools/src/source/link/",
        },
        .flags = flags.items,
        .excluding_contains = &.{ "test", "benchmark" },
    }) catch unreachable;
    return lib;
}

// Builds third_party/abseil sources; derived from:
//
// ```
// $ find third_party/abseil-cpp/absl | grep '\.cc' | grep -v 'test' | grep -v 'benchmark' | grep -v gaussian_distribution_gentables | grep -v print_hash_of | grep -v chi_square
// ```
//
fn buildLibAbseilCpp(b: *Builder, step: *std.build.LibExeObjStep, options: Options) *std.build.LibExeObjStep {
    const lib = if (!options.separate_libs) step else blk: {
        var main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/dawn/dummy.zig" }) catch unreachable;
        const separate_lib = b.addStaticLibrary("abseil-cpp-common", main_abs);
        separate_lib.install();
        separate_lib.setBuildMode(step.build_mode);
        separate_lib.setTarget(step.target);
        separate_lib.linkLibCpp();
        break :blk separate_lib;
    };
    system_sdk.include(b, lib, .{});

    const target = (std.zig.system.NativeTargetInfo.detect(b.allocator, step.target) catch unreachable).target;
    if (target.os.tag == .macos) lib.linkFramework("CoreFoundation");
    if (target.os.tag == .windows) lib.linkSystemLibrary("bcrypt");

    var flags = std.ArrayList([]const u8).init(b.allocator);
    flags.appendSlice(&.{
        include("libs/dawn"),
        include("libs/dawn/third_party/abseil-cpp"),
    }) catch unreachable;
    if (target.os.tag == .windows) flags.appendSlice(&.{
        "-DABSL_FORCE_THREAD_IDENTITY_MODE=2",
        "-DWIN32_LEAN_AND_MEAN",
        "-DD3D10_ARBITRARY_HEADER_ORDERING",
        "-D_CRT_SECURE_NO_WARNINGS",
        "-DNOMINMAX",
    }) catch unreachable;

    // absl
    appendLangScannedSources(b, lib, options, .{
        .rel_dirs = &.{
            "libs/dawn/third_party/abseil-cpp/absl/strings/",
            "libs/dawn/third_party/abseil-cpp/absl/strings/internal/",
            "libs/dawn/third_party/abseil-cpp/absl/strings/internal/str_format/",
            "libs/dawn/third_party/abseil-cpp/absl/types/",
            "libs/dawn/third_party/abseil-cpp/absl/flags/internal/",
            "libs/dawn/third_party/abseil-cpp/absl/flags/",
            "libs/dawn/third_party/abseil-cpp/absl/synchronization/",
            "libs/dawn/third_party/abseil-cpp/absl/synchronization/internal/",
            "libs/dawn/third_party/abseil-cpp/absl/hash/internal/",
            "libs/dawn/third_party/abseil-cpp/absl/debugging/",
            "libs/dawn/third_party/abseil-cpp/absl/debugging/internal/",
            "libs/dawn/third_party/abseil-cpp/absl/status/",
            "libs/dawn/third_party/abseil-cpp/absl/time/internal/cctz/src/",
            "libs/dawn/third_party/abseil-cpp/absl/time/",
            "libs/dawn/third_party/abseil-cpp/absl/container/internal/",
            "libs/dawn/third_party/abseil-cpp/absl/numeric/",
            "libs/dawn/third_party/abseil-cpp/absl/random/",
            "libs/dawn/third_party/abseil-cpp/absl/random/internal/",
            "libs/dawn/third_party/abseil-cpp/absl/base/internal/",
            "libs/dawn/third_party/abseil-cpp/absl/base/",
        },
        .flags = flags.items,
        .excluding_contains = &.{ "_test", "_testing", "benchmark", "print_hash_of.cc", "gaussian_distribution_gentables.cc" },
    }) catch unreachable;
    return lib;
}

// Buids dawn wire sources; derived from src/dawn/wire/BUILD.gn
fn buildLibDawnWire(b: *Builder, step: *std.build.LibExeObjStep, options: Options) *std.build.LibExeObjStep {
    const lib = if (!options.separate_libs) step else blk: {
        var main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/dawn/dummy.zig" }) catch unreachable;
        const separate_lib = b.addStaticLibrary("dawn-wire", main_abs);
        separate_lib.install();
        separate_lib.setBuildMode(step.build_mode);
        separate_lib.setTarget(step.target);
        separate_lib.linkLibCpp();
        break :blk separate_lib;
    };

    var flags = std.ArrayList([]const u8).init(b.allocator);
    flags.appendSlice(&.{
        include("libs/dawn"),
        include("libs/dawn/src"),
        include("libs/dawn/include"),
        include("libs/dawn/out/Debug/gen/include"),
        include("libs/dawn/out/Debug/gen/src"),
    }) catch unreachable;

    appendLangScannedSources(b, lib, options, .{
        .rel_dirs = &.{
            "libs/dawn/out/Debug/gen/src/dawn/wire/",
            "libs/dawn/out/Debug/gen/src/dawn/wire/client/",
            "libs/dawn/out/Debug/gen/src/dawn/wire/server/",
            "libs/dawn/src/dawn/wire/",
            "libs/dawn/src/dawn/wire/client/",
            "libs/dawn/src/dawn/wire/server/",
        },
        .flags = flags.items,
        .excluding_contains = &.{ "test", "benchmark", "mock" },
    }) catch unreachable;
    return lib;
}

// Builds dawn utils sources; derived from src/dawn/utils/BUILD.gn
fn buildLibDawnUtils(b: *Builder, step: *std.build.LibExeObjStep, options: Options) *std.build.LibExeObjStep {
    const lib = if (!options.separate_libs) step else blk: {
        var main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/dawn/dummy.zig" }) catch unreachable;
        const separate_lib = b.addStaticLibrary("dawn-utils", main_abs);
        separate_lib.install();
        separate_lib.setBuildMode(step.build_mode);
        separate_lib.setTarget(step.target);
        separate_lib.linkLibCpp();
        break :blk separate_lib;
    };
    glfw.link(b, lib, .{ .system_sdk = .{ .set_sysroot = false } });

    var flags = std.ArrayList([]const u8).init(b.allocator);
    appendDawnEnableBackendTypeFlags(&flags, options) catch unreachable;
    flags.appendSlice(&.{
        include("libs/mach-glfw/upstream/glfw/include"),
        include("libs/dawn/src"),
        include("libs/dawn/include"),
        include("libs/dawn/out/Debug/gen/include"),
    }) catch unreachable;

    var cpp_sources = std.ArrayList([]const u8).init(b.allocator);
    for ([_][]const u8{
        "src/dawn/utils/BackendBinding.cpp",
        "src/dawn/utils/NullBinding.cpp",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        cpp_sources.append(abs_path) catch unreachable;
    }

    if (options.d3d12.?) {
        for ([_][]const u8{
            "src/dawn/utils/D3D12Binding.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            cpp_sources.append(abs_path) catch unreachable;
        }
        flags.appendSlice(dawn_d3d12_flags) catch unreachable;
    }
    if (options.metal.?) {
        for ([_][]const u8{
            "src/dawn/utils/MetalBinding.mm",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            cpp_sources.append(abs_path) catch unreachable;
        }
    }

    if (options.desktop_gl.?) {
        for ([_][]const u8{
            "src/dawn/utils/OpenGLBinding.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            cpp_sources.append(abs_path) catch unreachable;
        }
    }

    if (options.vulkan.?) {
        for ([_][]const u8{
            "src/dawn/utils/VulkanBinding.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            cpp_sources.append(abs_path) catch unreachable;
        }
    }

    var cpp_flags = std.ArrayList([]const u8).init(b.allocator);
    cpp_flags.appendSlice(flags.items) catch unreachable;
    options.appendFlags(&cpp_flags, false, true) catch unreachable;
    lib.addCSourceFiles(cpp_sources.items, cpp_flags.items);
    return lib;
}

// Buids dxcompiler sources; derived from libs/DirectXShaderCompiler/CMakeLists.txt
fn buildLibDxcompiler(b: *Builder, step: *std.build.LibExeObjStep, options: Options) *std.build.LibExeObjStep {
    const lib = if (!options.separate_libs) step else blk: {
        var main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/dawn/dummy.zig" }) catch unreachable;
        const separate_lib = b.addStaticLibrary("dxcompiler", main_abs);
        separate_lib.install();
        separate_lib.setBuildMode(step.build_mode);
        separate_lib.setTarget(step.target);
        separate_lib.linkLibCpp();
        break :blk separate_lib;
    };
    system_sdk.include(b, lib, .{});

    lib.linkSystemLibrary("oleaut32");
    lib.linkSystemLibrary("ole32");
    lib.linkSystemLibrary("dbghelp");
    lib.linkSystemLibrary("dxguid");
    lib.linkLibCpp();

    var flags = std.ArrayList([]const u8).init(b.allocator);
    flags.appendSlice(&.{
        include("libs/"),
        include("libs/DirectXShaderCompiler/include/llvm/llvm_assert"),
        include("libs/DirectXShaderCompiler/include"),
        include("libs/DirectXShaderCompiler/build/include"),
        include("libs/DirectXShaderCompiler/build/lib/HLSL"),
        include("libs/DirectXShaderCompiler/build/lib/DxilPIXPasses"),
        include("libs/DirectXShaderCompiler/build/include"),
        "-DUNREFERENCED_PARAMETER(x)=",
        "-Wno-inconsistent-missing-override",
        "-Wno-missing-exception-spec",
        "-Wno-switch",
        "-Wno-deprecated-declarations",
        "-Wno-macro-redefined", // regex2.h and regcomp.c requires this for OUT redefinition
        "-DMSFT_SUPPORTS_CHILD_PROCESSES=1",
        "-DHAVE_LIBPSAPI=1",
        "-DHAVE_LIBSHELL32=1",
        "-DLLVM_ON_WIN32=1",
    }) catch unreachable;

    appendLangScannedSources(b, lib, options, .{
        .zero_debug_symbols = true,
        .rel_dirs = &.{
            "libs/DirectXShaderCompiler/lib/Analysis/IPA",
            "libs/DirectXShaderCompiler/lib/Analysis",
            "libs/DirectXShaderCompiler/lib/AsmParser",
            "libs/DirectXShaderCompiler/lib/Bitcode/Writer",
            "libs/DirectXShaderCompiler/lib/DxcBindingTable",
            "libs/DirectXShaderCompiler/lib/DxcSupport",
            "libs/DirectXShaderCompiler/lib/DxilContainer",
            "libs/DirectXShaderCompiler/lib/DxilPIXPasses",
            "libs/DirectXShaderCompiler/lib/DxilRootSignature",
            "libs/DirectXShaderCompiler/lib/DXIL",
            "libs/DirectXShaderCompiler/lib/DxrFallback",
            "libs/DirectXShaderCompiler/lib/HLSL",
            "libs/DirectXShaderCompiler/lib/IRReader",
            "libs/DirectXShaderCompiler/lib/IR",
            "libs/DirectXShaderCompiler/lib/Linker",
            "libs/DirectXShaderCompiler/lib/miniz",
            "libs/DirectXShaderCompiler/lib/Option",
            "libs/DirectXShaderCompiler/lib/PassPrinters",
            "libs/DirectXShaderCompiler/lib/Passes",
            "libs/DirectXShaderCompiler/lib/ProfileData",
            "libs/DirectXShaderCompiler/lib/Target",
            "libs/DirectXShaderCompiler/lib/Transforms/InstCombine",
            "libs/DirectXShaderCompiler/lib/Transforms/IPO",
            "libs/DirectXShaderCompiler/lib/Transforms/Scalar",
            "libs/DirectXShaderCompiler/lib/Transforms/Utils",
            "libs/DirectXShaderCompiler/lib/Transforms/Vectorize",
        },
        .flags = flags.items,
    }) catch unreachable;

    appendLangScannedSources(b, lib, options, .{
        .zero_debug_symbols = true,
        .rel_dirs = &.{
            "libs/DirectXShaderCompiler/lib/Support",
        },
        .flags = flags.items,
        .excluding_contains = &.{
            "DynamicLibrary.cpp", // ignore, HLSL_IGNORE_SOURCES
            "PluginLoader.cpp", // ignore, HLSL_IGNORE_SOURCES
            "Path.cpp", // ignore, LLVM_INCLUDE_TESTS
            "DynamicLibrary.cpp", // ignore
        },
    }) catch unreachable;

    appendLangScannedSources(b, lib, options, .{
        .zero_debug_symbols = true,
        .rel_dirs = &.{
            "libs/DirectXShaderCompiler/lib/Bitcode/Reader",
        },
        .flags = flags.items,
        .excluding_contains = &.{
            "BitReader.cpp", // ignore
        },
    }) catch unreachable;
    return lib;
}

fn include(comptime rel: []const u8) []const u8 {
    return "-I" ++ thisDir() ++ "/" ++ rel;
}

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}

fn appendLangScannedSources(
    b: *Builder,
    step: *std.build.LibExeObjStep,
    options: Options,
    args: struct {
        zero_debug_symbols: bool = false,
        flags: []const []const u8,
        rel_dirs: []const []const u8 = &.{},
        objc: bool = false,
        excluding: []const []const u8 = &.{},
        excluding_contains: []const []const u8 = &.{},
    },
) !void {
    var cpp_flags = std.ArrayList([]const u8).init(b.allocator);
    try cpp_flags.appendSlice(args.flags);
    options.appendFlags(&cpp_flags, args.zero_debug_symbols, true) catch unreachable;
    const cpp_extensions: []const []const u8 = if (args.objc) &.{".mm"} else &.{ ".cpp", ".cc" };
    try appendScannedSources(b, step, .{
        .flags = cpp_flags.items,
        .rel_dirs = args.rel_dirs,
        .extensions = cpp_extensions,
        .excluding = args.excluding,
        .excluding_contains = args.excluding_contains,
    });

    var flags = std.ArrayList([]const u8).init(b.allocator);
    try flags.appendSlice(args.flags);
    options.appendFlags(&flags, args.zero_debug_symbols, false) catch unreachable;
    const c_extensions: []const []const u8 = if (args.objc) &.{".m"} else &.{".c"};
    try appendScannedSources(b, step, .{
        .flags = flags.items,
        .rel_dirs = args.rel_dirs,
        .extensions = c_extensions,
        .excluding = args.excluding,
        .excluding_contains = args.excluding_contains,
    });
}

fn appendScannedSources(b: *Builder, step: *std.build.LibExeObjStep, args: struct {
    flags: []const []const u8,
    rel_dirs: []const []const u8 = &.{},
    extensions: []const []const u8,
    excluding: []const []const u8 = &.{},
    excluding_contains: []const []const u8 = &.{},
}) !void {
    var sources = std.ArrayList([]const u8).init(b.allocator);
    for (args.rel_dirs) |rel_dir| {
        try scanSources(b, &sources, rel_dir, args.extensions, args.excluding, args.excluding_contains);
    }
    step.addCSourceFiles(sources.items, args.flags);
}

/// Scans rel_dir for sources ending with one of the provided extensions, excluding relative paths
/// listed in the excluded list.
/// Results are appended to the dst ArrayList.
fn scanSources(
    b: *Builder,
    dst: *std.ArrayList([]const u8),
    rel_dir: []const u8,
    extensions: []const []const u8,
    excluding: []const []const u8,
    excluding_contains: []const []const u8,
) !void {
    const abs_dir = try std.mem.concat(b.allocator, u8, &.{ thisDir(), "/", rel_dir });
    var dir = try std.fs.openDirAbsolute(abs_dir, .{ .iterate = true });
    defer dir.close();
    var dir_it = dir.iterate();
    while (try dir_it.next()) |entry| {
        if (entry.kind != .File) continue;
        var abs_path = try std.fs.path.join(b.allocator, &.{ abs_dir, entry.name });
        abs_path = try std.fs.realpathAlloc(b.allocator, abs_path);

        const allowed_extension = blk: {
            const ours = std.fs.path.extension(entry.name);
            for (extensions) |ext| {
                if (std.mem.eql(u8, ours, ext)) break :blk true;
            }
            break :blk false;
        };
        if (!allowed_extension) continue;

        const excluded = blk: {
            for (excluding) |excluded| {
                if (std.mem.eql(u8, entry.name, excluded)) break :blk true;
            }
            break :blk false;
        };
        if (excluded) continue;

        const excluded_contains = blk: {
            for (excluding_contains) |contains| {
                if (std.mem.containsAtLeast(u8, entry.name, 1, contains)) break :blk true;
            }
            break :blk false;
        };
        if (excluded_contains) continue;

        try dst.append(abs_path);
    }
}
