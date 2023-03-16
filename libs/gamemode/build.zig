const std = @import("std");

var _module: ?*std.build.Module = null;

pub fn module(b: *std.Build) *std.build.Module {
    if (_module) |m| return m;
    _module = b.createModule(.{
        .source_file = .{ .path = sdkPath("/src/main.zig") },
    });
    return _module.?;
}

pub fn link(step: *std.build.CompileStep) void {
    step.addIncludePath(sdkPath("/upstream/include"));
}

fn sdkPath(comptime suffix: []const u8) []const u8 {
    if (suffix[0] != '/') @compileError("suffix must be an absolute path");
    return comptime blk: {
        const root_dir = std.fs.path.dirname(@src().file) orelse ".";
        break :blk root_dir ++ suffix;
    };
}
