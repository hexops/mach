const std = @import("std");
const Builder = std.build.Builder;

pub fn Sdk(comptime deps: anytype) type {
    return struct {
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

            /// Whether or not to use Dawn in debug mode.
            debug: bool = false,

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

            /// Produce static libraries at zig-out/lib
            install_libs: bool = false,

            /// The binary release version to use from https://github.com/hexops/mach-gpu-dawn/releases
            binary_version: []const u8 = "release-9844560",

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

        pub fn link(b: *Builder, step: *std.build.LibExeObjStep, options: Options) !void {
            const opt = options.detectDefaults(step.target_info.target);

            try if (options.from_source)
                linkFromSource(b, step, opt)
            else
                linkFromBinary(b, step, opt);
        }

        fn linkFromSource(b: *Builder, step: *std.build.LibExeObjStep, options: Options) !void {
            // branch: generated-2022-08-06
            try ensureGitRepoCloned(b.allocator, "https://github.com/hexops/dawn", "0b704c4acae154ec8d4be7615d18a489f270f6c0", sdkPath(b, "/libs/dawn"));

            // branch: mach
            try ensureGitRepoCloned(b.allocator, "https://github.com/hexops/DirectXShaderCompiler", "cff9a6f0b7f961748b822e1d313a7205dfdecf9d", sdkPath(b, "/libs/DirectXShaderCompiler"));

            step.addIncludePath(sdkPath(b, "/libs/dawn/out/Debug/gen/include"));
            step.addIncludePath(sdkPath(b, "/libs/dawn/include"));
            step.addIncludePath(sdkPath(b, "/src/dawn"));

            if (options.separate_libs) {
                const lib_mach_dawn_native = try buildLibMachDawnNative(b, step, options);
                step.linkLibrary(lib_mach_dawn_native);

                const lib_dawn_common = try buildLibDawnCommon(b, step, options);
                step.linkLibrary(lib_dawn_common);

                const lib_dawn_platform = try buildLibDawnPlatform(b, step, options);
                step.linkLibrary(lib_dawn_platform);

                // dawn-native
                const lib_abseil_cpp = try buildLibAbseilCpp(b, step, options);
                step.linkLibrary(lib_abseil_cpp);
                const lib_dawn_native = try buildLibDawnNative(b, step, options);
                step.linkLibrary(lib_dawn_native);

                if (options.d3d12.?) {
                    const lib_dxcompiler = try buildLibDxcompiler(b, step, options);
                    step.linkLibrary(lib_dxcompiler);
                }

                const lib_dawn_wire = try buildLibDawnWire(b, step, options);
                step.linkLibrary(lib_dawn_wire);

                const lib_dawn_utils = try buildLibDawnUtils(b, step, options);
                step.linkLibrary(lib_dawn_utils);

                const lib_spirv_tools = try buildLibSPIRVTools(b, step, options);
                step.linkLibrary(lib_spirv_tools);

                const lib_tint = try buildLibTint(b, step, options);
                step.linkLibrary(lib_tint);
                return;
            }

            const lib_dawn = b.addStaticLibrary("dawn", null);
            lib_dawn.setBuildMode(if (options.debug) .Debug else .ReleaseFast);
            lib_dawn.setTarget(step.target);
            if (!options.debug)
                lib_dawn.strip = true;
            lib_dawn.linkLibCpp();
            if (options.install_libs)
                lib_dawn.install();
            step.linkLibrary(lib_dawn);

            _ = try buildLibMachDawnNative(b, lib_dawn, options);
            _ = try buildLibDawnCommon(b, lib_dawn, options);
            _ = try buildLibDawnPlatform(b, lib_dawn, options);
            _ = try buildLibAbseilCpp(b, lib_dawn, options);
            _ = try buildLibDawnNative(b, lib_dawn, options);
            _ = try buildLibDawnWire(b, lib_dawn, options);
            _ = try buildLibDawnUtils(b, lib_dawn, options);
            _ = try buildLibSPIRVTools(b, lib_dawn, options);
            _ = try buildLibTint(b, lib_dawn, options);
            if (options.d3d12.?) _ = try buildLibDxcompiler(b, lib_dawn, options);
        }

        fn ensureGitRepoCloned(allocator: std.mem.Allocator, clone_url: []const u8, revision: []const u8, dir: []const u8) !void {
            if (isEnvVarTruthy(allocator, "NO_ENSURE_SUBMODULES") or isEnvVarTruthy(allocator, "NO_ENSURE_GIT")) {
                return;
            }

            ensureGit(allocator);

            if (std.fs.openDirAbsolute(dir, .{})) |_| {
                const current_revision = try getCurrentGitRevision(allocator, dir);
                if (!std.mem.eql(u8, current_revision, revision)) {
                    // Reset to the desired revision
                    exec(allocator, &[_][]const u8{ "git", "fetch" }, dir) catch |err| std.debug.print("warning: failed to 'git fetch' in {s}: {s}\n", .{ dir, @errorName(err) });
                    try exec(allocator, &[_][]const u8{ "git", "reset", "--quiet", "--hard", revision }, dir);
                    try exec(allocator, &[_][]const u8{ "git", "submodule", "update", "--init", "--recursive" }, dir);
                }
                return;
            } else |err| return switch (err) {
                error.FileNotFound => {
                    std.log.info("cloning required dependency..\ngit clone {s} {s}..\n", .{ clone_url, dir });

                    try exec(allocator, &[_][]const u8{ "git", "clone", "-c", "core.longpaths=true", clone_url, dir }, sdkPathAllocator(allocator, "/"));
                    try exec(allocator, &[_][]const u8{ "git", "reset", "--quiet", "--hard", revision }, dir);
                    try exec(allocator, &[_][]const u8{ "git", "submodule", "update", "--init", "--recursive" }, dir);
                    return;
                },
                else => err,
            };
        }

        fn exec(allocator: std.mem.Allocator, argv: []const []const u8, cwd: []const u8) !void {
            var child = std.ChildProcess.init(argv, allocator);
            child.cwd = cwd;
            _ = try child.spawnAndWait();
        }

        fn getCurrentGitRevision(allocator: std.mem.Allocator, cwd: []const u8) ![]const u8 {
            const result = try std.ChildProcess.exec(.{ .allocator = allocator, .argv = &.{ "git", "rev-parse", "HEAD" }, .cwd = cwd });
            allocator.free(result.stderr);
            if (result.stdout.len > 0) return result.stdout[0 .. result.stdout.len - 1]; // trim newline
            return result.stdout;
        }

        fn ensureGit(allocator: std.mem.Allocator) void {
            const argv = &[_][]const u8{ "git", "--version" };
            const result = std.ChildProcess.exec(.{
                .allocator = allocator,
                .argv = argv,
                .cwd = ".",
            }) catch { // e.g. FileNotFound
                std.log.err("mach: error: 'git --version' failed. Is git not installed?", .{});
                std.process.exit(1);
            };
            defer {
                allocator.free(result.stderr);
                allocator.free(result.stdout);
            }
            if (result.term.Exited != 0) {
                std.log.err("mach: error: 'git --version' failed. Is git not installed?", .{});
                std.process.exit(1);
            }
        }

        fn isEnvVarTruthy(allocator: std.mem.Allocator, name: []const u8) bool {
            if (std.process.getEnvVarOwned(allocator, name)) |truthy| {
                defer allocator.free(truthy);
                if (std.mem.eql(u8, truthy, "true")) return true;
                return false;
            } else |_| {
                return false;
            }
        }

        fn getGitHubBaseURLOwned(allocator: std.mem.Allocator) ![]const u8 {
            if (std.process.getEnvVarOwned(allocator, "MACH_GITHUB_BASE_URL")) |base_url| {
                std.log.info("mach: respecting MACH_GITHUB_BASE_URL: {s}\n", .{base_url});
                return base_url;
            } else |_| {
                return allocator.dupe(u8, "https://github.com");
            }
        }

        pub fn linkFromBinary(b: *Builder, step: *std.build.LibExeObjStep, options: Options) !void {
            const target = step.target_info.target;
            const binaries_available = switch (target.os.tag) {
                .windows => target.abi.isGnu(),
                .linux => (target.cpu.arch.isX86() or target.cpu.arch.isAARCH64()) and (target.abi.isGnu() or target.abi.isMusl()),
                .macos => blk: {
                    if (!target.cpu.arch.isX86() and !target.cpu.arch.isAARCH64()) break :blk false;

                    // If min. target macOS version is lesser than the min version we have available, then
                    // our binary is incompatible with the target.
                    const min_available = std.builtin.Version{ .major = 12, .minor = 0 };
                    if (target.os.version_range.semver.min.order(min_available) == .lt) break :blk false;
                    break :blk true;
                },
                else => false,
            };
            if (!binaries_available) {
                const zig_triple = try target.zigTriple(b.allocator);
                defer b.allocator.free(zig_triple);
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
            binary_target.os_version_min = .{ .none = undefined };
            binary_target.os_version_max = .{ .none = undefined };
            binary_target.glibc_version = null;
            const zig_triple = try binary_target.zigTriple(b.allocator);
            defer b.allocator.free(zig_triple);
            try ensureBinaryDownloaded(b.allocator, zig_triple, options.debug, target.os.tag == .windows, options.binary_version);

            const base_cache_dir_rel = try std.fs.path.join(b.allocator, &.{ "zig-cache", "mach", "gpu-dawn" });
            try std.fs.cwd().makePath(base_cache_dir_rel);
            const base_cache_dir = try std.fs.cwd().realpathAlloc(b.allocator, base_cache_dir_rel);
            const commit_cache_dir = try std.fs.path.join(b.allocator, &.{ base_cache_dir, options.binary_version });
            const release_tag = if (options.debug) "debug" else "release-fast";
            const target_cache_dir = try std.fs.path.join(b.allocator, &.{ commit_cache_dir, zig_triple, release_tag });
            const include_dir = try std.fs.path.join(b.allocator, &.{ commit_cache_dir, "include" });
            defer {
                b.allocator.free(base_cache_dir);
                b.allocator.free(commit_cache_dir);
                b.allocator.free(target_cache_dir);
                b.allocator.free(include_dir);
            }

            step.addLibraryPath(target_cache_dir);
            step.linkSystemLibraryName("dawn");
            step.linkLibCpp();

            step.addIncludePath(include_dir);
            step.addIncludePath(sdkPath(b, "/src/dawn"));

            if (options.linux_window_manager != null and options.linux_window_manager.? == .X11) {
                step.linkSystemLibraryName("X11");
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
                step.linkSystemLibraryName("ole32");
                step.linkSystemLibraryName("dxguid");
            }
        }

        pub fn ensureBinaryDownloaded(
            allocator: std.mem.Allocator,
            zig_triple: []const u8,
            is_debug: bool,
            is_windows: bool,
            version: []const u8,
        ) !void {
            // If zig-cache/mach/gpu-dawn/<git revision> does not exist:
            //   If on a commit in the main branch => rm -r zig-cache/mach/gpu-dawn/
            //   else => noop
            // If zig-cache/mach/gpu-dawn/<git revision>/<target> exists:
            //   noop
            // else:
            //   Download archive to zig-cache/mach/gpu-dawn/download/macos-aarch64
            //   Extract to zig-cache/mach/gpu-dawn/<git revision>/macos-aarch64/libgpu.a
            //   Remove zig-cache/mach/gpu-dawn/download

            const base_cache_dir_rel = try std.fs.path.join(allocator, &.{ "zig-cache", "mach", "gpu-dawn" });
            try std.fs.cwd().makePath(base_cache_dir_rel);
            const base_cache_dir = try std.fs.cwd().realpathAlloc(allocator, base_cache_dir_rel);
            const commit_cache_dir = try std.fs.path.join(allocator, &.{ base_cache_dir, version });
            defer {
                allocator.free(base_cache_dir_rel);
                allocator.free(base_cache_dir);
                allocator.free(commit_cache_dir);
            }

            if (!dirExists(commit_cache_dir)) {
                // Commit cache dir does not exist. If the commit we're on is in the main branch, we're
                // probably moving to a newer commit and so we should cleanup older cached binaries.
                const current_git_commit = try getCurrentGitCommit(allocator);
                if (gitBranchContainsCommit(allocator, "main", current_git_commit) catch false) {
                    std.fs.deleteTreeAbsolute(base_cache_dir) catch {};
                }
            }

            const release_tag = if (is_debug) "debug" else "release-fast";
            const target_cache_dir = try std.fs.path.join(allocator, &.{ commit_cache_dir, zig_triple, release_tag });
            defer allocator.free(target_cache_dir);
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
            ensureCanDownloadFiles(allocator);

            const download_dir = try std.fs.path.join(allocator, &.{ target_cache_dir, "download" });
            defer allocator.free(download_dir);
            try std.fs.cwd().makePath(download_dir);

            // Replace "..." with "---" because GitHub releases has very weird restrictions on file names.
            // https://twitter.com/slimsag/status/1498025997987315713
            const github_triple = try std.mem.replaceOwned(u8, allocator, zig_triple, "...", "---");
            defer allocator.free(github_triple);

            // Compose the download URL, e.g.:
            // https://github.com/hexops/mach-gpu-dawn/releases/download/release-6b59025/libdawn_x86_64-macos-none_debug.a.gz
            const github_base_url = try getGitHubBaseURLOwned(allocator);
            defer allocator.free(github_base_url);
            const lib_prefix = if (is_windows) "dawn_" else "libdawn_";
            const lib_ext = if (is_windows) ".lib" else ".a";
            const lib_file_name = if (is_windows) "dawn.lib" else "libdawn.a";
            const download_url = try std.mem.concat(allocator, u8, &.{
                github_base_url,
                "/hexops/mach-gpu-dawn/releases/download/",
                version,
                "/",
                lib_prefix,
                github_triple,
                "_",
                release_tag,
                lib_ext,
                ".gz",
            });
            defer allocator.free(download_url);

            // Download and decompress libdawn
            const gz_target_file = try std.fs.path.join(allocator, &.{ download_dir, "compressed.gz" });
            defer allocator.free(gz_target_file);
            try downloadFile(allocator, gz_target_file, download_url);
            const target_file = try std.fs.path.join(allocator, &.{ target_cache_dir, lib_file_name });
            defer allocator.free(target_file);
            try gzipDecompress(allocator, gz_target_file, target_file);

            // If we don't yet have the headers (these are shared across architectures), download them.
            const include_dir = try std.fs.path.join(allocator, &.{ commit_cache_dir, "include" });
            defer allocator.free(include_dir);
            if (!dirExists(include_dir)) {
                // Compose the headers download URL, e.g.:
                // https://github.com/hexops/mach-gpu-dawn/releases/download/release-6b59025/headers.json.gz
                const headers_download_url = try std.mem.concat(allocator, u8, &.{
                    github_base_url,
                    "/hexops/mach-gpu-dawn/releases/download/",
                    version,
                    "/headers.json.gz",
                });
                defer allocator.free(headers_download_url);

                // Download and decompress headers.json.gz
                const headers_gz_target_file = try std.fs.path.join(allocator, &.{ download_dir, "headers.json.gz" });
                defer allocator.free(headers_gz_target_file);
                try downloadFile(allocator, headers_gz_target_file, headers_download_url);
                const headers_target_file = try std.fs.path.join(allocator, &.{ target_cache_dir, "headers.json" });
                defer allocator.free(headers_target_file);
                try gzipDecompress(allocator, headers_gz_target_file, headers_target_file);

                // Extract headers JSON archive.
                try extractHeaders(allocator, headers_target_file, commit_cache_dir);
            }

            try std.fs.deleteTreeAbsolute(download_dir);
        }

        fn extractHeaders(allocator: std.mem.Allocator, json_file: []const u8, out_dir: []const u8) !void {
            const contents = try std.fs.cwd().readFileAlloc(allocator, json_file, std.math.maxInt(usize));
            defer allocator.free(contents);

            var parser = std.json.Parser.init(allocator, false);
            defer parser.deinit();
            var tree = try parser.parse(contents);
            defer tree.deinit();

            var iter = tree.root.Object.iterator();
            while (iter.next()) |f| {
                const out_path = try std.fs.path.join(allocator, &.{ out_dir, f.key_ptr.* });
                defer allocator.free(out_path);
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

            var buf_stream = std.io.bufferedReader(file.reader());
            var gzip_stream = try std.compress.gzip.gzipStream(allocator, buf_stream.reader());
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
                .cwd = sdkPathAllocator(allocator, "/"),
            });
            defer {
                allocator.free(result.stdout);
                allocator.free(result.stderr);
            }
            return result.term.Exited == 0;
        }

        fn getCurrentGitCommit(allocator: std.mem.Allocator) ![]const u8 {
            const result = try std.ChildProcess.exec(.{
                .allocator = allocator,
                .argv = &.{ "git", "rev-parse", "HEAD" },
                .cwd = sdkPathAllocator(allocator, "/"),
            });
            defer allocator.free(result.stderr);
            if (result.stdout.len > 0) return result.stdout[0 .. result.stdout.len - 1]; // trim newline
            return result.stdout;
        }

        fn gitClone(allocator: std.mem.Allocator, repository: []const u8, dir: []const u8) !bool {
            const result = try std.ChildProcess.exec(.{
                .allocator = allocator,
                .argv = &.{ "git", "clone", repository, dir },
                .cwd = sdkPathAllocator(allocator, "/"),
            });
            defer {
                allocator.free(result.stdout);
                allocator.free(result.stderr);
            }
            return result.term.Exited == 0;
        }

        fn downloadFile(allocator: std.mem.Allocator, target_file: []const u8, url: []const u8) !void {
            std.debug.print("downloading {s}..\n", .{url});

            // Some Windows users experience `SSL certificate problem: unable to get local issuer certificate`
            // so we give them the option to disable SSL if they desire / don't want to debug the issue.
            var child = if (isEnvVarTruthy(allocator, "CURL_INSECURE"))
                std.ChildProcess.init(&.{ "curl", "--insecure", "-L", "-o", target_file, url }, allocator)
            else
                std.ChildProcess.init(&.{ "curl", "-L", "-o", target_file, url }, allocator);
            child.cwd = sdkPathAllocator(allocator, "/");
            child.stderr = std.io.getStdErr();
            child.stdout = std.io.getStdOut();
            _ = try child.spawnAndWait();
        }

        fn ensureCanDownloadFiles(allocator: std.mem.Allocator) void {
            const result = std.ChildProcess.exec(.{
                .allocator = allocator,
                .argv = &.{ "curl", "--version" },
                .cwd = sdkPathAllocator(allocator, "/"),
            }) catch { // e.g. FileNotFound
                std.log.err("mach: error: 'curl --version' failed. Is curl not installed?", .{});
                std.process.exit(1);
            };
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

        fn buildLibMachDawnNative(b: *Builder, step: *std.build.LibExeObjStep, options: Options) !*std.build.LibExeObjStep {
            const lib = if (!options.separate_libs) step else blk: {
                const separate_lib = b.addStaticLibrary("dawn-native-mach", null);
                separate_lib.setBuildMode(if (options.debug) .Debug else .ReleaseFast);
                separate_lib.setTarget(step.target);
                if (!options.debug)
                    separate_lib.strip = true;
                separate_lib.linkLibCpp();
                if (options.install_libs)
                    separate_lib.install();
                break :blk separate_lib;
            };

            // TODO(build-system): pass system SDK options through
            try deps.glfw.link(b, lib, .{ .system_sdk = .{ .set_sysroot = false } });

            var cpp_flags = std.ArrayList([]const u8).init(b.allocator);
            try options.appendFlags(&cpp_flags, false, true);
            try appendDawnEnableBackendTypeFlags(&cpp_flags, options);
            try cpp_flags.appendSlice(&.{
                include(b, deps.glfw_include_dir),
                include(b, "libs/dawn/out/Debug/gen/include"),
                include(b, "libs/dawn/out/Debug/gen/src"),
                include(b, "libs/dawn/include"),
                include(b, "libs/dawn/src"),
            });
            if (step.target_info.target.os.tag == .windows) {
                try cpp_flags.appendSlice(&.{
                    "-D_DEBUG",
                    "-D_MT",
                    "-D_DLL",
                });
            }
            return lib;
        }

        // Builds common sources; derived from src/common/BUILD.gn
        fn buildLibDawnCommon(b: *Builder, step: *std.build.LibExeObjStep, options: Options) !*std.build.LibExeObjStep {
            const lib = if (!options.separate_libs) step else blk: {
                const separate_lib = b.addStaticLibrary("dawn-common", null);
                separate_lib.setBuildMode(if (options.debug) .Debug else .ReleaseFast);
                separate_lib.setTarget(step.target);
                if (!options.debug)
                    separate_lib.strip = true;
                separate_lib.linkLibCpp();
                if (options.install_libs)
                    separate_lib.install();
                break :blk separate_lib;
            };

            var flags = std.ArrayList([]const u8).init(b.allocator);
            try flags.appendSlice(&.{
                include(b, "libs/dawn/src"),
                include(b, "libs/dawn/out/Debug/gen/include"),
                include(b, "libs/dawn/out/Debug/gen/src"),
            });
            try appendLangScannedSources(b, lib, options, .{
                .rel_dirs = &.{
                    "libs/dawn/src/dawn/common/",
                    "libs/dawn/out/Debug/gen/src/dawn/common/",
                },
                .flags = flags.items,
                .excluding_contains = &.{
                    "test",
                    "benchmark",
                    "mock",
                    "WindowsUtils.cpp",
                },
            });

            var cpp_sources = std.ArrayList([]const u8).init(b.allocator);
            if (step.target_info.target.os.tag == .macos) {
                // TODO(build-system): pass system SDK options through
                deps.system_sdk.include(b, lib, .{});
                lib.linkFramework("Foundation");
                const abs_path = sdkPath(b, "/libs/dawn/src/dawn/common/SystemUtils_mac.mm");
                try cpp_sources.append(abs_path);
            }
            if (step.target_info.target.os.tag == .windows) {
                const abs_path = sdkPath(b, "/libs/dawn/src/dawn/common/WindowsUtils.cpp");
                try cpp_sources.append(abs_path);
            }

            var cpp_flags = std.ArrayList([]const u8).init(b.allocator);
            try cpp_flags.appendSlice(flags.items);
            try options.appendFlags(&cpp_flags, false, true);
            lib.addCSourceFiles(cpp_sources.items, cpp_flags.items);
            return lib;
        }

        // Build dawn platform sources; derived from src/dawn/platform/BUILD.gn
        fn buildLibDawnPlatform(b: *Builder, step: *std.build.LibExeObjStep, options: Options) !*std.build.LibExeObjStep {
            const lib = if (!options.separate_libs) step else blk: {
                const separate_lib = b.addStaticLibrary("dawn-platform", null);
                separate_lib.setBuildMode(if (options.debug) .Debug else .ReleaseFast);
                separate_lib.setTarget(step.target);
                if (!options.debug)
                    separate_lib.strip = true;
                separate_lib.linkLibCpp();
                if (options.install_libs)
                    separate_lib.install();
                break :blk separate_lib;
            };

            var cpp_flags = std.ArrayList([]const u8).init(b.allocator);
            try options.appendFlags(&cpp_flags, false, true);
            try cpp_flags.appendSlice(&.{
                include(b, "libs/dawn/src"),
                include(b, "libs/dawn/include"),

                include(b, "libs/dawn/out/Debug/gen/include"),
            });

            var cpp_sources = std.ArrayList([]const u8).init(b.allocator);
            inline for ([_][]const u8{
                "src/dawn/platform/DawnPlatform.cpp",
                "src/dawn/platform/WorkerThread.cpp",
                "src/dawn/platform/tracing/EventTracer.cpp",
            }) |path| {
                const abs_path = sdkPath(b, "/libs/dawn/" ++ path);
                try cpp_sources.append(abs_path);
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
        fn buildLibDawnNative(b: *Builder, step: *std.build.LibExeObjStep, options: Options) !*std.build.LibExeObjStep {
            const lib = if (!options.separate_libs) step else blk: {
                const separate_lib = b.addStaticLibrary("dawn-native", null);
                separate_lib.setBuildMode(if (options.debug) .Debug else .ReleaseFast);
                separate_lib.setTarget(step.target);
                if (!options.debug)
                    separate_lib.strip = true;
                separate_lib.linkLibCpp();
                if (options.install_libs)
                    separate_lib.install();
                break :blk separate_lib;
            };
            deps.system_sdk.include(b, lib, .{});

            var flags = std.ArrayList([]const u8).init(b.allocator);
            try appendDawnEnableBackendTypeFlags(&flags, options);
            try flags.appendSlice(&.{
                include(b, "libs/dawn"),
                include(b, "libs/dawn/src"),
                include(b, "libs/dawn/include"),
                include(b, "libs/dawn/third_party/vulkan-deps/spirv-tools/src/include"),
                include(b, "libs/dawn/third_party/abseil-cpp"),
                include(b, "libs/dawn/third_party/khronos"),

                // TODO(build-system): make these optional
                "-DTINT_BUILD_SPV_READER=1",
                "-DTINT_BUILD_SPV_WRITER=1",
                "-DTINT_BUILD_WGSL_READER=1",
                "-DTINT_BUILD_WGSL_WRITER=1",
                "-DTINT_BUILD_MSL_WRITER=1",
                "-DTINT_BUILD_HLSL_WRITER=1",
                "-DTINT_BUILD_GLSL_WRITER=1",

                include(b, "libs/dawn/"),
                include(b, "libs/dawn/include/tint"),
                include(b, "libs/dawn/third_party/vulkan-deps/vulkan-tools/src/"),

                include(b, "libs/dawn/out/Debug/gen/include"),
                include(b, "libs/dawn/out/Debug/gen/src"),
            });
            if (options.d3d12.?) try flags.appendSlice(dawn_d3d12_flags);

            try appendLangScannedSources(b, lib, options, .{
                .rel_dirs = &.{
                    "libs/dawn/out/Debug/gen/src/dawn/",
                    "libs/dawn/src/dawn/native/",
                    "libs/dawn/src/dawn/native/utils/",
                    "libs/dawn/src/dawn/native/stream/",
                },
                .flags = flags.items,
                .excluding_contains = &.{
                    "test",
                    "benchmark",
                    "mock",
                    "SpirvValidation.cpp",
                    "XlibXcbFunctions.cpp",
                    "dawn_proc.c",
                },
            });

            // dawn_native_gen
            try appendLangScannedSources(b, lib, options, .{
                .rel_dirs = &.{
                    "libs/dawn/out/Debug/gen/src/dawn/native/",
                },
                .flags = flags.items,
                .excluding_contains = &.{ "test", "benchmark", "mock", "webgpu_dawn_native_proc.cpp" },
            });

            // TODO(build-system): could allow enable_vulkan_validation_layers here. See src/dawn/native/BUILD.gn
            // TODO(build-system): allow use_angle here. See src/dawn/native/BUILD.gn
            // TODO(build-system): could allow use_swiftshader here. See src/dawn/native/BUILD.gn

            var cpp_sources = std.ArrayList([]const u8).init(b.allocator);
            if (options.d3d12.?) {
                lib.linkSystemLibraryName("dxgi");
                lib.linkSystemLibraryName("dxguid");

                inline for ([_][]const u8{
                    "src/dawn/mingw_helpers.cpp",
                }) |path| {
                    const abs_path = sdkPath(b, "/" ++ path);
                    try cpp_sources.append(abs_path);
                }

                try appendLangScannedSources(b, lib, options, .{
                    .rel_dirs = &.{
                        "libs/dawn/src/dawn/native/d3d12/",
                    },
                    .flags = flags.items,
                    .excluding_contains = &.{ "test", "benchmark", "mock" },
                });
            }
            if (options.metal.?) {
                lib.linkFramework("Metal");
                lib.linkFramework("CoreGraphics");
                lib.linkFramework("Foundation");
                lib.linkFramework("IOKit");
                lib.linkFramework("IOSurface");
                lib.linkFramework("QuartzCore");

                try appendLangScannedSources(b, lib, options, .{
                    .objc = true,
                    .rel_dirs = &.{
                        "libs/dawn/src/dawn/native/metal/",
                        "libs/dawn/src/dawn/native/",
                    },
                    .flags = flags.items,
                    .excluding_contains = &.{ "test", "benchmark", "mock" },
                });
            }

            if (options.linux_window_manager != null and options.linux_window_manager.? == .X11) {
                lib.linkSystemLibraryName("X11");
                inline for ([_][]const u8{
                    "src/dawn/native/XlibXcbFunctions.cpp",
                }) |path| {
                    const abs_path = sdkPath(b, "/libs/dawn/" ++ path);
                    try cpp_sources.append(abs_path);
                }
            }

            inline for ([_][]const u8{
                "src/dawn/native/null/DeviceNull.cpp",
            }) |path| {
                const abs_path = sdkPath(b, "/libs/dawn/" ++ path);
                try cpp_sources.append(abs_path);
            }

            if (options.desktop_gl.? or options.vulkan.?) {
                inline for ([_][]const u8{
                    "src/dawn/native/SpirvValidation.cpp",
                }) |path| {
                    const abs_path = sdkPath(b, "/libs/dawn/" ++ path);
                    try cpp_sources.append(abs_path);
                }
            }

            if (options.desktop_gl.?) {
                try appendLangScannedSources(b, lib, options, .{
                    .rel_dirs = &.{
                        "libs/dawn/out/Debug/gen/src/dawn/native/opengl/",
                        "libs/dawn/src/dawn/native/opengl/",
                    },
                    .flags = flags.items,
                    .excluding_contains = &.{ "test", "benchmark", "mock" },
                });
            }

            if (options.vulkan.?) {
                try appendLangScannedSources(b, lib, options, .{
                    .rel_dirs = &.{
                        "libs/dawn/src/dawn/native/vulkan/",
                    },
                    .flags = flags.items,
                    .excluding_contains = &.{ "test", "benchmark", "mock" },
                });

                if (isLinuxDesktopLike(step.target_info.target)) {
                    inline for ([_][]const u8{
                        "src/dawn/native/vulkan/external_memory/MemoryServiceOpaqueFD.cpp",
                        "src/dawn/native/vulkan/external_semaphore/SemaphoreServiceFD.cpp",
                    }) |path| {
                        const abs_path = sdkPath(b, "/libs/dawn/" ++ path);
                        try cpp_sources.append(abs_path);
                    }
                } else if (step.target_info.target.os.tag == .fuchsia) {
                    inline for ([_][]const u8{
                        "src/dawn/native/vulkan/external_memory/MemoryServiceZirconHandle.cpp",
                        "src/dawn/native/vulkan/external_semaphore/SemaphoreServiceZirconHandle.cpp",
                    }) |path| {
                        const abs_path = sdkPath(b, "/libs/dawn/" ++ path);
                        try cpp_sources.append(abs_path);
                    }
                } else {
                    inline for ([_][]const u8{
                        "src/dawn/native/vulkan/external_memory/MemoryServiceNull.cpp",
                        "src/dawn/native/vulkan/external_semaphore/SemaphoreServiceNull.cpp",
                    }) |path| {
                        const abs_path = sdkPath(b, "/libs/dawn/" ++ path);
                        try cpp_sources.append(abs_path);
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

            inline for ([_][]const u8{
                "src/dawn/native/null/NullBackend.cpp",
            }) |path| {
                const abs_path = sdkPath(b, "/libs/dawn/" ++ path);
                try cpp_sources.append(abs_path);
            }

            if (options.d3d12.?) {
                inline for ([_][]const u8{
                    "src/dawn/native/d3d12/D3D12Backend.cpp",
                }) |path| {
                    const abs_path = sdkPath(b, "/libs/dawn/" ++ path);
                    try cpp_sources.append(abs_path);
                }
            }
            if (options.desktop_gl.?) {
                inline for ([_][]const u8{
                    "src/dawn/native/opengl/OpenGLBackend.cpp",
                }) |path| {
                    const abs_path = sdkPath(b, "/libs/dawn/" ++ path);
                    try cpp_sources.append(abs_path);
                }
            }
            if (options.vulkan.?) {
                inline for ([_][]const u8{
                    "src/dawn/native/vulkan/VulkanBackend.cpp",
                }) |path| {
                    const abs_path = sdkPath(b, "/libs/dawn/" ++ path);
                    try cpp_sources.append(abs_path);
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
            try cpp_flags.appendSlice(flags.items);
            try options.appendFlags(&cpp_flags, false, true);
            lib.addCSourceFiles(cpp_sources.items, cpp_flags.items);
            return lib;
        }

        // Builds tint sources; derived from src/tint/BUILD.gn
        fn buildLibTint(b: *Builder, step: *std.build.LibExeObjStep, options: Options) !*std.build.LibExeObjStep {
            const lib = if (!options.separate_libs) step else blk: {
                const separate_lib = b.addStaticLibrary("tint", null);
                separate_lib.setBuildMode(if (options.debug) .Debug else .ReleaseFast);
                separate_lib.setTarget(step.target);
                if (!options.debug)
                    separate_lib.strip = true;
                separate_lib.linkLibCpp();
                if (options.install_libs)
                    separate_lib.install();
                break :blk separate_lib;
            };

            var flags = std.ArrayList([]const u8).init(b.allocator);
            try flags.appendSlice(&.{
                // TODO(build-system): make these optional
                "-DTINT_BUILD_SPV_READER=1",
                "-DTINT_BUILD_SPV_WRITER=1",
                "-DTINT_BUILD_WGSL_READER=1",
                "-DTINT_BUILD_WGSL_WRITER=1",
                "-DTINT_BUILD_MSL_WRITER=1",
                "-DTINT_BUILD_HLSL_WRITER=1",
                "-DTINT_BUILD_GLSL_WRITER=1",

                include(b, "libs/dawn/"),
                include(b, "libs/dawn/include/tint"),

                // Required for TINT_BUILD_SPV_READER=1 and TINT_BUILD_SPV_WRITER=1, if specified
                include(b, "libs/dawn/third_party/vulkan-deps"),
                include(b, "libs/dawn/third_party/vulkan-deps/spirv-tools/src"),
                include(b, "libs/dawn/third_party/vulkan-deps/spirv-tools/src/include"),
                include(b, "libs/dawn/third_party/vulkan-deps/spirv-headers/src/include"),
                include(b, "libs/dawn/out/Debug/gen/third_party/vulkan-deps/spirv-tools/src"),
                include(b, "libs/dawn/out/Debug/gen/third_party/vulkan-deps/spirv-tools/src/include"),
                include(b, "libs/dawn/include"),
            });

            // libtint_core_all_src
            try appendLangScannedSources(b, lib, options, .{
                .rel_dirs = &.{
                    "libs/dawn/src/tint",
                    "libs/dawn/src/tint/diagnostic/",
                    "libs/dawn/src/tint/inspector/",
                    "libs/dawn/src/tint/reader/",
                    "libs/dawn/src/tint/resolver/",
                    "libs/dawn/src/tint/utils/",
                    "libs/dawn/src/tint/text/",
                    "libs/dawn/src/tint/transform/",
                    "libs/dawn/src/tint/transform/utils",
                    "libs/dawn/src/tint/writer/",
                    "libs/dawn/src/tint/ast/",
                    "libs/dawn/src/tint/val/",
                },
                .flags = flags.items,
                .excluding_contains = &.{ "test", "bench", "printer_windows", "printer_linux", "printer_other", "glsl.cc" },
            });

            var cpp_sources = std.ArrayList([]const u8).init(b.allocator);
            switch (step.target_info.target.os.tag) {
                .windows => try cpp_sources.append(sdkPath(b, "/libs/dawn/src/tint/diagnostic/printer_windows.cc")),
                .linux => try cpp_sources.append(sdkPath(b, "/libs/dawn/src/tint/diagnostic/printer_linux.cc")),
                else => try cpp_sources.append(sdkPath(b, "/libs/dawn/src/tint/diagnostic/printer_other.cc")),
            }

            // libtint_sem_src
            try appendLangScannedSources(b, lib, options, .{
                .rel_dirs = &.{
                    "libs/dawn/src/tint/sem/",
                },
                .flags = flags.items,
                .excluding_contains = &.{ "test", "benchmark" },
            });

            // libtint_spv_reader_src
            try appendLangScannedSources(b, lib, options, .{
                .rel_dirs = &.{
                    "libs/dawn/src/tint/reader/spirv/",
                },
                .flags = flags.items,
                .excluding_contains = &.{ "test", "benchmark" },
            });

            // libtint_spv_writer_src
            try appendLangScannedSources(b, lib, options, .{
                .rel_dirs = &.{
                    "libs/dawn/src/tint/writer/spirv/",
                },
                .flags = flags.items,
                .excluding_contains = &.{ "test", "bench" },
            });

            // TODO(build-system): make optional
            // libtint_wgsl_reader_src
            try appendLangScannedSources(b, lib, options, .{
                .rel_dirs = &.{
                    "libs/dawn/src/tint/reader/wgsl/",
                },
                .flags = flags.items,
                .excluding_contains = &.{ "test", "bench" },
            });

            // TODO(build-system): make optional
            // libtint_wgsl_writer_src
            try appendLangScannedSources(b, lib, options, .{
                .rel_dirs = &.{
                    "libs/dawn/src/tint/writer/wgsl/",
                },
                .flags = flags.items,
                .excluding_contains = &.{ "test", "bench" },
            });

            // TODO(build-system): make optional
            // libtint_msl_writer_src
            try appendLangScannedSources(b, lib, options, .{
                .rel_dirs = &.{
                    "libs/dawn/src/tint/writer/msl/",
                },
                .flags = flags.items,
                .excluding_contains = &.{ "test", "bench" },
            });

            // TODO(build-system): make optional
            // libtint_hlsl_writer_src
            try appendLangScannedSources(b, lib, options, .{
                .rel_dirs = &.{
                    "libs/dawn/src/tint/writer/hlsl/",
                },
                .flags = flags.items,
                .excluding_contains = &.{ "test", "bench" },
            });

            // TODO(build-system): make optional
            // libtint_glsl_writer_src
            try appendLangScannedSources(b, lib, options, .{
                .rel_dirs = &.{
                    "libs/dawn/src/tint/writer/glsl/",
                },
                .flags = flags.items,
                .excluding_contains = &.{ "test", "bench" },
            });

            var cpp_flags = std.ArrayList([]const u8).init(b.allocator);
            try cpp_flags.appendSlice(flags.items);
            try options.appendFlags(&cpp_flags, false, true);
            lib.addCSourceFiles(cpp_sources.items, cpp_flags.items);
            return lib;
        }

        // Builds third_party/vulkan-deps/spirv-tools sources; derived from third_party/vulkan-deps/spirv-tools/src/BUILD.gn
        fn buildLibSPIRVTools(b: *Builder, step: *std.build.LibExeObjStep, options: Options) !*std.build.LibExeObjStep {
            const lib = if (!options.separate_libs) step else blk: {
                const separate_lib = b.addStaticLibrary("spirv-tools", null);
                separate_lib.setBuildMode(if (options.debug) .Debug else .ReleaseFast);
                separate_lib.setTarget(step.target);
                if (!options.debug)
                    separate_lib.strip = true;
                separate_lib.linkLibCpp();
                if (options.install_libs)
                    separate_lib.install();
                break :blk separate_lib;
            };

            var flags = std.ArrayList([]const u8).init(b.allocator);
            try flags.appendSlice(&.{
                include(b, "libs/dawn"),
                include(b, "libs/dawn/third_party/vulkan-deps/spirv-tools/src"),
                include(b, "libs/dawn/third_party/vulkan-deps/spirv-tools/src/include"),
                include(b, "libs/dawn/third_party/vulkan-deps/spirv-headers/src/include"),
                include(b, "libs/dawn/out/Debug/gen/third_party/vulkan-deps/spirv-tools/src"),
                include(b, "libs/dawn/out/Debug/gen/third_party/vulkan-deps/spirv-tools/src/include"),
                include(b, "libs/dawn/third_party/vulkan-deps/spirv-headers/src/include/spirv/unified1"),
            });

            // spvtools
            try appendLangScannedSources(b, lib, options, .{
                .rel_dirs = &.{
                    "libs/dawn/third_party/vulkan-deps/spirv-tools/src/source/",
                    "libs/dawn/third_party/vulkan-deps/spirv-tools/src/source/util/",
                },
                .flags = flags.items,
                .excluding_contains = &.{ "test", "benchmark" },
            });

            // spvtools_val
            try appendLangScannedSources(b, lib, options, .{
                .rel_dirs = &.{
                    "libs/dawn/third_party/vulkan-deps/spirv-tools/src/source/val/",
                },
                .flags = flags.items,
                .excluding_contains = &.{ "test", "benchmark" },
            });

            // spvtools_opt
            try appendLangScannedSources(b, lib, options, .{
                .rel_dirs = &.{
                    "libs/dawn/third_party/vulkan-deps/spirv-tools/src/source/opt/",
                },
                .flags = flags.items,
                .excluding_contains = &.{ "test", "benchmark" },
            });

            // spvtools_link
            try appendLangScannedSources(b, lib, options, .{
                .rel_dirs = &.{
                    "libs/dawn/third_party/vulkan-deps/spirv-tools/src/source/link/",
                },
                .flags = flags.items,
                .excluding_contains = &.{ "test", "benchmark" },
            });
            return lib;
        }

        // Builds third_party/abseil sources; derived from:
        //
        // ```
        // $ find third_party/abseil-cpp/absl | grep '\.cc' | grep -v 'test' | grep -v 'benchmark' | grep -v gaussian_distribution_gentables | grep -v print_hash_of | grep -v chi_square
        // ```
        //
        fn buildLibAbseilCpp(b: *Builder, step: *std.build.LibExeObjStep, options: Options) !*std.build.LibExeObjStep {
            const lib = if (!options.separate_libs) step else blk: {
                const separate_lib = b.addStaticLibrary("abseil-cpp-common", null);
                separate_lib.setBuildMode(if (options.debug) .Debug else .ReleaseFast);
                separate_lib.setTarget(step.target);
                if (!options.debug)
                    separate_lib.strip = true;
                separate_lib.linkLibCpp();
                if (options.install_libs)
                    separate_lib.install();
                break :blk separate_lib;
            };
            deps.system_sdk.include(b, lib, .{});

            const target = step.target_info.target;
            if (target.os.tag == .macos) lib.linkFramework("CoreFoundation");
            if (target.os.tag == .windows) lib.linkSystemLibraryName("bcrypt");

            var flags = std.ArrayList([]const u8).init(b.allocator);
            try flags.appendSlice(&.{
                include(b, "libs/dawn"),
                include(b, "libs/dawn/third_party/abseil-cpp"),
            });
            if (target.os.tag == .windows) try flags.appendSlice(&.{
                "-DABSL_FORCE_THREAD_IDENTITY_MODE=2",
                "-DWIN32_LEAN_AND_MEAN",
                "-DD3D10_ARBITRARY_HEADER_ORDERING",
                "-D_CRT_SECURE_NO_WARNINGS",
                "-DNOMINMAX",
                include(b, "src/dawn/zig_mingw_pthread"),
            });

            // absl
            try appendLangScannedSources(b, lib, options, .{
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
            });
            return lib;
        }

        // Buids dawn wire sources; derived from src/dawn/wire/BUILD.gn
        fn buildLibDawnWire(b: *Builder, step: *std.build.LibExeObjStep, options: Options) !*std.build.LibExeObjStep {
            const lib = if (!options.separate_libs) step else blk: {
                const separate_lib = b.addStaticLibrary("dawn-wire", null);
                separate_lib.setBuildMode(if (options.debug) .Debug else .ReleaseFast);
                separate_lib.setTarget(step.target);
                if (!options.debug)
                    separate_lib.strip = true;
                separate_lib.linkLibCpp();
                if (options.install_libs)
                    separate_lib.install();
                break :blk separate_lib;
            };

            var flags = std.ArrayList([]const u8).init(b.allocator);
            try flags.appendSlice(&.{
                include(b, "libs/dawn"),
                include(b, "libs/dawn/src"),
                include(b, "libs/dawn/include"),
                include(b, "libs/dawn/out/Debug/gen/include"),
                include(b, "libs/dawn/out/Debug/gen/src"),
            });

            try appendLangScannedSources(b, lib, options, .{
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
            });
            return lib;
        }

        // Builds dawn utils sources; derived from src/dawn/utils/BUILD.gn
        fn buildLibDawnUtils(b: *Builder, step: *std.build.LibExeObjStep, options: Options) !*std.build.LibExeObjStep {
            const lib = if (!options.separate_libs) step else blk: {
                const separate_lib = b.addStaticLibrary("dawn-utils", null);
                separate_lib.setBuildMode(if (options.debug) .Debug else .ReleaseFast);
                separate_lib.setTarget(step.target);
                if (!options.debug)
                    separate_lib.strip = true;
                separate_lib.linkLibCpp();
                if (options.install_libs)
                    separate_lib.install();
                break :blk separate_lib;
            };
            try deps.glfw.link(b, lib, .{ .system_sdk = .{ .set_sysroot = false } });

            var flags = std.ArrayList([]const u8).init(b.allocator);
            try appendDawnEnableBackendTypeFlags(&flags, options);
            try flags.appendSlice(&.{
                include(b, deps.glfw_include_dir),
                include(b, "libs/dawn/src"),
                include(b, "libs/dawn/include"),
                include(b, "libs/dawn/out/Debug/gen/include"),
            });

            var cpp_sources = std.ArrayList([]const u8).init(b.allocator);
            inline for ([_][]const u8{
                "src/dawn/utils/BackendBinding.cpp",
                "src/dawn/utils/NullBinding.cpp",
            }) |path| {
                const abs_path = sdkPath(b, "/libs/dawn/" ++ path);
                try cpp_sources.append(abs_path);
            }

            if (options.d3d12.?) {
                inline for ([_][]const u8{
                    "src/dawn/utils/D3D12Binding.cpp",
                }) |path| {
                    const abs_path = sdkPath(b, "/libs/dawn/" ++ path);
                    try cpp_sources.append(abs_path);
                }
                try flags.appendSlice(dawn_d3d12_flags);
            }
            if (options.metal.?) {
                inline for ([_][]const u8{
                    "src/dawn/utils/MetalBinding.mm",
                }) |path| {
                    const abs_path = sdkPath(b, "/libs/dawn/" ++ path);
                    try cpp_sources.append(abs_path);
                }
            }

            if (options.desktop_gl.?) {
                inline for ([_][]const u8{
                    "src/dawn/utils/OpenGLBinding.cpp",
                }) |path| {
                    const abs_path = sdkPath(b, "/libs/dawn/" ++ path);
                    try cpp_sources.append(abs_path);
                }
            }

            if (options.vulkan.?) {
                inline for ([_][]const u8{
                    "src/dawn/utils/VulkanBinding.cpp",
                }) |path| {
                    const abs_path = sdkPath(b, "/libs/dawn/" ++ path);
                    try cpp_sources.append(abs_path);
                }
            }

            var cpp_flags = std.ArrayList([]const u8).init(b.allocator);
            try cpp_flags.appendSlice(flags.items);
            try options.appendFlags(&cpp_flags, false, true);
            lib.addCSourceFiles(cpp_sources.items, cpp_flags.items);
            return lib;
        }

        // Buids dxcompiler sources; derived from libs/DirectXShaderCompiler/CMakeLists.txt
        fn buildLibDxcompiler(b: *Builder, step: *std.build.LibExeObjStep, options: Options) !*std.build.LibExeObjStep {
            const lib = if (!options.separate_libs) step else blk: {
                const separate_lib = b.addStaticLibrary("dxcompiler", null);
                separate_lib.setBuildMode(if (options.debug) .Debug else .ReleaseFast);
                separate_lib.setTarget(step.target);
                if (!options.debug)
                    separate_lib.strip = true;
                separate_lib.linkLibCpp();
                if (options.install_libs)
                    separate_lib.install();
                break :blk separate_lib;
            };
            deps.system_sdk.include(b, lib, .{});

            lib.linkSystemLibraryName("oleaut32");
            lib.linkSystemLibraryName("ole32");
            lib.linkSystemLibraryName("dbghelp");
            lib.linkSystemLibraryName("dxguid");
            lib.linkLibCpp();

            var flags = std.ArrayList([]const u8).init(b.allocator);
            try flags.appendSlice(&.{
                include(b, "libs/"),
                include(b, "libs/DirectXShaderCompiler/include/llvm/llvm_assert"),
                include(b, "libs/DirectXShaderCompiler/include"),
                include(b, "libs/DirectXShaderCompiler/build/include"),
                include(b, "libs/DirectXShaderCompiler/build/lib/HLSL"),
                include(b, "libs/DirectXShaderCompiler/build/lib/DxilPIXPasses"),
                include(b, "libs/DirectXShaderCompiler/build/include"),
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
            });

            try appendLangScannedSources(b, lib, options, .{
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
                    "libs/DirectXShaderCompiler/lib/Miniz",
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
            });

            try appendLangScannedSources(b, lib, options, .{
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
            });

            try appendLangScannedSources(b, lib, options, .{
                .zero_debug_symbols = true,
                .rel_dirs = &.{
                    "libs/DirectXShaderCompiler/lib/Bitcode/Reader",
                },
                .flags = flags.items,
                .excluding_contains = &.{
                    "BitReader.cpp", // ignore
                },
            });
            return lib;
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
            try options.appendFlags(&cpp_flags, args.zero_debug_symbols, true);
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
            try options.appendFlags(&flags, args.zero_debug_symbols, false);
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
            const abs_dir = try std.fs.path.join(b.allocator, &.{ sdkPath(b, "/"), rel_dir });
            defer b.allocator.free(abs_dir);
            var dir = try std.fs.openIterableDirAbsolute(abs_dir, .{});
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

        var this_dir: ?[]const u8 = null;

        fn thisDir(allocator: std.mem.Allocator) []const u8 {
            if (this_dir == null) {
                const unresolved_dir = comptime std.fs.path.dirname(@src().file) orelse ".";

                if (comptime unresolved_dir[0] == '/') {
                    this_dir = unresolved_dir;
                } else {
                    this_dir = std.fs.cwd().realpathAlloc(allocator, unresolved_dir) catch unreachable;
                }
            }

            return this_dir.?;
        }

        fn sdkPath(b: *Builder, comptime suffix: []const u8) []const u8 {
            return sdkPathAllocator(b.allocator, suffix);
        }

        fn sdkPathAllocator(allocator: std.mem.Allocator, comptime suffix: []const u8) []const u8 {
            if (suffix[0] != '/') @compileError("suffix must be an absolute path");

            return std.fs.path.resolve(allocator, &.{ thisDir(allocator), suffix[1..] }) catch unreachable;
        }

        fn include(b: *Builder, comptime rel: []const u8) []const u8 {
            return std.mem.concat(b.allocator, u8, &.{ "-I", sdkPath(b, "/" ++ rel) }) catch unreachable;
        }
    };
}
