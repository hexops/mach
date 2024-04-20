const std = @import("std");
const sysmidi = @import("mach").sysmidi;
const sysaudio = @import("mach").sysaudio;

const App = struct {
    midi_client: sysmidi.Client,
    audio_ctx: sysaudio.Context,
    player: sysaudio.Player,
    playing: [512]Tone = std.mem.zeroes([512]Tone),
    keys: [88]bool = std.mem.zeroes([88]bool),
    rng: std.rand.DefaultPrng = std.rand.DefaultPrng.init(1337),
    r: f32 = 0.0,
    beast_mode: bool = false,
    insanity_mode: bool = false,

    fn init(app: *App, allocator: std.mem.Allocator) !void {
        app.* = .{
            .midi_client = undefined,
            .audio_ctx = undefined,
            .player = undefined,
        };

        // Initialize system audio
        app.audio_ctx = try sysaudio.Context.init(null, allocator, .{});
        errdefer app.audio_ctx.deinit();
        try app.audio_ctx.refresh();

        // Create a system audio playback device
        const device = app.audio_ctx.defaultDevice(.playback) orelse return error.NoDeviceFound;
        app.player = try app.audio_ctx.createPlayer(device, writeFn, .{ .user_data = app });
        errdefer app.player.deinit();
        try app.player.start();

        // Initialize midi client
        app.midi_client = sysmidi.Client.init();
        errdefer app.midi_client.deinit();
        try app.midi_client.open(.{
            .user_ctx = app,
            .on_midi_event = onMidiEvent,
        });
    }

    fn deinit(app: *App) void {
        app.player.deinit();
        app.audio_ctx.deinit();
        app.midi_client.deinit();
    }

    pub fn renderTUI(app: *App) void {
        std.debug.print("{s}", .{@embedFile("ziguana.txt")});
        var line: usize = 0;
        while (line < 7) : (line += 1) {
            if (line == 0) {
                var i: usize = 0;
                while (i < (88 * 2) + 1) : (i += 1) {
                    std.debug.print("_", .{});
                }
                std.debug.print("\n", .{});
            } else {
                var i: usize = 0;
                while (i < (88 * 2) + 1) : (i += 1) {
                    const idx = i / 2;
                    const wk = idx % 12; // hand / octave index
                    const white_key = (wk == 0 or wk == 2 or wk == 3 or wk == 5 or wk == 7 or wk == 8 or wk == 10);
                    const edge = (i % 2) == 0;
                    if (edge) { //} and (idx == 88 or !app.keys[idx])) {
                        std.debug.print("|", .{});
                    } else if ((white_key and line == 6) or (!white_key and line == 4)) {
                        std.debug.print("_", .{});
                    } else {
                        if (app.keys[idx]) {
                            std.debug.print(" ", .{});
                        } else if (!white_key and line > 4) {
                            std.debug.print(" ", .{});
                        } else {
                            std.debug.print("%", .{});
                        }
                    }

                    // __________________________________________________________________________________
                    // |@|@| | | | | |
                    // |@|@| | | | | |
                    // |@|@| | | | | |
                    // |@|_| |_| |_| |
                    // |@| | | | | | |
                    // |_| |_| |_| |_|

                }
                std.debug.print("\n", .{});
            }
        }
    }

    pub fn keyHit(app: *App, key: u8, velocity: u8) void {
        // Graphics
        const piano_key = key -% 21;
        std.debug.print("key: {}\n", .{piano_key});
        if (piano_key >= 0 and piano_key <= 88) {
            app.keys[piano_key] = true;
            app.renderTUI();
        }

        // Functionality
        app.r = app.rng.random().float(f32);
        const key_440hz = 69.0; // midi key for C4
        const relative_key: f32 = @as(f32, @floatFromInt(key)) - key_440hz;
        if (relative_key == 38) {
            app.insanity_mode = !app.insanity_mode;
        }
        if (relative_key == 39) {
            app.beast_mode = !app.beast_mode;
        }
        const frequency: f32 = 440.0 * std.math.pow(f32, 2, relative_key / 12.0);

        for (&app.playing) |*tone| {
            if (!tone.active) {
                tone.* = Tone{
                    .frequency = frequency,
                    .active = true,
                    .key = key,
                    .closed = 0,
                    .sample_counter = 0,
                    .velocity = @as(f32, @floatFromInt(velocity)) / (256.0 / 2.0),
                };
                return;
            }
        }
    }

    pub fn keyClose(app: *App, key: u8, velocity: u8) void {
        _ = velocity;

        // Graphics
        const piano_key = key -% 21;
        if (piano_key >= 0 and piano_key <= 88) {
            app.keys[piano_key] = false;
            app.renderTUI();
        }

        // Functionality
        for (&app.playing) |*tone| {
            if (tone.active and tone.closed == 0 and tone.key == key) {
                tone.closed = tone.sample_counter;
                return;
            }
        }
    }

    pub fn onMidiEvent(user_ctx: ?*anyopaque, ev: sysmidi.Event) void {
        var app: *App = @ptrCast(@alignCast(user_ctx));
        switch (ev) {
            .channel => |ch| switch (ch) {
                .note_on => |v| {
                    app.keyHit(v.key, v.velocity);
                },
                .note_off => |v| {
                    app.keyClose(v.key, v.velocity);
                },
            },
        }
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var app: App = undefined;
    try app.init(allocator);
    defer app.deinit();

    // TODO: blocking!
}

const Tone = struct {
    frequency: f32,
    active: bool,
    key: u8,
    closed: usize,
    sample_counter: usize,
    velocity: f32,
};

fn writeFn(app_op: ?*anyopaque, frames: usize) void {
    const app: *App = @as(*App, @ptrCast(@alignCast(app_op)));

    const r = app.r;
    var frame: usize = 0;
    while (frame < frames) : (frame += 1) {
        const sample_rate = @as(f32, @floatFromInt(app.player.sampleRate()));
        app.r += 1.0 / (sample_rate * 10.0);

        var sample: f32 = 0;
        for (&app.playing) |*tone| {
            if (!tone.active) continue;

            // Tone ending / fade out handling.
            const fade_out_duration_seconds = 0.5;
            const fade_out_duration_frames: f32 = fade_out_duration_seconds * sample_rate;
            const frames_since_close: f32 = @floatFromInt(tone.sample_counter - tone.closed);
            // 0.0 if not fading out at all (tone start or open) to 1.0 (tone end / faded out completely)
            const fade_out_progression = if (tone.closed == 0) 0.0 else frames_since_close / fade_out_duration_frames;
            if (fade_out_progression >= 1.0) {
                tone.active = false; // completely faded out, this tone has ended
            }

            // A number ranging from 1.0 to 0.0 based on the progression of fade out.
            const fade_out = 1.0 - std.math.clamp(std.math.log10(fade_out_progression * 10.0), 0.0, 1.0);

            tone.sample_counter += 1;
            const sample_counter = @as(f32, @floatFromInt(tone.sample_counter));

            // const noise = std.math.cos(sample_counter / (sample_rate / 100.0));
            // std.debug.print("noise: {}\n", .{noise});
            // const frequency = tone.frequency + (std.math.cos(sample_counter / 100.0));

            // The sine wave that plays the frequency.
            // const sine_wave = std.math.sin(tone.frequency * 2.0 * std.math.pi * sample_counter / sample_rate) * gain;

            // Piano-sounding wave.
            const f2pit = tone.frequency * 2.0 * std.math.pi * (sample_counter / sample_rate);
            var piano = std.math.sin(f2pit) * std.math.exp(-0.0004 * f2pit);

            // overtones
            const overtone_factor = ((@max(tone.velocity - 0.2, 0.0)) * 2.0);
            // const overtone_factor = 1.0;
            var overtone: f32 = 0.0;
            var double: f32 = 2.0;
            while (overtone < 4.0) : (overtone += 1.0) {
                // std.debug.print("hm: {d}\n", .{std.math.cos(sample_counter / sample_rate)});
                // const wave = std.math.cos(std.math.clamp((sample_counter / sample_rate) * (overtone_factor * 10.0), 0.0, 10.0) + 2.5) / 10.0;
                // piano += (std.math.sin((1.0 + (overtone * (1.0 - wave))) * f2pit) * std.math.exp(-0.0004 * f2pit) / double);
                var wave: f32 = 0.5;
                if (app.beast_mode) {
                    wave = std.math.clamp((std.math.sin(r) * overtone_factor), 0.0, 1.5);
                }
                // std.debug.print("hm: {d}, {d}\n", .{ tone.velocity, overtone_factor });
                piano += (std.math.sin(((1.0 + overtone) * f2pit) * wave) * std.math.exp(-0.0002 * f2pit) / double) * overtone_factor;
                if (app.beast_mode) {
                    double = double + double * 2.0;
                } else {
                    double = double + double;
                }
            }
            // piano += (std.math.sin(3.0 * f2pit) * std.math.exp(-0.0004 * f2pit) / 4.0) * overtone_factor;
            // piano += (std.math.sin(4.0 * f2pit) * std.math.exp(-0.0004 * f2pit) / 8.0) * overtone_factor;
            // piano += (std.math.sin(5.0 * f2pit) * std.math.exp(-0.0004 * f2pit) / 16.0) * overtone_factor;
            // piano += (std.math.sin(6.0 * f2pit) * std.math.exp(-0.0004 * f2pit) / 32.0) * overtone_factor;
            // std.debug.print("velocity: {d}\n", .{tone.velocity});

            // piano += piano * piano * piano; // saturation

            const gain = 0.1 * std.math.clamp(overtone_factor, 0.0, 1.0);
            piano *= gain;

            if (app.insanity_mode) {
                const T = u8;
                const max_t: f32 = @floatFromInt(std.math.maxInt(T));
                piano = @as(f32, @floatFromInt(@as(T, @intFromFloat(std.math.clamp(piano, 0.0, 1.0) * max_t)))) / max_t;
            }

            sample += piano * fade_out;
            //
            // sample = sample * (sample_counter / sample_rate);

            // const duration = @as(f32, @floatFromInt(tone.duration));
            // // A number ranging from 0.0 to 1.0 in the first 1/64th of the duration of the tone.
            // const fade_in = @min(sample_counter / (duration / 64.0), 1.0);

            // // A number ranging from 1.0 to 0.0 over half the duration of the tone.
            // const progression = sample_counter / duration; // 0.0 (tone start) to 1.0 (tone end)
            // const fade_out = 1.0 - std.math.clamp(std.math.log10(progression * 10.0), 0.0, 1.0);

            // // Mix this tone into the sample we'll actually play on e.g. the speakers, reducing
            // // sine wave intensity if we're fading in or out over the entire duration of the
            // // tone.
            // sample += sine_wave * fade_in * fade_out;
        }

        // Emit the sample on all channels.
        app.player.writeAll(frame, sample);
    }
}
