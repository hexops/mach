const std = @import("std");
const Builder = std.build.Builder;
const glfw = @import("libs/mach-glfw/build.zig");
const system_sdk = @import("libs/mach-glfw/system_sdk.zig");

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    const options = Options{
        .from_source = b.option(bool, "from-source", "Build Dawn from source") orelse false,
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
    dawn_example.addIncludeDir("libs/dawn/out/Debug/gen/src/include");
    dawn_example.addIncludeDir("libs/dawn/out/Debug/gen/src");
    dawn_example.addIncludeDir("libs/dawn/src/include");
    dawn_example.addIncludeDir("src/dawn");
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

    /// Defaults to true on Windows, Linux
    // TODO(build-system): not respected at all currently
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
    separate_libs: bool = true,

    /// Whether to build Dawn from source or not.
    from_source: bool = false,

    /// The binary release version to use from https://github.com/hexops/mach-gpu-dawn/releases
    binary_version: []const u8 = "release-027ea24",

    /// Detects the default options to use for the given target.
    pub fn detectDefaults(self: Options, target: std.Target) Options {
        const tag = target.os.tag;
        const linux_desktop_like = isLinuxDesktopLike(target);

        var options = self;
        if (options.linux_window_manager == null and linux_desktop_like) options.linux_window_manager = .X11;
        if (options.d3d12 == null) options.d3d12 = tag == .windows;
        if (options.metal == null) options.metal = tag.isDarwin();
        if (options.vulkan == null) options.vulkan = tag == .fuchsia or linux_desktop_like;

        // TODO(build-system): respect these options / defaults
        if (options.desktop_gl == null) options.desktop_gl = linux_desktop_like; // TODO(build-system): add windows
        options.opengl_es = false;
        // if (options.opengl_es == null) options.opengl_es = tag == .windows or tag == .emscripten or target.isAndroid() or linux_desktop_like;
        return options;
    }

    pub fn appendFlags(self: Options, flags: *std.ArrayList([]const u8), zero_debug_symbols: bool) !void {
        if (self.minimal_debug_symbols) {
            if (zero_debug_symbols) try flags.append("-g0") else try flags.append("-g1");
        }
    }
};

pub fn link(b: *Builder, step: *std.build.LibExeObjStep, options: Options) void {
    const target = (std.zig.system.NativeTargetInfo.detect(b.allocator, step.target) catch unreachable).target;
    const opt = options.detectDefaults(target);

    ensureSubmodules(b.allocator) catch |err| @panic(@errorName(err));

    if (options.from_source) linkFromSource(b, step, opt) else linkFromBinary(b, step, opt);
}

fn linkFromSource(b: *Builder, step: *std.build.LibExeObjStep, options: Options) void {
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
}

fn ensureSubmodules(allocator: std.mem.Allocator) !void {
    const child = try std.ChildProcess.init(&.{ "git", "submodule", "update", "--init", "--recursive" }, allocator);
    child.cwd = thisDir();
    child.stderr = std.io.getStdErr();
    child.stdout = std.io.getStdOut();
    _ = try child.spawnAndWait();
}

pub fn linkFromBinary(b: *Builder, step: *std.build.LibExeObjStep, options: Options) void {
    const target = (std.zig.system.NativeTargetInfo.detect(b.allocator, step.target) catch unreachable).target;

    // If it's not the default ABI, we have no binaries available.
    const default_abi = std.Target.Abi.default(target.cpu.arch, target.os);
    if (target.abi != default_abi) return linkFromSource(b, step, options);

    const triple = blk: {
        if (target.cpu.arch.isX86()) switch (target.os.tag) {
            .windows => return linkFromSource(b, step, options), // break :blk "windows-x86_64",
            .linux => return linkFromSource(b, step, options), // break :blk "linux-x86_64",
            .macos => break :blk "macos-x86_64",
            else => return linkFromSource(b, step, options),
        };
        if (target.cpu.arch.isAARCH64()) switch (target.os.tag) {
            .macos => return linkFromSource(b, step, options), // break :blk "macos-aarch64",
            else => return linkFromSource(b, step, options),
        };
        return linkFromSource(b, step, options);
    };
    ensureBinaryDownloaded(b.allocator, triple, options.binary_version);

    const current_git_commit = getCurrentGitCommit(b.allocator) catch unreachable;
    const base_cache_dir_rel = std.fs.path.join(b.allocator, &.{ "zig-cache", "mach", "gpu-dawn" }) catch unreachable;
    std.fs.cwd().makePath(base_cache_dir_rel) catch unreachable;
    const base_cache_dir = std.fs.cwd().realpathAlloc(b.allocator, base_cache_dir_rel) catch unreachable;
    const commit_cache_dir = std.fs.path.join(b.allocator, &.{ base_cache_dir, current_git_commit }) catch unreachable;
    const target_cache_dir = std.fs.path.join(b.allocator, &.{ commit_cache_dir, triple }) catch unreachable;

    step.addLibraryPath(target_cache_dir);
    step.linkSystemLibrary("dawn");
    step.linkLibCpp();

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
}

