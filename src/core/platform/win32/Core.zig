const std = @import("std");
const w = @import("win32.zig");
const mach = @import("../../../main.zig");
const gpu = mach.gpu;
const core = @import("../../main.zig");

const Joystick = core.Joystick;
const Frequency = @import("../../Frequency.zig");
const EventQueue = std.fifo.LinearFifo(core.Event, .Dynamic);
const Core = @This();

allocator: std.mem.Allocator,

window: w.HWND,
surrogate: u16 = 0,
dinput: *w.IDirectInput8W,

event_mutex: std.Thread.RwLock = .{},
events: EventQueue,
mutex: std.Thread.Mutex = .{},
limits: core.SizeLimit = .{ .min = .{}, .max = .{} },
oom: std.Thread.ResetEvent = .{},

// GPU state
instance: *gpu.Instance = undefined,
surface: *gpu.Surface = undefined,
gpu_adapter: *gpu.Adapter = undefined,
gpu_device: *gpu.Device = undefined,

swap_chain_mu: std.Thread.RwLock = .{},
swap_chain_desc: gpu.SwapChain.Descriptor = undefined,
swap_chain: *gpu.SwapChain = undefined,

const log = std.log.scoped(.mach);

////////////////////////////
/// Internals
////////////////////////////

const RequestAdapterResponse = struct {
    status: gpu.RequestAdapterStatus,
    adapter: ?*gpu.Adapter,
    message: ?[*:0]const u8,
};

inline fn requestAdapterCallback(
    context: *RequestAdapterResponse,
    status: gpu.RequestAdapterStatus,
    adapter: ?*gpu.Adapter,
    message: ?[*:0]const u8,
) void {
    context.* = RequestAdapterResponse{
        .status = status,
        .adapter = adapter,
        .message = message,
    };
}

inline fn printUnhandledErrorCallback(_: void, ty: gpu.ErrorType, message: [*:0]const u8) void {
    switch (ty) {
        .validation => std.log.err("gpu: validation error: {s}\n", .{message}),
        .out_of_memory => std.log.err("gpu: out of memory: {s}\n", .{message}),
        .device_lost => std.log.err("gpu: device lost: {s}\n", .{message}),
        .unknown => std.log.err("gpu: unknown error: {s}\n", .{message}),
        else => unreachable,
    }
    std.process.exit(1);
}

fn deviceLostCallback(reason: gpu.Device.LostReason, msg: [*:0]const u8, userdata: ?*anyopaque) callconv(.C) void {
    _ = userdata;
    _ = reason;
    log.err("mach: device lost: {s}", .{msg});
    @panic("mach: device lost");
}

