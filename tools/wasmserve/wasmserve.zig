const std = @import("std");
const builtin = @import("builtin");
const mime = @import("mime.zig");
const net = std.net;
const mem = std.mem;
const fs = std.fs;
const build = std.build;

const www_dir_path = sdkPath("/www");
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

pub fn serve(step: *build.CompileStep, options: Options) Error!*Wasmserve {
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
    exe_step: *build.CompileStep,
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

        var www_dir = try fs.cwd().openIterableDir(www_dir_path, .{});
        defer www_dir.close();
        var www_dir_iter = www_dir.iterate();
        while (try www_dir_iter.next()) |file| {
            const path = try fs.path.join(self.b.allocator, &.{ www_dir_path, file.name });
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

fn sdkPath(comptime suffix: []const u8) []const u8 {
    if (suffix[0] != '/') @compileError("suffix must be an absolute path");
    return comptime blk: {
        const root_dir = std.fs.path.dirname(@src().file) orelse ".";
        break :blk root_dir ++ suffix;
    };
}

// copied from CompileStep.make()
// TODO: this is very tricky
// TODO(wasmserve): wasmserve is broken after recent Zig build changes, need to expose
// this from Zig stdlib or something instead of copying this huge function out of stdlib
// like this (nasty!)
fn getExecArgs(_: *build.CompileStep) ![]const []const u8 {
    @panic("wasmserve is currently not working");
}

fn makePackageCmd(self: *std.build.CompileStep, pkg: std.build.Pkg, zig_args: *std.ArrayList([]const u8)) error{OutOfMemory}!void {
    const builder = self.builder;

    try zig_args.append("--pkg-begin");
    try zig_args.append(pkg.name);
    try zig_args.append(builder.pathFromRoot(pkg.source.getPath(self.builder)));

    if (pkg.dependencies) |dependencies| {
        for (dependencies) |sub_pkg| {
            try makePackageCmd(self, sub_pkg, zig_args);
        }
    }

    try zig_args.append("--pkg-end");
}
