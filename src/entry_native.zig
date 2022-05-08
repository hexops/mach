const std = @import("std");
const Allocator = std.mem.Allocator;
const App = @import("app");

const glfw = @import("glfw");
const gpu = @import("gpu");
const util = @import("util.zig");
const c = @import("c.zig").c;

const Engine = @import("Engine.zig");
const Options = Engine.Options;

// TODO: check signatures
comptime {
    if (!@hasDecl(App, "init")) @compileError("App must export 'pub fn init(app: *App, engine: *mach.Engine) !void'");
    if (!@hasDecl(App, "deinit")) @compileError("App must export 'pub fn deinit(app: *App, engine: *mach.Engine) void'");
    if (!@hasDecl(App, "update")) @compileError("App must export 'pub fn update(app: *App, engine: *mach.Engine) !bool'");
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const options = if (@hasDecl(App, "options")) App.options else Options{};
    var engine = try Engine.init(allocator, options);
    var app: App = undefined;

    try app.init(&engine);
    defer app.deinit(&engine);

    const window = engine.core.internal.window;
    while (!window.shouldClose()) {
        try glfw.pollEvents();

        engine.delta_time_ns = engine.timer.lap();
        engine.delta_time = @intToFloat(f64, engine.delta_time_ns) / @intToFloat(f64, std.time.ns_per_s);

        var framebuffer_size = try window.getFramebufferSize();
        engine.gpu_driver.target_desc.width = framebuffer_size.width;
        engine.gpu_driver.target_desc.height = framebuffer_size.height;

        if (engine.gpu_driver.swap_chain == null or !engine.gpu_driver.current_desc.equal(&engine.gpu_driver.target_desc)) {
            const use_legacy_api = engine.gpu_driver.surface == null;
            if (!use_legacy_api) {
                engine.gpu_driver.swap_chain = engine.gpu_driver.device.nativeCreateSwapChain(engine.gpu_driver.surface, &engine.gpu_driver.target_desc);
            } else engine.gpu_driver.swap_chain.?.configure(
                engine.gpu_driver.swap_chain_format,
                .{ .render_attachment = true },
                engine.gpu_driver.target_desc.width,
                engine.gpu_driver.target_desc.height,
            );

            if (@hasDecl(App, "resize")) {
                try app.resize(&engine, engine.gpu_driver.target_desc.width, engine.gpu_driver.target_desc.height);
            }
            engine.gpu_driver.current_desc = engine.gpu_driver.target_desc;
        }

        const success = try app.update(&engine);
        if (!success)
            break;
    }
}
