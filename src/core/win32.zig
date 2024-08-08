const std = @import("std");
const w = @import("win32/win32.zig");
const mach = @import("../main.zig");
const Core = @import("../Core.zig");
const InputState = @import("InputState.zig");
const Frequency = @import("Frequency.zig");
const unicode = @import("unicode.zig");

const gpu = mach.gpu;
const InitOptions = Core.InitOptions;
const Event = Core.Event;
const KeyEvent = Core.KeyEvent;
const MouseButtonEvent = Core.MouseButtonEvent;
const MouseButton = Core.MouseButton;
const Size = Core.Size;
const DisplayMode = Core.DisplayMode;
const CursorShape = Core.CursorShape;
const VSyncMode = Core.VSyncMode;
const CursorMode = Core.CursorMode;
const Position = Core.Position;
const Key = Core.Key;
const KeyMods = Core.KeyMods;
const Joystick = Core.Joystick;

const EventQueue = std.fifo.LinearFifo(Event, .Dynamic);
const Win32 = @This();

// --------------------------
// Module state
// --------------------------
allocator: std.mem.Allocator,
core: *Core,

// Core platform interface
surface_descriptor: gpu.Surface.Descriptor,
display_mode: DisplayMode,
vsync_mode: VSyncMode,
cursor_mode: CursorMode,
cursor_shape: CursorShape,
border: bool,
headless: bool,
size: Size,

// Internals
window: w.HWND,
refresh_rate: u32,
surrogate: u16 = 0,
dinput: *w.IDirectInput8W,
saved_window_rect: w.RECT,
surface_descriptor_from_hwnd: gpu.Surface.DescriptorFromWindowsHWND,
events: EventQueue,
input_state: InputState,
oom: std.Thread.ResetEvent = .{},

// ------------------------------
// Platform interface
// ------------------------------
pub fn init(
    self: *Win32,
    options: InitOptions,
) !void {
    self.allocator = options.allocator;
    self.core = @fieldParentPtr("platform", self);
    self.events = EventQueue.init(self.allocator);
    self.size = options.size;
    self.input_state = .{};
    self.saved_window_rect = .{.top = 0, .left = 0, .right = 0, .bottom = 0};

    const hInstance = w.GetModuleHandleW(null);
    const class_name = w.L("mach");
    const class = std.mem.zeroInit(w.WNDCLASSW, .{
        .style = w.CS_OWNDC,
        .lpfnWndProc = wndProc,
        .hInstance = hInstance,
        .hIcon = w.LoadIconW(null, @as([*:0]align(1) const u16, @ptrFromInt(@as(u32, w.IDI_APPLICATION)))),
        .hCursor = w.LoadCursorW(null, @as([*:0]align(1) const u16, @ptrFromInt(@as(u32, w.IDC_ARROW)))),
        .lpszClassName = class_name,
    });
    if (w.RegisterClassW(&class) == 0) return error.Unexpected;

    const title = try std.unicode.utf8ToUtf16LeAllocZ(self.allocator, options.title);
    defer self.allocator.free(title);

    var request_window_width: i32 = @bitCast(self.size.width);
    var request_window_height: i32 = @bitCast(self.size.height);

    const window_ex_style: w.WINDOW_EX_STYLE = .{ .APPWINDOW = 1 };
    const window_style: w.WINDOW_STYLE = if (options.border) w.WS_OVERLAPPEDWINDOW else w.WS_POPUPWINDOW; // w.WINDOW_STYLE{.POPUP = 1};
    // TODO (win32): should border == false mean borderless display_mode?

    var rect: w.RECT = .{ .left = 0, .top = 0, .right = request_window_width, .bottom = request_window_height };

    if (w.TRUE == w.AdjustWindowRectEx(&rect, window_style, w.FALSE, window_ex_style)) {
        request_window_width = rect.right - rect.left;
        request_window_height = rect.bottom - rect.top;
    }

    const window = w.CreateWindowExW(
        window_ex_style,
        class_name,
        title,
        window_style,
        w.CW_USEDEFAULT,
        w.CW_USEDEFAULT,
        request_window_width,
        request_window_height,
        null,
        null,
        hInstance,
        null,
    ) orelse return error.Unexpected;

    self.window = window;

    var dinput: ?*w.IDirectInput8W = undefined;
    const ptr: ?*?*anyopaque = @ptrCast(&dinput);
    if (w.DirectInput8Create(hInstance, w.DIRECTINPUT_VERSION, w.IID_IDirectInput8W, ptr, null) != w.DI_OK) {
        return error.Unexpected;
    }
    self.dinput = dinput.?;

    self.surface_descriptor_from_hwnd = .{
        .hinstance = std.os.windows.kernel32.GetModuleHandleW(null).?,
        .hwnd = window,
    };

    self.surface_descriptor = .{ .next_in_chain = .{
        .from_windows_hwnd = &self.surface_descriptor_from_hwnd,
    } };
    self.border = options.border;
    self.headless = options.headless;
    self.refresh_rate = 60; // TODO (win32)  get monitor refresh rate

    _ = w.SetWindowLongPtrW(window, w.GWLP_USERDATA, @bitCast(@intFromPtr(self)));
    if (!options.headless) {
        setDisplayMode(self, options.display_mode);
    }

    self.size = getClientRect(self);
    _ = w.GetWindowRect(self.window, &self.saved_window_rect);
}

