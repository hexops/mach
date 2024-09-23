/// Load two opus sound files:
/// - One long ~3 minute sound file (BGM/Background music) that plays on repeat
/// - One short sound file (SFX/Sound effect) that plays when you press a key
const std = @import("std");
const builtin = @import("builtin");

const mach = @import("mach");
const assets = @import("assets");
const gpu = mach.gpu;
const math = mach.math;
const sysaudio = mach.sysaudio;

pub const App = @This();

// TODO: banish global allocator
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

pub const mach_module = .app;

pub const mach_systems = .{ .start, .init, .deinit, .tick, .audio_state_change };

// TODO(object)
pub const components = .{
    .is_bgm = .{ .type = void },
};

sfx: mach.Audio.Opus,

fn start(
    core: *mach.Core,
    audio: *mach.Audio,
    app: *App,
) !void {
    core.schedule(.init);
    audio.schedule(.init);
    app.schedule(.init);
}

fn init(
    entities: *mach.Entities.Mod,
    core: *mach.Core,
    audio: *mach.Audio,
    app: *App,
    app_mod: mach.Functions(App),
) !void {
    core.on_tick = app_mod.id.tick;
    core.on_exit = app_mod.id.deinit;

    // Configure the audio module to send our app's .audio_state_change event when an entity's sound
    // finishes playing.
    audio.on_state_change = app_audio_state_change.id;

    const bgm_fbs = std.io.fixedBufferStream(assets.bgm.bit_bit_loop);
    const bgm_sound_stream = std.io.StreamSource{ .const_buffer = bgm_fbs };
    const bgm = try mach.Audio.Opus.decodeStream(gpa.allocator(), bgm_sound_stream);

    const sfx_fbs = std.io.fixedBufferStream(assets.sfx.sword1);
    const sfx_sound_stream = std.io.StreamSource{ .const_buffer = sfx_fbs };
    const sfx = try mach.Audio.Opus.decodeStream(gpa.allocator(), sfx_sound_stream);

    // Initialize module state
    app.init(.{ .sfx = sfx });

    const bgm_entity = try entities.new();
    try app.set(bgm_entity, .is_bgm, {});
    try audio.set(bgm_entity, .samples, bgm.samples);
    try audio.set(bgm_entity, .channels, bgm.channels);
    try audio.set(bgm_entity, .playing, true);
    try audio.set(bgm_entity, .index, 0);

    std.debug.print("controls:\n", .{});
    std.debug.print("[typing]     Play SFX\n", .{});
    std.debug.print("[arrow up]   increase volume 10%\n", .{});
    std.debug.print("[arrow down] decrease volume 10%\n", .{});
}

fn deinit(audio: *mach.Audio) void {
    audio.schedule(.deinit);
}

fn audioStateChange(
    entities: *mach.Entities.Mod,
    audio: *mach.Audio,
    app: *App,
) !void {
    // Find audio entities that are no longer playing
    var q = try entities.query(.{
        .ids = mach.Entities.Mod.read(.id),
        .playings = mach.Audio.read(.playing),
    });
    while (q.next()) |v| {
        for (v.ids, v.playings) |id, playing| {
            if (playing) continue;

            if (app.get(id, .is_bgm)) |_| {
                // Repeat background music
                try audio.set(id, .index, 0);
                try audio.set(id, .playing, true);
            } else {
                // Remove the entity for the old sound
                try entities.remove(id);
            }
        }
    }
}

fn tick(
    entities: *mach.Entities.Mod,
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
                    const e = try entities.new();
                    try audio.set(e, .samples, app.sfx.samples);
                    try audio.set(e, .channels, app.sfx.channels);
                    try audio.set(e, .index, 0);
                    try audio.set(e, .playing, true);
                },
            },
            .close => core.exit(),
            else => {},
        }
    }

    // Grab the back buffer of the swapchain
    // TODO(Core)
    const back_buffer_view = core.swap_chain.getCurrentTextureView().?;
    defer back_buffer_view.release();

    // Create a command encoder
    const label = @tagName(mach_module) ++ ".tick";
    const encoder = core.device.createCommandEncoder(&.{ .label = label });
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
    core.queue.submit(&[_]*gpu.CommandBuffer{command});
}
