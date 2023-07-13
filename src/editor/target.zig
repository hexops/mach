const std = @import("std");
const allocator = @import("main.zig").allocator;

pub const Target = enum {
    @"linux-x86_64",
    @"linux-aarch64",
    @"macos-x86_64",
    @"macos-aarch64",
    @"windows-x86_64",
    @"windows-aarch64",
    wasm32,

    // TODO
    // android,
    // ios,

    pub fn parse(str: []const u8) ?Target {
        return if (std.mem.eql(u8, str, "linux"))
            .@"linux-x86_64"
        else if (std.mem.eql(u8, str, "windows"))
            .@"windows-x86_64"
        else if (std.mem.eql(u8, str, "macos"))
            .@"macos-aarch64"
        else if (std.mem.eql(u8, str, "wasm"))
            .wasm32
        else
            std.meta.stringToEnum(Target, str) orelse return null;
    }

    pub fn toZigTriple(self: Target) ![]const u8 {
        const zig_target = std.zig.CrossTarget{
            .cpu_arch = switch (self) {
                .@"linux-x86_64",
                .@"macos-x86_64",
                .@"windows-x86_64",
                => .x86_64,
                .@"linux-aarch64",
                .@"macos-aarch64",
                .@"windows-aarch64",
                => .aarch64,
                .wasm32 => .wasm32,
            },
            .os_tag = switch (self) {
                .@"linux-x86_64", .@"linux-aarch64" => .linux,
                .@"macos-x86_64", .@"macos-aarch64" => .macos,
                .@"windows-x86_64", .@"windows-aarch64" => .windows,
                .wasm32 => .freestanding,
            },
        };
        return zig_target.zigTriple(allocator);
    }
};
