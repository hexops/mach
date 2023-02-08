const std = @import("std");
const wasmserve = @import("wasmserve.zig");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addSharedLibrary(.{
        .name = "test",
        .root_source_file = .{ .path = "test/main.zig" },
        .target = .{ .cpu_arch = .wasm32, .os_tag = .freestanding, .abi = .none },
        .optimize = optimize,
    });
    exe.install();

    const serve_step = try wasmserve.serve(exe, .{ .watch_paths = &.{"wasmserve.zig"} });
    const run_step = b.step("test", "Start a testing server");
    run_step.dependOn(&serve_step.step);
}
