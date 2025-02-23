const std = @import("std");
const mach = @import("mach");
const gpu = mach.gpu;

const App = @This();

// The set of Mach modules our application may use.
pub const Modules = mach.Modules(.{
    mach.Core,
    @This(),
});

pub const mach_module = .app;

pub const mach_systems = .{ .main, .init, .tick, .deinit };

pub const main = mach.schedule(.{
    .{ mach.Core, .init },
    .{ App, .init },
    .{ mach.Core, .main },
});

window: mach.ObjectID,
title_timer: mach.time.Timer,
color_timer: mach.time.Timer,
color_time: f32 = 0.0,
flip: bool = false,
pipeline: *gpu.RenderPipeline = undefined,

pub fn init(
    core: *mach.Core,
    app: *App,
    app_mod: mach.Mod(App),
) !void {
    core.on_tick = app_mod.id.tick;
    core.on_exit = app_mod.id.deinit;

    const window = try core.windows.new(.{
        .title = "core-transparent-window",
        .vsync_mode = .double,
        .transparent = true,
    });

    // Store our render pipeline in our module's state, so we can access it later on.
    app.* = .{
        .window = window,
        .title_timer = try mach.time.Timer.start(),
        .color_timer = try mach.time.Timer.start(),
    };
}

fn setupPipeline(core: *mach.Core, app: *App, window_id: mach.ObjectID) !void {
    var window = core.windows.getValue(window_id);
    defer core.windows.setValueRaw(window_id, window);

    // Create our shader module
    const shader_module = window.device.createShaderModuleWGSL("shader.wgsl", @embedFile("shader.wgsl"));
    defer shader_module.release();

    // Blend state describes how rendered colors get blended
    var blend = gpu.BlendState{};

    // Color target describes e.g. the pixel format of the window we are rendering to.
    const color_target = gpu.ColorTargetState{
        .format = window.framebuffer_format,
        .blend = &blend,
    };

    // Fragment state describes which shader and entrypoint to use for rendering fragments.
    const fragment = gpu.FragmentState.init(.{
        .module = shader_module,
        .entry_point = "frag_main",
        .targets = &.{color_target},
    });

    // Create our render pipeline that will ultimately get pixels onto the screen.
    const label = @tagName(mach_module) ++ ".init";
    const pipeline_descriptor = gpu.RenderPipeline.Descriptor{
        .label = label,
        .fragment = &fragment,
        .vertex = gpu.VertexState{
            .module = shader_module,
            .entry_point = "vertex_main",
        },
    };
    app.pipeline = window.device.createRenderPipeline(&pipeline_descriptor);
}

// TODO(object): window-title
// try updateWindowTitle(core);

pub fn tick(app: *App, core: *mach.Core) void {
    while (core.nextEvent()) |event| {
        switch (event) {
            .window_open => |ev| {
                try setupPipeline(core, app, ev.window_id);
            },
            .key_repeat, .key_press => |ev| {
                switch (ev.key) {
                    .right => {
                        core.windows.set(app.window, .width, core.windows.get(app.window, .width) + 10);
                    },
                    .left => {
                        core.windows.set(app.window, .width, core.windows.get(app.window, .width) - 10);
                    },
                    .up => {
                        core.windows.set(app.window, .height, core.windows.get(app.window, .height) + 10);
                    },
                    .down => {
                        core.windows.set(app.window, .height, core.windows.get(app.window, .height) - 10);
                    },
                    else => {},
                }
            },
            .close => core.exit(),
            else => {},
        }
    }

    var window = core.windows.getValue(app.window);

    // Grab the back buffer of the swapchain
    // TODO(Core)
    const back_buffer_view = window.swap_chain.getCurrentTextureView().?;
    defer back_buffer_view.release();

    // Create a command encoder
    const label = @tagName(mach_module) ++ ".tick";

    const encoder = window.device.createCommandEncoder(&.{ .label = label });
    defer encoder.release();

    // Begin render pass
    const transparent_background = gpu.Color{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 0.0 };
    const color_attachments = [_]gpu.RenderPassColorAttachment{.{
        .view = back_buffer_view,
        .clear_value = transparent_background,
        .load_op = .clear,
        .store_op = .store,
    }};
    const render_pass = encoder.beginRenderPass(&gpu.RenderPassDescriptor.init(.{
        .label = label,
        .color_attachments = &color_attachments,
    }));
    defer render_pass.release();

    // Draw
    render_pass.setPipeline(app.pipeline);
    render_pass.draw(3, 1, 0, 0);

    // Finish render pass
    render_pass.end();

    // Submit our commands to the queue
    var command = encoder.finish(&.{ .label = label });
    defer command.release();
    window.queue.submit(&[_]*gpu.CommandBuffer{command});

    if (app.title_timer.read() >= 1.0) {
        app.title_timer.reset();
        // TODO(object): window-title

        core.windows.set(app.window, .title, std.fmt.allocPrintZ(core.allocator, "core-transparent-window [ {d}fps ] [ Input {d}hz ]", .{ core.frame.rate, core.input.rate }) catch unreachable);
    }

    if (app.color_time >= 4.0 or app.color_time <= 0.0) {
        app.color_time = @trunc(app.color_time);
        app.flip = !app.flip;
    }

    if (!app.flip) {
        app.color_time -= app.color_timer.lap();
    } else {
        app.color_time += app.color_timer.lap();
    }

    const red = mach.math.lerp(0.1, 0.6, mach.math.clamp(app.color_time, 0.0, 1.0));
    const blue = mach.math.lerp(0.2, 0.6, mach.math.clamp(app.color_time - 1.0, 0.0, 1.0));
    const green = mach.math.lerp(0.2, 0.6, mach.math.clamp(app.color_time - 2.0, 0.0, 1.0));
    const alpha = mach.math.lerp(0.3, 1.0, app.color_time / 4.0);

    core.windows.set(
        app.window,
        .decoration_color,
        .{ .r = red, .g = green, .b = blue, .a = alpha },
    );
}

pub fn deinit(app: *App) void {
    app.pipeline.release();
}
