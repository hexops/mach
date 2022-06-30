const std = @import("std");
const soundio = @import("soundio");
const c = soundio.c;
const SoundIo = soundio.SoundIo;
const OutStream = soundio.OutStream;

var seconds_offset: f32 = 0;

fn write_callback(
    maybe_outstream: ?[*]c.SoundIoOutStream,
    frame_count_min: c_int,
    frame_count_max: c_int,
) callconv(.C) void {
    _ = frame_count_min;
    const outstream = OutStream{ .handle = @ptrCast(*c.SoundIoOutStream, maybe_outstream) };
    const layout = outstream.layout();
    const float_sample_rate = outstream.sampleRate();
    const seconds_per_frame = 1.0 / @intToFloat(f32, float_sample_rate);
    var frames_left = frame_count_max;

    while (frames_left > 0) {
        var frame_count = frames_left;

        var areas: [*]c.SoundIoChannelArea = undefined;
        outstream.beginWrite(
            @ptrCast([*]?[*]c.SoundIoChannelArea, &areas),
            &frame_count,
        ) catch |err| std.debug.panic("write failed: {s}", .{@errorName(err)});

        if (frame_count == 0) break;

        const pitch = 440.0;
        const radians_per_second = pitch * 2.0 * std.math.pi;
        var frame: c_int = 0;
        while (frame < frame_count) : (frame += 1) {
            const sample = std.math.sin((seconds_offset + @intToFloat(f32, frame) *
                seconds_per_frame) * radians_per_second);
            {
                var channel: usize = 0;
                while (channel < @intCast(usize, layout.channelCount())) : (channel += 1) {
                    const channel_ptr = areas[channel].ptr;
                    const sample_ptr = &channel_ptr[@intCast(usize, areas[channel].step * frame)];
                    @ptrCast(*f32, @alignCast(@alignOf(f32), sample_ptr)).* = sample;
                }
            }
        }
        seconds_offset += seconds_per_frame * @intToFloat(f32, frame_count);
        outstream.endWrite() catch |err| std.debug.panic("end write failed: {s}", .{@errorName(err)});
        frames_left -= frame_count;
    }
}

pub fn main() !void {
    const sio = try SoundIo.init();
    defer sio.deinit();
    try sio.connect();
    sio.flushEvents();

    const default_output_index = sio.defaultOutputDeviceIndex().?;
    if (default_output_index < 0) return error.NoOutputDeviceFound;

    const device = sio.getOutputDevice(default_output_index) orelse return error.OutOfMemory;
    defer device.unref();

    std.debug.print("Output device: {s}\n", .{device.name()});

    const outstream = try device.createOutStream();
    defer outstream.deinit();

    outstream.setFormat(.float32LE);
    outstream.setWriteCallback(write_callback);

    try outstream.open();
    try outstream.start();

    while (true) sio.waitEvents();
}
