const std = @import("std");
const sysaudio = @import("sysaudio");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var a = try sysaudio.Context.init(null, allocator, .{ .deviceChangeFn = deviceChange });
    defer a.deinit();
    try a.refresh();

    const device = a.defaultDevice(.playback) orelse return error.NoDevice;

    var p = try a.createPlayer(device, writeCallback, .{});
    defer p.deinit();
    try p.start();

    try p.setVolume(0.85);

    var buf: [16]u8 = undefined;
    while (true) {
        std.debug.print("( paused = {}, volume = {d} )\n> ", .{ p.paused(), try p.volume() });
        const line = (try std.io.getStdIn().reader().readUntilDelimiterOrEof(&buf, '\n')) orelse break;
        var iter = std.mem.split(u8, line, ":");
        const cmd = std.mem.trimRight(u8, iter.first(), &std.ascii.whitespace);
        if (std.mem.eql(u8, cmd, "vol")) {
            var vol = try std.fmt.parseFloat(f32, std.mem.trim(u8, iter.next().?, &std.ascii.whitespace));
            try p.setVolume(vol);
        } else if (std.mem.eql(u8, cmd, "pause")) {
            try p.pause();
            try std.testing.expect(p.paused());
        } else if (std.mem.eql(u8, cmd, "play")) {
            try p.play();
            try std.testing.expect(!p.paused());
        } else if (std.mem.eql(u8, cmd, "exit")) {
            break;
        }
    }
}

const pitch = 440.0;
const radians_per_second = pitch * 2.0 * std.math.pi;
var seconds_offset: f32 = 0.0;
fn writeCallback(self_opaque: *anyopaque, n_frame: usize) void {
    var self = @ptrCast(*sysaudio.Player, @alignCast(@alignOf(sysaudio.Player), self_opaque));

    const seconds_per_frame = 1.0 / @intToFloat(f32, self.sampleRate());
    var frame: usize = 0;
    while (frame < n_frame) : (frame += 1) {
        const sample = std.math.sin((seconds_offset + @intToFloat(f32, frame) * seconds_per_frame) * radians_per_second);
        self.writeAll(frame, sample);
    }
    seconds_offset = @mod(seconds_offset + seconds_per_frame * @intToFloat(f32, n_frame), 1.0);
}

fn deviceChange(self: ?*anyopaque) void {
    _ = self;
    std.debug.print("Device change detected!\n", .{});
}
