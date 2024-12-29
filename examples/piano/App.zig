// A simple tone engine.
//
// `keyToFrequency` can be used to convert a keyboard key to a frequency, so that the
// keys asdfghj on your QWERTY keyboard will map to the notes C/D/E/F/G/A/B[4], the
// keys above qwertyu will map to C5 and the keys below zxcvbnm will map to C3.
//
// The duration is hard-coded to 1.5s. To prevent clicking, tones are faded in linearly over
// the first 1/64th duration of the tone. To provide a cool sustained effect, tones are faded
// out using 1-log10(x*10) (google it to see how it looks, it's strong for most of the duration of
// the note then fades out slowly.)
const std = @import("std");
const builtin = @import("builtin");

const mach = @import("mach");
const gpu = mach.gpu;
const math = mach.math;
const sysaudio = mach.sysaudio;

const App = @This();

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
play_after: mach.Objects(.{}, struct {
    frequency: f32,
}),

allocator: std.mem.Allocator,
window: mach.ObjectID,
ghost_key_mode: bool = false,

pub fn init(
    core: *mach.Core,
    audio: *mach.Audio,
    app: *App,
    app_mod: mach.Mod(App),
) !void {
    core.on_tick = app_mod.id.tick;
    core.on_exit = app_mod.id.deinit;

    const window = try core.windows.new(.{
        .title = "piano",
    });

    // Configure the audio module to call our App.audioStateChange function when a sound buffer
    // finishes playing.
    audio.on_state_change = app_mod.id.audioStateChange;

    // TODO(allocator): find a better way to get an allocator here
    const allocator = std.heap.c_allocator;

    app.* = .{
        .allocator = allocator,
        .play_after = app.play_after,
        .window = window,
    };

    std.debug.print("controls:\n", .{});
    std.debug.print("[typing]     Play piano noises\n", .{});
    std.debug.print("[spacebar]   enable ghost-key mode (demonstrate seamless back-to-back sound playback)\n", .{});
    std.debug.print("[arrow up]   increase volume 10%\n", .{});
    std.debug.print("[arrow down] decrease volume 10%\n", .{});
}

/// Called on the high-priority audio OS thread when the audio driver needs more audio samples, so
/// this callback should be fast to respond.
pub fn audioStateChange(audio: *mach.Audio, app: *App) !void {
    audio.buffers.lock();
    defer audio.buffers.unlock();

    app.play_after.lock();
    defer app.play_after.unlock();

    // Find audio objects that are no longer playing
    var buffers = audio.buffers.slice();
    while (buffers.next()) |buf_id| {
        if (audio.buffers.get(buf_id, .playing)) continue;

        // If this object has a play_after child, then play a new sound.
        if (try app.play_after.getFirstChildOfType(buf_id)) |play_after_id| {
            const frequency = app.play_after.get(play_after_id, .frequency);

            std.debug.print("ghost note!\n", .{});
            _ = try audio.buffers.new(.{
                .samples = try app.fillTone(audio, frequency),
                .channels = @intCast(audio.player.channels().len),
            });

            // TODO(object): support cascading removal of children when parent is deleted?
            //
            // TODO(object): potential footgun: if object is deleted, its graph relations remain in
            // tact still.
            try app.play_after.removeChild(buf_id, play_after_id);
        }

        // Remove the audio buffer that is no longer playing
        const samples = audio.buffers.get(buf_id, .samples);
        audio.buffers.delete(buf_id);
        app.allocator.free(samples);
    }
}

pub fn tick(
    core: *mach.Core,
    audio: *mach.Audio,
    app: *App,
) !void {
    while (core.nextEvent()) |event| {
        switch (event) {
            .key_press => |ev| {
                switch (ev.key) {
                    // Controls
                    .space => app.ghost_key_mode = !app.ghost_key_mode,
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

                    // Piano keys
                    else => {
                        // Play a new sound
                        audio.buffers.lock();
                        defer audio.buffers.unlock();

                        app.play_after.lock();
                        defer app.play_after.unlock();

                        // Play a new piano key sound
                        const sound_id = try audio.buffers.new(.{
                            .samples = try app.fillTone(audio, keyToFrequency(ev.key)),
                            .channels = @intCast(audio.player.channels().len),
                        });

                        if (app.ghost_key_mode) {
                            // After that sound plays, we'll chain on another sound that is one semi-tone higher.
                            const one_semi_tone_higher = keyToFrequency(ev.key) * math.pow(f32, 2.0, (1.0 / 12.0));

                            const play_after_id = try app.play_after.new(.{ .frequency = one_semi_tone_higher });
                            try audio.buffers.addChild(sound_id, play_after_id);
                        }
                    },
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
    window.queue.submit(&[_]*gpu.CommandBuffer{command});
}

fn fillTone(app: *App, audio: *mach.Audio, frequency: f32) ![]align(mach.Audio.alignment) const f32 {
    const channels = audio.player.channels().len;
    const sample_rate: f32 = @floatFromInt(audio.player.sampleRate());
    const duration: f32 = 1.5 * @as(f32, @floatFromInt(channels)) * sample_rate; // play the tone for 1.5s
    const gain = 0.1;

    const samples = try app.allocator.alignedAlloc(f32, mach.Audio.alignment, @intFromFloat(duration));

    var i: usize = 0;
    while (i < samples.len) : (i += channels) {
        const sample_index: f32 = @floatFromInt(i + 1);
        const sine_wave = math.sin(frequency * 2.0 * math.pi * sample_index / sample_rate) * gain;

        // A number ranging from 0.0 to 1.0 in the first 1/64th of the duration of the tone.
        const fade_in = @min(sample_index / (duration / 64.0), 1.0);

        // A number ranging from 1.0 to 0.0 over half the duration of the tone.
        const progression = sample_index / duration; // 0.0 (tone start) to 1.0 (tone end)
        const fade_out = 1.0 - math.clamp(math.log10(progression * 10.0), 0.0, 1.0);

        for (0..channels) |channel| {
            samples[i + channel] = sine_wave * fade_in * fade_out;
        }
    }

    return samples;
}

// TODO(Core)
fn keyToFrequency(key: mach.Core.Key) f32 {
    // The frequencies here just come from a piano frequencies chart. You can google for them.
    return switch (key) {
        // First row of piano keys, the highest.
        .q => 523.25, // C5
        .w => 587.33, // D5
        .e => 659.26, // E5
        .r => 698.46, // F5
        .t => 783.99, // G5
        .y => 880.0, // A5
        .u => 987.77, // B5
        .i => 1046.5, // C6
        .o => 1174.7, // D6
        .p => 1318.5, // E6
        .left_bracket => 1396.9, // F6
        .right_bracket => 1568.0, // G6

        // Second row of piano keys, the middle.
        .a => 261.63, // C4
        .s => 293.67, // D4
        .d => 329.63, // E4
        .f => 349.23, // F4
        .g => 392.0, // G4
        .h => 440.0, // A4
        .j => 493.88, // B4
        .k => 523.25, // C5
        .l => 587.33, // D5
        .semicolon => 659.26, // E5
        .apostrophe => 698.46, // F5

        // Third row of piano keys, the lowest.
        .z => 130.81, // C3
        .x => 146.83, // D3
        .c => 164.81, // E3
        .v => 174.61, // F3
        .b => 196.00, // G3
        .n => 220.0, // A3
        .m => 246.94, // B3
        .comma => 261.63, // C4
        .period => 293.67, // D4
        .slash => 329.63, // E5
        else => 0.0,
    };
}
