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

pub const App = @This();

// TODO: banish global allocator
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

pub const name = .app;
pub const Mod = mach.Mod(@This());

pub const systems = .{
    .start = .{ .handler = start },
    .init = .{ .handler = init },
    .deinit = .{ .handler = deinit },
    .tick = .{ .handler = tick },
    .audio_state_change = .{ .handler = audioStateChange },
};

pub const components = .{
    .play_after = .{ .type = f32 },
};

ghost_key_mode: bool = false,

fn start(core: *mach.Core.Mod, audio: *mach.Audio.Mod, app: *Mod) void {
    core.schedule(.init);
    audio.schedule(.init);
    app.schedule(.init);
}

fn init(core: *mach.Core.Mod, audio: *mach.Audio.Mod, app: *Mod) void {
    core.state().on_tick = app.system(.tick);
    core.state().on_exit = app.system(.deinit);

    // Configure the audio module to send our app's .audio_state_change event when an entity's sound
    // finishes playing.
    audio.state().on_state_change = app.system(.audio_state_change);

    // Initialize piano module state
    app.init(.{});

    std.debug.print("controls:\n", .{});
    std.debug.print("[typing]     Play piano noises\n", .{});
    std.debug.print("[spacebar]   enable ghost-key mode (demonstrate seamless back-to-back sound playback)\n", .{});
    std.debug.print("[arrow up]   increase volume 10%\n", .{});
    std.debug.print("[arrow down] decrease volume 10%\n", .{});

    core.schedule(.start);
}

fn deinit(core: *mach.Core.Mod, audio: *mach.Audio.Mod) void {
    audio.schedule(.deinit);
    core.schedule(.deinit);
}

fn audioStateChange(
    entities: *mach.Entities.Mod,
    audio: *mach.Audio.Mod,
    app: *Mod,
) !void {
    // Find audio entities that are no longer playing
    var q = try entities.query(.{
        .ids = mach.Entities.Mod.read(.id),
        .playings = mach.Audio.Mod.read(.playing),
    });
    while (q.next()) |v| {
        for (v.ids, v.playings) |id, playing| {
            if (playing) continue;

            if (app.get(id, .play_after)) |frequency| {
                // Play a new sound
                const e = try entities.new();
                try audio.set(e, .samples, try fillTone(audio, frequency));
                try audio.set(e, .channels, @intCast(audio.state().player.channels().len));
                try audio.set(e, .playing, true);
                try audio.set(e, .index, 0);
            }

            // Remove the entity for the old sound
            try entities.remove(id);
        }
    }
}

fn tick(
    entities: *mach.Entities.Mod,
    core: *mach.Core.Mod,
    audio: *mach.Audio.Mod,
    app: *Mod,
) !void {
    // TODO(Core)
    var iter = core.state().pollEvents();
    while (iter.next()) |event| {
        switch (event) {
            .key_press => |ev| {
                switch (ev.key) {
                    // Controls
                    .space => app.state().ghost_key_mode = !app.state().ghost_key_mode,
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

                    // Piano keys
                    else => {
                        // Play a new sound
                        const e = try entities.new();
                        try audio.set(e, .samples, try fillTone(audio, keyToFrequency(ev.key)));
                        try audio.set(e, .channels, @intCast(audio.state().player.channels().len));
                        try audio.set(e, .playing, true);
                        try audio.set(e, .index, 0);

                        if (app.state().ghost_key_mode) {
                            // After that sound plays, we'll chain on another sound that is one semi-tone higher.
                            const one_semi_tone_higher = keyToFrequency(ev.key) * math.pow(f32, 2.0, (1.0 / 12.0));
                            try app.set(e, .play_after, one_semi_tone_higher);
                        }
                    },
                }
            },
            .close => core.schedule(.exit),
            else => {},
        }
    }

    // Grab the back buffer of the swapchain
    // TODO(Core)
    const back_buffer_view = core.state().swap_chain.getCurrentTextureView().?;
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
    defer render_pass.release();

    // Draw nothing

    // Finish render pass
    render_pass.end();

    // Submit our commands to the queue
    var command = encoder.finish(&.{ .label = label });
    defer command.release();
    core.state().queue.submit(&[_]*gpu.CommandBuffer{command});

    // Present the frame
    core.schedule(.present_frame);
}

fn fillTone(audio: *mach.Audio.Mod, frequency: f32) ![]const f32 {
    const channels = audio.state().player.channels().len;
    const sample_rate: f32 = @floatFromInt(audio.state().player.sampleRate());
    const duration: f32 = 1.5 * @as(f32, @floatFromInt(channels)) * sample_rate; // play the tone for 1.5s
    const gain = 0.1;

    const samples = try gpa.allocator().alloc(f32, @intFromFloat(duration));

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
