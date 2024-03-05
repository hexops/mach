const std = @import("std");
const core = @import("mach").core;
const gpu = core.gpu;
const renderer = @import("renderer.zig");

pub const App = @This();

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

title_timer: core.Timer,

pub fn init(app: *App) !void {
    try core.init(.{});
    app.* = .{
        .title_timer = try core.Timer.start(),
    };
}

pub fn deinit(app: *App) void {
    _ = app;
    defer _ = gpa.deinit();
    defer core.deinit();
}

pub fn update(app: *App) !bool {
    var iter = core.pollEvents();
    while (iter.next()) |event| {
        switch (event) {
            .key_press => |ev| {
                if (ev.key == .space) return true;
            },
            .close => return true,
            else => {},
        }
    }

    app.render();

    // update the window title every second
    if (app.title_timer.read() >= 1.0) {
        app.title_timer.reset();
        try core.printTitle("Clear Color [ {d}fps ] [ Input {d}hz ]", .{
            core.frameRate(),
            core.inputRate(),
        });
    }

    return false;
}

fn render(app: *App) void {
    _ = app;
    const back_buffer_view = core.swap_chain.getCurrentTextureView().?;
    const color_attachment = gpu.RenderPassColorAttachment{
        .view = back_buffer_view,
        .clear_value = gpu.Color{ .r = 0.0, .g = 0.0, .b = 1.0, .a = 1.0 },
        .load_op = .clear,
        .store_op = .store,
    };

    const encoder = core.device.createCommandEncoder(null);
    const render_pass_info = gpu.RenderPassDescriptor.init(.{
        .color_attachments = &.{color_attachment},
    });

    const pass = encoder.beginRenderPass(&render_pass_info);
    pass.end();
    pass.release();

    var command = encoder.finish(null);
    encoder.release();

    var queue = core.queue;
    queue.submit(&[_]*gpu.CommandBuffer{command});
    command.release();
    core.swap_chain.present();
    back_buffer_view.release();
}
