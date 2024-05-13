const std = @import("std");
const builtin = @import("builtin");
const mach = @import("main.zig");
const sysaudio = mach.sysaudio;

pub const Opus = @import("mach-opus");

pub const name = .mach_audio;
pub const Mod = mach.Mod(@This());

pub const components = .{
    .samples = .{ .type = []const f32 },
    .channels = .{ .type = u8 },
    .playing = .{ .type = bool },
    .index = .{ .type = usize },
};

pub const systems = .{
    .init = .{ .handler = init },
    .deinit = .{ .handler = deinit },
    .audio_tick = .{ .handler = audioTick },
};

const log = std.log.scoped(name);

// The number of milliseconds worth of audio to render ahead of time. The lower this number is, the
// less latency there is in playing new audio. The higher this number is, the less chance there is
// of glitchy audio playback.
//
// By default, we use three times 1/60th of a second - i.e. 3 frames could drop before audio would
// stop playing smoothly assuming a 60hz application render rate.
ms_render_ahead: f32 = 16,

allocator: std.mem.Allocator,
ctx: sysaudio.Context,
player: sysaudio.Player,
on_state_change: ?mach.AnySystem = null,
output_mu: std.Thread.Mutex = .{},
output: SampleBuffer,
mixing_buffer: ?std.ArrayListUnmanaged(f32) = null,
render_num_samples: usize = 0,
debug: bool = false,
running_mu: std.Thread.Mutex = .{},
running: bool = true,

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

const SampleBuffer = std.fifo.LinearFifo(u8, .Dynamic);

fn init(audio: *Mod) !void {
    const allocator = gpa.allocator();
    const ctx = try sysaudio.Context.init(null, allocator, .{});
    try ctx.refresh();

    // TODO(audio): let people handle these errors
    // TODO(audio): enable selecting non-default devices
    const device = ctx.defaultDevice(.playback) orelse return error.NoDeviceFound;
    var player = try ctx.createPlayer(device, writeFn, .{ .user_data = audio, .sample_rate = 48000 });
    log.info("opened audio device: channels={} sample_rate={} format={s}", .{ player.channels().len, player.sampleRate(), @tagName(player.format()) });

    const debug_str = std.process.getEnvVarOwned(
        allocator,
        "MACH_DEBUG_AUDIO",
    ) catch |err| switch (err) {
        error.EnvironmentVariableNotFound => null,
        else => return err,
    };
    const debug = if (debug_str) |s| blk: {
        defer allocator.free(s);
        break :blk std.ascii.eqlIgnoreCase(s, "true");
    } else false;

    audio.init(.{
        .allocator = allocator,
        .ctx = ctx,
        .player = player,
        .output = SampleBuffer.init(allocator),
        .debug = debug,
    });

    try player.start();
}

fn deinit(audio: *Mod) void {
    audio.state().running_mu.lock();
    defer audio.state().running_mu.unlock();
    audio.state().running = false;

    audio.state().player.deinit();
    audio.state().ctx.deinit();
    if (audio.state().mixing_buffer) |*b| b.deinit(audio.state().allocator);
}