pub fn deinit(self: *Win32) void {
    self.events.deinit();
    _ = self.dinput.IUnknown_Release();
}

pub fn update(self: *Win32) !void {
    _ = self;
    var msg: w.MSG = undefined;
    while (w.PeekMessageW(&msg, null, 0, 0, w.PM_REMOVE) != 0) {
        _ = w.TranslateMessage(&msg);
        _ = w.DispatchMessageW(&msg);
    }
}

pub const EventIterator = struct {
    queue: *EventQueue,

    pub fn next(self: *EventIterator) ?Event {
        return self.queue.readItem();
    }
};

pub fn pollEvents(self: *Win32) EventIterator {
    return .{ .queue = &self.events };
}

pub fn setTitle(self: *Win32, title: [:0]const u8) void {
    const wtitle = std.unicode.utf8ToUtf16LeAllocZ(self.allocator, title) catch {
        self.oom.set();
        return;
    };
    defer self.allocator.free(wtitle);
    _ = w.SetWindowTextW(self.window, wtitle);
}

pub fn setDisplayMode(self: *Win32, mode: DisplayMode) void {
    self.display_mode = mode;

    switch (mode) {
        .windowed => {
            const window_style: w.WINDOW_STYLE = if (self.border) w.WS_OVERLAPPEDWINDOW else w.WS_POPUPWINDOW; 
            const window_ex_style = w.WINDOW_EX_STYLE{ .APPWINDOW = 1 };

            _ = w.SetWindowLongW(self.window, w.GWL_STYLE, @bitCast(window_style));
            _ = w.SetWindowLongW(self.window, w.GWL_EXSTYLE, @bitCast(window_ex_style));

            restoreWindowPosition(self);
        },
        .fullscreen => {         
            // TODO (win32) - change to use exclusive fullscreen using ChangeDisplaySetting

            _ = w.GetWindowRect(self.window, &self.saved_window_rect);

            const window_style = w.WINDOW_STYLE{ .POPUP = 1, .VISIBLE = 1};
            const window_ex_style = w.WINDOW_EX_STYLE{ .APPWINDOW = 1 };

            _ = w.SetWindowLongW(self.window, w.GWL_STYLE, @bitCast(window_style));
            _ = w.SetWindowLongW(self.window, w.GWL_EXSTYLE, @bitCast(window_ex_style));

            const monitor = w.MonitorFromWindow(self.window, w.MONITOR_DEFAULTTONEAREST);
            var monitor_info: w.MONITORINFO = undefined;
            monitor_info.cbSize = @sizeOf(w.MONITORINFO);
            if (w.GetMonitorInfoW(monitor, &monitor_info) == w.TRUE) {
                _ = w.SetWindowPos(self.window, 
                    null, 
                    monitor_info.rcMonitor.left, 
                    monitor_info.rcMonitor.top, 
                    monitor_info.rcMonitor.right - monitor_info.rcMonitor.left, 
                    monitor_info.rcMonitor.bottom - monitor_info.rcMonitor.top,
                    w.SWP_NOZORDER
                );
            }
        },
        .borderless => {
            _ = w.GetWindowRect(self.window, &self.saved_window_rect);

            const window_style = w.WINDOW_STYLE{ .POPUP = 1, .VISIBLE = 1};
            const window_ex_style = w.WINDOW_EX_STYLE{ .APPWINDOW = 1 };

            _ = w.SetWindowLongW(self.window, w.GWL_STYLE, @bitCast(window_style));
            _ = w.SetWindowLongW(self.window, w.GWL_EXSTYLE, @bitCast(window_ex_style));

            const monitor = w.MonitorFromWindow(self.window, w.MONITOR_DEFAULTTONEAREST);
            var monitor_info: w.MONITORINFO = undefined;
            monitor_info.cbSize = @sizeOf(w.MONITORINFO);
            if (w.GetMonitorInfoW(monitor, &monitor_info) == w.TRUE) {
                _ = w.SetWindowPos(self.window, 
                    null, 
                    monitor_info.rcMonitor.left, 
                    monitor_info.rcMonitor.top, 
                    monitor_info.rcMonitor.right - monitor_info.rcMonitor.left, 
                    monitor_info.rcMonitor.bottom - monitor_info.rcMonitor.top,
                    w.SWP_NOZORDER
                );
            }
        },
    }
}