fn gpusetup(self: *Core,
    window: w.HWND,
    options: core.Options) !void
{
    self.instance = gpu.createInstance(null) orelse {
        log.err("failed to create GPU instance", .{});
        std.process.exit(1);
    };
    self.surface = try createSurfaceForWindow(self.instance, window);

    var response: RequestAdapterResponse = undefined;
    self.instance.requestAdapter(&gpu.RequestAdapterOptions{
        .compatible_surface = self.surface,
        .power_preference = options.power_preference,
        .force_fallback_adapter = .false,
    }, &response, requestAdapterCallback);
    if (response.status != .success) {
        log.err("failed to create GPU adapter: {?s}", .{response.message});
        log.info("-> maybe try MACH_GPU_BACKEND=opengl ?", .{});
        std.process.exit(1);
    }

    // Print which adapter we are going to use.
    var props = std.mem.zeroes(gpu.Adapter.Properties);
    response.adapter.?.getProperties(&props);
    if (props.backend_type == .null) {
        log.err("no backend found for {s} adapter", .{props.adapter_type.name()});
        std.process.exit(1);
    }
    log.info("found {s} backend on {s} adapter: {s}, {s}\n", .{
        props.backend_type.name(),
        props.adapter_type.name(),
        props.name,
        props.driver_description,
    });

    // Create a device with default limits/features.
    self.gpu_device = response.adapter.?.createDevice(&.{
        .next_in_chain = .{
            .dawn_toggles_descriptor = &gpu.dawn.TogglesDescriptor.init(.{
                .enabled_toggles = &[_][*:0]const u8{
                    "allow_unsafe_apis",
                },
            }),
        },

        .required_features_count = if (options.required_features) |v| @as(u32, @intCast(v.len)) else 0,
        .required_features = if (options.required_features) |v| @as(?[*]const gpu.FeatureName, v.ptr) else null,
        .required_limits = if (options.required_limits) |limits| @as(?*const gpu.RequiredLimits, &gpu.RequiredLimits{
            .limits = limits,
        }) else null,
        .device_lost_callback = &deviceLostCallback,
        .device_lost_userdata = null,
    }) orelse {
        log.err("failed to create GPU device\n", .{});
        std.process.exit(1);
    };
    self.gpu_device.setUncapturedErrorCallback({}, printUnhandledErrorCallback);

//    const framebuffer_size =  window.getFramebufferSize();
    const swap_chain_desc = gpu.SwapChain.Descriptor{
        .label = "main swap chain",
        .usage = options.swap_chain_usage,
        .format = .bgra8_unorm,
        .width = @bitCast(options.size.width), //framebuffer_size.width,
        .height = @bitCast(options.size.height), //framebuffer_size.height,
        .present_mode = .mailbox,
    };
    self.swap_chain = self.gpu_device.createSwapChain(self.surface, &swap_chain_desc);

    core.adapter = response.adapter.?;
    core.device = self.gpu_device;
    core.queue = self.gpu_device.getQueue();
    core.swap_chain = self.swap_chain;
    core.descriptor = swap_chain_desc;

    self.gpu_adapter = core.adapter;
}

fn createSurfaceForWindow(
    instance: *gpu.Instance,
    window: w.HWND,
) !*gpu.Surface {
//    const glfw_native = glfw.Native(glfw_options);
    const extension = gpu.Surface.Descriptor.NextInChain{
        .from_windows_hwnd = &.{
            .hinstance = std.os.windows.kernel32.GetModuleHandleW(null).?,
            .hwnd = window,
        },
    };

    return instance.createSurface(&gpu.Surface.Descriptor{
        .next_in_chain = extension,
    });
}

