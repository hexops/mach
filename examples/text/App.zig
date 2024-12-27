const std = @import("std");
const zigimg = @import("zigimg");
const assets = @import("assets");
const mach = @import("mach");
const gfx = mach.gfx;
const gpu = mach.gpu;
const math = mach.math;

const vec2 = math.vec2;
const vec3 = math.vec3;
const vec4 = math.vec4;
const Vec2 = math.Vec2;
const Vec3 = math.Vec3;
const Mat3x3 = math.Mat3x3;
const Mat4x4 = math.Mat4x4;

const App = @This();

pub const mach_module = .app;

pub const mach_systems = .{ .main, .init, .tick, .deinit };

pub const main = mach.schedule(.{
    .{ mach.Core, .init },
    .{ gfx.Text, .init },
    .{ App, .init },
    .{ mach.Core, .main },
});

allocator: std.mem.Allocator,
window: mach.ObjectID,
timer: mach.time.Timer,
spawn_timer: mach.time.Timer,
fps_timer: mach.time.Timer,
rand: std.Random.DefaultPrng,

frame_count: usize = 0,
time: f32 = 0,
direction: Vec2 = vec2(0, 0),
spawning: bool = false,
player_id: mach.ObjectID = undefined,
style1_id: mach.ObjectID = undefined,
pipeline_id: mach.ObjectID = undefined,

const upscale = 1.0;

const text1: []const []const u8 = &.{
    "Text but with spaces\n",
    "and\n",
    "newlines\n",
};

const text2: []const []const u8 = &.{"$!?"};

pub fn init(
    core: *mach.Core,
    app: *App,
    app_mod: mach.Mod(App),
) !void {
    core.on_tick = app_mod.id.tick;
    core.on_exit = app_mod.id.deinit;

    const window = try core.windows.new(.{
        .title = "gfx.Text",
    });

    // TODO(allocator): find a better way to get an allocator here
    const allocator = std.heap.c_allocator;

    app.* = .{
        .allocator = allocator,
        .window = window,
        .timer = try mach.time.Timer.start(),
        .spawn_timer = try mach.time.Timer.start(),
        .fps_timer = try mach.time.Timer.start(),
        .rand = std.Random.DefaultPrng.init(1337),
    };
}

fn setupPipeline(
    app: *App,
    text: *gfx.Text,
    window_id: mach.ObjectID,
) !void {
    // Create a text rendering pipeline
    app.pipeline_id = try text.pipelines.new(.{
        .window = window_id,
        .render_pass = undefined,
    });

    // Create a text style
    app.style1_id = try text.styles.new(.{
        .font_size = 48 * gfx.px_per_pt, // 48pt
    });

    // TODO(text): release this memory somewhere
    const player_text_value =
        \\ Text with spaces
        \\ and newlines
        \\ but nothing fancy (yet)
    ;
    const player_text = try app.allocator.alloc(u8, player_text_value.len);
    @memcpy(player_text, player_text_value);
    const player_segments = try app.allocator.alloc(gfx.Text.Segment, 1);
    player_segments[0] = .{
        .text = player_text,
        .style = app.style1_id,
    };

    // Create our player text
    app.player_id = try text.objects.new(.{
        .transform = Mat4x4.translate(vec3(-0.02, 0, 0)),
        .segments = player_segments,
    });
    // Attach the text object to our text rendering pipeline.
    try text.pipelines.setParent(app.player_id, app.pipeline_id);
}