pub fn setBorder(self: *Win32, value: bool) void {
    const overlappedwindow: i32 = @bitCast(w.WS_OVERLAPPEDWINDOW);
    const popupwindow: i32 = @bitCast(w.WS_POPUPWINDOW);
    _ = w.SetWindowLongW(self.window, w.GWL_STYLE, if (value) overlappedwindow else popupwindow);
    self.border = value;
}

pub fn setHeadless(self: *Win32, value: bool) void {
    _ = w.ShowWindow(self.window, if (value) w.SW_HIDE else w.SW_SHOW);
    self.headless = value;
}

pub fn setVSync(self: *Win32, mode: VSyncMode) void {
    self.vsync_mode = mode;
}

pub fn setSize(self: *Win32, value: Size) void {
    // TODO (win32) - use AdjustClientRect to get correct client rect.
    _ = w.SetWindowPos(self.window, null, 0, 0, @as(i32, @intCast(value.width)), @as(i32, @intCast(value.height)), w.SET_WINDOW_POS_FLAGS{ .NOMOVE = 1, .NOZORDER = 1, .NOACTIVATE = 1 });
    self.size = value;
}

pub fn setCursorMode(self: *Win32, mode: CursorMode) void {
    switch (mode) {
        .normal => while (w.ShowCursor(w.TRUE) < 0) {},
        .hidden => while (w.ShowCursor(w.FALSE) >= 0) {},
        .disabled => {},
    }
    self.cursor_mode = mode;
}