////////////////////////////
/// Platform interface 
////////////////////////////
pub fn init(
    self: *Core,
    allocator: std.mem.Allocator,
    frame: *Frequency,
    input: *Frequency,
    options: core.Options,
) !void {
    _ = frame;
    _ = input;
    const hInstance = w.GetModuleHandleW(null);
    const class_name = w.L("mach");
    const class = std.mem.zeroInit(w.WNDCLASSW, .{
        .style = w.CS_OWNDC,
        .lpfnWndProc = wndProc,
        .hInstance = hInstance,
        .lpszClassName = class_name,
    });
    if (w.RegisterClassW(&class) == 0) return error.Unexpected;

    const title = try std.unicode.utf8ToUtf16LeAllocZ(allocator, options.title);
    defer allocator.free(title);

    const window = w.CreateWindowExW(
        .{.APPWINDOW = 1, .WINDOWEDGE = 1, .CLIENTEDGE = 1},
        class_name,
        title,
        if (options.border) w.WS_OVERLAPPEDWINDOW else w.WS_POPUPWINDOW,
        w.CW_USEDEFAULT,
        w.CW_USEDEFAULT,
        @bitCast(options.size.width),
        @bitCast(options.size.height),
        null,
        null,
        hInstance,
        null,
    ) orelse return error.Unexpected;

    var dinput: ?*w.IDirectInput8W = undefined;
    //@ptrCast(*anyopaque

    const ptr: ?*?*anyopaque = @ptrCast(&dinput);

    //    if (w.DirectInput8Create(instance, w.DIRECTINPUT_VERSION, &w.IID_IDirectInput8W, &dinput, null) != w.DI_OK) return error.Unexpected;
    if (w.DirectInput8Create(hInstance, w.DIRECTINPUT_VERSION, w.IID_IDirectInput8W, ptr, null) != w.DI_OK) {
        return error.Unexpected;
    }

    //try gpusetup(self, window, options);
    const instance = gpu.createInstance(null) orelse {
        log.err("failed to create GPU instance", .{});
        std.process.exit(1);
    };
    const surface = try createSurfaceForWindow(instance, window);

    var response: RequestAdapterResponse = undefined;
    instance.requestAdapter(&gpu.RequestAdapterOptions{
        .compatible_surface = surface,
        .power_preference = options.power_preference,
        .force_fallback_adapter = .false,
    }, &response, requestAdapterCallback);
    if (response.status != .success) {
        log.err("failed to create GPU adapter: {?s}", .{response.message});
        log.info("-> maybe try MACH_GPU_BACKEND=opengl ?", .{});
        std.process.exit(1);
    }

    // Print which adapter we are going to use.
    var props = std.mem.zeroes(gpu.Adapter.Properties);
    response.adapter.?.getProperties(&props);
    if (props.backend_type == .null) {
        log.err("no backend found for {s} adapter", .{props.adapter_type.name()});
        std.process.exit(1);
    }
    log.info("found {s} backend on {s} adapter: {s}, {s}\n", .{
        props.backend_type.name(),
        props.adapter_type.name(),
        props.name,
        props.driver_description,
    });

    // Create a device with default limits/features.
    const gpu_device = response.adapter.?.createDevice(&.{
        .next_in_chain = .{
            .dawn_toggles_descriptor = &gpu.dawn.TogglesDescriptor.init(.{
                .enabled_toggles = &[_][*:0]const u8{
                    "allow_unsafe_apis",
                },
            }),
        },

        .required_features_count = if (options.required_features) |v| @as(u32, @intCast(v.len)) else 0,
        .required_features = if (options.required_features) |v| @as(?[*]const gpu.FeatureName, v.ptr) else null,
        .required_limits = if (options.required_limits) |limits| @as(?*const gpu.RequiredLimits, &gpu.RequiredLimits{
            .limits = limits,
        }) else null,
        .device_lost_callback = &deviceLostCallback,
        .device_lost_userdata = null,
    }) orelse {
        log.err("failed to create GPU device\n", .{});
        std.process.exit(1);
    };
    gpu_device.setUncapturedErrorCallback({}, printUnhandledErrorCallback);

//    const framebuffer_size =  window.getFramebufferSize();
    const swap_chain_desc = gpu.SwapChain.Descriptor{
        .label = "main swap chain",
        .usage = options.swap_chain_usage,
        .format = .bgra8_unorm,
        .width = @bitCast(options.size.width), //framebuffer_size.width,
        .height = @bitCast(options.size.height), //framebuffer_size.height,
        .present_mode = .fifo, //.mailbox,
    };
    const swap_chain = gpu_device.createSwapChain(surface, &swap_chain_desc);

    core.adapter = response.adapter.?;
    core.device = gpu_device;
    core.queue = gpu_device.getQueue();
    core.swap_chain = swap_chain;
    core.descriptor = swap_chain_desc;

    self.* = .{
        .allocator = allocator,
        .window = window,
        .events = EventQueue.init(allocator),
        .dinput = dinput.?,

        .instance = instance,
        .surface = surface,
        .gpu_adapter = response.adapter.?,
        .gpu_device = gpu_device,
        //.max_refresh_rate = max_refresh_rate,
        .swap_chain = swap_chain,
        .swap_chain_desc = swap_chain_desc,
    };

    _ = w.SetWindowLongPtrW(window, w.GWLP_USERDATA, @bitCast(@intFromPtr(self)));
    if (!options.headless) {
        setDisplayMode(self, options.display_mode);
    }
}

pub fn deinit(self: *Core) void {
    self.events.deinit();
    _ = self.dinput.IUnknown_Release();

    self.gpu_device.setDeviceLostCallback(null, null);

    self.swap_chain.release();
    self.surface.release();
    core.queue.release();
    self.gpu_device.release();
    self.gpu_adapter.release();
    self.instance.release();    
}

