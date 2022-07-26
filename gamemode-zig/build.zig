const std = @import("std");

pub const pkg = std.build.Pkg{
    .name = "gamemode",
    .source = .{ .path = thisDir() ++ "/src/gamemode.zig" },
};

/// Link system library gamemode
pub fn link(exe: *std.build.LibExeObjStep) void {
    exe.linkSystemLibrary("gamemode");
}

/// TODO:
/// Build and link gamemode
pub fn buildAndLink(b: *std.build.Builder, exe: *std.build.LibExeObjStep) void {
    const lib = b.addSharedLibrarySource("gamemode", std.build.FileSource{ .path = thisDir() ++ "/c/client_impl.c" }, .unversioned);
    lib.linkLibC();
    exe.linkLibrary(lib);
}

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}