pub fn ensureBinaryDownloaded(allocator: std.mem.Allocator, triple: []const u8, version: []const u8) void {
    // If zig-cache/mach/gpu-dawn/<git revision> does not exist:
    //   If on a commit in the main branch => rm -r zig-cache/mach/gpu-dawn/
    //   else => noop
    // If zig-cache/mach/gpu-dawn/<git revision>/<target> exists:
    //   noop
    // else:
    //   Download archive to zig-cache/mach/gpu-dawn/download/macos-aarch64
    //   Extract to zig-cache/mach/gpu-dawn/<git revision>/macos-aarch64/libgpu.a
    //   Remove zig-cache/mach/gpu-dawn/download

    const current_git_commit = getCurrentGitCommit(allocator) catch unreachable;
    const base_cache_dir_rel = std.fs.path.join(allocator, &.{ "zig-cache", "mach", "gpu-dawn" }) catch unreachable;
    std.fs.cwd().makePath(base_cache_dir_rel) catch unreachable;
    const base_cache_dir = std.fs.cwd().realpathAlloc(allocator, base_cache_dir_rel) catch unreachable;
    const commit_cache_dir = std.fs.path.join(allocator, &.{ base_cache_dir, current_git_commit }) catch unreachable;

    if (!dirExists(commit_cache_dir)) {
        // Commit cache dir does not exist. If the commit we want is in the main branch, we're
        // probably moving to a newer commit and so we should cleanup older cached binaries.
        if (gitBranchContainsCommit(allocator, "main", current_git_commit) catch false) {
            std.fs.deleteTreeAbsolute(base_cache_dir) catch {};
        }
    }

    const target_cache_dir = std.fs.path.join(allocator, &.{ commit_cache_dir, triple }) catch unreachable;
    if (dirExists(target_cache_dir)) {
        return; // nothing to do, already have the binary
    }

    const download_dir = std.fs.path.join(allocator, &.{ target_cache_dir, "download" }) catch unreachable;
    std.fs.cwd().makePath(download_dir) catch unreachable;

    // Compose the download URL, e.g.:
    // https://github.com/hexops/mach-gpu-dawn/releases/download/release-2e5a4eb/libdawn_x86_64-macos.a.gz
    const download_url = std.mem.concat(allocator, u8, &.{
        "https://github.com/hexops/mach-gpu-dawn/releases/download/",
        version,
        "/libdawn_",
        triple,
        ".a.gz",
    }) catch unreachable;

    const gz_target_file = std.fs.path.join(allocator, &.{ download_dir, "compressed.gz" }) catch unreachable;
    downloadFile(allocator, gz_target_file, download_url) catch unreachable;

    const target_file = std.fs.path.join(allocator, &.{ target_cache_dir, "libdawn.a" }) catch unreachable;
    gzipDecompress(allocator, gz_target_file, target_file) catch unreachable;

    std.fs.deleteTreeAbsolute(download_dir) catch unreachable;
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

    var flags = std.ArrayList([]const u8).init(b.allocator);
    options.appendFlags(&flags, false) catch unreachable;
    appendDawnEnableBackendTypeFlags(&flags, options) catch unreachable;
    flags.appendSlice(&.{
        include("libs/mach-glfw/upstream/glfw/include"),
        include("libs/dawn/out/Debug/gen/src/include"),
        include("libs/dawn/out/Debug/gen/src"),
        include("libs/dawn/src/include"),
        include("libs/dawn/src"),
    }) catch unreachable;

    lib.addCSourceFile("src/dawn/dawn_native_mach.cpp", flags.items);
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
    options.appendFlags(&flags, false) catch unreachable;
    flags.append(include("libs/dawn/src")) catch unreachable;

    var sources = std.ArrayList([]const u8).init(b.allocator);
    for ([_][]const u8{
        "src/common/Assert.cpp",
        "src/common/DynamicLib.cpp",
        "src/common/GPUInfo.cpp",
        "src/common/Log.cpp",
        "src/common/Math.cpp",
        "src/common/RefCounted.cpp",
        "src/common/Result.cpp",
        "src/common/SlabAllocator.cpp",
        "src/common/SystemUtils.cpp",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        sources.append(abs_path) catch unreachable;
    }

    const target = (std.zig.system.NativeTargetInfo.detect(b.allocator, step.target) catch unreachable).target;
    if (target.os.tag == .macos) {
        // TODO(build-system): pass system SDK options through
        system_sdk.include(b, lib, .{});
        lib.linkFramework("Foundation");
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn/src/common/SystemUtils_mac.mm" }) catch unreachable;
        sources.append(abs_path) catch unreachable;
    }
    lib.addCSourceFiles(sources.items, flags.items);
    return lib;
}

// Build dawn platform sources; derived from src/dawn_platform/BUILD.gn
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

    var flags = std.ArrayList([]const u8).init(b.allocator);
    options.appendFlags(&flags, false) catch unreachable;
    flags.appendSlice(&.{
        include("libs/dawn/src"),
        include("libs/dawn/src/include"),

        include("libs/dawn/out/Debug/gen/src/include"),
    }) catch unreachable;

    var sources = std.ArrayList([]const u8).init(b.allocator);
    for ([_][]const u8{
        "src/dawn_platform/DawnPlatform.cpp",
        "src/dawn_platform/WorkerThread.cpp",
        "src/dawn_platform/tracing/EventTracer.cpp",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        sources.append(abs_path) catch unreachable;
    }
    lib.addCSourceFiles(sources.items, flags.items);
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

// Builds dawn native sources; derived from src/dawn_native/BUILD.gn
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
    options.appendFlags(&flags, false) catch unreachable;
    appendDawnEnableBackendTypeFlags(&flags, options) catch unreachable;
    if (options.desktop_gl.?) {
        // OpenGL requires spriv-cross until Dawn moves OpenGL shader generation to Tint.
        flags.append(include("libs/dawn/third_party/vulkan-deps/spirv-cross/src")) catch unreachable;

        const lib_spirv_cross = buildLibSPIRVCross(b, step, options);
        step.linkLibrary(lib_spirv_cross);
    }
    flags.appendSlice(&.{
        include("libs/dawn"),
        include("libs/dawn/src"),
        include("libs/dawn/src/include"),
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
        include("libs/dawn/third_party/tint"),
        include("libs/dawn/third_party/tint/include"),

        include("libs/dawn/out/Debug/gen/src/include"),
        include("libs/dawn/out/Debug/gen/src"),
    }) catch unreachable;

    var sources = std.ArrayList([]const u8).init(b.allocator);
    sources.appendSlice(&.{
        thisDir() ++ "/src/dawn/sources/dawn_native.cpp",
        thisDir() ++ "/libs/dawn/out/Debug/gen/src/dawn/dawn_proc.c",
    }) catch unreachable;

    // dawn_native_utils_gen
    sources.append(thisDir() ++ "/src/dawn/sources/dawn_native_utils_gen.cpp") catch unreachable;

    // TODO(build-system): could allow enable_vulkan_validation_layers here. See src/dawn_native/BUILD.gn
    // TODO(build-system): allow use_angle here. See src/dawn_native/BUILD.gn
    // TODO(build-system): could allow use_swiftshader here. See src/dawn_native/BUILD.gn

    if (options.d3d12.?) {
        // TODO(build-system): windows
        //     libs += [ "dxguid.lib" ]
        // TODO(build-system): reduce build units
        for ([_][]const u8{
            "src/dawn_native/d3d12/AdapterD3D12.cpp",
            "src/dawn_native/d3d12/BackendD3D12.cpp",
            "src/dawn_native/d3d12/BindGroupD3D12.cpp",
            "src/dawn_native/d3d12/BindGroupLayoutD3D12.cpp",
            "src/dawn_native/d3d12/BufferD3D12.cpp",
            "src/dawn_native/d3d12/CPUDescriptorHeapAllocationD3D12.cpp",
            "src/dawn_native/d3d12/CommandAllocatorManager.cpp",
            "src/dawn_native/d3d12/CommandBufferD3D12.cpp",
            "src/dawn_native/d3d12/CommandRecordingContext.cpp",
            "src/dawn_native/d3d12/ComputePipelineD3D12.cpp",
            "src/dawn_native/d3d12/D3D11on12Util.cpp",
            "src/dawn_native/d3d12/D3D12Error.cpp",
            "src/dawn_native/d3d12/D3D12Info.cpp",
            "src/dawn_native/d3d12/DeviceD3D12.cpp",
            "src/dawn_native/d3d12/GPUDescriptorHeapAllocationD3D12.cpp",
            "src/dawn_native/d3d12/HeapAllocatorD3D12.cpp",
            "src/dawn_native/d3d12/HeapD3D12.cpp",
            "src/dawn_native/d3d12/NativeSwapChainImplD3D12.cpp",
            "src/dawn_native/d3d12/PageableD3D12.cpp",
            "src/dawn_native/d3d12/PipelineLayoutD3D12.cpp",
            "src/dawn_native/d3d12/PlatformFunctions.cpp",
            "src/dawn_native/d3d12/QuerySetD3D12.cpp",
            "src/dawn_native/d3d12/QueueD3D12.cpp",
            "src/dawn_native/d3d12/RenderPassBuilderD3D12.cpp",
            "src/dawn_native/d3d12/RenderPipelineD3D12.cpp",
            "src/dawn_native/d3d12/ResidencyManagerD3D12.cpp",
            "src/dawn_native/d3d12/ResourceAllocatorManagerD3D12.cpp",
            "src/dawn_native/d3d12/ResourceHeapAllocationD3D12.cpp",
            "src/dawn_native/d3d12/SamplerD3D12.cpp",
            "src/dawn_native/d3d12/SamplerHeapCacheD3D12.cpp",
            "src/dawn_native/d3d12/ShaderModuleD3D12.cpp",
            "src/dawn_native/d3d12/ShaderVisibleDescriptorAllocatorD3D12.cpp",
            "src/dawn_native/d3d12/StagingBufferD3D12.cpp",
            "src/dawn_native/d3d12/StagingDescriptorAllocatorD3D12.cpp",
            "src/dawn_native/d3d12/SwapChainD3D12.cpp",
            "src/dawn_native/d3d12/TextureCopySplitter.cpp",
            "src/dawn_native/d3d12/TextureD3D12.cpp",
            "src/dawn_native/d3d12/UtilsD3D12.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            lib.addCSourceFile(abs_path, flags.items);
            sources.append(abs_path) catch unreachable;
        }
    }
    if (options.metal.?) {
        lib.linkFramework("Metal");
        lib.linkFramework("CoreGraphics");
        lib.linkFramework("Foundation");
        lib.linkFramework("IOKit");
        lib.linkFramework("IOSurface");
        lib.linkFramework("QuartzCore");

        sources.appendSlice(&.{
            thisDir() ++ "/src/dawn/sources/dawn_native_metal.mm",
            thisDir() ++ "/libs/dawn/src/dawn_native/metal/BackendMTL.mm",
        }) catch unreachable;
    }

    if (options.linux_window_manager != null and options.linux_window_manager.? == .X11) {
        lib.linkSystemLibrary("X11");
        for ([_][]const u8{
            "src/dawn_native/XlibXcbFunctions.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            sources.append(abs_path) catch unreachable;
        }
    }

    for ([_][]const u8{
        "src/dawn_native/null/DeviceNull.cpp",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        sources.append(abs_path) catch unreachable;
    }

    if (options.desktop_gl.? or options.vulkan.?) {
        for ([_][]const u8{
            "src/dawn_native/SpirvValidation.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            sources.append(abs_path) catch unreachable;
        }
    }

    if (options.desktop_gl.?) {
        for ([_][]const u8{
            "out/Debug/gen/src/dawn_native/opengl/OpenGLFunctionsBase_autogen.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            sources.append(abs_path) catch unreachable;
        }

        // TODO(build-system): reduce build units
        for ([_][]const u8{
            "src/dawn_native/opengl/BackendGL.cpp",
            "src/dawn_native/opengl/BindGroupGL.cpp",
            "src/dawn_native/opengl/BindGroupLayoutGL.cpp",
            "src/dawn_native/opengl/BufferGL.cpp",
            "src/dawn_native/opengl/CommandBufferGL.cpp",
            "src/dawn_native/opengl/ComputePipelineGL.cpp",
            "src/dawn_native/opengl/DeviceGL.cpp",
            "src/dawn_native/opengl/GLFormat.cpp",
            "src/dawn_native/opengl/NativeSwapChainImplGL.cpp",
            "src/dawn_native/opengl/OpenGLFunctions.cpp",
            "src/dawn_native/opengl/OpenGLVersion.cpp",
            "src/dawn_native/opengl/PersistentPipelineStateGL.cpp",
            "src/dawn_native/opengl/PipelineGL.cpp",
            "src/dawn_native/opengl/PipelineLayoutGL.cpp",
            "src/dawn_native/opengl/QuerySetGL.cpp",
            "src/dawn_native/opengl/QueueGL.cpp",
            "src/dawn_native/opengl/RenderPipelineGL.cpp",
            "src/dawn_native/opengl/SamplerGL.cpp",
            "src/dawn_native/opengl/ShaderModuleGL.cpp",
            "src/dawn_native/opengl/SpirvUtils.cpp",
            "src/dawn_native/opengl/SwapChainGL.cpp",
            "src/dawn_native/opengl/TextureGL.cpp",
            "src/dawn_native/opengl/UtilsGL.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            sources.append(abs_path) catch unreachable;
        }
    }

    const target = (std.zig.system.NativeTargetInfo.detect(b.allocator, step.target) catch unreachable).target;
    if (options.vulkan.?) {
        // TODO(build-system): reduce build units
        for ([_][]const u8{
            "src/dawn_native/vulkan/AdapterVk.cpp",
            "src/dawn_native/vulkan/BackendVk.cpp",
            "src/dawn_native/vulkan/BindGroupLayoutVk.cpp",
            "src/dawn_native/vulkan/BindGroupVk.cpp",
            "src/dawn_native/vulkan/BufferVk.cpp",
            "src/dawn_native/vulkan/CommandBufferVk.cpp",
            "src/dawn_native/vulkan/ComputePipelineVk.cpp",
            "src/dawn_native/vulkan/DescriptorSetAllocator.cpp",
            "src/dawn_native/vulkan/DeviceVk.cpp",
            "src/dawn_native/vulkan/FencedDeleter.cpp",
            "src/dawn_native/vulkan/NativeSwapChainImplVk.cpp",
            "src/dawn_native/vulkan/PipelineLayoutVk.cpp",
            "src/dawn_native/vulkan/QuerySetVk.cpp",
            "src/dawn_native/vulkan/QueueVk.cpp",
            "src/dawn_native/vulkan/RenderPassCache.cpp",
            "src/dawn_native/vulkan/RenderPipelineVk.cpp",
            "src/dawn_native/vulkan/ResourceHeapVk.cpp",
            "src/dawn_native/vulkan/ResourceMemoryAllocatorVk.cpp",
            "src/dawn_native/vulkan/SamplerVk.cpp",
            "src/dawn_native/vulkan/ShaderModuleVk.cpp",
            "src/dawn_native/vulkan/StagingBufferVk.cpp",
            "src/dawn_native/vulkan/SwapChainVk.cpp",
            "src/dawn_native/vulkan/TextureVk.cpp",
            "src/dawn_native/vulkan/UtilsVulkan.cpp",
            "src/dawn_native/vulkan/VulkanError.cpp",
            "src/dawn_native/vulkan/VulkanExtensions.cpp",
            "src/dawn_native/vulkan/VulkanFunctions.cpp",
            "src/dawn_native/vulkan/VulkanInfo.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            sources.append(abs_path) catch unreachable;
        }

        if (isLinuxDesktopLike(target)) {
            for ([_][]const u8{
                "src/dawn_native/vulkan/external_memory/MemoryServiceOpaqueFD.cpp",
                "src/dawn_native/vulkan/external_semaphore/SemaphoreServiceFD.cpp",
            }) |path| {
                var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
                lib.addCSourceFile(abs_path, flags.items);
                sources.append(abs_path) catch unreachable;
            }
        } else if (target.os.tag == .fuchsia) {
            for ([_][]const u8{
                "src/dawn_native/vulkan/external_memory/MemoryServiceZirconHandle.cpp",
                "src/dawn_native/vulkan/external_semaphore/SemaphoreServiceZirconHandle.cpp",
            }) |path| {
                var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
                sources.append(abs_path) catch unreachable;
            }
        } else {
            for ([_][]const u8{
                "src/dawn_native/vulkan/external_memory/MemoryServiceNull.cpp",
                "src/dawn_native/vulkan/external_semaphore/SemaphoreServiceNull.cpp",
            }) |path| {
                var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
                sources.append(abs_path) catch unreachable;
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
        "src/dawn_native/DawnNative.cpp",
        "src/dawn_native/null/NullBackend.cpp",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        sources.append(abs_path) catch unreachable;
    }

    if (options.d3d12.?) {
        for ([_][]const u8{
            "src/dawn_native/d3d12/D3D12Backend.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            sources.append(abs_path) catch unreachable;
        }
    }
    if (options.desktop_gl.?) {
        for ([_][]const u8{
            "src/dawn_native/opengl/OpenGLBackend.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            sources.append(abs_path) catch unreachable;
        }
    }
    if (options.vulkan.?) {
        for ([_][]const u8{
            "src/dawn_native/vulkan/VulkanBackend.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            sources.append(abs_path) catch unreachable;
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
    lib.addCSourceFiles(sources.items, flags.items);
    return lib;
}

// Builds third party tint sources; derived from third_party/tint/src/BUILD.gn
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
    options.appendFlags(&flags, true) catch unreachable;
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
    var sources = std.ArrayList([]const u8).init(b.allocator);
    sources.appendSlice(&.{
        thisDir() ++ "/src/dawn/sources/tint_core_all_src.cc",
        thisDir() ++ "/src/dawn/sources/tint_core_all_src_2.cc",
        thisDir() ++ "/libs/dawn/third_party/tint/src/ast/node.cc",
        thisDir() ++ "/libs/dawn/third_party/tint/src/ast/texture.cc",
    }) catch unreachable;

    const target = (std.zig.system.NativeTargetInfo.detect(b.allocator, step.target) catch unreachable).target;
    switch (target.os.tag) {
        .windows => sources.append(thisDir() ++ "/libs/dawn/third_party/tint/src/diagnostic/printer_windows.cc") catch unreachable,
        .linux => sources.append(thisDir() ++ "/libs/dawn/third_party/tint/src/diagnostic/printer_linux.cc") catch unreachable,
        else => sources.append(thisDir() ++ "/libs/dawn/third_party/tint/src/diagnostic/printer_other.cc") catch unreachable,
    }

    // libtint_sem_src
    sources.appendSlice(&.{
        thisDir() ++ "/src/dawn/sources/tint_sem_src.cc",
        thisDir() ++ "/src/dawn/sources/tint_sem_src_2.cc",
        thisDir() ++ "/libs/dawn/third_party/tint/src/sem/node.cc",
        thisDir() ++ "/libs/dawn/third_party/tint/src/sem/texture_type.cc",
    }) catch unreachable;

    // libtint_spv_reader_src
    sources.append(thisDir() ++ "/src/dawn/sources/tint_spv_reader_src.cc") catch unreachable;

    // libtint_spv_writer_src
    sources.append(thisDir() ++ "/src/dawn/sources/tint_spv_writer_src.cc") catch unreachable;

    // TODO(build-system): make optional
    // libtint_wgsl_reader_src
    for ([_][]const u8{
        "third_party/tint/src/reader/wgsl/lexer.cc",
        "third_party/tint/src/reader/wgsl/parser.cc",
        "third_party/tint/src/reader/wgsl/parser_impl.cc",
        "third_party/tint/src/reader/wgsl/token.cc",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        sources.append(abs_path) catch unreachable;
    }

    // TODO(build-system): make optional
    // libtint_wgsl_writer_src
    for ([_][]const u8{
        "third_party/tint/src/writer/wgsl/generator.cc",
        "third_party/tint/src/writer/wgsl/generator_impl.cc",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        sources.append(abs_path) catch unreachable;
    }

    // TODO(build-system): make optional
    // libtint_msl_writer_src
    for ([_][]const u8{
        "third_party/tint/src/writer/msl/generator.cc",
        "third_party/tint/src/writer/msl/generator_impl.cc",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        sources.append(abs_path) catch unreachable;
    }

    // TODO(build-system): make optional
    // libtint_hlsl_writer_src
    for ([_][]const u8{
        "third_party/tint/src/writer/hlsl/generator.cc",
        "third_party/tint/src/writer/hlsl/generator_impl.cc",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        sources.append(abs_path) catch unreachable;
    }

    // TODO(build-system): make optional
    // libtint_glsl_writer_src
    for ([_][]const u8{
        "third_party/tint/src/transform/glsl.cc",
        "third_party/tint/src/writer/glsl/generator.cc",
        "third_party/tint/src/writer/glsl/generator_impl.cc",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        sources.append(abs_path) catch unreachable;
    }
    lib.addCSourceFiles(sources.items, flags.items);
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
    options.appendFlags(&flags, true) catch unreachable;
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
    var sources = std.ArrayList([]const u8).init(b.allocator);
    sources.appendSlice(&.{
        thisDir() ++ "/src/dawn/sources/spirv_tools.cpp",
        thisDir() ++ "/libs/dawn/third_party/vulkan-deps/spirv-tools/src/source/operand.cpp",
        thisDir() ++ "/libs/dawn/third_party/vulkan-deps/spirv-tools/src/source/spirv_reducer_options.cpp",
    }) catch unreachable;

    // spvtools_val
    sources.append(thisDir() ++ "/src/dawn/sources/spirv_tools_val.cpp") catch unreachable;

    // spvtools_opt
    sources.appendSlice(&.{
        thisDir() ++ "/src/dawn/sources/spirv_tools_opt.cpp",
        thisDir() ++ "/src/dawn/sources/spirv_tools_opt_2.cpp",
        thisDir() ++ "/libs/dawn/third_party/vulkan-deps/spirv-tools/src/source/opt/dataflow.cpp",
        thisDir() ++ "/libs/dawn/third_party/vulkan-deps/spirv-tools/src/source/opt/local_single_store_elim_pass.cpp",
        thisDir() ++ "/libs/dawn/third_party/vulkan-deps/spirv-tools/src/source/opt/loop_unswitch_pass.cpp",
        thisDir() ++ "/libs/dawn/third_party/vulkan-deps/spirv-tools/src/source/opt/mem_pass.cpp",
        thisDir() ++ "/libs/dawn/third_party/vulkan-deps/spirv-tools/src/source/opt/ssa_rewrite_pass.cpp",
        thisDir() ++ "/libs/dawn/third_party/vulkan-deps/spirv-tools/src/source/opt/vector_dce.cpp",
    }) catch unreachable;

    // spvtools_link
    for ([_][]const u8{
        "third_party/vulkan-deps/spirv-tools/src/source/link/linker.cpp",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        sources.append(abs_path) catch unreachable;
    }
    lib.addCSourceFiles(sources.items, flags.items);
    return lib;
}

// Builds third_party/vulkan-deps/spirv-tools sources; derived from third_party/vulkan-deps/spirv-tools/src/BUILD.gn
fn buildLibSPIRVCross(b: *Builder, step: *std.build.LibExeObjStep, options: Options) *std.build.LibExeObjStep {
    const lib = if (!options.separate_libs) step else blk: {
        var main_abs = std.fs.path.join(b.allocator, &.{ thisDir(), "src/dawn/dummy.zig" }) catch unreachable;
        const separate_lib = b.addStaticLibrary("spirv-cross", main_abs);
        separate_lib.install();
        separate_lib.setBuildMode(step.build_mode);
        separate_lib.setTarget(step.target);
        separate_lib.linkLibCpp();
        break :blk separate_lib;
    };

    var flags = std.ArrayList([]const u8).init(b.allocator);
    options.appendFlags(&flags, false) catch unreachable;
    flags.appendSlice(&.{
        "-DSPIRV_CROSS_EXCEPTIONS_TO_ASSERTIONS",
        include("libs/dawn/third_party/vulkan-deps/spirv-cross/src"),
        include("libs/dawn"),
        "-Wno-extra-semi",
        "-Wno-ignored-qualifiers",
        "-Wno-implicit-fallthrough",
        "-Wno-inconsistent-missing-override",
        "-Wno-missing-field-initializers",
        "-Wno-newline-eof",
        "-Wno-sign-compare",
        "-Wno-unused-variable",
    }) catch unreachable;

    const target = (std.zig.system.NativeTargetInfo.detect(b.allocator, step.target) catch unreachable).target;
    if (target.os.tag != .windows) flags.append("-fno-exceptions") catch unreachable;

    // spvtools_link
    lib.addCSourceFile(thisDir() ++ "/src/dawn/sources/spirv_cross.cpp", flags.items);
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

    var flags = std.ArrayList([]const u8).init(b.allocator);
    options.appendFlags(&flags, false) catch unreachable;
    flags.appendSlice(&.{
        include("libs/dawn"),
        include("libs/dawn/third_party/abseil-cpp"),
    }) catch unreachable;

    // absl
    lib.addCSourceFiles(&.{
        thisDir() ++ "/src/dawn/sources/abseil.cc",
        thisDir() ++ "/libs/dawn/third_party/abseil-cpp/absl/strings/numbers.cc",
        thisDir() ++ "/libs/dawn/third_party/abseil-cpp/absl/time/internal/cctz/src/time_zone_posix.cc",
        thisDir() ++ "/libs/dawn/third_party/abseil-cpp/absl/time/format.cc",
        thisDir() ++ "/libs/dawn/third_party/abseil-cpp/absl/random/internal/randen_hwaes.cc",
    }, flags.items);
    return lib;
}

// Buids dawn wire sources; derived from src/dawn_wire/BUILD.gn
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
    options.appendFlags(&flags, false) catch unreachable;
    flags.appendSlice(&.{
        include("libs/dawn"),
        include("libs/dawn/src"),
        include("libs/dawn/src/include"),
        include("libs/dawn/out/Debug/gen/src/include"),
        include("libs/dawn/out/Debug/gen/src"),
    }) catch unreachable;

    lib.addCSourceFile(thisDir() ++ "/src/dawn/sources/dawn_wire_gen.cpp", flags.items);
    return lib;
}

// Builds dawn utils sources; derived from src/utils/BUILD.gn
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
    options.appendFlags(&flags, false) catch unreachable;
    appendDawnEnableBackendTypeFlags(&flags, options) catch unreachable;
    flags.appendSlice(&.{
        include("libs/mach-glfw/upstream/glfw/include"),
        include("libs/dawn/src"),
        include("libs/dawn/src/include"),
        include("libs/dawn/out/Debug/gen/src/include"),
    }) catch unreachable;

    var sources = std.ArrayList([]const u8).init(b.allocator);
    for ([_][]const u8{
        "src/utils/BackendBinding.cpp",
        "src/utils/NullBinding.cpp",
    }) |path| {
        var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
        sources.append(abs_path) catch unreachable;
    }

    if (options.d3d12.?) {
        for ([_][]const u8{
            "src/utils/D3D12Binding.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            sources.append(abs_path) catch unreachable;
        }
    }
    if (options.metal.?) {
        for ([_][]const u8{
            "src/utils/MetalBinding.mm",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            sources.append(abs_path) catch unreachable;
        }
    }

    if (options.desktop_gl.?) {
        for ([_][]const u8{
            "src/utils/OpenGLBinding.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            sources.append(abs_path) catch unreachable;
        }
    }

    if (options.vulkan.?) {
        for ([_][]const u8{
            "src/utils/VulkanBinding.cpp",
        }) |path| {
            var abs_path = std.fs.path.join(b.allocator, &.{ thisDir(), "libs/dawn", path }) catch unreachable;
            sources.append(abs_path) catch unreachable;
        }
    }
    lib.addCSourceFiles(sources.items, flags.items);
    return lib;
}

fn include(comptime rel: []const u8) []const u8 {
    return "-I" ++ thisDir() ++ "/" ++ rel;
}

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}