pub fn update(self: *Core, app: anytype) !bool {
    _ = app;
//    _ = self;

    var msg: w.MSG = undefined;
    while (w.PeekMessageW(&msg, null, 0, 0, w.PM_REMOVE) != 0) {
        _ = w.TranslateMessage(&msg);
        _ = w.DispatchMessageW(&msg);
    }   

    self.gpu_device.tick();
    self.gpu_device.machWaitForCommandsToBeScheduled();

    return false;
}

pub const EventIterator = struct {
    mutex: *std.Thread.RwLock,
    queue: *EventQueue,

    pub fn next(self: *EventIterator) ?core.Event {
        self.mutex.lockShared();
        defer self.mutex.unlockShared();
        return self.queue.readItem();
    }
};

pub fn pollEvents(self: *Core) EventIterator {
    return .{ .mutex = &self.event_mutex, .queue = &self.events };
}

pub fn setTitle(self: *Core, title: [:0]const u8) void {
    const wtitle = std.unicode.utf8ToUtf16LeAllocZ(self.allocator, title) catch {
        self.oom.set();
        return;
    };
    defer self.allocator.free(wtitle);
    _ = w.SetWindowTextW(self.window, wtitle);
}

pub fn setDisplayMode(self: *Core, mode: core.DisplayMode) void {
    switch (mode) {
        .windowed => _ = w.ShowWindow(self.window, w.SW_RESTORE),
        //        .maximized => _ = w.ShowWindow(self.window, w.SW_MAXIMIZE),
        .fullscreen => {},
        .borderless => {},
    }
}

pub fn displayMode(self: *Core) core.DisplayMode {
    _ = self;
}

pub fn setBorder(self: *Core, value: bool) void {
    _ = w.SetWindowLongW(self.window, w.GWL_STYLE, if (value) w.WS_OVERLAPPEDWINDOW else w.WS_POPUPWINDOW);
}

pub fn border(self: *Core) bool {
    return w.GetWindowLongW(self.window, w.GWL_STYLE) == w.WS_OVERLAPPEDWINDOW;
}

pub fn setHeadless(self: *Core, value: bool) void {
    _ = w.ShowWindow(self.window, if (value) w.SW_HIDE else w.SW_SHOW);
}

pub fn headless(self: *Core) bool {
    _ = self;
}

pub fn setVSync(self: *Core, mode: core.VSyncMode) void {
    _ = self;
    _ = mode;
}

pub fn vsync(self: *Core) core.VSyncMode {
    _ = self;
}

pub fn setSize(self: *Core, value: core.Size) void {
    _ = w.SetWindowPos(self.window, 0, 0, 0, value.width, value.height, w.SWP_NOMOVE | w.SWP_NOZORDER | w.SWP_NOACTIVATE);
}

pub fn size(self: *Core) core.Size {
    var rect: w.RECT = undefined;
    _ = w.GetClientRect(self.window, &rect);

    const width:u32 = @intCast(rect.right - rect.left);
    const height:u32 = @intCast(rect.bottom - rect.top);

    return .{ .width = width, .height = height };
}

pub fn setSizeLimit(self: *Core, value: core.SizeLimit) void {
    self.mutex.lock();
    defer self.mutex.unlock();
    self.limits = value;
    // trigger WM_GETMINMAXINFO
    _ = w.SetWindowPos(self.window, 0, 0, 0, 0, 0, w.SWP_NOMOVE | w.SWP_NOSIZE | w.SWP_NOZORDER | w.SWP_NOACTIVATE);
}

pub fn sizeLimit(self: *Core) core.SizeLimit {
    self.mutex.lock();
    defer self.mutex.unlock();
    return self.limits;
}

pub fn setCursorMode(_: *Core, mode: core.CursorMode) void {
    switch (mode) {
        .normal => while (w.ShowCursor(true) < 0) {},
        .hidden => while (w.ShowCursor(false) >= 0) {},
        .disabled => {},
    }
}

pub fn cursorMode(_: *Core) core.CursorMode {
    w.ShowCursor(false);
    return w.ShowCursor(true) >= 0;
}

