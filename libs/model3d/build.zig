const std = @import("std");
const Builder = std.build.Builder;

var cached_pkg: ?std.build.Pkg = null;

pub fn pkg(b: *Builder) std.build.Pkg {
    if (cached_pkg == null) {
        cached_pkg = .{
            .name = "model3d",
            .source = .{ .path = sdkPath(b, "/src/main.zig") },
            .dependencies = &.{},
        };
    }

    return cached_pkg.?;
}

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&testStep(b, mode, target).step);
}

pub fn testStep(b: *Builder, mode: std.builtin.Mode, target: std.zig.CrossTarget) *std.build.RunStep {
    const main_tests = b.addTestExe("model3d-tests", "src/main.zig");
    main_tests.setBuildMode(mode);
    main_tests.setTarget(target);
    link(b, main_tests, target);
    main_tests.install();
    return main_tests.run();
}

pub fn link(b: *Builder, step: *std.build.LibExeObjStep, target: std.zig.CrossTarget) void {
    const lib = b.addStaticLibrarySource("model3d", null);
    lib.setTarget(target);
    // Note: model3d needs unaligned accesses, which are safe on all modern architectures.
    // See https://gitlab.com/bztsrc/model3d/-/issues/19
    lib.addCSourceFile(sdkPath(b, "/src/c/m3d.c"), &.{ "-std=c89", "-fno-sanitize=alignment" });
    lib.linkLibC();
    step.addIncludePath(sdkPath(b, "/src/c/"));
    step.linkLibrary(lib);
}

const unresolved_dir = (struct {
    inline fn unresolvedDir() []const u8 {
        return comptime std.fs.path.dirname(@src().file) orelse ".";
    }
}).unresolvedDir();

fn thisDir(allocator: std.mem.Allocator) []const u8 {
    if (comptime unresolved_dir[0] == '/') {
        return unresolved_dir;
    }

    const cached_dir = &(struct {
        var cached_dir: ?[]const u8 = null;
    }).cached_dir;

    if (cached_dir.* == null) {
        cached_dir.* = std.fs.cwd().realpathAlloc(allocator, unresolved_dir) catch unreachable;
    }

    return cached_dir.*.?;
}

inline fn sdkPath(b: *Builder, comptime suffix: []const u8) []const u8 {
    return sdkPathAllocator(b.allocator, suffix);
}

inline fn sdkPathAllocator(allocator: std.mem.Allocator, comptime suffix: []const u8) []const u8 {
    return sdkPathInternal(allocator, suffix.len, suffix[0..suffix.len].*);
}

fn sdkPathInternal(allocator: std.mem.Allocator, comptime len: usize, comptime suffix: [len]u8) []const u8 {
    if (suffix[0] != '/') @compileError("suffix must be an absolute path");

    if (comptime unresolved_dir[0] == '/') {
        return unresolved_dir ++ @as([]const u8, &suffix);
    }

    const cached_dir = &(struct {
        var cached_dir: ?[]const u8 = null;
    }).cached_dir;

    if (cached_dir.* == null) {
        cached_dir.* = std.fs.path.resolve(allocator, &.{ thisDir(allocator), suffix[1..] }) catch unreachable;
    }

    return cached_dir.*.?;
}
