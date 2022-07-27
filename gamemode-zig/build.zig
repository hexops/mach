const std = @import("std");
const LibExeObjStep = std.build.LibExeObjStep;

pub const pkg = std.build.Pkg{
    .name = "gamemode",
    .source = .{ .path = thisDir() ++ "/src/gamemode.zig" },
};

pub const Options = struct {
    libexecdir: []const u8 = "",
    sysconfdir: []const u8 = "",
    gamemode_version: []const u8 = "",

    // Seems to be the only option the c files for libgamemode use
    have_fn_pidfd_open: bool = true,
};

/// Link system library gamemode
pub fn linkFromSystem(exe: *LibExeObjStep) void {
    exe.linkSystemLibrary("gamemode");
}

/// Build and link gamemode
pub fn linkFromSource(b: *std.build.Builder, exe: *LibExeObjStep, opts: Options) void {
    var build_config = std.fs.createFileAbsolute((comptime thisDir()) ++ "/c/common/build-config.h", .{}) catch unreachable;
    defer build_config.close();
    const writer = build_config.writer();
    writer.print(
        \\#define LIBEXECDIR "{s}"
        \\#define SYSCONFDIR "{s}"
        \\#define GAMEMODE_VERSION "{s}"
        \\#define HAVE_FN_PIDFD_OPEN {}
    , .{ opts.libexecdir, opts.sysconfdir, opts.gamemode_version, @boolToInt(opts.have_fn_pidfd_open) }) catch unreachable;

    const lib_common = b.addStaticLibrary("common", null);
    lib_common.addCSourceFiles(&.{ (comptime thisDir()) ++ "/c/common/common-helpers.c", (comptime thisDir()) ++ "/c/common/common-pidfds.c" }, &.{});
    lib_common.addIncludePath((comptime thisDir()) ++ "/c/common/");
    lib_common.linkLibC();

    const lib_gamemode = b.addSharedLibrarySource("gamemode", null, .unversioned);
    lib_gamemode.addCSourceFile((comptime thisDir()) ++ "/c/client_impl.c", &.{});
    lib_gamemode.addIncludePath((comptime thisDir()) ++ "/c/common/");
    lib_gamemode.linkLibC();
    lib_gamemode.linkSystemLibrary("dbus-1");
    lib_gamemode.linkLibrary(lib_common);

    exe.linkLibrary(lib_gamemode);
}

//  TODO:
/// Build from provided shared library binary
// pub fn linkFromBinary(exe: *LibExeObjStep) void {}

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}
