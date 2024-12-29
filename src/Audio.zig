const std = @import("std");
const builtin = @import("builtin");
const mach = @import("main.zig");
const sysaudio = mach.sysaudio;

pub const Opus = @import("mach-opus");

const Audio = @This();

pub const mach_module = .mach_audio;

pub const mach_systems = .{ .init, .tick, .deinit };

/// The length of a @Vector(len, f32) used for SIMD mixing of audio buffers. Audio buffers must be
/// aligned to simd_vector_length * @sizeOf(f32).
pub const simd_vector_length = std.simd.suggestVectorLength(f32) orelse 1;

/// The number of f32s which should be reserved for padding at the start of an []f32 buffer, assuming
/// it is @alignOf(f32) / 4-byte aligned, in order to achieve @Vector(simd_vector_length, f32) alignment.
pub const simd_vector_f32_buffer_padding = (simd_vector_length - (4 % simd_vector_length)) % simd_vector_length;

const log = std.log.scoped(mach_module);

// The number of milliseconds worth of audio to render ahead of time. The lower this number is, the
// less latency there is in playing new audio. The higher this number is, the less chance there is
// of glitchy audio playback.
//
// By default, we use three times 1/60th of a second - i.e. 3 frames could drop before audio would
// stop playing smoothly assuming a 60hz application render rate.
ms_render_ahead: f32 = 16,

buffers: mach.Objects(
    .{},
    struct {
        /// The actual audio samples
        samples: []const f32 align(simd_vector_length),

        /// The number of channels in the samples buffer
        channels: u8,

        /// Volume multiplier
        volume: f32 = 1.0,

        /// Whether the buffer should be playing currently
        playing: bool = true,

        /// The currently playhead of the samples
        index: usize = 0,
    },
),

/// Whether to debug audio sync issues
debug: bool = false,

/// Callback which is ran when buffers change state from playing -> not playing
on_state_change: ?mach.FunctionID = null,

/// Audio player (has global volume controls)
player: sysaudio.Player,

// Internal fields
allocator: std.mem.Allocator,
ctx: sysaudio.Context,
output: SampleBuffer,
mixing_buffer: ?std.ArrayListUnmanaged(f32) = null,
shutdown: std.atomic.Value(bool) = .init(false),
mod: mach.Mod(Audio),
driver_needs_num_samples: usize = 0,

const SampleBuffer = std.fifo.LinearFifo(u8, .Dynamic);

pub fn init(audio: *Audio, audio_mod: mach.Mod(Audio)) !void {
    // TODO(allocator): find a better way for modules to get allocators
    const allocator = std.heap.c_allocator;

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

    audio.* = .{
        .buffers = audio.buffers,
        .allocator = allocator,
        .ctx = ctx,
        .player = player,
        .output = SampleBuffer.init(allocator),
        .debug = debug,
        .mod = audio_mod,
    };

    try player.start();
}

pub fn deinit(audio: *Audio) void {
    audio.shutdown.store(true, .release);
    audio.player.deinit();
    audio.ctx.deinit();
    if (audio.mixing_buffer) |*b| b.deinit(audio.allocator);
}

/// Audio.tick is called on the high-priority OS audio thread when the audio driver is waiting for
/// more audio samples because the audio.output buffer does not currently have enough to satisfy the
/// driver.
///
/// Its goal is to fill the audio.output buffer with enough samples to satisfy the immediate
/// requirements of the audio driver (audio.driver_needs_num_samples), and prepare some amount of
/// additional samples ahead of time to satisfy the driver in the future.
pub fn tick(audio: *Audio, audio_mod: mach.Mod(Audio)) !void {
    // If the other thread called deinit(), return.
    if (audio.shutdown.load(.acquire)) {
        return;
    }

    const allocator = audio.allocator;
    const player = &audio.player;
    const player_channels: u8 = @intCast(player.channels().len);
    const driver_needs = audio.driver_needs_num_samples;

    // How many audio samples we will render ahead by
    const samples_per_ms = @as(f32, @floatFromInt(player.sampleRate())) / 1000.0;
    const render_ahead: u32 = @as(u32, @intFromFloat(@trunc(audio.ms_render_ahead * samples_per_ms))) * player_channels;

    // Our goal is to satisfy the driver's immediate needs, plus prepare render_head number of samples.
    const goal_pre_rendered = driver_needs + render_ahead;

    const already_prepared = audio.output.readableLength() / player.format().size();
    const render_num_samples = if (already_prepared > goal_pre_rendered) 0 else goal_pre_rendered - already_prepared;
    if (render_num_samples < 0) @panic("invariant: Audio.tick ran when more audio samples are not needed");

    // Ensure our f32 mixing buffer has enough space for the samples we will render right now.
    // This will allocate to grow but never shrink.
    var mixing_buffer = if (audio.mixing_buffer) |*b| b else blk: {
        const b = try std.ArrayListUnmanaged(f32).initCapacity(allocator, simd_vector_f32_buffer_padding + render_num_samples);
        audio.mixing_buffer = b;
        break :blk &audio.mixing_buffer.?;
    };
    try mixing_buffer.resize(allocator, simd_vector_f32_buffer_padding + render_num_samples); // grows, but never shrinks

    // Zero the mixing buffer to silence: if no audio is mixed in below, then we want silence
    // not undefined memory noise.
    @memset(mixing_buffer.items, 0);

    var did_state_change = false;
    {
        audio.buffers.lock();
        defer audio.buffers.unlock();

        var buffers = audio.buffers.slice();
        while (buffers.next()) |buf_id| {
            var buffer = audio.buffers.getValue(buf_id);
            if (!buffer.playing) continue;
            defer audio.buffers.setValue(buf_id, buffer);

            const channels_diff = player_channels - buffer.channels + 1;
            const mixing_buffer_len = mixing_buffer.items.len - simd_vector_f32_buffer_padding;
            const to_read = (@min(buffer.samples.len - buffer.index, mixing_buffer_len - simd_vector_f32_buffer_padding) / channels_diff) + @rem(@min(buffer.samples.len - buffer.index, mixing_buffer_len), channels_diff);
            if (buffer.channels == 1 and player_channels > 1) {
                // Duplicate samples for mono sounds
                var i: usize = simd_vector_f32_buffer_padding;
                for (buffer.samples[buffer.index..][0..to_read]) |sample| {
                    mixSamplesDuplicate(mixing_buffer.items[i..][0..player_channels], sample * buffer.volume);
                    i += player_channels;
                }
            } else {
                mixSamples(mixing_buffer.items[simd_vector_f32_buffer_padding..to_read], buffer.samples[buffer.index..][0..to_read], buffer.volume);
            }

            if (buffer.index + to_read >= buffer.samples.len) {
                // No longer playing, we've read all samples
                did_state_change = true;
                buffer.playing = false;
                buffer.index = 0;
            } else buffer.index = buffer.index + to_read;
        }
    }
    if (did_state_change) if (audio.on_state_change) |f| audio_mod.run(f);

    // Write our rendered samples to the fifo, expanding its size as needed and converting our f32
    // samples to the format the driver expects.
    const out_buffer_len = render_num_samples * player.format().size();
    const out_buffer = try audio.output.writableWithSize(out_buffer_len); // TODO(audio): handle potential OOM here better
    std.debug.assert((mixing_buffer.items.len - simd_vector_f32_buffer_padding) == render_num_samples);
    sysaudio.convertTo(
        f32,
        mixing_buffer.items[simd_vector_f32_buffer_padding..],
        player.format(),
        out_buffer[0..out_buffer_len], // writableWithSize may return a larger slice than needed
    );
    audio.output.update(out_buffer_len);
}

