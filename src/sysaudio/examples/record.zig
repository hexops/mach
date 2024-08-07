//! Redirects input device into zig-out/raw_audio file.

const std = @import("std");
const sysaudio = @import("mach").sysaudio;

var recorder: sysaudio.Recorder = undefined;
var file: std.fs.File = undefined;

// Note: this Info.plist file gets embedded into the final binary __TEXT,__info_plist
// linker section. On macOS this means that NSMicrophoneUsageDescription is set. Without
// that being set, the application would be denied access to the microphone (the prompt
// for microphone access would not even appear.)
//
// The linker is just a convenient way to specify this without building a .app bundle with
// a separate Info.plist file.
export var __info_plist: [663:0]u8 linksection("__TEXT,__info_plist") =
    (
    \\ <?xml version="1.0" encoding="UTF-8"?>
    \\ <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    \\ <plist version="1.0">
    \\ <dict>
    \\   <key>CFBundleDevelopmentRegion</key>
    \\   <string>English</string>
    \\   <key>CFBundleIdentifier</key>
    \\   <string>com.my.app</string>
    \\   <key>CFBundleInfoDictionaryVersion</key>
    \\   <string>6.0</string>
    \\   <key>CFBundleName</key>
    \\   <string>myapp</string>
    \\   <key>CFBundleDisplayName</key>
    \\   <string>My App</string>
    \\   <key>CFBundleVersion</key>
    \\   <string>1.0.0</string>
    \\   <key>NSMicrophoneUsageDescription</key>
    \\   <string>To record audio from your microphone</string>
    \\ </dict>
    \\ </plist>
).*;

pub fn main() !void {
    _ = __info_plist;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);

    var ctx = try sysaudio.Context.init(null, gpa.allocator(), .{});
    defer ctx.deinit();
    try ctx.refresh();

    const device = ctx.defaultDevice(.capture) orelse return error.NoDevice;

    recorder = try ctx.createRecorder(device, readCallback, .{});
    defer recorder.deinit();
    try recorder.start();

    const zig_out = try std.fs.cwd().makeOpenPath("zig-out", .{});
    file = try zig_out.createFile("raw_audio", .{});

    std.debug.print(
        \\Recording to zig-out/raw_audio using:
        \\
        \\  device: {s}
        \\  channels: {}
        \\  sample_rate: {}
        \\
        \\You can play this recording back using e.g.:
        \\  $ ffplay -f f32le -ar {} -ac {} zig-out/raw_audio
        \\
    , .{
        device.name,
        device.channels.len,
        recorder.sampleRate(),
        recorder.sampleRate(),
        device.channels.len,
    });
    // Note: you may also use e.g.:
    //
    // ```
    // paplay -p --format=FLOAT32LE --rate 48000 --raw zig-out/raw_audio
    // aplay -f FLOAT_LE -r 48000 zig-out/raw_audio
    // ```

    while (true) {}
}

fn readCallback(_: ?*anyopaque, input: []const u8) void {
    const format_size = recorder.format().size();
    const samples = input.len / format_size;
    var buffer: [16 * 1024]f32 = undefined;
    sysaudio.convertFrom(f32, buffer[0..samples], recorder.format(), input);
    _ = file.write(std.mem.sliceAsBytes(buffer[0 .. input.len / format_size])) catch {};
}
