const std = @import("std");
const win32 = @import("../win32.zig");
const main = @import("main.zig");
const backends = @import("backends.zig");
const util = @import("util.zig");

pub const Context = struct {
    allocator: std.mem.Allocator,
    devices_info: util.DevicesInfo,
    enumerator: ?*win32.IMMDeviceEnumerator,
    watcher: ?Watcher,
    is_wine: bool,

    const Watcher = struct {
        deviceChangeFn: main.Context.DeviceChangeFn,
        user_data: ?*anyopaque,
        notif_client: win32.IMMNotificationClient,
    };

    pub fn init(allocator: std.mem.Allocator, options: main.Context.Options) !backends.Context {
        const flags = win32.COINIT_APARTMENTTHREADED | win32.COINIT_DISABLE_OLE1DDE;
        var hr = win32.CoInitializeEx(null, flags);
        switch (hr) {
            win32.S_OK,
            win32.S_FALSE,
            win32.RPC_E_CHANGED_MODE,
            => {},
            win32.E_OUTOFMEMORY => return error.OutOfMemory,
            win32.E_UNEXPECTED => return error.SystemResources,
            win32.E_INVALIDARG => unreachable,
            else => unreachable,
        }

        var ctx = try allocator.create(Context);
        errdefer allocator.destroy(ctx);
        ctx.* = .{
            .allocator = allocator,
            .devices_info = util.DevicesInfo.init(),
            .enumerator = blk: {
                var enumerator: ?*win32.IMMDeviceEnumerator = null;
                hr = win32.CoCreateInstance(
                    win32.CLSID_MMDeviceEnumerator,
                    null,
                    win32.CLSCTX_ALL,
                    win32.IID_IMMDeviceEnumerator,
                    @as(*?*anyopaque, @ptrCast(&enumerator)),
                );
                switch (hr) {
                    win32.S_OK => {},
                    win32.E_POINTER => unreachable,
                    win32.E_NOINTERFACE => unreachable,
                    win32.CLASS_E_NOAGGREGATION => return error.SystemResources,
                    win32.REGDB_E_CLASSNOTREG => unreachable,
                    else => unreachable,
                }
                break :blk enumerator;
            },
            .watcher = if (options.deviceChangeFn) |deviceChangeFn| .{
                .deviceChangeFn = deviceChangeFn,
                .user_data = options.user_data,
                .notif_client = win32.IMMNotificationClient{
                    .vtable = &.{
                        .base = .{
                            .QueryInterface = queryInterfaceCB,
                            .AddRef = addRefCB,
                            .Release = releaseCB,
                        },
                        .OnDeviceStateChanged = onDeviceStateChangedCB,
                        .OnDeviceAdded = onDeviceAddedCB,
                        .OnDeviceRemoved = onDeviceRemovedCB,
                        .OnDefaultDeviceChanged = onDefaultDeviceChangedCB,
                        .OnPropertyValueChanged = onPropertyValueChangedCB,
                    },
                },
            } else null,
            .is_wine = blk: {
                const hntdll = win32.GetModuleHandleA("ntdll.dll");
                if (hntdll) |_| {
                    if (win32.GetProcAddress(hntdll, "wine_get_version")) |_| {
                        break :blk true;
                    }
                }
                break :blk false;
            },
        };

        if (options.deviceChangeFn) |_| {
            hr = ctx.enumerator.?.RegisterEndpointNotificationCallback(&ctx.watcher.?.notif_client);
            switch (hr) {
                win32.S_OK => {},
                win32.E_POINTER => unreachable,
                win32.E_OUTOFMEMORY => return error.OutOfMemory,
                else => return error.SystemResources,
            }
        }

        return .{ .wasapi = ctx };
    }

    fn queryInterfaceCB(ctx: *const win32.IUnknown, riid: ?*const win32.Guid, ppv: ?*?*anyopaque) callconv(std.os.windows.WINAPI) win32.HRESULT {
        if (riid.?.eql(win32.IID_IUnknown.*) or riid.?.eql(win32.IID_IMMNotificationClient.*)) {
            ppv.?.* = @as(?*anyopaque, @ptrFromInt(@intFromPtr(ctx)));
            _ = ctx.IUnknown_AddRef();
            return win32.S_OK;
        } else {
            ppv.?.* = null;
            return win32.E_NOINTERFACE;
        }
    }

    fn addRefCB(_: *const win32.IUnknown) callconv(std.os.windows.WINAPI) u32 {
        return 1;
    }

    fn releaseCB(_: *const win32.IUnknown) callconv(std.os.windows.WINAPI) u32 {
        return 1;
    }

    fn onDeviceStateChangedCB(ctx: *const win32.IMMNotificationClient, _: ?[*:0]const u16, _: u32) callconv(std.os.windows.WINAPI) win32.HRESULT {
        var watcher: *Watcher = @constCast(@fieldParentPtr("notif_client", ctx));
        watcher.deviceChangeFn(watcher.user_data);
        return win32.S_OK;
    }

    fn onDeviceAddedCB(ctx: *const win32.IMMNotificationClient, _: ?[*:0]const u16) callconv(std.os.windows.WINAPI) win32.HRESULT {
        var watcher: *Watcher = @constCast(@fieldParentPtr("notif_client", ctx));
        watcher.deviceChangeFn(watcher.user_data);
        return win32.S_OK;
    }

    fn onDeviceRemovedCB(ctx: *const win32.IMMNotificationClient, _: ?[*:0]const u16) callconv(std.os.windows.WINAPI) win32.HRESULT {
        var watcher: *Watcher = @constCast(@fieldParentPtr("notif_client", ctx));
        watcher.deviceChangeFn(watcher.user_data);
        return win32.S_OK;
    }

    fn onDefaultDeviceChangedCB(ctx: *const win32.IMMNotificationClient, _: win32.DataFlow, _: win32.Role, _: ?[*:0]const u16) callconv(std.os.windows.WINAPI) win32.HRESULT {
        var watcher: *Watcher = @constCast(@fieldParentPtr("notif_client", ctx));
        watcher.deviceChangeFn(watcher.user_data);
        return win32.S_OK;
    }

    fn onPropertyValueChangedCB(ctx: *const win32.IMMNotificationClient, _: ?[*:0]const u16, _: win32.PROPERTYKEY) callconv(std.os.windows.WINAPI) win32.HRESULT {
        var watcher: *Watcher = @constCast(@fieldParentPtr("notif_client", ctx));
        watcher.deviceChangeFn(watcher.user_data);
        return win32.S_OK;
    }

    pub fn deinit(ctx: *Context) void {
        if (ctx.watcher) |*watcher| {
            _ = ctx.enumerator.?.UnregisterEndpointNotificationCallback(&watcher.notif_client);
        }
        _ = ctx.enumerator.?.IUnknown_Release();
        for (ctx.devices_info.list.items) |d|
            freeDevice(ctx.allocator, d);
        ctx.devices_info.list.deinit(ctx.allocator);
        ctx.allocator.destroy(ctx);
    }

    pub fn refresh(ctx: *Context) !void {
        // get default devices id
        const default_playback_id = try ctx.getDefaultAudioEndpoint(.playback);
        defer ctx.allocator.free(default_playback_id.?);
        const default_capture_id = try ctx.getDefaultAudioEndpoint(.capture);
        if (default_capture_id) |default_id| {
            defer ctx.allocator.free(default_id);
        }

        // enumerate
        var collection: ?*win32.IMMDeviceCollection = null;
        var hr = ctx.enumerator.?.EnumAudioEndpoints(
            win32.DataFlow.all,
            win32.DEVICE_STATE_ACTIVE,
            &collection,
        );
        switch (hr) {
            win32.S_OK => {},
            win32.E_POINTER => unreachable,
            win32.E_INVALIDARG => unreachable,
            win32.E_OUTOFMEMORY => return error.OutOfMemory,
            else => return error.OpeningDevice,
        }
        defer _ = collection.?.IUnknown_Release();

        var device_count: u32 = 0;
        hr = collection.?.GetCount(&device_count);
        switch (hr) {
            win32.S_OK => {},
            win32.E_POINTER => unreachable,
            else => return error.OpeningDevice,
        }

        var i: u32 = 0;
        while (i < device_count) : (i += 1) {
            var imm_device: ?*win32.IMMDevice = null;
            hr = collection.?.Item(i, &imm_device);
            switch (hr) {
                win32.S_OK => {},
                win32.E_POINTER => unreachable,
                win32.E_INVALIDARG => unreachable,
                else => return error.OpeningDevice,
            }
            defer _ = imm_device.?.IUnknown_Release();

            var property_store: ?*win32.IPropertyStore = null;
            var variant: win32.PROPVARIANT = undefined;
            hr = imm_device.?.OpenPropertyStore(win32.STGM_READ, &property_store);
            switch (hr) {
                win32.S_OK => {},
                win32.E_POINTER => unreachable,
                win32.E_INVALIDARG => unreachable,
                win32.E_OUTOFMEMORY => return error.OutOfMemory,
                else => return error.OpeningDevice,
            }
            defer _ = property_store.?.IUnknown_Release();

            hr = property_store.?.GetValue(&win32.PKEY_AudioEngine_DeviceFormat, &variant);
            switch (hr) {
                win32.S_OK, win32.INPLACE_S_TRUNCATED => {},
                else => return error.OpeningDevice,
            }
            const wf: *win32.WAVEFORMATEXTENSIBLE = @ptrCast(variant.anon.anon.anon.blob.pBlobData);
            defer win32.CoTaskMemFree(variant.anon.anon.anon.blob.pBlobData);

            const channels = blk: {
                var chn_arr = std.ArrayList(main.ChannelPosition).init(ctx.allocator);
                var channel: u32 = win32.SPEAKER_FRONT_LEFT;
                while (channel < win32.SPEAKER_ALL) : (channel <<= 1) {
                    if (wf.dwChannelMask & channel != 0) try chn_arr.append(fromWASApiChannel(channel));
                }
                break :blk try chn_arr.toOwnedSlice();
            };

            const sample_rate = util.Range(u24){
                .min = @intCast(wf.Format.nSamplesPerSec),
                .max = @intCast(wf.Format.nSamplesPerSec),
            };

            const formats = blk: {
                var audio_client: ?*win32.IAudioClient = null;
                hr = imm_device.?.Activate(win32.IID_IAudioClient, win32.CLSCTX_ALL, null, @as(?*?*anyopaque, @ptrCast(&audio_client)));
                switch (hr) {
                    win32.S_OK => {},
                    win32.E_POINTER => unreachable,
                    win32.E_INVALIDARG => unreachable,
                    win32.E_NOINTERFACE => unreachable,
                    win32.E_OUTOFMEMORY => return error.OutOfMemory,
                    win32.AUDCLNT_E_DEVICE_INVALIDATED => unreachable,
                    else => return error.OpeningDevice,
                }

                var fmt_arr = std.ArrayList(main.Format).init(ctx.allocator);
                var closest_match: ?*win32.WAVEFORMATEX = null;
                for (std.meta.tags(main.Format)) |format| {
                    const wave_format = makeWaveFormatExtensible(format, channels, @intCast(wf.Format.nSamplesPerSec));

                    if (audio_client.?.IsFormatSupported(
                        .SHARED,
                        @as(?*const win32.WAVEFORMATEX, @ptrCast(@alignCast(&wave_format))),
                        &closest_match,
                    ) == win32.S_OK) {
                        try fmt_arr.append(format);
                    }
                }

                break :blk try fmt_arr.toOwnedSlice();
            };

            const id = blk: {
                var id_u16: ?[*:0]u16 = undefined;
                hr = imm_device.?.GetId(&id_u16);
                switch (hr) {
                    win32.S_OK => {},
                    win32.E_POINTER => unreachable,
                    win32.E_OUTOFMEMORY => return error.OutOfMemory,
                    else => return error.OpeningDevice,
                }
                defer win32.CoTaskMemFree(id_u16);

                break :blk std.unicode.utf16LeToUtf8AllocZ(ctx.allocator, std.mem.span(id_u16.?)) catch |err| switch (err) {
                    error.OutOfMemory => return error.OutOfMemory,
                    else => return error.OpeningDevice,
                };
            };

            const name = blk: {
                hr = property_store.?.GetValue(&win32.PKEY_Device_FriendlyName, &variant);
                switch (hr) {
                    win32.S_OK, win32.INPLACE_S_TRUNCATED => {},
                    else => return error.OpeningDevice,
                }
                defer win32.CoTaskMemFree(variant.anon.anon.anon.pwszVal);

                break :blk std.unicode.utf16LeToUtf8AllocZ(
                    ctx.allocator,
                    std.mem.span(variant.anon.anon.anon.pwszVal.?),
                ) catch |err| switch (err) {
                    error.OutOfMemory => return error.OutOfMemory,
                    else => return error.OpeningDevice,
                };
            };

            const dataflow = blk: {
                var endpoint: ?*win32.IMMEndpoint = null;
                hr = imm_device.?.IUnknown_QueryInterface(win32.IID_IMMEndpoint, @as(?*?*anyopaque, @ptrCast(&endpoint)));
                switch (hr) {
                    win32.S_OK => {},
                    win32.E_POINTER => unreachable,
                    win32.E_NOINTERFACE => unreachable,
                    else => unreachable,
                }
                defer _ = endpoint.?.IUnknown_Release();

                var dataflow: win32.DataFlow = undefined;
                hr = endpoint.?.GetDataFlow(&dataflow);
                switch (hr) {
                    win32.S_OK => {},
                    win32.E_POINTER => unreachable,
                    else => return error.OpeningDevice,
                }
                break :blk dataflow;
            };

            const modes: []const main.Device.Mode = switch (dataflow) {
                .render => &.{.playback},
                .capture => &.{.capture},
                .all => &.{ .playback, .capture },
            };

            for (modes) |mode| {
                try ctx.devices_info.list.append(ctx.allocator, .{
                    .mode = mode,
                    .channels = channels,
                    .sample_rate = sample_rate,
                    .formats = formats,
                    .id = id,
                    .name = name,
                });
                switch (mode) {
                    .playback => if (default_playback_id) |default_id| {
                        if (std.mem.eql(u8, id, default_id)) {
                            ctx.devices_info.setDefault(.playback, ctx.devices_info.list.items.len - 1);
                        }
                    },
                    .capture => if (default_capture_id) |default_id| {
                        if (std.mem.eql(u8, id, default_id)) {
                            ctx.devices_info.setDefault(.capture, ctx.devices_info.list.items.len - 1);
                        }
                    },
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

    fn fromWASApiChannel(speaker: u32) main.ChannelPosition {
        return switch (speaker) {
            win32.SPEAKER_FRONT_CENTER => .front_center,
            win32.SPEAKER_FRONT_LEFT => .front_left,
            win32.SPEAKER_FRONT_RIGHT => .front_right,
            win32.SPEAKER_FRONT_LEFT_OF_CENTER => .front_left_center,
            win32.SPEAKER_FRONT_RIGHT_OF_CENTER => .front_right_center,
            win32.SPEAKER_BACK_CENTER => .back_center,
            win32.SPEAKER_BACK_LEFT => .back_left,
            win32.SPEAKER_BACK_RIGHT => .back_right,
            win32.SPEAKER_SIDE_LEFT => .side_left,
            win32.SPEAKER_SIDE_RIGHT => .side_right,
            win32.SPEAKER_TOP_CENTER => .top_center,
            win32.SPEAKER_TOP_FRONT_CENTER => .top_front_center,
            win32.SPEAKER_TOP_FRONT_LEFT => .top_front_left,
            win32.SPEAKER_TOP_FRONT_RIGHT => .top_front_right,
            win32.SPEAKER_TOP_BACK_CENTER => .top_back_center,
            win32.SPEAKER_TOP_BACK_LEFT => .top_back_left,
            win32.SPEAKER_TOP_BACK_RIGHT => .top_back_right,
            win32.SPEAKER_LOW_FREQUENCY => .lfe,
            else => unreachable,
        };
    }

    fn getDefaultAudioEndpoint(ctx: *Context, mode: main.Device.Mode) !?[:0]u8 {
        var default_playback_device: ?*win32.IMMDevice = null;
        var hr = ctx.enumerator.?.GetDefaultAudioEndpoint(
            if (mode == .playback) .render else .capture,
            if (mode == .playback) .console else .communications,
            &default_playback_device,
        );
        switch (hr) {
            win32.S_OK => {},
            win32.E_POINTER => unreachable,
            win32.E_INVALIDARG => unreachable,
            win32.E_OUTOFMEMORY => return error.OutOfMemory,
            win32.E_NOT_FOUND => return null,
            else => return error.OpeningDevice,
        }
        defer _ = default_playback_device.?.IUnknown_Release();

        var default_playback_id_u16: ?[*:0]u16 = undefined;
        hr = default_playback_device.?.GetId(&default_playback_id_u16);
        defer win32.CoTaskMemFree(default_playback_id_u16);
        switch (hr) {
            win32.S_OK => {},
            win32.E_POINTER => unreachable,
            win32.E_OUTOFMEMORY => return error.OutOfMemory,
            else => return error.OpeningDevice,
        }

        return std.unicode.utf16LeToUtf8AllocZ(ctx.allocator, std.mem.span(default_playback_id_u16.?)) catch |err| switch (err) {
            error.OutOfMemory => return error.OutOfMemory,
            else => return error.OpeningDevice,
        };
    }

    fn createAudioClient(
        ctx: *Context,
        device: main.Device,
        format: main.Format,
        sample_rate: u24,
        imm_device: *?*win32.IMMDevice,
        audio_client: *?*win32.IAudioClient,
        audio_client3: *?*win32.IAudioClient3,
        max_buffer_frames: *u32,
    ) !void {
        const id_u16 = std.unicode.utf8ToUtf16LeAllocZ(ctx.allocator, device.id) catch |err| switch (err) {
            error.OutOfMemory => return error.OutOfMemory,
            else => unreachable,
        };
        defer ctx.allocator.free(id_u16);
        var hr = ctx.enumerator.?.GetDevice(id_u16, imm_device);
        switch (hr) {
            win32.S_OK => {},
            win32.E_POINTER => unreachable,
            win32.E_OUTOFMEMORY => return error.OutOfMemory,
            else => return error.OpeningDevice,
        }

        hr = imm_device.*.?.Activate(win32.IID_IAudioClient3, win32.CLSCTX_ALL, null, @as(?*?*anyopaque, @ptrCast(audio_client3)));
        if (hr == win32.S_OK) {
            hr = audio_client3.*.?.IUnknown_QueryInterface(win32.IID_IAudioClient, @as(?*?*anyopaque, @ptrCast(audio_client)));
            switch (hr) {
                win32.S_OK => {},
                win32.E_NOINTERFACE => unreachable,
                win32.E_POINTER => unreachable,
                else => return error.OpeningDevice,
            }
        } else {
            hr = imm_device.*.?.Activate(win32.IID_IAudioClient, win32.CLSCTX_ALL, null, @as(?*?*anyopaque, @ptrCast(audio_client)));
            switch (hr) {
                win32.S_OK => {},
                win32.E_POINTER => unreachable,
                win32.E_INVALIDARG => unreachable,
                win32.E_NOINTERFACE => unreachable,
                win32.E_OUTOFMEMORY => return error.OutOfMemory,
                win32.AUDCLNT_E_DEVICE_INVALIDATED => return error.OpeningDevice,
                else => return error.OpeningDevice,
            }
        }

        const wave_format = makeWaveFormatExtensible(format, device.channels, sample_rate);

        if (!ctx.is_wine and audio_client3.* != null) {
            hr = audio_client3.*.?.InitializeSharedAudioStream(
                win32.AUDCLNT_STREAMFLAGS_EVENTCALLBACK,
                0, // TODO: use the advantage of AudioClient3
                @as(?*const win32.WAVEFORMATEX, @ptrCast(@alignCast(&wave_format))),
                null,
            );
            switch (hr) {
                win32.S_OK => {},
                win32.E_OUTOFMEMORY => return error.OutOfMemory,
                win32.E_POINTER => unreachable,
                win32.E_INVALIDARG => unreachable,
                win32.AUDCLNT_E_ALREADY_INITIALIZED => unreachable,
                win32.AUDCLNT_E_WRONG_ENDPOINT_TYPE => unreachable,
                win32.AUDCLNT_E_CPUUSAGE_EXCEEDED => return error.OpeningDevice,
                win32.AUDCLNT_E_DEVICE_INVALIDATED => return error.OpeningDevice,
                win32.AUDCLNT_E_DEVICE_IN_USE => unreachable,
                win32.AUDCLNT_E_ENGINE_FORMAT_LOCKED => return error.OpeningDevice,
                win32.AUDCLNT_E_ENGINE_PERIODICITY_LOCKED => return error.OpeningDevice,
                win32.AUDCLNT_E_ENDPOINT_CREATE_FAILED => return error.OpeningDevice,
                win32.AUDCLNT_E_INVALID_DEVICE_PERIOD => return error.OpeningDevice,
                win32.AUDCLNT_E_UNSUPPORTED_FORMAT => unreachable,
                win32.AUDCLNT_E_SERVICE_NOT_RUNNING => return error.OpeningDevice,
                else => return error.OpeningDevice,
            }
        } else {
            hr = audio_client.*.?.Initialize(
                .SHARED,
                win32.AUDCLNT_STREAMFLAGS_EVENTCALLBACK,
                0,
                0,
                @as(?*const win32.WAVEFORMATEX, @ptrCast(@alignCast(&wave_format))),
                null,
            );
            switch (hr) {
                win32.S_OK => {},
                win32.E_OUTOFMEMORY => return error.OutOfMemory,
                win32.E_POINTER => unreachable,
                win32.E_INVALIDARG => unreachable,
                win32.AUDCLNT_E_ALREADY_INITIALIZED => unreachable,
                win32.AUDCLNT_E_WRONG_ENDPOINT_TYPE => unreachable,
                win32.AUDCLNT_E_BUFFER_SIZE_NOT_ALIGNED => return error.OpeningDevice,
                win32.AUDCLNT_E_BUFFER_SIZE_ERROR => return error.OpeningDevice,
                win32.AUDCLNT_E_CPUUSAGE_EXCEEDED => return error.OpeningDevice,
                win32.AUDCLNT_E_DEVICE_INVALIDATED => return error.OpeningDevice,
                win32.AUDCLNT_E_DEVICE_IN_USE => unreachable,
                win32.AUDCLNT_E_ENDPOINT_CREATE_FAILED => return error.OpeningDevice,
                win32.AUDCLNT_E_INVALID_DEVICE_PERIOD => return error.OpeningDevice,
                win32.AUDCLNT_E_UNSUPPORTED_FORMAT => unreachable,
                win32.AUDCLNT_E_EXCLUSIVE_MODE_NOT_ALLOWED => unreachable,
                win32.AUDCLNT_E_BUFDURATION_PERIOD_NOT_EQUAL => unreachable,
                win32.AUDCLNT_E_SERVICE_NOT_RUNNING => return error.OpeningDevice,
                else => return error.OpeningDevice,
            }
        }

        hr = audio_client.*.?.GetBufferSize(max_buffer_frames);
        switch (hr) {
            win32.S_OK => {},
            win32.E_POINTER => unreachable,
            win32.AUDCLNT_E_NOT_INITIALIZED => unreachable,
            win32.AUDCLNT_E_DEVICE_INVALIDATED => return error.OpeningDevice,
            win32.AUDCLNT_E_SERVICE_NOT_RUNNING => return error.OpeningDevice,
            else => unreachable,
        }
    }

    fn createEvent(audio_client: ?*win32.IAudioClient) !?*anyopaque {
        const ready_event = win32.CreateEventA(null, 0, 0, null) orelse return error.SystemResources;
        const hr = audio_client.?.SetEventHandle(ready_event);
        switch (hr) {
            win32.S_OK => return ready_event,
            win32.E_INVALIDARG => unreachable,
            win32.AUDCLNT_E_EVENTHANDLE_NOT_EXPECTED => unreachable,
            win32.AUDCLNT_E_NOT_INITIALIZED => unreachable,
            win32.AUDCLNT_E_DEVICE_INVALIDATED => return error.OpeningDevice,
            win32.AUDCLNT_E_SERVICE_NOT_RUNNING => return error.OpeningDevice,
            else => return error.OpeningDevice,
        }
    }

    fn createSimpleVolume(audio_client: ?*win32.IAudioClient) !?*win32.ISimpleAudioVolume {
        var simple_volume: ?*win32.ISimpleAudioVolume = null;
        const hr = audio_client.?.GetService(win32.IID_ISimpleAudioVolume, @as(?*?*anyopaque, @ptrCast(&simple_volume)));
        switch (hr) {
            win32.S_OK => return simple_volume,
            win32.E_POINTER => unreachable,
            win32.E_NOINTERFACE => unreachable,
            win32.AUDCLNT_E_NOT_INITIALIZED => unreachable,
            win32.AUDCLNT_E_WRONG_ENDPOINT_TYPE => unreachable,
            win32.AUDCLNT_E_DEVICE_INVALIDATED => return error.OpeningDevice,
            win32.AUDCLNT_E_SERVICE_NOT_RUNNING => return error.OpeningDevice,
            else => return error.OpeningDevice,
        }
    }

    pub fn createPlayer(ctx: *Context, device: main.Device, writeFn: main.WriteFn, options: main.StreamOptions) !backends.Player {
        const format = device.preferredFormat(options.format);
        const sample_rate = device.sample_rate.min;

        var imm_device: ?*win32.IMMDevice = null;
        var audio_client: ?*win32.IAudioClient = null;
        var audio_client3: ?*win32.IAudioClient3 = null;
        var max_buffer_frames: u32 = 0;
        try ctx.createAudioClient(device, format, sample_rate, &imm_device, &audio_client, &audio_client3, &max_buffer_frames);

        var render_client: ?*win32.IAudioRenderClient = null;
        const hr = audio_client.?.GetService(win32.IID_IAudioRenderClient, @as(?*?*anyopaque, @ptrCast(&render_client)));
        switch (hr) {
            win32.S_OK => {},
            win32.E_POINTER => unreachable,
            win32.E_NOINTERFACE => unreachable,
            win32.AUDCLNT_E_NOT_INITIALIZED => unreachable,
            win32.AUDCLNT_E_WRONG_ENDPOINT_TYPE => unreachable,
            win32.AUDCLNT_E_DEVICE_INVALIDATED => return error.OpeningDevice,
            win32.AUDCLNT_E_SERVICE_NOT_RUNNING => return error.OpeningDevice,
            else => return error.OpeningDevice,
        }

        const simple_volume = try createSimpleVolume(audio_client);
        const ready_event = try createEvent(audio_client);

        const player = try ctx.allocator.create(Player);
        player.* = .{
            .allocator = ctx.allocator,
            .thread = undefined,
            .audio_client = audio_client,
            .audio_client3 = audio_client3,
            .simple_volume = simple_volume,
            .imm_device = imm_device,
            .render_client = render_client,
            .ready_event = ready_event,
            .max_buffer_frames = max_buffer_frames,
            .aborted = .{ .raw = false },
            .is_paused = false,
            .writeFn = writeFn,
            .user_data = options.user_data,
            .channels = device.channels,
            .format = format,
            .sample_rate = sample_rate,
        };
        return .{ .wasapi = player };
    }

    pub fn createRecorder(ctx: *Context, device: main.Device, readFn: main.ReadFn, options: main.StreamOptions) !backends.Recorder {
        const format = device.preferredFormat(options.format);
        const sample_rate = device.sample_rate.min;

        var imm_device: ?*win32.IMMDevice = null;
        var audio_client: ?*win32.IAudioClient = null;
        var audio_client3: ?*win32.IAudioClient3 = null;
        var max_buffer_frames: u32 = 0;
        try ctx.createAudioClient(device, format, sample_rate, &imm_device, &audio_client, &audio_client3, &max_buffer_frames);

        var capture_client: ?*win32.IAudioCaptureClient = null;
        const hr = audio_client.?.GetService(win32.IID_IAudioCaptureClient, @as(?*?*anyopaque, @ptrCast(&capture_client)));
        switch (hr) {
            win32.S_OK => {},
            win32.E_POINTER => unreachable,
            win32.E_NOINTERFACE => unreachable,
            win32.AUDCLNT_E_NOT_INITIALIZED => unreachable,
            win32.AUDCLNT_E_WRONG_ENDPOINT_TYPE => unreachable,
            win32.AUDCLNT_E_DEVICE_INVALIDATED => return error.OpeningDevice,
            win32.AUDCLNT_E_SERVICE_NOT_RUNNING => return error.OpeningDevice,
            else => return error.OpeningDevice,
        }

        const simple_volume = try createSimpleVolume(audio_client);
        const ready_event = try createEvent(audio_client);

        const recorder = try ctx.allocator.create(Recorder);
        recorder.* = .{
            .allocator = ctx.allocator,
            .thread = undefined,
            .audio_client = audio_client,
            .audio_client3 = audio_client3,
            .simple_volume = simple_volume,
            .imm_device = imm_device,
            .capture_client = capture_client,
            .ready_event = ready_event,
            .max_buffer_frames = max_buffer_frames,
            .aborted = .{ .raw = false },
            .is_paused = false,
            .readFn = readFn,
            .user_data = options.user_data,
            .channels = device.channels,
            .format = format,
            .sample_rate = sample_rate,
        };
        return .{ .wasapi = recorder };
    }

    fn makeWaveFormatExtensible(format: main.Format, channels: []const main.ChannelPosition, sample_rate: u24) win32.WAVEFORMATEXTENSIBLE {
        return win32.WAVEFORMATEXTENSIBLE{
            .Format = .{
                .wFormatTag = win32.WAVE_FORMAT_EXTENSIBLE,
                .nChannels = @as(u16, @intCast(channels.len)),
                .nSamplesPerSec = sample_rate,
                .nAvgBytesPerSec = sample_rate * format.frameSize(@intCast(channels.len)),
                .nBlockAlign = format.frameSize(@intCast(channels.len)),
                .wBitsPerSample = format.sizeBits(),
                .cbSize = 0x16,
            },
            .Samples = .{
                .wValidBitsPerSample = format.validSizeBits(),
            },
            .dwChannelMask = toChannelMask(channels),
            .SubFormat = toSubFormat(format),
        };
    }

    fn toSubFormat(format: main.Format) win32.Guid {
        return switch (format) {
            .u8, .i16, .i24, .i32 => win32.CLSID_KSDATAFORMAT_SUBTYPE_PCM.*,
            .f32 => win32.CLSID_KSDATAFORMAT_SUBTYPE_IEEE_FLOAT.*,
        };
    }

    fn toChannelMask(channels: []const main.ChannelPosition) u32 {
        var mask: u32 = 0;
        for (channels) |ch| {
            mask |= switch (ch) {
                .front_center => win32.SPEAKER_FRONT_CENTER,
                .front_left => win32.SPEAKER_FRONT_LEFT,
                .front_right => win32.SPEAKER_FRONT_RIGHT,
                .front_left_center => win32.SPEAKER_FRONT_LEFT_OF_CENTER,
                .front_right_center => win32.SPEAKER_FRONT_RIGHT_OF_CENTER,
                .back_center => win32.SPEAKER_BACK_CENTER,
                .back_left => win32.SPEAKER_BACK_LEFT,
                .back_right => win32.SPEAKER_BACK_RIGHT,
                .side_left => win32.SPEAKER_SIDE_LEFT,
                .side_right => win32.SPEAKER_SIDE_RIGHT,
                .top_center => win32.SPEAKER_TOP_CENTER,
                .top_front_center => win32.SPEAKER_TOP_FRONT_CENTER,
                .top_front_left => win32.SPEAKER_TOP_FRONT_LEFT,
                .top_front_right => win32.SPEAKER_TOP_FRONT_RIGHT,
                .top_back_center => win32.SPEAKER_TOP_BACK_CENTER,
                .top_back_left => win32.SPEAKER_TOP_BACK_LEFT,
                .top_back_right => win32.SPEAKER_TOP_BACK_RIGHT,
                .lfe => win32.SPEAKER_LOW_FREQUENCY,
            };
        }
        return mask;
    }
};

pub const Player = struct {
    allocator: std.mem.Allocator,
    thread: std.Thread,
    simple_volume: ?*win32.ISimpleAudioVolume,
    imm_device: ?*win32.IMMDevice,
    audio_client: ?*win32.IAudioClient,
    audio_client3: ?*win32.IAudioClient3,
    render_client: ?*win32.IAudioRenderClient,
    ready_event: ?*anyopaque,
    max_buffer_frames: u32,
    aborted: std.atomic.Value(bool),
    is_paused: bool,
    writeFn: main.WriteFn,
    user_data: ?*anyopaque,

    channels: []main.ChannelPosition,
    format: main.Format,
    sample_rate: u24,

    pub fn deinit(player: *Player) void {
        player.aborted.store(true, .unordered);
        player.thread.join();
        _ = player.simple_volume.?.IUnknown_Release();
        _ = player.render_client.?.IUnknown_Release();
        _ = player.audio_client.?.IUnknown_Release();
        _ = player.audio_client3.?.IUnknown_Release();
        _ = player.imm_device.?.IUnknown_Release();
        player.allocator.destroy(player);
    }

    pub fn start(player: *Player) !void {
        player.thread = std.Thread.spawn(.{}, writeThread, .{player}) catch |err| switch (err) {
            error.ThreadQuotaExceeded,
            error.SystemResources,
            error.LockedMemoryLimitExceeded,
            error.Unexpected,
            => return error.SystemResources,
            error.OutOfMemory => return error.OutOfMemory,
        };
    }

    fn writeThread(player: *Player) void {
        var hr = player.audio_client.?.Start();
        switch (hr) {
            win32.S_OK => {},
            win32.AUDCLNT_E_NOT_INITIALIZED => unreachable,
            win32.AUDCLNT_E_NOT_STOPPED => unreachable,
            win32.AUDCLNT_E_EVENTHANDLE_NOT_SET => unreachable,
            win32.AUDCLNT_E_DEVICE_INVALIDATED => return,
            win32.AUDCLNT_E_SERVICE_NOT_RUNNING => return,
            else => unreachable,
        }

        while (!player.aborted.load(.unordered)) {
            _ = win32.WaitForSingleObject(player.ready_event, win32.INFINITE);

            var padding_frames: u32 = 0;
            hr = player.audio_client.?.GetCurrentPadding(&padding_frames);
            switch (hr) {
                win32.S_OK => {},
                win32.E_POINTER => unreachable,
                win32.AUDCLNT_E_NOT_INITIALIZED => unreachable,
                win32.AUDCLNT_E_DEVICE_INVALIDATED => return,
                win32.AUDCLNT_E_SERVICE_NOT_RUNNING => return,
                else => unreachable,
            }

            const frames = player.max_buffer_frames - padding_frames;
            if (frames > 0) {
                var data: [*]u8 = undefined;
                hr = player.render_client.?.GetBuffer(frames, @as(?*?*u8, @ptrCast(&data)));
                switch (hr) {
                    win32.S_OK => {},
                    win32.E_POINTER => unreachable,
                    win32.AUDCLNT_E_BUFFER_ERROR => unreachable,
                    win32.AUDCLNT_E_BUFFER_TOO_LARGE => unreachable,
                    win32.AUDCLNT_E_BUFFER_SIZE_ERROR => unreachable,
                    win32.AUDCLNT_E_OUT_OF_ORDER => unreachable,
                    win32.AUDCLNT_E_DEVICE_INVALIDATED => return,
                    win32.AUDCLNT_E_BUFFER_OPERATION_PENDING => continue,
                    win32.AUDCLNT_E_SERVICE_NOT_RUNNING => return,
                    else => unreachable,
                }

                player.writeFn(
                    player.user_data,
                    data[0 .. frames * player.format.frameSize(@intCast(player.channels.len))],
                );

                hr = player.render_client.?.ReleaseBuffer(frames, 0);
                switch (hr) {
                    win32.S_OK => {},
                    win32.E_INVALIDARG => unreachable,
                    win32.AUDCLNT_E_INVALID_SIZE => unreachable,
                    win32.AUDCLNT_E_BUFFER_SIZE_ERROR => unreachable,
                    win32.AUDCLNT_E_OUT_OF_ORDER => unreachable,
                    win32.AUDCLNT_E_DEVICE_INVALIDATED => return,
                    win32.AUDCLNT_E_SERVICE_NOT_RUNNING => return,
                    else => unreachable,
                }
            }
        }
    }

    pub fn play(player: *Player) !void {
        if (player.paused()) {
            const hr = player.audio_client.?.Start();
            switch (hr) {
                win32.S_OK => {},
                win32.AUDCLNT_E_NOT_INITIALIZED => unreachable,
                win32.AUDCLNT_E_NOT_STOPPED => unreachable,
                win32.AUDCLNT_E_EVENTHANDLE_NOT_SET => unreachable,
                win32.AUDCLNT_E_DEVICE_INVALIDATED => return error.CannotPlay,
                win32.AUDCLNT_E_SERVICE_NOT_RUNNING => return error.CannotPlay,
                else => unreachable,
            }
            player.is_paused = false;
        }
    }

    pub fn pause(player: *Player) !void {
        if (!player.paused()) {
            const hr = player.audio_client.?.Stop();
            switch (hr) {
                win32.S_OK => {},
                win32.AUDCLNT_E_DEVICE_INVALIDATED => return error.CannotPause,
                win32.AUDCLNT_E_SERVICE_NOT_RUNNING => return error.CannotPause,
                else => unreachable,
            }
            player.is_paused = true;
        }
    }

    pub fn paused(player: *Player) bool {
        return player.is_paused;
    }

    pub fn setVolume(player: *Player, vol: f32) !void {
        const hr = player.simple_volume.?.SetMasterVolume(vol, null);
        switch (hr) {
            win32.S_OK => {},
            win32.E_INVALIDARG => unreachable,
            win32.AUDCLNT_E_DEVICE_INVALIDATED => return error.CannotSetVolume,
            win32.AUDCLNT_E_SERVICE_NOT_RUNNING => return error.CannotSetVolume,
            else => return error.CannotSetVolume,
        }
    }

    pub fn volume(player: *Player) !f32 {
        var vol: f32 = 0;
        const hr = player.simple_volume.?.GetMasterVolume(&vol);
        switch (hr) {
            win32.S_OK => {},
            win32.E_POINTER => unreachable,
            win32.AUDCLNT_E_DEVICE_INVALIDATED => return error.CannotGetVolume,
            win32.AUDCLNT_E_SERVICE_NOT_RUNNING => return error.CannotGetVolume,
            else => return error.CannotGetVolume,
        }
        return vol;
    }
};

pub const Recorder = struct {
    allocator: std.mem.Allocator,
    thread: std.Thread,
    simple_volume: ?*win32.ISimpleAudioVolume,
    imm_device: ?*win32.IMMDevice,
    audio_client: ?*win32.IAudioClient,
    audio_client3: ?*win32.IAudioClient3,
    capture_client: ?*win32.IAudioCaptureClient,
    ready_event: ?*anyopaque,
    max_buffer_frames: u32,
    aborted: std.atomic.Value(bool),
    is_paused: bool,
    readFn: main.ReadFn,
    user_data: ?*anyopaque,

    channels: []main.ChannelPosition,
    format: main.Format,
    sample_rate: u24,

    pub fn deinit(recorder: *Recorder) void {
        recorder.aborted.store(true, .unordered);
        recorder.thread.join();
        _ = recorder.simple_volume.?.IUnknown_Release();
        _ = recorder.capture_client.?.IUnknown_Release();
        _ = recorder.audio_client.?.IUnknown_Release();
        _ = recorder.audio_client3.?.IUnknown_Release();
        _ = recorder.imm_device.?.IUnknown_Release();
        recorder.allocator.destroy(recorder);
    }

    pub fn start(recorder: *Recorder) !void {
        recorder.thread = std.Thread.spawn(.{}, readThread, .{recorder}) catch |err| switch (err) {
            error.ThreadQuotaExceeded,
            error.SystemResources,
            error.LockedMemoryLimitExceeded,
            error.Unexpected,
            => return error.SystemResources,
            error.OutOfMemory => return error.OutOfMemory,
        };
    }

    fn readThread(recorder: *Recorder) void {
        var hr = recorder.audio_client.?.Start();
        switch (hr) {
            win32.S_OK => {},
            win32.AUDCLNT_E_NOT_INITIALIZED => unreachable,
            win32.AUDCLNT_E_NOT_STOPPED => unreachable,
            win32.AUDCLNT_E_EVENTHANDLE_NOT_SET => unreachable,
            win32.AUDCLNT_E_DEVICE_INVALIDATED => return,
            win32.AUDCLNT_E_SERVICE_NOT_RUNNING => return,
            else => unreachable,
        }

        while (!recorder.aborted.load(.unordered)) {
            _ = win32.WaitForSingleObject(recorder.ready_event, win32.INFINITE);

            var padding_frames: u32 = 0;
            hr = recorder.audio_client.?.GetCurrentPadding(&padding_frames);
            switch (hr) {
                win32.S_OK => {},
                win32.E_POINTER => unreachable,
                win32.AUDCLNT_E_NOT_INITIALIZED => unreachable,
                win32.AUDCLNT_E_DEVICE_INVALIDATED => return,
                win32.AUDCLNT_E_SERVICE_NOT_RUNNING => return,
                else => unreachable,
            }

            var frames = recorder.max_buffer_frames - padding_frames;
            if (frames > 0) {
                var data: [*]u8 = undefined;
                var flags: u32 = 0;
                hr = recorder.capture_client.?.GetBuffer(@as(?*?*u8, @ptrCast(&data)), &frames, &flags, null, null);
                switch (hr) {
                    win32.S_OK => {},
                    win32.E_POINTER => unreachable,
                    win32.AUDCLNT_E_BUFFER_ERROR => unreachable,
                    win32.AUDCLNT_E_BUFFER_TOO_LARGE => unreachable,
                    win32.AUDCLNT_E_BUFFER_SIZE_ERROR => unreachable,
                    win32.AUDCLNT_E_OUT_OF_ORDER => unreachable,
                    win32.AUDCLNT_E_DEVICE_INVALIDATED => return,
                    win32.AUDCLNT_E_BUFFER_OPERATION_PENDING => continue,
                    win32.AUDCLNT_E_SERVICE_NOT_RUNNING => return,
                    else => unreachable,
                }

                recorder.readFn(
                    recorder.user_data,
                    data[0 .. frames * recorder.format.frameSize(@intCast(recorder.channels.len))],
                );

                hr = recorder.capture_client.?.ReleaseBuffer(frames);
                switch (hr) {
                    win32.S_OK => {},
                    win32.E_INVALIDARG => unreachable,
                    win32.AUDCLNT_E_INVALID_SIZE => unreachable,
                    win32.AUDCLNT_E_BUFFER_SIZE_ERROR => unreachable,
                    win32.AUDCLNT_E_OUT_OF_ORDER => unreachable,
                    win32.AUDCLNT_E_DEVICE_INVALIDATED => return,
                    win32.AUDCLNT_E_SERVICE_NOT_RUNNING => return,
                    else => unreachable,
                }
            }
        }
    }

    pub fn record(recorder: *Recorder) !void {
        if (recorder.paused()) {
            const hr = recorder.audio_client.?.Start();
            switch (hr) {
                win32.S_OK => {},
                win32.AUDCLNT_E_NOT_INITIALIZED => unreachable,
                win32.AUDCLNT_E_NOT_STOPPED => unreachable,
                win32.AUDCLNT_E_EVENTHANDLE_NOT_SET => unreachable,
                win32.AUDCLNT_E_DEVICE_INVALIDATED => return error.CannotRecord,
                win32.AUDCLNT_E_SERVICE_NOT_RUNNING => return error.CannotRecord,
                else => unreachable,
            }
            recorder.is_paused = false;
        }
    }

    pub fn pause(recorder: *Recorder) !void {
        if (!recorder.paused()) {
            const hr = recorder.audio_client.?.Stop();
            switch (hr) {
                win32.S_OK => {},
                win32.AUDCLNT_E_DEVICE_INVALIDATED => return error.CannotPause,
                win32.AUDCLNT_E_SERVICE_NOT_RUNNING => return error.CannotPause,
                else => unreachable,
            }
            recorder.is_paused = true;
        }
    }

    pub fn paused(recorder: *Recorder) bool {
        return recorder.is_paused;
    }

    pub fn setVolume(recorder: *Recorder, vol: f32) !void {
        const hr = recorder.simple_volume.?.SetMasterVolume(vol, null);
        switch (hr) {
            win32.S_OK => {},
            win32.E_INVALIDARG => unreachable,
            win32.AUDCLNT_E_DEVICE_INVALIDATED => return error.CannotSetVolume,
            win32.AUDCLNT_E_SERVICE_NOT_RUNNING => return error.CannotSetVolume,
            else => return error.CannotSetVolume,
        }
    }

    pub fn volume(recorder: *Recorder) !f32 {
        var vol: f32 = 0;
        const hr = recorder.simple_volume.?.GetMasterVolume(&vol);
        switch (hr) {
            win32.S_OK => {},
            win32.E_POINTER => unreachable,
            win32.AUDCLNT_E_DEVICE_INVALIDATED => return error.CannotGetVolume,
            win32.AUDCLNT_E_SERVICE_NOT_RUNNING => return error.CannotGetVolume,
            else => return error.CannotGetVolume,
        }
        return vol;
    }
};

pub fn freeDevice(allocator: std.mem.Allocator, device: main.Device) void {
    allocator.free(device.id);
    allocator.free(device.name);
    allocator.free(device.formats);
    allocator.free(device.channels);
}
