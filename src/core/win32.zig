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

const log = std.log.scoped(.mach);

const EventQueue = std.fifo.LinearFifo(Event, .Dynamic);
const Win32 = @This();

/////////////////////////
// Module state
////////////////////////
allocator: std.mem.Allocator,
core: *Core,

// Core platform interface
title: [:0]u8,
display_mode: DisplayMode,
vsync_mode: VSyncMode,
cursor_mode: CursorMode,
cursor_shape: CursorShape,
border: bool,
headless: bool,
refresh_rate: u32,
size: Size,
surface_descriptor: gpu.Surface.Descriptor,
surface_descriptor_from_hwnd: gpu.Surface.DescriptorFromWindowsHWND,

// Internals
window: w.HWND,
surrogate: u16 = 0,
dinput: *w.IDirectInput8W,

events: EventQueue,
oom: std.Thread.ResetEvent = .{},

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
        .unknown => std.log.err("gpu: unknown error: {s}\n", .{message}),
        else => unreachable,
    }
    std.process.exit(1);
}

////////////////////////////
/// Platform interface 
////////////////////////////
pub fn init(
    self: *Win32,
    options: InitOptions,
) !void {
    self.allocator = options.allocator;
    self.core = @fieldParentPtr("platform", self);
    self.events = EventQueue.init(self.allocator);
    self.size = options.size;

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

    // TODO set title , copy to self.title
    const title = try std.unicode.utf8ToUtf16LeAllocZ(self.allocator, options.title);
    defer self.allocator.free(title);

    var request_window_width:i32 = @bitCast(self.size.width);
    var request_window_height:i32 = @bitCast(self.size.height);

    const window_ex_style: w.WINDOW_EX_STYLE = .{.APPWINDOW = 1, .WINDOWEDGE = 1, .CLIENTEDGE = 1};
    const window_style: w.WINDOW_STYLE = if (options.border) w.WS_OVERLAPPEDWINDOW else w.WS_POPUPWINDOW;

    var rect: w.RECT = .{ .left = 0, .top = 0, .right = request_window_width, .bottom = request_window_height};

    if (w.TRUE == w.AdjustWindowRectEx(&rect,
        window_style, 
        w.FALSE, 
        window_ex_style)) 
    {
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

    self.surface_descriptor = .{
        .next_in_chain = .{
            .from_windows_hwnd = &self.surface_descriptor_from_hwnd,
        }
    };

    _ = w.SetWindowLongPtrW(window, w.GWLP_USERDATA, @bitCast(@intFromPtr(self)));
    if (!options.headless) {
        setDisplayMode(self, options.display_mode);
    }

    self.size = getClientRect(self);
}

pub fn getClientRect(self: *Win32) Size {
    var rect: w.RECT = undefined;
    _ = w.GetClientRect(self.window, &rect);

    const width:u32 = @intCast(rect.right - rect.left);
    const height:u32 = @intCast(rect.bottom - rect.top);

    return .{ .width = width, .height = height };
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
    // TODO update self.title
    defer self.allocator.free(wtitle);
    _ = w.SetWindowTextW(self.window, wtitle);
}

pub fn setDisplayMode(self: *Win32, mode: DisplayMode) void {
    // TODO update self.displayMode
    switch (mode) {
        .windowed => _ = w.ShowWindow(self.window, w.SW_RESTORE),
        //        .maximized => _ = w.ShowWindow(self.window, w.SW_MAXIMIZE),
        .fullscreen => {},
        .borderless => {},
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
    // TODO - use AdjustClientRect to get correct client rect.
    _ = w.SetWindowPos(self.window, 
        null, 
        0, 
        0, 
        @as(i32, @intCast(value.width)), 
        @as(i32, @intCast(value.height)), 
        w.SET_WINDOW_POS_FLAGS{.NOMOVE = 1, .NOZORDER = 1, .NOACTIVATE = 1}
    );
    self.size = value;
}
// pub fn size(self: *Core) core.Size {
//     var rect: w.RECT = undefined;
//     _ = w.GetClientRect(self.window, &rect);

//     const width:u32 = @intCast(rect.right - rect.left);
//     const height:u32 = @intCast(rect.bottom - rect.top);

//     return .{ .width = width, .height = height };
// }

// pub fn setSizeLimit(self: *Core, value: core.SizeLimit) void {
//     self.mutex.lock();
//     defer self.mutex.unlock();
//     self.limits = value;
//     // trigger WM_GETMINMAXINFO
//     _ = w.SetWindowPos(self.window, 0, 0, 0, 0, 0, w.SWP_NOMOVE | w.SWP_NOSIZE | w.SWP_NOZORDER | w.SWP_NOACTIVATE);
// }

// pub fn sizeLimit(self: *Core) core.SizeLimit {
//     self.mutex.lock();
//     defer self.mutex.unlock();
//     return self.limits;
// }

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
    _ = self;
    _ = key;
    // TODO: Not implemented
    return false;
}

pub fn keyReleased(self: *Win32, key: Key) bool {
    _ = self;
    _ = key;
    // TODO: Not implemented
    return false;
}

pub fn mousePressed(self: *Win32, button: MouseButton) bool {
    _ = self;
    _ = button;
    // TODO: Not implemented
    return false;
}

pub fn mouseReleased(self: *Win32, button: MouseButton) bool {
    _ = self;
    _ = button;
    // TODO: Not implemented
    return false;
}

pub fn mousePosition(self: *Win32) Position {
    _ = self;
    // TODO: Not implemented
    return Position{.x = 0.0, .y = 0.0};
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
        w.WM_GETMINMAXINFO => {
            //self.mutex.lock();
            //defer self.mutex.unlock();

            // TODO: SizeLimit is no longer in mach core or has changed
            // const info: *w.MINMAXINFO = blk: {
            //     const int: usize = @bitCast(lParam);
            //     break :blk @ptrFromInt(int);
            // };
            // if (self.limits.min.width) |width| info.ptMinTrackSize.x = @bitCast(width);
            // if (self.limits.min.height) |height| info.ptMinTrackSize.y = @bitCast(height);
            // if (self.limits.max.width) |width| info.ptMaxTrackSize.x = @bitCast(width);
            // if (self.limits.max.height) |height| info.ptMaxTrackSize.y = @bitCast(height);
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

            const key = keyFromScancode(scancode);
            if (msg == w.WM_KEYDOWN or msg == w.WM_SYSKEYDOWN) {
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
