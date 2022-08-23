//! Usage: zig run ./dev/ensure-standard-files.zig

const std = @import("std");

const dirs = [_][]const u8{
    ".",
    "basisu",
    "ecs",
    "freetype",
    "gamemode",
    "glfw",
    "gpu",
    "gpu-dawn",
    "sysaudio",
    "sysjs",
};

pub fn main() !void {
    inline for (dirs) |dir| {
        copyFile("dev/template/LICENSE", dir ++ "/LICENSE");
        copyFile("dev/template/LICENSE-MIT", dir ++ "/LICENSE-MIT");
        copyFile("dev/template/LICENSE-APACHE", dir ++ "/LICENSE-APACHE");
    }
}

pub fn copyFile(src_path: []const u8, dst_path: []const u8) void {
    std.fs.cwd().copyFile(src_path, std.fs.cwd(), dst_path, .{}) catch unreachable;
}
