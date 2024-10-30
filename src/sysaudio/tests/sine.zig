const std = @import("std");
const sysaudio = @import("mach").sysaudio;

var player: sysaudio.Player = undefined;

pub fn main() !void {
    var timer = try std.time.Timer.start();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var ctx = try sysaudio.Context.init(null, gpa.allocator(), .{ .deviceChangeFn = deviceChange });
    std.log.info("Took {} to initialize the context...", .{std.fmt.fmtDuration(timer.lap())});
    defer ctx.deinit();
    try ctx.refresh();
    std.log.info("Took {} to refresh the context...", .{std.fmt.fmtDuration(timer.lap())});

    const device = ctx.defaultDevice(.playback) orelse return error.NoDevice;
    std.log.info("Took {} to get the default playback device...", .{std.fmt.fmtDuration(timer.lap())});

    player = try ctx.createPlayer(device, writeCallback, .{});
    std.log.info("Took {} to create a player...", .{std.fmt.fmtDuration(timer.lap())});
    defer player.deinit();
    try player.start();
    std.log.info("Took {} to start the player...", .{std.fmt.fmtDuration(timer.lap())});

    try player.setVolume(0.85);
    std.log.info("Took {} to set the volume...", .{std.fmt.fmtDuration(timer.lap())});

    var buf: [16]u8 = undefined;
    std.log.info("player created & entering i/o loop...", .{});
    while (true) {
        std.debug.print("( paused = {}, volume = {d} )\n> ", .{ player.paused(), try player.volume() });
        const line = (try std.io.getStdIn().reader().readUntilDelimiterOrEof(&buf, '\n')) orelse break;
        var iter = std.mem.splitScalar(u8, line, ':');
        const cmd = std.mem.trimRight(u8, iter.first(), &std.ascii.whitespace);
        if (std.mem.eql(u8, cmd, "vol")) {
            const vol = try std.fmt.parseFloat(f32, std.mem.trim(u8, iter.next().?, &std.ascii.whitespace));
            try player.setVolume(vol);
        } else if (std.mem.eql(u8, cmd, "pause")) {
            try player.pause();
            try std.testing.expect(player.paused());
        } else if (std.mem.eql(u8, cmd, "play")) {
            try player.play();
            try std.testing.expect(!player.paused());
        } else if (std.mem.eql(u8, cmd, "exit")) {
            break;
        }
    }
}

const pitch = 440.0;
const radians_per_second = pitch * 2.0 * std.math.pi;
var seconds_offset: f32 = 0.0;

fn writeCallback(_: ?*anyopaque, output: []u8) void {
    const seconds_per_frame = 1.0 / @as(f32, @floatFromInt(player.sampleRate()));
    const frame_size = player.format().frameSize(@intCast(player.channels().len));
    const frames = output.len / frame_size;

    var i: usize = 0;
    var src: [16]f32 = undefined;
    while (i < output.len) : (i += frame_size) {
        const frame_index: f32 = @floatFromInt(i / frame_size);
        const sample = @sin((seconds_offset + frame_index * seconds_per_frame) * radians_per_second);
        for (0..player.channels().len) |ch| src[ch] = sample;
        sysaudio.convertTo(
            f32,
            src[0..player.channels().len],
            player.format(),
            output[i..][0..frame_size],
        );
    }

    seconds_offset = @mod(seconds_offset + seconds_per_frame * @as(f32, @floatFromInt(frames)), 1.0);
}

fn deviceChange(_: ?*anyopaque) void {
    std.log.info("device change detected!", .{});
}
