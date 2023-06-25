const std = @import("std");
const mime_map = @import("Builder/mime.zig").mime_map;
const Target = @import("target.zig").Target;
const OptimizeMode = std.builtin.OptimizeMode;
const allocator = @import("root").allocator;

const Builder = @This();

const out_dir_path = "zig-out/www";
const @"www/index.html" = @embedFile("Builder/www/index.html");
const @"www/ansi_to_html.js" = @embedFile("Builder/www/ansi_to_html.js");
const @"www/wasmserve.js" = @embedFile("Builder/www/wasmserve.js");
const @"www/favicon.ico" = @embedFile("Builder/www/favicon.ico");

steps: []const []const u8 = &.{},
serve: bool = false,
target: ?Target = null,
optimize: OptimizeMode = .Debug,
zig_path: []const u8 = "zig",
zig_build_args: []const []const u8 = &.{},

status: Status = .building,
listen_port: u16 = 1717,
subscribers: std.ArrayListUnmanaged(std.net.Stream) = .{},
watch_paths: ?[][]const u8 = null,
mtimes: std.AutoHashMapUnmanaged(std.fs.File.INode, i128) = .{},
@"formated-www/index.html": []const u8 = undefined,

const Status = union(enum) {
    building,
    built,
    stopped,
    compile_error: []const u8,
};

pub fn run(self: *Builder) !void {
    var child = try self.runZigBuild(.Inherit);
    switch (try child.wait()) {
        .Exited => |code| {
            if (code != 0) std.os.exit(code);
        },
        else => std.os.exit(1),
    }

    if (self.serve) {
        var out_dir = std.fs.cwd().openIterableDir(out_dir_path, .{}) catch |err| {
            std.log.err("cannot open '{s}': {s}", .{ out_dir_path, @errorName(err) });
            std.os.exit(1);
        };
        defer out_dir.close();

        var wasm_file_name: ?[]const u8 = null;
        var out_dir_iter = out_dir.iterate();
        while (try out_dir_iter.next()) |entry| {
            if (entry.kind != .file) continue;
            if (std.mem.eql(u8, std.fs.path.extension(entry.name), ".wasm")) {
                wasm_file_name = try allocator.dupe(u8, entry.name);
            }
        }
        if (wasm_file_name == null) {
            std.log.err("no WASM binary found at '{s}'", .{out_dir_path});
            std.os.exit(1);
        }

        self.@"formated-www/index.html" = try std.fmt.allocPrint(
            allocator,
            @"www/index.html",
            .{
                .app_name = std.fs.path.stem(wasm_file_name.?),
                .wasm_path = wasm_file_name.?,
            },
        );

        const watch_thread = if (self.watch_paths) |_|
            try std.Thread.spawn(.{}, watch, .{self})
        else
            null;
        defer if (watch_thread) |wt| wt.detach();

        var server = std.net.StreamServer.init(.{ .reuse_address = true });
        defer server.deinit();
        try server.listen(std.net.Address.initIp4(.{ 127, 0, 0, 1 }, self.listen_port));
        std.log.info("started listening at http://127.0.0.1:{d}...", .{self.listen_port});

        var pool = try allocator.create(std.Thread.Pool);
        try pool.init(.{ .allocator = allocator });
        defer pool.deinit();

        while (true) {
            const conn = try server.accept();
            try pool.spawn(handleConn, .{ self, conn });
        }
    }
}

fn runZigBuild(self: Builder, stderr_behavior: std.process.Child.StdIo) !std.process.Child {
    var args_arena = std.heap.ArenaAllocator.init(allocator);
    defer args_arena.deinit();

    const args = try self.buildArgs(args_arena.allocator());

    var child = std.process.Child.init(args, allocator);
    child.stderr_behavior = stderr_behavior;

    try child.spawn();

    return child;
}

fn buildArgs(self: Builder, arena: std.mem.Allocator) ![]const []const u8 {
    var argv = std.ArrayList([]const u8).init(arena);
    try argv.ensureTotalCapacity(self.steps.len + self.zig_build_args.len + 6);

    argv.appendAssumeCapacity(try arena.dupe(u8, self.zig_path));
    argv.appendAssumeCapacity("build");

    for (self.steps) |step| {
        argv.appendAssumeCapacity(try arena.dupe(u8, step));
    }

    argv.appendAssumeCapacity("--color");
    argv.appendAssumeCapacity("on");
    argv.appendAssumeCapacity(try std.fmt.allocPrint(arena, "-Doptimize={s}", .{@tagName(self.optimize)}));
    if (self.target) |target| {
        argv.appendAssumeCapacity(try std.fmt.allocPrint(arena, "-Dtarget={s}", .{try target.toZigTriple()}));
    }

    for (self.zig_build_args) |arg| {
        argv.appendAssumeCapacity(try arena.dupe(u8, arg));
    }

    return try argv.toOwnedSlice();
}

fn watch(self: *Builder) void {
    _ = self;
    // TODO: use std.fs.Watch once async implemented
}

const path_handlers = std.ComptimeStringMap(*const fn (*Builder, std.net.Stream) void, .{
    .{ "/", struct {
        fn h(self: *Builder, stream: std.net.Stream) void {
            sendData(stream, .ok, .close, mime_map.get(".html").?, self.@"formated-www/index.html");
        }
    }.h },
    .{ "/notify", struct {
        fn h(builder: *Builder, stream: std.net.Stream) void {
            sendData(stream, .ok, .keep_alive, "text/event-stream", null);
            builder.subscribers.append(allocator, stream) catch {
                stream.close();
                return;
            };
            builder.notify(stream);
        }
    }.h },
    .{ "/wasmserve.js", struct {
        fn h(_: *Builder, stream: std.net.Stream) void {
            sendData(stream, .ok, .close, mime_map.get(".js").?, @"www/wasmserve.js");
        }
    }.h },
    .{ "/ansi_to_html.js", struct {
        fn h(_: *Builder, stream: std.net.Stream) void {
            sendData(stream, .ok, .close, mime_map.get(".js").?, @"www/ansi_to_html.js");
        }
    }.h },
    .{ "/favicon.ico", struct {
        fn h(_: *Builder, stream: std.net.Stream) void {
            sendData(stream, .ok, .close, mime_map.get(".ico").?, @"www/favicon.ico");
        }
    }.h },
});

