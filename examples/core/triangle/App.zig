const std = @import("std");
const mach = @import("mach");
const gpu = mach.gpu;

const zigimg = @import("zigimg");

pub const name = .app;
pub const Mod = mach.Mod(@This());

const Offscreen = @import("Offscreen.zig");

pub const systems = .{
    .init = .{ .handler = init },
    .after_init = .{ .handler = afterInit },
    .deinit = .{ .handler = deinit },
    .tick = .{ .handler = tick },
};

title_timer: mach.Timer,
pipeline: *gpu.RenderPipeline,
screenshot_requested: bool = false,
save_screenshot: bool = false,
screenshot_saved: bool = false,

pub fn deinit(core: *mach.Core.Mod, game: *Mod, offscreen: *Offscreen.Mod) void {
    game.state().pipeline.release();
    offscreen.schedule(.deinit);
    core.schedule(.deinit);
}

fn init(game: *Mod, core: *mach.Core.Mod, offscreen: *Offscreen.Mod) !void {
    core.schedule(.init);
    offscreen.schedule(.init);
    game.schedule(.after_init);
}

fn afterInit(game: *Mod, core: *mach.Core.Mod, _: *Offscreen.Mod) !void {

    // Create our shader module
    const shader_module = core.state().device.createShaderModuleWGSL("shader.wgsl", @embedFile("shader.wgsl"));
    defer shader_module.release();

    // Blend state describes how rendered colors get blended
    const blend = gpu.BlendState{};

    // Color target describes e.g. the pixel format of the window we are rendering to.
    const color_target = gpu.ColorTargetState{
        .format = core.get(core.state().main_window, .framebuffer_format).?,
        .blend = &blend,
    };

    // Fragment state describes which shader and entrypoint to use for rendering fragments.
    const fragment = gpu.FragmentState.init(.{
        .module = shader_module,
        .entry_point = "frag_main",
        .targets = &.{color_target},
    });

    // Create our render pipeline that will ultimately get pixels onto the screen.
    const label = @tagName(name) ++ ".init";
    const pipeline_descriptor = gpu.RenderPipeline.Descriptor{
        .label = label,
        .fragment = &fragment,
        .vertex = gpu.VertexState{
            .module = shader_module,
            .entry_point = "vertex_main",
        },
    };
    const pipeline = core.state().device.createRenderPipeline(&pipeline_descriptor);

    // Store our render pipeline in our module's state, so we can access it later on.
    game.init(.{
        .title_timer = try mach.Timer.start(),
        .pipeline = pipeline,
    });
    try updateWindowTitle(core);

    core.schedule(.start);
}

fn tick(core: *mach.Core.Mod, game: *Mod, offscreen: *Offscreen.Mod) !void {
    // TODO(important): event polling should occur in mach.Core module and get fired as ECS event.
    // TODO(Core)
    var iter = mach.core.pollEvents();
    while (iter.next()) |event| {
        switch (event) {
            .close => core.schedule(.exit), // Tell mach.Core to exit the app
            else => {},
        }
    }

    if (mach.core.keyPressed(mach.core.Key.space) and !game.state().screenshot_saved) {
        game.state().screenshot_requested = true;
    }

    // Grab the back buffer of the swapchain
    // TODO(Core)
    const back_buffer_view = mach.core.swap_chain.getCurrentTextureView().?;
    defer back_buffer_view.release();

    // Create a command encoder
    const label = @tagName(name) ++ ".tick";
    const encoder: *mach.gpu.CommandEncoder = core.state().device.createCommandEncoder(&.{ .label = label });
    defer encoder.release();

    // Begin render pass
    const sky_blue_background = gpu.Color{ .r = 0.776, .g = 0.988, .b = 1, .a = 1 };
    const color_attachments = [_]gpu.RenderPassColorAttachment{.{
        .view = back_buffer_view,
        .clear_value = sky_blue_background,
        .load_op = .clear,
        .store_op = .store,
    }};
    const render_pass = encoder.beginRenderPass(&gpu.RenderPassDescriptor.init(.{
        .label = label,
        .color_attachments = &color_attachments,
    }));
    defer render_pass.release();

    // Draw
    render_pass.setPipeline(game.state().pipeline);
    render_pass.draw(3, 1, 0, 0);

    // Finish render pass
    render_pass.end();

    if (game.state().screenshot_requested) {
        const offscreen_color_attachments = [_]gpu.RenderPassColorAttachment{.{
            .view = offscreen.state().view,
            .clear_value = sky_blue_background,
            .load_op = .clear,
            .store_op = .store,
        }};

        const offscreen_render_pass = encoder.beginRenderPass(&gpu.RenderPassDescriptor.init(.{
            .label = label,
            .color_attachments = &offscreen_color_attachments,
        }));
        defer offscreen_render_pass.release();

        // Draw
        offscreen_render_pass.setPipeline(game.state().pipeline);
        offscreen_render_pass.draw(3, 1, 0, 0);

        // Finish render pass
        offscreen_render_pass.end();

        encoder.copyTextureToBuffer(
            &.{ .texture = offscreen.state().texture },
            &.{ .buffer = offscreen.state().buffer, .layout = .{
                .bytes_per_row = offscreen.state().buffer_padded_bytes_per_row,
                .rows_per_image = offscreen.state().buffer_height,
            } },
            &.{
                .width = offscreen.state().buffer_width,
                .height = offscreen.state().buffer_height,
                .depth_or_array_layers = 1,
            },
        );
        game.state().save_screenshot = true;
        game.state().screenshot_requested = false;
    }

    // Submit our commands to the queue
    var command = encoder.finish(&.{ .label = label });
    defer command.release();
    core.state().queue.submit(&[_]*gpu.CommandBuffer{command});

    // Present the frame
    core.schedule(.present_frame);

    if (game.state().save_screenshot) {
        const state: *Offscreen = offscreen.state();

        const buffer_size = state.buffer_height * state.buffer_width;

        var response: gpu.Buffer.MapAsyncStatus = undefined;
        const callback = (struct {
            pub inline fn callback(ctx: *gpu.Buffer.MapAsyncStatus, status: gpu.Buffer.MapAsyncStatus) void {
                ctx.* = status;
            }
        }).callback;

        state.buffer.mapAsync(.{ .read = true }, 0, buffer_size * @sizeOf([4]u8), &response, callback);
        while (true) {
            if (response == gpu.Buffer.MapAsyncStatus.success) {
                break;
            } else {
                mach.core.device.tick();
            }
        }

        if (state.buffer.getConstMappedRange([4]u8, 0, buffer_size)) |buffer_mapped| {
            var image = try zigimg.Image.create(state.allocator, state.buffer_width, state.buffer_height, .rgba32);

            for (image.pixels.rgba32, 0..) |*p, i| {
                p.r = buffer_mapped[i][2];
                p.g = buffer_mapped[i][1];
                p.b = buffer_mapped[i][0];
                p.a = buffer_mapped[i][3];
            }

            try image.writeToFilePath("output.png", .{ .png = .{} });
        }

        game.state().save_screenshot = false;
        game.state().screenshot_saved = true;
    }

    // update the window title every second
    if (game.state().title_timer.read() >= 1.0) {
        game.state().title_timer.reset();
        try updateWindowTitle(core);
    }
}

fn updateWindowTitle(core: *mach.Core.Mod) !void {
    try mach.Core.printTitle(
        core,
        core.state().main_window,
        "core-custom-entrypoint [ {d}fps ] [ Input {d}hz ]",
        .{
            // TODO(Core)
            mach.core.frameRate(),
            mach.core.inputRate(),
        },
    );
    core.schedule(.update);
}