pub fn setCursorShape(_: *Core, shape: core.CursorShape) void {
    const name = switch (shape) {
        .arrow => w.IDC_ARROW,
        .ibeam => w.IDC_IBEAM,
        .crosshair => w.IDC_CROSS,
        .pointing_hand => w.IDC_HAND,
        .resize_ew => w.IDC_SIZEWE,
        .resize_ns => w.IDC_SIZENS,
        .resize_nwse => w.IDC_SIZENWSE,
        .resize_nesw => w.IDC_SIZENESW,
        .resize_all => w.IDC_SIZEALL,
        .not_allowed => w.IDC_NO,
    };
    _ = w.SetCursor(w.LoadCursorW(null, @ptrFromInt(name)));
}

pub fn cursorShape(self: *Core) core.CursorShape {
    _ = self;
}

pub fn keyPressed(self: *Core, key: core.Key) bool {
    _ = self;
    _ = key;
    // self.input_mutex.lockShared();
    // defer self.input_mutex.unlockShared();
    // return self.input_state.isKeyPressed(key);
}

pub fn keyReleased(self: *Core, key: core.Key) bool {
    _ = self;
    _ = key;
    // self.input_mutex.lockShared();
    // defer self.input_mutex.unlockShared();
    // return self.input_state.isKeyReleased(key);
}

pub fn mousePressed(self: *Core, button: core.MouseButton) bool {
    _ = self;
    _ = button;
    // self.input_mutex.lockShared();
    // defer self.input_mutex.unlockShared();
    // return self.input_state.isMouseButtonPressed(button);
}

pub fn mouseReleased(self: *Core, button: core.MouseButton) bool {
    _ = self;
    _ = button;
    // self.input_mutex.lockShared();
    // defer self.input_mutex.unlockShared();
    // return self.input_state.isMouseButtonReleased(button);
}

pub fn mousePosition(self: *Core) core.Position {
    _ = self;
    // self.input_mutex.lockShared();
    // defer self.input_mutex.unlockShared();
    // return self.input_state.mouse_position;
}

pub fn outOfMemory(self: *Core) bool {
    if (self.oom.isSet()) {
        self.oom.reset();
        return true;
    }
    return false;
}

fn pushEvent(self: *Core, event: core.Event) void {
    self.event_mutex.lock();
    defer self.event_mutex.unlock();
    self.events.writeItem(event) catch self.oom.set();
}

