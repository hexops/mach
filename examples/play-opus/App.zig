/// Load two opus sound files:
/// - One long ~3 minute sound file (BGM/Background music) that plays on repeat
/// - One short sound file (SFX/Sound effect) that plays when you press a key
const std = @import("std");
const builtin = @import("builtin");

const mach = @import("mach");
const assets = @import("assets");
const Opus = @import("opus");
const gpu = mach.gpu;
const math = mach.math;
const sysaudio = mach.sysaudio;

pub const App = @This();

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

pub const name = .app;
pub const Mod = mach.Mod(@This());

pub const events = .{
    .init = .{ .handler = init },
    .after_init = .{ .handler = afterInit },
    .deinit = .{ .handler = deinit },
    .tick = .{ .handler = tick },
    .audio_state_change = .{ .handler = audioStateChange },
};

pub const components = .{
    .is_bgm = .{ .type = void },
};

sfx: Opus,

fn init(
    entity: *mach.Entity.Mod,
    core: *mach.Core.Mod,
    audio: *mach.Audio.Mod,
    app: *Mod,
) !void {
    audio.send(.init, .{});
    app.send(.after_init, .{});

    const bgm_fbs = std.io.fixedBufferStream(assets.bgm.bit_bit_loop);
    const sfx_fbs = std.io.fixedBufferStream(assets.sfx.sword1);

    var sound_stream = std.io.StreamSource{ .const_buffer = bgm_fbs };
    const bgm = try Opus.decodeStream(gpa.allocator(), sound_stream);

    sound_stream = std.io.StreamSource{ .const_buffer = sfx_fbs };
    const sfx = try Opus.decodeStream(gpa.allocator(), sound_stream);

    // Initialize module state
    app.init(.{ .sfx = sfx });

    const bgm_entity = try entity.new();
    try app.set(bgm_entity, .is_bgm, {});
    try audio.set(bgm_entity, .samples, bgm.samples);
    try audio.set(bgm_entity, .channels, bgm.channels);
    try audio.set(bgm_entity, .playing, true);
    try audio.set(bgm_entity, .index, 0);

    std.debug.print("controls:\n", .{});
    std.debug.print("[typing]     Play SFX\n", .{});
    std.debug.print("[arrow up]   increase volume 10%\n", .{});
    std.debug.print("[arrow down] decrease volume 10%\n", .{});

    core.send(.start, .{});
}

fn afterInit(audio: *mach.Audio.Mod, app: *Mod) void {
    // Configure the audio module to send our app's .audio_state_change event when an entity's sound
    // finishes playing.
    audio.state().on_state_change = app.event(.audio_state_change);
}

fn deinit(core: *mach.Core.Mod, audio: *mach.Audio.Mod) void {
    audio.send(.deinit, .{});
    core.send(.deinit, .{});
}

fn audioStateChange(
    entity: *mach.Entity.Mod,
    audio: *mach.Audio.Mod,
    app: *Mod,
) !void {
    // Find audio entities that are no longer playing
    var archetypes_iter = audio.__entities.queryDeprecated(.{ .all = &.{.{ .mach_audio = &.{.playing} }} });
    while (archetypes_iter.next()) |archetype| {
        for (
            archetype.slice(.entity, .id),
            archetype.slice(.mach_audio, .playing),
        ) |id, playing| {
            if (playing) continue;

            if (app.get(id, .is_bgm)) |_| {
                // Repeat background music
                try audio.set(id, .index, 0);
                try audio.set(id, .playing, true);
            } else {
                // Remove the entity for the old sound
                try entity.remove(id);
            }
        }
    }
}

fn tick(
    entity: *mach.Entity.Mod,
    core: *mach.Core.Mod,
    audio: *mach.Audio.Mod,
    app: *Mod,
) !void {
    // TODO(Core)
    var iter = mach.core.pollEvents();
    while (iter.next()) |event| {
        switch (event) {
            .key_press => |ev| switch (ev.key) {
                .down => {
                    const vol = math.clamp(try audio.state().player.volume() - 0.1, 0, 1);
                    try audio.state().player.setVolume(vol);
                    std.debug.print("[volume] {d:.0}%\n", .{vol * 100.0});
                },
                .up => {
                    const vol = math.clamp(try audio.state().player.volume() + 0.1, 0, 1);
                    try audio.state().player.setVolume(vol);
                    std.debug.print("[volume] {d:.0}%\n", .{vol * 100.0});
                },
                else => {
                    // Play a new SFX
                    const e = try entity.new();
                    try audio.set(e, .samples, app.state().sfx.samples);
                    try audio.set(e, .channels, app.state().sfx.channels);
                    try audio.set(e, .index, 0);
                    try audio.set(e, .playing, true);
                },
            },
            .close => core.send(.exit, .{}),
            else => {},
        }
    }

    // Grab the back buffer of the swapchain
    // TODO(Core)
    const back_buffer_view = mach.core.swap_chain.getCurrentTextureView().?;
    defer back_buffer_view.release();

    // Create a command encoder
    const label = @tagName(name) ++ ".tick";
    const encoder = core.state().device.createCommandEncoder(&.{ .label = label });
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

    // Draw nothing

    // Finish render pass
    render_pass.end();

    // Submit our commands to the queue
    var command = encoder.finish(&.{ .label = label });
    defer command.release();
    core.state().queue.submit(&[_]*gpu.CommandBuffer{command});

    // Present the frame
    core.send(.present_frame, .{});
}
