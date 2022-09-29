const std = @import("std");

pub const pkg = std.build.Pkg{
    .name = "gamemode",
    .source = .{ .path = sdkPath("/gamemode.zig") },
};

pub fn link(step: *std.build.LibExeObjStep) void {
    step.addIncludePath(sdkPath("/upstream/include"));
}

fn sdkPath(comptime suffix: []const u8) []const u8 {
    if (suffix[0] != '/') @compileError("suffix must be an absolute path");
    return comptime blk: {
        const root_dir = std.fs.path.dirname(@src().file) orelse ".";
        break :blk root_dir ++ suffix;
    };
}