fn wndProc(wnd: w.HWND, msg: u32, wParam: w.WPARAM, lParam: w.LPARAM) callconv(w.WINAPI) w.LRESULT {
    const self = blk: {
        const userdata: usize = @bitCast(w.GetWindowLongPtrW(wnd, w.GWLP_USERDATA));
        const ptr: ?*Core = @ptrFromInt(userdata);
        break :blk ptr orelse return w.DefWindowProcW(wnd, msg, wParam, lParam);
    };

    switch (msg) {
        w.WM_CLOSE => {
            self.pushEvent(.close);
            return 0;
        },
        w.WM_GETMINMAXINFO => {
            self.mutex.lock();
            defer self.mutex.unlock();
            const info: *w.MINMAXINFO = blk: {
                const int: usize = @bitCast(lParam);
                break :blk @ptrFromInt(int);
            };
            if (self.limits.min.width) |width| info.ptMinTrackSize.x = @bitCast(width);
            if (self.limits.min.height) |height| info.ptMinTrackSize.y = @bitCast(height);
            if (self.limits.max.width) |width| info.ptMaxTrackSize.x = @bitCast(width);
            if (self.limits.max.height) |height| info.ptMaxTrackSize.y = @bitCast(height);
            return 0;
        },
        w.WM_KEYDOWN, w.WM_KEYUP => {
            const vkey: w.VIRTUAL_KEY = @enumFromInt(wParam);
            if (vkey == w.VK_PROCESSKEY) return 0;

            if (msg == w.WM_SYSKEYDOWN and vkey == w.VK_F4) {
                self.pushEvent(.close);
                return 0;
            }

            const flags = lParam >> 16;
            const scancode: u9 = @intCast(flags & 0x1FF);

            if (scancode == 0x1D) {
                // right alt sends left control first
                var next: w.MSG = undefined;
                const time = w.GetMessageTime();
                if (w.PeekMessageW(&next, self.window, 0, 0, w.PM_NOREMOVE) != 0 and
                    next.time == time and
                    (next.message == msg or (msg == w.WM_SYSKEYDOWN and next.message == w.WM_KEYUP)) and
                    ((next.lParam >> 16) & 0x1FF) == 0x138)
                {
                    return 0;
                }
            }

            const key = keyFromScancode(scancode);
            if (msg == w.WM_KEYDOWN) {
                if (flags & w.KF_REPEAT == 0) {
                    self.pushEvent(.{ .key_press = .{ .key = key, .mods = undefined } });
                } else {
                    self.pushEvent(.{ .key_repeat = .{ .key = key, .mods = undefined } });
                }
            } else {
                self.pushEvent(.{ .key_release = .{ .key = key, .mods = undefined } });
            }

            return 0;
        },
        w.WM_CHAR => {
            const char: u16 = @truncate(wParam);
            var chars: []const u16 = undefined;
            if (self.surrogate != 0) {
                chars = &.{ self.surrogate, char };
                self.surrogate = 0;
            } else if (std.unicode.utf16IsHighSurrogate(char)) {
                self.surrogate = char;
                return 0;
            } else {
                chars = &.{char};
            }
            var iter = std.unicode.Utf16LeIterator.init(chars);
            if (iter.nextCodepoint()) |codepoint| {
                self.pushEvent(.{ .char_input = .{ .codepoint = codepoint.? } });
            } else |err| {
                err catch {};
            }
            return 0;
        },
        w.WM_LBUTTONDOWN,
        w.WM_LBUTTONUP,
        w.WM_RBUTTONDOWN,
        w.WM_RBUTTONUP,
        w.WM_MBUTTONDOWN,
        w.WM_MBUTTONUP,
        w.WM_XBUTTONDOWN,
        w.WM_XBUTTONUP,
        => {
            const x:f64 = @floatFromInt(@as(i16, @truncate(lParam & 0xFFFF))); 
            const y:f64 = @floatFromInt(@as(i16, @truncate((lParam >> 16) & 0xFFFF))); 

            const xbutton: u32 = @truncate(wParam >> 16);
            const button: core.MouseButton = switch (msg) {
                w.WM_LBUTTONDOWN, w.WM_LBUTTONUP => .left,
                w.WM_RBUTTONDOWN, w.WM_RBUTTONUP => .right,
                w.WM_MBUTTONDOWN, w.WM_MBUTTONUP => .middle,
                else => if (xbutton == @as(u32, @bitCast(w.XBUTTON1))) .four else .five,
            };

            switch (msg) {
                w.WM_LBUTTONDOWN,
                w.WM_MBUTTONDOWN,
                w.WM_RBUTTONDOWN,
                w.WM_XBUTTONDOWN,
                => self.pushEvent(.{ .mouse_press = .{ .button = button, .mods = undefined, .pos = .{.x = x, .y = y }}}),
                else => self.pushEvent(.{ .mouse_release = .{ .button = button, .mods = undefined, .pos = .{.x = x, .y = y}}}),
            }

            return if (msg == w.WM_XBUTTONDOWN or msg == w.WM_XBUTTONUP) w.TRUE else 0;
        },
        w.WM_MOUSEMOVE => {
            self.pushEvent(.{
                .mouse_motion = .{
                    .pos = .{
                        .x = 0,
                        .y = 0,
                    },
                },
            });
            return 0;
        },
        w.WM_MOUSEWHEEL => {
            self.pushEvent(.{
                .mouse_scroll = .{
                    .xoffset = 0,
                    .yoffset = 0,
                },
            });
            return 0;
        },
        else => return w.DefWindowProcW(wnd, msg, wParam, lParam),
    }
}

