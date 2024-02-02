const std = @import("std");
const builtin = @import("builtin");
const mach = @import("mach");
const sysaudio = mach.sysaudio;

pub const name = .audio;
pub const Mod = mach.Mod(@This());

allocator: std.mem.Allocator,
ctx: sysaudio.Context,
player: sysaudio.Player,
playlist: std.ArrayListUnmanaged(Playing),
buffer: [2048]f32,

const Playing = struct {
    samples: std.ArrayListUnmanaged(f32) = .{},
    status: Status = .paused,
    index: usize = 0,
};

const Status = enum {
    playing,
    paused,
};

pub const local = struct {
    pub fn init(mod: *Mod, allocator: std.mem.Allocator) !void {
        const ctx = try sysaudio.Context.init(null, allocator, .{});
        try ctx.refresh();

        const device = ctx.defaultDevice(.playback) orelse return error.NoDeviceFound;
        var player = try ctx.createPlayer(device, writeFn, .{ .user_data = mod });
        try player.start();

        var playlist = std.ArrayListUnmanaged(Playing){};
        try playlist.append(allocator, .{});

        mod.state = .{
            .allocator = allocator,
            .ctx = ctx,
            .player = player,
            .playlist = playlist,
            .buffer = undefined,
        };
    }

    pub fn deinit(mod: *Mod) !void {
        mod.state.player.deinit();
        mod.state.ctx.deinit();
        for (mod.state.playlist.items) |*playlist| {
            playlist.samples.deinit(mod.state.allocator);
        }
        mod.state.playlist.deinit(mod.state.allocator);
    }

    pub fn add(mod: *Mod, samples: []const f32) !void {
        try mod.state.playlist.items[0].samples.appendSlice(mod.state.allocator, samples);
    }

    pub fn playSound(mod: *Mod, samples: []const f32) !void {
        try mod.state.playlist.append(mod.state.allocator, .{ .status = .playing });
        try mod.state.playlist.items[mod.state.playlist.items.len - 1].samples.appendSlice(mod.state.allocator, samples);
    }

    pub fn play(mod: *Mod) !void {
        for (mod.state.playlist.items) |*playlist| {
            playlist.status = .playing;
        }
    }

    pub fn pause(mod: *Mod) !void {
        for (mod.state.playlist.items) |*playlist| {
            playlist.status = .paused;
        }
    }
};

fn writeFn(mod_opaque: ?*anyopaque, output: []u8) void {
    const mod: *Mod = @ptrCast(@alignCast(mod_opaque));
    const player = &mod.state.player;

    // Clear buffer from previous samples
    @memset(output, 0);

    const total_samples = output.len / player.format().size();

    var buffer: [4096]f32 = undefined;
    var i: usize = 0;

    while (i < total_samples) {
        const buffer_len = @min(buffer.len, total_samples - i);

        var max_samples: usize = 0;
        for (mod.state.playlist.items) |*playlist| {
            if (playlist.status == .paused) continue;

            const sample_count = @min(buffer_len, playlist.samples.items.len - playlist.index);
            max_samples = @max(max_samples, sample_count);
            mixSamples(
                buffer[0..sample_count],
                playlist.samples.items[playlist.index..][0..sample_count],
            );

            playlist.index += sample_count;
        }

        if (max_samples == 0) break;

        sysaudio.convertTo(
            f32,
            buffer[0..max_samples],
            player.format(),
            output[i * player.format().size() ..][0 .. max_samples * player.format().size()],
        );

        i += max_samples;
    }
}

const use_simd = builtin.mode != .ReleaseFast and builtin.mode != .ReleaseSmall;

inline fn mixSamples(a: []f32, b: []const f32) void {
    std.debug.assert(a.len >= b.len);

    var i: usize = 0;
    if (use_simd) {
        if (std.simd.suggestVectorSize(f32)) |vec_size| {
            const Vec = @Vector(vec_size, f32);
            const vec_blocks_len = b.len - (b.len % vec_size);
            while (i < vec_blocks_len) : (i += vec_size) {
                const b_vec: Vec = b[i..][0..vec_size].*;
                a[i..][0..vec_size].* += b_vec;
            }
        }
    }

    if (i < b.len) {
        for (a[i..b.len], b[i..]) |*a_sample, b_sample| {
            a_sample.* += b_sample;
        }
    }
}