pub fn setCursorShape(self: *Win32, shape: CursorShape) void {
    const name: i32 = switch (shape) {
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
    _ = w.SetCursor(w.LoadCursorW(null, @ptrFromInt(@as(usize, @intCast(name)))));
    self.cursor_shape = shape;
}

pub fn keyPressed(self: *Win32, key: Key) bool {
    return self.input_state.isKeyPressed(key);
}

pub fn keyReleased(self: *Win32, key: Key) bool {
    return self.input_state.isKeyReleased(key);
}

pub fn mousePressed(self: *Win32, button: MouseButton) bool {
    return self.input_state.isMouseButtonPressed(button);
}

pub fn mouseReleased(self: *Win32, button: MouseButton) bool {
    return self.input_state.isMouseButtonReleased(button);
}

pub fn mousePosition(self: *Win32) Position {
    return self.input_state.mouse_position;
}

pub fn joystickPresent(_: *Win32, _: Joystick) bool {
    @panic("NOT IMPLEMENTED");
}
pub fn joystickName(_: *Win32, _: Joystick) ?[:0]const u8 {
    @panic("NOT IMPLEMENTED");
}
pub fn joystickButtons(_: *Win32, _: Joystick) ?[]const bool {
    @panic("NOT IMPLEMENTED");
}
// May be called from any thread.
pub fn joystickAxes(_: *Win32, _: Joystick) ?[]const f32 {
    @panic("NOT IMPLEMENTED");
}
pub fn nativeWindowWin32(self: *Win32) w.HWND {
    return self.window;
}

// -----------------------------
//  Internal functions
// -----------------------------
fn getClientRect(self: *Win32) Size {
    var rect: w.RECT = undefined;
    _ = w.GetClientRect(self.window, &rect);

    const width: u32 = @intCast(rect.right - rect.left);
    const height: u32 = @intCast(rect.bottom - rect.top);

    return .{ .width = width, .height = height };
}

fn restoreWindowPosition(self: *Win32) void {
    if (self.saved_window_rect.right - self.saved_window_rect.left == 0) {
        _ = w.ShowWindow(self.window, w.SW_RESTORE);
    } else {
        _ = w.SetWindowPos(self.window, 
            null, 
            self.saved_window_rect.left,
            self.saved_window_rect.top, 
            self.saved_window_rect.right - self.saved_window_rect.left, 
            self.saved_window_rect.bottom - self.saved_window_rect.top,
            w.SWP_SHOWWINDOW
        );
    }
}

pub fn outOfMemory(self: *Win32) bool {
    if (self.oom.isSet()) {
        self.oom.reset();
        return true;
    }
    return false;
}

fn pushEvent(self: *Win32, event: Event) void {
    self.events.writeItem(event) catch self.oom.set();
}

fn getKeyboardModifiers() mach.Core.KeyMods {
    return .{
        .shift = w.GetKeyState(@as(i32, @intFromEnum(w.VK_SHIFT))) < 0, //& 0x8000 == 0x8000,
        .control = w.GetKeyState(@as(i32, @intFromEnum(w.VK_CONTROL))) < 0, // & 0x8000 == 0x8000,
        .alt = w.GetKeyState(@as(i32, @intFromEnum(w.VK_MENU))) < 0, // & 0x8000 == 0x8000,
        .super = (w.GetKeyState(@as(i32, @intFromEnum(w.VK_LWIN)))) < 0 // & 0x8000 == 0x8000)
            or (w.GetKeyState(@as(i32, @intFromEnum(w.VK_RWIN)))) < 0, // & 0x8000 == 0x8000),
        .caps_lock = w.GetKeyState(@as(i32, @intFromEnum(w.VK_CAPITAL))) & 1 == 1,
        .num_lock = w.GetKeyState(@as(i32, @intFromEnum(w.VK_NUMLOCK))) & 1 == 1,
    };
}

fn wndProc(wnd: w.HWND, msg: u32, wParam: w.WPARAM, lParam: w.LPARAM) callconv(w.WINAPI) w.LRESULT {
    const self = blk: {
        const userdata: usize = @bitCast(w.GetWindowLongPtrW(wnd, w.GWLP_USERDATA));
        const ptr: ?*Win32 = @ptrFromInt(userdata);
        break :blk ptr orelse return w.DefWindowProcW(wnd, msg, wParam, lParam);
    };

    switch (msg) {
        w.WM_CLOSE => {
            self.pushEvent(.close);
            return 0;
        },
        w.WM_SIZE => {
            const width: u32 = @as(u32, @intCast(lParam & 0xFFFF));
            const height: u32 = @as(u32, @intCast((lParam >> 16) & 0xFFFF));
            self.size = .{.width = width, .height = height};

            // TODO (win32): only send resize event when sizing is done.
            //               the main mach loops does not run while resizing.
            //               Which means if events are pushed here they will
            //               queue up until resize is done.

            self.core.swap_chain_update.set();

            return 0;
        },
        w.WM_KEYDOWN, w.WM_KEYUP, w.WM_SYSKEYDOWN, w.WM_SYSKEYUP => {
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

            const mods = getKeyboardModifiers();
            const key = keyFromScancode(scancode);
            if (msg == w.WM_KEYDOWN or msg == w.WM_SYSKEYDOWN) {
                if (flags & w.KF_REPEAT == 0) {
                    self.pushEvent(.{ .key_press = .{ .key = key, .mods = mods } });
                    self.input_state.keys.setValue(@intFromEnum(key), true);
                } else {
                    self.pushEvent(.{ .key_repeat = .{ .key = key, .mods = mods } });
                }
            } else {
                self.pushEvent(.{ .key_release = .{ .key = key, .mods = mods } });
                self.input_state.keys.setValue(@intFromEnum(key), false);
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
            const mods = getKeyboardModifiers();
            const x: f64 = @floatFromInt(@as(i16, @truncate(lParam & 0xFFFF)));
            const y: f64 = @floatFromInt(@as(i16, @truncate((lParam >> 16) & 0xFFFF)));
            const xbutton: u32 = @truncate(wParam >> 16);
            const button: MouseButton = switch (msg) {
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
                => {
                    self.pushEvent(.{ .mouse_press = .{ .button = button, .mods = mods, .pos = .{ .x = x, .y = y } } });
                    self.input_state.mouse_buttons.setValue(@intFromEnum(button), true);
                },
                else => {
                    self.pushEvent(.{ .mouse_release = .{ .button = button, .mods = mods, .pos = .{ .x = x, .y = y } } });
                    self.input_state.mouse_buttons.setValue(@intFromEnum(button), false);
                },
            }

            return if (msg == w.WM_XBUTTONDOWN or msg == w.WM_XBUTTONUP) w.TRUE else 0;
        },
        w.WM_MOUSEMOVE => {
            const x: f64 = @floatFromInt(@as(i16, @truncate(lParam & 0xFFFF)));
            const y: f64 = @floatFromInt(@as(i16, @truncate((lParam >> 16) & 0xFFFF)));

            self.pushEvent(.{
                .mouse_motion = .{
                    .pos = .{
                        .x = x,
                        .y = y,
                    },
                },
            });
            self.input_state.mouse_position = .{ .x = x, .y = y };

            return 0;
        },
        w.WM_MOUSEWHEEL => {
            const WHEEL_DELTA = 120.0;
            const wheel_high_word: u16 = @truncate((wParam >> 16) & 0xffff);
            const delta_y: f32 = @as(f32, @floatFromInt(@as(i16, @bitCast(wheel_high_word)))) / WHEEL_DELTA;

            self.pushEvent(.{
                .mouse_scroll = .{
                    .xoffset = 0,
                    .yoffset = delta_y,
                },
            });
            return 0;
        },
        w.WM_SETFOCUS => {
            self.pushEvent(.{ .focus_gained = {} });
            return 0;
        },
        w.WM_KILLFOCUS => {
            self.pushEvent(.{ .focus_lost = {} });
            // Clear input state when focus is lost to avoid "stuck" button when focus is regained.
            self.input_state = .{};
            return 0;
        },
        else => return w.DefWindowProcW(wnd, msg, wParam, lParam),
    }
}

fn keyFromScancode(scancode: u9) Key {
    comptime var table: [0x15D]Key = undefined;
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
            0x54 => .print, // sysrq
            0x56 => .iso_backslash,
            //0x56 => .europe2,
            0x57 => .f11,
            0x58 => .f12,
            0x59 => .kp_equal,
            0x5B => .left_super, // sent by touchpad gestures
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
            0x73 => .international1,
            0x76 => .f24,            
            //0x77 => .lang4,
            //0x78 => .lang3,
            //0x79 => .international4,
            //0x7B => .international5,
            //0x7D => .international3,
            0x7E => .kp_comma,
            //0xF1 => .lang2,
            //0xF2 => .lang1,
            0x11C => .kp_enter,
            0x11D => .right_control,
            0x135 => .kp_divide,
            0x136 => .right_shift, // sent by IME
            0x137 => .print,
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

// TODO (win32) Implement consistent error handling when interfacing with the Windows API.
// TODO (win32) Support High DPI awareness
// TODO (win32) Consider to add support for mouse capture
// TODO (win32) Change to using WM_INPUT for mouse movement.