fn keyFromScancode(scancode: u9) core.Key {
    comptime var table: [0x15D]core.Key = undefined;
    comptime for (&table, 1..) |*ptr, i| {
        ptr.* = switch (i) {
            0x1 => .escape,
            0x2 => .one,
            0x3 => .two,
            0x4 => .three,
            0x5 => .four,
            0x6 => .five,
            0x7 => .six,
            0x8 => .seven,
            0x9 => .eight,
            0xA => .nine,
            0xB => .zero,
            0xC => .minus,
            0xD => .equal,
            0xE => .backspace,
            0xF => .tab,
            0x10 => .q,
            0x11 => .w,
            0x12 => .e,
            0x13 => .r,
            0x14 => .t,
            0x15 => .y,
            0x16 => .u,
            0x17 => .i,
            0x18 => .o,
            0x19 => .p,
            0x1A => .left_bracket,
            0x1B => .right_bracket,
            0x1C => .enter,
            0x1D => .left_control,
            0x1E => .a,
            0x1F => .s,
            0x20 => .d,
            0x21 => .f,
            0x22 => .g,
            0x23 => .h,
            0x24 => .j,
            0x25 => .k,
            0x26 => .l,
            0x27 => .semicolon,
            0x28 => .apostrophe,
            0x29 => .grave,
            0x2A => .left_shift,
            0x2B => .backslash,
            0x2C => .z,
            0x2D => .x,
            0x2E => .c,
            0x2F => .v,
            0x30 => .b,
            0x31 => .n,
            0x32 => .m,
            0x33 => .comma,
            0x34 => .period,
            0x35 => .slash,
            0x36 => .right_shift,
            0x37 => .kp_multiply,
            0x38 => .left_alt,
            0x39 => .space,
            0x3A => .caps_lock,
            0x3B => .f1,
            0x3C => .f2,
            0x3D => .f3,
            0x3E => .f4,
            0x3F => .f5,
            0x40 => .f6,
            0x41 => .f7,
            0x42 => .f8,
            0x43 => .f9,
            0x44 => .f10,
            0x45 => .pause,
            0x46 => .scroll_lock,
            0x47 => .kp_7,
            0x48 => .kp_8,
            0x49 => .kp_9,
            0x4A => .kp_subtract,
            0x4B => .kp_4,
            0x4C => .kp_5,
            0x4D => .kp_6,
            0x4E => .kp_add,
            0x4F => .kp_1,
            0x50 => .kp_2,
            0x51 => .kp_3,
            0x52 => .kp_0,
            0x53 => .kp_decimal,
            //0x56 => .europe2,
            0x57 => .f11,
            0x58 => .f12,
            //0x5C => .international6,
            0x64 => .f13,
            0x65 => .f14,
            0x66 => .f15,
            0x67 => .f16,
            0x68 => .f17,
            0x69 => .f18,
            0x6A => .f19,
            0x6B => .f20,
            0x6C => .f21,
            0x6D => .f22,
            0x6E => .f23,
            //0x70 => .international2,
            //0x73 => .international1,
            //0x76 => .lang5,
            //0x77 => .lang4,
            //0x78 => .lang3,
            //0x79 => .international4,
            //0x7B => .international5,
            //0x7D => .international3,
            //0x7E => .kp_comma,
            //0xF1 => .lang2,
            //0xF2 => .lang1,
            //0x11C => .kp_enter,
            0x11D => .right_control,
            //0x135 => .kp_divide,
            0x138 => .right_alt,
            0x145 => .num_lock,
            0x146 => .pause,
            0x147 => .home,
            0x148 => .up,
            0x149 => .page_up,
            0x14B => .left,
            0x14D => .right,
            0x14F => .end,
            0x150 => .down,
            0x151 => .page_down,
            0x152 => .insert,
            0x153 => .delete,
            0x15B => .left_super,
            0x15C => .right_super,
            0x15D => .menu,
            else => .unknown,
        };
    };
    return if (scancode > 0 and scancode <= table.len) table[scancode - 1] else .unknown;
}

pub fn joystickPresent(_: *Core, _: Joystick) bool {
    @panic("NOT IMPLEMENTED");
}
pub fn joystickName(_: *Core, _: Joystick) ?[:0]const u8 {
    @panic("NOT IMPLEMENTED");
}
pub fn joystickButtons(_: *Core, _: Joystick) ?[]const bool {
    @panic("NOT IMPLEMENTED");
}
// May be called from any thread.
pub fn joystickAxes(_: *Core, _: Joystick) ?[]const f32 {
    @panic("NOT IMPLEMENTED");
}
