const std = @import("std");
const Mode = @import("main.zig").Mode;
const DeviceDescriptor = @import("main.zig").DeviceDescriptor;
const js = @import("sysjs");

const Audio = @This();

pub const Device = struct {
    context: js.Object,

    pub fn deinit(device: Device) void {
        device.context.deinit();
    }

    pub fn pause(device: Device) void {
        device.context.call("suspend", &.{});
    }

    pub fn start(device: Device) void {
        _ = device.context.call("resume", &.{});
    }
};

pub const DeviceIterator = struct {
    ctx: *Audio,
    mode: Mode,

    pub fn next(_: DeviceIterator) IteratorError!?DeviceDescriptor {
        return null;
    }
};

pub const IteratorError = error{};

pub const Error = error{
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

pub fn waitEvents(_: Audio) void {}

pub fn requestDevice(audio: Audio, config: DeviceDescriptor) Error!Device {
    const context = audio.context_constructor.construct(&.{});
    _ = context.call("suspend", &.{});

    const input_channels = if (config.mode.? == .input) js.createNumber(@intToFloat(f64, config.channels.?)) else js.createUndefined();
    const output_channels = if (config.mode.? == .output) js.createNumber(@intToFloat(f64, config.channels.?)) else js.createUndefined();

    const node = context.call("createScriptProcessor", &.{ js.createNumber(4096), input_channels, output_channels }).view(.object);
    defer node.deinit();

    context.set("node", node.toValue());

    {
        const audio_process_event = js.createFunction(audioProcessEvent);
        defer audio_process_event.deinit();
        node.set("onaudioprocess", audio_process_event.toValue());
    }

    {
        const destination = context.get("destination").view(.object);
        defer destination.deinit();
        _ = node.call("connect", &.{destination.toValue()});
    }

    return Device{
        .context = context,
    };
}

fn audioProcessEvent(args: js.Object, _: usize) js.Value {
    const audio_event = args.getIndex(0).view(.object);
    _ = audio_event;
    return js.createUndefined();
}

pub fn outputDeviceIterator(audio: Audio) DeviceIterator {
    return .{ .audio = audio, .mode = .output };
}

pub fn inputDeviceIterator(audio: Audio) DeviceIterator {
    return .{ .audio = audio, .mode = .input };
}
