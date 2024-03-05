const std = @import("std");
const main = @import("main.zig");

pub const DevicesInfo = struct {
    list: std.ArrayListUnmanaged(main.Device),
    default_output: ?usize,
    default_input: ?usize,

    pub fn init() DevicesInfo {
        return .{
            .list = .{},
            .default_output = null,
            .default_input = null,
        };
    }

    pub fn clear(device_info: *DevicesInfo) void {
        device_info.default_output = null;
        device_info.default_input = null;
        device_info.list.clearRetainingCapacity();
    }

    pub fn get(device_info: DevicesInfo, i: usize) main.Device {
        return device_info.list.items[i];
    }

    pub fn default(device_info: DevicesInfo, mode: main.Device.Mode) ?main.Device {
        const index = switch (mode) {
            .playback => device_info.default_output,
            .capture => device_info.default_input,
        } orelse {
            for (device_info.list.items) |device| {
                if (device.mode == mode) {
                    return device;
                }
            }
            return null;
        };
        return device_info.get(index);
    }

    pub fn setDefault(device_info: *DevicesInfo, mode: main.Device.Mode, i: usize) void {
        switch (mode) {
            .playback => device_info.default_output = i,
            .capture => device_info.default_input = i,
        }
    }
};

pub fn Range(comptime T: type) type {
    return struct {
        min: T,
        max: T,

        pub fn clamp(range: @This(), val: T) T {
            return std.math.clamp(val, range.min, range.max);
        }
    };
}

pub fn doNothing() callconv(.C) void {}