/// .audio_tick is sent whenever the audio driver requests more audio samples to output to the
/// speakers. Usually the driver is requesting a small amount of samples, e.g. ~4096 samples.
///
/// The audio driver asks for more samples on a different, often high-priority OS thread. It does
/// not block waiting for .audio_tick to be dispatched, instead it simply returns whatever samples
/// are already prepared in the audio.state().output buffer ahead of time. This ensures that even
/// if the system is under heavy load, or a few frames are particularly slow, that audio
/// (hopefully) continues playing uninterrupted.
///
/// The goal of this event handler, then, is to prepare enough audio samples ahead of time in the
/// audio.state().output buffer that feed the driver so it does not get hungry and play silence
/// instead. At the same time, we don't want to play too far ahead as that would cause latency
/// between e.g. user interactions and audio actually playing - so in practice the amount we play
/// ahead is rather small and imperceivable to most humans.
fn audioTick(entities: *mach.Entities.Mod, audio: *Mod) !void {
    audio.state().running_mu.lock();
    const running = audio.state().running;
    const driver_expects = audio.state().render_num_samples; // How many samples the driver last expected us to produce.
    audio.state().running_mu.unlock();
    if (!running) return; // Scheduled by the other thread e.g. right before .deinit, ignore it.

    const allocator = audio.state().allocator;
    const player = &audio.state().player;
    const player_channels: u8 = @intCast(player.channels().len);

    // How many audio samples we will render ahead by
    const samples_per_ms = @as(f32, @floatFromInt(player.sampleRate())) / 1000.0;
    const render_ahead: u32 = @as(u32, @intFromFloat(@trunc(audio.state().ms_render_ahead * samples_per_ms))) * player_channels;

    // Our goal is to ensure that we always have pre-rendered the number of samples the driver last
    // expected, expects, plus the play ahead amount.
    const goal_pre_rendered = driver_expects + render_ahead;

    audio.state().output_mu.lock();
    const already_prepared = audio.state().output.readableLength() / player.format().size();
    const render_num_samples = if (already_prepared > goal_pre_rendered) 0 else goal_pre_rendered - already_prepared;
    audio.state().output_mu.unlock();

    if (render_num_samples < 0) return; // we do not need to render more audio right now

    // Ensure our f32 mixing buffer has enough space for the samples we will render right now.
    // This will allocate to grow but never shrink.
    var mixing_buffer = if (audio.state().mixing_buffer) |*b| b else blk: {
        const b = try std.ArrayListUnmanaged(f32).initCapacity(allocator, render_num_samples);
        audio.state().mixing_buffer = b;
        break :blk &audio.state().mixing_buffer.?;
    };
    try mixing_buffer.resize(allocator, render_num_samples); // grows, but never shrinks

    // Zero the mixing buffer to silence: if no audio is mixed in below, then we want silence
    // not undefined memory.
    @memset(mixing_buffer.items, 0);

    var did_state_change = false;
    var q = try entities.query(.{
        .samples_slices = Mod.read(.samples),
        .channels = Mod.read(.channels),
        .playings = Mod.write(.playing),
        .indexes = Mod.write(.index),
    });
    while (q.next()) |v| {
        for (v.samples_slices, v.channels, v.playings, v.indexes) |samples, channels, *playing, *index| {
            if (!playing.*) continue;

            const channels_diff = player_channels - channels + 1;
            const to_read = @min(samples.len - index.*, mixing_buffer.items.len) / channels_diff;
            if (channels == 1 and player_channels > 1) {
                // Duplicate samples for mono sounds
                var i: usize = 0;
                for (samples[index.*..][0..to_read]) |sample| {
                    mixSamplesDuplicate(mixing_buffer.items[i..][0..player_channels], sample);
                    i += player_channels;
                }
            } else {
                mixSamples(mixing_buffer.items[0..to_read], samples[index.*..][0..to_read]);
            }

            if (index.* + to_read >= samples.len) {
                // No longer playing, we've read all samples
                did_state_change = true;
                playing.* = false;
                index.* = 0;
                continue;
            }
            index.* = index.* + to_read;
        }
    }
    if (audio.state().on_state_change) |on_state_change_event| {
        if (did_state_change) audio.scheduleAny(on_state_change_event);
    }

    // Write our rendered samples to the fifo, expanding its size as needed and converting our f32
    // samples to the format the driver expects.
    // TODO(audio): handle potential OOM here
    audio.state().output_mu.lock();
    defer audio.state().output_mu.unlock();
    const out_buffer_len = render_num_samples * player.format().size();
    const out_buffer = try audio.state().output.writableWithSize(out_buffer_len);
    std.debug.assert(mixing_buffer.items.len == render_num_samples);
    sysaudio.convertTo(
        f32,
        mixing_buffer.items,
        player.format(),
        out_buffer[0..out_buffer_len], // writableWithSize may return a larger slice than needed
    );
    audio.state().output.update(out_buffer_len);
}

