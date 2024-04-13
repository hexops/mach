const std = @import("std");
const builtin = @import("builtin");
const main = @import("main.zig");
const backends = @import("backends.zig");
const util = @import("util.zig");
const c = @cImport({
    @cInclude("CoreAudio/CoreAudio.h");
    @cInclude("AudioUnit/AudioUnit.h");
});
const avaudio = @import("objc").avf_audio.avaudio;

const native_endian = builtin.cpu.arch.endian();
var is_darling = false;

const default_sample_rate = 44_100; // Hz

pub const Context = struct {
    allocator: std.mem.Allocator,
    devices_info: util.DevicesInfo,

    pub fn init(allocator: std.mem.Allocator, options: main.Context.Options) !backends.Context {
        _ = options;

        if (std.fs.accessAbsolute("/usr/lib/darling", .{})) {
            is_darling = true;
        } else |_| {}

        const ctx = try allocator.create(Context);
        errdefer allocator.destroy(ctx);
        ctx.* = .{
            .allocator = allocator,
            .devices_info = util.DevicesInfo.init(),
        };

        return .{ .coreaudio = ctx };
    }

    pub fn deinit(ctx: *Context) void {
        for (ctx.devices_info.list.items) |d|
            freeDevice(ctx.allocator, d);
        ctx.devices_info.list.deinit(ctx.allocator);
        ctx.allocator.destroy(ctx);
    }

    pub fn refresh(ctx: *Context) !void {
        for (ctx.devices_info.list.items) |d|
            freeDevice(ctx.allocator, d);
        ctx.devices_info.clear();

        var prop_address = c.AudioObjectPropertyAddress{
            .mSelector = c.kAudioHardwarePropertyDevices,
            .mScope = c.kAudioObjectPropertyScopeGlobal,
            .mElement = c.kAudioObjectPropertyElementMain,
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

        const devs = try ctx.allocator.alloc(c.AudioObjectID, devices_count);
        defer ctx.allocator.free(devs);
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
            const buf_list = try ctx.allocator.create(c.AudioBufferList);
            defer ctx.allocator.destroy(buf_list);

            for (std.meta.tags(main.Device.Mode)) |mode| {
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

                if (c.AudioObjectGetPropertyData(
                    id,
                    &prop_address,
                    0,
                    null,
                    &io_size,
                    buf_list,
                ) != c.noErr) {
                    return error.OpeningDevice;
                }

                if (buf_list.mBuffers[0].mNumberChannels == 0) break;

                const audio_buffer_list_property_address = c.AudioObjectPropertyAddress{
                    .mSelector = c.kAudioDevicePropertyStreamConfiguration,
                    .mScope = switch (mode) {
                        .playback => c.kAudioDevicePropertyScopeOutput,
                        .capture => c.kAudioDevicePropertyScopeInput,
                    },
                    .mElement = c.kAudioObjectPropertyElementMain,
                };
                var output_audio_buffer_list: c.AudioBufferList = undefined;
                var audio_buffer_list_size: c_uint = undefined;

                if (c.AudioObjectGetPropertyDataSize(
                    id,
                    &audio_buffer_list_property_address,
                    0,
                    null,
                    &audio_buffer_list_size,
                ) != c.noErr) {
                    return error.OpeningDevice;
                }

                if (c.AudioObjectGetPropertyData(
                    id,
                    &prop_address,
                    0,
                    null,
                    &audio_buffer_list_size,
                    &output_audio_buffer_list,
                ) != c.noErr) {
                    return error.OpeningDevice;
                }

                var output_channel_count: usize = 0;
                for (0..output_audio_buffer_list.mNumberBuffers) |mBufferIndex| {
                    output_channel_count += output_audio_buffer_list.mBuffers[mBufferIndex].mNumberChannels;
                }

                const channels = try ctx.allocator.alloc(main.ChannelPosition, output_channel_count);

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

                const name = try ctx.allocator.allocSentinel(u8, io_size, 0);
                errdefer ctx.allocator.free(name);
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
                const id_str = try std.fmt.allocPrintZ(ctx.allocator, "{d}", .{id});
                errdefer ctx.allocator.free(id_str);

                const dev = main.Device{
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

                try ctx.devices_info.list.append(ctx.allocator, dev);
                if (id == default_output_id and mode == .playback) {
                    ctx.devices_info.default_output = ctx.devices_info.list.items.len - 1;
                }

                if (id == default_input_id and mode == .capture) {
                    ctx.devices_info.default_input = ctx.devices_info.list.items.len - 1;
                }
            }
        }
    }

    pub fn devices(ctx: Context) []const main.Device {
        return ctx.devices_info.list.items;
    }

    pub fn defaultDevice(ctx: Context, mode: main.Device.Mode) ?main.Device {
        return ctx.devices_info.default(mode);
    }

    pub fn createPlayer(ctx: *Context, device: main.Device, writeFn: main.WriteFn, options: main.StreamOptions) !backends.Player {
        const player = try ctx.allocator.create(Player);
        errdefer ctx.allocator.destroy(player);

        // obtain an AudioOutputUnit using an AUHAL component description
        var component_desc = c.AudioComponentDescription{
            .componentType = c.kAudioUnitType_Output,
            .componentSubType = c.kAudioUnitSubType_HALOutput,
            .componentManufacturer = c.kAudioUnitManufacturer_Apple,
            .componentFlags = 0,
            .componentFlagsMask = 0,
        };
        const component = c.AudioComponentFindNext(null, &component_desc);
        if (component == null) return error.OpeningDevice;

        // instantiate the audio unit
        var audio_unit: c.AudioComponentInstance = undefined;
        if (c.AudioComponentInstanceNew(component, &audio_unit) != c.noErr) return error.OpeningDevice;

        // Initialize the AUHAL before making any changes or using it. Note that an AUHAL may need
        // to be initialized twice, e.g. before and after making changes to it, as an AUHAL needs to
        // be initialized *before* anything is done to it.
        if (c.AudioUnitInitialize(audio_unit) != c.noErr) return error.OpeningDevice;
        errdefer _ = c.AudioUnitUninitialize(audio_unit);

        const device_id = std.fmt.parseInt(c.AudioDeviceID, device.id, 10) catch return error.OpeningDevice;
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

        const stream_desc = try createStreamDesc(options.format, options.sample_rate orelse default_sample_rate, device.channels.len);
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
            .allocator = ctx.allocator,
            .audio_unit = audio_unit.?,
            .is_paused = false,
            .vol = 1.0,
            .writeFn = writeFn,
            .user_data = options.user_data,
            .channels = device.channels,
            .format = options.format,
            .sample_rate = options.sample_rate orelse default_sample_rate,
        };
        return .{ .coreaudio = player };
    }

    pub fn createRecorder(ctx: *Context, device: main.Device, readFn: main.ReadFn, options: main.StreamOptions) !backends.Recorder {
        // Request permission to record via requestRecordPermission. If permission was previously
        // granted, it will immediately return. Otherwise the function will block, the OS will display
        // an "<App> wants to access the Microphone. [Allow] [Deny]" menu, then the callback will be
        // invoked and requestRecordPermission will return.
        const audio_session = avaudio.AVAudioSession.sharedInstance();
        const PermissionContext = void;
        const perm_ctx: PermissionContext = {};
        audio_session.requestRecordPermission(perm_ctx, (struct {
            pub fn callback(perm_ctx_2: PermissionContext, permission_granted: bool) void {
                _ = permission_granted;
                _ = perm_ctx_2;
                // Note: in the event permission was NOT granted by the user, we could capture that here
                // and surface it as an error.
                //
                // However, in this situation the OS will simply replace all audio samples with zero-value
                // (silence) ones - so there's no harm for us in doing nothing in that case: the user would
                // find out we're recording only silence, and they would need to correct it in their System
                // Preferences by granting the app permission to record.
            }
        }).callback);

        const recorder = try ctx.allocator.create(Recorder);
        errdefer ctx.allocator.destroy(recorder);

        const device_id = std.fmt.parseInt(c.AudioDeviceID, device.id, 10) catch return error.OpeningDevice;
        var io_size: u32 = 0;
        var prop_address = c.AudioObjectPropertyAddress{
            .mSelector = c.kAudioDevicePropertyStreamConfiguration,
            .mScope = c.kAudioObjectPropertyScopeInput,
            .mElement = c.kAudioObjectPropertyElementMain,
        };

        if (c.AudioObjectGetPropertyDataSize(
            device_id,
            &prop_address,
            0,
            null,
            &io_size,
        ) != c.noErr) {
            return error.OpeningDevice;
        }

        std.debug.assert(io_size == @sizeOf(c.AudioBufferList));
        const buf_list = try ctx.allocator.create(c.AudioBufferList);
        errdefer ctx.allocator.destroy(buf_list);

        if (c.AudioObjectGetPropertyData(
            device_id,
            &prop_address,
            0,
            null,
            &io_size,
            @as(*anyopaque, @ptrCast(buf_list)),
        ) != c.noErr) {
            return error.OpeningDevice;
        }

        // obtain an AudioOutputUnit using an AUHAL component description
        var component_desc = c.AudioComponentDescription{
            .componentType = c.kAudioUnitType_Output,
            .componentSubType = c.kAudioUnitSubType_HALOutput,
            .componentManufacturer = c.kAudioUnitManufacturer_Apple,
            .componentFlags = 0,
            .componentFlagsMask = 0,
        };
        const component = c.AudioComponentFindNext(null, &component_desc);
        if (component == null) return error.OpeningDevice;

        // instantiate the audio unit
        var audio_unit: c.AudioComponentInstance = undefined;
        if (c.AudioComponentInstanceNew(component, &audio_unit) != c.noErr) return error.OpeningDevice;

        // Initialize the AUHAL before making any changes or using it. Note that an AUHAL may need
        // to be initialized twice, e.g. before and after making changes to it, as an AUHAL needs to
        // be initialized *before* anything is done to it.
        if (c.AudioUnitInitialize(audio_unit) != c.noErr) return error.OpeningDevice;
        errdefer _ = c.AudioUnitUninitialize(audio_unit);

        // To obtain the device input, we must enable IO on the input scope of the Audio Unit. Input
        // must be explicitly enabled with kAudioOutputUnitProperty_EnableIO on Element 1 of the
        // AUHAL, and this *must be done before* setting the AUHAL's current device. We must also
        // disable IO on the output scope of the AUHAL, since it can be used for both.

        // Enable AUHAL input
        const enable_io: u32 = 1;
        const au_element_input: u32 = 1;
        if (c.AudioUnitSetProperty(
            audio_unit,
            c.kAudioOutputUnitProperty_EnableIO,
            c.kAudioUnitScope_Input,
            au_element_input,
            &enable_io,
            @sizeOf(u32),
        ) != c.noErr) {
            return error.OpeningDevice;
        }

        // Disable AUHAL output
        const disable_io: u32 = 0;
        const au_element_output: u32 = 0;
        if (c.AudioUnitSetProperty(
            audio_unit,
            c.kAudioOutputUnitProperty_EnableIO,
            c.kAudioUnitScope_Output,
            au_element_output,
            &disable_io,
            @sizeOf(u32),
        ) != c.noErr) {
            return error.OpeningDevice;
        }

        // Set the audio device to be Audio Unit's current device. A device can only be associated
        // with an AUHAL after enabling IO.
        if (c.AudioUnitSetProperty(
            audio_unit,
            c.kAudioOutputUnitProperty_CurrentDevice,
            c.kAudioUnitScope_Global,
            au_element_output,
            &device_id,
            @sizeOf(c.AudioDeviceID),
        ) != c.noErr) {
            return error.OpeningDevice;
        }

        // Register the capture callback for the AUHAL; this will be called when the AUHAL has
        // received new data from the input device.
        const capture_callback = c.AURenderCallbackStruct{
            .inputProc = Recorder.captureCallback,
            .inputProcRefCon = recorder,
        };
        if (c.AudioUnitSetProperty(
            audio_unit,
            c.kAudioOutputUnitProperty_SetInputCallback,
            c.kAudioUnitScope_Global,
            au_element_output,
            &capture_callback,
            @sizeOf(c.AURenderCallbackStruct),
        ) != c.noErr) {
            return error.OpeningDevice;
        }

        // Set the desired output format.
        const sample_rate = blk: {
            if (options.sample_rate) |rate| {
                if (rate < device.sample_rate.min or rate > device.sample_rate.max) return error.OpeningDevice;
                break :blk rate;
            }
            break :blk device.sample_rate.max;
        };
        const stream_desc = try createStreamDesc(options.format, sample_rate, device.channels.len);
        if (c.AudioUnitSetProperty(
            audio_unit,
            c.kAudioUnitProperty_StreamFormat,
            c.kAudioUnitScope_Output,
            au_element_input,
            &stream_desc,
            @sizeOf(c.AudioStreamBasicDescription),
        ) != c.noErr) {
            return error.OpeningDevice;
        }

        // Now that we are done with modifying the AUHAL, initialize it once more to ensure that it
        // is ready to use.
        if (c.AudioUnitInitialize(audio_unit) != c.noErr) return error.OpeningDevice;
        errdefer _ = c.AudioUnitUninitialize(audio_unit);

        recorder.* = .{
            .allocator = ctx.allocator,
            .audio_unit = audio_unit.?,
            .is_paused = false,
            .vol = 1.0,
            .buf_list = buf_list,
            .readFn = readFn,
            .user_data = options.user_data,
            .channels = device.channels,
            .format = options.format,
            .sample_rate = sample_rate,
        };
        return .{ .coreaudio = recorder };
    }
};

