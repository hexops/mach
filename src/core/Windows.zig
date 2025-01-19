const std = @import("std");
const w = @import("../win32.zig");
const mach = @import("../main.zig");
const Core = @import("../Core.zig");

const windowmsg = @import("windowmsg.zig");

const gpu = mach.gpu;
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

const log = std.log.scoped(.mach);
const EventQueue = std.fifo.LinearFifo(Event, .Dynamic);
const Win32 = @This();

const window_ex_style: w.WINDOW_EX_STYLE = .{
    .APPWINDOW = 1,
    .NOREDIRECTIONBITMAP = 1,
};

pub const Native = struct {
    hwnd: w.HWND,
    surrogate: u16 = 0,
    // dinput: *w.IDirectInput8W = undefined,
};

pub fn run(comptime on_each_update_fn: anytype, args_tuple: std.meta.ArgsTuple(@TypeOf(on_each_update_fn))) void {
    while (@call(.auto, on_each_update_fn, args_tuple) catch false) {}
}

pub fn tick(core: *Core) !void {
    {
        var windows = core.windows.slice();
        while (windows.next()) |window_id| {
            if (core.windows.get(window_id, .native) != null) {
                // TODO: propagate window.decorated and all others
                // Handle resizing the window when the user changes width or height
                if (core.windows.updated(window_id, .width) or core.windows.updated(window_id, .height)) {
                    setWindowSize(
                        core.windows.get(window_id, .native).?.hwnd,
                        .{
                            .width = core.windows.get(window_id, .width),
                            .height = core.windows.get(window_id, .height),
                        },
                    );
                }
            } else {
                try initWindow(core, window_id);
                std.debug.assert(core.windows.getValue(window_id).native != null);
            }
        }
    }

    var msg: w.MSG = undefined;
    while (true) {
        const result = w.PeekMessageW(&msg, null, 0, 0, w.PM_REMOVE);
        if (result < 0) fatalWin32("PeekMessage", w.GetLastError());
        if (result == 0) break;
        if (msg.message == w.WM_QUIT) {
            std.log.info("quit (exit code {})", .{msg.wParam});
            w.ExitProcess(std.math.cast(u32, msg.wParam) orelse 0xffffffff);
        }
        _ = w.TranslateMessage(&msg);
        _ = w.DispatchMessageW(&msg);
    }
}

fn setWindowSize(hwnd: w.HWND, size_pt: Size) void {
    const dpi = w.dpiFromHwnd(hwnd);
    const style = styleFromHwnd(hwnd);
    var rect: w.RECT = .{
        .left = 0,
        .top = 0,
        .right = w.pxFromPt(i32, @intCast(size_pt.width), dpi),
        .bottom = w.pxFromPt(i32, @intCast(size_pt.height), dpi),
    };
    if (0 == w.AdjustWindowRectExForDpi(&rect, style, w.FALSE, window_ex_style, dpi)) fatalWin32(
        "AdjustWindowRectExForDpi",
        w.GetLastError(),
    );
    if (0 == w.SetWindowPos(
        hwnd,
        null,
        undefined,
        undefined,
        rect.right - rect.left,
        rect.bottom - rect.top,
        .{ .NOZORDER = 1, .NOMOVE = 1 },
    )) fatalWin32("SetWindowPos", w.GetLastError());
}