fn sendData(
    stream: std.net.Stream,
    status: std.http.Status,
    connection: std.http.Connection,
    content_type: []const u8,
    data: ?[]const u8,
) void {
    if (data) |d| {
        stream.writer().print(
            "HTTP/1.1 {d} {s}\r\n" ++
                "Connection: {s}\r\n" ++
                "Content-Length: {d}\r\n" ++
                "Content-Type: {s}\r\n" ++
                "\r\n{s}",
            .{
                @intFromEnum(status),
                status.phrase() orelse "N/A",
                switch (connection) {
                    .close => "close",
                    .keep_alive => "keep-alive",
                },
                d.len,
                content_type,
                d,
            },
        ) catch {
            stream.close();
            return;
        };
    } else {
        stream.writer().print(
            "HTTP/1.1 {d} {s}\r\n" ++
                "Connection: {s}\r\n" ++
                "Content-Type: {s}\r\n" ++
                "\r\n",
            .{
                @intFromEnum(status),
                status.phrase() orelse "N/A",
                switch (connection) {
                    .close => "close",
                    .keep_alive => "keep-alive",
                },
                content_type,
            },
        ) catch {
            stream.close();
            return;
        };
    }
}

fn handleConn(self: *Builder, conn: std.net.StreamServer.Connection) void {
    errdefer {
        sendError(conn.stream, .internal_server_error);
        conn.stream.close();
    }

    var buf: [2048]u8 = undefined;
    const first_line = conn.stream.reader().readUntilDelimiter(&buf, '\n') catch |err| {
        defer conn.stream.close();
        return switch (err) {
            error.StreamTooLong => sendError(conn.stream, .uri_too_long),
            else => sendError(conn.stream, .bad_request),
        };
    };
    var first_line_iter = std.mem.splitScalar(u8, first_line, ' ');
    _ = first_line_iter.next(); // skip method
    if (first_line_iter.next()) |uri_str| {
        const uri = std.Uri.parseWithoutScheme(uri_str) catch {
            defer conn.stream.close();
            return sendError(conn.stream, .bad_request);
        };

        const handler = path_handlers.get(uri.path) orelse {
            // no handlers found. search in files
            const rel_path = uri.path[1..];

            const ext = std.fs.path.extension(rel_path);
            const file_mime = mime_map.get(ext) orelse "text/plain";

            const out_dir = std.fs.cwd().openDir(out_dir_path, .{}) catch |err| {
                std.log.err("cannot open '{s}': {s}", .{ out_dir_path, @errorName(err) });
                std.os.exit(1);
            };

            const file = out_dir.openFile(rel_path, .{}) catch |err| {
                if (err == error.FileNotFound) {
                    sendError(conn.stream, .not_found);
                } else {
                    sendError(conn.stream, .internal_server_error);
                }
                return;
            };
            defer file.close();

            const file_size = file.getEndPos() catch {
                sendError(conn.stream, .internal_server_error);
                return;
            };

            conn.stream.writer().print(
                "HTTP/1.1 200 OK\r\n" ++
                    "Connection: close\r\n" ++
                    "Content-Length: {d}\r\n" ++
                    "Content-Type: {s}\r\n" ++
                    "\r\n",
                .{ file_size, file_mime },
            ) catch return;
            std.fs.File.writeFileAll(.{ .handle = conn.stream.handle }, file, .{}) catch return;

            return;
        };
        handler(self, conn.stream);
    } else {
        defer conn.stream.close();
        return sendError(conn.stream, .bad_request);
    }
}

fn sendError(stream: std.net.Stream, status: std.http.Status) void {
    sendData(stream, status, .close, mime_map.get(".txt").?, status.phrase() orelse "N/A");
}

fn notify(self: *Builder, stream: std.net.Stream) void {
    stream.writer().print("event: {s}\n", .{@tagName(self.status)}) catch {
        stream.close();
        return;
    };
    switch (self.status) {
        .compile_error => |msg| {
            var lines = std.mem.splitScalar(u8, msg, '\n');
            while (lines.next()) |line| {
                stream.writer().print("data: {s}\n", .{line}) catch {
                    stream.close();
                    return;
                };
            }
        },
        .built, .building, .stopped => {},
    }
    _ = stream.write("\n") catch {
        stream.close();
        return;
    };
}

fn compile(self: *Builder) void {
    std.log.info("building...", .{});

    var child = self.runZigBuild(.Pipe) catch unreachable;

    const stderr = child.stderr.?.reader().readAllAlloc(
        allocator,
        std.math.maxInt(usize),
    ) catch @panic("OOM");

    std.io.getStdErr().writeAll(stderr) catch unreachable;

    const term = child.wait() catch unreachable;
    if (term == .Exited and term.Exited == 0) {
        allocator.free(stderr);
        self.status = .built;
        std.log.info("built", .{});
    } else if (term == .Exited and term.Exited == 1) {
        std.log.warn("compile error", .{});
        self.status = .{ .compile_error = stderr };
    } else {
        allocator.free(stderr);
        self.status = .stopped;
        std.log.warn("the build process has stopped unexpectedly", .{});
    }

    for (self.subscribers.items) |sub| {
        self.notify(sub);
    }
}
