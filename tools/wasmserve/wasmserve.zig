const std = @import("std");
const builtin = @import("builtin");
const mime = @import("mime.zig");
const net = std.net;
const mem = std.mem;
const fs = std.fs;
const build = std.build;

const www_dir_path = "/www";
const buffer_size = 2048;
const esc = struct {
    pub const reset = "\x1b[0m";
    pub const bold = "\x1b[1m";
    pub const underline = "\x1b[4m";
    pub const red = "\x1b[31m";
    pub const yellow = "\x1b[33m";
    pub const cyan = "\x1b[36m";
    pub const gray = "\x1b[90m";
};

pub const Options = struct {
    install_dir: ?build.InstallDir = null,
    watch_paths: ?[]const []const u8 = null,
    listen_address: ?net.Address = null,
};

pub const Error = error{CannotOpenDirectory} || mem.Allocator.Error;

pub fn serve(step: *build.LibExeObjStep, options: Options) Error!*Wasmserve {
    const self = try step.builder.allocator.create(Wasmserve);
    const install_dir = options.install_dir orelse build.InstallDir{ .lib = {} };
    const install_dir_iter = fs.cwd().makeOpenPathIterable(step.builder.getInstallPath(install_dir, ""), .{}) catch
        return error.CannotOpenDirectory;
    self.* = Wasmserve{
        .step = build.Step.init(.run, "wasmserve", step.builder.allocator, Wasmserve.make),
        .b = step.builder,
        .exe_step = step,
        .install_dir = install_dir,
        .install_dir_iter = install_dir_iter,
        .address = options.listen_address orelse net.Address.initIp4([4]u8{ 127, 0, 0, 1 }, 8080),
        .subscriber = null,
        .watch_paths = options.watch_paths orelse &.{step.root_src.?.path},
        .mtimes = std.AutoHashMap(fs.File.INode, i128).init(step.builder.allocator),
        .notify_msg = null,
    };
    return self;
}

