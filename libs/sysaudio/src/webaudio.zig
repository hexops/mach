const std = @import("std");
const Mode = @import("main.zig").Mode;
const DeviceOptions = @import("main.zig").DeviceOptions;
const DeviceProperties  = @import("main.zig").DeviceProperties;
const js = @import("sysjs");

const Audio = @This();

pub const DataCallback = if (@import("builtin").zig_backend == .stage1)
    fn (device: *Device, user_data: ?*anyopaque, buffer: []u8) void
else
    *const fn (device: *Device, user_data: ?*anyopaque, buffer: []u8) void;

pub const Device = struct {
    properties: DeviceProperties,

    // Internal fields.
    context: js.Object,

    pub const Options = DeviceOptions;
    pub const Properties = DeviceProperties;

    pub fn deinit(device: *Device, allocator: std.mem.Allocator) void {
        device.context.deinit();
        allocator.destroy(device);
    }

    pub fn setCallback(device: *Device, callback: DataCallback, user_data: ?*anyopaque) void {
        device.context.set("device", js.createNumber(@intToFloat(f64, @ptrToInt(device))));
        device.context.set("callback", js.createNumber(@intToFloat(f64, @ptrToInt(callback))));
        if (user_data) |ud|
            device.context.set("user_data", js.createNumber(@intToFloat(f64, @ptrToInt(ud))));
    }

    pub fn pause(device: *Device) Error!void {
        _ = device.context.call("suspend", &.{});
    }

    pub fn start(device: *Device) Error!void {
        _ = device.context.call("resume", &.{});
    }
};

pub const DeviceIterator = struct {
    ctx: *Audio,
    mode: Mode,

    pub fn next(_: DeviceIterator) IteratorError!?DeviceProperties {
        return null;
    }
};

pub const IteratorError = error{};

pub const Error = error{
    OutOfMemory,
    AudioUnsupported,
};

context_constructor: js.Function,

pub fn init() Error!Audio {
    const context = js.global().get("AudioContext");
    if (context.is(.undef))
        return error.AudioUnsupported;

    return Audio{ .context_constructor = context.view(.func) };
}

pub fn deinit(audio: Audio) void {
    audio.context_constructor.deinit();
}

// TODO(sysaudio): implement waitEvents for WebAudio, will a WASM process terminate without this?
pub fn waitEvents(_: Audio) void {}

const default_channel_count = 2;
const default_sample_rate = 48000;
const default_buffer_size_per_channel = 1024; // 21.33ms

pub fn requestDevice(audio: Audio, allocator: std.mem.Allocator, options: DeviceOptions) Error!*Device {
    // NOTE: WebAudio only supports F32 audio format, so options.format is unused
    const mode = options.mode;
    const channels = options.channels orelse default_channel_count;
    const sample_rate = options.sample_rate orelse default_sample_rate;

    const context_options = js.createMap();
    defer context_options.deinit();
    context_options.set("sampleRate", js.createNumber(@intToFloat(f64, sample_rate)));

    const context = audio.context_constructor.construct(&.{context_options.toValue()});
    _ = context.call("suspend", &.{});

    const input_channels = if (mode == .input) js.createNumber(@intToFloat(f64, channels)) else js.createUndefined();
    const output_channels = if (mode == .output) js.createNumber(@intToFloat(f64, channels)) else js.createUndefined();

    const node = context.call("createScriptProcessor", &.{ js.createNumber(default_buffer_size_per_channel), input_channels, output_channels }).view(.object);
    defer node.deinit();

    context.set("node", node.toValue());

    {
        // TODO(sysaudio): this capture leaks for now, we need a better way to pass captures via sysjs
        // that passes by value I think.
        const captures = std.heap.page_allocator.alloc(js.Value, 1) catch unreachable;
        captures[0] = context.toValue();
        const audio_process_event = js.createFunction(audioProcessEvent, captures);

        // TODO(sysaudio): this leaks, we need a good place to clean this up.
        // defer audio_process_event.deinit();
        node.set("onaudioprocess", audio_process_event.toValue());
    }

    {
        const destination = context.get("destination").view(.object);
        defer destination.deinit();
        _ = node.call("connect", &.{destination.toValue()});
    }

    var properties = DeviceProperties {
        .format = .F32,
        .mode = options.mode orelse .output,
        .channels = options.channels orelse default_channel_count,
        .sample_rate = options.sample_rate orelse default_sample_rate,
    };

    const device = try allocator.create(Device);
    device.* = .{
        .properties = properties,
        .context = context,
    };
    return device;
}

fn audioProcessEvent(args: js.Object, _: usize, captures: []js.Value) js.Value {
    const device_context = captures[0].view(.object);

    const audio_event = args.getIndex(0).view(.object);
    defer audio_event.deinit();
    const output_buffer = audio_event.get("outputBuffer").view(.object);
    defer output_buffer.deinit();
    const num_channels = @floatToInt(usize, output_buffer.get("numberOfChannels").view(.num));

    const buffer_length = default_buffer_size_per_channel * num_channels * @sizeOf(f32);
    // TODO(sysaudio): reuse buffer, do not allocate in this hot path
    const buffer = std.heap.page_allocator.alloc(u8, buffer_length) catch unreachable;
    defer std.heap.page_allocator.free(buffer);

    const callback = device_context.get("callback");
    if (!callback.is(.undef)) {
        var dev = @intToPtr(*Device, @floatToInt(usize, device_context.get("device").view(.num)));
        const cb = @intToPtr(DataCallback, @floatToInt(usize, callback.view(.num)));
        const user_data = device_context.get("user_data");
        const ud = if (user_data.is(.undef)) null else @intToPtr(*anyopaque, @floatToInt(usize, user_data.view(.num)));

        // TODO(sysaudio): do not reconstruct Uint8Array (expensive)
        const source = js.constructType("Uint8Array", &.{js.createNumber(@intToFloat(f64, buffer_length))});
        defer source.deinit();

        cb(dev, ud, buffer[0..]);
        source.copyBytes(buffer[0..]);

        const float_source = js.constructType("Float32Array", &.{
            source.get("buffer"),
            source.get("byteOffset"),
            js.createNumber(source.get("byteLength").view(.num) / 4),
        });
        defer float_source.deinit();

        js.global().set("source", source.toValue());
        js.global().set("float_source", float_source.toValue());
        js.global().set("output_buffer", output_buffer.toValue());

        var channel: usize = 0;
        while (channel < num_channels) : (channel += 1) {
            // TODO(sysaudio): investigate if using copyToChannel would be better?
            //_ = output_buffer.call("copyToChannel", &.{ float_source.toValue(), js.createNumber(@intToFloat(f64, channel)) });
            const output_data = output_buffer.call("getChannelData", &.{js.createNumber(@intToFloat(f64, channel))}).view(.object);
            defer output_data.deinit();
            const channel_slice = float_source.call("slice", &.{
                js.createNumber(@intToFloat(f64, channel * default_buffer_size_per_channel)),
                js.createNumber(@intToFloat(f64, (channel + 1) * default_buffer_size_per_channel)),
            });
            _ = output_data.call("set", &.{channel_slice});
        }
    }

    return js.createUndefined();
}

pub fn outputDeviceIterator(audio: Audio) DeviceIterator {
    return .{ .audio = audio, .mode = .output };
}

pub fn inputDeviceIterator(audio: Audio) DeviceIterator {
    return .{ .audio = audio, .mode = .input };
}
