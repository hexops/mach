const std = @import("std");
const mach = @import("mach");
const sysaudio = @import("sysaudio");
const js = @import("sysjs");

pub const App = @This();

audio: sysaudio,
device: sysaudio.Device,

var random_engine = std.rand.DefaultPrng.init(0);

pub fn init(app: *App, _: *mach.Core) !void {
    const audio = try sysaudio.init();
    errdefer audio.deinit();

    const device = try audio.requestDevice(.{ .mode = .output, .channels = 1 });
    errdefer device.deinit();

    device.setCallback(callback, null);
    device.start();

    app.audio = audio;
    app.device = device;
}

fn callback(_: *sysaudio.Device, _: ?*anyopaque, buffer: []u8) void {
    // This is ok
    // var i: usize = 0;
    // while (i < buffer.len) : (i += 1) {
    //     buffer[i] = 0;
    // }

    // This is ok
    // var i: usize = 0;
    // while (i < buffer.len - 4) : (i += 4) {
    //     buffer[i] = 0;
    //     buffer[i + 1] = 0;
    //     buffer[i + 2] = 20;
    //     buffer[i + 3] = 66;
    // }

    var i: usize = 0;
    while (i < buffer.len) : (i += 4) {
        // This below doesnt works why?
        //const val = random_engine.random().float(f32);
        //const val_buf = @bitCast([4]u8, val);

        var j: usize = 0;
        while (j < 4) : (j += 1) {
            buffer[i + j] = random_engine.random().int(u8);
        }
    }

    // This below doesnt works, why?
    //random_engine.random().bytes(buffer);
}

pub fn deinit(app: *App, _: *mach.Core) void {
    app.device.deinit();
    app.audio.deinit();
}

pub fn update(app: *App, engine: *mach.Core) !void {
    while (engine.pollEvent()) |event| {
        switch (event) {
            .key_press => |ev| {
                app.device.pause();
                std.log.info("key is {s}", .{@tagName(ev.key)});
            },
            else => {},
        }
    }
    app.audio.waitEvents();
    //std.log.info("update", .{});
}