// Callback invoked on the audio thread
fn writeFn(audio_opaque: ?*anyopaque, output: []u8) void {
    const audio: *Mod = @ptrCast(@alignCast(audio_opaque));

    // Make sure any audio.state() we access is covered by a mutex so it is not accessed during
    // .deinit in the main thread.
    audio.state().running_mu.lock();

    const running = audio.state().running;
    if (!running) {
        audio.state().running_mu.unlock();
        @memset(output, 0);
        return;
    }
    const format_size = audio.state().player.format().size();
    const render_num_samples = @divExact(output.len, format_size);
    audio.state().render_num_samples = render_num_samples;

    audio.state().running_mu.unlock();

    // Notify that we are writing audio frames now
    //
    // Note that we do not *wait* at all for .audio_tick to complete, this is an asynchronous
    // dispatch of the event. The expectation is that audio.state().output already has enough
    // samples in it that we can return right now. The event is just a signal dispatched on another
    // thread to enable reacting to audio events in realtime.
    audio.schedule(.audio_tick);

    // Read the prepared audio samples and directly @memcpy them to the output buffer.
    audio.state().output_mu.lock();
    defer audio.state().output_mu.unlock();
    var read_slice = audio.state().output.readableSlice(0);
    if (read_slice.len < output.len) {
        // We do not have enough audio data prepared. Busy-wait until we do, otherwise the audio
        // thread may become de-sync'd with the loop responsible for producing it.
        audio.schedule(.audio_tick);
        if (audio.state().debug) log.debug("resync, found {} samples but need {} (nano timestamp {})", .{ read_slice.len / format_size, output.len / format_size, std.time.nanoTimestamp() });

        audio.state().output_mu.unlock();
        l: while (true) {
            audio.state().output_mu.lock();
            if (audio.state().output.readableLength() >= output.len) {
                read_slice = audio.state().output.readableSlice(0);
                break :l;
            }
            audio.state().output_mu.unlock();

            // Handle potential exit
            audio.state().running_mu.lock();
            if (!audio.state().running) {
                audio.state().running_mu.unlock();
                @memset(output, 0);
                return;
            }
        }
    }
    if (read_slice.len > output.len) {
        read_slice = read_slice[0..output.len];
    }
    @memcpy(output[0..read_slice.len], read_slice);
    audio.state().output.discard(read_slice.len);
}

// TODO(audio): remove this switch, currently ReleaseFast/ReleaseSmall have some weird behavior if
// we use suggestVectorLength
const vector_length = switch (builtin.mode) {
    .Debug, .ReleaseSafe => std.simd.suggestVectorLength(f32),
    else => null,
};

inline fn mixSamples(a: []f32, b: []const f32) void {
    std.debug.assert(a.len >= b.len);

    var i: usize = 0;

    // use SIMD when available
    if (vector_length) |vec_len| {
        const Vec = @Vector(vec_len, f32);
        const vec_blocks_len = b.len - (b.len % vec_len);

        while (i < vec_blocks_len) : (i += vec_len) {
            const b_vec: Vec = b[i..][0..vec_len].*;
            a[i..][0..vec_len].* += b_vec;
        }
    }

    for (a[i..b.len], b[i..]) |*a_sample, b_sample| {
        a_sample.* += b_sample;
    }
}

inline fn mixSamplesDuplicate(a: []f32, b: f32) void {
    var i: usize = 0;

    // use SIMD when available
    if (vector_length) |vec_len| {
        const vec_blocks_len = a.len - (a.len % vec_len);
        while (i < vec_blocks_len) : (i += vec_len) {
            a[i..][0..vec_len].* += @as(@Vector(vec_len, f32), @splat(b));
        }
    }

    for (a[i..]) |*a_sample| {
        a_sample.* += b;
    }
}