pub fn tick(
    core: *mach.Core,
    app: *App,
    text: *gfx.Text,
    text_mod: mach.Mod(gfx.Text),
) !void {
    const label = @tagName(mach_module) ++ ".tick";

    var direction = app.direction;
    var spawning = app.spawning;
    while (core.nextEvent()) |event| {
        switch (event) {
            .key_press => |ev| {
                switch (ev.key) {
                    .left => direction.v[0] -= 1,
                    .right => direction.v[0] += 1,
                    .up => direction.v[1] += 1,
                    .down => direction.v[1] -= 1,
                    .space => spawning = true,
                    else => {},
                }
            },
            .key_release => |ev| {
                switch (ev.key) {
                    .left => direction.v[0] += 1,
                    .right => direction.v[0] -= 1,
                    .up => direction.v[1] -= 1,
                    .down => direction.v[1] += 1,
                    .space => spawning = false,
                    else => {},
                }
            },
            .window_open => |ev| try setupPipeline(app, text, ev.window_id),
            .close => core.exit(),
            else => {},
        }
    }
    app.direction = direction;
    app.spawning = spawning;

    var player = text.objects.getValue(app.player_id);
    var player_pos = player.transform.translation();
    if (spawning and app.spawn_timer.read() > 1.0 / 60.0) {
        // Spawn new entities
        _ = app.spawn_timer.lap();
        for (0..10) |_| {
            var new_pos = player_pos;
            new_pos.v[0] += app.rand.random().floatNorm(f32) * 50;
            new_pos.v[1] += app.rand.random().floatNorm(f32) * 50;

            // TODO(text): release this memory somewhere
            const new_text_value = "?!";
            const new_text = try app.allocator.alloc(u8, new_text_value.len);
            @memcpy(new_text, new_text_value);
            const new_segments = try app.allocator.alloc(gfx.Text.Segment, 1);
            new_segments[0] = .{
                .text = new_text,
                .style = app.style1_id,
            };

            const new_text_id = try text.objects.new(.{
                .transform = Mat4x4.scaleScalar(upscale).mul(&Mat4x4.translate(new_pos)),
                .segments = new_segments,
            });
            try text.pipelines.setParent(new_text_id, app.pipeline_id);
        }
    }

    // Multiply by delta_time to ensure that movement is the same speed regardless of the frame rate.
    const delta_time = app.timer.lap();

    // Rotate all text objects in the pipeline.
    var pipeline_children = try text.pipelines.getChildren(app.pipeline_id);
    defer pipeline_children.deinit();
    for (pipeline_children.items) |text_id| {
        if (!text.objects.is(text_id)) continue;
        if (text_id == app.player_id) continue; // don't rotate the player
        var s = text.objects.getValue(text_id);

        const location = s.transform.translation();
        var transform = Mat4x4.ident;
        transform = transform.mul(&Mat4x4.translate(location));
        transform = transform.mul(&Mat4x4.rotateZ(2 * math.pi * app.time));
        transform = transform.mul(&Mat4x4.scaleScalar(@min(math.cos(app.time / 2.0), 0.5)));
        text.objects.set(text_id, .transform, transform);
    }

    // Calculate the player position, by moving in the direction the player wants to go
    // by the speed amount.
    const speed = 200.0;
    player_pos.v[0] += direction.x() * speed * delta_time;
    player_pos.v[1] += direction.y() * speed * delta_time;
    text.objects.set(app.player_id, .transform, Mat4x4.translate(player_pos));

    const window = core.windows.getValue(app.window);

    // Grab the back buffer of the swapchain
    // TODO(Core)
    const back_buffer_view = window.swap_chain.getCurrentTextureView().?;
    defer back_buffer_view.release();

    // Create a command encoder
    const encoder = window.device.createCommandEncoder(&.{ .label = label });
    defer encoder.release();

    // Begin render pass
    const sky_blue = gpu.Color{ .r = 0.776, .g = 0.988, .b = 1, .a = 1 };
    const color_attachments = [_]gpu.RenderPassColorAttachment{.{
        .view = back_buffer_view,
        .clear_value = sky_blue,
        .load_op = .clear,
        .store_op = .store,
    }};
    const render_pass = encoder.beginRenderPass(&gpu.RenderPassDescriptor.init(.{
        .label = label,
        .color_attachments = &color_attachments,
    }));

    // Render text
    text.pipelines.set(app.pipeline_id, .render_pass, render_pass);
    text_mod.call(.tick);

    // Finish render pass
    render_pass.end();
    var command = encoder.finish(&.{ .label = label });
    window.queue.submit(&[_]*gpu.CommandBuffer{command});
    command.release();
    render_pass.release();

    app.frame_count += 1;
    app.time += delta_time;

    // TODO(object): window-title
    // // Every second, update the window title with the FPS
    // if (app.fps_timer.read() >= 1.0) {
    //     const pipeline = text.pipelines.getValue(app.pipeline_id);
    //     try core.printTitle(
    //         core.main_window,
    //         "text [ FPS: {d} ] [ Texts: {d} ] [ Segments: {d} ] [ Styles: {d} ]",
    //         .{ app.frame_count, pipeline.num_texts, pipeline.num_segments, pipeline.num_styles },
    //     );
    //     core.schedule(.update);
    //     app.fps_timer.reset();
    //     app.frame_count = 0;
    // }
}

pub fn deinit(
    app: *App,
    text: *gfx.Text,
) void {
    // Cleanup here, if desired.
    text.objects.delete(app.player_id);
}
