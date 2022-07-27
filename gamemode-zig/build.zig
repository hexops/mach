const std = @import("std");

pub const pkg = std.build.Pkg{
    .name = "gamemode",
    .source = .{ .path = thisDir() ++ "/src/gamemode.zig" },
};

/// Link system library gamemode
pub fn link(exe: *std.build.LibExeObjStep) void {
    exe.linkSystemLibrary("gamemode");
}

// TODO: to build we still need to generate a config file called build_common.h
// (see https://github.com/FeralInteractive/gamemode/blob/4dc99dff76218718763a6b07fc1900fa6d1dafd9/meson.build) line 151

/// Build and link gamemode
pub fn buildAndLink(b: *std.build.Builder, exe: *std.build.LibExeObjStep) void {
    const lib_common = b.addStaticLibrary("common", null);
    lib_common.addCSourceFiles(&.{ (comptime thisDir()) ++ "/c/common/common-helpers.c", (comptime thisDir()) ++ "/c/common/common-pidfds.c" }, &.{});
    lib_common.linkLibC();

    const lib_gamemode = b.addSharedLibrarySource("gamemode", null, .unversioned);
    lib_gamemode.addCSourceFile((comptime thisDir()) ++ "/c/client_impl.c", &.{});
    lib_gamemode.linkLibC();
    lib_gamemode.linkLibrary(lib_common);

    exe.linkLibrary(lib_gamemode);
}

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}