const Wasmserve = struct {
    step: build.Step,
    b: *build.Builder,
    exe_step: *build.LibExeObjStep,
    install_dir: build.InstallDir,
    install_dir_iter: fs.IterableDir,
    address: net.Address,
    subscriber: ?*net.StreamServer.Connection,
    watch_paths: []const []const u8,
    mtimes: std.AutoHashMap(fs.File.INode, i128),
    notify_msg: ?NotifyMessage,

    const NotifyMessage = struct {
        const Event = enum {
            built,
            build_error,
            stopped,
        };

        event: Event,
        data: []const u8,
    };

    pub fn make(step: *build.Step) !void {
        const self = @fieldParentPtr(Wasmserve, "step", step);

        self.compile();
        std.debug.assert(mem.eql(u8, fs.path.extension(self.exe_step.out_filename), ".wasm"));

        const resolved_www_dir_path = sdkPathAllocator(step.dependencies.allocator, www_dir_path);

        var www_dir = try fs.cwd().openIterableDir(resolved_www_dir_path, .{});
        defer www_dir.close();
        var www_dir_iter = www_dir.iterate();
        while (try www_dir_iter.next()) |file| {
            const path = try fs.path.join(self.b.allocator, &.{ resolved_www_dir_path, file.name });
            defer self.b.allocator.free(path);
            const install_www = self.b.addInstallFileWithDir(
                .{ .path = path },
                self.install_dir,
                file.name,
            );
            try install_www.step.make();
        }

        const watch_thread = try std.Thread.spawn(.{}, watch, .{self});
        defer watch_thread.detach();
        try self.runServer();
    }

    fn runServer(self: *Wasmserve) !void {
        var server = net.StreamServer.init(.{ .reuse_address = true });
        defer server.deinit();
        try server.listen(self.address);

        var addr_buf = @as([45]u8, undefined);
        var fbs = std.io.fixedBufferStream(&addr_buf);
        if (self.address.format("", .{}, fbs.writer())) {
            std.log.info("Started listening at " ++ esc.cyan ++ esc.underline ++ "http://{s}" ++ esc.reset ++ "...", .{fbs.getWritten()});
        } else |err| logErr(err, @src());

        while (server.accept()) |conn| {
            self.respond(conn) catch |err| {
                logErr(err, @src());
                continue;
            };
        } else |err| logErr(err, @src());
    }

    fn respond(self: *Wasmserve, conn: net.StreamServer.Connection) !void {
        errdefer respondError(conn.stream, 500, "Internal Server Error") catch |err| logErr(err, @src());

        var recv_buf: [buffer_size]u8 = undefined;
        const first_line = conn.stream.reader().readUntilDelimiter(&recv_buf, '\n') catch |err| {
            switch (err) {
                error.StreamTooLong => try respondError(conn.stream, 414, "Too Long Request"),
                else => try respondError(conn.stream, 400, "Bad Request"),
            }
            return;
        };
        var first_line_iter = mem.split(u8, first_line, " ");
        _ = first_line_iter.next(); // skip method
        if (first_line_iter.next()) |uri| {
            if (uri[0] != '/') {
                try respondError(conn.stream, 400, "Bad Request");
                return;
            }

            const url = dropFragment(uri)[1..];
            if (mem.eql(u8, url, "notify")) {
                _ = try conn.stream.write("HTTP/1.1 200 OK\r\nConnection: Keep-Alive\r\nContent-Type: text/event-stream\r\nCache-Control: No-Cache\r\n\r\n");
                self.subscriber = try self.b.allocator.create(net.StreamServer.Connection);
                self.subscriber.?.* = conn;
                if (self.notify_msg) |msg|
                    if (msg.event != .built)
                        self.notify();
                return;
            }
            if (self.researchPath(url)) |file_path| {
                try self.respondFile(conn.stream, file_path);
                return;
            } else |_| {}

            try respondError(conn.stream, 404, "Not Found");
        } else {
            try respondError(conn.stream, 400, "Bad Request");
        }
    }

    fn respondFile(self: Wasmserve, stream: net.Stream, path: []const u8) !void {
        const ext = fs.path.extension(path);
        var file_mime: []const u8 = "text/plain";
        inline for (mime.mime_list) |entry| {
            for (entry.ext) |ext_entry| {
                if (std.mem.eql(u8, ext, ext_entry))
                    file_mime = entry.mime;
            }
        }

        const file = try self.install_dir_iter.dir.openFile(path, .{});
        defer file.close();
        const file_size = try file.getEndPos();

        try stream.writer().print(
            "HTTP/1.1 200 OK\r\n" ++
                "Connection: close\r\n" ++
                "Content-Length: {d}\r\n" ++
                "Content-Type: {s}\r\n" ++
                "\r\n",
            .{ file_size, file_mime },
        );
        try fs.File.writeFileAll(.{ .handle = stream.handle }, file, .{});
    }

    fn respondError(stream: net.Stream, code: u32, desc: []const u8) !void {
        try stream.writer().print(
            "HTTP/1.1 {d} {s}\r\n" ++
                "Connection: close\r\n" ++
                "Content-Length: {d}\r\n" ++
                "Content-Type: text/html\r\n" ++
                "\r\n<!DOCTYPE html><html><body><h1>{s}</h1></body></html>",
            .{ code, desc, desc.len + 50, desc },
        );
    }

    fn researchPath(self: Wasmserve, path: []const u8) ![]const u8 {
        var walker = try self.install_dir_iter.walk(self.b.allocator);
        defer walker.deinit();
        while (try walker.next()) |walk_entry| {
            if (walk_entry.kind != .File) continue;
            if (mem.eql(u8, walk_entry.path, path) or (path.len == 0 and mem.eql(u8, walk_entry.path, "index.html")))
                return try self.b.allocator.dupe(u8, walk_entry.path);
        }
        return error.FileNotFound;
    }

    fn watch(self: *Wasmserve) void {
        timer_loop: while (true) : (std.time.sleep(500 * std.time.ns_per_ms)) {
            for (self.watch_paths) |path| {
                var dir = fs.cwd().openIterableDir(path, .{}) catch continue;
                defer dir.close();
                var walker = dir.walk(self.b.allocator) catch |err| {
                    logErr(err, @src());
                    continue;
                };
                defer walker.deinit();
                while (walker.next() catch |err| {
                    logErr(err, @src());
                    continue;
                }) |walk_entry| {
                    if (walk_entry.kind != .File) continue;
                    if (self.checkForUpdate(dir.dir, walk_entry.path)) |is_updated| {
                        if (is_updated)
                            continue :timer_loop;
                    } else |err| {
                        logErr(err, @src());
                        continue;
                    }
                }
            }
        }
    }

    fn checkForUpdate(self: *Wasmserve, p_dir: fs.Dir, path: []const u8) !bool {
        const stat = try p_dir.statFile(path);
        const entry = try self.mtimes.getOrPut(stat.inode);
        if (entry.found_existing and stat.mtime > entry.value_ptr.*) {
            std.log.info(esc.yellow ++ esc.underline ++ "{s}" ++ esc.reset ++ " updated", .{path});
            self.compile();
            entry.value_ptr.* = stat.mtime;
            return true;
        }
        entry.value_ptr.* = stat.mtime;
        return false;
    }

    fn notify(self: *Wasmserve) void {
        if (self.subscriber) |s| {
            if (self.notify_msg) |msg| {
                s.stream.writer().print("event: {s}\n", .{@tagName(msg.event)}) catch |err| logErr(err, @src());

                var lines = std.mem.split(u8, msg.data, "\n");
                while (lines.next()) |line|
                    s.stream.writer().print("data: {s}\n", .{line}) catch |err| logErr(err, @src());
                _ = s.stream.write("\n") catch |err| logErr(err, @src());
            }
        }
    }

    fn compile(self: *Wasmserve) void {
        std.log.info("Building...", .{});
        const argv = getExecArgs(self.exe_step) catch |err| {
            logErr(err, @src());
            return;
        };
        defer self.b.allocator.free(argv);
        var res = std.ChildProcess.exec(.{ .argv = argv, .allocator = self.b.allocator }) catch |err| {
            logErr(err, @src());
            return;
        };
        defer self.b.allocator.free(res.stdout);
        if (self.notify_msg) |msg|
            if (msg.event == .build_error)
                self.b.allocator.free(msg.data);

        switch (res.term) {
            .Exited => |code| {
                if (code == 0) {
                    std.log.info("Built", .{});
                    self.notify_msg = .{
                        .event = .built,
                        .data = "",
                    };
                } else {
                    std.log.err("Compile error", .{});
                    self.notify_msg = .{
                        .event = .build_error,
                        .data = res.stderr,
                    };
                }
            },
            .Signal, .Stopped, .Unknown => {
                std.log.err("The build process has stopped unexpectedly", .{});
                self.notify_msg = .{
                    .event = .stopped,
                    .data = "",
                };
            },
        }
        std.io.getStdErr().writeAll(res.stderr) catch |err| logErr(err, @src());
        self.notify();
    }
};