pub const Player = struct {
    allocator: std.mem.Allocator,
    audio_unit: c.AudioUnit,
    is_paused: bool,
    vol: f32,
    writeFn: main.WriteFn,
    user_data: ?*anyopaque,

    channels: []main.ChannelPosition,
    format: main.Format,
    sample_rate: u24,

    pub fn renderCallback(
        player_opaque: ?*anyopaque,
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

        const player = @as(*Player, @ptrCast(@alignCast(player_opaque.?)));

        const frames = buf.*.mBuffers[0].mDataByteSize;
        player.writeFn(player.user_data, @as([*]u8, @ptrCast(buf.*.mBuffers[0].mData.?))[0..frames]);

        return c.noErr;
    }

    pub fn deinit(player: *Player) void {
        _ = c.AudioOutputUnitStop(player.audio_unit);
        _ = c.AudioUnitUninitialize(player.audio_unit);
        _ = c.AudioComponentInstanceDispose(player.audio_unit);
        player.allocator.destroy(player);
    }

    pub fn start(player: *Player) !void {
        try player.play();
    }

    pub fn play(player: *Player) !void {
        if (c.AudioOutputUnitStart(player.audio_unit) != c.noErr) {
            return error.CannotPlay;
        }
        player.is_paused = false;
    }

    pub fn pause(player: *Player) !void {
        if (c.AudioOutputUnitStop(player.audio_unit) != c.noErr) {
            return error.CannotPause;
        }
        player.is_paused = true;
    }

    pub fn paused(player: *Player) bool {
        return player.is_paused;
    }

    pub fn setVolume(player: *Player, vol: f32) !void {
        if (c.AudioUnitSetParameter(
            player.audio_unit,
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

    pub fn volume(player: *Player) !f32 {
        var vol: f32 = 0;
        if (c.AudioUnitGetParameter(
            player.audio_unit,
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

pub const Recorder = struct {
    allocator: std.mem.Allocator,
    audio_unit: c.AudioUnit,
    is_paused: bool,
    vol: f32,
    buf_list: *c.AudioBufferList,
    m_data: ?[]u8 = null,
    readFn: main.ReadFn,
    user_data: ?*anyopaque,

    channels: []main.ChannelPosition,
    format: main.Format,
    sample_rate: u24,

    pub fn captureCallback(
        recorder_opaque: ?*anyopaque,
        action_flags: [*c]c.AudioUnitRenderActionFlags,
        time_stamp: [*c]const c.AudioTimeStamp,
        bus_number: u32,
        num_frames: u32,
        buffer_list: [*c]c.AudioBufferList,
    ) callconv(.C) c.OSStatus {
        _ = buffer_list;

        const recorder = @as(*Recorder, @ptrCast(@alignCast(recorder_opaque.?)));

        // We want interleaved multi-channel audio, when multiple channels are available-so we'll
        // only use a single buffer. If we wanted non-interleaved audio we would use multiple
        // buffers.
        var m_buffer = &recorder.buf_list.*.mBuffers[0];

        // Ensure our buffer matches the size needed for the render operation. Note that the buffer
        // may grow (in the case of multi-channel audio during the first render callback) or shrink
        // in e.g. the event of the device being unplugged and the default input device switching.
        const new_len = num_frames * recorder.format.frameSize(@intCast(recorder.channels.len));
        if (recorder.m_data == null or recorder.m_data.?.len != new_len) {
            if (recorder.m_data) |old| recorder.allocator.free(old);
            recorder.m_data = recorder.allocator.alloc(u8, new_len) catch return c.noErr;
        }
        recorder.buf_list.*.mNumberBuffers = 1;
        m_buffer.mData = recorder.m_data.?.ptr;
        m_buffer.mDataByteSize = @intCast(recorder.m_data.?.len);
        m_buffer.mNumberChannels = @intCast(recorder.channels.len);

        const err_no = c.AudioUnitRender(
            recorder.audio_unit,
            action_flags,
            time_stamp,
            bus_number,
            num_frames,
            recorder.buf_list,
        );
        if (err_no != c.noErr) {
            // TODO: err_no here is rather helpful, we should indicate what it is back to the user
            // in this event probably?
            return c.noErr;
        }

        if (recorder.buf_list.*.mNumberBuffers == 1) {
            recorder.readFn(recorder.user_data, @as([*]u8, @ptrCast(recorder.buf_list.*.mBuffers[0].mData.?))[0..new_len]);
        } else {
            @panic("TODO: convert planar to interleaved");
            // for (recorder.channels, 0..) |*ch, i| {
            //     ch.ptr = @as([*]u8, @ptrCast(recorder.buf_list.*.mBuffers[i].mData.?));
            // }
        }

        return c.noErr;
    }

    pub fn deinit(recorder: *Recorder) void {
        _ = c.AudioOutputUnitStop(recorder.audio_unit);
        _ = c.AudioUnitUninitialize(recorder.audio_unit);
        _ = c.AudioComponentInstanceDispose(recorder.audio_unit);
        recorder.allocator.destroy(recorder.buf_list);
        recorder.allocator.destroy(recorder);
    }

    pub fn start(recorder: *Recorder) !void {
        try recorder.record();
    }

    pub fn record(recorder: *Recorder) !void {
        if (c.AudioOutputUnitStart(recorder.audio_unit) != c.noErr) {
            return error.CannotRecord;
        }
        recorder.is_paused = false;
    }

    pub fn pause(recorder: *Recorder) !void {
        if (c.AudioOutputUnitStop(recorder.audio_unit) != c.noErr) {
            return error.CannotPause;
        }
        recorder.is_paused = true;
    }

    pub fn paused(recorder: *Recorder) bool {
        return recorder.is_paused;
    }

    pub fn setVolume(recorder: *Recorder, vol: f32) !void {
        if (c.AudioUnitSetParameter(
            recorder.audio_unit,
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

    pub fn volume(recorder: *Recorder) !f32 {
        var vol: f32 = 0;
        if (c.AudioUnitGetParameter(
            recorder.audio_unit,
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
            // TODO(i24)
            // .i24 => c.kAudioFormatFlagIsSignedInteger,
            .i32 => c.kAudioFormatFlagIsSignedInteger,
            .f32 => c.kAudioFormatFlagIsFloat,
            .u8 => return error.IncompatibleDevice,
        },
        .mBytesPerPacket = format.frameSize(@intCast(ch_count)),
        .mFramesPerPacket = 1,
        .mBytesPerFrame = format.frameSize(@intCast(ch_count)),
        .mChannelsPerFrame = @intCast(ch_count),
        .mBitsPerChannel = switch (format) {
            .i16 => 16,
            // TODO(i24)
            // .i24 => 24,
            .i32 => 32,
            .f32 => 32,
            .u8 => return error.IncompatibleDevice,
        },
        .mReserved = 0,
    };

    if (native_endian == .big) {
        desc.mFormatFlags |= c.kAudioFormatFlagIsBigEndian;
    }

    return desc;
}
