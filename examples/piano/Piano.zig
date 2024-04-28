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

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

pub const name = .piano;
pub const Mod = mach.Mod(@This());

pub const global_events = .{
    .init = .{ .handler = init },
    .deinit = .{ .handler = deinit },
    .tick = .{ .handler = tick },
    .audio_state_change = .{ .handler = audioStateChange },
};

pub const local_events = .{
    .init = .{ .handler = init },
    .tick = .{ .handler = tick },
};

pub const components = .{
    .play_after = .{ .type = f32 },
};

ghost_key_mode: bool = false,

fn init(audio: *mach.Audio.Mod, piano: *Mod) void {
    // Initialize audio module
    audio.send(.init, .{});

    // Initialize piano module state
    piano.init(.{});

    std.debug.print("controls:\n", .{});
    std.debug.print("[typing]     Play piano noises\n", .{});
    std.debug.print("[spacebar]   enable ghost-key mode (demonstrate seamless back-to-back sound playback)\n", .{});
    std.debug.print("[arrow up]   increase volume 10%\n", .{});
    std.debug.print("[arrow down] decrease volume 10%\n", .{});
}

fn deinit(audio: *mach.Audio.Mod) void {
    // Initialize audio module
    audio.send(.deinit, .{});
}

fn audioStateChange(
    audio: *mach.Audio.Mod,
    which: mach.EntityID,
    piano: *Mod,
) !void {
    if (audio.get(which, .playing) == false) {
        if (piano.get(which, .play_after)) |frequency| {
            // Play a new sound
            const entity = try audio.newEntity();
            try audio.set(entity, .samples, try fillTone(audio, frequency));
            try audio.set(entity, .playing, true);
            try audio.set(entity, .index, 0);
        }

        // Remove the entity for the old sound
        try audio.removeEntity(which);
    }
}

fn tick(
    core: *mach.Core.Mod,
    audio: *mach.Audio.Mod,
    piano: *Mod,
) !void {
    // TODO(Core)
    var iter = mach.core.pollEvents();
    while (iter.next()) |event| {
        switch (event) {
            .key_press => |ev| {
                const vol = try audio.state().player.volume();
                switch (ev.key) {
                    // Controls
                    .space => piano.state().ghost_key_mode = !piano.state().ghost_key_mode,
                    .down => try audio.state().player.setVolume(@max(0.0, vol - 0.1)),
                    .up => try audio.state().player.setVolume(@min(1.0, vol + 0.1)),

                    // Piano keys
                    else => {
                        // Play a new sound
                        const entity = try audio.newEntity();
                        try audio.set(entity, .samples, try fillTone(audio, keyToFrequency(ev.key)));
                        try audio.set(entity, .playing, true);
                        try audio.set(entity, .index, 0);

                        if (piano.state().ghost_key_mode) {
                            // After that sound plays, we'll chain on another sound that is one semi-tone higher.
                            const one_semi_tone_higher = keyToFrequency(ev.key) * math.pow(f32, 2.0, (1.0 / 12.0));
                            try piano.set(entity, .play_after, one_semi_tone_higher);
                        }
                    },
                }
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
fn keyToFrequency(key: mach.core.Key) f32 {
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
