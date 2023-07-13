//! The 'mach' CLI and engine editor

// Check that the user's app matches the required interface.
comptime {
    if (!@import("builtin").is_test) @import("core").AppInterface(@import("app"));
}

const std = @import("std");
const builtin = @import("builtin");

const App = @import("app").App;
const core = @import("core");
const gpu = core.gpu;

const Builder = @import("Builder.zig");
const Target = @import("target.zig").Target;

pub const GPUInterface = gpu.dawn.Interface;

const default_zig_path = "zig";

var args: []const [:0]u8 = undefined;
var arg_i: usize = 1;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const allocator = gpa.allocator();

pub fn main() !void {
    defer _ = gpa.deinit();

    args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len == 1) {
        gpu.Impl.init();
        _ = gpu.Export(GPUInterface);

        var app: App = undefined;
        try app.init();
        defer app.deinit();

        while (true) {
            if (try app.update()) return;
        }
    }

    if (std.mem.eql(u8, args[arg_i], "build")) {
        arg_i += 1;
        var builder = Builder{};
        var steps = std.ArrayList([]const u8).init(allocator);
        var build_args = std.ArrayList([]const u8).init(allocator);

        if (std.mem.eql(u8, args[arg_i], "help") or std.mem.eql(u8, args[arg_i], "--help") or std.mem.eql(u8, args[arg_i], "-h")) {
            try printHelp(.build);
            std.os.exit(1);
        }

        while (arg_i < args.len) : (arg_i += 1) {
            if (argOption("-zig-path")) |value| {
                builder.zig_path = value;
            } else if (std.mem.eql(u8, args[arg_i], "--serve")) {
                if (builder.target == null) builder.target = .wasm32;
                if (builder.target.? != .wasm32) {
                    std.log.err("--serve requires -target=wasm32", .{});
                    try printHelp(.build);
                    std.os.exit(1);
                }
                builder.serve = true;
            } else if (argOption("-target")) |value| {
                builder.target = Target.parse(value) orelse {
                    std.log.err("invalid target '{s}'", .{args[arg_i]});
                    try printHelp(.build);
                    std.os.exit(1);
                };
            } else if (argOption("-listen-port")) |value| {
                builder.listen_port = std.fmt.parseInt(u16, value, 10) catch {
                    std.log.err("invalid port '{s}'", .{args[arg_i]});
                    try printHelp(.build);
                    std.os.exit(1);
                };
            } else if (argOption("-watch-path")) |value| {
                var paths = std.mem.splitScalar(u8, value, ',');
                builder.watch_paths = try allocator.alloc([]const u8, std.mem.count(u8, value, ",") + 1);
                for (0..255) |i| {
                    const path = paths.next() orelse break;
                    builder.watch_paths.?[i] = std.mem.trim(u8, path, &std.ascii.whitespace);
                }
            } else if (argOption("-optimize")) |value| {
                builder.optimize = std.meta.stringToEnum(std.builtin.OptimizeMode, value) orelse {
                    std.log.err("invalid optimize mode '{s}'", .{args[arg_i]});
                    try printHelp(.build);
                    std.os.exit(1);
                };
            } else if (std.mem.eql(u8, args[arg_i], "--")) {
                arg_i += 1;
                while (arg_i < args.len) : (arg_i += 1) {
                    try build_args.append(args[arg_i]);
                }
            } else {
                try steps.append(args[arg_i]);
            }
        }

        builder.steps = try steps.toOwnedSlice();
        builder.zig_build_args = try build_args.toOwnedSlice();

        return builder.run();
    } else if (std.mem.eql(u8, args[arg_i], "help") or std.mem.eql(u8, args[arg_i], "--help") or std.mem.eql(u8, args[arg_i], "-h")) {
        arg_i += 1;
        var subcommand = SubCommand.help;

        if (arg_i < args.len) {
            if (std.mem.eql(u8, args[arg_i], "build")) {
                subcommand = .build;
            } else {
                std.log.err("unknown command name '{s}'", .{args[arg_i]});
                try printHelp(.help);
                std.os.exit(1);
            }
        }
        return printHelp(subcommand);
    } else {
        std.log.err("invalid command '{s}'", .{args[arg_i]});
        try printHelp(.help);
        std.os.exit(1);
    }
}

pub const SubCommand = enum {
    build,
    help,
};

fn printHelp(subcommand: SubCommand) !void {
    const stdout = std.io.getStdOut();
    switch (subcommand) {
        .build => {
            try stdout.writeAll(
                \\Usage: 
                \\    mach build [steps] [options] [-- [zig-build-options]]
                \\
                \\General Options:
                \\
                \\  -zig-path [path]      Override path to zig binary
                \\
                \\  -target [target]      The CPU architecture and OS to build for
                \\                        Default is native target
                \\                        Supported targets:
                \\                          linux-x86_64,   linux-aarch64,
                \\                          macos-x86_64,   macos-aarch64,
                \\                          windows-x86_64, windows-aarch64,
                \\                          wasm32,
                \\
                \\  -optimize [optimize]  Prioritize performance, safety, or binary size
                \\                        Default is Debug
                \\                        Supported values:
                \\                          Debug
                \\                          ReleaseSafe
                \\                          ReleaseFast
                \\                          ReleaseSmall
                \\
                \\Serve Options:
                \\
                \\  --serve               Starts a development server
                \\                        for testing WASM applications/games
                \\
                \\  -listen-port [port]   The development server port
                \\
                \\  -watch-path [paths]   Watches for changes in specified directory
                \\                        and automatically builds and reloads
                \\                        development server
                \\                        Separate each path with comma (,)
                \\
                \\
            );
        },
        .help => {
            try stdout.writeAll(
                \\Usage: 
                \\  mach [command]
                \\
                \\Commands:
                \\  build  Build current project
                \\  help   Print this mesage or the help of the given command
                \\
                \\
            );
        },
    }
}

pub fn argOption(name: []const u8) ?[]const u8 {
    const cmd_arg = args[arg_i];
    if (std.mem.startsWith(u8, cmd_arg, name)) {
        if (cmd_arg.len > name.len + 1 and cmd_arg[name.len] == '=') {
            return cmd_arg[name.len + 1 ..];
        } else if (cmd_arg.len == name.len) {
            arg_i += 1;
            if (arg_i < args.len) {
                return args[arg_i];
            } else {
                std.log.err("expected value after '{s}' option", .{cmd_arg});
                std.os.exit(1);
            }
        }
    }
    return null;
}
