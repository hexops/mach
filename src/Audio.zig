const std = @import("std");
const builtin = @import("builtin");
const mach = @import("main.zig");
const sysaudio = mach.sysaudio;

pub const name = .mach_audio;
pub const Mod = mach.Mod(@This());

pub const components = .{
    .samples = .{ .type = []const f32 },
    .playing = .{ .type = bool },
    .index = .{ .type = usize },
};

pub const local_events = .{
    .init = .{ .handler = init },
    .render = .{ .handler = render },
};

allocator: std.mem.Allocator,
ctx: sysaudio.Context,
player: sysaudio.Player,
mixing_buffer: []f32,
buffer: SampleBuffer = SampleBuffer.init(),
mutex: std.Thread.Mutex = .{},
cond: std.Thread.Condition = .{},

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

// Enough space to hold 30ms of audio @ 48000hz, f32 audio samples, 6 channels
//
// This buffer is only used to transfer samples from the .render event handler to the audio thread,
// so it being larger than needed introduces no latency but it being smaller than needed could block
// the .render event handler.
pub const SampleBuffer = std.fifo.LinearFifo(f32, .{ .Static = 48000 * 0.03 * @sizeOf(f32) * 6 });

fn init(audio: *Mod) !void {
    const allocator = gpa.allocator();
    const ctx = try sysaudio.Context.init(null, allocator, .{});
    try ctx.refresh();

    // TODO(audio): let people handle these errors
    // TODO(audio): enable selecting non-default devices
    const device = ctx.defaultDevice(.playback) orelse return error.NoDeviceFound;
    // TODO(audio): allow us to set user_data after creation of the player, so that we do not need
    // __state access.

    var player = try ctx.createPlayer(device, writeFn, .{ .user_data = &audio.__state });

    const frame_size = @sizeOf(f32) * player.channels().len; // size of an audio frame
    const sample_rate = player.sampleRate(); // number of samples per second
    const sample_rate_ms = sample_rate / 1000; // number of samples per ms

    // A 30ms buffer of audio that we will use to store mixed samples before sending them to the
    // audio thread for playback.
    //
    // TODO(audio): enable audio rendering loop to run at different frequency to reduce this buffer
    // size and reduce latency.
    const mixing_buffer = try allocator.alloc(f32, 30 * sample_rate_ms * frame_size);

    audio.init(.{
        .allocator = allocator,
        .ctx = ctx,
        .player = player,
        .mixing_buffer = mixing_buffer,
    });

    try player.start();
}

fn deinit(audio: *Mod) void {
    audio.state().player.deinit();
    audio.state().ctx.deinit();
    audio.state().allocator.free(audio.state().mixing_buffer);

    var archetypes_iter = audio.entities.query(.{ .all = &.{
        .{ .mach_audio = &.{.samples} },
    } });
    while (archetypes_iter.next()) |archetype| {
        const samples = archetype.slice(.mach_audio, .samples);
        for (samples) |buf| buf.deinit(audio.state().allocator);
    }
}

fn render(audio: *Mod) !void {
    // Prepare the next buffer of mixed audio by querying entities and mixing the samples they want
    // to play.
    var mixing_buffer = audio.state().mixing_buffer;
    @memset(mixing_buffer, 0);
    var max_samples: usize = 0;

    var archetypes_iter = audio.entities.query(.{ .all = &.{
        .{ .mach_audio = &.{ .samples, .playing, .index } },
    } });
    while (archetypes_iter.next()) |archetype| {
        for (
            archetype.slice(.entity, .id),
            archetype.slice(.mach_audio, .samples),
            archetype.slice(.mach_audio, .playing),
            archetype.slice(.mach_audio, .index),
        ) |id, samples, playing, index| {
            if (!playing) continue;

            const to_read = @min(samples.len - index, mixing_buffer.len);
            mixSamples(mixing_buffer[0..to_read], samples[index..][0..to_read]);
            max_samples = @max(max_samples, to_read);
            if (index + to_read >= samples.len) {
                // No longer playing, we've read all samples
                try audio.set(id, .playing, false);
                try audio.set(id, .index, 0);
                continue;
            }
            try audio.set(id, .index, index + to_read);
        }
    }

    // Write our mixed buffer to the audio thread via the sample buffer.
    audio.state().mutex.lock();
    defer audio.state().mutex.unlock();
    while (audio.state().buffer.writableLength() < max_samples) {
        audio.state().cond.wait(&audio.state().mutex);
    }
    audio.state().buffer.writeAssumeCapacity(mixing_buffer[0..max_samples]);
}

// Callback invoked on the audio thread.
fn writeFn(audio_opaque: ?*anyopaque, output: []u8) void {
    const audio: *@This() = @ptrCast(@alignCast(audio_opaque));

    // Clear buffer from previous samples
    @memset(output, 0);

    const total_samples = @divExact(output.len, audio.player.format().size());

    var i: usize = 0;
    while (i < total_samples) {
        audio.mutex.lock();
        defer audio.mutex.unlock();

        const read_slice = audio.buffer.readableSlice(0);
        const read_len = @min(read_slice.len, total_samples - i);
        if (read_len == 0) return;

        sysaudio.convertTo(
            f32,
            read_slice[0..read_len],
            audio.player.format(),
            output[i * @sizeOf(f32) ..][0 .. read_len * @sizeOf(f32)],
        );

        i += read_len;
        audio.buffer.discard(read_len);
        audio.cond.signal();
    }
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

    if (i < b.len) {
        for (a[i..b.len], b[i..]) |*a_sample, b_sample| {
            a_sample.* += b_sample;
        }
    }
}
