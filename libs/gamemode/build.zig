const std = @import("std");

pub const pkg = std.build.Pkg{
    .name = "gamemode",
    .source = .{ .path = thisDir() ++ "/gamemode.zig" },
};

pub fn link(step: *std.build.LibExeObjStep) void {
    step.addIncludeDir(comptime thisDir() ++ "/upstream/include");
}

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}
