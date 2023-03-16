const std = @import("std");
const App = @import("app").App;
const core = @import("core");
const gpu = core.gpu;

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
        const pool = try core.platform_util.AutoReleasePool.init();
        defer core.platform_util.AutoReleasePool.release(pool);
        if (try app.update()) return;
    }
}