/// Called by the system audio driver when the output buffer needs to be filled. Called on a
/// dedicated OS thread for high-priority audio. Its goal is to fill the output buffer as quickly
/// as possible and return, else audio skips will occur.
fn writeFn(audio_opaque: ?*anyopaque, output: []u8) void {
    const audio: *Audio = @ptrCast(@alignCast(audio_opaque));
    const format_size = audio.player.format().size();

    // If the other thread called deinit(), write zeros to the buffer (no sound) and return.
    if (audio.shutdown.load(.acquire)) {
        @memset(output, 0);
        return;
    }

    // Do we have enough audio samples in our audio.output buffer to fill the output buffer?
    //
    // This is the most common case, because audio.output should have much more data prepared
    // ahead of time than what the audio driver needs.
    var read_slice = audio.output.readableSlice(0);
    if (read_slice.len >= output.len) {
        if (read_slice.len > output.len) read_slice = read_slice[0..output.len];
        @memcpy(output[0..read_slice.len], read_slice);
        audio.output.discard(read_slice.len);
        return;
    }

    // At this point, we don't have enough audio data prepared in our audio.output buffer. so we
    // must prepare it now.
    while (true) {
        // Run the audio tick function, which should fill the audio.output buffer with more audio
        // samples.
        audio.driver_needs_num_samples = @divExact(output.len, format_size);
        audio.mod.call(.tick);

        // Check if we now have enough data in our audio.output buffer. If we do, then we're done.
        read_slice = audio.output.readableSlice(0);
        if (read_slice.len >= output.len) {
            if (read_slice.len > output.len) read_slice = read_slice[0..output.len];
            @memcpy(output[0..read_slice.len], read_slice);
            audio.output.discard(read_slice.len);
            return;
        }

        // The audio tick didn't produce enough data, this might indicate some subtle mismatch in
        // the audio tick function not producing a multiple of the audio driver's actual buffer
        // size.
        if (audio.debug) log.debug("resync, found {} samples but need {} (nano timestamp {})", .{
            @divExact(read_slice.len, format_size),
            @divExact(output.len, format_size),
            std.time.nanoTimestamp(),
        });

        // If the other thread called deinit(), write zeros to the buffer (no sound) and return.
        if (audio.shutdown.load(.acquire)) {
            @memset(output, 0);
            return;
        }
    }
}

inline fn mixSamples(
    a: []align(simd_vector_length) f32,
    b: []align(simd_vector_length) const f32,
    volume: f32,
) void {
    std.debug.assert(a.len >= b.len);
    const Vec = @Vector(simd_vector_length, f32);
    const vec_blocks_len = b.len - (b.len % simd_vector_length);
    var i: usize = 0;
    while (i < vec_blocks_len) : (i += simd_vector_length) {
        const b_vec: Vec = b[i..][0..simd_vector_length].*;
        const a_vec: *Vec = @ptrCast(@alignCast(a[i..][0..simd_vector_length]));
        a_vec.* += b_vec * @as(Vec, @splat(volume));
    }
}

inline fn mixSamplesDuplicate(a: []align(simd_vector_length) f32, b: f32) void {
    const Vec = @Vector(simd_vector_length, f32);
    const vec_blocks_len = a.len - (a.len % simd_vector_length);
    var i: usize = 0;
    while (i < vec_blocks_len) : (i += simd_vector_length) {
        const a_vec: *Vec = @ptrCast(@alignCast(a[i..][0..simd_vector_length]));
        a_vec.* += @as(Vec, @splat(b));
    }
}
