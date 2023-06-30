const std = @import("std");
const builtin = @import("builtin");
const main = @import("main.zig");
const backends = @import("backends.zig");
const util = @import("util.zig");
// const c = @import("cimport.zig");
const c = @cImport({
    @cInclude("CoreAudio/CoreAudio.h");
    @cInclude("AudioUnit/AudioUnit.h");
});
const native_endian = builtin.cpu.arch.endian();
var is_darling = false;

pub const Context = struct {
    allocator: std.mem.Allocator,
    devices_info: util.DevicesInfo,

    pub fn init(allocator: std.mem.Allocator, options: main.Context.Options) !backends.BackendContext {
        _ = options;

        if (std.fs.accessAbsolute("/usr/lib/darling", .{})) {
            is_darling = true;
        } else |_| {}

        var self = try allocator.create(Context);
        errdefer allocator.destroy(self);
        self.* = .{
            .allocator = allocator,
            .devices_info = util.DevicesInfo.init(),
        };

        return .{ .coreaudio = self };
    }

    pub fn deinit(self: *Context) void {
        for (self.devices_info.list.items) |d|
            freeDevice(self.allocator, d);
        self.devices_info.list.deinit(self.allocator);
        self.allocator.destroy(self);
    }

    pub fn refresh(self: *Context) !void {
        for (self.devices_info.list.items) |d|
            freeDevice(self.allocator, d);
        self.devices_info.clear(self.allocator);

        var prop_address = c.AudioObjectPropertyAddress{
            .mSelector = c.kAudioHardwarePropertyDevices,
            .mScope = c.kAudioObjectPropertyScopeGlobal,
            .mElement = c.kAudioObjectPropertyElementMaster,
        };

        var io_size: u32 = 0;
        if (c.AudioObjectGetPropertyDataSize(
            c.kAudioObjectSystemObject,
            &prop_address,
            0,
            null,
            &io_size,
        ) != c.noErr) {
            return error.OpeningDevice;
        }

        const devices_count = io_size / @sizeOf(c.AudioObjectID);
        if (devices_count == 0) return;

        var devs = try self.allocator.alloc(c.AudioObjectID, devices_count);
        defer self.allocator.free(devs);
        if (c.AudioObjectGetPropertyData(
            c.kAudioObjectSystemObject,
            &prop_address,
            0,
            null,
            &io_size,
            @as(*anyopaque, @ptrCast(devs)),
        ) != c.noErr) {
            return error.OpeningDevice;
        }

        var default_input_id: c.AudioObjectID = undefined;
        var default_output_id: c.AudioObjectID = undefined;

        io_size = @sizeOf(c.AudioObjectID);
        if (c.AudioHardwareGetProperty(
            c.kAudioHardwarePropertyDefaultInputDevice,
            &io_size,
            &default_input_id,
        ) != c.noErr) {
            return error.OpeningDevice;
        }

        io_size = @sizeOf(c.AudioObjectID);
        if (c.AudioHardwareGetProperty(
            c.kAudioHardwarePropertyDefaultOutputDevice,
            &io_size,
            &default_output_id,
        ) != c.noErr) {
            return error.OpeningDevice;
        }

        for (devs) |id| {
            var buf_list: *c.AudioBufferList = undefined;
            defer self.allocator.destroy(buf_list);
            var mode: main.Device.Mode = undefined;
            for (std.meta.tags(main.Device.Mode)) |m| {
                mode = m;

                io_size = 0;
                prop_address.mSelector = c.kAudioDevicePropertyStreamConfiguration;
                prop_address.mScope = switch (mode) {
                    .playback => c.kAudioObjectPropertyScopeOutput,
                    .capture => c.kAudioObjectPropertyScopeInput,
                };
                if (c.AudioObjectGetPropertyDataSize(
                    id,
                    &prop_address,
                    0,
                    null,
                    &io_size,
                ) != c.noErr) {
                    continue;
                }

                buf_list = try self.allocator.create(c.AudioBufferList);
                if (c.AudioObjectGetPropertyData(
                    id,
                    &prop_address,
                    0,
                    null,
                    &io_size,
                    @as(*anyopaque, @ptrCast(buf_list)),
                ) != c.noErr) {
                    return error.OpeningDevice;
                }

                if (buf_list.mBuffers[0].mNumberChannels > 0) {
                    break;
                }
            }

            // for now, only set `channels` to the output channels
            const audio_buffer_list_property_address = c.AudioObjectPropertyAddress{
                .mSelector = c.kAudioDevicePropertyStreamConfiguration,
                .mScope = c.kAudioDevicePropertyScopeOutput,
                .mElement = c.kAudioObjectPropertyElementMain,
            };
            var output_audio_buffer_list: c.AudioBufferList = undefined;
            var audio_buffer_list_size: c_uint = undefined;

            if (c.AudioObjectGetPropertyDataSize(id, &audio_buffer_list_property_address, 0, null, &audio_buffer_list_size) != c.noErr) {
                return error.OpeningDevice;
            }

            if (c.AudioObjectGetPropertyData(id, &prop_address, 0, null, &audio_buffer_list_size, &output_audio_buffer_list) != c.noErr) {
                return error.OpeningDevice;
            }

            var output_channel_count: usize = 0;
            for (0..output_audio_buffer_list.mNumberBuffers) |mBufferIndex| {
                output_channel_count += output_audio_buffer_list.mBuffers[mBufferIndex].mNumberChannels;
            }

            var channels = try self.allocator.alloc(main.Channel, output_channel_count);

            prop_address.mSelector = c.kAudioDevicePropertyNominalSampleRate;
            io_size = @sizeOf(f64);
            var sample_rate: f64 = undefined;
            if (c.AudioObjectGetPropertyData(
                id,
                &prop_address,
                0,
                null,
                &io_size,
                &sample_rate,
            ) != c.noErr) {
                return error.OpeningDevice;
            }

            io_size = @sizeOf([*]const u8);
            if (c.AudioDeviceGetPropertyInfo(
                id,
                0,
                0,
                c.kAudioDevicePropertyDeviceName,
                &io_size,
                null,
            ) != c.noErr) {
                return error.OpeningDevice;
            }

            const name = try self.allocator.allocSentinel(u8, io_size, 0);
            errdefer self.allocator.free(name);
            if (c.AudioDeviceGetProperty(
                id,
                0,
                0,
                c.kAudioDevicePropertyDeviceName,
                &io_size,
                name.ptr,
            ) != c.noErr) {
                return error.OpeningDevice;
            }
            const id_str = try std.fmt.allocPrintZ(self.allocator, "{d}", .{id});
            errdefer self.allocator.free(id_str);

            var dev = main.Device{
                .id = id_str,
                .name = name,
                .mode = mode,
                .channels = channels,
                .formats = &.{ .i16, .i32, .f32 },
                .sample_rate = .{
                    .min = @as(u24, @intFromFloat(@floor(sample_rate))),
                    .max = @as(u24, @intFromFloat(@floor(sample_rate))),
                },
            };

            try self.devices_info.list.append(self.allocator, dev);
            if (id == default_output_id) {
                self.devices_info.default_output = self.devices_info.list.items.len - 1;
            }

            if (id == default_input_id) {
                self.devices_info.default_input = self.devices_info.list.items.len - 1;
            }
        }
    }

    pub fn devices(self: Context) []const main.Device {
        return self.devices_info.list.items;
    }

    pub fn defaultDevice(self: Context, mode: main.Device.Mode) ?main.Device {
        return self.devices_info.default(mode);
    }

    pub fn createPlayer(self: *Context, device: main.Device, writeFn: main.WriteFn, options: main.StreamOptions) !backends.BackendPlayer {
        var player = try self.allocator.create(Player);

        var component_desc = c.AudioComponentDescription{
            .componentType = c.kAudioUnitType_Output,
            .componentSubType = c.kAudioUnitSubType_HALOutput,
            .componentManufacturer = c.kAudioUnitManufacturer_Apple,
            .componentFlags = 0,
            .componentFlagsMask = 0,
        };
        const component = c.AudioComponentFindNext(null, &component_desc);
        if (component == null) return error.OpeningDevice;

        var audio_unit: c.AudioComponentInstance = undefined;
        if (c.AudioComponentInstanceNew(component, &audio_unit) != c.noErr) return error.OpeningDevice;

        if (c.AudioUnitInitialize(audio_unit) != c.noErr) return error.OpeningDevice;
        errdefer _ = c.AudioUnitUninitialize(audio_unit);

        const device_id = std.fmt.parseInt(c.AudioDeviceID, device.id, 10) catch unreachable;
        if (c.AudioUnitSetProperty(
            audio_unit,
            c.kAudioOutputUnitProperty_CurrentDevice,
            c.kAudioUnitScope_Input,
            0,
            &device_id,
            @sizeOf(c.AudioDeviceID),
        ) != c.noErr) {
            return error.OpeningDevice;
        }

        const stream_desc = try createStreamDesc(options.format, options.sample_rate, device.channels.len);
        if (c.AudioUnitSetProperty(
            audio_unit,
            c.kAudioUnitProperty_StreamFormat,
            c.kAudioUnitScope_Input,
            0,
            &stream_desc,
            @sizeOf(c.AudioStreamBasicDescription),
        ) != c.noErr) {
            return error.OpeningDevice;
        }

        const render_callback = c.AURenderCallbackStruct{
            .inputProc = Player.renderCallback,
            .inputProcRefCon = player,
        };
        if (c.AudioUnitSetProperty(
            audio_unit,
            c.kAudioUnitProperty_SetRenderCallback,
            c.kAudioUnitScope_Input,
            0,
            &render_callback,
            @sizeOf(c.AURenderCallbackStruct),
        ) != c.noErr) {
            return error.OpeningDevice;
        }

        player.* = .{
            .allocator = self.allocator,
            .audio_unit = audio_unit.?,
            .is_paused = false,
            .vol = 1.0,
            .writeFn = writeFn,
            .user_data = options.user_data,
            .channels = device.channels,
            .format = options.format,
            .sample_rate = options.sample_rate,
            .write_step = options.format.frameSize(device.channels.len),
        };
        return .{ .coreaudio = player };
    }
};