fn updateWindowSize(
    dpi: u32,
    window_style: w.WINDOW_STYLE,
    hwnd: w.HWND,
    requested_client_size: w.SIZE,
) void {
    const monitor = blk: {
        var rect: w.RECT = undefined;
        if (0 == w.GetWindowRect(hwnd, &rect)) fatalWin32("GetWindowRect", w.GetLastError());

        break :blk w.MonitorFromPoint(
            .{ .x = rect.left, .y = rect.top },
            w.MONITOR_DEFAULTTONULL,
        ) orelse {
            log.warn("MonitorFromPoint {},{} failed with {}", .{ rect.left, rect.top, w.GetLastError() });
            return;
        };
    };

    const work_rect: w.RECT = blk: {
        var info: w.MONITORINFO = undefined;
        info.cbSize = @sizeOf(w.MONITORINFO);
        if (0 == w.GetMonitorInfoW(monitor, &info)) {
            log.warn("GetMonitorInfo failed with {}", .{w.GetLastError()});
            return;
        }
        break :blk info.rcWork;
    };

    const work_size: w.SIZE = .{
        .cx = work_rect.right - work_rect.left,
        .cy = work_rect.bottom - work_rect.top,
    };
    log.debug(
        "primary monitor work topleft={},{} size={}x{}",
        .{ work_rect.left, work_rect.top, work_size.cx, work_size.cy },
    );

    const wanted_size: w.SIZE = blk: {
        var rect: w.RECT = .{
            .left = 0,
            .top = 0,
            .right = requested_client_size.cx,
            .bottom = requested_client_size.cy,
        };
        if (0 == w.AdjustWindowRectExForDpi(&rect, window_style, w.FALSE, window_ex_style, dpi)) fatalWin32(
            "AdjustWindowRectExForDpi",
            w.GetLastError(),
        );
        break :blk .{
            .cx = rect.right - rect.left,
            .cy = rect.bottom - rect.top,
        };
    };

    const window_size: w.SIZE = .{
        .cx = @min(wanted_size.cx, work_size.cx),
        .cy = @min(wanted_size.cy, work_size.cy),
    };
    if (0 == w.SetWindowPos(
        hwnd,
        null,
        work_rect.left + @divTrunc(work_size.cx - window_size.cx, 2),
        work_rect.top + @divTrunc(work_size.cy - window_size.cy, 2),
        window_size.cx,
        window_size.cy,
        .{ .NOZORDER = 1 },
    )) fatalWin32("SetWindowPos", w.GetLastError());
}

const CreateWindowArgs = struct {
    window_id: mach.ObjectID,
};

var wndproc_core: *Core = undefined;

fn initWindow(
    core: *Core,
    window_id: mach.ObjectID,
) !void {
    wndproc_core = core;

    var core_window = core.windows.getValue(window_id);

    const hInstance = w.GetModuleHandleW(null);
    const class_name = w.L("mach");
    {
        const class: w.WNDCLASSW = .{
            .style = .{},
            .lpfnWndProc = wndProc,
            .cbClsExtra = 0,
            .cbWndExtra = @sizeOf(mach.ObjectID),
            .hInstance = hInstance,
            .hIcon = w.LoadIconW(null, w.IDI_APPLICATION),
            .hCursor = w.LoadCursorW(null, w.IDC_ARROW),
            .hbrBackground = null,
            .lpszMenuName = null,
            .lpszClassName = class_name,
        };
        if (w.RegisterClassW(&class) == 0) fatalWin32("RegisterClass", w.GetLastError());
    }

    const title = try std.unicode.utf8ToUtf16LeAllocZ(core.allocator, core_window.title);
    defer core.allocator.free(title);

    const window_style: w.WINDOW_STYLE = if (core_window.decorated) w.WS_OVERLAPPEDWINDOW else w.WS_POPUPWINDOW; // w.WINDOW_STYLE{.POPUP = 1};

    const create_args: CreateWindowArgs = .{
        .window_id = window_id,
    };
    const hwnd = w.CreateWindowExW(
        window_ex_style,
        class_name,
        title,
        window_style,
        w.CW_USEDEFAULT,
        w.CW_USEDEFAULT,
        w.CW_USEDEFAULT,
        w.CW_USEDEFAULT,
        null,
        null,
        hInstance,
        @constCast(@ptrCast(&create_args)),
    ) orelse return error.Unexpected;

    const dpi = w.dpiFromHwnd(hwnd);

    updateWindowSize(dpi, window_style, hwnd, .{
        .cx = @bitCast(core_window.width),
        .cy = @bitCast(core_window.height),
    });

    // const dinput = blk: {
    //     var dinput: ?*w.IDirectInput8W = undefined;
    //     const ptr: ?*?*anyopaque = @ptrCast(&dinput);
    //     if (w.DirectInput8Create(hInstance, w.DIRECTINPUT_VERSION, w.IID_IDirectInput8W, ptr, null) != w.DI_OK) {
    //         return error.Unexpected;
    //     }
    //     break :blk dinput;
    // };

    const size = getClientSize(hwnd);
    core_window.width = size.width;
    core_window.height = size.height;

    _ = w.ShowWindow(hwnd, w.SW_SHOW);

    // try some things to bring our window to the top
    const HWND_TOP: ?w.HWND = null;
    _ = w.SetWindowPos(hwnd, HWND_TOP, 0, 0, 0, 0, .{ .NOMOVE = 1, .NOSIZE = 1 });
    _ = w.SetForegroundWindow(hwnd);
    _ = w.BringWindowToTop(hwnd);

    {
        // TODO: make this lifetime better
        var surface_descriptor_from_hwnd: gpu.Surface.DescriptorFromWindowsHWND = .{
            .hinstance = std.os.windows.kernel32.GetModuleHandleW(null).?,
            .hwnd = hwnd,
        };
        core.windows.setRaw(window_id, .surface_descriptor, .{ .next_in_chain = .{
            .from_windows_hwnd = &surface_descriptor_from_hwnd,
        } });
        try core.initWindow(window_id);
    }
}

