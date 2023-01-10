const std = @import("std");
const gpu = @import("gpu");
const App = @import("app").App;
const util = @import("util.zig");

pub const GPUInterface = gpu.dawn.Interface;
pub const scope_levels = if (@hasDecl(App, "scope_levels")) App.scope_levels else [0]std.log.ScopeLevel{};
pub const log_level = if (@hasDecl(App, "log_level")) App.log_level else std.log.default_level;
pub fn main() !void {
    gpu.Impl.init();
    _ = gpu.Export(GPUInterface);

    var app: App = undefined;
    try app.init();
    defer app.deinit();

    while (true) {
        const pool = try util.AutoReleasePool.init();
        defer util.AutoReleasePool.release(pool);
        if (try app.update()) return;
    }
}