pub const Player = struct {
    allocator: std.mem.Allocator,
    audio_unit: c.AudioUnit,
    is_paused: bool,
    vol: f32,
    writeFn: main.WriteFn,
    user_data: ?*anyopaque,

    channels: []main.Channel,
    format: main.Format,
    sample_rate: u24,
    write_step: u8,

    pub fn renderCallback(
        self_opaque: ?*anyopaque,
        action_flags: [*c]c.AudioUnitRenderActionFlags,
        time_stamp: [*c]const c.AudioTimeStamp,
        bus_number: u32,
        frames_left: u32,
        buf: [*c]c.AudioBufferList,
    ) callconv(.C) c.OSStatus {
        _ = action_flags;
        _ = time_stamp;
        _ = bus_number;
        _ = frames_left;

        const self = @as(*Player, @ptrCast(@alignCast(self_opaque.?)));

        for (self.channels, 0..) |*ch, i| {
            ch.ptr = @as([*]u8, @ptrCast(buf.*.mBuffers[0].mData.?)) + self.format.frameSize(i);
        }
        const frames = buf.*.mBuffers[0].mDataByteSize / self.format.frameSize(self.channels.len);
        self.writeFn(self.user_data, frames);

        return c.noErr;
    }

    pub fn deinit(self: *Player) void {
        _ = c.AudioOutputUnitStop(self.audio_unit);
        _ = c.AudioUnitUninitialize(self.audio_unit);
        _ = c.AudioComponentInstanceDispose(self.audio_unit);
        self.allocator.destroy(self);
    }

    pub fn start(self: *Player) !void {
        return self.play();
    }

    pub fn play(self: *Player) !void {
        if (c.AudioOutputUnitStart(self.audio_unit) != c.noErr) {
            return error.CannotPlay;
        }
        self.is_paused = false;
    }

    pub fn pause(self: *Player) !void {
        if (c.AudioOutputUnitStop(self.audio_unit) != c.noErr) {
            return error.CannotPause;
        }
        self.is_paused = true;
    }

    pub fn paused(self: Player) bool {
        return self.is_paused;
    }

    pub fn setVolume(self: *Player, vol: f32) !void {
        if (c.AudioUnitSetParameter(
            self.audio_unit,
            c.kHALOutputParam_Volume,
            c.kAudioUnitScope_Global,
            0,
            vol,
            0,
        ) != c.noErr) {
            if (is_darling) return;
            return error.CannotSetVolume;
        }
    }

    pub fn volume(self: Player) !f32 {
        var vol: f32 = 0;
        if (c.AudioUnitGetParameter(
            self.audio_unit,
            c.kHALOutputParam_Volume,
            c.kAudioUnitScope_Global,
            0,
            &vol,
        ) != c.noErr) {
            if (is_darling) return 1;
            return error.CannotGetVolume;
        }
        return vol;
    }
};