fn dropFragment(input: []const u8) []const u8 {
    for (input) |c, i|
        if (c == '?' or c == '#')
            return input[0..i];

    return input;
}

fn logErr(err: anyerror, src: std.builtin.SourceLocation) void {
    if (@errorReturnTrace()) |bt| {
        std.log.err(esc.red ++ esc.bold ++ "{s}" ++ esc.reset ++ " >>>\n{s}", .{ @errorName(err), bt });
    } else {
        var file_name_buf: [1024]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&file_name_buf);
        const allocator = fba.allocator();
        const file_path = fs.path.relative(allocator, ".", src.file) catch @as([]const u8, src.file);
        std.log.err(esc.red ++ esc.bold ++ "{s}" ++ esc.reset ++
            " at " ++ esc.underline ++ "{s}:{d}:{d}" ++ esc.reset ++
            esc.gray ++ " fn {s}()" ++ esc.reset, .{
            @errorName(err),
            file_path,
            src.line,
            src.column,
            src.fn_name,
        });
    }
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

inline fn sdkPath(b: *build.Builder, comptime suffix: []const u8) []const u8 {
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

// copied from LibExeObjStep.make()
// TODO: this is very tricky
fn getExecArgs(self: *build.LibExeObjStep) ![]const []const u8 {
    const builder = self.builder;

    if (self.root_src == null and self.link_objects.items.len == 0) {
        std.log.err("linker needs 1 or more objects to link", .{});
        return error.NeedAnObject;
    }

    var zig_args = std.ArrayList([]const u8).init(builder.allocator);
    defer zig_args.deinit();

    zig_args.append(builder.zig_exe) catch unreachable;

    const cmd = switch (self.kind) {
        .lib => "build-lib",
        .exe => "build-exe",
        .obj => "build-obj",
        .@"test" => "test",
        .test_exe => "test",
    };
    zig_args.append(cmd) catch unreachable;

    try zig_args.append("--color");
    try zig_args.append("on");

    if (builder.reference_trace) |some| {
        try zig_args.append(try std.fmt.allocPrint(builder.allocator, "-freference-trace={d}", .{some}));
    }

    if (self.use_llvm) |use_llvm| {
        if (use_llvm) {
            try zig_args.append("-fLLVM");
        } else {
            try zig_args.append("-fno-LLVM");
        }
    }

    if (self.use_lld) |use_lld| {
        if (use_lld) {
            try zig_args.append("-fLLD");
        } else {
            try zig_args.append("-fno-LLD");
        }
    }

    if (self.target.ofmt) |ofmt| {
        try zig_args.append(try std.fmt.allocPrint(builder.allocator, "-ofmt={s}", .{@tagName(ofmt)}));
    }

    if (self.entry_symbol_name) |entry| {
        try zig_args.append("--entry");
        try zig_args.append(entry);
    }

    if (self.stack_size) |stack_size| {
        try zig_args.append("--stack");
        try zig_args.append(try std.fmt.allocPrint(builder.allocator, "{}", .{stack_size}));
    }

    if (self.root_src) |root_src| try zig_args.append(root_src.getPath(builder));

    var prev_has_extra_flags = false;

    // Resolve transitive dependencies
    {
        var transitive_dependencies = std.ArrayList(build.LibExeObjStep.LinkObject).init(builder.allocator);
        defer transitive_dependencies.deinit();

        for (self.link_objects.items) |link_object| {
            switch (link_object) {
                .other_step => |other| {
                    // Inherit dependency on system libraries
                    for (other.link_objects.items) |other_link_object| {
                        switch (other_link_object) {
                            .system_lib => try transitive_dependencies.append(other_link_object),
                            else => continue,
                        }
                    }

                    // Inherit dependencies on darwin frameworks
                    if (!other.isDynamicLibrary()) {
                        var it = other.frameworks.iterator();
                        while (it.next()) |framework| {
                            self.frameworks.put(framework.key_ptr.*, framework.value_ptr.*) catch unreachable;
                        }
                    }
                },
                else => continue,
            }
        }

        try self.link_objects.appendSlice(transitive_dependencies.items);
    }

    for (self.link_objects.items) |link_object| {
        switch (link_object) {
            .static_path => |static_path| try zig_args.append(static_path.getPath(builder)),

            .other_step => |other| switch (other.kind) {
                .exe => @panic("Cannot link with an executable build artifact"),
                .test_exe => @panic("Cannot link with an executable build artifact"),
                .@"test" => @panic("Cannot link with a test"),
                .obj => {
                    try zig_args.append(other.getOutputSource().getPath(builder));
                },
                .lib => {
                    const full_path_lib = other.getOutputLibSource().getPath(builder);
                    try zig_args.append(full_path_lib);

                    if (other.linkage != null and other.linkage.? == .dynamic and !self.target.isWindows()) {
                        if (fs.path.dirname(full_path_lib)) |dirname| {
                            try zig_args.append("-rpath");
                            try zig_args.append(dirname);
                        }
                    }
                },
            },

            .system_lib => |system_lib| {
                const prefix: []const u8 = prefix: {
                    if (system_lib.needed) break :prefix "-needed-l";
                    if (system_lib.weak) {
                        if (self.target.isDarwin()) break :prefix "-weak-l";
                        std.log.warn("Weak library import used for a non-darwin target, this will be converted to normally library import `-lname`", .{});
                    }
                    break :prefix "-l";
                };
                switch (system_lib.use_pkg_config) {
                    .no => try zig_args.append(builder.fmt("{s}{s}", .{ prefix, system_lib.name })),
                    .yes, .force => {
                        if (self.runPkgConfig(system_lib.name)) |args| {
                            try zig_args.appendSlice(args);
                        } else |err| switch (err) {
                            error.PkgConfigInvalidOutput,
                            error.PkgConfigCrashed,
                            error.PkgConfigFailed,
                            error.PkgConfigNotInstalled,
                            error.PackageNotFound,
                            => switch (system_lib.use_pkg_config) {
                                .yes => {
                                    // pkg-config failed, so fall back to linking the library
                                    // by name directly.
                                    try zig_args.append(builder.fmt("{s}{s}", .{
                                        prefix,
                                        system_lib.name,
                                    }));
                                },
                                .force => {
                                    std.debug.panic("pkg-config failed for library {s}", .{system_lib.name});
                                },
                                .no => unreachable,
                            },

                            else => |e| return e,
                        }
                    },
                }
            },

            .assembly_file => |asm_file| {
                if (prev_has_extra_flags) {
                    try zig_args.append("-extra-cflags");
                    try zig_args.append("--");
                    prev_has_extra_flags = false;
                }
                try zig_args.append(asm_file.getPath(builder));
            },

            .c_source_file => |c_source_file| {
                if (c_source_file.args.len == 0) {
                    if (prev_has_extra_flags) {
                        try zig_args.append("-cflags");
                        try zig_args.append("--");
                        prev_has_extra_flags = false;
                    }
                } else {
                    try zig_args.append("-cflags");
                    for (c_source_file.args) |arg| {
                        try zig_args.append(arg);
                    }
                    try zig_args.append("--");
                }
                try zig_args.append(c_source_file.source.getPath(builder));
            },

            .c_source_files => |c_source_files| {
                if (c_source_files.flags.len == 0) {
                    if (prev_has_extra_flags) {
                        try zig_args.append("-cflags");
                        try zig_args.append("--");
                        prev_has_extra_flags = false;
                    }
                } else {
                    try zig_args.append("-cflags");
                    for (c_source_files.flags) |flag| {
                        try zig_args.append(flag);
                    }
                    try zig_args.append("--");
                }
                for (c_source_files.files) |file| {
                    try zig_args.append(builder.pathFromRoot(file));
                }
            },
        }
    }

    if (self.image_base) |image_base| {
        try zig_args.append("--image-base");
        try zig_args.append(builder.fmt("0x{x}", .{image_base}));
    }

    if (self.filter) |filter| {
        try zig_args.append("--test-filter");
        try zig_args.append(filter);
    }

    if (self.test_evented_io) {
        try zig_args.append("--test-evented-io");
    }

    if (self.name_prefix.len != 0) {
        try zig_args.append("--test-name-prefix");
        try zig_args.append(self.name_prefix);
    }

    if (self.test_runner) |test_runner| {
        try zig_args.append("--test-runner");
        try zig_args.append(builder.pathFromRoot(test_runner));
    }

    for (builder.debug_log_scopes) |log_scope| {
        try zig_args.append("--debug-log");
        try zig_args.append(log_scope);
    }

    if (builder.debug_compile_errors) {
        try zig_args.append("--debug-compile-errors");
    }

    if (builder.verbose_cimport) zig_args.append("--verbose-cimport") catch unreachable;
    if (builder.verbose_air) zig_args.append("--verbose-air") catch unreachable;
    if (builder.verbose_llvm_ir) zig_args.append("--verbose-llvm-ir") catch unreachable;
    if (builder.verbose_link or self.verbose_link) zig_args.append("--verbose-link") catch unreachable;
    if (builder.verbose_cc or self.verbose_cc) zig_args.append("--verbose-cc") catch unreachable;
    if (builder.verbose_llvm_cpu_features) zig_args.append("--verbose-llvm-cpu-features") catch unreachable;

    if (self.emit_h) try zig_args.append("-femit-h");

    if (self.strip) |strip| {
        if (strip) {
            try zig_args.append("-fstrip");
        } else {
            try zig_args.append("-fno-strip");
        }
    }

    if (self.unwind_tables) |unwind_tables| {
        if (unwind_tables) {
            try zig_args.append("-funwind-tables");
        } else {
            try zig_args.append("-fno-unwind-tables");
        }
    }

    switch (self.compress_debug_sections) {
        .none => {},
        .zlib => try zig_args.append("--compress-debug-sections=zlib"),
    }

    if (self.link_eh_frame_hdr) {
        try zig_args.append("--eh-frame-hdr");
    }
    if (self.link_emit_relocs) {
        try zig_args.append("--emit-relocs");
    }
    if (self.link_function_sections) {
        try zig_args.append("-ffunction-sections");
    }
    if (self.link_gc_sections) |x| {
        try zig_args.append(if (x) "--gc-sections" else "--no-gc-sections");
    }
    if (self.linker_allow_shlib_undefined) |x| {
        try zig_args.append(if (x) "-fallow-shlib-undefined" else "-fno-allow-shlib-undefined");
    }
    if (self.link_z_notext) {
        try zig_args.append("-z");
        try zig_args.append("notext");
    }
    if (!self.link_z_relro) {
        try zig_args.append("-z");
        try zig_args.append("norelro");
    }
    if (self.link_z_lazy) {
        try zig_args.append("-z");
        try zig_args.append("lazy");
    }

    if (self.libc_file) |libc_file| {
        try zig_args.append("--libc");
        try zig_args.append(libc_file.getPath(self.builder));
    } else if (builder.libc_file) |libc_file| {
        try zig_args.append("--libc");
        try zig_args.append(libc_file);
    }

    switch (self.build_mode) {
        .Debug => {}, // Skip since it's the default.
        else => zig_args.append(builder.fmt("-O{s}", .{@tagName(self.build_mode)})) catch unreachable,
    }

    try zig_args.append("--cache-dir");
    try zig_args.append(builder.pathFromRoot(builder.cache_root));

    try zig_args.append("--global-cache-dir");
    try zig_args.append(builder.pathFromRoot(builder.global_cache_root));

    zig_args.append("--name") catch unreachable;
    zig_args.append(self.name) catch unreachable;

    if (self.linkage) |some| switch (some) {
        .dynamic => try zig_args.append("-dynamic"),
        .static => try zig_args.append("-static"),
    };
    if (self.kind == .lib and self.linkage != null and self.linkage.? == .dynamic) {
        if (self.version) |version| {
            zig_args.append("--version") catch unreachable;
            zig_args.append(builder.fmt("{}", .{version})) catch unreachable;
        }

        if (self.target.isDarwin()) {
            const install_name = self.install_name orelse builder.fmt("@rpath/{s}{s}{s}", .{
                self.target.libPrefix(),
                self.name,
                self.target.dynamicLibSuffix(),
            });
            try zig_args.append("-install_name");
            try zig_args.append(install_name);
        }
    }

    if (self.entitlements) |entitlements| {
        try zig_args.appendSlice(&[_][]const u8{ "--entitlements", entitlements });
    }
    if (self.pagezero_size) |pagezero_size| {
        const size = try std.fmt.allocPrint(builder.allocator, "{x}", .{pagezero_size});
        try zig_args.appendSlice(&[_][]const u8{ "-pagezero_size", size });
    }
    if (self.search_strategy) |strat| switch (strat) {
        .paths_first => try zig_args.append("-search_paths_first"),
        .dylibs_first => try zig_args.append("-search_dylibs_first"),
    };
    if (self.headerpad_size) |headerpad_size| {
        const size = try std.fmt.allocPrint(builder.allocator, "{x}", .{headerpad_size});
        try zig_args.appendSlice(&[_][]const u8{ "-headerpad", size });
    }
    if (self.headerpad_max_install_names) {
        try zig_args.append("-headerpad_max_install_names");
    }
    if (self.dead_strip_dylibs) {
        try zig_args.append("-dead_strip_dylibs");
    }

    if (self.bundle_compiler_rt) |x| {
        if (x) {
            try zig_args.append("-fcompiler-rt");
        } else {
            try zig_args.append("-fno-compiler-rt");
        }
    }
    if (self.single_threaded) |single_threaded| {
        if (single_threaded) {
            try zig_args.append("-fsingle-threaded");
        } else {
            try zig_args.append("-fno-single-threaded");
        }
    }
    if (self.disable_stack_probing) {
        try zig_args.append("-fno-stack-check");
    }
    if (self.stack_protector) |stack_protector| {
        if (stack_protector) {
            try zig_args.append("-fstack-protector");
        } else {
            try zig_args.append("-fno-stack-protector");
        }
    }
    if (self.red_zone) |red_zone| {
        if (red_zone) {
            try zig_args.append("-mred-zone");
        } else {
            try zig_args.append("-mno-red-zone");
        }
    }
    if (self.omit_frame_pointer) |omit_frame_pointer| {
        if (omit_frame_pointer) {
            try zig_args.append("-fomit-frame-pointer");
        } else {
            try zig_args.append("-fno-omit-frame-pointer");
        }
    }
    if (self.dll_export_fns) |dll_export_fns| {
        if (dll_export_fns) {
            try zig_args.append("-fdll-export-fns");
        } else {
            try zig_args.append("-fno-dll-export-fns");
        }
    }
    if (self.disable_sanitize_c) {
        try zig_args.append("-fno-sanitize-c");
    }
    if (self.sanitize_thread) {
        try zig_args.append("-fsanitize-thread");
    }
    if (self.rdynamic) {
        try zig_args.append("-rdynamic");
    }
    if (self.import_memory) {
        try zig_args.append("--import-memory");
    }
    if (self.import_table) {
        try zig_args.append("--import-table");
    }
    if (self.export_table) {
        try zig_args.append("--export-table");
    }
    if (self.initial_memory) |initial_memory| {
        try zig_args.append(builder.fmt("--initial-memory={d}", .{initial_memory}));
    }
    if (self.max_memory) |max_memory| {
        try zig_args.append(builder.fmt("--max-memory={d}", .{max_memory}));
    }
    if (self.shared_memory) {
        try zig_args.append("--shared-memory");
    }
    if (self.global_base) |global_base| {
        try zig_args.append(builder.fmt("--global-base={d}", .{global_base}));
    }

    if (self.code_model != .default) {
        try zig_args.append("-mcmodel");
        try zig_args.append(@tagName(self.code_model));
    }
    if (self.wasi_exec_model) |model| {
        try zig_args.append(builder.fmt("-mexec-model={s}", .{@tagName(model)}));
    }
    for (self.export_symbol_names) |symbol_name| {
        try zig_args.append(builder.fmt("--export={s}", .{symbol_name}));
    }

    if (!self.target.isNative()) {
        try zig_args.append("-target");
        try zig_args.append(try self.target.zigTriple(builder.allocator));

        // TODO this logic can disappear if cpu model + features becomes part of the target triple
        const cross = self.target.toTarget();
        const all_features = cross.cpu.arch.allFeaturesList();
        var populated_cpu_features = cross.cpu.model.features;
        populated_cpu_features.populateDependencies(all_features);

        if (populated_cpu_features.eql(cross.cpu.features)) {
            // The CPU name alone is sufficient.
            try zig_args.append("-mcpu");
            try zig_args.append(cross.cpu.model.name);
        } else {
            var mcpu_buffer = std.ArrayList(u8).init(builder.allocator);

            try mcpu_buffer.writer().print("-mcpu={s}", .{cross.cpu.model.name});

            for (all_features) |feature, i_usize| {
                const i = @intCast(std.Target.Cpu.Feature.Set.Index, i_usize);
                const in_cpu_set = populated_cpu_features.isEnabled(i);
                const in_actual_set = cross.cpu.features.isEnabled(i);
                if (in_cpu_set and !in_actual_set) {
                    try mcpu_buffer.writer().print("-{s}", .{feature.name});
                } else if (!in_cpu_set and in_actual_set) {
                    try mcpu_buffer.writer().print("+{s}", .{feature.name});
                }
            }

            try zig_args.append(try mcpu_buffer.toOwnedSlice());
        }

        if (self.target.dynamic_linker.get()) |dynamic_linker| {
            try zig_args.append("--dynamic-linker");
            try zig_args.append(dynamic_linker);
        }
    }

    if (self.linker_script) |linker_script| {
        try zig_args.append("--script");
        try zig_args.append(linker_script.getPath(builder));
    }

    if (self.version_script) |version_script| {
        try zig_args.append("--version-script");
        try zig_args.append(builder.pathFromRoot(version_script));
    }

    if (self.kind == .@"test") {
        if (self.exec_cmd_args) |exec_cmd_args| {
            for (exec_cmd_args) |cmd_arg| {
                if (cmd_arg) |arg| {
                    try zig_args.append("--test-cmd");
                    try zig_args.append(arg);
                } else {
                    try zig_args.append("--test-cmd-bin");
                }
            }
        } else {
            const need_cross_glibc = self.target.isGnuLibC() and self.is_linking_libc;

            switch (self.builder.host.getExternalExecutor(self.target_info, .{
                .qemu_fixes_dl = need_cross_glibc and builder.glibc_runtimes_dir != null,
                .link_libc = self.is_linking_libc,
            })) {
                .native => {},
                .bad_dl, .bad_os_or_cpu => {
                    try zig_args.append("--test-no-exec");
                },
                .rosetta => if (builder.enable_rosetta) {
                    try zig_args.append("--test-cmd-bin");
                } else {
                    try zig_args.append("--test-no-exec");
                },
                .qemu => |bin_name| ok: {
                    if (builder.enable_qemu) qemu: {
                        const glibc_dir_arg = if (need_cross_glibc)
                            builder.glibc_runtimes_dir orelse break :qemu
                        else
                            null;
                        try zig_args.append("--test-cmd");
                        try zig_args.append(bin_name);
                        if (glibc_dir_arg) |dir| {
                            // TODO look into making this a call to `linuxTriple`. This
                            // needs the directory to be called "i686" rather than
                            // "x86" which is why we do it manually here.
                            const fmt_str = "{s}" ++ fs.path.sep_str ++ "{s}-{s}-{s}";
                            const cpu_arch = self.target.getCpuArch();
                            const os_tag = self.target.getOsTag();
                            const abi = self.target.getAbi();
                            const cpu_arch_name: []const u8 = if (cpu_arch == .x86)
                                "i686"
                            else
                                @tagName(cpu_arch);
                            const full_dir = try std.fmt.allocPrint(builder.allocator, fmt_str, .{
                                dir, cpu_arch_name, @tagName(os_tag), @tagName(abi),
                            });

                            try zig_args.append("--test-cmd");
                            try zig_args.append("-L");
                            try zig_args.append("--test-cmd");
                            try zig_args.append(full_dir);
                        }
                        try zig_args.append("--test-cmd-bin");
                        break :ok;
                    }
                    try zig_args.append("--test-no-exec");
                },
                .wine => |bin_name| if (builder.enable_wine) {
                    try zig_args.append("--test-cmd");
                    try zig_args.append(bin_name);
                    try zig_args.append("--test-cmd-bin");
                } else {
                    try zig_args.append("--test-no-exec");
                },
                .wasmtime => |bin_name| if (builder.enable_wasmtime) {
                    try zig_args.append("--test-cmd");
                    try zig_args.append(bin_name);
                    try zig_args.append("--test-cmd");
                    try zig_args.append("--dir=.");
                    try zig_args.append("--test-cmd");
                    try zig_args.append("--allow-unknown-exports"); // TODO: Remove when stage2 is default compiler
                    try zig_args.append("--test-cmd-bin");
                } else {
                    try zig_args.append("--test-no-exec");
                },
                .darling => |bin_name| if (builder.enable_darling) {
                    try zig_args.append("--test-cmd");
                    try zig_args.append(bin_name);
                    try zig_args.append("--test-cmd-bin");
                } else {
                    try zig_args.append("--test-no-exec");
                },
            }
        }
    } else if (self.kind == .test_exe) {
        try zig_args.append("--test-no-exec");
    }

    for (self.packages.items) |pkg| {
        try makePackageCmd(self, pkg, &zig_args);
    }

    for (self.include_dirs.items) |include_dir| {
        switch (include_dir) {
            .raw_path => |include_path| {
                try zig_args.append("-I");
                try zig_args.append(self.builder.pathFromRoot(include_path));
            },
            .raw_path_system => |include_path| {
                if (builder.sysroot != null) {
                    try zig_args.append("-iwithsysroot");
                } else {
                    try zig_args.append("-isystem");
                }

                const resolved_include_path = self.builder.pathFromRoot(include_path);

                const common_include_path = if (builtin.os.tag == .windows and builder.sysroot != null and fs.path.isAbsolute(resolved_include_path)) blk: {
                    // We need to check for disk designator and strip it out from dir path so
                    // that zig/clang can concat resolved_include_path with sysroot.
                    const disk_designator = fs.path.diskDesignatorWindows(resolved_include_path);

                    if (mem.indexOf(u8, resolved_include_path, disk_designator)) |where| {
                        break :blk resolved_include_path[where + disk_designator.len ..];
                    }

                    break :blk resolved_include_path;
                } else resolved_include_path;

                try zig_args.append(common_include_path);
            },
            .other_step => |other| if (other.emit_h) {
                const h_path = other.getOutputHSource().getPath(self.builder);
                try zig_args.append("-isystem");
                try zig_args.append(fs.path.dirname(h_path).?);
            },
        }
    }

    for (self.lib_paths.items) |lib_path| {
        try zig_args.append("-L");
        try zig_args.append(lib_path);
    }

    for (self.rpaths.items) |rpath| {
        try zig_args.append("-rpath");
        try zig_args.append(rpath);
    }

    for (self.c_macros.items) |c_macro| {
        try zig_args.append("-D");
        try zig_args.append(c_macro);
    }

    if (self.target.isDarwin()) {
        for (self.framework_dirs.items) |dir| {
            if (builder.sysroot != null) {
                try zig_args.append("-iframeworkwithsysroot");
            } else {
                try zig_args.append("-iframework");
            }
            try zig_args.append(dir);
            try zig_args.append("-F");
            try zig_args.append(dir);
        }

        var it = self.frameworks.iterator();
        while (it.next()) |entry| {
            const name = entry.key_ptr.*;
            const info = entry.value_ptr.*;
            if (info.needed) {
                zig_args.append("-needed_framework") catch unreachable;
            } else if (info.weak) {
                zig_args.append("-weak_framework") catch unreachable;
            } else {
                zig_args.append("-framework") catch unreachable;
            }
            zig_args.append(name) catch unreachable;
        }
    } else {
        if (self.framework_dirs.items.len > 0) {
            std.log.info("Framework directories have been added for a non-darwin target, this will have no affect on the build", .{});
        }

        if (self.frameworks.count() > 0) {
            std.log.info("Frameworks have been added for a non-darwin target, this will have no affect on the build", .{});
        }
    }

    if (builder.sysroot) |sysroot| {
        try zig_args.appendSlice(&[_][]const u8{ "--sysroot", sysroot });
    }

    for (builder.search_prefixes.items) |search_prefix| {
        try zig_args.append("-L");
        try zig_args.append(builder.pathJoin(&.{
            search_prefix, "lib",
        }));
        try zig_args.append("-I");
        try zig_args.append(builder.pathJoin(&.{
            search_prefix, "include",
        }));
    }

    if (self.valgrind_support) |valgrind_support| {
        if (valgrind_support) {
            try zig_args.append("-fvalgrind");
        } else {
            try zig_args.append("-fno-valgrind");
        }
    }

    if (self.each_lib_rpath) |each_lib_rpath| {
        if (each_lib_rpath) {
            try zig_args.append("-feach-lib-rpath");
        } else {
            try zig_args.append("-fno-each-lib-rpath");
        }
    }

    if (self.build_id) |build_id| {
        if (build_id) {
            try zig_args.append("-fbuild-id");
        } else {
            try zig_args.append("-fno-build-id");
        }
    }

    if (self.override_lib_dir) |dir| {
        try zig_args.append("--zig-lib-dir");
        try zig_args.append(builder.pathFromRoot(dir));
    } else if (self.builder.override_lib_dir) |dir| {
        try zig_args.append("--zig-lib-dir");
        try zig_args.append(builder.pathFromRoot(dir));
    }

    if (self.main_pkg_path) |dir| {
        try zig_args.append("--main-pkg-path");
        try zig_args.append(builder.pathFromRoot(dir));
    }

    if (self.force_pic) |pic| {
        if (pic) {
            try zig_args.append("-fPIC");
        } else {
            try zig_args.append("-fno-PIC");
        }
    }

    if (self.pie) |pie| {
        if (pie) {
            try zig_args.append("-fPIE");
        } else {
            try zig_args.append("-fno-PIE");
        }
    }

    if (self.want_lto) |lto| {
        if (lto) {
            try zig_args.append("-flto");
        } else {
            try zig_args.append("-fno-lto");
        }
    }

    if (self.subsystem) |subsystem| {
        try zig_args.append("--subsystem");
        try zig_args.append(switch (subsystem) {
            .Console => "console",
            .Windows => "windows",
            .Posix => "posix",
            .Native => "native",
            .EfiApplication => "efi_application",
            .EfiBootServiceDriver => "efi_boot_service_driver",
            .EfiRom => "efi_rom",
            .EfiRuntimeDriver => "efi_runtime_driver",
        });
    }

    try zig_args.append("--enable-cache");

    // Windows has an argument length limit of 32,766 characters, macOS 262,144 and Linux
    // 2,097,152. If our args exceed 30 KiB, we instead write them to a "response file" and
    // pass that to zig, e.g. via 'zig build-lib @args.rsp'
    // See @file syntax here: https://gcc.gnu.org/onlinedocs/gcc/Overall-Options.html
    var args_length: usize = 0;
    for (zig_args.items) |arg| {
        args_length += arg.len + 1; // +1 to account for null terminator
    }
    if (args_length >= 30 * 1024) {
        const args_dir = try fs.path.join(
            builder.allocator,
            &[_][]const u8{ builder.pathFromRoot("zig-cache"), "args" },
        );
        try std.fs.cwd().makePath(args_dir);

        var args_arena = std.heap.ArenaAllocator.init(builder.allocator);
        defer args_arena.deinit();

        const args_to_escape = zig_args.items[2..];
        var escaped_args = try std.ArrayList([]const u8).initCapacity(args_arena.allocator(), args_to_escape.len);

        arg_blk: for (args_to_escape) |arg| {
            for (arg) |c, arg_idx| {
                if (c == '\\' or c == '"') {
                    // Slow path for arguments that need to be escaped. We'll need to allocate and copy
                    var escaped = try std.ArrayList(u8).initCapacity(args_arena.allocator(), arg.len + 1);
                    const writer = escaped.writer();
                    writer.writeAll(arg[0..arg_idx]) catch unreachable;
                    for (arg[arg_idx..]) |to_escape| {
                        if (to_escape == '\\' or to_escape == '"') try writer.writeByte('\\');
                        try writer.writeByte(to_escape);
                    }
                    escaped_args.appendAssumeCapacity(escaped.items);
                    continue :arg_blk;
                }
            }
            escaped_args.appendAssumeCapacity(arg); // no escaping needed so just use original argument
        }

        // Write the args to zig-cache/args/<SHA256 hash of args> to avoid conflicts with
        // other zig build commands running in parallel.
        const partially_quoted = try std.mem.join(builder.allocator, "\" \"", escaped_args.items);
        const args = try std.mem.concat(builder.allocator, u8, &[_][]const u8{ "\"", partially_quoted, "\"" });

        var args_hash: [std.crypto.hash.sha2.Sha256.digest_length]u8 = undefined;
        std.crypto.hash.sha2.Sha256.hash(args, &args_hash, .{});
        var args_hex_hash: [std.crypto.hash.sha2.Sha256.digest_length * 2]u8 = undefined;
        _ = try std.fmt.bufPrint(
            &args_hex_hash,
            "{s}",
            .{std.fmt.fmtSliceHexLower(&args_hash)},
        );

        const args_file = try fs.path.join(builder.allocator, &[_][]const u8{ args_dir, args_hex_hash[0..] });
        try std.fs.cwd().writeFile(args_file, args);

        zig_args.shrinkRetainingCapacity(2);
        try zig_args.append(try std.mem.concat(builder.allocator, u8, &[_][]const u8{ "@", args_file }));
    }

    return zig_args.toOwnedSlice();
}

fn makePackageCmd(self: *build.LibExeObjStep, pkg: build.Pkg, zig_args: *std.ArrayList([]const u8)) error{OutOfMemory}!void {
    try zig_args.append("--pkg-begin");
    try zig_args.append(pkg.name);
    try zig_args.append(self.builder.pathFromRoot(pkg.source.getPath(self.builder)));

    if (pkg.dependencies) |dependencies| {
        for (dependencies) |sub_pkg| {
            try makePackageCmd(self, sub_pkg, zig_args);
        }
    }

    try zig_args.append("--pkg-end");
}
