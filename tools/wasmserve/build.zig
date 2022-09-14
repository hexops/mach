const std = @import("std");
const wasmserve = @import("wasmserve.zig");

pub fn build(b: *std.build.Builder) !void {
    const mode = b.standardReleaseOptions();

    const exe = b.addSharedLibrary("test", "test/main.zig", .unversioned);
    exe.setBuildMode(mode);
    exe.setTarget(.{ .cpu_arch = .wasm32, .os_tag = .freestanding, .abi = .none });
    exe.install();

    const serve_step = try wasmserve.serve(exe, .{ .watch_paths = &.{"wasmserve.zig"} });
    const run_step = b.step("test", "Start a testing server");
    run_step.dependOn(&serve_step.step);
}