fn freeDevice(allocator: std.mem.Allocator, device: main.Device) void {
    allocator.free(device.id);
    allocator.free(device.name);
    allocator.free(device.channels);
}

fn createStreamDesc(format: main.Format, sample_rate: u24, ch_count: usize) !c.AudioStreamBasicDescription {
    var desc = c.AudioStreamBasicDescription{
        .mSampleRate = @as(f64, @floatFromInt(sample_rate)),
        .mFormatID = c.kAudioFormatLinearPCM,
        .mFormatFlags = switch (format) {
            .i16 => c.kAudioFormatFlagIsSignedInteger,
            .i24 => c.kAudioFormatFlagIsSignedInteger,
            .i32 => c.kAudioFormatFlagIsSignedInteger,
            .f32 => c.kAudioFormatFlagIsFloat,
            .u8 => return error.IncompatibleDevice,
            .i24_4b => return error.IncompatibleDevice,
        },
        .mBytesPerPacket = format.frameSize(ch_count),
        .mFramesPerPacket = 1,
        .mBytesPerFrame = format.frameSize(ch_count),
        .mChannelsPerFrame = @as(c_uint, @intCast(ch_count)),
        .mBitsPerChannel = switch (format) {
            .i16 => 16,
            .i24 => 24,
            .i32 => 32,
            .f32 => 32,
            .u8 => unreachable,
            .i24_4b => unreachable,
        },
        .mReserved = 0,
    };

    if (native_endian == .Big) {
        desc.mFormatFlags |= c.kAudioFormatFlagIsBigEndian;
    }

    return desc;
}

test {
    std.testing.refAllDeclsRecursive(@This());
}
