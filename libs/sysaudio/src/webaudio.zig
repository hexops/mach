const std = @import("std");
const Mode = @import("main.zig").Mode;
const Format = @import("main.zig").Format;
const DataCallback = @import("main.zig").DataCallback;
const js = @import("sysjs");

const Audio = @This();

pub const sysaudio = struct {
    extern "sysaudio" fn start() void;
    extern "sysaudio" fn pause() void;
};

pub const Device = struct {
    properties: Properties,

    pub const Options = struct {
        mode: Mode = .output,
        format: ?Format = null,
        is_raw: ?bool = null,
        channels: ?u8 = null,
        sample_rate: ?u32 = null,
        id: ?[:0]const u8 = null,
        name: ?[]const u8 = null,
    };

    pub const Properties = struct {
        mode: Mode,
        format: Format,
        is_raw: bool,
        channels: u8,
        sample_rate: u32,
        id: [:0]const u8,
        name: []const u8,
    };

    pub fn deinit(device: *Device, allocator: std.mem.Allocator) void {
        allocator.destroy(device);
    }

    pub fn setCallback(device: *Device, callback: DataCallback, user_data: ?*anyopaque) void {
        _ = device;
        audio_callback = callback;
        audio_user_data = user_data;
    }

    pub fn pause(device: *Device) Error!void {
        _ = device;
        sysaudio.pause();
    }

    pub fn start(device: *Device) Error!void {
        _ = device;
        sysaudio.start();
    }
};

pub const DeviceIterator = struct {
    ctx: *Audio,
    mode: Mode,

    pub fn next(_: DeviceIterator) IteratorError!?Device.Properties {
        return null;
    }
};

pub const IteratorError = error{};

pub const Error = error{
    OutOfMemory,
    AudioUnsupported,
};

pub fn init() Error!Audio {
    const context = js.global().get("AudioContext");
    defer context.view(.func).deinit();
    if (context.is(.undef))
        return error.AudioUnsupported;

    return Audio{};
}

pub fn deinit(audio: Audio) void {
    _ = audio;
}

// TODO(sysaudio): implement waitEvents for WebAudio, will a WASM process terminate without this?
pub fn waitEvents(_: Audio) void {}

const default_channel_count = 2;
const default_sample_rate = 48000;
const default_buffer_size_per_channel = 1024; // 21.33ms

pub fn requestDevice(audio: Audio, allocator: std.mem.Allocator, options: Device.Options) Error!*Device {
    // NOTE: WebAudio only supports F32 audio format, so options.format is unused
    //const mode = options.mode;
    //const channels = options.channels orelse default_channel_count;
    //const sample_rate = options.sample_rate orelse default_sample_rate;
    _ = audio;
    _ = allocator;

    // TODO(sysaudio): Figure out ID/name or make optional again
    var properties = Device.Properties{
        .id = "0",
        .name = "WebAudio",
        .format = .F32,
        .mode = options.mode,
        .is_raw = false,
        .channels = options.channels orelse default_channel_count,
        .sample_rate = options.sample_rate orelse default_sample_rate,
    };

    audio_device = Device{
        .properties = properties,
    };
    return &(audio_device.?);
}

// TODO(sysaudio): Remove this global state if possible
var audio_device: ?Device = null;
var audio_callback: ?DataCallback = null;
var audio_user_data: ?*anyopaque = null;
var audio_output_buffer: ?[]f32 = null;

fn get_output_buffer(length: usize) ?[]f32 {
    if (audio_output_buffer) |buffer| {
        if (buffer.len >= length) {
            // We can reuse the buffer
            return buffer;
        }
        // The buffer isn't large enough, we'll have to allocate a new one
        std.heap.page_allocator.free(buffer);
    }
    const new_buffer = std.heap.page_allocator.alloc(f32, length) catch unreachable;
    audio_output_buffer = new_buffer;
    return new_buffer;
}

export fn audioProcessEvent(sample_rate: u32, num_channels: u8, num_samples: u32) ?[*]const f32 {
    const dev = &(audio_device orelse return null);

    dev.properties.sample_rate = sample_rate;
    dev.properties.channels = num_channels;

    const cb = audio_callback orelse return null;
    const buffer = get_output_buffer(@intCast(u32, num_channels) * num_samples) orelse return null;

    cb(dev, audio_user_data, @ptrCast([*]u8, buffer.ptr)[0 .. buffer.len * @sizeOf(f32)]);

    return buffer.ptr;
}

pub fn outputDeviceIterator(audio: Audio) DeviceIterator {
    return .{ .audio = audio, .mode = .output };
}

pub fn inputDeviceIterator(audio: Audio) DeviceIterator {
    return .{ .audio = audio, .mode = .input };
}
