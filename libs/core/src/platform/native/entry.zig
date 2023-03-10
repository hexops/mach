const std = @import("std");
const gpu = @import("gpu");
const App = @import("app").App;
const util = @import("util.zig");

pub const GPUInterface = gpu.dawn.Interface;

const app_std_options = if (@hasDecl(App, "std_options")) App.std_options else struct {};

pub const std_options = struct {
    pub const log_level = if (@hasDecl(app_std_options, "log_level"))
        app_std_options.log_level
    else
        std.log.default_level;

    pub const log_scope_levels = if (@hasDecl(App, "log_scope_levels"))
        app_std_options.log_scope_levels
    else
        &[0]std.log.ScopeLevel{};
};

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
