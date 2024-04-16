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
    .render = .{ .handler = render },
};

allocator: std.mem.Allocator,
ctx: sysaudio.Context = undefined,
player: sysaudio.Player = undefined,
buffer: SampleBuffer = SampleBuffer.init(),
mutex: std.Thread.Mutex = .{},
cond: std.Thread.Condition = .{},

// This should be big enough for when backends expect a large output buffer
pub const SampleBuffer = std.fifo.LinearFifo(f32, .{ .Static = 8 * 1024 });

pub fn init(audio: *@This()) !void {
    audio.ctx = try sysaudio.Context.init(null, audio.allocator, .{});
    try audio.ctx.refresh();

    const device = audio.ctx.defaultDevice(.playback) orelse return error.NoDeviceFound;
    audio.player = try audio.ctx.createPlayer(device, writeFn, .{ .user_data = audio });
    try audio.player.start();
}

pub fn deinit(audio: *Mod) void {
    audio.state().player.deinit();
    audio.state().ctx.deinit();

    var iter = audio.entities.entities.valueIterator();
    while (iter.next()) |*entity| {
        entity.samples.deinit(audio.state().allocator);
    }
}

pub fn render(audio: *Mod) !void {
    // Prepare the next 30ms of audio by querying entities and mixing the samples they want to play.
    // 48_000 * 0.03 = 1440 = 30ms
    var mixing_buffer: [1440]f32 = undefined;
    var max_samples: usize = 0;

    var iter = audio.entities.query(.{ .all = &.{.{ .mach_audio = &.{ .samples, .playing, .index } }} });
    while (iter.next()) |archetype| for (
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
            try audio.set(id, .playing, false);
            try audio.set(id, .index, 0);
            continue;
        }

        try audio.set(id, .index, index + to_read);
    };

    audio.state().mutex.lock();
    defer audio.state().mutex.unlock();
    while (audio.state().buffer.writableLength() < max_samples) {
        audio.state().cond.wait(&audio.state().mutex);
    }
    audio.state().buffer.writeAssumeCapacity(mixing_buffer[0..max_samples]);
}

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

// TODO: what's this weird behavior in ReleaseFast/Small?
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
