const std = @import("std");
const mime = @import("mime.zig");
const net = std.net;
const mem = std.mem;
const fs = std.fs;
const build = std.build;

const www_dir_path = thisDir() ++ "/www";
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
    install_step_name: []const u8 = "install",
    install_dir: ?build.InstallDir = null,
    watch_paths: []const []const u8 = &.{},
    listen_address: net.Address = net.Address.initIp4([4]u8{ 127, 0, 0, 1 }, 8080),
};

pub fn serve(step: *build.LibExeObjStep, options: Options) !*Wasmserve {
    const self = step.builder.allocator.create(Wasmserve) catch unreachable;
    const install_dir = options.install_dir orelse build.InstallDir{ .lib = {} };
    self.* = Wasmserve{
        .step = build.Step.init(.run, "wasmserve", step.builder.allocator, Wasmserve.make),
        .b = step.builder,
        .exe_step = step,
        .install_step_name = options.install_step_name,
        .install_dir = install_dir,
        .install_dir_iter = try fs.cwd().makeOpenPathIterable(step.builder.getInstallPath(install_dir, ""), .{}),
        .address = options.listen_address,
        .subscriber = null,
        .watch_paths = options.watch_paths,
        .mtimes = std.AutoHashMap(fs.File.INode, i128).init(step.builder.allocator),
        .status = .idle,
        .notify_msg = try step.builder.allocator.alloc(u8, 0),
    };
    return self;
}

const Wasmserve = struct {
    step: build.Step,
    b: *build.Builder,
    exe_step: *build.LibExeObjStep,
    install_step_name: []const u8,
    install_dir: build.InstallDir,
    install_dir_iter: fs.IterableDir,
    address: net.Address,
    subscriber: ?*net.StreamServer.Connection,
    watch_paths: []const []const u8,
    mtimes: std.AutoHashMap(fs.File.INode, i128),
    status: Status,
    notify_msg: []u8,

    const Status = enum {
        idle,
        built,
        build_error,
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

        const zero_iovec = &[0]std.os.iovec_const{};
        var send_total: usize = 0;
        while (true) {
            const send_len = try std.os.sendfile(
                stream.handle,
                file.handle,
                send_total,
                file_size,
                zero_iovec,
                zero_iovec,
                0,
            );
            if (send_len == 0)
                break;
            send_total += send_len;
        }
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
        timer_loop: while (true) : (std.time.sleep(100 * std.time.ns_per_ms)) {
            for (self.watch_paths) |path| {
                var dir = fs.cwd().openIterableDir(path, .{}) catch {
                    if (self.checkForUpdate(path)) |is_updated| {
                        if (is_updated)
                            continue :timer_loop;
                    } else |err| logErr(err, @src());
                    continue;
                };
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
                    if (self.checkForUpdate(walk_entry.path)) |is_updated| {
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

    fn checkForUpdate(self: *Wasmserve, path: []const u8) !bool {
        const stat = try fs.cwd().statFile(path);
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
            s.stream.writer().print("event: {s}\n", .{@tagName(self.status)}) catch |err| logErr(err, @src());
            var lines = std.mem.split(u8, self.notify_msg, "\n");
            while (lines.next()) |line|
                s.stream.writer().print("data: {s}\n", .{line}) catch |err| logErr(err, @src());
            _ = s.stream.write("\n") catch |err| logErr(err, @src());
            if (self.status == .built) self.status = .idle;
        }
    }

    fn compile(self: *Wasmserve) void {
        std.log.info("Compiling...", .{});
        const res = std.ChildProcess.exec(.{
            .allocator = self.b.allocator,
            .argv = &.{ self.b.zig_exe, "build", self.install_step_name, "--prominent-compile-errors", "--color", "on" },
        }) catch |err| {
            logErr(err, @src());
            return;
        };
        self.b.allocator.free(res.stdout);
        self.b.allocator.free(self.notify_msg);
        std.debug.print("{s}", .{res.stderr});
        self.notify_msg = res.stderr;
        switch (res.term) {
            .Exited => |code| {
                self.status = if (code == 0) .built else .build_error;
            },
            // TODO: separate status and message
            else => {},
        }
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

fn thisDir() []const u8 {
    return fs.path.dirname(@src().file) orelse ".";
}