fn windowIdFromHwnd(hwnd: w.HWND) mach.ObjectID {
    const userdata: usize = @bitCast(w.GetWindowLongPtrW(hwnd, @enumFromInt(0)));
    if (userdata == 0) unreachable;
    return @bitCast(userdata - 1);
}
fn styleFromHwnd(hwnd: w.HWND) w.WINDOW_STYLE {
    return @bitCast(@as(u32, @truncate(@as(usize, @bitCast(w.GetWindowLongPtrW(hwnd, w.GWL_EXSTYLE))))));
}
// -----------------------------
//  Internal functions
// -----------------------------
fn getClientSize(hwnd: w.HWND) Size {
    var rect: w.RECT = undefined;
    if (0 == w.GetClientRect(hwnd, &rect))
        fatalWin32("GetClientRect", w.GetLastError());
    std.debug.assert(rect.left == 0);
    std.debug.assert(rect.top == 0);
    return .{ .width = @intCast(rect.right), .height = @intCast(rect.bottom) };
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

const debug_wndproc_log = false;
var global_msg_tail: ?*windowmsg.MessageNode = null;

fn wndProc(hwnd: w.HWND, msg: u32, wParam: w.WPARAM, lParam: w.LPARAM) callconv(w.WINAPI) w.LRESULT {
    var msg_node: windowmsg.MessageNode = undefined;
    if (debug_wndproc_log) msg_node.init(&global_msg_tail, hwnd, msg, wParam, lParam);
    defer if (debug_wndproc_log) msg_node.deinit();
    if (debug_wndproc_log) switch (msg) {
        w.WM_MOUSEMOVE => {},
        else => std.log.info("{}", .{msg_node.fmtPath()}),
    };

    const core = wndproc_core;
    switch (msg) {
        w.WM_CREATE => {
            const create_struct: *w.CREATESTRUCTW = @ptrFromInt(@as(usize, @bitCast(lParam)));
            const create_args: *CreateWindowArgs = @alignCast(@ptrCast(create_struct.lpCreateParams));
            const window_id = create_args.window_id;

            core.windows.setRaw(window_id, .native, .{ .hwnd = hwnd });
            // we add 1 to distinguish between a valid window id and an uninitialized slot
            std.debug.assert(0 == w.SetWindowLongPtrW(hwnd, @enumFromInt(0), @bitCast(create_args.window_id + 1)));
            std.debug.assert(create_args.window_id == windowIdFromHwnd(hwnd));
            return 0;
        },
        w.WM_DESTROY => @panic("Mach doesn't support destroying windows yet"),
        w.WM_CLOSE => {
            core.pushEvent(.{ .close = .{ .window_id = windowIdFromHwnd(hwnd) } });
            return 0;
        },
        w.WM_DPICHANGED, w.WM_WINDOWPOSCHANGED => {
            const client_size_px = getClientSize(hwnd);

            const window_id = windowIdFromHwnd(hwnd);
            var core_window = core.windows.getValue(window_id);

            var change = false;
            if (core_window.framebuffer_width != client_size_px.width or core_window.framebuffer_height != client_size_px.height) {
                change = true;
                // Recreate the swap_chain
                core_window.swap_chain.release();
                core_window.swap_chain_descriptor.width = client_size_px.width;
                core_window.swap_chain_descriptor.height = client_size_px.height;
                core_window.swap_chain = core_window.device.createSwapChain(core_window.surface, &core_window.swap_chain_descriptor);
                core_window.framebuffer_width = client_size_px.width;
                core_window.framebuffer_height = client_size_px.height;
            }

            const dpi = w.dpiFromHwnd(hwnd);
            const client_size_pt: Size = .{
                .width = w.ptFromPx(u32, client_size_px.width, dpi),
                .height = w.ptFromPx(u32, client_size_px.height, dpi),
            };
            if (core_window.width != client_size_pt.width or core_window.height != client_size_pt.height) {
                change = true;
                core_window.width = client_size_pt.width;
                core_window.height = client_size_pt.height;
            }

            if (change) {
                core.pushEvent(.{ .window_resize = .{
                    .window_id = window_id,
                    .size = .{ .width = client_size_pt.width, .height = client_size_pt.height },
                } });
                core.windows.setValueRaw(window_id, core_window);
            }
            return 0;
        },
        w.WM_KEYDOWN, w.WM_KEYUP, w.WM_SYSKEYDOWN, w.WM_SYSKEYUP => {
            // ScanCode: Unique Identifier for a physical button.
            // Virtulkey: A key with a name, multiple physical buttons can produce the same virtual key.
            const window_id = windowIdFromHwnd(hwnd);

            const vkey: w.VIRTUAL_KEY = @enumFromInt(wParam);
            if (vkey == w.VK_PROCESSKEY) return 0;

            if (msg == w.WM_SYSKEYDOWN and vkey == w.VK_F4) {
                core.pushEvent(.{ .close = .{ .window_id = window_id } });

                return 0;
            }

            const WinKeyFlags = packed struct(u32) {
                repeat_count: u16,
                scancode: u8,
                extended: bool,
                reserved: u4,
                context: bool,
                previous: bool,
                transition: bool,
            };

            const flags: WinKeyFlags = @bitCast(@as(u32, @truncate(@as(usize, @bitCast(lParam)))));
            const scancode: u9 = flags.scancode | (@as(u9, if (flags.extended) 1 else 0) << 8);
            if (scancode == 0x1D) {
                // right alt sends left control first
                var next: w.MSG = undefined;
                const time = w.GetMessageTime();
                if (w.PeekMessageW(&next, hwnd, 0, 0, w.PM_NOREMOVE) != 0 and
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
                if (flags.previous) core.pushEvent(.{
                    .key_repeat = .{
                        .window_id = window_id,
                        .key = key,
                        .mods = mods,
                    },
                }) else core.pushEvent(.{
                    .key_press = .{
                        .window_id = window_id,
                        .key = key,
                        .mods = mods,
                    },
                });
            } else core.pushEvent(.{
                .key_release = .{
                    .window_id = window_id,
                    .key = key,
                    .mods = mods,
                },
            });

            return 0;
        },
        w.WM_CHAR => {
            const window_id = windowIdFromHwnd(hwnd);

            const chars: [2]u16 = blk: {
                var native = core.windows.get(window_id, .native).?;
                defer core.windows.setRaw(window_id, .native, native);
                const chars = [2]u16{ native.surrogate, @truncate(wParam) };
                if (std.unicode.utf16IsHighSurrogate(chars[1])) {
                    native.surrogate = chars[1];
                    return 0;
                }
                native.surrogate = 0;
                break :blk chars;
            };
            const codepoint: u21 = blk: {
                if (std.unicode.utf16IsHighSurrogate(chars[0])) {
                    if (std.unicode.utf16DecodeSurrogatePair(&chars)) |c| break :blk c else |e| switch (e) {
                        error.ExpectedSecondSurrogateHalf => {},
                    }
                }
                break :blk chars[1];
            };
            core.pushEvent(.{ .char_input = .{
                .window_id = window_id,
                .codepoint = codepoint,
            } });
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
            const window_id = windowIdFromHwnd(hwnd);
            const mods = getKeyboardModifiers();
            const point = w.pointFromLparam(lParam);

            const MouseFlags = packed struct(u8) {
                left_down: bool,
                right_down: bool,
                shift_down: bool,
                control_down: bool,
                middle_down: bool,
                xbutton1_down: bool,
                xbutton2_down: bool,
                _: bool,
            };
            const flags: MouseFlags = @bitCast(@as(u8, @truncate(wParam)));
            const button: MouseButton = switch (msg) {
                w.WM_LBUTTONDOWN, w.WM_LBUTTONUP => .left,
                w.WM_RBUTTONDOWN, w.WM_RBUTTONUP => .right,
                w.WM_MBUTTONDOWN, w.WM_MBUTTONUP => .middle,
                else => if (flags.xbutton1_down) .four else .five,
            };

            switch (msg) {
                w.WM_LBUTTONDOWN,
                w.WM_MBUTTONDOWN,
                w.WM_RBUTTONDOWN,
                w.WM_XBUTTONDOWN,
                => core.pushEvent(.{
                    .mouse_press = .{
                        .window_id = window_id,
                        .button = button,
                        .mods = mods,
                        .pos = .{ .x = @floatFromInt(point.x), .y = @floatFromInt(point.y) },
                    },
                }),
                else => core.pushEvent(.{
                    .mouse_release = .{
                        .window_id = window_id,
                        .button = button,
                        .mods = mods,
                        .pos = .{ .x = @floatFromInt(point.x), .y = @floatFromInt(point.y) },
                    },
                }),
            }

            return if (msg == w.WM_XBUTTONDOWN or msg == w.WM_XBUTTONUP) w.TRUE else 0;
        },
        w.WM_MOUSEMOVE => {
            const window_id = windowIdFromHwnd(hwnd);
            const point = w.pointFromLparam(lParam);
            core.pushEvent(.{
                .mouse_motion = .{
                    .window_id = window_id,
                    .pos = .{
                        .x = @floatFromInt(point.x),
                        .y = @floatFromInt(point.y),
                    },
                },
            });
            return 0;
        },
        w.WM_MOUSEWHEEL => {
            const window_id = windowIdFromHwnd(hwnd);
            const WHEEL_DELTA = 120.0;
            const wheel_high_word: u16 = @truncate((wParam >> 16) & 0xffff);
            const delta_y: f32 = @as(f32, @floatFromInt(@as(i16, @bitCast(wheel_high_word)))) / WHEEL_DELTA;

            core.pushEvent(.{
                .mouse_scroll = .{
                    .window_id = window_id,
                    .xoffset = 0,
                    .yoffset = delta_y,
                },
            });
            return 0;
        },
        w.WM_SETFOCUS => {
            const window_id = windowIdFromHwnd(hwnd);
            core.pushEvent(.{ .focus_gained = .{ .window_id = window_id } });
            return 0;
        },
        w.WM_KILLFOCUS => {
            const window_id = windowIdFromHwnd(hwnd);
            core.pushEvent(.{ .focus_lost = .{ .window_id = window_id } });
            return 0;
        },
        else => return w.DefWindowProcW(hwnd, msg, wParam, lParam),
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
            0x70 => .international2,
            0x73 => .international1,
            0x76 => .f24,
            //0x77 => .lang4,
            //0x78 => .lang3,
            0x79 => .international4,
            0x7B => .international5,
            0x7D => .international3,
            0x7E => .kp_comma,
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

fn fatalWin32(what: []const u8, last_error: u32) noreturn {
    std.debug.panic("{s} failed, error={}", .{ what, last_error });
}

// TODO (win32) Implement consistent error handling when interfacing with the Windows API.
// TODO (win32) Consider to add support for mouse capture
// TODO (win32) Change to using WM_INPUT for mouse movement.
