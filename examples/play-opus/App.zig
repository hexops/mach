/// Loads and plays opus sound files.
///
/// Plays a long background music sound file that plays on repeat, and a short sound effect that
/// plays when pressing keys.
const std = @import("std");
const builtin = @import("builtin");

const mach = @import("mach");
const assets = @import("assets");
const gpu = mach.gpu;
const math = mach.math;
const sysaudio = mach.sysaudio;

pub const App = @This();

pub const mach_module = .app;

pub const mach_systems = .{ .main, .init, .tick, .deinit, .audioStateChange };

pub const main = mach.schedule(.{
    .{ mach.Core, .init },
    .{ mach.Audio, .init },
    .{ App, .init },
    .{ mach.Core, .main },
});

pub const deinit = mach.schedule(.{
    .{ mach.Audio, .deinit },
});

/// Tag object we set as a child of mach.Audio objects to indicate they are background music.
// TODO(object): consider adding a better object 'tagging' system?
bgm: mach.Objects(.{}, struct {}),

sfx: mach.Audio.Opus,

pub fn init(
    core: *mach.Core,
    audio: *mach.Audio,
    app: *App,
    app_mod: mach.Mod(App),
) !void {
    // TODO(allocator): find a better way to get an allocator here
    const allocator = std.heap.c_allocator;

    core.on_tick = app_mod.id.tick;
    core.on_exit = app_mod.id.deinit;

    // Configure the audio module to send our app's .audio_state_change event when an entity's sound
    // finishes playing.
    audio.on_state_change = app_mod.id.audioStateChange;

    const bgm_fbs = std.io.fixedBufferStream(assets.bgm.bit_bit_loop);
    const bgm_sound_stream = std.io.StreamSource{ .const_buffer = bgm_fbs };
    const bgm = try mach.Audio.Opus.decodeStream(allocator, bgm_sound_stream);
    // TODO(object): bgm here is not freed inside of deinit(), if we had object-scoped allocators we
    // could do this more nicely in real applications

    const sfx_fbs = std.io.fixedBufferStream(assets.sfx.sword1);
    const sfx_sound_stream = std.io.StreamSource{ .const_buffer = sfx_fbs };
    const sfx = try mach.Audio.Opus.decodeStream(allocator, sfx_sound_stream);

    // Initialize module state
    app.* = .{ .sfx = sfx, .bgm = app.bgm };

    const bgm_buffer = blk: {
        audio.buffers.lock();
        defer audio.buffers.unlock();

        break :blk try audio.buffers.new(.{
            .samples = bgm.samples,
            .channels = bgm.channels,
        });
    };
    const bgm_obj = try app.bgm.new(.{});
    try app.bgm.setParent(bgm_obj, bgm_buffer);

    std.debug.print("controls:\n", .{});
    std.debug.print("[typing]     Play SFX\n", .{});
    std.debug.print("[arrow up]   increase volume 10%\n", .{});
    std.debug.print("[arrow down] decrease volume 10%\n", .{});
}

pub fn audioStateChange(audio: *mach.Audio, app: *App) !void {
    audio.buffers.lock();
    defer audio.buffers.unlock();

    // Find audio entities that are no longer playing
    var buffers = audio.buffers.slice();
    while (buffers.next()) |buf_id| {
        if (audio.buffers.get(buf_id, .playing)) continue;

        // If the buffer has a bgm object as a child, then we consider it background music
        if (try app.bgm.getFirstChildOfType(buf_id)) |_| {
            // Repeat background music forever
            audio.buffers.set(buf_id, .index, 0);
            audio.buffers.set(buf_id, .playing, true);
        } else audio.buffers.delete(buf_id);
    }
}

pub fn tick(
    core: *mach.Core,
    audio: *mach.Audio,
    app: *App,
) !void {
    while (core.nextEvent()) |event| {
        switch (event) {
            .key_press => |ev| switch (ev.key) {
                .down => {
                    const vol = math.clamp(try audio.player.volume() - 0.1, 0, 1);
                    try audio.player.setVolume(vol);
                    std.debug.print("[volume] {d:.0}%\n", .{vol * 100.0});
                },
                .up => {
                    const vol = math.clamp(try audio.player.volume() + 0.1, 0, 1);
                    try audio.player.setVolume(vol);
                    std.debug.print("[volume] {d:.0}%\n", .{vol * 100.0});
                },
                else => {
                    // Play a new SFX
                    audio.buffers.lock();
                    defer audio.buffers.unlock();

                    _ = try audio.buffers.new(.{
                        .samples = app.sfx.samples,
                        .channels = app.sfx.channels,

                        // Start 0.15s into the sfx, which removes the silence at the start of the
                        // audio clip and makes it more apparent the low latency between pressing a
                        // key and sfx actually playing.
                        .index = @intFromFloat(@as(f32, @floatFromInt(audio.player.sampleRate() * app.sfx.channels)) * 0.15),
                    });
                },
            },
            .close => core.exit(),
            else => {},
        }
    }

    var main_window = core.windows.getValue(core.main_window);

    // Grab the back buffer of the swapchain
    // TODO(Core)
    const back_buffer_view = main_window.swap_chain.getCurrentTextureView().?;
    defer back_buffer_view.release();

    // Create a command encoder
    const label = @tagName(mach_module) ++ ".tick";
    const encoder = main_window.device.createCommandEncoder(&.{ .label = label });
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

    // Draw nothing

    // Finish render pass
    render_pass.end();

    // Submit our commands to the queue
    var command = encoder.finish(&.{ .label = label });
    defer command.release();
    main_window.queue.submit(&[_]*gpu.CommandBuffer{command});
}
